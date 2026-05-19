-- ════════════════════════════════════════════════════════════════
-- Supabase Security Advisor 59 Warnings 처리
-- 작성: 2026-05-19
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run
-- ════════════════════════════════════════════════════════════════
-- 처리 범위:
--   Phase 1: function_search_path_mutable 14건
--   Phase 2: anon SECURITY DEFINER EXECUTE 회수 20건
--   Phase 3: authenticated EXECUTE 회수 (안전한 함수만) 9건
--   Phase 4: rls_policy_always_true (ITQ anon INSERT) 1건
--   Phase 5: public_bucket_allows_listing 2건
-- 보류 1건 (extension_in_public/pg_trgm): 인덱스 깨질 위험으로 별도 처리
-- 별도 1건 (auth_leaked_password_protection): Dashboard에서 활성화
-- ════════════════════════════════════════════════════════════════

BEGIN;

-- ════════════════════════════════════════════════════════════════
-- Phase 1: search_path 고정 (14건)
-- ════════════════════════════════════════════════════════════════

ALTER FUNCTION public.update_60_exhibitions_updated_at() SET search_path = public, pg_temp;
ALTER FUNCTION public.update_loyalty_updated_at() SET search_path = public, pg_temp;
ALTER FUNCTION public.update_loyalty_tier_on_contract(uuid, bigint) SET search_path = public, pg_temp;
ALTER FUNCTION public.admin_adjust_loyalty(uuid, integer, text) SET search_path = public, pg_temp;
ALTER FUNCTION public.use_loyalty_points(uuid, integer, text, text, text) SET search_path = public, pg_temp;
ALTER FUNCTION public.expire_loyalty_points() SET search_path = public, pg_temp;
ALTER FUNCTION public.earn_loyalty_points(uuid, integer, text, text, text, timestamp with time zone) SET search_path = public, pg_temp;
ALTER FUNCTION public.admin_approve_business_registration(uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.admin_reject_business_registration(uuid, text) SET search_path = public, pg_temp;
ALTER FUNCTION public.process_payment(uuid, text, integer, text, text, text) SET search_path = public, pg_temp;
ALTER FUNCTION public.approve_settlement(uuid, uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.reject_settlement(uuid, uuid, text) SET search_path = public, pg_temp;
ALTER FUNCTION public.complete_settlement_payment(uuid, text) SET search_path = public, pg_temp;
ALTER FUNCTION public.protect_review_columns() SET search_path = public, pg_temp;

-- ════════════════════════════════════════════════════════════════
-- Phase 2: anon 권한 회수 — 모든 SECURITY DEFINER 함수 (20건)
-- anon 사용자가 RPC로 직접 호출할 일이 없는 함수들. 공개 폼은 service role API로 우회됨.
-- ════════════════════════════════════════════════════════════════

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon;
REVOKE EXECUTE ON FUNCTION public.auto_create_settlement_on_journal() FROM anon;
REVOKE EXECUTE ON FUNCTION public.auto_link_member_on_insert() FROM anon;
REVOKE EXECUTE ON FUNCTION public.link_member_to_orphan_data(uuid, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.create_settlement(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.process_payment(uuid, text, integer, text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.process_refund(uuid, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_admin() FROM anon;
REVOKE EXECUTE ON FUNCTION public.earn_loyalty_points(uuid, integer, text, text, text, timestamp with time zone) FROM anon;
REVOKE EXECUTE ON FUNCTION public.use_loyalty_points(uuid, integer, text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.update_loyalty_tier_on_contract(uuid, bigint) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_adjust_loyalty(uuid, integer, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.expire_loyalty_points() FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_approve_business_registration(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.admin_reject_business_registration(uuid, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.approve_settlement(uuid, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.reject_settlement(uuid, uuid, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.complete_settlement_payment(uuid, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.cancel_contract(uuid, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.calculate_penalty(uuid, text) FROM anon;

-- ════════════════════════════════════════════════════════════════
-- Phase 3: authenticated 권한 회수 — 클라이언트 직접 호출 없는 함수만 (9건)
-- 트리거 함수, 서버 전용 함수, 비활성 적립금 함수만 안전하게 회수.
-- ════════════════════════════════════════════════════════════════

-- 트리거 전용 (직접 호출 없음)
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.auto_create_settlement_on_journal() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.auto_link_member_on_insert() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.link_member_to_orphan_data(uuid, text) FROM authenticated;

-- 서버 전용 (api/* + service role만 호출)
REVOKE EXECUTE ON FUNCTION public.create_settlement(uuid) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.process_payment(uuid, text, integer, text, text, text) FROM authenticated;

-- 적립금 (UI OFF + cron OFF로 호출 안 됨)
REVOKE EXECUTE ON FUNCTION public.earn_loyalty_points(uuid, integer, text, text, text, timestamp with time zone) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.use_loyalty_points(uuid, integer, text, text, text) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.update_loyalty_tier_on_contract(uuid, bigint) FROM authenticated;

-- 주의: 아래 함수들은 authenticated 권한 유지 (실제 클라이언트에서 호출 중)
--   admin_adjust_loyalty (적립금 재개 시 admin 호출)
--   admin_approve_business_registration, admin_reject_business_registration (admin 대시보드)
--   approve_settlement, reject_settlement, complete_settlement_payment (admin 대시보드)
--   process_refund (admin 환불)
--   expire_loyalty_points (admin 수동 실행 가능)
--   cancel_contract, calculate_penalty (고객·통역사 대시보드)
--   is_admin (RLS 정책 헬퍼)
-- → 함수 내부에서 is_admin() / auth.uid() 검증으로 보호됨.

-- ════════════════════════════════════════════════════════════════
-- Phase 4: ITQ 견적문의 anon INSERT 정책 제거 (1건)
-- 공개 폼 INSERT는 service role API(/api/inquiry)로 이미 우회됨.
-- ════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS anon_insert_itq ON public."46_ITQ견적문의";

-- ════════════════════════════════════════════════════════════════
-- Phase 5: 공개 버킷의 listing 정책 제거 (2건)
-- 직접 URL 접근(getPublicUrl)은 그대로 작동, listing API만 차단.
-- ════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS case_images_select_public ON storage.objects;
DROP POLICY IF EXISTS "프로필사진_공개_조회" ON storage.objects;

COMMIT;

-- ════════════════════════════════════════════════════════════════
-- 적용 결과 예상:
--   59 → 13 건 (78% 감소)
--   남는 13건 = 의도적 유지(admin/user 함수 authenticated 권한) +
--              pg_trgm(보류) + leaked password(Dashboard)
-- ════════════════════════════════════════════════════════════════
-- 다음 단계:
--   1. Supabase Dashboard → Authentication → Providers → Email
--      → "Leaked password protection" 토글 ON (1건 해결)
--   2. (선택) pg_trgm 이동 — 인덱스·쿼리 영향 확인 후 별도 마이그레이션
-- ════════════════════════════════════════════════════════════════
