-- ════════════════════════════════════════════════════════════════
-- 통역사 구인 현황 — 고객사 직접 등록 모델 (Phase 4A)
-- 작성: 2026-05-21
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run
-- ════════════════════════════════════════════════════════════════
-- 배경:
--   현재 /interpreter-jobs는 admin이 견적의뢰 중 골라 큐레이션한 공고만 노출(Phase 3).
--   Phase 4부터는 로그인 고객사가 직접 공고를 등록하고, admin 검토 후 게재되는
--   "절충안" 구조로 확장. 기존 견적의뢰와 새 직접 등록 공고를 한 테이블에서
--   source_type으로 구분하고, 검토 상태는 review_status로 관리.
--
-- 노출 룰 (Phase 4 이후):
--   ┌─ source_type='admin_inquiry'  → showcase_consent=true AND showcase_published_at IS NOT NULL  (Phase 3 룰 유지)
--   └─ source_type='direct_posting' → review_status='approved'                                       (Phase 4 신규)
--
-- 직접 컨택 우회 방어 — 컬럼만 미리 두고 Phase 4F에서 활용:
--   company_name_disclosure (false=익명, true=로그인 통역사에게 공개. 매칭 후엔 무조건 공개)
-- ════════════════════════════════════════════════════════════════

BEGIN;

-- 1) 컬럼 7개 추가
ALTER TABLE "46_ITQ견적문의"
  ADD COLUMN IF NOT EXISTS source_type              text         NOT NULL DEFAULT 'admin_inquiry',
  ADD COLUMN IF NOT EXISTS posted_by_user_id        uuid,           -- 직접 등록한 고객사 user_id
  ADD COLUMN IF NOT EXISTS review_status            text,           -- 'pending' | 'approved' | 'rejected' (direct_posting만)
  ADD COLUMN IF NOT EXISTS review_note              text,           -- admin 메모 또는 거부 사유
  ADD COLUMN IF NOT EXISTS reviewed_at              timestamptz,
  ADD COLUMN IF NOT EXISTS reviewed_by              uuid,           -- 검토한 admin user_id
  ADD COLUMN IF NOT EXISTS company_name_disclosure  boolean      NOT NULL DEFAULT false;  -- Phase 4F에서 활용

-- 2) CHECK 제약
ALTER TABLE "46_ITQ견적문의"
  DROP CONSTRAINT IF EXISTS chk_46_source_type;
ALTER TABLE "46_ITQ견적문의"
  ADD CONSTRAINT chk_46_source_type
  CHECK (source_type IN ('admin_inquiry', 'direct_posting'));

ALTER TABLE "46_ITQ견적문의"
  DROP CONSTRAINT IF EXISTS chk_46_review_status;
ALTER TABLE "46_ITQ견적문의"
  ADD CONSTRAINT chk_46_review_status
  CHECK (review_status IS NULL OR review_status IN ('pending', 'approved', 'rejected'));

-- 3) 외래키 (01_회원 참조). 회원 삭제 시 NULL로 끊김
ALTER TABLE "46_ITQ견적문의"
  DROP CONSTRAINT IF EXISTS fk_46_posted_by;
ALTER TABLE "46_ITQ견적문의"
  ADD CONSTRAINT fk_46_posted_by
  FOREIGN KEY (posted_by_user_id) REFERENCES "01_회원"(id) ON DELETE SET NULL;

ALTER TABLE "46_ITQ견적문의"
  DROP CONSTRAINT IF EXISTS fk_46_reviewed_by;
ALTER TABLE "46_ITQ견적문의"
  ADD CONSTRAINT fk_46_reviewed_by
  FOREIGN KEY (reviewed_by) REFERENCES "01_회원"(id) ON DELETE SET NULL;

-- 4) 인덱스 — 자주 쓰는 쿼리 가속
-- 4-1. admin 검토 큐 (direct_posting + pending)
CREATE INDEX IF NOT EXISTS idx_46_review_queue
  ON "46_ITQ견적문의" (created_at DESC)
  WHERE source_type = 'direct_posting' AND review_status = 'pending';

-- 4-2. 공개 카드 — direct_posting + approved (지역 필터 함께 사용)
CREATE INDEX IF NOT EXISTS idx_46_direct_approved
  ON "46_ITQ견적문의" (reviewed_at DESC, showcase_country_code)
  WHERE source_type = 'direct_posting' AND review_status = 'approved';

-- 4-3. "내 공고" 조회 — 고객사 본인이 올린 공고 목록
CREATE INDEX IF NOT EXISTS idx_46_posted_by
  ON "46_ITQ견적문의" (posted_by_user_id, created_at DESC)
  WHERE source_type = 'direct_posting';

COMMIT;

-- ════════════════════════════════════════════════════════════════
-- 검증 쿼리 (Run 후 별도 실행해서 확인)
-- ════════════════════════════════════════════════════════════════
-- 1. 컬럼 7개 확인
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = '46_ITQ견적문의'
--   AND column_name IN ('source_type','posted_by_user_id','review_status','review_note','reviewed_at','reviewed_by','company_name_disclosure')
-- ORDER BY ordinal_position;
--
-- 2. CHECK 제약 2개 확인
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = '"46_ITQ견적문의"'::regclass
--   AND conname IN ('chk_46_source_type', 'chk_46_review_status');
--
-- 3. 외래키 2개 확인
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = '"46_ITQ견적문의"'::regclass
--   AND conname IN ('fk_46_posted_by', 'fk_46_reviewed_by');
--
-- 4. 인덱스 3개 확인
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'public' AND tablename = '46_ITQ견적문의'
--   AND indexname IN ('idx_46_review_queue', 'idx_46_direct_approved', 'idx_46_posted_by');
--
-- 5. 기존 row 기본값 확인 (모두 source_type='admin_inquiry', company_name_disclosure=false)
-- SELECT id, source_type, review_status, company_name_disclosure FROM "46_ITQ견적문의" LIMIT 5;
