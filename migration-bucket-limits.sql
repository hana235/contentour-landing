-- ============================================================
-- Storage 버킷 사이즈/MIME 제한 일괄 적용 (2026-05-18)
-- 4개 버킷 동시 처리 (interpreter-docs 포함, 재실행 안전)
-- ============================================================
-- 사용: Supabase Dashboard → SQL Editor에서 전체 실행
-- 효과: 버킷이 있으면 설정 업데이트, 없으면 생성
-- ============================================================


-- ────────────────────────────────────────────────
-- 1. interpreter-docs (비공개) — 10MB / 통역사 서류
-- ────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'interpreter-docs',
  'interpreter-docs',
  false,
  10485760,
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
-- 2. profile-images (공개) — 5MB / 통역사 프로필 사진
-- ────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  true,
  5242880,
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;


-- ────────────────────────────────────────────────
-- 3. case-images (공개) — 10MB / 성과사례 이미지
-- ────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'case-images',
  'case-images',
  true,
  10485760,
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;


-- ────────────────────────────────────────────────
-- 4. business-registrations (비공개) — 5MB / 사업자등록증
-- ────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'business-registrations',
  'business-registrations',
  false,
  5242880,
  ARRAY[
    'application/pdf',
    'image/jpeg',
    'image/png'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;


-- ============================================================
-- 검증
-- ============================================================
SELECT
  id AS bucket_name,
  public,
  file_size_limit,
  ROUND(file_size_limit / 1048576.0, 1) AS limit_mb,
  array_length(allowed_mime_types, 1) AS mime_count,
  allowed_mime_types
FROM storage.buckets
WHERE id IN (
  'interpreter-docs',
  'profile-images',
  'case-images',
  'business-registrations'
)
ORDER BY id;
