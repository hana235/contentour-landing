// 사업자등록증 승인 게이트
// 정책(B): 결제·계약 확정은 관리자가 사업자등록증을 '승인(approved)'한 고객만 가능.
// 가입 시 등록증은 선택이라, 미등록/검수중(pending)/반려(rejected) 상태는 결제 단계에서 차단한다.
// (견적 요청·상담 등 앞단은 자유롭게 허용 — 결제 직전에만 검증)

async function getBusinessStatus(sb, userId) {
    if (!userId) return 'none';
    try {
        const { data } = await sb.from('01_회원')
            .select('business_registration_status')
            .eq('id', userId).single();
        return (data && data.business_registration_status) || 'none';
    } catch (e) {
        return 'none';
    }
}

// 승인됐으면 null(통과), 아니면 { status, code, error } 반환 → 호출측에서 403 응답
async function checkBusinessApproved(sb, userId) {
    const status = await getBusinessStatus(sb, userId);
    if (status === 'approved') return null;
    const msg = status === 'pending'
        ? '사업자등록증 검수가 진행 중입니다. 승인 완료 후 결제가 가능합니다.'
        : status === 'rejected'
            ? '사업자등록증이 반려되었습니다. 마이페이지에서 다시 등록해주세요.'
            : '결제 전 사업자등록증 등록·승인이 필요합니다. 마이페이지에서 등록해주세요.';
    return { status: status, code: 'business_not_approved', error: msg };
}

module.exports = { getBusinessStatus, checkBusinessApproved };
