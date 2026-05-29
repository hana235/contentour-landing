-- ============================================================================
-- RLS 라이브 스냅샷 (prod jgeqbdrfpekzuumaklvx, 2026-05-29 기준)
-- ----------------------------------------------------------------------------
-- 목적: repo ↔ prod 소스 드리프트 해소. 그동안 RLS 강화(v2~v7 등)가 라이브엔
--       적용됐으나 일부 정책 SQL이 repo에 남지 않아, repo로 재구축 시 약해질 수
--       있었음. 이 파일은 2026-05-29 prod pg_policies 덤프를 그대로 재현한다.
-- 성격: 멱등(DROP IF EXISTS 후 CREATE). 재실행 안전. is_admin() 헬퍼는 이미 존재.
-- 주의: service_role의 USING(true)는 정상 — 백엔드 API 키 전용(클라 미노출 확인).
-- ============================================================================

-- ── 01_회원 ──────────────────────────────────────────────────────────────
ALTER TABLE "01_회원" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_all" ON "01_회원";
CREATE POLICY "service_all" ON "01_회원" FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS "authenticated_read" ON "01_회원";
CREATE POLICY "authenticated_read" ON "01_회원" FOR SELECT TO authenticated
USING (
  (id = auth.uid())
  OR is_admin()
  OR (EXISTS (
    SELECT 1 FROM "42_통역계약" c
    WHERE (((c.customer_id = auth.uid()) AND (c.interpreter_id = "01_회원".id))
        OR ((c.interpreter_id = auth.uid()) AND (c.customer_id = "01_회원".id)))
  ))
);

DROP POLICY IF EXISTS "authenticated_update" ON "01_회원";
CREATE POLICY "authenticated_update" ON "01_회원" FOR UPDATE TO authenticated
USING ((id = auth.uid()) OR is_admin())
WITH CHECK ((id = auth.uid()) OR is_admin());

-- ── 42_통역계약 ──────────────────────────────────────────────────────────
ALTER TABLE "42_통역계약" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_all" ON "42_통역계약";
CREATE POLICY "service_all" ON "42_통역계약" FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS "authenticated_insert" ON "42_통역계약";
CREATE POLICY "authenticated_insert" ON "42_통역계약" FOR INSERT TO authenticated
WITH CHECK ((customer_id = auth.uid()) OR is_admin());

DROP POLICY IF EXISTS "authenticated_read" ON "42_통역계약";
CREATE POLICY "authenticated_read" ON "42_통역계약" FOR SELECT TO authenticated
USING ((customer_id = auth.uid()) OR (interpreter_id = auth.uid()) OR is_admin());

DROP POLICY IF EXISTS "authenticated_update" ON "42_통역계약";
CREATE POLICY "authenticated_update" ON "42_통역계약" FOR UPDATE TO authenticated
USING ((customer_id = auth.uid()) OR (interpreter_id = auth.uid()) OR is_admin())
WITH CHECK ((customer_id = auth.uid()) OR (interpreter_id = auth.uid()) OR is_admin());

-- ── 43_정산내역 ──────────────────────────────────────────────────────────
ALTER TABLE "43_정산내역" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_all" ON "43_정산내역";
CREATE POLICY "service_all" ON "43_정산내역" FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS "authenticated_read" ON "43_정산내역";
CREATE POLICY "authenticated_read" ON "43_정산내역" FOR SELECT TO authenticated
USING ((interpreter_id = auth.uid()) OR is_admin());

-- ── 44_상담일지 ──────────────────────────────────────────────────────────
ALTER TABLE "44_상담일지" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_all" ON "44_상담일지";
CREATE POLICY "service_all" ON "44_상담일지" FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS "authenticated_insert" ON "44_상담일지";
CREATE POLICY "authenticated_insert" ON "44_상담일지" FOR INSERT TO authenticated
WITH CHECK ((interpreter_id = auth.uid()) OR (customer_id = auth.uid()) OR is_admin());

DROP POLICY IF EXISTS "authenticated_read" ON "44_상담일지";
CREATE POLICY "authenticated_read" ON "44_상담일지" FOR SELECT TO authenticated
USING ((interpreter_id = auth.uid()) OR (customer_id = auth.uid()) OR is_admin());

DROP POLICY IF EXISTS "authenticated_update" ON "44_상담일지";
CREATE POLICY "authenticated_update" ON "44_상담일지" FOR UPDATE TO authenticated
USING ((interpreter_id = auth.uid()) OR (customer_id = auth.uid()) OR is_admin())
WITH CHECK ((interpreter_id = auth.uid()) OR (customer_id = auth.uid()) OR is_admin());

-- ── 45_채팅메시지 ────────────────────────────────────────────────────────
ALTER TABLE "45_채팅메시지" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_all" ON "45_채팅메시지";
CREATE POLICY "service_all" ON "45_채팅메시지" FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS "authenticated_insert" ON "45_채팅메시지";
CREATE POLICY "authenticated_insert" ON "45_채팅메시지" FOR INSERT TO authenticated
WITH CHECK (
  (sender_id = auth.uid())
  AND ((contract_id IS NULL)
    OR (EXISTS (
      SELECT 1 FROM "42_통역계약" c
      WHERE ((c.id = "45_채팅메시지".contract_id)
        AND ((c.customer_id = auth.uid()) OR (c.interpreter_id = auth.uid())))
    ))
    OR is_admin())
);

DROP POLICY IF EXISTS "authenticated_read" ON "45_채팅메시지";
CREATE POLICY "authenticated_read" ON "45_채팅메시지" FOR SELECT TO authenticated
USING (
  (sender_id = auth.uid())
  OR is_admin()
  OR (EXISTS (
    SELECT 1 FROM "42_통역계약" c
    WHERE ((c.id = "45_채팅메시지".contract_id)
      AND ((c.customer_id = auth.uid()) OR (c.interpreter_id = auth.uid())))
  ))
);

-- ── 46_ITQ견적문의 ───────────────────────────────────────────────────────
ALTER TABLE "46_ITQ견적문의" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_all" ON "46_ITQ견적문의";
CREATE POLICY "service_all" ON "46_ITQ견적문의" FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS "authenticated_insert" ON "46_ITQ견적문의";
CREATE POLICY "authenticated_insert" ON "46_ITQ견적문의" FOR INSERT TO authenticated
WITH CHECK ((user_id IS NULL) OR (user_id = auth.uid()) OR is_admin());

DROP POLICY IF EXISTS "authenticated_read" ON "46_ITQ견적문의";
CREATE POLICY "authenticated_read" ON "46_ITQ견적문의" FOR SELECT TO authenticated
USING ((user_id = auth.uid()) OR is_admin());

DROP POLICY IF EXISTS "authenticated_update" ON "46_ITQ견적문의";
CREATE POLICY "authenticated_update" ON "46_ITQ견적문의" FOR UPDATE TO authenticated
USING ((user_id = auth.uid()) OR is_admin())
WITH CHECK ((user_id = auth.uid()) OR is_admin());

-- ── 47_결제기록 ──────────────────────────────────────────────────────────
ALTER TABLE "47_결제기록" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_all" ON "47_결제기록";
CREATE POLICY "service_all" ON "47_결제기록" FOR ALL TO service_role USING (true);

DROP POLICY IF EXISTS "authenticated_read" ON "47_결제기록";
CREATE POLICY "authenticated_read" ON "47_결제기록" FOR SELECT TO authenticated
USING ((customer_id = auth.uid()) OR is_admin());
