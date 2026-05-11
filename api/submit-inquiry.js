const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://jgeqbdrfpekzuumaklvx.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const sb = createClient(SUPABASE_URL, SERVICE_KEY);

function s(v, max) {
    if (v == null) return null;
    var str = String(v).trim();
    if (!str) return null;
    return str.length > max ? str.slice(0, max) : str;
}

function isEmail(v) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(v || '').trim());
}

module.exports = async function handler(req, res) {
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    if (!SERVICE_KEY) {
        return res.status(500).json({ error: '서버 설정 오류(SERVICE_KEY 누락).' });
    }

    var b = req.body || {};

    var company = s(b.company, 200);
    var contact_name = s(b.contact_name, 100);
    var email = s(b.email, 200);
    var phone = s(b.phone, 50);
    var exhibition_name = s(b.exhibition_name, 300);
    var location = s(b.location, 200);
    var venue = s(b.venue, 200);
    var start_date = s(b.start_date, 20);
    var end_date = s(b.end_date, 20);
    var language_pair = s(b.language_pair, 200);
    var service_type = s(b.service_type, 100);
    var working_hours = s(b.working_hours, 100);
    var keywords = s(b.keywords, 500);
    var message = s(b.message, 5000);
    var headcount = parseInt(b.headcount);
    if (!Number.isFinite(headcount) || headcount < 1) headcount = 1;
    if (headcount > 999) headcount = 999;
    var consent = b.consent === true;

    if (!company || !contact_name || !email || !phone || !exhibition_name) {
        return res.status(400).json({ error: '필수 항목이 누락되었습니다.' });
    }
    if (!isEmail(email)) {
        return res.status(400).json({ error: '이메일 형식이 올바르지 않습니다.' });
    }
    if (!consent) {
        return res.status(400).json({ error: '개인정보 수집·이용 동의가 필요합니다.' });
    }
    if (start_date && end_date && start_date > end_date) {
        return res.status(400).json({ error: '종료일은 시작일 이후로 입력해주세요.' });
    }

    try {
        var { data, error } = await sb
            .from('46_ITQ견적문의')
            .insert({
                company: company,
                contact_name: contact_name,
                email: email,
                phone: phone,
                exhibition_name: exhibition_name,
                location: location,
                venue: venue,
                start_date: start_date,
                end_date: end_date,
                language_pair: language_pair,
                service_type: service_type,
                headcount: headcount,
                working_hours: working_hours,
                keywords: keywords,
                message: message,
                consent: consent,
                status: '접수'
            })
            .select('id')
            .single();

        if (error) {
            console.error('견적문의 저장 실패:', error);
            return res.status(500).json({ error: '저장 실패. 잠시 후 다시 시도해주세요.' });
        }

        return res.status(200).json({ ok: true, inquiryId: data.id });
    } catch (e) {
        console.error('Submit inquiry error:', e);
        return res.status(500).json({ error: '서버 오류가 발생했습니다.' });
    }
};
