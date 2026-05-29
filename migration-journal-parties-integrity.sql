-- ============================================================================
-- 44_상담일지 당사자 무결성 트리거 (2026-05-29)
-- ----------------------------------------------------------------------------
-- 배경: authenticated_insert RLS의 WITH CHECK가
--       (interpreter_id = auth.uid() OR customer_id = auth.uid() OR is_admin())
--       이라, 한쪽 당사자가 본인 id만 맞추면 *상대 id를 임의 지정*한 일지를
--       만들 수 있다(오귀속). 유출은 아니나 데이터 무결성 결함.
-- 조치: BEFORE INSERT/UPDATE 트리거로 customer_id·interpreter_id가 실제 계약
--       관계(또는 지정된 contract_id의 당사자)와 일치하는지 검증.
-- 성격: 멱등(CREATE OR REPLACE + DROP TRIGGER IF EXISTS). 재실행 안전.
-- 영향: 정상 흐름(통역사 본인이 본인 계약 고객에 대해 작성) 영향 0.
--       admin/service_role(서버 API)은 신뢰하여 면제. 초안(당사자 미지정) 통과.
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_journal_parties()
RETURNS TRIGGER AS $$
BEGIN
    -- 관리자/서버(service_role)는 신뢰
    IF is_admin() THEN
        RETURN NEW;
    END IF;
    IF auth.uid() IS NULL THEN  -- service_role 등 JWT 없는 호출
        RETURN NEW;
    END IF;

    -- contract_id가 지정된 경우: 그 계약의 당사자와 일치해야 함
    IF NEW.contract_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM "42_통역계약" c
            WHERE c.id = NEW.contract_id
              AND (NEW.customer_id IS NULL OR c.customer_id = NEW.customer_id)
              AND (NEW.interpreter_id IS NULL OR c.interpreter_id = NEW.interpreter_id)
        ) THEN
            RAISE EXCEPTION '상담일지의 계약/당사자 정보가 일치하지 않습니다.';
        END IF;
        RETURN NEW;
    END IF;

    -- contract_id가 없고 양 당사자가 모두 지정된 경우:
    -- 두 사람을 잇는 실제 계약이 존재해야 함
    IF NEW.customer_id IS NOT NULL AND NEW.interpreter_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM "42_통역계약" c
            WHERE c.customer_id = NEW.customer_id
              AND c.interpreter_id = NEW.interpreter_id
        ) THEN
            RAISE EXCEPTION '상담일지의 고객/통역사가 실제 계약 관계가 아닙니다.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_validate_journal_parties ON "44_상담일지";
CREATE TRIGGER trg_validate_journal_parties
    BEFORE INSERT OR UPDATE OF customer_id, interpreter_id, contract_id ON "44_상담일지"
    FOR EACH ROW EXECUTE FUNCTION validate_journal_parties();
