-- ════════════════════════════════════════════════════════════════
-- migration: 고객사 직접 통역사 선택 — 70_구인공고지원 status에 'selected' 추가
-- 작성: 2026-05-28
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run
-- ════════════════════════════════════════════════════════════════
-- 배경:
--   고객사가 본인 공고의 지원자 중 1명을 직접 "선택"하면 그 지원 row를
--   status='selected'로 표시(고객 선택, admin 확정 대기). admin이 확정하면
--   기존 showcaseAssign 흐름으로 'matched' + 계약 생성.
--
-- 변경된 status flow:
--   'pending'   — 지원 직후, admin/고객 검토 대기
--   'forwarded' — admin이 고객사에 매칭 제안 (기존)
--   'selected'  — ★신규★ 고객사가 직접 선택, admin 확정 대기
--   'matched'   — 확정, contract 생성됨
--   'declined'  — 후보 제외 / 거절
-- ════════════════════════════════════════════════════════════════

BEGIN;

-- 1) status CHECK 제약 교체 ('selected' 허용)
ALTER TABLE "70_구인공고지원" DROP CONSTRAINT IF EXISTS chk_70_status;
ALTER TABLE "70_구인공고지원" ADD CONSTRAINT chk_70_status
    CHECK (status IN ('pending', 'forwarded', 'selected', 'matched', 'declined'));

-- 2) 부분 인덱스에 'selected' 포함 (admin이 고객 선택 건 조회 시 활용)
DROP INDEX IF EXISTS idx_70_status_posting;
CREATE INDEX IF NOT EXISTS idx_70_status_posting
    ON "70_구인공고지원" (status, posting_id)
    WHERE status IN ('pending', 'forwarded', 'selected');

COMMIT;

-- ════════════════════════════════════════════════════════════════
-- 검증
-- ════════════════════════════════════════════════════════════════
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = '"70_구인공고지원"'::regclass AND conname = 'chk_70_status';
--   → CHECK (status IN ('pending','forwarded','selected','matched','declined')) 확인
