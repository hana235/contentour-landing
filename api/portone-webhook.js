const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

const SUPABASE_URL = 'https://jgeqbdrfpekzuumaklvx.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const PORTONE_SECRET = process.env.PORTONE_V2_API_SECRET;
const WEBHOOK_SECRET = process.env.PORTONE_WEBHOOK_SECRET;

const sb = createClient(SUPABASE_URL, SERVICE_KEY);

// Vercel 기본 bodyParser 비활성화 — 서명 검증을 위해 raw body 필요
module.exports.config = { api: { bodyParser: false } };

function readRawBody(req) {
    return new Promise(function (resolve, reject) {
        let data = '';
        req.on('data', function (chunk) { data += chunk; });
        req.on('end', function () { resolve(data); });
        req.on('error', reject);
    });
}

// PortOne V2 Webhook 서명 검증 (Svix 표준 호환)
// signature header: "v1,base64sig" 가 공백으로 여러 개 묶일 수 있음
function verifySignature(rawBody, headers, secret) {
    const id = headers['webhook-id'];
    const timestamp = headers['webhook-timestamp'];
    const sigHeader = headers['webhook-signature'];
    if (!id || !timestamp || !sigHeader || !secret) return false;

    // 5분 이상 지난 요청은 거절 (replay 방지)
    const tsNum = parseInt(timestamp, 10);
    if (!Number.isFinite(tsNum)) return false;
    const now = Math.floor(Date.now() / 1000);
    if (Math.abs(now - tsNum) > 300) return false;

    const payload = id + '.' + timestamp + '.' + rawBody;

    // PortOne webhook secret은 보통 "whsec_BASE64" 형태로 전달됨
    const secretRaw = secret.startsWith('whsec_') ? secret.slice(6) : secret;
    let secretBuf;
    try { secretBuf = Buffer.from(secretRaw, 'base64'); }
    catch (e) { secretBuf = Buffer.from(secretRaw, 'utf8'); }

    const expected = crypto.createHmac('sha256', secretBuf).update(payload).digest('base64');

    const sigList = sigHeader.split(' ');
    return sigList.some(function (sig) {
        const parts = sig.split(',');
        if (parts.length !== 2 || parts[0] !== 'v1') return false;
        try {
            const a = Buffer.from(parts[1], 'base64');
            const b = Buffer.from(expected, 'base64');
            return a.length === b.length && crypto.timingSafeEqual(a, b);
        } catch (e) { return false; }
    });
}

module.exports = async function handler(req, res) {
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }
    if (!SERVICE_KEY || !PORTONE_SECRET || !WEBHOOK_SECRET) {
        console.error('Webhook env 누락');
        return res.status(500).json({ error: 'Server config' });
    }

    let rawBody;
    try { rawBody = await readRawBody(req); }
    catch (e) { return res.status(400).json({ error: 'Invalid body' }); }

    if (!verifySignature(rawBody, req.headers, WEBHOOK_SECRET)) {
        console.error('PortOne webhook 서명 검증 실패');
        return res.status(401).json({ error: 'Invalid signature' });
    }

    let event;
    try { event = JSON.parse(rawBody); }
    catch (e) { return res.status(400).json({ error: 'Invalid JSON' }); }

    const type = event.type || '';
    const paymentId = event.data && event.data.paymentId;
    if (!paymentId) {
        return res.status(200).json({ ok: true, ignored: true });
    }

    try {
        // ── 결제 완료 (가상계좌 입금 포함) ──
        if (type === 'Transaction.Paid') {
            const portoneRes = await fetch(
                'https://api.portone.io/payments/' + encodeURIComponent(paymentId),
                { headers: { 'Authorization': 'PortOne ' + PORTONE_SECRET } }
            );
            if (!portoneRes.ok) {
                console.error('webhook PortOne 조회 실패:', portoneRes.status);
                return res.status(500).json({ ok: false });
            }
            const payment = await portoneRes.json();
            if (payment.status !== 'PAID') {
                return res.status(200).json({ ok: true, skipped: true });
            }

            let customData = payment.customData;
            if (typeof customData === 'string') {
                try { customData = JSON.parse(customData); } catch (e) { customData = {}; }
            }
            const contractId = customData && customData.contractId;
            const paymentType = (customData && customData.paymentType) || 'deposit';
            if (!contractId) {
                console.error('webhook customData 누락:', paymentId);
                return res.status(200).json({ ok: false, error: 'No contractId' });
            }
            if (!['deposit', 'balance', 'full'].includes(paymentType)) {
                return res.status(200).json({ ok: false, error: 'Invalid paymentType' });
            }

            const methodType = (payment.method && payment.method.type)
                ? String(payment.method.type).toLowerCase() : 'virtual';
            const amount = payment.amount && payment.amount.total;

            // process_payment 멱등성: imp_uid UNIQUE로 중복 INSERT 차단
            const { error: rpcErr } = await sb.rpc('process_payment', {
                p_contract_id: contractId,
                p_payment_type: paymentType,
                p_amount: amount,
                p_method: methodType,
                p_merchant_uid: payment.id,
                p_imp_uid: payment.id
            });
            if (rpcErr) {
                console.error('webhook process_payment 실패:', rpcErr);
                return res.status(500).json({ ok: false });
            }
        }
        // ── PG측 환불 (관리자 PortOne 콘솔 직접 환불 또는 자동 취소) ──
        else if (type === 'Transaction.Cancelled' || type === 'Transaction.PartialCancelled') {
            await sb.from('47_결제기록')
                .update({
                    status: 'refunded',
                    cancelled_at: new Date().toISOString(),
                    updated_at: new Date().toISOString()
                })
                .eq('imp_uid', paymentId);
        }
        // ── 그 외 이벤트(Ready, VirtualAccountIssued, PayPending 등)는 우선 무시 ──

        return res.status(200).json({ ok: true });
    } catch (e) {
        console.error('portone-webhook 예외:', e);
        // 200 반환으로 PortOne 무한 retry 차단 (재시도 필요하면 500)
        return res.status(200).json({ ok: false, error: e.message });
    }
};
