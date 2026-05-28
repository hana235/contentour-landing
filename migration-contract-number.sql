-- ════════════════════════════════════════════════════════════════
-- migration: 계약번호 contract_no — 생성 시 자동 부여(트리거) + 기존 백필
-- 작성: 2026-05-28
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run
-- ════════════════════════════════════════════════════════════════
-- 목적:
--   계약마다 표시용 번호 CT-YYYYMMDD-XXXX 를 DB에 저장.
--   - YYYYMMDD = 계약 생성일(created_at) → 고객·통역사·admin 어디서나 동일
--   - XXXX    = 내부 UUID 끝 4자(대문자)
--   BEFORE INSERT 트리거로 신규 계약마다 자동 부여 → "앞으로 생기는 계약"에 자동 적용.
--   내부 ID(UUID)는 그대로 유지(로직·FK용). contract_no는 표시·검색용.
-- ════════════════════════════════════════════════════════════════

ALTER TABLE "42_통역계약" ADD COLUMN IF NOT EXISTS contract_no text;

-- 생성 시 자동 부여 (id·created_at은 DEFAULT가 BEFORE INSERT 시점에 이미 채워짐)
CREATE OR REPLACE FUNCTION public.set_contract_no()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.contract_no IS NULL OR NEW.contract_no = '' THEN
        NEW.contract_no := 'CT-'
            || to_char(COALESCE(NEW.created_at, now()), 'YYYYMMDD')
            || '-'
            || upper(right(regexp_replace(NEW.id::text, '[^a-zA-Z0-9]', '', 'g'), 4));
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_contract_no ON "42_통역계약";
CREATE TRIGGER trg_set_contract_no
    BEFORE INSERT ON "42_통역계약"
    FOR EACH ROW EXECUTE FUNCTION public.set_contract_no();

-- 기존 계약 백필
UPDATE "42_통역계약"
   SET contract_no = 'CT-'
       || to_char(COALESCE(created_at, now()), 'YYYYMMDD') || '-'
       || upper(right(regexp_replace(id::text, '[^a-zA-Z0-9]', '', 'g'), 4))
 WHERE contract_no IS NULL OR contract_no = '';

-- 검증: SELECT id, contract_no, created_at FROM "42_통역계약" ORDER BY created_at DESC LIMIT 10;
