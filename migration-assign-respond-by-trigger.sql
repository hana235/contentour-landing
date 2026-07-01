-- ============================================================================
-- 배정 응답기한(respond_by) 전 경로 공통화 트리거 (2026-07-01)
-- ----------------------------------------------------------------------------
-- 문제: respond_by(통역사 수락/거절 48h 기한)가 api/assign.js 경로에서만 설정됐다.
--       나머지 배정 경로 3종 —
--         · showcase 배정 (api/admin-app.js / showcase_assign_atomic)
--         · 수동계약 생성 (api/admin-app.js)
--         · 견적수락 (api/my.js handleAcceptQuote)
--       은 interpreter_id를 채우면서 respond_by를 안 넣어, 미응답 감지·리마인더
--       (notify_overdue_assignments, respond_by IS NOT NULL 조건)에 영원히 안 잡혔다.
--
-- 해결: 배정 상태 규칙을 DB 트리거로 중앙화 — "미수락 배정 건은 반드시 respond_by를 갖는다".
--   · interpreter_id 있고 아직 미응답(interpreter_accepted IS NULL) → respond_by 없으면 48h 부여
--   · 수락/거절됐거나(interpreter_accepted NOT NULL) 배정 해제(interpreter_id NULL)
--       → respond_by·last_reminder_at 초기화 (재배정 시 새 기한이 깨끗하게 붙도록)
--   모든 INSERT/UPDATE 경로(현재 4종 + 향후 추가분)를 자동 커버.
--
-- 의존: respond_by 컬럼(migration-assign-respond-by.sql), last_reminder_at 컬럼
--       (migration-assign-auto-reminder.sql) 먼저 적용돼 있어야 함.
-- 멱등: CREATE OR REPLACE + DROP TRIGGER IF EXISTS.
-- 참고: api/assign.js:166-172(4b)의 명시적 respond_by 설정은 트리거와 중복이나 무해
--       (트리거 미적용 환경에서도 assign 경로는 동작하도록 유지).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_assignment_respond_by()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.interpreter_id IS NOT NULL AND NEW.interpreter_accepted IS NULL THEN
        -- 미응답 배정: 응답 기한이 없으면 48h 부여
        IF NEW.respond_by IS NULL THEN
            NEW.respond_by := now() + interval '48 hours';
        END IF;
    ELSE
        -- 수락/거절 완료 or 배정 해제: 기한·리마인더 스로틀 초기화
        NEW.respond_by := NULL;
        NEW.last_reminder_at := NULL;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_42_통역계약_respond_by ON "42_통역계약";
CREATE TRIGGER trg_42_통역계약_respond_by
    BEFORE INSERT OR UPDATE ON "42_통역계약"
    FOR EACH ROW
    EXECUTE FUNCTION public.set_assignment_respond_by();

COMMENT ON FUNCTION public.set_assignment_respond_by IS
'미수락 배정 건에 respond_by(48h)를 전 경로 공통 부여, 수락/거절·해제 시 초기화. 미응답 감지·리마인더가 모든 배정 경로를 커버하도록 중앙화.';

-- 검증:
--   1) 견적수락/수동계약/showcase 배정으로 만든 계약에 respond_by가 채워지는지 확인
--      SELECT id, interpreter_id, interpreter_accepted, respond_by FROM "42_통역계약"
--       WHERE interpreter_id IS NOT NULL AND interpreter_accepted IS NULL;
--   2) 통역사 수락 후 respond_by가 NULL로 비는지 확인.
