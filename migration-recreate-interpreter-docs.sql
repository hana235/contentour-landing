-- ============================================================
-- interpreter-docs 버킷 복구 (실수로 삭제된 경우)
-- 2026-05-18
-- ============================================================
-- 사용 순서:
-- 1) 버킷 자체가 삭제된 경우 → Supabase Dashboard에서 먼저 버킷 생성
--    Storage → "New bucket" → 이름: interpreter-docs / Public: OFF
--    또는 아래 [버킷 생성 SQL]을 실행해도 됨
-- 2) [정책 복구 SQL] 실행 (재실행 안전)
-- 3) 크기/MIME 제한 추가 (Dashboard UI에서 Edit bucket)


-- ────────────────────────────────────────────────
-- [버킷 생성 SQL] — Dashboard 대신 SQL로 만들 때
-- ────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'interpreter-docs',
  'interpreter-docs',
  false,
  10485760,  -- 10 MB
  ARRAY[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;


-- ────────────────────────────────────────────────
-- [정책 복구 SQL] — migration-storage-rls.sql 발췌
-- ────────────────────────────────────────────────

-- 통역사: 본인 폴더 조회
DROP POLICY IF EXISTS "interpreter_docs_select_own" ON storage.objects;
CREATE POLICY "interpreter_docs_select_own" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'interpreter-docs'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 통역사: 본인 폴더 업로드
DROP POLICY IF EXISTS "interpreter_docs_insert_own" ON storage.objects;
CREATE POLICY "interpreter_docs_insert_own" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'interpreter-docs'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 통역사: 본인 폴더 삭제
DROP POLICY IF EXISTS "interpreter_docs_delete_own" ON storage.objects;
CREATE POLICY "interpreter_docs_delete_own" ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'interpreter-docs'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- 관리자: 전체 조회
DROP POLICY IF EXISTS "interpreter_docs_select_admin" ON storage.objects;
CREATE POLICY "interpreter_docs_select_admin" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'interpreter-docs'
  AND EXISTS (
    SELECT 1 FROM "01_회원"
    WHERE id = auth.uid() AND role = 'admin'
  )
);


-- ────────────────────────────────────────────────
-- 검증: 복구 결과 확인
-- ────────────────────────────────────────────────
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id = 'interpreter-docs';

SELECT policyname, cmd
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname LIKE 'interpreter_docs%'
ORDER BY policyname;
