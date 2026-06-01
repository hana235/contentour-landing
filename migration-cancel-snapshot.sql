-- ═══════════════════════════════════════════════════════════════
-- 취소 분쟁 대비: 51_취소내역 계약 스냅샷 동결 + 통지 시각 기록 (2026-06-01)
-- ═══════════════════════════════════════════════════════════════
-- 목적:
--   취소 분쟁 시 "취소 당시 계약 조건"을 증거로 보존.
--   기존: contract_id로 live 42_통역계약을 조인 → 계약이 나중에 바뀌면 그때 조건을 잃음.
--   보강: 취소 시점 금액을 51_취소내역에 동결 + 상대방 통지 시각 기록.
--
--   ※ 이미 동결돼 있던 것: exhibition_start(시작일), applied_policy_id(적용 위약금정책),
--     days_remaining / penalty_rate(위약금 근거). → 여기선 '금액'과 '통지시각'만 추가.
--
--   cancel_contract RPC를 수정하지 않고 BEFORE INSERT 트리거로 처리 →
--   어떤 삽입 경로(RPC/클라이언트)든 자동 동결, 향후 경로 추가에도 안전.
--
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- ═══════════════════════════════════════════════════════════════

BEGIN;

-- ─── 1. 컬럼 추가 (멱등) ───────────────────────────────────────
ALTER TABLE "51_취소내역"
  ADD COLUMN IF NOT EXISTS amount_snapshot  integer,      -- 취소 시점 계약 총액(total_amount) 동결
  ADD COLUMN IF NOT EXISTS deposit_snapshot integer,      -- 취소 시점 선결제/계약금(deposit_amount) 동결
  ADD COLUMN IF NOT EXISTS notified_at      timestamptz;  -- 취소 사실 상대방 통지 시각

COMMENT ON COLUMN "51_취소내역".amount_snapshot  IS '취소 시점 계약 총액 동결(분쟁 대비, 계약 변경 무관)';
COMMENT ON COLUMN "51_취소내역".deposit_snapshot IS '취소 시점 선결제/계약금 동결';
COMMENT ON COLUMN "51_취소내역".notified_at      IS '취소 사실 상대방 통지 시각(취소 fan-out 시점)';

-- ─── 2. BEFORE INSERT 트리거: 금액 동결 + 통지 시각 ────────────
-- SECURITY DEFINER + search_path 고정 (Security Advisor 권고 준수)
CREATE OR REPLACE FUNCTION public.freeze_cancellation_snapshot()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $func$
BEGIN
  -- 취소 당시 계약 금액 동결 (이미 명시 값이 있으면 보존)
  IF NEW.amount_snapshot IS NULL OR NEW.deposit_snapshot IS NULL THEN
    SELECT COALESCE(NEW.amount_snapshot,  c.total_amount),
           COALESCE(NEW.deposit_snapshot, c.deposit_amount)
      INTO NEW.amount_snapshot, NEW.deposit_snapshot
      FROM "42_통역계약" c
     WHERE c.id = NEW.contract_id;
  END IF;

  -- 상대방 통지 시각 (취소 fan-out은 취소와 동시에 발생하므로 삽입 시각으로 기록)
  IF NEW.notified_at IS NULL THEN
    NEW.notified_at := now();
  END IF;

  RETURN NEW;
END;
$func$;

DROP TRIGGER IF EXISTS trg_freeze_cancellation_snapshot ON "51_취소내역";
CREATE TRIGGER trg_freeze_cancellation_snapshot
  BEFORE INSERT ON "51_취소내역"
  FOR EACH ROW EXECUTE FUNCTION public.freeze_cancellation_snapshot();

-- 함수 실행 권한: 트리거로만 호출되므로 직접 실행은 막아둠
REVOKE EXECUTE ON FUNCTION public.freeze_cancellation_snapshot() FROM PUBLIC;

COMMIT;

-- ─── 검증 ──────────────────────────────────────────────────────
-- SELECT column_name FROM information_schema.columns
--  WHERE table_name='51_취소내역'
--    AND column_name IN ('amount_snapshot','deposit_snapshot','notified_at');
-- (신규 취소 1건 발생 후) SELECT amount_snapshot, deposit_snapshot, notified_at
--   FROM "51_취소내역" ORDER BY created_at DESC LIMIT 1;
