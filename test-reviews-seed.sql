-- ============================================================
-- 리뷰 모더레이션 테스트 데이터 (내부 검증용)
-- 가장 최근 계약 4건을 기준으로 다양한 상태의 리뷰 4건 자동 생성
-- ============================================================
-- 사용법:
--   1) 아래 INSERT 블록 실행 → 테스트 데이터 생성
--   2) admin-dashboard "🚩 리뷰 검토" 탭 + interpreter-dashboard "고객 후기" 탭 확인
--   3) 검증 끝나면 맨 아래 DELETE 블록 실행 → 테스트 데이터 정리
-- 주의:
--   - 기존 계약 4건이 필요 (없으면 적은 수만 들어감)
--   - 같은 계약+고객 조합은 UNIQUE 제약 — ON CONFLICT DO NOTHING
--   - exhibition_name에 "(TEST)" 표시 + review_text에 "[테스트-XXX]" prefix로 식별
-- ============================================================


-- ───────────────────────────────────────────────
-- [1] 테스트 리뷰 4건 INSERT
-- ───────────────────────────────────────────────
WITH sample_contracts AS (
  SELECT
    id,
    customer_id,
    interpreter_id,
    COALESCE(exhibition_name, '테스트 전시회') AS expo_name,
    ROW_NUMBER() OVER (ORDER BY created_at DESC) AS rn
  FROM "42_통역계약"
  WHERE customer_id IS NOT NULL
    AND interpreter_id IS NOT NULL
  LIMIT 4
)
INSERT INTO "49_통역사리뷰" (
  contract_id, customer_id, interpreter_id, exhibition_name,
  rating_expertise, rating_manner, rating_communication, rating_overall,
  review_text, is_public,
  auto_flagged, flagged_keywords,
  report_status, report_reason, reported_at,
  hidden_at, hide_reason
)
SELECT
  id, customer_id, interpreter_id, expo_name || ' (TEST)',
  CASE rn WHEN 1 THEN 5 WHEN 2 THEN 2 WHEN 3 THEN 3 WHEN 4 THEN 1 END,
  CASE rn WHEN 1 THEN 5 WHEN 2 THEN 3 WHEN 3 THEN 4 WHEN 4 THEN 1 END,
  CASE rn WHEN 1 THEN 5 WHEN 2 THEN 2 WHEN 3 THEN 4 WHEN 4 THEN 2 END,
  CASE rn WHEN 1 THEN 5 WHEN 2 THEN 2 WHEN 3 THEN 3 WHEN 4 THEN 1 END,
  CASE rn
    WHEN 1 THEN '[테스트-정상] 매우 친절하고 전문성 있는 통역이었습니다. 다음에도 함께하고 싶어요.'
    WHEN 2 THEN '[테스트-자동플래그] 환불 요청드립니다. 약속 불이행이 있었고 노쇼였어요.'
    WHEN 3 THEN '[테스트-신고됨] 평범한 후기인데 통역사가 신고했다고 가정한 케이스입니다.'
    WHEN 4 THEN '[테스트-관리자숨김] 이미 관리자가 숨김 처리한 리뷰 (복원 버튼 동작 확인용).'
  END,
  -- is_public: 자동플래그·숨김 케이스는 false
  CASE rn WHEN 2 THEN false WHEN 4 THEN false ELSE true END,
  -- auto_flagged
  CASE rn WHEN 2 THEN true ELSE false END,
  -- flagged_keywords
  CASE rn WHEN 2 THEN '환불,약속 불이행,노쇼' END,
  -- report_status
  CASE rn
    WHEN 3 THEN 'reported'
    WHEN 4 THEN 'hidden'
    ELSE 'none'
  END,
  -- report_reason
  CASE rn WHEN 3 THEN '허위 사실 — 해당 내용은 실제와 다릅니다 (테스트 신고)' END,
  -- reported_at
  CASE rn WHEN 3 THEN now() END,
  -- hidden_at
  CASE rn WHEN 4 THEN now() END,
  -- hide_reason
  CASE rn WHEN 4 THEN '테스트용 관리자 숨김 처리' END
FROM sample_contracts
ON CONFLICT (contract_id, customer_id) DO NOTHING;


-- ───────────────────────────────────────────────
-- [2] 생성 결과 확인
-- ───────────────────────────────────────────────
SELECT
  id, exhibition_name, rating_overall,
  is_public, auto_flagged, report_status,
  LEFT(review_text, 40) AS review_preview
FROM "49_통역사리뷰"
WHERE exhibition_name LIKE '%(TEST)%'
ORDER BY created_at DESC;


-- ============================================================
-- [3] 정리 (검증 끝난 후 실행)
-- ============================================================
-- DELETE FROM "49_통역사리뷰" WHERE exhibition_name LIKE '%(TEST)%';
-- ============================================================
