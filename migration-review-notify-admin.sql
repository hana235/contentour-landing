-- ═══════════════════════════════════════════════════════════════
-- 신규 리뷰 → 관리자 승인대기 알림 trigger (2026-06-02)
-- ═══════════════════════════════════════════════════════════════
-- 배경:
--   전체 승인제(is_public=false로 INSERT)로 전환됐으나, 관리자는 49_통역사리뷰를
--   realtime 구독하지 않고 신규 리뷰 알림도 없어 리뷰 탭을 수동 새로고침해야만
--   승인 대기 리뷰를 확인 가능. (기존 notify_interpreter_on_review는 통역사만 알림)
--   24_알림 INSERT RLS는 user_id=auth.uid() OR is_admin()이라 고객 클라이언트가
--   관리자 알림을 직접 INSERT 불가 → SECURITY DEFINER trigger로 처리.
--
-- 동작: 리뷰 INSERT 시 비공개(승인 대기) 건이면 관리자 전원에게 24_알림.
-- 멱등: CREATE OR REPLACE + DROP TRIGGER IF EXISTS.
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION notify_admins_on_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 승인 대기(비공개) 신규 리뷰만 관리자에게 통지
  IF NEW.is_public IS NOT TRUE THEN
    INSERT INTO "24_알림" (user_id, notification_type, title, message, link, is_read)
    SELECT m.id, 'service',
      '📝 새 리뷰 승인 대기',
      '"' || COALESCE(NEW.exhibition_name, '') || '" 건에 새 리뷰가 등록되어 검토가 필요합니다.',
      '/admin-dashboard.html#reviews',
      false
    FROM "01_회원" m WHERE m.role = 'admin';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_admins_on_review ON "49_통역사리뷰";

CREATE TRIGGER trg_notify_admins_on_review
AFTER INSERT ON "49_통역사리뷰"
FOR EACH ROW
EXECUTE FUNCTION notify_admins_on_review();
