-- ═══════════════════════════════════════════════════════════════
-- notification_type enum 완성: 'marketing' + 'points' 추가 (2026-06-01)
-- ═══════════════════════════════════════════════════════════════
-- 근본 원인(확정):
--   migration-notif-settings-enforce.sql의 24_알림 BEFORE INSERT 트리거가
--   아래 CASE로 notification_type을 분기:
--     CASE NEW.notification_type
--       WHEN 'payment' WHEN 'chat' WHEN 'assignment' WHEN 'quote'
--       WHEN 'service' WHEN 'marketing' WHEN 'points' ...
--   Postgres가 WHEN 리터럴을 notification_type enum으로 캐스팅하는데
--   enum에 없는 값('quote'→해결, 'marketing','points'→여기서 해결)에서
--   "invalid input value for enum notification_type" 예외 발생.
--   → 이 트리거는 모든 24_알림 INSERT에 걸리므로 계약 취소 알림 등에서 연쇄 실패.
--
--   CASE가 참조하는 7개 타입 중 enum에 빠진 마지막 2개가 marketing·points.
--   이 둘을 추가하면 CASE의 모든 리터럴이 유효 → 알림 INSERT 정상화 (whack-a-mole 종료).
--
-- 안전성: ADD VALUE IF NOT EXISTS — 비파괴적·멱등.
--   ※ 트랜잭션으로 감싸지 않음 (ALTER TYPE ADD VALUE 자동커밋).
--
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- 관련: migration-notification-type-quote.sql, migration-contract-status-enum-fix.sql
-- ═══════════════════════════════════════════════════════════════

ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'marketing';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'points';

-- ─── 검증 ──────────────────────────────────────────────────────
-- SELECT unnest(enum_range(NULL::notification_type))::text;
--   → enforce 트리거 CASE의 7개(payment,chat,assignment,quote,service,marketing,points) 모두 포함되어야 함
