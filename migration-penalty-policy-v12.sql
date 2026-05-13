-- ═══════════════════════════════════════════════════════════════
-- 위약금 정책 v1.2 정합화 + calculate_penalty RPC penalty_base 분기 (2026-05-12)
-- ═══════════════════════════════════════════════════════════════
-- 목적:
--   1. 50_위약금정책 customer 5행을 약관 v1.2의 4구간으로 정렬
--      (D-30/D-29~D-14/D-13~D-8/D-7~D-0)
--   2. calculate_penalty RPC가 penalty_base 컬럼을 읽어
--      deposit_amount / total_amount 분기하도록 수정
--
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- ═══════════════════════════════════════════════════════════════

BEGIN;

-- ─── 1. 50_위약금정책 customer 행 4구간으로 재정렬 ────────────────
-- 기존 5행 중 4행은 UPDATE, 1행(D-0 단독)은 (d)에 흡수되어 무력화
-- 무력화는 DELETE 대신 min/max=-999로 두어 FK 안전 + 이력 추적 가능

-- (a) D-30~9999 (rate=0, base=deposit) ← 기존 (min=14, max=9999)
UPDATE "50_위약금정책"
SET min_days = 30,
    max_days = 9999,
    penalty_rate = 0,
    penalty_base = 'deposit',
    description = '30일 이전 취소: 전액 환불'
WHERE cancel_type = 'customer'
  AND min_days = 14
  AND max_days = 9999;

-- (b) D-14~D-29 (rate=50, base=deposit) ← 기존 (min=7, max=13)
UPDATE "50_위약금정책"
SET min_days = 14,
    max_days = 29,
    penalty_rate = 50,
    penalty_base = 'deposit',
    description = '29~14일 전 취소: 계약금 50% 차감'
WHERE cancel_type = 'customer'
  AND min_days = 7
  AND max_days = 13;

-- (c) D-8~D-13 (rate=100, base=deposit, "계약금 환불 불가") ← 기존 (min=3, max=6)
UPDATE "50_위약금정책"
SET min_days = 8,
    max_days = 13,
    penalty_rate = 100,
    penalty_base = 'deposit',
    description = '13~8일 전 취소: 계약금 환불 불가'
WHERE cancel_type = 'customer'
  AND min_days = 3
  AND max_days = 6;

-- (d) D-0~D-7 (rate=50, base=total, "총 계약금액 50%") ← 기존 (min=1, max=2)
UPDATE "50_위약금정책"
SET min_days = 0,
    max_days = 7,
    penalty_rate = 50,
    penalty_base = 'total',
    description = '7일~당일 취소: 총 계약금액 50% 위약금'
WHERE cancel_type = 'customer'
  AND min_days = 1
  AND max_days = 2;

-- (e) 기존 D-0 단독 row 무력화 — (d)에 흡수됨
UPDATE "50_위약금정책"
SET min_days = -999,
    max_days = -999,
    penalty_rate = 0,
    description = '[deprecated v1.2] 당일 100% → 7일~당일 50%(d)로 흡수됨'
WHERE cancel_type = 'customer'
  AND min_days = 0
  AND max_days = 0;


-- ─── 2. calculate_penalty RPC: penalty_base 분기 + deposit_amount 사용 ─
CREATE OR REPLACE FUNCTION public.calculate_penalty(
    p_contract_id uuid,
    p_cancelled_by text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_start date;
    v_total numeric;
    v_deposit numeric;
    v_days int;
    v_policy uuid;
    v_rate numeric;
    v_base text;
    v_base_amount numeric;
    v_penalty numeric;
    v_refund numeric;
    v_description text;
    v_interp_action text;
BEGIN
    -- deposit_amount가 0/NULL이면 total_amount로 대체 (A안 100% 선결제 호환)
    SELECT start_date,
           total_amount,
           COALESCE(NULLIF(deposit_amount, 0), total_amount)
      INTO v_start, v_total, v_deposit
    FROM "42_통역계약"
    WHERE id = p_contract_id;

    IF v_start IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', '계약을 찾을 수 없습니다.');
    END IF;

    v_days := v_start - CURRENT_DATE;

    SELECT id, penalty_rate, penalty_base, description, interpreter_action
      INTO v_policy, v_rate, v_base, v_description, v_interp_action
    FROM "50_위약금정책"
    WHERE cancel_type = p_cancelled_by
      AND v_days >= min_days
      AND (max_days IS NULL OR v_days <= max_days)
    ORDER BY min_days DESC
    LIMIT 1;

    IF v_rate IS NULL THEN
        v_rate := 0;
        v_base := 'total';
        v_description := COALESCE(v_description, '해당 정책 없음');
    END IF;

    -- penalty_base에 따라 base 금액 결정
    IF v_base = 'total' THEN
        v_base_amount := v_total;
    ELSE
        v_base_amount := v_deposit;
    END IF;

    v_penalty := round(v_base_amount * v_rate / 100);
    -- 환불액 = 고객이 실제 지불한 총액 - 위약금
    v_refund := v_total - v_penalty;
    IF v_refund < 0 THEN v_refund := 0; END IF;

    RETURN jsonb_build_object(
        'success', true,
        'policy_id', v_policy,
        'days_remaining', v_days,
        'penalty_rate', v_rate,
        'penalty_base', v_base,
        'penalty_amount', v_penalty,
        'refund_amount', v_refund,
        'description', v_description,
        'interpreter_action', v_interp_action
    );
END
$function$;

COMMIT;

-- ═══════════════════════════════════════════════════════════════
-- 검증 쿼리 (트랜잭션 적용 후 실행)
-- ═══════════════════════════════════════════════════════════════
--
-- ① 정책 4구간 정렬 확인
-- SELECT cancel_type, min_days, max_days, penalty_rate, penalty_base, description
--   FROM "50_위약금정책"
--  WHERE cancel_type = 'customer' AND min_days >= 0
--  ORDER BY min_days DESC;
--
-- 예상 결과:
--   30  9999 0   deposit  30일 이전 취소: 전액 환불
--   14  29   50  deposit  29~14일 전 취소: 계약금 50% 차감
--   8   13   100 deposit  13~8일 전 취소: 계약금 환불 불가
--   0   7    50  total    7일~당일 취소: 총 계약금액 50% 위약금
--
-- ② RPC 동작 확인 — 임의 계약 ID로 경계 케이스 호출
--    (Supabase SQL Editor에서 실제 계약 한 건의 id를 넣어 실행)
-- SELECT calculate_penalty('<contract-uuid>', 'customer');
--
-- ③ 옛 10/90 계약(deposit_amount != total_amount)에서 D-10 시뮬레이션
--   기대: penalty_rate=100, penalty_base=deposit,
--         penalty_amount = deposit_amount,
--         refund_amount  = total_amount - deposit_amount (= balance_amount)
--
-- ═══════════════════════════════════════════════════════════════
