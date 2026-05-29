// ══════════════ 공유 상수 & 유틸리티 ══════════════
// 여러 JS 파일에서 중복 정의되던 상수를 통합

window.CT = window.CT || {};

// ── 상태 매핑 ──
CT.SETTLEMENT_STATUS = {
    request: '승인 대기',
    approved: '승인 완료',
    paid: '입금 완료',
    rejected: '반려'
};

CT.CONTRACT_STATUS = {
    pending: '대기',
    confirmed: '확정',
    in_progress: '진행중',
    completed: '완료',
    cancelled: '취소'
};

CT.USER_ROLES = {
    admin: '관리자',
    customer: '고객사',
    interpreter: '통역사',
    member: '회원'
};

// ── 언어 매핑 ──
CT.LANG_MAP = {
    en: '영어', jp: '일본어', zh: '중국어', de: '독일어',
    fr: '프랑스어', es: '스페인어', ru: '러시아어', ar: '아랍어'
};

// ── Supabase 클라이언트 통합 접근 ──
CT.getClient = function() {
    return window.sbClient || null;
};

// ── HTML 이스케이프 ──
CT.escHtml = function(str) {
    if (!str) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
};

// ── 날짜 포맷 ──
CT.formatDate = function(dateStr) {
    if (!dateStr) return '-';
    var d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    return d.getFullYear() + '.' + String(d.getMonth() + 1).padStart(2, '0') + '.' + String(d.getDate()).padStart(2, '0');
};

// ── 금액 포맷 ──
CT.formatMoney = function(amount) {
    if (!amount) return '₩0';
    return '₩' + Number(amount).toLocaleString();
};

// ── 상대 시간 ──
CT.timeAgo = function(dateStr) {
    if (!dateStr) return '';
    var diff = Date.now() - new Date(dateStr).getTime();
    var min = Math.floor(diff / 60000);
    if (min < 1) return '방금';
    if (min < 60) return min + '분 전';
    var hr = Math.floor(min / 60);
    if (hr < 24) return hr + '시간 전';
    var day = Math.floor(hr / 24);
    if (day < 7) return day + '일 전';
    return CT.formatDate(dateStr);
};

// ── 표시용 계약번호 CT-YYYYMMDD-XXXX ──
// 우선순위: 저장된 contract_no(트리거가 생성 시 부여) → (마이그레이션 적용 전) 계산 fallback.
// 날짜=계약 생성일(created_at) 기준이라 고객·통역사·admin 어디서나 동일. 내부 UUID는 유지.
CT.contractNo = function(c) {
    if (!c) return '';
    if (c.contractNo) return c.contractNo;
    if (c.contract_no) return c.contract_no;
    var dateStr = c.createdAt || c.created_at || '';
    if (!dateStr && c.timeline && c.timeline.length) {
        var s = c.timeline.find(function(t){ return t.step === '계약 체결' && t.done; });
        if (s && s.date) dateStr = s.date;
    }
    if (!dateStr) dateStr = new Date().toISOString().slice(0, 10);
    var d = String(dateStr).replace(/[^0-9]/g, '').slice(0, 8);
    if (d.length !== 8) d = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    var suffix = String(c.id || c.dbId || '').replace(/[^a-zA-Z0-9]/g, '').slice(-4).toUpperCase() || '0000';
    return 'CT-' + d + '-' + suffix;
};

// ── 금액 계산 (VAT·플랫폼 수수료) ──
// 모델: 통역사 일당 = 공급가(net), 부가세 = net×10%, 총액 = net×1.1.
// 통역사측 플랫폼 수수료는 VAT와 별개 개념(정산에서 공제)이라 상수를 분리한다.
CT.VAT_RATE = 0.1;             // 부가가치세율
CT.PLATFORM_FEE_RATE = 0.1;    // 통역사 정산 플랫폼 수수료율 (VAT와 무관)
CT.vatFromNet   = function(net)   { return Math.round((net   || 0) * CT.VAT_RATE); };          // 공급가 → 부가세
CT.totalFromNet = function(net)   { return (net || 0) + CT.vatFromNet(net); };                  // 공급가 → 총액(VAT 포함)
CT.vatFromTotal = function(total) { return Math.round((total || 0) * 10 / 110); };              // 총액(VAT 포함) → 부가세
CT.netFromTotal = function(total) { return (total || 0) - CT.vatFromTotal(total); };             // 총액(VAT 포함) → 공급가
CT.platformFee  = function(net)   { return Math.round((net   || 0) * CT.PLATFORM_FEE_RATE); };   // 공급가 → 통역사측 플랫폼 수수료

// ── 감사 로그 기록 ──
CT.logAudit = async function(action, targetTable, targetId, details) {
    var sb = CT.getClient();
    if (!sb) return;
    try {
        await sb.rpc('log_audit', {
            p_action: action,
            p_target_table: targetTable || null,
            p_target_id: targetId || null,
            p_details: details || {}
        });
    } catch (e) {
        console.warn('감사 로그 기록 실패:', e);
    }
};
