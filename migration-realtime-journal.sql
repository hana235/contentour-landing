-- ════════════════════════════════════════════════════════════════
-- 44_상담일지 — Realtime publication 등록 + REPLICA IDENTITY FULL
-- 작성: 2026-07-24
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run (한 번만)
-- ----------------------------------------------------------------------------
-- 목적: customer-dashboard.html이 postgres_changes(filter customer_id)로 44_상담일지를
--       구독하고 "📝 통역사가 새 상담일지를 등록했습니다" 토스트를 띄우나, 이 테이블이
--       supabase_realtime publication에 없어 실시간 푸시가 절대 발화되지 않음
--       (새로고침·재접속 전까지 미표시). publication에 추가해 라이브 전달 복구.
-- 성격: 멱등(이미 추가돼 있으면 건너뜀). 재실행 안전. RLS는 이미 정상(고객사 SELECT 가능).
-- 비고: 이벤트를 customer_id(非PK)로 필터하므로 REPLICA IDENTITY FULL 필요
--       (FULL 없으면 UPDATE 이벤트의 필터 매칭이 누락될 수 있음 — Supabase 알려진 gotcha).
-- ════════════════════════════════════════════════════════════════

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = '44_상담일지'
    ) THEN
        EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE "44_상담일지"';
        RAISE NOTICE '44_상담일지 publication 추가됨';
    ELSE
        RAISE NOTICE '44_상담일지 이미 publication에 있음';
    END IF;
END $$;

ALTER TABLE "44_상담일지" REPLICA IDENTITY FULL;

-- ════════════════════════════════════════════════════════════════
-- 검증: 아래에 44_상담일지가 보이면 정상
--   SELECT tablename FROM pg_publication_tables WHERE pubname='supabase_realtime';
-- ════════════════════════════════════════════════════════════════
