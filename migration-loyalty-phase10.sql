-- ═══════════════════════════════════════════════════════════════
-- 적립금 시스템 Phase 10 — 회원당 연 1회 -1000P (2026-05-15)
-- ═══════════════════════════════════════════════════════════════
-- 전제: phase1 + phase4 + phase5 + phase7 + cron + phase9 적용 완료
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
--
-- 정책 (사용자 결정):
--   회원당 1년에 1번 -1000P 보관 수수료. 적립 건수와 무관.
--   기준점(anchor):
--     - 이전에 annual_fee 차감 기록이 있으면: 가장 최근 차감일
--     - 없으면: 가입일 (01_회원.created_at)
--   다음 차감 시점 = anchor + 12개월. NOW() >= 다음 차감 시점이면 차감.
--   잔액 < 1000P면 잔액만큼만 차감. 잔액 0이면 처리 안 함(다음 적립 후 재평가).
--
-- earn 레코드의 expires_at, expired_at는 더 이상 의미 없음 (Phase 9까지의 잔재).
-- 본 함수는 그 컬럼들을 참조하지 않음.
-- ═══════════════════════════════════════════════════════════════


CREATE OR REPLACE FUNCTION expire_loyalty_points()
RETURNS TABLE(processed_users INTEGER, total_expired INTEGER) AS $$
DECLARE
    user_rec RECORD;
    v_balance INTEGER;
    v_account_created TIMESTAMPTZ;
    v_last_fee_date TIMESTAMPTZ;
    v_anchor TIMESTAMPTZ;
    v_due_date TIMESTAMPTZ;
    v_deduct INTEGER;
    v_users INTEGER := 0;
    v_total INTEGER := 0;
BEGIN
    FOR user_rec IN
        SELECT user_id, balance
        FROM "30_적립금"
        WHERE balance > 0
        ORDER BY user_id
        FOR UPDATE
    LOOP
        v_balance := user_rec.balance;

        SELECT created_at INTO v_account_created
        FROM "01_회원"
        WHERE id = user_rec.user_id;

        IF v_account_created IS NULL THEN CONTINUE; END IF;

        SELECT MAX(created_at) INTO v_last_fee_date
        FROM "31_적립금이력"
        WHERE user_id = user_rec.user_id
          AND source_type = 'annual_fee';

        v_anchor := COALESCE(v_last_fee_date, v_account_created);
        v_due_date := v_anchor + INTERVAL '12 months';

        IF NOW() < v_due_date THEN CONTINUE; END IF;

        v_deduct := LEAST(1000, v_balance);

        IF v_deduct <= 0 THEN CONTINUE; END IF;

        UPDATE "30_적립금"
        SET balance = balance - v_deduct
        WHERE user_id = user_rec.user_id;

        INSERT INTO "31_적립금이력"
            (user_id, type, points, source_type, reason, balance_after)
        VALUES
            (user_rec.user_id, 'expire', -v_deduct, 'annual_fee',
             '연간 보관 수수료 (-' || v_deduct || 'P, 가입일 기준 매년)',
             v_balance - v_deduct);

        v_users := v_users + 1;
        v_total := v_total + v_deduct;
    END LOOP;

    processed_users := v_users;
    total_expired := v_total;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ═══════════════════════════════════════════════════════════════
-- 검증 쿼리
-- ═══════════════════════════════════════════════════════════════
-- 1) 함수 본문 확인
--    SELECT prosrc FROM pg_proc WHERE proname = 'expire_loyalty_points';
--
-- 2) 수동 1회 실행
--    SELECT * FROM expire_loyalty_points();
--    → 가입 후 12개월 안 된 회원만 있으면 0/0
--
-- 3) 특정 회원의 다음 차감 시점 예상
--    SELECT
--      m.id, m.email, m.created_at AS account_created,
--      MAX(h.created_at) FILTER (WHERE h.source_type='annual_fee') AS last_fee,
--      COALESCE(MAX(h.created_at) FILTER (WHERE h.source_type='annual_fee'), m.created_at)
--        + INTERVAL '12 months' AS next_due
--    FROM "01_회원" m
--    LEFT JOIN "31_적립금이력" h ON h.user_id = m.id
--    WHERE m.id = '<user-uuid>'
--    GROUP BY m.id;
--
-- 4) 연간 수수료 이력
--    SELECT user_id, points, reason, balance_after, created_at
--    FROM "31_적립금이력"
--    WHERE source_type = 'annual_fee'
--    ORDER BY created_at DESC LIMIT 30;
-- ═══════════════════════════════════════════════════════════════
