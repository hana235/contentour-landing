-- ============================================================================
-- 바이어 데이터·명함 = 고객사 전용(콘텐츄어 미열람) — RLS에서 admin 열람 제거 (2026-06-25)
-- ----------------------------------------------------------------------------
-- 배경: 고객사가 바이어 연락처·상담 내용을 영업 기밀로 여겨 콘텐츄어(관리자)에게
--       보이는 것을 꺼림. 바이어 정보는 콘텐츄어가 볼 이유가 없으므로 SELECT에서
--       admin을 빼 '미열람'을 기술적으로 강제한다. (insert/update/delete는 무관)
-- 적용 대상: 53_현장바이어 (모든 양식의 바이어), buyer-cards 명함 이미지.
-- 영향: 소유 고객사 + 해당 계약 통역사만 조회 가능. 콘텐츄어 admin은 조회 불가.
-- 멱등: DROP POLICY IF EXISTS + CREATE. 재실행 안전. (되돌리려면 OR is_admin() 복원)
-- ============================================================================

-- 53_현장바이어 조회: 소유 고객사 + 대리 통역사 + 해당 계약 통역사 (admin 제거)
DROP POLICY IF EXISTS field_buyer_select ON "53_현장바이어";
CREATE POLICY field_buyer_select ON "53_현장바이어"
    FOR SELECT TO authenticated
    USING (
        customer_id = auth.uid()
        OR interpreter_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM "42_통역계약" c
            WHERE c.id = "53_현장바이어".contract_id
              AND c.interpreter_id = auth.uid()
        )
    );

-- buyer-cards 명함 이미지 조회: 업로더 본인 폴더만 (admin 제거)
DROP POLICY IF EXISTS buyer_cards_select ON storage.objects;
CREATE POLICY buyer_cards_select ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'buyer-cards'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
