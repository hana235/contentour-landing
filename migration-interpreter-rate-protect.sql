-- ════════════════════════════════════════════════════════════════
-- migration: 40_통역사프로필 확정 단가 컬럼 변조 차단 (단가 승인 게이트 강제)
-- 목적:
--   통역사가 콘솔/직접 UPDATE로 확정 단가(rate_by_type / rate_by_language /
--   base_rate)를 임의로 바꿔 관리자 승인 게이트를 우회하던 구멍을 차단.
--
-- 배경:
--   기존 protect_interpreter_verify_columns 트리거는 is_verified 등 인증 컬럼만
--   보호하고, 단가 컬럼은 "코드가 status 직접 쓰면 깨질 우려"로 일부러 제외돼 있었음
--   (migration-interpreter-security.sql:92). 그 결과 단가 승인 워크플로우가
--   클라이언트에서 완전히 우회 가능한 상태였음.
--
-- 정상 신청 경로(saveRatesOnly)는 pending_rate_by_type / pending_rate_by_language /
--   rate_status='pending' / rate_submitted_at 만 쓰고 확정 단가는 건드리지 않으므로,
--   아래 보호로 정상 동작은 깨지지 않음.
--
-- 보호 규칙(비 admin · 비 service_role 사용자에 한해):
--   - base_rate / rate_by_type / rate_by_language        → OLD 강제 (직접 변경 불가)
--   - rate_status → 'pending' 으로의 전환만 허용, 그 외(특히 'approved') → OLD 강제
-- ════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.protect_interpreter_verify_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_admin BOOLEAN;
BEGIN
    -- service_role 은 자유롭게 변경 가능
    IF current_setting('request.jwt.claims', true)::jsonb ->> 'role' = 'service_role' THEN
        RETURN NEW;
    END IF;

    SELECT EXISTS(SELECT 1 FROM "01_회원" WHERE id = auth.uid() AND role = 'admin')
      INTO v_is_admin;
    IF v_is_admin THEN
        RETURN NEW;
    END IF;

    -- ── 통역사 본인: 인증 관련 컬럼 OLD 강제 (기존 보호 유지) ──
    NEW.is_verified       := OLD.is_verified;
    NEW.verified_at       := OLD.verified_at;
    NEW.verified_by       := OLD.verified_by;
    NEW.verification_note := OLD.verification_note;

    -- ── 확정 단가 컬럼 OLD 강제 (신규 보호) ──
    -- 승인된 실제 단가는 admin 승인(또는 service_role)을 통해서만 갱신.
    -- pending_rate_by_type / pending_rate_by_language 는 신청 경로이므로 보호하지 않음.
    NEW.base_rate         := OLD.base_rate;
    NEW.rate_by_type      := OLD.rate_by_type;
    NEW.rate_by_language  := OLD.rate_by_language;

    -- rate_status: 'pending'(승인 신청)으로의 전환만 허용. 그 외 값은 OLD 강제.
    IF NEW.rate_status IS DISTINCT FROM OLD.rate_status
       AND NEW.rate_status <> 'pending' THEN
        NEW.rate_status := OLD.rate_status;
    END IF;

    RETURN NEW;
END;
$$;

-- 트리거는 기존 정의(trg_40_통역사프로필_protect_verify) 그대로 사용.
-- 함수만 교체되므로 별도 DROP/CREATE TRIGGER 불필요. (안전 위해 재생성)
DROP TRIGGER IF EXISTS trg_40_통역사프로필_protect_verify ON "40_통역사프로필";
CREATE TRIGGER trg_40_통역사프로필_protect_verify
BEFORE UPDATE ON "40_통역사프로필"
FOR EACH ROW
EXECUTE FUNCTION public.protect_interpreter_verify_columns();

COMMENT ON FUNCTION public.protect_interpreter_verify_columns IS
'40_통역사프로필 변조 차단: 비admin은 is_verified/verified_* 및 확정 단가(base_rate, rate_by_type, rate_by_language) 변경 불가. rate_status는 pending 전환만 허용.';
