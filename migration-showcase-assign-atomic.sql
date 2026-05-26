-- ════════════════════════════════════════════════════════════════
-- migration: showcase_assign_atomic
-- 목적: showcaseAssign (공고 매칭 확정)의 4단계 INSERT/UPDATE를
--       단일 트랜잭션으로 묶어 부분 실패 시 전체 롤백 보장.
--
-- 기존 흐름 (api/admin-app.js):
--   1) 42_통역계약 INSERT  (에러 처리됨)
--   2) 46_ITQ견적문의 UPDATE  (에러 무시 → 상태 불일치 위험)
--   3) 70_구인공고지원 UPDATE 매칭됨  (에러 무시)
--   4) 70_구인공고지원 UPDATE 나머지 거절  (에러 무시)
--
-- 적용 후: 1~4를 한 트랜잭션으로 처리, 하나라도 실패하면 모두 롤백.
-- 알림(24_알림) · 감사로그(99_감사로그)는 best-effort이므로 RPC 밖에 유지.
--
-- 클라이언트는 이 함수가 없으면 자동 fallback (단계별 처리) — backward compat.
-- ════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.showcase_assign_atomic(
    p_posting_id           UUID,
    p_interpreter_id       UUID,
    p_daily_rate           NUMERIC,
    p_memo                 TEXT,
    p_interpreter_display  TEXT
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_posting        RECORD;
    v_days           INT;
    v_total          NUMERIC;
    v_customer_id    UUID;
    v_contract_id    UUID;
BEGIN
    -- 1) posting 조회
    SELECT *
      INTO v_posting
      FROM "46_ITQ견적문의"
     WHERE id = p_posting_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'posting not found: %', p_posting_id;
    END IF;

    -- 2) 일수 계산
    v_days := 1;
    IF v_posting.start_date IS NOT NULL AND v_posting.end_date IS NOT NULL THEN
        v_days := GREATEST(1, (v_posting.end_date - v_posting.start_date) + 1);
    END IF;
    v_total := COALESCE(p_daily_rate, 0) * v_days;
    v_customer_id := COALESCE(v_posting.posted_by_user_id, v_posting.user_id);

    -- 3) 계약 생성
    INSERT INTO "42_통역계약" (
        order_id, customer_id, interpreter_id,
        exhibition_name, client_company, venue,
        start_date, end_date, working_days,
        language_pair, service_type,
        daily_rate, total_amount, tax_amount, net_amount,
        status
    ) VALUES (
        p_posting_id, v_customer_id, p_interpreter_id,
        COALESCE(v_posting.exhibition_name, ''),
        COALESCE(v_posting.company, ''),
        COALESCE(v_posting.venue, v_posting.location, ''),
        v_posting.start_date, v_posting.end_date, v_days,
        COALESCE(v_posting.language_pair, ''), 'OTHER',
        p_daily_rate, v_total, ROUND(v_total * 0.1), v_total,
        'pending'
    )
    RETURNING id INTO v_contract_id;

    -- 4) 견적문의 → 계약진행
    UPDATE "46_ITQ견적문의"
       SET contract_id = v_contract_id,
           status      = '계약진행',
           admin_note  = jsonb_build_object(
                             'interpreter',   p_interpreter_display,
                             'interpreterId', p_interpreter_id,
                             'memo',          COALESCE(p_memo, '')
                         )::text
     WHERE id = p_posting_id;

    -- 5) 지원자 → 매칭 확정
    UPDATE "70_구인공고지원"
       SET status      = 'matched',
           contract_id = v_contract_id
     WHERE posting_id     = p_posting_id
       AND interpreter_id = p_interpreter_id;

    -- 6) 나머지 지원자 → 거절
    UPDATE "70_구인공고지원"
       SET status = 'declined'
     WHERE posting_id     = p_posting_id
       AND interpreter_id <> p_interpreter_id
       AND status IN ('pending', 'forwarded');

    RETURN v_contract_id;
END;
$$;

-- 권한: service_role만 호출 가능 (API 서버에서만 사용)
REVOKE ALL ON FUNCTION public.showcase_assign_atomic(UUID, UUID, NUMERIC, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.showcase_assign_atomic(UUID, UUID, NUMERIC, TEXT, TEXT) FROM anon;
REVOKE ALL ON FUNCTION public.showcase_assign_atomic(UUID, UUID, NUMERIC, TEXT, TEXT) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.showcase_assign_atomic(UUID, UUID, NUMERIC, TEXT, TEXT) TO service_role;

COMMENT ON FUNCTION public.showcase_assign_atomic IS
'공고 매칭 확정 — 계약 생성 + 견적 갱신 + 지원자 상태 갱신을 단일 트랜잭션으로 처리. (api/admin-app.js showcaseAssign 액션이 호출)';
