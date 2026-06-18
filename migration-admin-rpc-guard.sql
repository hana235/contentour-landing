-- ══════════════════════════════════════════════════════════
-- HIGH 보안: admin_reset_password / admin_confirm_user 권한 게이트 + EXECUTE 회수
-- 작업일: 2026-06-18
-- 문제: 두 함수가 SECURITY DEFINER인데 (1) 본문에 호출자 admin 검증이 전혀 없고
--       (2) 다른 민감 RPC와 달리 EXECUTE REVOKE가 누락되어 PUBLIC에 열려 있었음.
--       → 임의의 인증 사용자(통역사·고객) 또는 anon이 admin_reset_password(<관리자 id>,'새비번')을
--         직접 호출해 관리자 비밀번호를 바꿔 계정/대시보드 전권을 탈취할 수 있었음.
-- 의존: public.is_admin() (이미 존재).
-- ══════════════════════════════════════════════════════════

-- 1) 비밀번호 초기화 — 본문에 admin 검증 추가
CREATE OR REPLACE FUNCTION public.admin_reset_password(target_user_id uuid, new_password text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION '권한이 없습니다.';
  END IF;

  UPDATE auth.users
  SET encrypted_password = crypt(new_password, gen_salt('bf')),
      updated_at = NOW()
  WHERE id = target_user_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'message', '해당 사용자를 찾을 수 없습니다.');
  END IF;

  RETURN json_build_object('success', true, 'message', '비밀번호가 초기화되었습니다.');
END;
$function$;

-- 2) 이메일 인증 확인 — 본문에 admin 검증 추가
CREATE OR REPLACE FUNCTION public.admin_confirm_user(target_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION '권한이 없습니다.';
  END IF;

  UPDATE auth.users SET
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    confirmation_token = COALESCE(confirmation_token, ''),
    recovery_token = COALESCE(recovery_token, ''),
    email_change = COALESCE(email_change, ''),
    email_change_token_new = COALESCE(email_change_token_new, ''),
    email_change_token_current = COALESCE(email_change_token_current, ''),
    email_change_confirm_status = COALESCE(email_change_confirm_status, 0),
    phone_change = COALESCE(phone_change, ''),
    phone_change_token = COALESCE(phone_change_token, ''),
    reauthentication_token = COALESCE(reauthentication_token, '')
  WHERE id = target_user_id;

  RETURN json_build_object('success', true);
END;
$function$;

-- 3) EXECUTE 권한 회수 (다른 민감 RPC와 동일 패턴)
--    admin_reset_password는 관리자 대시보드가 authenticated(admin) 클라이언트로 호출하므로
--    authenticated에는 EXECUTE를 남기되(본문 is_admin() 게이트가 최종 방어선), anon/PUBLIC은 회수.
REVOKE ALL ON FUNCTION public.admin_reset_password(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_reset_password(uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_reset_password(uuid, text) TO authenticated;

--    admin_confirm_user는 클라이언트 호출처가 없으므로 전부 회수.
REVOKE ALL ON FUNCTION public.admin_confirm_user(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_confirm_user(uuid) FROM anon;
REVOKE ALL ON FUNCTION public.admin_confirm_user(uuid) FROM authenticated;

-- 적용 확인:
--   SELECT proname, proacl FROM pg_proc WHERE proname IN ('admin_reset_password','admin_confirm_user');
--   → proacl에 PUBLIC(=빈 grantee)·anon EXECUTE가 없어야 함.
-- 검증 테스트: 일반 통역사/고객 계정 토큰으로 rpc('admin_reset_password', ...) 호출 시 '권한이 없습니다.' 예외.
