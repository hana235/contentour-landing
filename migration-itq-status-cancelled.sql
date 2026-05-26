-- ════════════════════════════════════════════════════════════════
-- migration: itq_status enum에 '취소됨' 값 추가
-- 문제: customer-dashboard.html 견적 문의 취소 시 api/submit.js handleCancelInquiry가
--       46_ITQ견적문의.status를 '취소됨'으로 UPDATE → enum 값 부재로 500 에러
-- 해결: enum에 '취소됨' 값 추가 (ADD VALUE IF NOT EXISTS — 멱등)
-- ════════════════════════════════════════════════════════════════

ALTER TYPE itq_status ADD VALUE IF NOT EXISTS '취소됨';

-- 확인용 (실행 후 enum 값 목록)
-- SELECT enumlabel FROM pg_enum WHERE enumtypid = 'itq_status'::regtype ORDER BY enumsortorder;
