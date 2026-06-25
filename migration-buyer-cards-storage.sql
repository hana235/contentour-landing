-- ============================================================================
-- buyer-cards Storage 버킷 + RLS — 현장 바이어 명함 이미지 저장 (2026-06-25)
-- ----------------------------------------------------------------------------
-- 명함 사진을 OCR 없이 그대로 보관. 명함=제3자 개인정보 → 비공개 버킷.
-- 경로 규칙: {auth.uid()}/{timestamp}_{rand}.jpg  (업로더 본인 폴더)
-- 접근: 업로더 본인 폴더 + admin 만. 열람은 서명 URL(createSignedUrl)로.
-- 멱등: on conflict do nothing + DROP POLICY IF EXISTS. 재실행 안전.
-- (interpreter-docs 버킷 RLS와 동일 패턴)
-- ============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'buyer-cards', 'buyer-cards', false,
    5242880,  -- 5MB
    ARRAY['image/jpeg','image/png','image/webp']
)
ON CONFLICT (id) DO UPDATE
    SET file_size_limit = EXCLUDED.file_size_limit,
        allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 업로드: 본인 폴더에만
DROP POLICY IF EXISTS buyer_cards_insert ON storage.objects;
CREATE POLICY buyer_cards_insert ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'buyer-cards'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- 조회(서명 URL 발급 포함): 본인 폴더 + admin
DROP POLICY IF EXISTS buyer_cards_select ON storage.objects;
CREATE POLICY buyer_cards_select ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'buyer-cards'
        AND ((storage.foldername(name))[1] = auth.uid()::text OR is_admin())
    );

-- 교체/삭제: 본인 폴더 + admin
DROP POLICY IF EXISTS buyer_cards_update ON storage.objects;
CREATE POLICY buyer_cards_update ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'buyer-cards'
        AND ((storage.foldername(name))[1] = auth.uid()::text OR is_admin())
    );

DROP POLICY IF EXISTS buyer_cards_delete ON storage.objects;
CREATE POLICY buyer_cards_delete ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'buyer-cards'
        AND ((storage.foldername(name))[1] = auth.uid()::text OR is_admin())
    );
