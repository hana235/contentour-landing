-- ══════════════════════════════════════════════════════════
-- 구인공고(46_ITQ견적문의) 조회수 추적 (2026-06-19)
-- ──────────────────────────────────────────────────────────
-- 목적: interpreter-jobs(통역사 모집) 페이지에서 공고 카드를 펼쳐볼 때마다
--   조회수를 +1 한다. 기존 표시값은 interest_count(지원 수)였고 "조회됨" 라벨과
--   의미가 안 맞았음 → 실제 조회수(view_count)를 별도 컬럼으로 도입.
--
-- 구성:
--   1) 46_ITQ견적문의.view_count 컬럼 (기본 0)
--   2) increment_showcase_view(text) RPC — 공개 노출 조건을 충족한 공고 row만 +1.
--      비로그인(anon)도 조회수를 올릴 수 있어야 하므로 anon/authenticated에 EXECUTE 부여.
--      SECURITY DEFINER로 RLS 우회하되, WHERE 조건으로 "실제 공개 공고"만 증가시켜
--      임의 견적문의 row 변조를 차단.
--
-- ⚠️ 적용 순서: 이 마이그레이션을 먼저 적용해야 함. (코드가 view_count 컬럼을 SELECT하므로
--    컬럼이 없으면 /api/showcase가 에러남 → 적용 후 코드 배포.)
-- 적용처: Supabase Dashboard → SQL Editor → Run
-- 프로젝트: jgeqbdrfpekzuumaklvx
-- 안전성: ADD COLUMN IF NOT EXISTS + CREATE OR REPLACE → 비파괴·멱등.
-- ══════════════════════════════════════════════════════════

ALTER TABLE "46_ITQ견적문의" ADD COLUMN IF NOT EXISTS view_count integer NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION public.increment_showcase_view(p_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    -- 실제 공개된 공고(쇼케이스 노출 조건 충족)만 조회수 증가 — 임의 견적문의 row 변조 차단
    UPDATE "46_ITQ견적문의"
       SET view_count = COALESCE(view_count, 0) + 1
     WHERE id::text = p_id
       AND (
            (source_type = 'admin_inquiry' AND showcase_consent = true AND showcase_published_at IS NOT NULL)
         OR (source_type = 'direct_posting' AND review_status = 'approved')
       );
END;
$$;

REVOKE ALL ON FUNCTION public.increment_showcase_view(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_showcase_view(text) TO anon, authenticated;

COMMENT ON FUNCTION public.increment_showcase_view IS
'구인공고(46_ITQ견적문의) 카드 상세 펼침 시 조회수 +1. 공개 노출 조건 충족 row만. anon/authenticated 호출 허용 (2026-06-19).';
