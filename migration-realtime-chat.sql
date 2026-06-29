-- ════════════════════════════════════════════════════════════════
-- 45_채팅메시지 — Realtime publication 등록 + REPLICA IDENTITY FULL
-- 작성: 2026-06-29
-- 적용: Supabase Dashboard → SQL Editor → 전체 복사 후 Run (한 번만)
-- ----------------------------------------------------------------------------
-- 목적: chat-data.js가 postgres_changes(INSERT/UPDATE, filter room_id)로 45_채팅메시지를
--       구독하나, 이 테이블이 supabase_realtime publication에 없어 실시간 메시지가
--       전달되지 않음(재접속·새로고침 전까지 미표시). publication에 추가해 라이브 전달 복구.
-- 성격: 멱등(이미 추가돼 있으면 건너뜀). 재실행 안전.
-- 비고: UPDATE 이벤트를 room_id(非PK)로 필터하므로 REPLICA IDENTITY FULL 필요
--       (FULL 없으면 UPDATE 이벤트의 필터 매칭이 누락될 수 있음 — Supabase 알려진 gotcha).
-- ════════════════════════════════════════════════════════════════

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = '45_채팅메시지'
    ) THEN
        EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE "45_채팅메시지"';
        RAISE NOTICE '45_채팅메시지 publication 추가됨';
    ELSE
        RAISE NOTICE '45_채팅메시지 이미 publication에 있음';
    END IF;
END $$;

ALTER TABLE "45_채팅메시지" REPLICA IDENTITY FULL;

-- ════════════════════════════════════════════════════════════════
-- 검증: 아래에 45_채팅메시지가 보이면 정상
--   SELECT tablename FROM pg_publication_tables WHERE pubname='supabase_realtime';
-- ════════════════════════════════════════════════════════════════
