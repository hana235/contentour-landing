-- ═══════════════════════════════════════════════════════════════
-- 42_통역계약 REPLICA IDENTITY FULL 적용 (2026-05-18)
-- ═══════════════════════════════════════════════════════════════
-- 목적:
--   admin-dashboard.html의 subscribeAdminGlobalRealtime()이
--   42_통역계약 UPDATE 이벤트 수신 시 oldRow.status, oldRow.deposit_status,
--   oldRow.cancelled_at, oldRow.interpreter_id 등을 newRow와 비교해
--   변경 종류별 토스트를 띄움.
--
--   기본 REPLICA IDENTITY는 'default'라 payload.old에 PK(id)만 포함됨
--   → 비-PK 컬럼 비교가 항상 undefined와 비교 → 잘못된 토스트가 매번 표시됨.
--
--   FULL로 변경하면 payload.old에 모든 컬럼이 포함되어 비교 로직 정상 작동.
--
-- 부작용:
--   - WAL(Write-Ahead Log) 크기 약간 증가 (UPDATE 시 전체 row 기록)
--   - 42_통역계약은 트래픽 작아서 (하루 수십~수백 UPDATE) 부담 무시 가능
--
-- 멱등: ALTER TABLE은 항상 재실행 안전
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE "42_통역계약" REPLICA IDENTITY FULL;

-- 검증:
-- SELECT c.relname, c.relreplident
-- FROM pg_class c
-- JOIN pg_namespace n ON n.oid = c.relnamespace
-- WHERE n.nspname = 'public' AND c.relname = '42_통역계약';
-- → relreplident = 'f' (full)
