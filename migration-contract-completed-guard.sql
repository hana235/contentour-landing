-- ══════════════════════════════════════════════════════════
-- 42_통역계약 'completed' 자가전이 차단 (2026-06-19)
-- ──────────────────────────────────────────────────────────
-- 증상: customer-dashboard.html confirmServiceComplete의 클라이언트 가드
--   (c.status==='complete')는 콘솔/직접호출로 우회 가능했고,
--   기존 보호 트리거(prevent_unauthorized_payment_update)의 status 차단 목록에
--   'completed'가 빠져 있어, 고객이 임의 상태의 계약을 'completed'로 위조 가능했음.
--   (정산은 admin RPC라 금전 탈취는 불가했으나, 거짓 완료 상태 표시가 가능)
--
-- 해법: 보호 트리거의 status 전이 차단 목록에 'completed' 추가.
--   ※ 클라이언트 UI의 정상 완료확인은 DB가 이미 'completed'일 때만 발동하여
--     completed→completed(무변화)를 쓰므로, IS DISTINCT FROM 가드에 안 걸려 그대로 동작.
--     실제 'completed' 전이는 admin/서비스 API(service_role)만 수행(트리거 상단에서 통과).
--
-- 안전성: 함수 본문은 기존(migration-payment-columns-protection.sql)을 그대로 두고
--   IN(...) 목록에 'completed'만 추가. 비파괴·멱등(CREATE OR REPLACE).
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- ══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.prevent_unauthorized_payment_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    actor_role text;
    is_service_role boolean;
BEGIN
    -- service_role(verify-payment 등 API)은 자유 통과
    is_service_role := (auth.role() = 'service_role') OR (auth.uid() IS NULL);
    IF is_service_role THEN
        RETURN NEW;
    END IF;

    -- admin도 자유 통과
    SELECT role INTO actor_role FROM "01_회원" WHERE id = auth.uid();
    IF actor_role = 'admin' THEN
        RETURN NEW;
    END IF;

    -- 일반 사용자(customer/interpreter)는 결제 컬럼 변경 금지
    IF NEW.deposit_status IS DISTINCT FROM OLD.deposit_status
       OR NEW.deposit_paid_at IS DISTINCT FROM OLD.deposit_paid_at
       OR NEW.deposit_amount IS DISTINCT FROM OLD.deposit_amount
       OR NEW.balance_status IS DISTINCT FROM OLD.balance_status
       OR NEW.balance_paid_at IS DISTINCT FROM OLD.balance_paid_at
       OR NEW.balance_amount IS DISTINCT FROM OLD.balance_amount
       OR NEW.total_amount IS DISTINCT FROM OLD.total_amount
       OR NEW.daily_rate IS DISTINCT FROM OLD.daily_rate
       OR NEW.tax_amount IS DISTINCT FROM OLD.tax_amount
       OR NEW.net_amount IS DISTINCT FROM OLD.net_amount
       OR NEW.settlement_status IS DISTINCT FROM OLD.settlement_status
    THEN
        RAISE EXCEPTION '결제 관련 컬럼은 관리자 또는 결제 API에서만 변경할 수 있습니다.';
    END IF;

    -- status를 결제/완료 관련 값으로 전이시키는 행위 차단 (계약 동의·취소는 허용)
    -- completed→completed 같은 무변화 자기쓰기는 IS DISTINCT FROM 가드로 자동 허용됨(정상 UI 경로).
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        IF NEW.status IN ('deposit_paid', 'balance_paid', 'paid', 'completed', 'settled', 'refunded') THEN
            RAISE EXCEPTION '결제·완료 상태 전이는 관리자 또는 결제 API에서만 가능합니다.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- 트리거는 이미 존재(trg_42_통역계약_prevent_payment_update) → 함수 교체만으로 자동 적용.

COMMENT ON FUNCTION public.prevent_unauthorized_payment_update IS
    'service_role/admin이 아닌 사용자가 42_통역계약 결제·완료(completed 포함) 상태/컬럼을 직접 변조하는 것을 차단. RLS column-level 제한 대체. (2026-06-19 completed 추가)';
