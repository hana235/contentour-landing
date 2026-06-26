-- ============================================================================
-- 55_상담일지_비공개 — 상담일지 '고객사 전용' 영역 (콘텐츄어 미열람) (2026-06-26)
-- ----------------------------------------------------------------------------
-- 배경: 기업이 상담 상세 내용(요약·성과·특이사항·조치)을 영업 기밀로 여겨
--       콘텐츄어(관리자)에게 보이는 것을 꺼림. 44_상담일지에는 운영·품질 정보만
--       남기고, 민감한 상담 본문은 본 테이블에 분리 저장한다. SELECT에서 admin을
--       빼 '미열람'을 기술적으로 강제. (바이어 데이터 53_현장바이어와 동일 원칙)
-- 연결: journal_id = 44_상담일지.id (1:1, UNIQUE → upsert).
-- 영향: 소유 고객사 + 대리/계약 통역사만 조회. 콘텐츄어 admin은 조회 불가.
-- 멱등: CREATE IF NOT EXISTS / DROP POLICY IF EXISTS. 재실행 안전.
-- ============================================================================

CREATE TABLE IF NOT EXISTS "55_상담일지_비공개" (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_id     uuid UNIQUE,                         -- 44_상담일지.id (1:1)
    contract_id    uuid,
    customer_id    uuid NOT NULL,                       -- 소유 고객사
    interpreter_id uuid,
    content        jsonb NOT NULL DEFAULT '{}'::jsonb,  -- {summary, result, issue, action}
    created_at     timestamptz DEFAULT now(),
    updated_at     timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_55_journal ON "55_상담일지_비공개"(journal_id);
CREATE INDEX IF NOT EXISTS idx_55_customer ON "55_상담일지_비공개"(customer_id);

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION touch_55_private()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_touch_55_private ON "55_상담일지_비공개";
CREATE TRIGGER trg_touch_55_private
    BEFORE UPDATE ON "55_상담일지_비공개"
    FOR EACH ROW EXECUTE FUNCTION touch_55_private();

-- ----------------------------------------------------------------------------
-- RLS — 소유 고객사 + 대리 통역사 + 해당 계약 통역사. admin 제외(미열람 강제).
-- ----------------------------------------------------------------------------
ALTER TABLE "55_상담일지_비공개" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS journal_private_select ON "55_상담일지_비공개";
CREATE POLICY journal_private_select ON "55_상담일지_비공개"
    FOR SELECT TO authenticated
    USING (
        customer_id = auth.uid()
        OR interpreter_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM "42_통역계약" c
            WHERE c.id = "55_상담일지_비공개".contract_id
              AND c.interpreter_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS journal_private_insert ON "55_상담일지_비공개";
CREATE POLICY journal_private_insert ON "55_상담일지_비공개"
    FOR INSERT TO authenticated
    WITH CHECK (customer_id = auth.uid() OR interpreter_id = auth.uid());

DROP POLICY IF EXISTS journal_private_update ON "55_상담일지_비공개";
CREATE POLICY journal_private_update ON "55_상담일지_비공개"
    FOR UPDATE TO authenticated
    USING (customer_id = auth.uid() OR interpreter_id = auth.uid())
    WITH CHECK (customer_id = auth.uid() OR interpreter_id = auth.uid());

DROP POLICY IF EXISTS journal_private_delete ON "55_상담일지_비공개";
CREATE POLICY journal_private_delete ON "55_상담일지_비공개"
    FOR DELETE TO authenticated
    USING (customer_id = auth.uid() OR interpreter_id = auth.uid());
