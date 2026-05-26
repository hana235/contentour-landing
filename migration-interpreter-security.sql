-- ════════════════════════════════════════════════════════════════
-- migration: 통역사 측 데이터 변조 차단 (정산 + is_verified 보호)
-- 목적:
--   1) 43_정산내역: 통역사가 본인 행을 UPDATE할 때 status·금액·감사필드 변조 차단
--      (정당한 재요청은 RPC `request_settlement_reapproval`로 통일)
--   2) 40_통역사프로필: 통역사가 본인 행 UPDATE 시 is_verified 자가 인증 차단
--
-- 기존 RLS는 본인 행 UPDATE 허용으로 두되, trigger로 컬럼 단위 변조만 차단.
-- 정상 사용(계좌·단가 변경 등)은 그대로 동작.
-- ════════════════════════════════════════════════════════════════


-- ─── 1. 43_정산내역 컬럼 변조 차단 trigger ──────────────────────
CREATE OR REPLACE FUNCTION public.protect_settlement_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_admin BOOLEAN;
BEGIN
    -- service_role 또는 admin은 자유롭게 변경 가능
    -- (auth.role()이 'service_role'이면 통과, admin도 통과)
    IF current_setting('request.jwt.claims', true)::jsonb ->> 'role' = 'service_role' THEN
        RETURN NEW;
    END IF;

    SELECT EXISTS(SELECT 1 FROM "01_회원" WHERE id = auth.uid() AND role = 'admin')
      INTO v_is_admin;
    IF v_is_admin THEN
        RETURN NEW;
    END IF;

    -- 통역사 본인이면: 보호 컬럼은 OLD 값 강제 (silent enforcement)
    -- 변경 가능한 것: bank_account_id, journal_submitted 같은 운영 필드
    NEW.status              := OLD.status;
    NEW.gross_amount        := OLD.gross_amount;
    NEW.tax_amount          := OLD.tax_amount;
    NEW.net_amount          := OLD.net_amount;
    NEW.platform_fee        := OLD.platform_fee;
    NEW.client_total        := OLD.client_total;
    NEW.platform_fee_rate   := OLD.platform_fee_rate;
    NEW.daily_rate          := OLD.daily_rate;
    NEW.working_days        := OLD.working_days;
    NEW.requested_at        := OLD.requested_at;
    NEW.approved_at         := OLD.approved_at;
    NEW.approved_by         := OLD.approved_by;
    NEW.rejected_at         := OLD.rejected_at;
    NEW.rejected_by         := OLD.rejected_by;
    NEW.reject_reason       := OLD.reject_reason;
    NEW.paid_at             := OLD.paid_at;
    NEW.payment_reference   := OLD.payment_reference;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_43_정산내역_protect_columns ON "43_정산내역";
CREATE TRIGGER trg_43_정산내역_protect_columns
BEFORE UPDATE ON "43_정산내역"
FOR EACH ROW
EXECUTE FUNCTION public.protect_settlement_columns();


-- ─── 2. 40_통역사프로필 is_verified 등 변조 차단 trigger ─────────
CREATE OR REPLACE FUNCTION public.protect_interpreter_verify_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_admin BOOLEAN;
BEGIN
    IF current_setting('request.jwt.claims', true)::jsonb ->> 'role' = 'service_role' THEN
        RETURN NEW;
    END IF;

    SELECT EXISTS(SELECT 1 FROM "01_회원" WHERE id = auth.uid() AND role = 'admin')
      INTO v_is_admin;
    IF v_is_admin THEN
        RETURN NEW;
    END IF;

    -- 통역사 본인이면: 인증 관련 컬럼은 OLD 값 강제
    NEW.is_verified       := OLD.is_verified;
    NEW.verified_at       := OLD.verified_at;
    NEW.verified_by       := OLD.verified_by;
    NEW.verification_note := OLD.verification_note;
    -- rate_status 등 단가 승인 관련도 보호 (rate 자체는 신청 가능, status는 admin만)
    -- NEW.rate_status := OLD.rate_status;  -- 코드가 status 직접 쓰면 깨지므로 일단 제외, 향후 결정

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_40_통역사프로필_protect_verify ON "40_통역사프로필";
CREATE TRIGGER trg_40_통역사프로필_protect_verify
BEFORE UPDATE ON "40_통역사프로필"
FOR EACH ROW
EXECUTE FUNCTION public.protect_interpreter_verify_columns();


-- ─── 3. 정산 재요청 RPC (정당한 경로) ────────────────────────────
-- 통역사가 반려된 본인 정산을 다시 요청하는 유일한 합법 경로.
-- 클라이언트의 직접 UPDATE는 위 trigger로 status가 안 바뀌므로, RPC로 통일.
CREATE OR REPLACE FUNCTION public.request_settlement_reapproval(
    p_settlement_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_owner UUID;
    v_status TEXT;
BEGIN
    SELECT interpreter_id, status
      INTO v_owner, v_status
      FROM "43_정산내역"
     WHERE id = p_settlement_id;

    IF v_owner IS NULL THEN
        RAISE EXCEPTION 'settlement not found';
    END IF;
    IF v_owner <> auth.uid() THEN
        RAISE EXCEPTION 'not owner';
    END IF;
    IF v_status <> 'rejected' THEN
        RAISE EXCEPTION 'only rejected settlements can be re-requested (current: %)', v_status;
    END IF;

    -- SECURITY DEFINER로 실행되므로 trigger의 OLD 강제를 우회
    UPDATE "43_정산내역"
       SET status         = 'request',
           requested_at   = NOW(),
           rejected_at    = NULL,
           rejected_by    = NULL,
           reject_reason  = NULL
     WHERE id = p_settlement_id;

    RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.request_settlement_reapproval(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_settlement_reapproval(UUID) TO authenticated;

COMMENT ON FUNCTION public.request_settlement_reapproval IS
'통역사가 본인의 반려된 정산을 재요청하는 유일한 합법 경로. rejected → request 전환만 허용.';
