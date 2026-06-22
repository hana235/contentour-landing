-- ════════════════════════════════════════════════════════════════
-- 40_통역사프로필 관리자 UPDATE 허용 (2026-06-22)
-- ════════════════════════════════════════════════════════════════
-- 증상: 관리자가 통역사 대시보드/검수 모달에서 다른 통역사의 프로필을
--   클라이언트(authenticated)로 UPDATE 할 때 0건 처리되어 조용히 실패.
--   - 노출 국가(country_code) 저장 안 됨
--   - 단가 승인(approveRate)·반려(rejectRate)·직접 조정(saveAdminRateEdit) 반영 안 됨
--     (반려해도 rate_status가 안 바뀌어 "승인 대기중"이 안 사라짐)
--
-- 원인: 기존 UPDATE 정책이 본인 한정이라 admin이 빠져 있었음.
--   migration-interpreter-tables.sql:558
--   CREATE POLICY "통역사_본인프로필_수정" ... FOR UPDATE USING (auth.uid() = user_id);
--   (SELECT 정책에는 is_admin()이 있으나 UPDATE에는 없었음)
--
-- 해결: UPDATE 정책에 OR is_admin() 추가. 본인 수정은 그대로 유지.
--   민감 컬럼(is_verified·평판·정산 등)은 별도 trigger(protect_interpreter_verify_columns,
--   protect_settlement_columns)가 비-admin에 대해 OLD 강제하므로 본 변경으로
--   통역사 자가변조 위험은 늘지 않음. admin은 trigger에서도 통과.
--
-- 멱등: DROP IF EXISTS + CREATE. 재실행 안전.
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- ════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "통역사_본인프로필_수정" ON "40_통역사프로필";

CREATE POLICY "통역사_본인프로필_수정" ON "40_통역사프로필"
  FOR UPDATE
  TO public
  USING ((auth.uid() = user_id) OR is_admin())
  WITH CHECK ((auth.uid() = user_id) OR is_admin());

-- 확인용:
-- SELECT polname, pg_get_expr(polqual, polrelid) AS using_expr,
--        pg_get_expr(polwithcheck, polrelid) AS check_expr
-- FROM pg_policy
-- WHERE polrelid = '"40_통역사프로필"'::regclass AND polcmd = 'w';
