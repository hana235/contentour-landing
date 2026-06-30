// 통합 라우터: my-inquiries / my-contracts
// vercel.json rewrites가 옛 URL을 _route 쿼리로 매핑

const { createClient } = require('@supabase/supabase-js');
const { checkRateLimit } = require('../lib/rate-limit');

const SUPABASE_URL = 'https://jgeqbdrfpekzuumaklvx.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnZXFiZHJmcGVrenV1bWFrbHZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4MzgwMzQsImV4cCI6MjA5MDQxNDAzNH0.C2y3UiPtHIF2s4nPvbGycN927HOG4YpO86FfgZAelUw';

const sb = createClient(SUPABASE_URL, SERVICE_KEY);
const sbAuth = createClient(SUPABASE_URL, ANON_KEY);

async function authenticate(req) {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.replace('Bearer ', '');
    if (!token) return { error: '인증이 필요합니다.', status: 401 };
    const { data: { user }, error } = await sbAuth.auth.getUser(token);
    if (error || !user) return { error: '인증 실패', status: 401 };
    return { user };
}

// ────────────────────────── my-inquiries ──────────────────────────
async function handleMyInquiries(req, res) {
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });
    const auth = await authenticate(req);
    if (auth.error) return res.status(auth.status).json({ error: auth.error });

    const { data: profile } = await sb.from('01_회원').select('role, name').eq('id', auth.user.id).single();
    if (!profile || (profile.role !== 'interpreter' && profile.role !== 'admin')) {
        return res.status(403).json({ error: '통역사 권한이 필요합니다.' });
    }

    try {
        const { data, error } = await sb
            .from('46_ITQ견적문의')
            .select('*')
            .like('admin_note', '%"inquiry_type":"direct"%')
            .order('created_at', { ascending: false });
        if (error) throw error;

        const filtered = (data || []).filter(d => {
            try {
                const note = typeof d.admin_note === 'string' ? JSON.parse(d.admin_note) : d.admin_note;
                if (!note || note.inquiry_type !== 'direct') return false;
                // 본인 user.id로 지정된 의뢰만 (이름 매칭 fallback 제거 — 동명이인 누출 방지)
                return note.requested_interpreter_id === auth.user.id;
            } catch (e) { return false; }
        });

        return res.status(200).json(filtered);
    } catch (e) {
        console.error('My inquiries error:', e);
        return res.status(500).json({ error: '요청 처리 중 오류가 발생했습니다.' });
    }
}

// ────────────────────────── my-contracts ──────────────────────────
async function handleMyContracts(req, res) {
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });
    const auth = await authenticate(req);
    if (auth.error) return res.status(auth.status).json({ error: auth.error });

    const { data: profile } = await sb.from('01_회원').select('role, name').eq('id', auth.user.id).single();
    if (!profile) return res.status(404).json({ error: '회원 정보를 찾을 수 없습니다.' });

    try {
        let query = sb.from('42_통역계약').select('*');
        if (profile.role === 'customer') query = query.eq('customer_id', auth.user.id);
        else if (profile.role === 'interpreter') query = query.eq('interpreter_id', auth.user.id);
        else if (profile.role !== 'admin') return res.status(403).json({ error: '접근 권한이 없습니다.' });

        const { data: contracts, error } = await query.order('created_at', { ascending: false });
        if (error) throw error;

        const userIds = new Set();
        contracts.forEach(c => {
            if (c.interpreter_id) userIds.add(c.interpreter_id);
            if (c.customer_id) userIds.add(c.customer_id);
        });

        let nameMap = {};
        if (userIds.size > 0) {
            const { data: users } = await sb.from('01_회원').select('id, name, email').in('id', Array.from(userIds));
            if (users) users.forEach(u => { nameMap[u.id] = u; });
        }

        const interpIds = contracts.map(c => c.interpreter_id).filter(Boolean);
        let interpMap = {};
        if (interpIds.length > 0) {
            const { data: profiles } = await sb.from('40_통역사프로필')
                .select('user_id, display_name, languages, profile_image_url').in('user_id', interpIds);
            if (profiles) profiles.forEach(p => { interpMap[p.user_id] = p; });
        }

        const result = contracts.map(c => ({
            ...c,
            _interpreterName: (interpMap[c.interpreter_id] || {}).display_name || (nameMap[c.interpreter_id] || {}).name || '통역사',
            _interpreterPhoto: (interpMap[c.interpreter_id] || {}).profile_image_url || '',
            _interpreterLangs: (interpMap[c.interpreter_id] || {}).languages || [],
            _customerName: (nameMap[c.customer_id] || {}).name || '고객',
            _customerEmail: (nameMap[c.customer_id] || {}).email || ''
        }));

        res.setHeader('Cache-Control', 'no-cache');
        return res.status(200).json(result);
    } catch (e) {
        console.error('Contracts query error:', e);
        return res.status(500).json({ error: '요청 처리 중 오류가 발생했습니다.' });
    }
}

// ────────────────────────── my-showcase-postings ──────────────────────────
// 로그인 고객사 본인이 등록한 통역사 구인공고 목록 + 지원자/매칭 카운트
async function handleMyShowcasePostings(req, res) {
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });
    const auth = await authenticate(req);
    if (auth.error) return res.status(auth.status).json({ error: auth.error });

    const { data: profile } = await sb.from('01_회원').select('role').eq('id', auth.user.id).single();
    if (!profile || profile.role !== 'customer') {
        return res.status(403).json({ error: '고객사 권한이 필요합니다.' });
    }

    try {
        const { data, error } = await sb
            .from('46_ITQ견적문의')
            .select('id, exhibition_name, location, venue, start_date, end_date, language_pair, headcount, message, showcase_label, showcase_industry, showcase_country_code, company_name_disclosure, review_status, review_note, reviewed_at, contract_id, created_at')
            .eq('source_type', 'direct_posting')
            .eq('posted_by_user_id', auth.user.id)
            .order('created_at', { ascending: false });
        if (error) throw error;

        const postingIds = (data || []).map(d => d.id);
        const countsMap = {};
        if (postingIds.length > 0) {
            const { data: apps } = await sb
                .from('70_구인공고지원')
                .select('posting_id, status')
                .in('posting_id', postingIds);
            (apps || []).forEach(a => {
                if (!countsMap[a.posting_id]) countsMap[a.posting_id] = { total: 0, matched: 0 };
                countsMap[a.posting_id].total += 1;
                if (a.status === 'matched') countsMap[a.posting_id].matched += 1;
            });
        }

        const result = (data || []).map(d => ({
            ...d,
            _applicants_count: countsMap[d.id] ? countsMap[d.id].total : 0,
            _matched_count: countsMap[d.id] ? countsMap[d.id].matched : 0
        }));

        res.setHeader('Cache-Control', 'no-cache');
        return res.status(200).json(result);
    } catch (e) {
        console.error('My showcase postings error:', e);
        return res.status(500).json({ error: '요청 처리 중 오류가 발생했습니다.' });
    }
}

// ────────────────────────── my-showcase-applications ──────────────────────────
// 로그인 통역사 본인이 지원한 구인공고 목록 + 공고 정보 join
async function handleMyShowcaseApplications(req, res) {
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });
    const auth = await authenticate(req);
    if (auth.error) return res.status(auth.status).json({ error: auth.error });

    const { data: profile } = await sb.from('01_회원').select('role').eq('id', auth.user.id).single();
    if (!profile || profile.role !== 'interpreter') {
        return res.status(403).json({ error: '통역사 권한이 필요합니다.' });
    }

    try {
        const { data: apps, error } = await sb
            .from('70_구인공고지원')
            .select('id, posting_id, status, applied_at, updated_at, contract_id')
            .eq('interpreter_id', auth.user.id)
            .order('applied_at', { ascending: false });
        if (error) throw error;
        if (!apps || apps.length === 0) {
            res.setHeader('Cache-Control', 'no-cache');
            return res.status(200).json([]);
        }

        const postingIds = Array.from(new Set(apps.map(a => a.posting_id)));
        const { data: postings } = await sb
            .from('46_ITQ견적문의')
            .select('id, exhibition_name, location, venue, start_date, end_date, language_pair, headcount, showcase_label, showcase_industry, showcase_country_code, review_status, contract_id, company_name_disclosure, company')
            .in('id', postingIds);
        const postingMap = {};
        (postings || []).forEach(p => { postingMap[p.id] = p; });

        const result = apps.map(a => {
            const p = postingMap[a.posting_id] || {};
            const label = (p.company_name_disclosure && p.company) ? p.company : (p.showcase_label || '한국 기업');
            return {
                id: a.id,
                posting_id: a.posting_id,
                status: a.status,
                applied_at: a.applied_at,
                updated_at: a.updated_at,
                contract_id: a.contract_id,
                label,
                isAnonymous: !(p.company_name_disclosure && p.company),
                exhibition: p.exhibition_name || '',
                location: p.location || '',
                venue: p.venue || '',
                start_date: p.start_date || '',
                end_date: p.end_date || '',
                language_pair: p.language_pair || '',
                headcount: p.headcount || 0,
                industry: p.showcase_industry || '',
                country_code: p.showcase_country_code || '',
                posting_review_status: p.review_status,
                posting_contract_id: p.contract_id
            };
        });

        res.setHeader('Cache-Control', 'no-cache');
        return res.status(200).json(result);
    } catch (e) {
        console.error('My showcase applications error:', e);
        return res.status(500).json({ error: '요청 처리 중 오류가 발생했습니다.' });
    }
}

// ────────────────────────── my-showcase-applicants ──────────────────────────
// 로그인 고객사가 본인 공고의 지원자 목록·프로필 조회. 연락처(이메일·전화)는 제외 — 계약 전 비공개.
async function handleMyShowcaseApplicants(req, res) {
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });
    const auth = await authenticate(req);
    if (auth.error) return res.status(auth.status).json({ error: auth.error });

    const { data: profile } = await sb.from('01_회원').select('role').eq('id', auth.user.id).single();
    if (!profile || profile.role !== 'customer') {
        return res.status(403).json({ error: '고객사 권한이 필요합니다.' });
    }

    const postingId = req.query.posting_id ? String(req.query.posting_id).trim() : '';
    if (!postingId) return res.status(400).json({ error: 'posting_id 필수' });

    // 본인 소유 공고 확인
    const { data: posting } = await sb
        .from('46_ITQ견적문의')
        .select('id, posted_by_user_id, source_type, review_status, contract_id')
        .eq('id', postingId).single();
    if (!posting || posting.posted_by_user_id !== auth.user.id || posting.source_type !== 'direct_posting') {
        return res.status(403).json({ error: '본인이 등록한 공고만 조회할 수 있습니다.' });
    }

    try {
        const { data: apps, error } = await sb
            .from('70_구인공고지원')
            .select('id, interpreter_id, status, applied_at')
            .eq('posting_id', postingId)
            .order('applied_at', { ascending: false });
        if (error) throw error;

        const result = { posting: { id: posting.id, matched: !!posting.contract_id, review_status: posting.review_status }, applicants: [] };
        if (apps && apps.length > 0) {
            const ids = apps.map(a => a.interpreter_id);
            const { data: profs } = await sb.from('40_통역사프로필')
                .select('user_id, display_name, languages, specialties, experience_years, base_rate, intro, profile_image_url, rating')
                .in('user_id', ids);
            const profMap = {}; (profs || []).forEach(p => { profMap[p.user_id] = p; });
            result.applicants = apps.map(a => {
                const p = profMap[a.interpreter_id] || {};
                return {
                    application_id: a.id,
                    interpreter_id: a.interpreter_id,
                    status: a.status,
                    applied_at: a.applied_at,
                    display_name: p.display_name || '통역사',
                    languages: p.languages || [],
                    specialties: p.specialties || [],
                    experience_years: p.experience_years || 0,
                    base_rate: p.base_rate || null,
                    intro: p.intro || '',
                    profile_image_url: p.profile_image_url || '',
                    rating: p.rating || null
                };
            });
        }
        res.setHeader('Cache-Control', 'no-store');
        return res.status(200).json(result);
    } catch (e) {
        console.error('My showcase applicants error:', e);
        return res.status(500).json({ error: '요청 처리 중 오류가 발생했습니다.' });
    }
}

// ────────────────────────── 디스패처 ──────────────────────────
// ────────────────────────── accept-assignment (통역사 배정 수락 + 고객·관리자 알림) ──────────────────────────
async function handleAcceptAssignment(req, res) {
    if (req.method !== 'POST') return res.status(405).json({ success: false, error: 'Method not allowed' });
    const auth = await authenticate(req);
    if (auth.error) return res.status(auth.status).json({ success: false, error: auth.error });

    const { data: profile } = await sb.from('01_회원').select('role, name').eq('id', auth.user.id).single();
    if (!profile || profile.role !== 'interpreter') return res.status(403).json({ success: false, error: '통역사만 수락할 수 있습니다.' });

    if (!await checkRateLimit(sb, 'accept-assign:' + auth.user.id, 20, 60)) {
        return res.status(429).json({ success: false, error: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.' });
    }

    const contractId = req.body && req.body.contractId;
    if (!contractId) return res.status(400).json({ success: false, error: '계약 ID가 필요합니다.' });

    try {
        const { data: c, error: cErr } = await sb.from('42_통역계약')
            .select('id, customer_id, interpreter_id, exhibition_name, client_company, contract_signed, interpreter_accepted, status')
            .eq('id', contractId).single();
        if (cErr || !c) return res.status(404).json({ success: false, error: '계약을 찾을 수 없습니다.' });
        if (c.interpreter_id !== auth.user.id) return res.status(403).json({ success: false, error: '본인에게 배정된 계약만 수락할 수 있습니다.' });
        if (c.status === 'cancelled') return res.status(400).json({ success: false, error: '취소된 계약입니다.' });

        // 수락 기록 (status는 'pending' 유지 — 결제 완료 시에만 deposit_paid). 멱등.
        if (c.interpreter_accepted !== true) {
            const { error: upErr } = await sb.from('42_통역계약')
                .update({ interpreter_accepted: true, accepted_at: new Date().toISOString() })
                .eq('id', contractId);
            if (upErr) { console.error('accept-assignment update 실패:', upErr); return res.status(500).json({ success: false, error: '수락 처리 실패' }); }
        }

        const interpName = profile.name || '통역사';
        const expoLabel = c.exhibition_name || '계약';

        // 고객사 알림
        if (c.customer_id) {
            try {
                await sb.from('24_알림').insert({
                    user_id: c.customer_id,
                    notification_type: 'service',
                    title: '🤝 통역사 수락 완료',
                    message: '담당 통역사(' + interpName + ')가 "' + expoLabel + '" 계약을 수락했습니다. ' + (c.contract_signed ? '선결제를 진행해주세요.' : '계약서를 확인하고 동의해주세요.'),
                    is_read: false
                });
            } catch (e) { console.error('고객 알림 실패(무시):', e && e.message); }
        }
        // 관리자 전원 알림
        try {
            const { data: admins } = await sb.from('01_회원').select('id').eq('role', 'admin');
            if (admins && admins.length) {
                await sb.from('24_알림').insert(admins.map(function (a) {
                    return { user_id: a.id, notification_type: 'service', title: '🤝 통역사 배정 수락', message: interpName + '님이 "' + expoLabel + '" (' + (c.client_company || '고객사') + ') 계약을 수락했습니다.', is_read: false };
                }));
            }
        } catch (e) { console.error('관리자 알림 실패(무시):', e && e.message); }

        return res.status(200).json({ success: true });
    } catch (e) {
        console.error('accept-assignment 예외:', e);
        return res.status(500).json({ success: false, error: '요청 처리 중 오류가 발생했습니다.' });
    }
}

// ────────────────────────── decline-assignment (통역사 배정 거절 + 관리자 알림) ──────────────────────────
// accept-assignment와 대칭: 클라이언트 직접 UPDATE 대신 서버에서 소유권 검증 후 처리.
async function handleDeclineAssignment(req, res) {
    if (req.method !== 'POST') return res.status(405).json({ success: false, error: 'Method not allowed' });
    const auth = await authenticate(req);
    if (auth.error) return res.status(auth.status).json({ success: false, error: auth.error });

    const { data: profile } = await sb.from('01_회원').select('role, name').eq('id', auth.user.id).single();
    if (!profile || profile.role !== 'interpreter') return res.status(403).json({ success: false, error: '통역사만 거절할 수 있습니다.' });

    if (!await checkRateLimit(sb, 'decline-assign:' + auth.user.id, 20, 60)) {
        return res.status(429).json({ success: false, error: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.' });
    }

    const contractId = req.body && req.body.contractId;
    const reason = (req.body && req.body.reason) || '';
    if (!contractId) return res.status(400).json({ success: false, error: '계약 ID가 필요합니다.' });

    try {
        const { data: c, error: cErr } = await sb.from('42_통역계약')
            .select('id, order_id, customer_id, interpreter_id, exhibition_name, client_company, status')
            .eq('id', contractId).single();
        if (cErr || !c) return res.status(404).json({ success: false, error: '계약을 찾을 수 없습니다.' });
        if (c.interpreter_id !== auth.user.id) return res.status(403).json({ success: false, error: '본인에게 배정된 계약만 거절할 수 있습니다.' });
        if (c.status === 'cancelled') return res.status(200).json({ success: true, alreadyCancelled: true });

        // 거절: 계약을 취소(cancelled)로 죽이지 않고 '재배정 대기'로 리셋한다.
        //  - 통역사 비움(interpreter_id=null) + 수락상태 초기화(interpreter_accepted=null) + status='pending'
        //  - 재배정은 기존 /api/assign(assign_inquiry_atomic)가 order_id로 같은 계약을 UPDATE하므로 중복 생성 없음.
        //    (RPC는 status를 건드리지 않아 pending 유지 → 새 통역사가 정상 수락 가능)
        const { error: upErr } = await sb.from('42_통역계약')
            .update({
                interpreter_id: null,
                interpreter_accepted: null,
                rejected_at: new Date().toISOString(),
                reject_reason: reason,
                status: 'pending'
            })
            .eq('id', contractId);
        if (upErr) { console.error('decline-assignment update 실패:', upErr); return res.status(500).json({ success: false, error: '거절 처리 실패' }); }

        // 연결된 견적문의를 다시 배정 가능 상태('검토중')로 복귀 → admin 배정 큐에 재노출
        if (c.order_id) {
            try { await sb.from('46_ITQ견적문의').update({ status: '검토중' }).eq('id', c.order_id); }
            catch (e) { console.error('의뢰 재배정 상태 복귀 실패(무시):', e && e.message); }
        }

        const interpName = profile.name || '통역사';
        const expoLabel = c.exhibition_name || '계약';

        // 관리자 전원 알림 (재배정 필요)
        try {
            const { data: admins } = await sb.from('01_회원').select('id').eq('role', 'admin');
            if (admins && admins.length) {
                await sb.from('24_알림').insert(admins.map(function (a) {
                    return { user_id: a.id, notification_type: 'service', title: '❌ 통역사 배정 거절', message: interpName + '님이 "' + expoLabel + '" (' + (c.client_company || '고객사') + ') 배정을 거절했습니다. 재배정이 필요합니다.' + (reason ? ' 사유: ' + reason : ''), is_read: false };
                }));
            }
        } catch (e) { console.error('관리자 알림 실패(무시):', e && e.message); }

        return res.status(200).json({ success: true });
    } catch (e) {
        console.error('decline-assignment 예외:', e);
        return res.status(500).json({ success: false, error: '요청 처리 중 오류가 발생했습니다.' });
    }
}

// ────────────────────────── accept-quote ──────────────────────────
// 고객이 견적을 수락하면 서버가 admin_note(관리자 작성)에서 권위 금액을 읽어
// 42_통역계약을 생성한다. 클라이언트가 보낸 금액을 신뢰하지 않음 → 가격 변조 차단.
async function handleAcceptQuote(req, res) {
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
    const auth = await authenticate(req);
    if (auth.error) return res.status(auth.status).json({ error: auth.error });

    if (!await checkRateLimit(sb, 'accept-quote:' + auth.user.id, 10, 60)) {
        return res.status(429).json({ error: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.' });
    }

    const inquiryId = req.body && req.body.inquiryId;
    if (!inquiryId) return res.status(400).json({ error: '문의 ID가 필요합니다.' });

    try {
        // 1. 권위 견적 조회 (service role)
        const { data: inq, error: inqErr } = await sb.from('46_ITQ견적문의')
            .select('id, user_id, exhibition_name, company, location, language_pair, service_type, start_date, end_date, status, quoted_amount, admin_note')
            .eq('id', inquiryId).single();
        if (inqErr || !inq) return res.status(404).json({ error: '문의를 찾을 수 없습니다.' });

        // 2. 소유권 확인 (본인 문의만)
        if (inq.user_id !== auth.user.id) return res.status(403).json({ error: '본인의 문의만 수락할 수 있습니다.' });

        // 3. admin_note 파싱 (관리자가 작성한 권위 데이터)
        let note = {};
        try { note = typeof inq.admin_note === 'string' ? JSON.parse(inq.admin_note) : (inq.admin_note || {}); } catch (e) { note = {}; }

        // 4. 서버측 금액 산정 (admin_note 우선, 누락 시 일당×일수 재계산) — VAT 10%
        const dailyRate = Number(note.dailyRate) || 0;
        const days = Number(note.days) || 1;
        const subtotal = Number(note.subtotal) || (dailyRate * days);             // 공급가(net)
        const tax = Number(note.platformFee) || Math.round(subtotal * 0.1);       // 부가세
        const total = Number(note.total) || (subtotal + tax);                     // 총액
        const deposit = Number(note.deposit) || total;                            // A안 100% 선결제
        const balance = Number(note.balance) || 0;
        if (subtotal <= 0 || total <= 0) return res.status(400).json({ error: '견적 금액이 유효하지 않습니다.' });

        // 5. 중복 계약 방지 (같은 고객+전시회+기간) — 멱등 처리
        //    전시회명만으로는 동명 다른 의뢰가 충돌하므로 기간(시작·종료일)까지 키에 포함
        const { data: existing } = await sb.from('42_통역계약')
            .select('id')
            .eq('customer_id', auth.user.id)
            .eq('exhibition_name', inq.exhibition_name)
            .eq('start_date', inq.start_date)
            .eq('end_date', inq.end_date)
            .limit(1);
        if (existing && existing.length > 0) {
            return res.status(200).json({ contractId: existing[0].id, duplicate: true,
                amounts: { subtotal, tax, total, deposit, balance, dailyRate, days } });
        }

        // 6. 상태 확인 (견적발송 상태만 신규 수락 가능)
        if (inq.status !== '견적발송') {
            return res.status(409).json({ error: '수락 가능한 견적이 아닙니다. (상태: ' + inq.status + ')' });
        }

        // 7. 계약 생성
        const { data: ins, error: insErr } = await sb.from('42_통역계약').insert({
            customer_id: auth.user.id,
            interpreter_id: note.interpreterId || null,
            exhibition_name: inq.exhibition_name,
            client_company: inq.company || '',
            venue: note.country || note.location || inq.location || '',
            start_date: inq.start_date,
            end_date: inq.end_date,
            working_days: days,
            language_pair: inq.language_pair || '',
            service_type: inq.service_type || '',
            daily_rate: dailyRate,
            total_amount: total,
            tax_amount: tax,
            net_amount: subtotal,
            deposit_amount: deposit,
            balance_amount: balance,
            balance_status: (balance > 0) ? 'pending' : 'paid',
            status: 'pending',
            interpreter_accepted: null,
            contract_signed: false
        }).select('id').single();
        if (insErr || !ins) { console.error('accept-quote insert 실패:', insErr); return res.status(500).json({ error: '계약 생성에 실패했습니다.' }); }

        // 8. 문의 상태 → 계약진행
        try { await sb.from('46_ITQ견적문의').update({ status: '계약진행' }).eq('id', inquiryId); }
        catch (e) { console.error('문의 상태 업데이트 실패(무시):', e && e.message); }

        return res.status(200).json({ contractId: ins.id,
            amounts: { subtotal, tax, total, deposit, balance, dailyRate, days } });
    } catch (e) {
        console.error('accept-quote 예외:', e);
        return res.status(500).json({ error: '요청 처리 중 오류가 발생했습니다.' });
    }
}

// ────────────────────────── scan-card (명함 OCR — Claude Vision) ──────────────────────────
// 로그인 사용자가 명함 이미지를 올리면 Claude Haiku 4.5로 구조화 필드 추출.
// 키(ANTHROPIC_API_KEY) 미설정 시 503으로 그레이스풀 처리. 과금 보호 위해 레이트리밋.
async function handleScanCard(req, res) {
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
    const auth = await authenticate(req);
    if (auth.error) return res.status(auth.status).json({ error: auth.error });

    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) return res.status(503).json({ error: '명함 인식 기능이 아직 활성화되지 않았습니다. (관리자: ANTHROPIC_API_KEY 등록 필요)' });

    if (!await checkRateLimit(sb, 'scan-card:' + auth.user.id, 20, 60)) {
        return res.status(429).json({ error: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.' });
    }

    const image = req.body && req.body.image;
    if (!image || typeof image !== 'string') return res.status(400).json({ error: '이미지가 필요합니다.' });

    const m = image.match(/^data:(image\/(?:png|jpe?g|webp|gif));base64,(.+)$/i);
    if (!m) return res.status(400).json({ error: '지원하지 않는 이미지 형식입니다.' });
    const mediaType = m[1].toLowerCase().replace('image/jpg', 'image/jpeg');
    const b64 = m[2];
    if (b64.length > 8 * 1024 * 1024) return res.status(413).json({ error: '이미지가 너무 큽니다. 다시 촬영해주세요.' });

    const prompt = '이 명함 이미지에서 정보를 추출해 JSON 객체로만 응답하세요. ' +
        '설명·코드펜스 없이 순수 JSON만 출력합니다. 키: ' +
        'company(회사명), contact_name(담당자 이름), title(직책), department(부서), ' +
        'email, phone(유선/대표번호), mobile(휴대폰), fax, website, address(주소), country(국가). ' +
        '값이 없으면 null. country는 주소·전화 국가번호·언어로 추론하세요. ' +
        '같은 종류가 여러 개면 가장 대표적인 것 하나만. 이름·회사명은 명함에 적힌 언어 그대로 표기하세요.';

    try {
        const aResp = await fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: { 'x-api-key': apiKey, 'anthropic-version': '2023-06-01', 'content-type': 'application/json' },
            body: JSON.stringify({
                model: 'claude-haiku-4-5',
                max_tokens: 1024,
                messages: [{
                    role: 'user',
                    content: [
                        { type: 'image', source: { type: 'base64', media_type: mediaType, data: b64 } },
                        { type: 'text', text: prompt }
                    ]
                }]
            })
        });
        if (!aResp.ok) {
            const errTxt = await aResp.text();
            console.error('Anthropic OCR 실패:', aResp.status, String(errTxt).slice(0, 300));
            return res.status(502).json({ error: '명함 인식 서비스 오류. 잠시 후 다시 시도해주세요.' });
        }
        const aData = await aResp.json();
        let text = '';
        if (aData && Array.isArray(aData.content)) {
            aData.content.forEach(function (b) { if (b && b.type === 'text') text += b.text; });
        }
        let jsonStr = String(text).trim().replace(/^```(?:json)?/i, '').replace(/```$/, '').trim();
        let fields = {};
        try { fields = JSON.parse(jsonStr); } catch (e) {
            const mm = jsonStr.match(/\{[\s\S]*\}/);
            if (mm) { try { fields = JSON.parse(mm[0]); } catch (e2) { fields = {}; } }
        }
        const keys = ['company', 'contact_name', 'title', 'department', 'email', 'phone', 'mobile', 'fax', 'website', 'address', 'country'];
        const out = {};
        keys.forEach(function (k) {
            const v = fields[k];
            out[k] = (v == null || v === '') ? null : String(v).slice(0, 300);
        });
        return res.status(200).json({ ok: true, fields: out });
    } catch (e) {
        console.error('scan-card 예외:', e);
        return res.status(500).json({ error: '명함 인식 중 오류가 발생했습니다.' });
    }
}

module.exports = async function handler(req, res) {
    if (!SERVICE_KEY) return res.status(500).json({ error: '서버 설정 오류' });

    const route = req.query._route || '';
    switch (route) {
        case 'my-inquiries': return handleMyInquiries(req, res);
        case 'my-contracts': return handleMyContracts(req, res);
        case 'my-showcase-postings': return handleMyShowcasePostings(req, res);
        case 'my-showcase-applications': return handleMyShowcaseApplications(req, res);
        case 'my-showcase-applicants': return handleMyShowcaseApplicants(req, res);
        case 'accept-assignment': return handleAcceptAssignment(req, res);
        case 'decline-assignment': return handleDeclineAssignment(req, res);
        case 'accept-quote': return handleAcceptQuote(req, res);
        case 'scan-card': return handleScanCard(req, res);
        default: return res.status(404).json({ error: 'Unknown route: ' + route });
    }
};
