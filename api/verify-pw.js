const crypto = require('crypto');
const { createClient } = require('@supabase/supabase-js');
const { checkRateLimit, clientIp } = require('../lib/rate-limit');

// SHA-256 hash of the site password (password itself is NOT stored here).
// 우선순위: 환경변수 GATE_PASSWORD_HASH(소스코드 밖 = git 노출·오프라인 크래킹 표면 축소).
// 미설정 시 아래 하드코딩 값으로 폴백하여 무중단.
const PASSWORD_HASH = ((process.env.GATE_PASSWORD_HASH || '').trim().toLowerCase())
    || 'b2c6029ad18868353002fd0be04a5f98a5e39134c4a6447b65f28123f3fccfb8';

// 타이밍 공격 방지용 상수시간 비교 (길이 다르면 즉시 false)
function safeEqualHex(a, b) {
    if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) return false;
    return crypto.timingSafeEqual(Buffer.from(a, 'hex'), Buffer.from(b, 'hex'));
}

// rate limit용 service-role 클라이언트 (env 없으면 null → fail-open)
const sb = process.env.SUPABASE_SERVICE_ROLE_KEY
    ? createClient('https://jgeqbdrfpekzuumaklvx.supabase.co', process.env.SUPABASE_SERVICE_ROLE_KEY)
    : null;

module.exports = async function handler(req, res) {
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    // 무차별 대입 방지 — IP당 분당 15회
    if (!await checkRateLimit(sb, 'pwgate:' + clientIp(req), 15, 60, { failClosed: true })) {
        return res.status(429).json({ ok: false, error: '시도가 너무 많습니다. 잠시 후 다시 시도하세요.' });
    }

    const { password } = req.body || {};
    if (!password || typeof password !== 'string') {
        return res.status(400).json({ ok: false });
    }

    const hash = crypto.createHash('sha256').update(password).digest('hex');

    if (safeEqualHex(hash, PASSWORD_HASH)) {
        // 서버단 게이트(middleware.js)용 쿠키 발급 — HttpOnly·Secure·SameSite=Lax, 7일
        // GATE_TOKEN 미설정이면 쿠키 없이 통과(미들웨어도 비활성이라 정합)
        var token = (process.env.GATE_TOKEN || '').trim();  // 붙여넣기 공백/줄바꿈 방어
        if (token) {
            res.setHeader('Set-Cookie',
                'ct_gate=' + token + '; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=604800');
        }
        return res.status(200).json({ ok: true });
    }

    return res.status(401).json({ ok: false });
};
