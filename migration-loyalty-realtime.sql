-- ═══════════════════════════════════════════════════════════════
-- 적립금 Realtime 활성화 (2026-05-15)
-- ═══════════════════════════════════════════════════════════════
-- 목적:
--   고객사 대시보드가 새로고침 없이 적립금 변경을 즉시 반영하려면
--   30_적립금, 31_적립금이력 테이블이 supabase_realtime publication에
--   포함돼야 함. 본 SQL은 미포함 시 추가 (멱등).
--
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- ═══════════════════════════════════════════════════════════════


DO $$
BEGIN
    -- 30_적립금
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = '30_적립금'
    ) THEN
        EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE "30_적립금"';
        RAISE NOTICE '30_적립금 추가됨';
    ELSE
        RAISE NOTICE '30_적립금 이미 publication에 있음';
    END IF;

    -- 31_적립금이력
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = '31_적립금이력'
    ) THEN
        EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE "31_적립금이력"';
        RAISE NOTICE '31_적립금이력 추가됨';
    ELSE
        RAISE NOTICE '31_적립금이력 이미 publication에 있음';
    END IF;
END$$;


-- 검증:
-- SELECT tablename FROM pg_publication_tables
-- WHERE pubname = 'supabase_realtime' AND schemaname = 'public'
-- ORDER BY tablename;
