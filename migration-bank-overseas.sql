-- ════════════════════════════════════════════════════════════════
-- 41_계좌정보 테이블 — 해외 통역사 송금 정보 지원 확장
-- 작성: 2026-05-19
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run
-- ════════════════════════════════════════════════════════════════
-- 변경 내역:
-- 1. 기존 NOT NULL 제약 해제 (해외 계좌는 bank_name 등이 NULL일 수 있음)
-- 2. account_type, payout_method 컬럼 추가
-- 3. 해외 계좌용 컬럼 추가 (SWIFT·IBAN·이메일 등)
-- 기존 데이터는 자동으로 account_type='domestic'으로 처리됨 (DEFAULT)
-- ════════════════════════════════════════════════════════════════

BEGIN;

-- 기존 NOT NULL 제약 해제 (해외 계좌 케이스 대응)
ALTER TABLE "41_계좌정보" ALTER COLUMN bank_name DROP NOT NULL;
ALTER TABLE "41_계좌정보" ALTER COLUMN account_holder DROP NOT NULL;
ALTER TABLE "41_계좌정보" ALTER COLUMN account_number DROP NOT NULL;

-- 계좌 유형 (국내/해외)
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS account_type text NOT NULL DEFAULT 'domestic'
  CHECK (account_type IN ('domestic', 'overseas'));

-- 송금 방법
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS payout_method text NOT NULL DEFAULT 'bank_domestic'
  CHECK (payout_method IN ('bank_domestic', 'bank_swift', 'wise', 'paypal', 'payoneer'));

-- 국가 코드 (ISO 2글자, 해외만 필수)
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS country_code text;

-- 통화 (ISO 4217, KRW/USD/EUR/JPY 등)
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS currency text DEFAULT 'KRW';

-- 해외 SWIFT 송금용
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS beneficiary_name_en text;     -- 수령자 영문명
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS bank_name_en text;            -- 영문 은행명
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS bank_address text;            -- 은행 주소
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS swift_code text;              -- SWIFT/BIC 코드
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS iban_or_account text;         -- IBAN 또는 계좌번호
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS beneficiary_address text;     -- 수령자 주소

-- Wise/PayPal/Payoneer 공용 이메일
ALTER TABLE "41_계좌정보" ADD COLUMN IF NOT EXISTS payout_email text;

-- 기존 데이터는 모두 국내 계좌이므로 DEFAULT 적용으로 처리됨
-- (account_type='domestic', payout_method='bank_domestic', currency='KRW')

COMMIT;

-- ════════════════════════════════════════════════════════════════
-- 검증 쿼리
-- ════════════════════════════════════════════════════════════════
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = '41_계좌정보'
-- ORDER BY ordinal_position;
