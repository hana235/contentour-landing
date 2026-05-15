-- ═══════════════════════════════════════════════════════════════
-- 적립금 시스템 Phase 9 — 12개월 보관 수수료 1회 1000P (2026-05-15)
-- ═══════════════════════════════════════════════════════════════
-- 전제: phase1 + phase4 + phase5 + phase7 + cron 적용 완료
--       (phase8 SQL은 실행하지 않은 상태에서 phase9로 갈음)
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
--
-- 정책:
--   각 적립 건이 12개월 도달 시 → 잔액에서 1000P 1회 차감.
--   해당 적립 건은 즉시 expired_at = NOW() 마킹 (재처리 X).
--   잔여 적립금은 영구 보존 (만료 더 이상 없음).
--
--   적립 건이 1000P 미만이면 LEAST(1000, points, balance)만큼만 차감.
--   잔액이 1000P 미만이면 잔액만큼만 차감.
--
-- 예시:
--   적립 10,000P → 12개월 도달 → -1,000P → 잔액 9,000P 영구 보존
--   적립    500P → 12개월 도달 → -  500P → 잔액 0P
--
-- 매일 KST 04:00 cron 'loyalty-daily-expire'이 이 함수 호출.
-- 같은 적립 건은 expired_at 마킹 후 재호출돼도 처리되지 않음 (멱등).
-- ═══════════════════════════════════════════════════════════════


CREATE OR REPLACE FUNCTION expire_loyalty_points()
RETURNS TABLE(processed_users INTEGER, total_expired INTEGER) AS $$
DECLARE
    earn_rec RECORD;
    v_balance INTEGER;
    v_deduct INTEGER;
    v_users UUID[] := ARRAY[]::UUID[];
    v_total INTEGER := 0;
BEGIN
    -- 12개월 도달했으나 아직 만료 처리 안 된 earn 레코드를 한 건씩 처리
    FOR earn_rec IN
        SELECT id, user_id, points
        FROM "31_적립금이력"
        WHERE type = 'earn'
          AND expired_at IS NULL
          AND expires_at IS NOT NULL
          AND expires_at < NOW()
        ORDER BY expires_at ASC, id ASC
    LOOP
        -- 회원 잔액 락
        SELECT balance INTO v_balance
        FROM "30_적립금"
        WHERE user_id = earn_rec.user_id
        FOR UPDATE;

        IF v_balance IS NULL THEN
            v_balance := 0;
        END IF;

        -- 차감액 결정: 1000P 또는 적립 건 자체 크기 또는 현재 잔액 중 가장 작은 값
        v_deduct := LEAST(1000, earn_rec.points, v_balance);

        IF v_deduct > 0 THEN
            -- 잔액 차감
            UPDATE "30_적립금"
            SET balance = balance - v_deduct
            WHERE user_id = earn_rec.user_id;

            v_balance := v_balance - v_deduct;
            v_total := v_total + v_deduct;

            -- 이력 1줄 (감사용)
            INSERT INTO "31_적립금이력"
                (user_id, type, points, source_type, reason, balance_after)
            VALUES
                (earn_rec.user_id, 'expire', -v_deduct, 'auto_expire_fee',
                 '12개월 보관 수수료 (-' || v_deduct || 'P, 적립 ID ' || earn_rec.id || ' 잔여 영구 보존)',
                 v_balance);
        END IF;

        -- earn 레코드는 차감 여부 무관하게 즉시 만료 마킹 (재처리 방지)
        UPDATE "31_적립금이력"
        SET expired_at = NOW()
        WHERE id = earn_rec.id;

        -- 처리된 회원 카운트
        IF NOT (earn_rec.user_id = ANY(v_users)) THEN
            v_users := v_users || earn_rec.user_id;
        END IF;
    END LOOP;

    processed_users := COALESCE(array_length(v_users, 1), 0);
    total_expired := v_total;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ═══════════════════════════════════════════════════════════════
-- 검증 쿼리
-- ═══════════════════════════════════════════════════════════════
-- 1) 함수 본문에 'auto_expire_fee' 있는지 확인
--    SELECT prosrc FROM pg_proc WHERE proname = 'expire_loyalty_points';
--
-- 2) 수동 실행 — 만료 대상 없으면 0/0
--    SELECT * FROM expire_loyalty_points();
--
-- 3) 보관 수수료 이력 (있는 경우)
--    SELECT user_id, points, reason, balance_after, created_at
--    FROM "31_적립금이력"
--    WHERE type = 'expire' AND source_type = 'auto_expire_fee'
--    ORDER BY created_at DESC LIMIT 20;
-- ═══════════════════════════════════════════════════════════════
