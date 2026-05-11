const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://jgeqbdrfpekzuumaklvx.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnZXFiZHJmcGVrenV1bWFrbHZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4MzgwMzQsImV4cCI6MjA5MDQxNDAzNH0.C2y3UiPtHIF2s4nPvbGycN927HOG4YpO86FfgZAelUw';
const PORTONE_SECRET = process.env.PORTONE_V2_API_SECRET;

const sb = createClient(SUPABASE_URL, SERVICE_KEY);
const sbAuth = createClient(SUPABASE_URL, ANON_KEY);

module.exports = async function handler(req, res) {
    if (req.method !== 'POST') {
        return res.status(405).json({ success: false, error: 'Method not allowed' });
    }
    if (!SERVICE_KEY || !PORTONE_SECRET) {
        return res.status(500).json({ success: false, error: '서버 설정 오류 (env 누락)' });
    }

    // 1) 호출자 인증
    const authHeader = req.headers.authorization || '';
    const token = authHeader.replace('Bearer ', '');
    if (!token) return res.status(401).json({ success: false, error: '로그인이 필요합니다.' });

    const { data: { user }, error: authErr } = await sbAuth.auth.getUser(token);
    if (authErr || !user) {
        return res.status(401).json({ success: false, error: '인증 실패' });
    }

    // 2) 입력 검증
    const { paymentId, contractId, paymentType, expectedAmount } = req.body || {};
    if (!paymentId || !contractId || !paymentType) {
        return res.status(400).json({ success: false, error: '필수 파라미터 누락' });
    }
    if (!['deposit', 'balance', 'full'].includes(paymentType)) {
        return res.status(400).json({ success: false, error: '유효하지 않은 결제 유형' });
    }
    if (typeof expectedAmount !== 'number' || expectedAmount <= 0) {
        return res.status(400).json({ success: false, error: '유효하지 않은 결제 금액' });
    }

    try {
        // 3) 계약 조회 + 본인 계약자 검증 (다른 사람 계약을 본인 결제로 등록 못 하게)
        const { data: contract, error: cErr } = await sb
            .from('42_통역계약')
            .select('customer_id, interpreter_id, total_amount')
            .eq('id', contractId)
            .single();
        if (cErr || !contract) {
            return res.status(404).json({ success: false, error: '계약을 찾을 수 없습니다.' });
        }
        if (contract.customer_id !== user.id) {
            return res.status(403).json({ success: false, error: '본인 계약만 결제 가능합니다.' });
        }

        // 4) PortOne V2 REST로 결제 조회
        const portoneRes = await fetch(
            `https://api.portone.io/payments/${encodeURIComponent(paymentId)}`,
            { headers: { 'Authorization': `PortOne ${PORTONE_SECRET}` } }
        );
        if (!portoneRes.ok) {
            const errText = await portoneRes.text();
            console.error('PortOne 조회 실패:', portoneRes.status, errText);
            return res.status(502).json({ success: false, error: 'PG 결제 조회 실패' });
        }
        const payment = await portoneRes.json();

        // 5) PortOne 응답 검증
        if (payment.status !== 'PAID') {
            return res.status(400).json({
                success: false,
                error: `결제가 완료되지 않았습니다 (status: ${payment.status})`
            });
        }
        const actualAmount = payment.amount && payment.amount.total;
        if (typeof actualAmount !== 'number' || actualAmount !== expectedAmount) {
            console.error('금액 불일치:', { expected: expectedAmount, actual: actualAmount, paymentId });
            return res.status(400).json({ success: false, error: '결제 금액 불일치' });
        }
        if (payment.currency && payment.currency !== 'KRW') {
            return res.status(400).json({ success: false, error: '결제 통화 불일치' });
        }

        // customData에서 contractId·paymentType 변조 검증
        let customData = payment.customData;
        if (typeof customData === 'string') {
            try { customData = JSON.parse(customData); } catch (e) { customData = {}; }
        }
        if (customData && customData.contractId && customData.contractId !== contractId) {
            return res.status(400).json({ success: false, error: 'customData 계약 ID 불일치' });
        }
        if (customData && customData.paymentType && customData.paymentType !== paymentType) {
            return res.status(400).json({ success: false, error: 'customData 결제 유형 불일치' });
        }

        // 6) process_payment RPC (멱등성·트랜잭션 보장)
        const methodType = payment.method && payment.method.type
            ? String(payment.method.type).toLowerCase()
            : 'card';
        const { data: rpcResult, error: rpcErr } = await sb.rpc('process_payment', {
            p_contract_id: contractId,
            p_payment_type: paymentType,
            p_amount: actualAmount,
            p_method: methodType,
            p_merchant_uid: payment.id,
            p_imp_uid: payment.id
        });
        if (rpcErr) {
            console.error('process_payment RPC 실패:', rpcErr);
            return res.status(500).json({ success: false, error: '결제 기록 저장 실패' });
        }
        if (rpcResult && rpcResult.success === false) {
            return res.status(400).json(rpcResult);
        }

        return res.status(200).json(Object.assign({ success: true }, rpcResult || {}));
    } catch (e) {
        console.error('verify-payment 예외:', e);
        return res.status(500).json({ success: false, error: e.message || '결제 검증 실패' });
    }
};
