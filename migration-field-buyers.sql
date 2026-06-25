-- ============================================================================
-- 53_현장바이어 — 전시회 현장 수집 바이어(명함) 리드 테이블 (2026-06-25)
-- ----------------------------------------------------------------------------
-- 상담일지 세 양식(콘텐츄어 기본/부산테크노파크/한국무역협회) 공통 바이어 카드의
-- 저장소. 명함을 구조화 리드로 쌓아 전시회 단위로 모으고 엑셀로 내보낸다.
-- 소유=고객사. 통역사는 본인 배정 계약 건만 대리 수집·조회.
-- 1단계(직접입력/불러오기/엑셀). 명함 OCR(card_image_url)은 2단계.
--
-- 멱등: CREATE TABLE IF NOT EXISTS + ADD COLUMN IF NOT EXISTS + DROP POLICY IF
--       EXISTS. 이전 버전 테이블이 이미 있어도 안전하게 최신 스키마로 맞춘다.
-- ============================================================================

CREATE TABLE IF NOT EXISTS "53_현장바이어" (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     uuid NOT NULL,
    created_at      timestamptz DEFAULT now(),
    updated_at      timestamptz DEFAULT now()
);

-- 메타
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS contract_id     uuid;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS interpreter_id  uuid;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS exhibition_name text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS form_type       text;   -- contentour|busan|kita
-- 공통(OCR 채움 대상)
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS company         text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS contact_name    text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS title           text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS department      text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS email           text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS phone           text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS mobile          text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS fax             text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS website         text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS address         text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS country         text;
-- 사용자 입력
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS memo            text;
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS follow_up_status text DEFAULT '미연락';
-- 양식별 추가필드
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS deal_result     text;   -- 상담결과 (busan/kita)
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS expected_amount text;   -- 예상금액 (busan/kita)
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS buyer_type      text;   -- 유형 (kita)
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS interest_items  text;   -- 관심품목 (kita)
-- OCR/출처
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS source          text DEFAULT '수기';  -- 명함스캔|수기
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS card_image_url  text;   -- 명함 이미지(2단계)
ALTER TABLE "53_현장바이어" ADD COLUMN IF NOT EXISTS scanned_by      uuid;

-- 42_통역계약 FK (이미 있으면 건너뜀)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_53_buyer_contract' AND table_name = '53_현장바이어'
    ) THEN
        ALTER TABLE "53_현장바이어"
            ADD CONSTRAINT fk_53_buyer_contract
            FOREIGN KEY (contract_id) REFERENCES "42_통역계약"(id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_53_buyer_customer    ON "53_현장바이어"(customer_id);
CREATE INDEX IF NOT EXISTS idx_53_buyer_contract    ON "53_현장바이어"(contract_id);
CREATE INDEX IF NOT EXISTS idx_53_buyer_interpreter ON "53_현장바이어"(interpreter_id);

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION touch_53_field_buyer()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_touch_53_field_buyer ON "53_현장바이어";
CREATE TRIGGER trg_touch_53_field_buyer
    BEFORE UPDATE ON "53_현장바이어"
    FOR EACH ROW EXECUTE FUNCTION touch_53_field_buyer();

-- ----------------------------------------------------------------------------
-- RLS: 소유 고객사 + 해당 계약 통역사 + admin
-- ----------------------------------------------------------------------------
ALTER TABLE "53_현장바이어" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS field_buyer_select ON "53_현장바이어";
CREATE POLICY field_buyer_select ON "53_현장바이어"
    FOR SELECT TO authenticated
    USING (
        customer_id = auth.uid()
        OR interpreter_id = auth.uid()
        OR EXISTS (SELECT 1 FROM "42_통역계약" c WHERE c.id = "53_현장바이어".contract_id AND c.interpreter_id = auth.uid())
        OR is_admin()
    );

DROP POLICY IF EXISTS field_buyer_insert ON "53_현장바이어";
CREATE POLICY field_buyer_insert ON "53_현장바이어"
    FOR INSERT TO authenticated
    WITH CHECK (
        is_admin()
        OR (customer_id = auth.uid())
        OR (
            interpreter_id = auth.uid()
            AND EXISTS (
                SELECT 1 FROM "42_통역계약" c
                WHERE c.id = "53_현장바이어".contract_id
                  AND c.interpreter_id = auth.uid()
                  AND c.customer_id = "53_현장바이어".customer_id
            )
        )
    );

DROP POLICY IF EXISTS field_buyer_update ON "53_현장바이어";
CREATE POLICY field_buyer_update ON "53_현장바이어"
    FOR UPDATE TO authenticated
    USING (customer_id = auth.uid() OR interpreter_id = auth.uid() OR is_admin())
    WITH CHECK (customer_id = auth.uid() OR interpreter_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS field_buyer_delete ON "53_현장바이어";
CREATE POLICY field_buyer_delete ON "53_현장바이어"
    FOR DELETE TO authenticated
    USING (customer_id = auth.uid() OR is_admin());
