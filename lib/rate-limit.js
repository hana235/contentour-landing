// ════════════════════════════════════════════════════════════════
// 서버리스(Vercel) 환경용 rate limit.
// 인메모리는 인스턴스마다 따로라 무용 → Postgres(Supabase) 기반 check_rate_limit RPC 사용.
// migration-rate-limit.sql 적용 후 활성화됨.
//
// 실패 처리 정책(2단계):
//  1) RPC/테이블 자체가 미배포(마이그레이션 미적용)  → 통과(fail-open).
//     설정 문제일 뿐이며, 여기서 막으면 사이트 전체가 마비되므로 가용성 우선.
//  2) 배포는 됐는데 일시적 DB 오류/예외              → opts.failClosed 이면 차단(fail-closed),
//     아니면 통과. 인증·결제 등 핵심 경로만 failClosed:true 로 호출.
// ════════════════════════════════════════════════════════════════

// RPC/테이블이 아예 배포되지 않았음을 나타내는 오류인지 판별.
// (undefined_function 42883, undefined_table 42P01, PostgREST 함수 미발견 PGRST202)
function isNotDeployed(error) {
    if (!error) return false;
    const code = error.code || '';
    if (code === 'PGRST202' || code === '42883' || code === '42P01') return true;
    const msg = (error.message || '') + ' ' + (error.details || '');
    return /check_rate_limit|98_rate_limit|does not exist|could not find|schema cache/i.test(msg);
}

// true = 허용, false = 차단(한도 초과 또는 fail-closed).
// opts.failClosed: 배포된 상태에서의 일시 오류 시 차단할지(기본 false = 통과).
async function checkRateLimit(sb, key, max, windowSeconds, opts) {
    const failClosed = !!(opts && opts.failClosed);
    if (!sb) return true; // 클라이언트 미주입은 설정 문제 → 통과(가용성)
    try {
        const { data, error } = await sb.rpc('check_rate_limit', {
            p_key: String(key).slice(0, 200),
            p_max: max,
            p_window_seconds: windowSeconds
        });
        if (error) {
            if (isNotDeployed(error)) {
                console.warn('[rate-limit] RPC 미배포 — 통과 처리:', error.message);
                return true; // 마이그레이션 미적용: 항상 통과
            }
            console.warn('[rate-limit] RPC 오류' + (failClosed ? ' (차단)' : ' (통과)') + ':', error.message);
            return !failClosed; // 배포됨 + 일시 오류: 핵심 경로는 차단
        }
        return data === true;
    } catch (e) {
        console.warn('[rate-limit] 예외' + (failClosed ? ' (차단)' : ' (통과)') + ':', e && e.message);
        return !failClosed;
    }
}

// 프록시 헤더에서 클라이언트 IP 추출 (Vercel은 x-forwarded-for 설정)
function clientIp(req) {
    const xff = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || '';
    return String(xff).split(',')[0].trim() || 'unknown';
}

module.exports = { checkRateLimit, clientIp };
