-- ═══════════════════════════════════════════════════════════════
-- 정산 재요청 RPC: rerequest_settlement (2026-06-02)
-- ═══════════════════════════════════════════════════════════════
-- 배경:
--   통역사 대시보드의 "정산 재요청"(stlReRequest)이 localStorage만 바꾸고
--   43_정산내역 DB를 갱신하지 않아 관리자에게 전파되지 않음.
--   직접 UPDATE는 protect_settlement_columns 트리거가 통역사의 status 변경을
--   OLD값으로 강제(무음 차단)하므로 불가 → SECURITY DEFINER RPC로 처리.
--
-- 동작:
--   - 호출자가 해당 정산의 통역사 본인(interpreter_id = auth.uid())이고
--     status='rejected'일 때만 status='request'로 복귀 + 반려필드 초기화.
--   - 관리자 전원에게 24_알림(type='settlement') 발송.
--
-- 멱등: CREATE OR REPLACE.
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.rerequest_settlement(p_settlement_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
    v_settlement "43_정산내역"%ROWTYPE;
BEGIN
    SELECT * INTO v_settlement FROM "43_정산내역" WHERE id = p_settlement_id;
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', '정산 내역을 찾을 수 없습니다.');
    END IF;

    -- 본인 소유 검증
    IF v_settlement.interpreter_id <> auth.uid() THEN
        RETURN json_build_object('success', false, 'error', '본인 정산만 재요청할 수 있습니다.');
    END IF;

    -- 반려 상태에서만 재요청 가능
    IF v_settlement.status <> 'rejected' THEN
        RETURN json_build_object('success', false, 'error', '반려된 정산만 재요청할 수 있습니다.');
    END IF;

    UPDATE "43_정산내역"
    SET status = 'request',
        requested_at = now(),
        rejected_at = NULL,
        rejected_by = NULL,
        reject_reason = NULL
    WHERE id = p_settlement_id;

    -- 관리자 전원에게 알림
    INSERT INTO "24_알림" (user_id, notification_type, title, message, link)
    SELECT m.id, 'settlement', '🔄 정산 재요청',
        COALESCE(v_settlement.exhibition_name, '') || ' 정산이 재요청되었습니다. 검토해주세요.',
        '/admin-dashboard.html#settlement'
    FROM "01_회원" m WHERE m.role = 'admin';

    RETURN json_build_object('success', true);
END;
$function$;

-- authenticated에 실행 권한 (내부에서 본인 검증)
GRANT EXECUTE ON FUNCTION public.rerequest_settlement(uuid) TO authenticated;
