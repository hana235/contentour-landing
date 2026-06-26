-- ============================================================================
-- 54_상담일지양식 — 통역사 직접 배정 지원 (2026-06-26)
-- ----------------------------------------------------------------------------
-- 기존: customer_id(고객사 지정) 또는 NULL(전체공통)만 가능.
-- 추가: interpreter_id 컬럼 → 특정 통역사 개인에게 직접 배정 가능.
--   · 고객사 지정  = customer_id 설정
--   · 통역사 지정  = interpreter_id 설정
--   · 전체 공통    = customer_id IS NULL AND interpreter_id IS NULL (둘 다 NULL)
-- ★ '전체공통'의 정의가 (customer_id IS NULL) → (둘 다 NULL)로 바뀌므로
--   통역사 지정 양식이 공통으로 새지 않도록 template_select 정책도 재정의함.
-- 멱등: ADD COLUMN IF NOT EXISTS / DROP POLICY IF EXISTS. 재실행 안전.
-- (migration-54-interpreter-read.sql 의 통역사 정책을 본 파일이 대체함)
-- ============================================================================

ALTER TABLE "54_상담일지양식" ADD COLUMN IF NOT EXISTS interpreter_id uuid;
CREATE INDEX IF NOT EXISTS idx_54_tpl_interpreter ON "54_상담일지양식"(interpreter_id);

-- 고객사/공통 조회: 본인 지정 + 진짜 공통(둘 다 NULL) + admin
DROP POLICY IF EXISTS template_select ON "54_상담일지양식";
CREATE POLICY template_select ON "54_상담일지양식"
    FOR SELECT TO authenticated
    USING (
        is_active = true AND (
            customer_id = auth.uid()
            OR (customer_id IS NULL AND interpreter_id IS NULL)
        )
        OR is_admin()
    );

-- 통역사 조회: 본인 직접배정(interpreter_id) + 본인 계약 고객사 지정 양식
DROP POLICY IF EXISTS template_select_interpreter ON "54_상담일지양식";
CREATE POLICY template_select_interpreter ON "54_상담일지양식"
    FOR SELECT TO authenticated
    USING (
        is_active = true AND (
            interpreter_id = auth.uid()
            OR customer_id IN (
                SELECT customer_id FROM "42_통역계약" WHERE interpreter_id = auth.uid()
            )
        )
    );
