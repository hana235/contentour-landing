-- ═══════════════════════════════════════════════════════════════
-- RLS 점검: 46_ITQ견적문의 / 44_상담일지 (2026-06-04)
-- ═══════════════════════════════════════════════════════════════
-- 배경: admin-data.js가 이 두 테이블을 클라이언트에서 직접 .update() 한다
--       (updateInquiryStatus, reviewJournal). 서버 RPC가 아니라 RLS에만 의존하므로,
--       "비-admin 인증 사용자가 이 테이블을 UPDATE하지 못하는지" 1회 확인 필요.
-- 적용처: Supabase Dashboard → SQL Editor → Run (읽기 전용 SELECT, 변경 없음)
-- ═══════════════════════════════════════════════════════════════

-- ① RLS 활성화 여부 (둘 다 relrowsecurity = true 여야 함)
SELECT relname AS table_name, relrowsecurity AS rls_enabled
FROM pg_class
WHERE relname IN ('46_ITQ견적문의', '44_상담일지');

-- ② 정책 목록 — UPDATE/ALL 정책의 qual/with_check 확인
--    안전: qual/with_check에 is_admin() 또는 본인(user_id = auth.uid()) 조건이 있어야 함
--    위험: UPDATE/ALL 정책이 roles=authenticated 인데 qual = true (전체 허용)
SELECT tablename, policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE tablename IN ('46_ITQ견적문의', '44_상담일지')
ORDER BY tablename,
         CASE cmd WHEN 'ALL' THEN 0 WHEN 'UPDATE' THEN 1 WHEN 'DELETE' THEN 2
                  WHEN 'INSERT' THEN 3 ELSE 4 END;

-- ═══════════════════════════════════════════════════════════════
-- 판정 가이드:
--   · UPDATE(또는 ALL) 정책이 없으면 → 인증 사용자는 UPDATE 불가(가장 안전).
--   · UPDATE 정책 qual에 is_admin()/auth.uid() 조건 있음 → 안전.
--   · UPDATE 정책이 authenticated + qual=true → ⚠️ 누구나 수정 가능, 강화 필요.
--
-- 만약 ②에서 위험 정책이 보이면 알려주세요. owner+admin 한정으로 강화하는
-- 마이그레이션을 만들어 드리겠습니다 (기존 project_rls_hardening 패턴 적용).
-- ═══════════════════════════════════════════════════════════════
