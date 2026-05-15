-- ═══════════════════════════════════════════════════════════════
-- 적립금 시스템 Phase 8 — 점진 소멸 (회원당 일 1000P 캡) (2026-05-15)
-- ═══════════════════════════════════════════════════════════════
-- 전제: phase1 + phase4 + phase5 + phase7 + cron 적용 완료
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
--
-- 변경 사항:
--   expire_loyalty_points: 회원당 1회 호출에 최대 1000P까지만 차감.
--                          오래된 만료 대상 earn 레코드부터 FIFO로 부분 차감.
--                          earn 레코드가 완전히 소진되면 expired_at = NOW() 기록.
--
-- 결과:
--   cron 'loyalty-daily-expire'이 매일 KST 04:00 1회 호출 → 회원당 매일 1000P 차감.
--   예: 12개월 지난 10,000P 잔액 → 10일에 걸쳐 매일 1000씩 소멸.
--       만료 대상 잔액이 500P면 그날만 500P 차감 후 완료.
--
-- 기존 데이터 영향:
--   없음 — 함수만 교체. 새 컬럼은 DEFAULT 0이라 기존 row에 영향 없음.
-- ═══════════════════════════════════════════════════════════════


-- ─── 1. earn 레코드 부분 만료 추적 컬럼 추가 ────────────────────
ALTER TABLE "31_적립금이력"
    ADD COLUMN IF NOT EXISTS points_expired INTEGER NOT NULL DEFAULT 0;

COMMENT ON COLUMN "31_적립금이력".points_expired IS
    'earn 레코드에서 이미 만료 처리된 누적 P. points와 같아지면 expired_at 기록됨.';


-- ─── 2. expire_loyalty_points: 회원당 일 1000P 캡 + FIFO 점진 소멸 ──
CREATE OR REPLACE FUNCTION expire_loyalty_points()
RETURNS TABLE(processed_users INTEGER, total_expired INTEGER) AS $$
DECLARE
    user_rec RECORD;
    earn_rec RECORD;
    v_balance INTEGER;
    v_daily_cap INTEGER := 1000;
    v_remaining_today INTEGER;
    v_to_expire INTEGER;
    v_record_remaining INTEGER;
    v_users INTEGER := 0;
    v_total INTEGER := 0;
    v_user_deducted INTEGER;
BEGIN
    -- 회원 단위로 루프: 만료 대상이 남아있는 회원만
    FOR user_rec IN
        SELECT DISTINCT user_id
        FROM "31_적립금이력"
        WHERE type = 'earn'
          AND expired_at IS NULL
          AND expires_at IS NOT NULL
          AND expires_at < NOW()
          AND (points - points_expired) > 0
    LOOP
        -- 현재 잔액 락
        SELECT balance INTO v_balance
        FROM "30_적립금"
        WHERE user_id = user_rec.user_id
        FOR UPDATE;

        IF v_balance IS NULL OR v_balance <= 0 THEN
            -- 잔액 없으면 earn 레코드를 그대로 만료 처리 (정리)
            UPDATE "31_적립금이력"
            SET expired_at = NOW()
            WHERE user_id = user_rec.user_id
              AND type = 'earn'
              AND expired_at IS NULL
              AND expires_at IS NOT NULL
              AND expires_at < NOW();
            CONTINUE;
        END IF;

        v_remaining_today := v_daily_cap;
        v_user_deducted := 0;

        -- 한 회원의 만료 대상 earn 레코드를 오래된 순으로 FIFO 처리
        FOR earn_rec IN
            SELECT id, (points - points_expired) AS record_remaining
            FROM "31_적립금이력"
            WHERE user_id = user_rec.user_id
              AND type = 'earn'
              AND expired_at IS NULL
              AND expires_at IS NOT NULL
              AND expires_at < NOW()
              AND (points - points_expired) > 0
            ORDER BY expires_at ASC, id ASC
            FOR UPDATE
        LOOP
            EXIT WHEN v_remaining_today <= 0;
            EXIT WHEN v_balance <= 0;

            v_to_expire := LEAST(earn_rec.record_remaining, v_balance, v_remaining_today);

            -- earn 레코드 부분 만료 업데이트 (다 차면 expired_at 기록)
            UPDATE "31_적립금이력"
            SET points_expired = points_expired + v_to_expire,
                expired_at = CASE
                    WHEN (points_expired + v_to_expire) >= points THEN NOW()
                    ELSE NULL
                END
            WHERE id = earn_rec.id;

            v_remaining_today := v_remaining_today - v_to_expire;
            v_balance := v_balance - v_to_expire;
            v_user_deducted := v_user_deducted + v_to_expire;
        END LOOP;

        -- 잔액 차감 + 이력 1줄 (당일 회원당 1줄)
        IF v_user_deducted > 0 THEN
            UPDATE "30_적립금"
            SET balance = balance - v_user_deducted
            WHERE user_id = user_rec.user_id;

            INSERT INTO "31_적립금이력"
                (user_id, type, points, source_type, reason, balance_after)
            VALUES
                (user_rec.user_id, 'expire', -v_user_deducted, 'auto_expire_drip',
                 '12개월 만료 점진 소멸 (일 최대 ' || v_daily_cap || 'P)',
                 v_balance);

            v_total := v_total + v_user_deducted;
            v_users := v_users + 1;
        END IF;
    END LOOP;

    processed_users := v_users;
    total_expired := v_total;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ═══════════════════════════════════════════════════════════════
-- 검증 쿼리
-- ═══════════════════════════════════════════════════════════════
-- 1) 컬럼 추가 확인
--    SELECT column_name, data_type, column_default
--    FROM information_schema.columns
--    WHERE table_name = '31_적립금이력' AND column_name = 'points_expired';
--
-- 2) 함수 정의에 'daily_cap' 또는 'auto_expire_drip' 들어갔는지
--    SELECT prosrc FROM pg_proc WHERE proname = 'expire_loyalty_points';
--
-- 3) 수동 1회 실행 — 만료 대상 없으면 0/0
--    SELECT * FROM expire_loyalty_points();
--
-- 4) 점진 만료 이력 확인 (당일 발생분)
--    SELECT user_id, points, reason, balance_after, created_at
--    FROM "31_적립금이력"
--    WHERE type = 'expire' AND source_type = 'auto_expire_drip'
--      AND created_at >= CURRENT_DATE
--    ORDER BY created_at DESC;
-- ═══════════════════════════════════════════════════════════════
