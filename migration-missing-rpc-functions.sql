-- ══════════════════════════════════════════════════════════
-- 누락된 RPC 2종 생성 — get_contract_partner_names / admin_upsert_setting
-- 작업일: 2026-07-07
-- 배경: 프론트가 호출하지만 운영 DB 에 정의된 적이 없어 항상 폴백 경로를 타던
--       함수들. (log_audit 과 동일한 스키마 드리프트.)
-- 재실행 안전(CREATE OR REPLACE).
-- ══════════════════════════════════════════════════════════


-- ──────────────────────────────────────────────────────────
-- 1) get_contract_partner_names(p_user_id uuid)
--    호출부: chat-data.js — 채팅방 목록에서 계약 상대방(고객사↔통역사)의 실명 표시.
--    01_회원 은 RLS 로 본인·admin 만 읽을 수 있어, 직접 조회 폴백은 상대 이름을
--    가져오지 못하고 "통역사"/"고객" 기본값만 표시됨 → 본 함수로 RLS 안전 우회.
--
--    ★ 보안: 파라미터 p_user_id 는 호출 시그니처 호환용으로만 두고 실제로는
--      auth.uid() 를 사용한다. (임의 user_id 를 넘겨 남의 계약 상대를 열람하는
--      enumeration 방지.)
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_contract_partner_names(p_user_id uuid DEFAULT NULL)
RETURNS TABLE(partner_id uuid, partner_name text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT DISTINCT m.id AS partner_id, m.name AS partner_name
    FROM "42_통역계약" c
    JOIN "01_회원" m
      ON m.id = CASE
                  WHEN c.customer_id = auth.uid() THEN c.interpreter_id
                  WHEN c.interpreter_id = auth.uid() THEN c.customer_id
                END
    WHERE (c.customer_id = auth.uid() OR c.interpreter_id = auth.uid())
      AND m.name IS NOT NULL;
$$;

REVOKE ALL ON FUNCTION public.get_contract_partner_names(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_contract_partner_names(uuid) TO authenticated;

COMMENT ON FUNCTION public.get_contract_partner_names(uuid) IS
'채팅 상대방 실명 조회. auth.uid() 의 계약 상대만 반환(파라미터는 무시). SECURITY DEFINER 로 01_회원 RLS 안전 우회.';


-- ──────────────────────────────────────────────────────────
-- 2) admin_upsert_setting(setting_key text, setting_value text)
--    호출부: admin-dashboard.html — 90_시스템설정 직접 INSERT 가 RLS 로 막힐 때
--    폴백. value 컬럼은 jsonb 이며 클라이언트가 JSON.stringify 한 텍스트를 넘기므로
--    ::jsonb 로 캐스팅한다.
--
--    ★ 보안: admin 만 시스템 설정을 변경할 수 있도록 함수 내부에서 재검증.
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_upsert_setting(setting_key text, setting_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM "01_회원" WHERE id = auth.uid() AND role = 'admin'
    ) THEN
        RAISE EXCEPTION 'permission denied: admin only';
    END IF;

    INSERT INTO "90_시스템설정" (key, value, updated_at, updated_by)
    VALUES (setting_key, setting_value::jsonb, now(), auth.uid())
    ON CONFLICT (key) DO UPDATE
        SET value      = EXCLUDED.value,
            updated_at = now(),
            updated_by = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.admin_upsert_setting(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_upsert_setting(text, text) TO authenticated;

COMMENT ON FUNCTION public.admin_upsert_setting(text, text) IS
'90_시스템설정 upsert 폴백. admin 만 실행 가능. setting_value 는 jsonb 로 캐스팅.';
