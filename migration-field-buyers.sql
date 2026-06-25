-- ============================================================================
-- 53_현장바이어 — 전시회 현장 수집 바이어(명함) 리드 테이블 (2026-06-25)
-- ----------------------------------------------------------------------------
-- 배경: 상담일지의 "바이어 정보"는 지금까지 44_상담일지.attachments JSON 안에
--       수기로만 저장됨. 전시 현장에서 교환한 명함을 구조화된 리드로 쌓아
--       (수기입력 → 추후 명함 OCR) 계약/전시회 단위로 모으고 엑셀로 내보내기
--       위한 전용 테이블.
-- 소유: 고객사(customer_id). 통역사는 본인 배정 계약 건만 대신 수집·조회.
-- 단계: 1단계(이 마이그레이션) = 골격(수기입력/불러오기/엑셀). OCR은 추후.
-- 성격: 멱등(IF NOT EXISTS / CREATE OR REPLACE / DROP POLICY IF EXISTS). 재실행 안전.
-- ============================================================================

CREATE TABLE IF NOT EXISTS "53_현장바이어" (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id     uuid REFERENCES "42_통역계약"(id) ON DELETE SET NULL,
    customer_id     uuid NOT NULL,           -- 소유자(명함을 받은 고객사)
    interpreter_id  uuid,                    -- 대신 수집한 통역사(있으면)
    exhibition_name text,                    -- 전시회명(스냅샷)
    company         text,                    -- 바이어 회사명
    country         text,                    -- 국가
    contact_name    text,                    -- 담당자 이름
    title           text,                    -- 직책
    email           text,
    phone           text,
    website         text,
    memo            text,                    -- 상담 메모
    follow_up_status text DEFAULT '미연락',  -- 미연락 / 견적발송 / 협의중 / 계약 / 보류
    source          text DEFAULT '수기',     -- 수기 / 명함스캔 / 주최사import
    card_image_url  text,                    -- 명함 이미지(Storage 경로, OCR 단계용)
    scanned_by      uuid,                    -- 입력/스캔 수행자(auth.uid)
    created_at      timestamptz DEFAULT now(),
    updated_at      timestamptz DEFAULT now()
);

COMMENT ON TABLE "53_현장바이어" IS '전시회 현장에서 수집한 바이어(명함) 리드. 소유=고객사, 통역사는 본인 계약 건 대리 수집.';

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
-- RLS: 소유 고객사 + 해당 계약 통역사 + admin 만 접근
-- ----------------------------------------------------------------------------
ALTER TABLE "53_현장바이어" ENABLE ROW LEVEL SECURITY;

-- 조회: 소유 고객사 / 대리 통역사 / 해당 계약의 통역사 / admin
DROP POLICY IF EXISTS field_buyer_select ON "53_현장바이어";
CREATE POLICY field_buyer_select ON "53_현장바이어"
    FOR SELECT TO authenticated
    USING (
        customer_id = auth.uid()
        OR interpreter_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM "42_통역계약" c
            WHERE c.id = "53_현장바이어".contract_id
              AND c.interpreter_id = auth.uid()
        )
        OR is_admin()
    );

-- 생성: 고객사 본인 소유로만, 또는 대리 통역사가 본인 계약 고객 건으로만
DROP POLICY IF EXISTS field_buyer_insert ON "53_현장바이어";
CREATE POLICY field_buyer_insert ON "53_현장바이어"
    FOR INSERT TO authenticated
    WITH CHECK (
        is_admin()
        -- 고객사가 본인 소유로 직접 입력
        OR (customer_id = auth.uid())
        -- 통역사가 본인 배정 계약의 고객 건을 대리 입력
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

-- 수정: 소유 고객사 / 대리 통역사 / admin
DROP POLICY IF EXISTS field_buyer_update ON "53_현장바이어";
CREATE POLICY field_buyer_update ON "53_현장바이어"
    FOR UPDATE TO authenticated
    USING (
        customer_id = auth.uid()
        OR interpreter_id = auth.uid()
        OR is_admin()
    )
    WITH CHECK (
        customer_id = auth.uid()
        OR interpreter_id = auth.uid()
        OR is_admin()
    );

-- 삭제: 소유 고객사 / admin (통역사는 삭제 불가 — 고객 자산 보호)
DROP POLICY IF EXISTS field_buyer_delete ON "53_현장바이어";
CREATE POLICY field_buyer_delete ON "53_현장바이어"
    FOR DELETE TO authenticated
    USING (
        customer_id = auth.uid()
        OR is_admin()
    );
