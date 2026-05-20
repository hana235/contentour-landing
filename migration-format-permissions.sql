-- ════════════════════════════════════════════════════════════════
-- 상담일지 양식 권한 DB 이전 (localStorage → DB)
-- 작성: 2026-05-20
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run
-- ════════════════════════════════════════════════════════════════
-- 배경:
--   admin이 토글한 상담일지 양식 권한(부산테크노파크/한국무역협회)이
--   localStorage에만 저장되어 고객사 브라우저에 닿지 못함.
--   01_회원 테이블에 JSONB 컬럼으로 이전하여 어디서 로그인해도 반영.
--
-- 형식: { "busan": true, "kita": false, "modified_at": "2026-05-20T..." }
--
-- RLS:
--   - 01_회원 기존 정책으로 충분
--     · "관리자 전체" (FOR ALL is_admin()) → admin이 모든 행 UPDATE 가능
--     · "본인 프로필 조회" (FOR SELECT auth.uid() = id) → 고객사가 본인 행 SELECT 가능
--   - 추가 정책 없음
--
-- Realtime:
--   - 01_회원 테이블의 UPDATE 이벤트가 고객사 본인 행에 대해 들어와야 함
--   - REPLICA IDENTITY FULL 보장 (이미 적용되어 있을 수 있음)
-- ════════════════════════════════════════════════════════════════

BEGIN;

-- 1) JSONB 컬럼 추가 (없을 때만)
ALTER TABLE "01_회원"
  ADD COLUMN IF NOT EXISTS format_permissions JSONB NOT NULL DEFAULT '{}'::jsonb;

-- 2) 인덱스 (admin 권한 조회 화면에서 정렬/조회용 — GIN으로 두면 향후 확장 시 유연)
CREATE INDEX IF NOT EXISTS idx_01_회원_format_permissions
  ON "01_회원" USING GIN (format_permissions);

-- 3) Realtime 구독을 위한 REPLICA IDENTITY FULL (이미 설정되어 있을 수 있음)
ALTER TABLE "01_회원" REPLICA IDENTITY FULL;

-- 4) Realtime publication에 포함 (이미 포함되어 있다면 무시됨)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = '01_회원'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE "01_회원";
  END IF;
END $$;

COMMIT;

-- ════════════════════════════════════════════════════════════════
-- 검증 쿼리 (Run 후 별도 실행해서 확인)
-- ════════════════════════════════════════════════════════════════
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = '01_회원' AND column_name = 'format_permissions';
--
-- SELECT id, name, company_name, format_permissions
-- FROM "01_회원"
-- WHERE role = 'customer'
-- LIMIT 5;
--
-- -- Realtime publication 포함 확인
-- SELECT tablename FROM pg_publication_tables
-- WHERE pubname = 'supabase_realtime' AND tablename = '01_회원';
