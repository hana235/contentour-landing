-- ============================================================================
-- 배정 미응답 자동 리마인더 (pg_cron) — 통역사·관리자 자동 알림 (2026-06-30)
-- ----------------------------------------------------------------------------
-- respond_by가 지났는데 통역사가 수락/거절을 안 한 배정을 주기적으로 감지해
-- 통역사(독촉) + 관리자(재배정 검토)에게 24_알림을 자동 발송한다.
-- 같은 건은 24h에 한 번만 발송(last_reminder_at로 스로틀). respond_by는 건드리지 않아
-- admin 미응답 목록에 계속 노출됨(수락/거절 시 자동 해소).
--
-- 의존: migration-assign-respond-by.sql (respond_by 컬럼) 먼저 적용돼 있어야 함.
-- 멱등: ADD COLUMN IF NOT EXISTS / CREATE OR REPLACE / unschedule 후 schedule.
-- ============================================================================

-- ─── 1. 마지막 자동 리마인더 시각 컬럼 (스로틀용) ───────────────────────────
ALTER TABLE "42_통역계약" ADD COLUMN IF NOT EXISTS last_reminder_at timestamptz;

-- ─── 2. 미응답 배정 감지·알림 함수 ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_overdue_assignments()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    r       RECORD;
    v_count integer := 0;
BEGIN
    FOR r IN
        SELECT c.id, c.interpreter_id, c.exhibition_name, c.client_company
          FROM "42_통역계약" c
         WHERE c.interpreter_id IS NOT NULL
           AND c.interpreter_accepted IS NULL
           AND c.status = 'pending'
           AND c.respond_by IS NOT NULL
           AND c.respond_by < now()
           AND (c.last_reminder_at IS NULL OR c.last_reminder_at < now() - interval '24 hours')
    LOOP
        -- 통역사 독촉
        INSERT INTO "24_알림" (user_id, notification_type, title, message, is_read)
        VALUES (r.interpreter_id, 'assignment', '⏰ 배정 응답 요청',
                '"' || COALESCE(r.exhibition_name, '배정') || '" 배정 건의 응답 기한이 지났습니다. 수락 또는 거절을 진행해주세요.', false);

        -- 관리자 전원 (재배정 검토)
        INSERT INTO "24_알림" (user_id, notification_type, title, message, is_read)
        SELECT m.id, 'assignment', '⏰ 통역사 미응답',
               '"' || COALESCE(r.exhibition_name, '배정') || '" (' || COALESCE(r.client_company, '고객사') || ') 배정에 통역사가 응답하지 않았습니다. 재배정을 검토해주세요.', false
          FROM "01_회원" m
         WHERE m.role = 'admin';

        UPDATE "42_통역계약" SET last_reminder_at = now() WHERE id = r.id;
        v_count := v_count + 1;
    END LOOP;
    RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.notify_overdue_assignments IS
'배정 응답 기한 초과·미수락 건을 감지해 통역사·관리자에게 24_알림 발송(24h 스로틀). pg_cron으로 주기 실행.';

-- ════════════════════════════════════════════════════════════════════════════
-- ※ 아래 3단계는 pg_cron 확장이 켜져 있어야 동작한다.
--   Supabase Dashboard → Database → Extensions → "pg_cron" 토글 ON 후 실행할 것.
--   (확장이 꺼진 상태면 cron 스키마가 없어 에러 — 위 1·2단계 함수는 그래도 적용됨)
-- ════════════════════════════════════════════════════════════════════════════

-- ─── 3. 매시 정각 스케줄 등록 (재실행 안전: 기존 잡 제거 후 재등록) ──────────
DO $$
BEGIN
    PERFORM cron.unschedule('notify-overdue-assignments');
EXCEPTION WHEN OTHERS THEN
    NULL; -- 잡이 없거나 pg_cron 미설치면 무시
END $$;

SELECT cron.schedule(
    'notify-overdue-assignments',
    '0 * * * *',                                   -- 매시 정각 (원하면 '0 9,15,21 * * *' 등으로 조정)
    $cron$ SELECT public.notify_overdue_assignments(); $cron$
);

-- 확인:
--   SELECT jobname, schedule, active FROM cron.job WHERE jobname = 'notify-overdue-assignments';
--   SELECT public.notify_overdue_assignments();  -- 수동 1회 실행(즉시 테스트)
--   SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 5;  -- 실행 이력
