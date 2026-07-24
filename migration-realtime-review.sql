-- ════════════════════════════════════════════════════════════════
-- 49_통역사리뷰 — Realtime publication 등록 + REPLICA IDENTITY FULL
-- 작성: 2026-07-24
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run (한 번만)
-- ----------------------------------------------------------------------------
-- 목적: customer-dashboard.html이 postgres_changes(UPDATE, filter customer_id)로 49_통역사리뷰를
--       구독하고 "💬 통역사가 리뷰에 답글을 남겼습니다" 토스트를 띄우나, 이 테이블이
--       supabase_realtime publication에 없어 실시간 푸시가 절대 발화되지 않음
--       (새로고침·재접속 전까지 미표시). publication에 추가해 라이브 전달 복구.
--       (참고: 새 리뷰 작성 시 통역사 알림은 24_알림 트리거 경유로 이미 정상 작동.)
-- 성격: 멱등(이미 추가돼 있으면 건너뜀). 재실행 안전. RLS는 이미 정상.
-- 비고: 이벤트를 customer_id(非PK)로 필터하므로 REPLICA IDENTITY FULL 필요
--       (FULL 없으면 UPDATE 이벤트의 필터 매칭이 누락될 수 있음 — Supabase 알려진 gotcha).
-- ════════════════════════════════════════════════════════════════

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = '49_통역사리뷰'
    ) THEN
        EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE "49_통역사리뷰"';
        RAISE NOTICE '49_통역사리뷰 publication 추가됨';
    ELSE
        RAISE NOTICE '49_통역사리뷰 이미 publication에 있음';
    END IF;
END $$;

ALTER TABLE "49_통역사리뷰" REPLICA IDENTITY FULL;

-- ════════════════════════════════════════════════════════════════
-- 검증: 아래에 49_통역사리뷰가 보이면 정상
--   SELECT tablename FROM pg_publication_tables WHERE pubname='supabase_realtime';
-- ════════════════════════════════════════════════════════════════
