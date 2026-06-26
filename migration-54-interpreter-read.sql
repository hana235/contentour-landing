-- ============================================================================
-- 54_상담일지양식 — 통역사 배정양식 조회 정책 추가 (2026-06-26)
-- ----------------------------------------------------------------------------
-- 기존 정책(template_select)은 "배정 고객사 본인 + 전체공통(NULL) + admin"만 조회 허용.
-- 그러나 상담일지는 현장에서 '통역사'가 작성하므로, 통역사가 본인 계약(42_통역계약)
-- 고객사에 배정된 양식을 읽을 수 있어야 함. 아래 정책을 추가로(OR) 부여한다.
-- (PostgreSQL의 다중 PERMISSIVE 정책은 OR로 합쳐지므로 기존 정책과 공존)
-- 멱등: DROP POLICY IF EXISTS. 재실행 안전.
-- ============================================================================

DROP POLICY IF EXISTS template_select_interpreter ON "54_상담일지양식";
CREATE POLICY template_select_interpreter ON "54_상담일지양식"
    FOR SELECT TO authenticated
    USING (
        is_active = true
        AND customer_id IN (
            SELECT customer_id FROM "42_통역계약"
            WHERE interpreter_id = auth.uid()
        )
    );
