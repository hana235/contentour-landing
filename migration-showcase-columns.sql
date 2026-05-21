-- ════════════════════════════════════════════════════════════════
-- 통역사 구인 현황(기업 홍보관) — 견적의뢰 테이블에 showcase 컬럼 추가
-- 작성: 2026-05-21
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run
-- ════════════════════════════════════════════════════════════════
-- 배경:
--   /interpreter-jobs 페이지(통역사 구인 현황)는 현재 mock 8건으로 구성.
--   Phase 3에서 46_ITQ견적문의 실데이터로 교체하되, 모든 견적을 노출하면
--   고객사 민감정보가 새어나가므로 admin 큐레이션을 거친 건만 공개한다.
--
-- 노출 규칙:
--   showcase_consent = true AND showcase_published_at IS NOT NULL 일 때만 공개.
--   동의가 있어도 admin이 익명 라벨·산업·국가코드를 채우고 published_at을 찍어야 카드에 뜸.
--   카드는 화이트리스트 컬럼만 반환 (company/contact_name/email/phone/message 등 절대 노출 금지).
--
-- 매칭 상태:
--   contract_id IS NULL  → '모집중' (recruiting)
--   contract_id IS NOT NULL → '매칭완료' (matched)
--
-- RLS:
--   46_ITQ견적문의는 현재 공개 SELECT 정책 없음.
--   본 마이그레이션도 RLS 정책을 추가하지 않는다.
--   대신 api/data.js?_route=showcase 라우트가 service_role로 화이트리스트 컬럼만 반환.
--   ([[project_public_forms_api_bypass]] 패턴 — anon 직접 SELECT 금지)
-- ════════════════════════════════════════════════════════════════

BEGIN;

-- 1) showcase 컬럼 6개 추가 (없을 때만)
ALTER TABLE "46_ITQ견적문의"
  ADD COLUMN IF NOT EXISTS showcase_consent       boolean      NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS showcase_label         text,         -- "한국 IT 중견기업" 같은 익명 라벨
  ADD COLUMN IF NOT EXISTS showcase_industry      text,         -- "IT" / "의료기기" / "뷰티·화장품" 등
  ADD COLUMN IF NOT EXISTS showcase_country_code  text,         -- "JP" / "DE" / "US" — 필터칩 매칭 (ISO 3166-1 alpha-2)
  ADD COLUMN IF NOT EXISTS showcase_published_at  timestamptz,  -- admin이 게재 확정한 시각. NULL이면 비공개
  ADD COLUMN IF NOT EXISTS interest_count         integer      NOT NULL DEFAULT 0;  -- "통역사 N명 관심" 표시용 (클릭 추적은 Phase 4)

-- 2) showcase_country_code는 ISO2 형식만 허용 (대문자 2자리)
ALTER TABLE "46_ITQ견적문의"
  DROP CONSTRAINT IF EXISTS chk_46_showcase_country_code_iso2;
ALTER TABLE "46_ITQ견적문의"
  ADD CONSTRAINT chk_46_showcase_country_code_iso2
  CHECK (showcase_country_code IS NULL OR showcase_country_code ~ '^[A-Z]{2}$');

-- 3) interest_count 음수 방지
ALTER TABLE "46_ITQ견적문의"
  DROP CONSTRAINT IF EXISTS chk_46_interest_count_nonneg;
ALTER TABLE "46_ITQ견적문의"
  ADD CONSTRAINT chk_46_interest_count_nonneg
  CHECK (interest_count >= 0);

-- 4) 공개 카드 조회용 부분 인덱스 (showcase_published_at DESC 정렬·필터 가속)
CREATE INDEX IF NOT EXISTS idx_46_showcase_published
  ON "46_ITQ견적문의" (showcase_published_at DESC, showcase_country_code)
  WHERE showcase_consent = true AND showcase_published_at IS NOT NULL;

COMMIT;

-- ════════════════════════════════════════════════════════════════
-- 검증 쿼리 (Run 후 별도 실행해서 확인)
-- ════════════════════════════════════════════════════════════════
-- 1. 컬럼 추가 확인
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = '46_ITQ견적문의'
--   AND column_name LIKE 'showcase_%' OR column_name = 'interest_count'
-- ORDER BY ordinal_position;
--
-- 2. 제약 조건 확인
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = '"46_ITQ견적문의"'::regclass
--   AND conname IN ('chk_46_showcase_country_code_iso2', 'chk_46_interest_count_nonneg');
--
-- 3. 인덱스 확인
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'public' AND tablename = '46_ITQ견적문의'
--   AND indexname = 'idx_46_showcase_published';
--
-- 4. 기존 row의 기본값 적용 확인 (showcase_consent=false, interest_count=0)
-- SELECT id, showcase_consent, interest_count FROM "46_ITQ견적문의" LIMIT 5;
--
-- ════════════════════════════════════════════════════════════════
-- 시드 데이터 (선택) — 출시 빈 페이지 방지용
-- ════════════════════════════════════════════════════════════════
-- 기존 견적의뢰 중 노출해도 되는 건이 있으면 아래 패턴으로 게재:
--
-- UPDATE "46_ITQ견적문의"
-- SET showcase_consent      = true,
--     showcase_label        = '한국 IT 중견기업',
--     showcase_industry     = 'IT',
--     showcase_country_code = 'JP',
--     showcase_published_at = NOW()
-- WHERE id = '<견적의뢰_UUID>';
--
-- 게재 취소(다시 숨기기):
-- UPDATE "46_ITQ견적문의" SET showcase_published_at = NULL WHERE id = '<UUID>';
