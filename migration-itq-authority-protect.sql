-- ══════════════════════════════════════════════════════════
-- HIGH 보안/금전: 46_ITQ견적문의 견적 권위 컬럼(admin_note)을 비관리자 직접 UPDATE로부터 보호
-- 작업일: 2026-06-18
-- 문제: 46_ITQ견적문의의 authenticated_update RLS가 행 소유 고객(user_id=auth.uid())에게
--       컬럼 제한 없는 UPDATE를 허용. accept-quote(api/my.js)는 계약 금액(일당·공급가·총액·계약금)을
--       admin_note(관리자 작성)에서 읽어 권위로 신뢰하는데, 고객이 자기 문의의 admin_note 금액을
--       1원 등으로 변조한 뒤 수락하면 변조된 저액으로 계약이 생성되고 verify-payment도 그 값으로
--       재계산해 결제까지 통과 → 가격 변조(저액 결제) 가능.
-- 해결: 42_통역계약 결제컬럼 보호(prevent_unauthorized_payment_update)와 동일하게,
--       service_role/admin이 아닌 사용자가 admin_note를 변경하면 차단하는 BEFORE UPDATE 트리거.
-- 주의: status는 고객의 정상 '견적거절' 클라이언트 전이가 있어 의도적으로 잠그지 않음
--       (가격 권위는 admin_note이므로 admin_note 잠금만으로 본 취약점은 닫힘).
-- ══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.prevent_itq_authority_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    actor_role text;
BEGIN
    -- service_role(API: assign RPC·showcase·cancel 등)은 자유 통과
    IF (auth.role() = 'service_role') OR (auth.uid() IS NULL) THEN
        RETURN NEW;
    END IF;

    -- admin 자유 통과
    SELECT role INTO actor_role FROM "01_회원" WHERE id = auth.uid();
    IF actor_role = 'admin' THEN
        RETURN NEW;
    END IF;

    -- 일반 사용자(customer/interpreter)는 admin_note(견적 금액 권위) 변경 금지
    IF NEW.admin_note IS DISTINCT FROM OLD.admin_note THEN
        RAISE EXCEPTION 'admin_note(견적 권위)는 관리자 또는 서버 API에서만 변경할 수 있습니다.';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_46_ITQ견적문의_protect_authority ON "46_ITQ견적문의";
CREATE TRIGGER trg_46_ITQ견적문의_protect_authority
    BEFORE UPDATE ON "46_ITQ견적문의"
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_itq_authority_update();

COMMENT ON FUNCTION public.prevent_itq_authority_update IS
    'service_role/admin이 아닌 사용자가 46_ITQ견적문의.admin_note(견적 금액 권위)를 직접 UPDATE하는 것을 차단. accept-quote 가격 변조 방지.';

-- 검증 테스트: 고객 토큰으로 본인 문의의 admin_note를 REST UPDATE 시도 → 거부되어야 함.
--   정상 흐름(관리자 견적 발송 → 고객 accept-quote → 결제)은 그대로 동작해야 함.
