-- ════════════════════════════════════════════════════════════════
-- migration: 통역사 패널티/정지 컬럼 변조 차단 + 정당한 적용 RPC
-- 목적:
--   40_통역사프로필.penalty_count / is_suspended / suspended_until 를
--   통역사 본인이 직접 UPDATE(anon키, 브라우저 콘솔)로 변조(리셋)하지 못하게 차단.
--   정당한 패널티 적용은 SECURITY DEFINER RPC apply_cancel_penalty 로만 가능.
--
-- 배경: 기존 코드는 취소 시 클라이언트가 40_통역사프로필을 직접 UPDATE 하여
--   penalty_count 증가/정지 처리 → 통역사가 콘솔에서 penalty_count=0, is_suspended=false
--   로 되돌릴 수 있었음. 정산/is_verified 보호([[migration-interpreter-security.sql]])와
--   동일 패턴으로 정합.
-- ════════════════════════════════════════════════════════════════


-- ─── 1. 기존 보호 트리거 함수 확장: 패널티 컬럼도 OLD 강제 ──────────
--     (is_verified 보호 로직은 그대로 유지, 패널티 3컬럼 + RPC 허용 플래그만 추가)
CREATE OR REPLACE FUNCTION public.protect_interpreter_verify_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_admin BOOLEAN;
BEGIN
    -- 서버 RPC(apply_cancel_penalty 등)가 명시적으로 허용한 트랜잭션은 통과
    IF current_setting('app.allow_penalty_write', true) = '1' THEN
        RETURN NEW;
    END IF;

    -- service_role(서버) 통과
    IF current_setting('request.jwt.claims', true)::jsonb ->> 'role' = 'service_role' THEN
        RETURN NEW;
    END IF;

    -- admin 통과
    SELECT EXISTS(SELECT 1 FROM "01_회원" WHERE id = auth.uid() AND role = 'admin')
      INTO v_is_admin;
    IF v_is_admin THEN
        RETURN NEW;
    END IF;

    -- 통역사 본인이면: 인증 컬럼 보호 (기존)
    NEW.is_verified       := OLD.is_verified;
    NEW.verified_at       := OLD.verified_at;
    NEW.verified_by       := OLD.verified_by;
    NEW.verification_note := OLD.verification_note;

    -- 통역사 본인이면: 패널티/정지 컬럼 보호 (신규)
    NEW.penalty_count     := OLD.penalty_count;
    NEW.is_suspended      := OLD.is_suspended;
    NEW.suspended_until   := OLD.suspended_until;

    RETURN NEW;
END;
$$;

-- 트리거는 이미 존재(trg_40_통역사프로필_protect_verify) → 함수만 교체되면 자동 적용.
-- 안전을 위해 재생성(idempotent).
DROP TRIGGER IF EXISTS trg_40_통역사프로필_protect_verify ON "40_통역사프로필";
CREATE TRIGGER trg_40_통역사프로필_protect_verify
BEFORE UPDATE ON "40_통역사프로필"
FOR EACH ROW
EXECUTE FUNCTION public.protect_interpreter_verify_columns();


-- ─── 2. 패널티 적용 RPC (정당한 유일 경로) ────────────────────────
--     취소 시 통역사 귀책 패널티 +1, 누적 3회 이상이면 30일 정지.
--     본인 계약인지 서버에서 검증 후, allow_penalty_write 플래그를 세워
--     위 트리거를 우회하여 갱신.
CREATE OR REPLACE FUNCTION public.apply_cancel_penalty(
    p_contract_id TEXT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid       UUID := auth.uid();
    v_interp    UUID;
    v_count     INT;
    v_suspended BOOLEAN;
BEGIN
    IF v_uid IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'unauthenticated');
    END IF;

    -- 계약의 배정 통역사가 본인인지 확인 (타인 계약으로 패널티 호출 차단)
    SELECT interpreter_id INTO v_interp
      FROM "42_통역계약"
     WHERE id = p_contract_id::uuid;

    IF v_interp IS NULL OR v_interp <> v_uid THEN
        RETURN jsonb_build_object('success', false, 'error', 'not_your_contract');
    END IF;

    -- 트리거 우회 허용 (트랜잭션 로컬)
    PERFORM set_config('app.allow_penalty_write', '1', true);

    UPDATE "40_통역사프로필"
       SET penalty_count   = COALESCE(penalty_count, 0) + 1,
           is_suspended    = (COALESCE(penalty_count, 0) + 1) >= 3,
           suspended_until = CASE WHEN (COALESCE(penalty_count, 0) + 1) >= 3
                                  THEN NOW() + INTERVAL '30 days'
                                  ELSE NULL END
     WHERE user_id = v_uid
     RETURNING penalty_count, is_suspended INTO v_count, v_suspended;

    RETURN jsonb_build_object('success', true, 'penalty_count', v_count, 'is_suspended', v_suspended);
END;
$$;

REVOKE ALL ON FUNCTION public.apply_cancel_penalty(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apply_cancel_penalty(TEXT) TO authenticated;

COMMENT ON FUNCTION public.apply_cancel_penalty IS
'취소 시 통역사 본인 패널티 +1(누적 3회 이상 30일 정지)을 적용하는 유일한 합법 경로. 클라이언트 직접 UPDATE는 trigger로 차단됨.';
