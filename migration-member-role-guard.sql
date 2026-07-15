-- ══════════════════════════════════════════════════════════
-- 01_회원 권한 컬럼 자가변조 차단 (2026-07-15)
-- ──────────────────────────────────────────────────────────
-- 증상 ①(Critical): 가입만 한 일반 사용자가 스스로 관리자로 승격 가능했음.
--   라이브 정책 authenticated_update 가
--     USING ((id = auth.uid()) OR is_admin()) WITH CHECK (동일)
--   로 "행"만 제한하고 "컬럼"은 제한하지 않으며, 01_회원에는 트리거가 없었음.
--   → 브라우저 콘솔에서 아래 한 줄로 관리자 탈취:
--       await sbClient.from('01_회원')
--         .update({ role:'admin', is_super_admin:true }).eq('id', myUid)
--   RLS의 is_admin() 과 api/admin-app.js·assign.js·file-url.js·admin-inquiries.js가
--   전부 이 컬럼을 신뢰하므로, 승격 시 전 회원 PII / 통역사 계좌번호
--   (계좌_admin_조회) / 통역사 서류 전체가 열림.
--
-- 증상 ②(High): 같은 원인으로 고객이 본인 사업자등록증 검수를 자가 승인 가능했음.
--       .update({ business_registration_status:'approved' })
--   lib/business-guard.js 의 checkBusinessApproved 가 정확히 이 컬럼만 보므로
--   결제·계약 확정 게이트(정책 B)가 그대로 무력화됨.
--
-- 해법: 42_통역계약의 prevent_unauthorized_payment_update() 와 동일한 패턴으로
--   01_회원에 BEFORE UPDATE 트리거를 걸어 권한 컬럼 변경을 차단.
--
-- 정상 경로 영향 없음 (전수 확인):
--   - 가입 시 role 설정 → api/submit.js:217(통역사)·:412(고객사) 가 service_role → 통과
--   - handle_new_user 는 auth.users INSERT 트리거 → BEFORE UPDATE 와 무관
--   - admin_approve/reject_business_registration RPC → admin 분기로 통과 (아래 ②)
--   - 사용자 본인 등록증 업로드 → 'pending'/'none' 만 쓰므로 허용 (아래 ②)
--     (client-auth.html:923, customer-dashboard.html:1611, supabase-config.js:254·259)
--   - admin-dashboard.html:6875 saveFpPermissionsForClient → format_permissions 만 → 무관
--   - role 을 UPDATE 하는 서버 함수·RPC 는 존재하지 않음 (전 *.sql grep 확인)
--
-- ※ 신규 관리자 승격은 이제 SQL Editor 에서만 가능합니다(auth.uid() IS NULL → 통과).
--   admin 세션이 XSS로 탈취돼도 role 승격은 불가 — 의도된 설계입니다.
--
-- 안전성: 비파괴·멱등(CREATE OR REPLACE + DROP TRIGGER IF EXISTS).
--   기존 정책·컬럼·데이터를 일절 변경하지 않음.
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- ══════════════════════════════════════════════════════════


-- ─── 0. 적용 전 감사: 이미 승격된 계정이 있는지 확인 ──────────
--   ※ 아래 쿼리를 먼저 단독 실행할 것. 본인이 아는 관리자 외의 행이 나오면
--     트리거를 걸기 전에 해당 계정부터 강등·조사해야 합니다.
--
--   SELECT id, email, name, role, is_super_admin, created_at
--     FROM "01_회원"
--    WHERE role = 'admin' OR is_super_admin = true
--    ORDER BY created_at;
--
--   -- 자가 승인된 사업자등록증 점검 (검수자 없이 approved 인 행)
--   SELECT id, email, company_name, business_registration_status,
--          business_registration_reviewed_by, business_registration_reviewed_at
--     FROM "01_회원"
--    WHERE business_registration_status = 'approved'
--      AND business_registration_reviewed_by IS NULL;


-- ─── 0-b. 사전 안전장치: 컬럼 존재 확인 ────────────────────
--   트리거 본문이 참조하는 컬럼이 실제로 없으면 NEW.<컬럼> 이 런타임에 터져
--   01_회원의 "모든" UPDATE 가 실패합니다(로그인 후 프로필 저장까지 전부).
--   그래서 트리거를 만들기 전에 여기서 먼저 중단시킵니다.
--   ※ repo의 schema.json 은 오래된 파일이라 컬럼 확인 근거로 쓸 수 없습니다.
DO $$
DECLARE
    missing text;
BEGIN
    SELECT string_agg(c, ', ') INTO missing
      FROM unnest(ARRAY[
            'role',
            'is_super_admin',
            'business_registration_status',
            'business_registration_reviewed_at',
            'business_registration_reviewed_by',
            'business_registration_reject_reason',
            'company_verified_at'
           ]) AS c
     WHERE NOT EXISTS (
            SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'public'
               AND table_name = '01_회원'
               AND column_name = c
           );

    IF missing IS NOT NULL THEN
        RAISE EXCEPTION
            '01_회원에 없는 컬럼: %. 트리거를 만들면 모든 UPDATE가 실패하므로 중단합니다. 컬럼명을 확인하고 함수 본문을 맞춰주세요.',
            missing;
    END IF;
END $$;


-- ─── 1. 가드 함수 ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.prevent_unauthorized_member_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    actor_role text;
    is_service_role boolean;
BEGIN
    -- service_role(가입 API 등) 및 SQL Editor/postgres(auth.uid() IS NULL)는 자유 통과
    is_service_role := (auth.role() = 'service_role') OR (auth.uid() IS NULL);
    IF is_service_role THEN
        RETURN NEW;
    END IF;

    SELECT role INTO actor_role FROM "01_회원" WHERE id = auth.uid();

    -- ① 등급 컬럼: 세션을 가진 누구도 변경 불가 (admin 포함)
    --    승격/강등은 service_role 서버 API 또는 SQL Editor 에서만.
    IF NEW.role IS DISTINCT FROM OLD.role
       OR COALESCE(NEW.is_super_admin, false) IS DISTINCT FROM COALESCE(OLD.is_super_admin, false)
    THEN
        RAISE EXCEPTION '회원 등급(role/is_super_admin)은 서버에서만 변경할 수 있습니다.';
    END IF;

    -- ② 사업자등록증 검수 상태
    --    일반 사용자: 본인 업로드/삭제 흐름의 'pending'/'none' 만 허용
    --    admin: admin_approve/reject_business_registration RPC 가 SECURITY DEFINER 라도
    --           auth.uid() 는 관리자 uid 로 잡히므로 여기서 통과시켜야 승인 기능이 동작함
    --    ※ actor_role 이 NULL 일 때 <> 는 NULL 을 반환해 IF 가 false 로 처리(=차단 우회)되므로
    --      반드시 IS DISTINCT FROM 을 쓸 것. fail-closed 유지.
    IF NEW.business_registration_status IS DISTINCT FROM OLD.business_registration_status THEN
        IF actor_role IS DISTINCT FROM 'admin'
           AND COALESCE(NEW.business_registration_status, 'none') NOT IN ('pending', 'none')
        THEN
            RAISE EXCEPTION '사업자등록증 검수 상태는 관리자만 변경할 수 있습니다.';
        END IF;
    END IF;

    -- ③ 검수 메타 컬럼: 일반 사용자가 검수 이력을 위조하지 못하도록 admin 전용
    IF actor_role IS DISTINCT FROM 'admin' THEN
        IF NEW.business_registration_reviewed_at IS DISTINCT FROM OLD.business_registration_reviewed_at
           OR NEW.business_registration_reviewed_by IS DISTINCT FROM OLD.business_registration_reviewed_by
           OR NEW.business_registration_reject_reason IS DISTINCT FROM OLD.business_registration_reject_reason
           OR NEW.company_verified_at IS DISTINCT FROM OLD.company_verified_at
        THEN
            RAISE EXCEPTION '사업자등록증 검수 정보는 관리자만 변경할 수 있습니다.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.prevent_unauthorized_member_update IS
    'service_role/SQL Editor 가 아닌 세션이 01_회원의 role·is_super_admin 을 변경하는 것을 차단(admin 포함). 사업자등록증 검수 상태·메타는 admin 만 변경 가능하고 일반 사용자는 pending/none 만 허용. RLS column-level 제한 대체. (2026-07-15)';


-- ─── 2. 트리거 ────────────────────────────────────────────
DROP TRIGGER IF EXISTS "trg_01_회원_prevent_role_update" ON "01_회원";
CREATE TRIGGER "trg_01_회원_prevent_role_update"
    BEFORE UPDATE ON "01_회원"
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_unauthorized_member_update();


-- ─── 3. 함수 권한 하드닝 ──────────────────────────────────
--   트리거 함수는 트리거가 호출하므로 일반 사용자 EXECUTE 는 불필요.
--   (handle_new_user 등에 이미 적용된 migration-security-advisor-fix 계열과 동일 패턴)
--   ※ CREATE TRIGGER 가 생성자의 EXECUTE 권한을 확인하므로 REVOKE 는 그 뒤에 둔다.
REVOKE EXECUTE ON FUNCTION public.prevent_unauthorized_member_update() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.prevent_unauthorized_member_update() FROM anon;
REVOKE EXECUTE ON FUNCTION public.prevent_unauthorized_member_update() FROM authenticated;


-- ─── 4. 적용 후 검증 ──────────────────────────────────────
--   아래는 "실패해야 정상"입니다. 일반 고객사 계정으로 로그인한 브라우저 콘솔에서:
--
--   await sbClient.from('01_회원').update({ role:'admin' }).eq('id', (await sbClient.auth.getUser()).data.user.id)
--   → { error: { message: '회원 등급(role/is_super_admin)은 서버에서만 변경할 수 있습니다.' } }
--
--   await sbClient.from('01_회원').update({ business_registration_status:'approved' }).eq('id', myUid)
--   → { error: { message: '사업자등록증 검수 상태는 관리자만 변경할 수 있습니다.' } }
--
--   아래는 "성공해야 정상"입니다 (회귀 확인):
--   - 고객사: 마이페이지에서 사업자등록증 재업로드 → status='pending' 저장
--   - 관리자: 대시보드에서 사업자등록증 승인 → status='approved' 저장
--   - 관리자: 고객사 양식 권한(format_permissions) 저장
--   - 신규 고객사/통역사 가입 (서버 API 경유)
