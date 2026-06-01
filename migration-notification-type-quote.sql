-- ═══════════════════════════════════════════════════════════════
-- notification_type enum 누락 값 추가: 'quote' (2026-06-01)
-- ═══════════════════════════════════════════════════════════════
-- 증상: 계약 취소 시 (contract_status 수정 후 다음 단계에서)
--   "invalid input value for enum notification_type: \"quote\"" 에러.
--
-- 원인: notification_type enum이 아래 10개로만 정의됨
--   ('system','service','payment','matching','settlement','chat',
--    'contract','assignment','mutual_match','rate_change')
--   그러나 cancel_contract RPC의 알림 fan-out이 24_알림에
--   notification_type='quote'로 INSERT → enum에 없어 캐스팅 예외.
--   (코드에도 'quote' 사용처가 있으나 enum 정의엔 빠져 있던 잠복 버그)
--
-- 안전성: ADD VALUE IF NOT EXISTS — 비파괴적·멱등. 데이터 영향 없음.
--   ※ 트랜잭션으로 감싸지 않음 (ALTER TYPE ADD VALUE 자동커밋 실행).
--
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- 관련: migration-contract-status-enum-fix.sql (동일 유형 enum 누락)
-- ═══════════════════════════════════════════════════════════════

ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'quote';

-- ─── 검증 ──────────────────────────────────────────────────────
-- SELECT unnest(enum_range(NULL::notification_type))::text;  -- 목록에 'quote' 포함 확인
