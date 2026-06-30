-- ════════════════════════════════════════════════════════════════
-- migration: 49_통역사리뷰 INSERT 시 is_public 강제 (전체 승인제 우회 차단)
-- 목적:
--   신규 리뷰는 "전체 승인제"로 비공개(is_public=false) 저장 후 관리자 승인 시에만
--   공개되어야 함. 그러나 기존 보호는 BEFORE UPDATE 트리거(protect_review_columns)
--   뿐이라, 고객이 클라이언트에서 직접 is_public:true 로 INSERT 하면 모더레이션을
--   건너뛰고 즉시 자가 공개되는 우회가 가능했음.
--
--   공개 노출 경로(api/data.js, interpreters.html)는 is_public=true 만 조회하므로,
--   INSERT 시점에 비admin/비service_role 의 is_public 을 false 로 강제하면
--   전체 승인제가 서버에서 보장됨. (관리자 승인은 UPDATE 경로로 별도 처리)
-- ════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.protect_review_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_admin BOOLEAN;
BEGIN
    -- service_role(서버 API)은 그대로 통과
    IF current_setting('request.jwt.claims', true)::jsonb ->> 'role' = 'service_role' THEN
        RETURN NEW;
    END IF;

    SELECT EXISTS(SELECT 1 FROM "01_회원" WHERE id = auth.uid() AND role = 'admin')
      INTO v_is_admin;
    IF v_is_admin THEN
        RETURN NEW;
    END IF;

    -- 일반 사용자(고객사) INSERT: 무조건 비공개로 저장 (관리자 승인 전까지 미노출)
    NEW.is_public := false;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_49_통역사리뷰_protect_insert ON "49_통역사리뷰";
CREATE TRIGGER trg_49_통역사리뷰_protect_insert
BEFORE INSERT ON "49_통역사리뷰"
FOR EACH ROW
EXECUTE FUNCTION public.protect_review_insert();

COMMENT ON FUNCTION public.protect_review_insert IS
'49_통역사리뷰 INSERT 시 비admin/비service_role의 is_public을 false로 강제(전체 승인제). 관리자 공개는 UPDATE 경로로만.';
