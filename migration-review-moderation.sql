-- ============================================================
-- 리뷰 모더레이션 시스템 (신고 + 답글 + 자동 금칙어 보류)
-- 49_통역사리뷰에 컬럼 추가
-- 재실행 안전 (IF NOT EXISTS 사용)
-- ============================================================

-- 1. 통역사 답글
ALTER TABLE "49_통역사리뷰"
  ADD COLUMN IF NOT EXISTS "interpreter_reply" text,
  ADD COLUMN IF NOT EXISTS "interpreter_reply_at" timestamptz;

-- 2. 신고 / 자동 플래그 / 숨김 관리
ALTER TABLE "49_통역사리뷰"
  ADD COLUMN IF NOT EXISTS "report_status" text NOT NULL DEFAULT 'none',
  ADD COLUMN IF NOT EXISTS "report_reason" text,
  ADD COLUMN IF NOT EXISTS "reported_at" timestamptz,
  ADD COLUMN IF NOT EXISTS "auto_flagged" boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "flagged_keywords" text,
  ADD COLUMN IF NOT EXISTS "hidden_by" uuid REFERENCES "01_회원"(id),
  ADD COLUMN IF NOT EXISTS "hidden_at" timestamptz,
  ADD COLUMN IF NOT EXISTS "hide_reason" text;

-- report_status 가능 값: 'none' | 'reported' | 'reviewed_kept' | 'hidden'
--   none           : 정상
--   reported       : 통역사가 신고함, 관리자 검토 대기
--   reviewed_kept  : 관리자 검토 후 유지 결정
--   hidden         : 관리자가 숨김 처리 (is_public=false와 함께 셋)

-- 3. 관리자 검토 대기열 인덱스 (자동 플래그 + 신고된 것만)
CREATE INDEX IF NOT EXISTS "idx_reviews_moderation_queue"
  ON "49_통역사리뷰" ("created_at" DESC)
  WHERE "auto_flagged" = true OR "report_status" = 'reported';

-- 4. RLS 업데이트: 통역사가 본인 리뷰에 답글 작성 가능
DROP POLICY IF EXISTS "interpreter_reply_own_review" ON "49_통역사리뷰";
CREATE POLICY "interpreter_reply_own_review"
  ON "49_통역사리뷰"
  FOR UPDATE
  TO authenticated
  USING (interpreter_id = auth.uid())
  WITH CHECK (interpreter_id = auth.uid());

-- 5. RLS 업데이트: 관리자는 전부 수정 가능 (숨김/유지 처리)
DROP POLICY IF EXISTS "admin_moderate_reviews" ON "49_통역사리뷰";
CREATE POLICY "admin_moderate_reviews"
  ON "49_통역사리뷰"
  FOR UPDATE
  TO authenticated
  USING (EXISTS (SELECT 1 FROM "01_회원" WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM "01_회원" WHERE id = auth.uid() AND role = 'admin'));

-- 6. 코멘트
COMMENT ON COLUMN "49_통역사리뷰"."interpreter_reply"    IS '통역사 답글 본문';
COMMENT ON COLUMN "49_통역사리뷰"."interpreter_reply_at" IS '통역사 답글 작성 시각';
COMMENT ON COLUMN "49_통역사리뷰"."report_status"        IS '신고 처리 상태: none|reported|reviewed_kept|hidden';
COMMENT ON COLUMN "49_통역사리뷰"."report_reason"        IS '통역사가 입력한 신고 사유';
COMMENT ON COLUMN "49_통역사리뷰"."auto_flagged"         IS '소프트 플래그 키워드 매칭 시 true (관리자 검토 대기)';
COMMENT ON COLUMN "49_통역사리뷰"."flagged_keywords"     IS '매칭된 소프트 플래그 키워드 (쉼표 구분)';
COMMENT ON COLUMN "49_통역사리뷰"."hidden_by"            IS '숨김 처리한 관리자 ID';
COMMENT ON COLUMN "49_통역사리뷰"."hide_reason"          IS '관리자가 숨김 처리한 사유';
