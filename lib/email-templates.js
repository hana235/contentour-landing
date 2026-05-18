/**
 * 공통 이메일 템플릿 + Resend 발송 헬퍼
 * - 모든 발송은 안전 모드: 실패해도 throw 안 함 (메인 흐름 보호)
 * - From: noreply@contentour.co.kr (도메인 인증됨)
 * - 사용처: api/admin-app.js, api/assign.js, api/payment.js
 */

const { Resend } = require('resend');

const FROM_NAME = '콘텐츄어';
const FROM_EMAIL = 'noreply@contentour.co.kr';
const FROM_HEADER = FROM_NAME + ' <' + FROM_EMAIL + '>';
const APP_URL = 'https://contentour-landing.vercel.app';
const SUPPORT_EMAIL = 'info@contentour.co.kr';
const SUPPORT_PHONE = '02-868-1522';

function getResend() {
    return process.env.RESEND_API_KEY ? new Resend(process.env.RESEND_API_KEY) : null;
}

function escapeHtml(s) {
    return String(s == null ? '' : s)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function formatKRW(n) {
    if (typeof n !== 'number') return '';
    return n.toLocaleString('ko-KR') + '원';
}

function formatDate(iso) {
    if (!iso) return '';
    try {
        const d = new Date(iso);
        const yyyy = d.getFullYear();
        const mm = String(d.getMonth() + 1).padStart(2, '0');
        const dd = String(d.getDate()).padStart(2, '0');
        return yyyy + '-' + mm + '-' + dd;
    } catch (e) { return ''; }
}

// ── 공통 레이아웃 ──────────────────────────
function wrapTemplate({ headerColor, headerSubtitle, title, bodyHTML }) {
    const accent = headerColor || '#0a2a5e';
    return `
        <div style="max-width:600px;margin:0 auto;font-family:'Noto Sans KR',sans-serif;color:#1a2a4a;">
            <div style="background:linear-gradient(135deg,${accent},#1565c0);padding:32px;text-align:center;border-radius:16px 16px 0 0;">
                <h1 style="color:#fff;font-size:1.4rem;margin:0;">CONTENTOUR</h1>
                <p style="color:rgba(255,255,255,0.7);font-size:0.85rem;margin-top:6px;">${escapeHtml(headerSubtitle || '')}</p>
            </div>
            <div style="background:#fff;padding:32px;border:1px solid #e5eaf2;border-top:none;">
                <h2 style="font-size:1.1rem;margin:0 0 18px;color:${accent};">${escapeHtml(title)}</h2>
                ${bodyHTML}
            </div>
            <div style="background:#f8fafc;padding:20px 32px;border:1px solid #e5eaf2;border-top:none;border-radius:0 0 16px 16px;">
                <p style="font-size:0.75rem;color:#999;margin:0;line-height:1.6;">
                    콘텐츄어 | 서울시 구로구 디지털로26길 43, 대륭포스트타워 8차 L동 204호<br>
                    문의: ${SUPPORT_EMAIL} | ${SUPPORT_PHONE}
                </p>
            </div>
        </div>
    `;
}

function infoTable(rows) {
    const trs = rows.map(([k, v]) =>
        `<tr><td style="padding:8px 0;color:#666;width:120px;font-size:0.88rem;">${escapeHtml(k)}</td>` +
        `<td style="padding:8px 0;font-weight:700;color:#1a2a4a;font-size:0.92rem;">${v}</td></tr>`
    ).join('');
    return `<div style="background:#f0f5ff;border:1.5px solid #dce6f5;border-radius:12px;padding:18px 22px;margin:18px 0;">
        <table style="width:100%;">${trs}</table>
    </div>`;
}

function ctaButton(label, url, color) {
    return `<a href="${url}" style="display:inline-block;background:linear-gradient(135deg,${color || '#1565c0'},#0d47a1);color:#fff;padding:13px 30px;border-radius:10px;text-decoration:none;font-weight:700;font-size:0.92rem;margin-top:8px;">${escapeHtml(label)} →</a>`;
}

// ── 안전 발송 헬퍼 ──────────────────────────
async function safeSend({ to, subject, html, label }) {
    const resend = getResend();
    if (!resend) {
        console.log('[email] RESEND_API_KEY 미설정 — ' + label + ' 발송 생략');
        return { success: false, reason: 'no_api_key' };
    }
    if (!to) {
        console.log('[email] ' + label + ' 발송 생략: 수신자 없음');
        return { success: false, reason: 'no_recipient' };
    }
    try {
        const { data, error } = await resend.emails.send({
            from: FROM_HEADER,
            to: to,
            subject: subject,
            html: html
        });
        if (error) throw error;
        console.log('[email] ' + label + ' 발송 OK to ' + to + ' (' + (data && data.id) + ')');
        return { success: true, id: data && data.id };
    } catch (e) {
        console.error('[email] ' + label + ' 발송 실패:', e && e.message);
        return { success: false, reason: e && e.message };
    }
}

// ═════════════════════════════════════════════════
// 1. 통역사 배정/계약 체결
// ═════════════════════════════════════════════════
async function emailContractAssignedToCustomer({ customerEmail, customerName, interpreterName, expo, startDate, endDate, totalAmount }) {
    const html = wrapTemplate({
        headerColor: '#0a2a5e',
        headerSubtitle: '통역사 배정 안내',
        title: '🤝 통역사가 배정되었습니다',
        bodyHTML: `
            <p style="font-size:0.95rem;line-height:1.7;margin:0 0 12px;">${escapeHtml(customerName || '고객')}님, 안녕하세요.</p>
            <p style="font-size:0.9rem;line-height:1.7;color:#4a5a75;margin:0 0 8px;">
                의뢰하신 견적에 대해 통역사 배정이 완료되었습니다. 아래 정보를 확인해주세요.
            </p>
            ${infoTable([
                ['전시회', escapeHtml(expo || '-')],
                ['배정 통역사', escapeHtml(interpreterName || '-')],
                ['진행 기간', escapeHtml(formatDate(startDate)) + (endDate ? ' ~ ' + escapeHtml(formatDate(endDate)) : '')],
                ['결제 예정 금액', formatKRW(totalAmount)]
            ])}
            <p style="font-size:0.86rem;color:#e65100;margin:0 0 16px;line-height:1.6;">
                ⚠️ 정식 계약 체결을 위해 대시보드에서 <strong>계약서 확인 및 결제</strong>를 진행해주세요.
            </p>
            ${ctaButton('대시보드에서 계약서 확인하기', APP_URL + '/customer-dashboard.html#contracts')}
        `
    });
    return safeSend({
        to: customerEmail,
        subject: '[콘텐츄어] 통역사가 배정되었습니다 — ' + (expo || ''),
        html,
        label: '배정-고객사'
    });
}

async function emailContractAssignedToInterpreter({ interpreterEmail, interpreterName, expo, customerCompany, startDate, endDate }) {
    const html = wrapTemplate({
        headerColor: '#1565c0',
        headerSubtitle: '신규 통역 건 배정',
        title: '📋 새 통역 건이 배정되었습니다',
        bodyHTML: `
            <p style="font-size:0.95rem;line-height:1.7;margin:0 0 12px;">${escapeHtml(interpreterName || '통역사')}님, 안녕하세요.</p>
            <p style="font-size:0.9rem;line-height:1.7;color:#4a5a75;margin:0 0 8px;">
                새 통역 건이 회원님께 배정되었습니다. 대시보드에서 상세 내용을 확인해주세요.
            </p>
            ${infoTable([
                ['전시회', escapeHtml(expo || '-')],
                ['고객사', escapeHtml(customerCompany || '-')],
                ['진행 기간', escapeHtml(formatDate(startDate)) + (endDate ? ' ~ ' + escapeHtml(formatDate(endDate)) : '')]
            ])}
            ${ctaButton('통역사 대시보드 바로가기', APP_URL + '/interpreter-dashboard.html')}
        `
    });
    return safeSend({
        to: interpreterEmail,
        subject: '[콘텐츄어] 새 통역 건이 배정되었습니다 — ' + (expo || ''),
        html,
        label: '배정-통역사'
    });
}

// ═════════════════════════════════════════════════
// 2. 결제 완료
// ═════════════════════════════════════════════════
async function emailPaymentCompleteToCustomer({ customerEmail, customerName, expo, paymentType, amount, totalAmount }) {
    const ptLabel = paymentType === 'deposit' ? '계약금' : (paymentType === 'balance' ? '잔금' : '결제');
    const html = wrapTemplate({
        headerColor: '#2e7d32',
        headerSubtitle: '결제 완료',
        title: '💳 결제가 완료되었습니다',
        bodyHTML: `
            <p style="font-size:0.95rem;line-height:1.7;margin:0 0 12px;">${escapeHtml(customerName || '고객')}님, 안녕하세요.</p>
            <p style="font-size:0.9rem;line-height:1.7;color:#4a5a75;margin:0 0 8px;">
                ${ptLabel} 결제가 정상적으로 처리되었습니다. 영수증은 대시보드에서 다운로드하실 수 있습니다.
            </p>
            ${infoTable([
                ['전시회', escapeHtml(expo || '-')],
                ['결제 구분', ptLabel],
                ['결제 금액', formatKRW(amount)],
                ['계약 총액', formatKRW(totalAmount)]
            ])}
            ${ctaButton('대시보드에서 영수증 보기', APP_URL + '/customer-dashboard.html#contracts', '#2e7d32')}
        `
    });
    return safeSend({
        to: customerEmail,
        subject: '[콘텐츄어] ' + ptLabel + ' 결제가 완료되었습니다',
        html,
        label: '결제-고객사'
    });
}

async function emailPaymentCompleteToInterpreter({ interpreterEmail, interpreterName, expo, paymentType, customerCompany }) {
    const ptLabel = paymentType === 'deposit' ? '계약금' : (paymentType === 'balance' ? '잔금' : '결제');
    const isFinal = paymentType === 'balance' || paymentType === 'full';
    const html = wrapTemplate({
        headerColor: '#2e7d32',
        headerSubtitle: '고객사 결제 완료',
        title: isFinal ? '✅ 잔금 결제가 완료되었습니다' : '💰 ' + ptLabel + ' 결제가 들어왔습니다',
        bodyHTML: `
            <p style="font-size:0.95rem;line-height:1.7;margin:0 0 12px;">${escapeHtml(interpreterName || '통역사')}님, 안녕하세요.</p>
            <p style="font-size:0.9rem;line-height:1.7;color:#4a5a75;margin:0 0 8px;">
                ${escapeHtml(customerCompany || '고객사')}의 ${ptLabel} 결제가 완료되었습니다.
                ${isFinal ? '<br><strong>정산 가능 상태가 되었으니 정산 신청 후 진행해주세요.</strong>' : ''}
            </p>
            ${infoTable([
                ['전시회', escapeHtml(expo || '-')],
                ['고객사', escapeHtml(customerCompany || '-')],
                ['결제 구분', ptLabel]
            ])}
            ${ctaButton('통역사 대시보드 바로가기', APP_URL + '/interpreter-dashboard.html', '#2e7d32')}
        `
    });
    return safeSend({
        to: interpreterEmail,
        subject: '[콘텐츄어] ' + (isFinal ? '잔금 결제 완료 — 정산 가능' : ptLabel + ' 결제 완료 안내'),
        html,
        label: '결제-통역사'
    });
}

// ═════════════════════════════════════════════════
// 3. 계약 취소
// ═════════════════════════════════════════════════
async function emailContractCancelled({ recipientEmail, recipientName, recipientRole, expo, cancelReason, cancelledByLabel, action }) {
    // action: 'approved' | 'rejected'
    const isApproved = action === 'approved';
    const headerColor = isApproved ? '#c62828' : '#1565c0';
    const title = isApproved ? '⚠️ 계약이 취소되었습니다' : '✓ 취소 요청이 거절되었습니다 — 계약 유지';
    const dashboardURL = recipientRole === 'interpreter'
        ? APP_URL + '/interpreter-dashboard.html'
        : APP_URL + '/customer-dashboard.html#contracts';

    const html = wrapTemplate({
        headerColor,
        headerSubtitle: isApproved ? '계약 취소 안내' : '취소 요청 거절',
        title,
        bodyHTML: `
            <p style="font-size:0.95rem;line-height:1.7;margin:0 0 12px;">${escapeHtml(recipientName || '회원')}님, 안녕하세요.</p>
            <p style="font-size:0.9rem;line-height:1.7;color:#4a5a75;margin:0 0 8px;">
                ${isApproved
                    ? '아래 계약 건이 관리자 승인을 거쳐 정식으로 <strong>취소 처리</strong>되었습니다.'
                    : '아래 계약 건의 취소 요청이 관리자에 의해 <strong>거절</strong>되어 계약이 계속 유지됩니다.'}
            </p>
            ${infoTable([
                ['전시회', escapeHtml(expo || '-')],
                ['취소 요청자', escapeHtml(cancelledByLabel || '-')],
                ['사유', escapeHtml(cancelReason || '-')]
            ])}
            <p style="font-size:0.84rem;color:#888;margin:0 0 16px;line-height:1.6;">
                ${isApproved
                    ? '계약 진행 단계에 따라 환불·정산 등의 후속 처리가 있을 수 있습니다. 자세한 사항은 대시보드에서 확인해주세요.'
                    : '거절 사유와 계약 상세는 대시보드에서 확인하실 수 있습니다.'}
            </p>
            ${ctaButton('대시보드에서 확인하기', dashboardURL, headerColor)}
        `
    });
    return safeSend({
        to: recipientEmail,
        subject: '[콘텐츄어] ' + (isApproved ? '계약이 취소되었습니다' : '계약 취소 요청이 거절되었습니다') + ' — ' + (expo || ''),
        html,
        label: '취소-' + (recipientRole || '회원')
    });
}

// ═════════════════════════════════════════════════
// 4. D-day 컨펌 안내 (cron에서 호출 예정)
// ═════════════════════════════════════════════════
async function emailDdayReminderToInterpreter({ interpreterEmail, interpreterName, expo, startDate, daysLeft }) {
    const label = daysLeft <= 0 ? '오늘' : ('D-' + daysLeft);
    const html = wrapTemplate({
        headerColor: '#e65100',
        headerSubtitle: '진행 임박 안내',
        title: '⏰ 곧 진행되는 통역 건이 있습니다 (' + label + ')',
        bodyHTML: `
            <p style="font-size:0.95rem;line-height:1.7;margin:0 0 12px;">${escapeHtml(interpreterName || '통역사')}님, 안녕하세요.</p>
            <p style="font-size:0.9rem;line-height:1.7;color:#4a5a75;margin:0 0 8px;">
                배정받으신 통역 건의 진행일이 임박했습니다. 대시보드 홈에서 <strong>"확인 완료"</strong> 버튼을 눌러주세요.
                관리자가 노쇼 위험 여부를 파악하기 위한 확인 절차입니다.
            </p>
            ${infoTable([
                ['전시회', escapeHtml(expo || '-')],
                ['진행일', escapeHtml(formatDate(startDate))],
                ['남은 일수', label]
            ])}
            ${ctaButton('확인 완료 처리하러 가기', APP_URL + '/interpreter-dashboard.html', '#e65100')}
        `
    });
    return safeSend({
        to: interpreterEmail,
        subject: '[콘텐츄어] ' + label + ' 진행 통역 건 확인 요청 — ' + (expo || ''),
        html,
        label: 'Dday-통역사'
    });
}

module.exports = {
    emailContractAssignedToCustomer,
    emailContractAssignedToInterpreter,
    emailPaymentCompleteToCustomer,
    emailPaymentCompleteToInterpreter,
    emailContractCancelled,
    emailDdayReminderToInterpreter,
    // 테스트/디버그용
    _safeSend: safeSend
};
