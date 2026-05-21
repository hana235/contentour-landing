-- ════════════════════════════════════════════════════════════════
-- 통역사 구인공고 지원 기록 테이블 (Phase 4D)
-- 작성: 2026-05-21
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run
-- ════════════════════════════════════════════════════════════════
-- 배경:
--   통역사가 /interpreter-jobs 페이지에서 카드의 "지원하기" 버튼을 누르면
--   이 테이블에 INSERT. 같은 공고에 중복 지원 불가.
--   admin이 지원자 풀에서 선별 후 고객사에 매칭 제안 → 수락 시 42_통역계약 INSERT.
--
-- status flow:
--   'pending'   — 지원 직후. admin 검토 대기
--   'forwarded' — admin이 고객사에 매칭 제안한 상태
--   'matched'   — 고객사 수락, contract 생성됨 (42_통역계약 FK 연결)
--   'declined'  — admin이 후보에서 제외 또는 고객사 거절
--
-- RLS:
--   service_role API 우회 패턴. anon SELECT 차단.
--   본인이 지원한 기록은 본인 통역사 대시보드에서 조회 (별도 API).
-- ════════════════════════════════════════════════════════════════

BEGIN;

-- 1) 테이블 생성
CREATE TABLE IF NOT EXISTS "70_구인공고지원" (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    posting_id      uuid NOT NULL REFERENCES "46_ITQ견적문의"(id) ON DELETE CASCADE,
    interpreter_id  uuid NOT NULL REFERENCES "01_회원"(id) ON DELETE CASCADE,
    contract_id     uuid REFERENCES "42_통역계약"(id) ON DELETE SET NULL,
    status          text NOT NULL DEFAULT 'pending',
    admin_note      text,
    applied_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_70_status CHECK (status IN ('pending', 'forwarded', 'matched', 'declined')),
    CONSTRAINT uq_70_posting_interpreter UNIQUE (posting_id, interpreter_id)
);

-- 2) 인덱스
CREATE INDEX IF NOT EXISTS idx_70_posting ON "70_구인공고지원" (posting_id, applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_70_interpreter ON "70_구인공고지원" (interpreter_id, applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_70_status_posting ON "70_구인공고지원" (status, posting_id) WHERE status IN ('pending', 'forwarded');

-- 3) updated_at 자동 갱신
CREATE OR REPLACE FUNCTION update_70_apps_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_70_apps_updated_at ON "70_구인공고지원";
CREATE TRIGGER trg_70_apps_updated_at
    BEFORE UPDATE ON "70_구인공고지원"
    FOR EACH ROW EXECUTE FUNCTION update_70_apps_updated_at();

-- 4) RLS — service_role 전용
ALTER TABLE "70_구인공고지원" ENABLE ROW LEVEL SECURITY;
-- 일부러 정책을 추가하지 않음 (RLS ON + 정책 없음 = anon/authenticated 모두 차단).
-- API는 service_role 사용하므로 RLS 우회.

COMMIT;

-- ════════════════════════════════════════════════════════════════
-- 검증 쿼리
-- ════════════════════════════════════════════════════════════════
-- 1. 테이블·컬럼 확인
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = '70_구인공고지원'
-- ORDER BY ordinal_position;
--
-- 2. 외래키 3개 확인
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint WHERE conrelid = '"70_구인공고지원"'::regclass AND contype = 'f';
--
-- 3. UNIQUE + CHECK 제약 확인
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint WHERE conrelid = '"70_구인공고지원"'::regclass AND contype IN ('u', 'c');
--
-- 4. 인덱스 3개 확인
-- SELECT indexname, indexdef FROM pg_indexes
-- WHERE schemaname = 'public' AND tablename = '70_구인공고지원';
--
-- 5. RLS ON 확인 (rowsecurity=true)
-- SELECT relname, relrowsecurity FROM pg_class WHERE relname = '70_구인공고지원';
