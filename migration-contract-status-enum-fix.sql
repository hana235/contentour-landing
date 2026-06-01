-- ═══════════════════════════════════════════════════════════════
-- contract_status enum 누락 값 추가: balance_paid / paid / refunded (2026-06-01)
-- ═══════════════════════════════════════════════════════════════
-- 증상: 고객사·통역사 계약 취소 시
--   "invalid input value for enum contract_status: \"balance_paid\"" 에러로 전면 실패.
--
-- 원인: contract_status enum이 아래 6개로만 정의돼 있었음
--   ('pending','deposit_paid','in_progress','completed','settled','cancelled')
--   그러나 시스템은 다음 값들을 contract_status로 참조/대입함:
--     - cancel_contract RPC      : 상태 분기에서 'balance_paid' 비교
--     - payment-columns-protection 트리거(59행):
--         NEW.status IN ('deposit_paid','balance_paid','paid','settled','refunded')
--         → 상태 변경 시마다 평가 → 첫 무효 라벨 'balance_paid'에서 예외
--     - api/payment.js:183       : 잔금 결제 시 status='balance_paid'
--   → enum에 없는 라벨이라 캐스팅 단계에서 예외 발생.
--
-- 영향 범위: 계약 취소 전면 차단 + 옛 10/90 계약 잔금결제 실패(잠복).
--   (100% 선결제가 기본이라 잔금결제 경로는 여태 안 드러났던 것)
--
-- 안전성: ADD VALUE IF NOT EXISTS — 비파괴적·멱등. 기존 데이터/행 영향 없음.
--   ※ 트랜잭션으로 감싸지 않음(ALTER TYPE ADD VALUE는 자동커밋으로 순차 실행 권장).
--     또한 같은 트랜잭션에서 추가한 라벨을 AFTER 참조하면 실패하므로 분리 실행.
--
-- 적용처: Supabase Dashboard → SQL Editor → Run (한 번에 실행)
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- ═══════════════════════════════════════════════════════════════

ALTER TYPE contract_status ADD VALUE IF NOT EXISTS 'balance_paid' AFTER 'deposit_paid';
ALTER TYPE contract_status ADD VALUE IF NOT EXISTS 'paid'         AFTER 'balance_paid';
ALTER TYPE contract_status ADD VALUE IF NOT EXISTS 'refunded'     AFTER 'cancelled';

-- ─── 검증 ──────────────────────────────────────────────────────
-- SELECT unnest(enum_range(NULL::contract_status))::text AS status_values;
--   → pending, deposit_paid, balance_paid, paid, in_progress, completed, settled, cancelled, refunded
