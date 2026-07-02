-- ════════════════════════════════════════════════════════════
-- 고객사 "완료 확인" 영구 기록 컬럼
-- 적용 위치: Supabase Dashboard SQL Editor
--
-- 배경: 고객사 대시보드의 "완료 확인" 버튼이 기존에는 status='completed'를
--       다시 쓰는 no-op이라 새로고침 시 원복됐음 (2026-07-02 점검 M2).
--       status='settled' 전이는 결제컬럼 보호 트리거가 클라이언트 차단하고,
--       정산 완료는 admin의 정산 승인 몫이므로 별도 확인 컬럼으로 기록한다.
--       (confirmation_clicked_at은 통역사 D-day 컨펌 전용이라 재사용 금지)
-- ════════════════════════════════════════════════════════════

ALTER TABLE "42_통역계약"
  ADD COLUMN IF NOT EXISTS customer_confirmed_at TIMESTAMPTZ NULL;

COMMENT ON COLUMN "42_통역계약".customer_confirmed_at IS
  '고객사가 서비스 완료(status=completed) 단계에서 "완료 확인" 버튼을 클릭한 시각. NULL=미확인. 정산(settled) 전이는 admin 정산 승인에서 별도 처리.';
