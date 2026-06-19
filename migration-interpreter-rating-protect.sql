-- ════════════════════════════════════════════════════════════════
-- 통역사 평판 컬럼(rating/satisfaction/cases_count) 자가변조 차단 (2026-06-19)
-- ──────────────────────────────────────────────────────────────────
-- 증상: 40_통역사프로필의 보호 트리거(protect_interpreter_verify_columns)가
--   is_verified·패널티 컬럼은 OLD로 강제하지만 rating·satisfaction·cases_count는
--   보호하지 않았음. 통역사가 본인 행을 직접 UPDATE(anon키/콘솔)하여
--   rating=5.0, satisfaction=100, cases_count=999 등으로 평판을 자가조작 가능했고,
--   이 값은 고객 노출 뷰(interpreters_public)로 검색·매칭에 영향.
--
-- 해법: 기존 보호 트리거 함수에 rating·satisfaction·cases_count OLD 강제 3줄 추가.
--   (집계/평점 갱신은 admin 또는 리뷰 RPC(service_role)만 — 트리거 상단에서 통과.)
--   대시보드는 이 값들을 '표시'만 하므로 클라이언트 쓰기 차단의 기능 영향 없음.
--
-- 컬럼 존재 검증: REST OpenAPI로 rating/satisfaction/cases_count 모두 200 확인(2026-06-19).
-- 안전성: 기존 함수 본문 유지 + 3줄 추가. 비파괴·멱등(CREATE OR REPLACE).
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- ════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.protect_interpreter_verify_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_admin BOOLEAN;
BEGIN
    -- 서버 RPC(apply_cancel_penalty 등)가 명시적으로 허용한 트랜잭션은 통과
    IF current_setting('app.allow_penalty_write', true) = '1' THEN
        RETURN NEW;
    END IF;

    -- service_role(서버) 통과
    IF current_setting('request.jwt.claims', true)::jsonb ->> 'role' = 'service_role' THEN
        RETURN NEW;
    END IF;

    -- admin 통과
    SELECT EXISTS(SELECT 1 FROM "01_회원" WHERE id = auth.uid() AND role = 'admin')
      INTO v_is_admin;
    IF v_is_admin THEN
        RETURN NEW;
    END IF;

    -- 통역사 본인이면: 인증 컬럼 보호 (기존)
    NEW.is_verified       := OLD.is_verified;
    NEW.verified_at       := OLD.verified_at;
    NEW.verified_by       := OLD.verified_by;
    NEW.verification_note := OLD.verification_note;

    -- 통역사 본인이면: 패널티/정지 컬럼 보호 (기존)
    NEW.penalty_count     := OLD.penalty_count;
    NEW.is_suspended      := OLD.is_suspended;
    NEW.suspended_until   := OLD.suspended_until;

    -- 통역사 본인이면: 평판 컬럼 보호 (신규 2026-06-19) — 검색/매칭 노출값 자가조작 차단
    NEW.rating            := OLD.rating;
    NEW.satisfaction      := OLD.satisfaction;
    NEW.cases_count       := OLD.cases_count;

    RETURN NEW;
END;
$$;

-- 트리거는 이미 존재(trg_40_통역사프로필_protect_verify) → 함수 교체만으로 자동 적용.

COMMENT ON FUNCTION public.protect_interpreter_verify_columns IS
'통역사 본인의 직접 UPDATE로부터 인증(is_verified)·패널티·평판(rating/satisfaction/cases_count) 컬럼을 보호. service_role/admin/허용RPC만 변경 가능. (2026-06-19 평판 3컬럼 추가)';
