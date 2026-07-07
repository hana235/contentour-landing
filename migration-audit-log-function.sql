-- ══════════════════════════════════════════════════════════
-- log_audit() — 프론트(CT.logAudit)가 호출하는 감사 로그 기록 RPC
-- 작업일: 2026-07-07
-- 배경: migration-audit-log.sql 이 테이블 99_감사로그 는 만들었으나
--       프론트가 rpc('log_audit', ...) 로 호출하는 "기록 함수"는 어디에도
--       정의된 적이 없어, 운영 DB 에 존재하지 않았음.
--       → CT.logAudit 가 매번 조용히 실패(console.warn)하고,
--         관리자 로그인/지원서 승인·거절/정산 승인 등이 전혀 기록되지 않고 있었음.
--       본 마이그레이션이 그 누락된 함수를 생성한다.
--
-- 시그니처는 프론트 호출부(shared-constants.js CT.logAudit)의 named 파라미터와
-- 정확히 일치해야 한다: p_action, p_target_table, p_target_id, p_details
--
-- 안전장치:
--   * SECURITY DEFINER + 고정 search_path (권한 상승·search_path 주입 방지)
--   * actor(user_id/role/email)는 클라이언트 입력을 신뢰하지 않고 auth.uid() 에서 서버측 유도
--   * 기존 RLS 정책 audit_admin_insert 와 동일하게 "admin 만 기록" 가드
--     (비관리자가 rpc 를 직접 호출해 로그를 위조·스팸하는 것을 차단)
--   * p_details(jsonb) 는 after_data 컬럼에 저장 (서버측 recordAudit 의 after 매핑과 일관)
-- 재실행 안전(CREATE OR REPLACE).
-- ══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.log_audit(
    p_action        text,
    p_target_table  text  DEFAULT NULL,
    p_target_id     text  DEFAULT NULL,
    p_details       jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid   uuid := auth.uid();
    v_role  text;
    v_email text;
BEGIN
    -- 액션명은 필수
    IF p_action IS NULL OR length(btrim(p_action)) = 0 THEN
        RETURN;
    END IF;

    -- 호출자 신원을 서버측에서 확정 (클라이언트가 전달한 actor 는 신뢰하지 않음)
    IF v_uid IS NOT NULL THEN
        SELECT role, email INTO v_role, v_email
        FROM "01_회원"
        WHERE id = v_uid;
    END IF;

    -- admin 만 감사 로그를 남긴다 (테이블 audit_admin_insert 정책과 동일 기준)
    IF v_role IS DISTINCT FROM 'admin' THEN
        RETURN;
    END IF;

    INSERT INTO "99_감사로그" (
        actor_user_id,
        actor_role,
        actor_email,
        action,
        target_table,
        target_id,
        after_data
    ) VALUES (
        v_uid,
        v_role,
        v_email,
        p_action,
        p_target_table,
        NULLIF(p_target_id, ''),
        p_details
    );
END;
$$;

-- 실행 권한: 로그인 사용자(내부에서 admin 여부 재검증) + 서버 service_role 만
REVOKE ALL ON FUNCTION public.log_audit(text, text, text, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.log_audit(text, text, text, jsonb) TO authenticated, service_role;

COMMENT ON FUNCTION public.log_audit(text, text, text, jsonb) IS
'클라이언트(CT.logAudit)용 감사 로그 기록 RPC. actor 는 auth.uid() 에서 유도하며 admin 만 기록됨. p_details 는 after_data 에 저장.';
