-- ============================================================================
-- 54_상담일지양식 — 관리자가 만들어 업체별로 배정하는 맞춤 상담일지 양식 (2026-06-25)
-- ----------------------------------------------------------------------------
-- 콘텐츄어(admin)가 양식 항목·문구를 직접 편집해 특정 고객사 전용 양식을 만들고
-- 배정. 고객사는 본인에게 배정된 양식(+전체공통)을 탭으로 받아 작성한다.
-- 양식 구조(sections): customer-dashboard의 "나만의 양식" 빌더와 동일 스키마
--   [{ name, fields:[{ name, type('text'|'number'|'date'|'textarea'|'select'),
--                       required:bool, options?:[...] }] }]
-- 작성 결과는 기존 44_상담일지에 저장(별도 테이블 없음).
-- 멱등: CREATE IF NOT EXISTS / DROP POLICY IF EXISTS. 재실행 안전.
-- ============================================================================

CREATE TABLE IF NOT EXISTS "54_상담일지양식" (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id  uuid,                              -- 배정 고객사(01_회원.id). NULL = 전체 공통
    name         text NOT NULL,
    sections     jsonb NOT NULL DEFAULT '[]'::jsonb,
    is_active    boolean DEFAULT true,
    created_by   uuid,                              -- 작성 admin
    created_at   timestamptz DEFAULT now(),
    updated_at   timestamptz DEFAULT now()
);

COMMENT ON TABLE "54_상담일지양식" IS '관리자 작성 맞춤 상담일지 양식. customer_id=배정 고객사(NULL=공통). 작성=admin, 조회=배정 고객사+공통+admin.';

CREATE INDEX IF NOT EXISTS idx_54_tpl_customer ON "54_상담일지양식"(customer_id);

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION touch_54_template()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_touch_54_template ON "54_상담일지양식";
CREATE TRIGGER trg_touch_54_template
    BEFORE UPDATE ON "54_상담일지양식"
    FOR EACH ROW EXECUTE FUNCTION touch_54_template();

-- ----------------------------------------------------------------------------
-- RLS
-- ----------------------------------------------------------------------------
ALTER TABLE "54_상담일지양식" ENABLE ROW LEVEL SECURITY;

-- 조회: 배정 고객사 본인 + 전체공통(customer_id IS NULL) + admin
DROP POLICY IF EXISTS template_select ON "54_상담일지양식";
CREATE POLICY template_select ON "54_상담일지양식"
    FOR SELECT TO authenticated
    USING (
        is_active = true AND (customer_id = auth.uid() OR customer_id IS NULL)
        OR is_admin()
    );

-- 작성/수정/삭제: admin 전용
DROP POLICY IF EXISTS template_insert ON "54_상담일지양식";
CREATE POLICY template_insert ON "54_상담일지양식"
    FOR INSERT TO authenticated
    WITH CHECK (is_admin());

DROP POLICY IF EXISTS template_update ON "54_상담일지양식";
CREATE POLICY template_update ON "54_상담일지양식"
    FOR UPDATE TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS template_delete ON "54_상담일지양식";
CREATE POLICY template_delete ON "54_상담일지양식"
    FOR DELETE TO authenticated
    USING (is_admin());
