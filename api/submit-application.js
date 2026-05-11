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

function arr(v, maxItems, maxItemLen) {
    if (!Array.isArray(v)) return [];
    return v.slice(0, maxItems).map(function (it) {
        if (typeof it === 'string') return it.slice(0, maxItemLen);
        if (it && typeof it === 'object') {
            var out = {};
            Object.keys(it).slice(0, 20).forEach(function (k) {
                var val = it[k];
                if (val == null) { out[k] = null; return; }
                if (typeof val === 'string') out[k] = val.slice(0, maxItemLen);
                else if (typeof val === 'number' || typeof val === 'boolean') out[k] = val;
                else out[k] = String(val).slice(0, maxItemLen);
            });
            return out;
        }
        return null;
    }).filter(function (x) { return x != null; });
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

    var name_ko = s(b.name_ko, 100);
    var name_en = s(b.name_en, 100);
    var email = s(b.email, 200);
    var phone = s(b.phone, 50);

    if (!name_ko || !email || !phone) {
        return res.status(400).json({ error: '필수 항목이 누락되었습니다.' });
    }
    if (!isEmail(email)) {
        return res.status(400).json({ error: '이메일 형식이 올바르지 않습니다.' });
    }
    if (b.privacy_consent !== true) {
        return res.status(400).json({ error: '개인정보 수집·이용 동의가 필요합니다.' });
    }

    var payload = {
        name_ko: name_ko,
        name_en: name_en,
        email: email,
        phone: phone,
        nationality: s(b.nationality, 100),
        birth_date: s(b.birth_date, 20),
        gender: s(b.gender, 20),
        city: s(b.city, 100),
        intro: s(b.intro, 5000),
        language_pairs: arr(b.language_pairs, 20, 200),
        specialties: arr(b.specialties, 30, 100),
        interpretation_types: arr(b.interpretation_types, 20, 100),
        preferred_regions: arr(b.preferred_regions, 30, 100),
        careers: arr(b.careers, 50, 500),
        total_experience: s(b.total_experience, 100),
        certifications: arr(b.certifications, 30, 500),
        school: s(b.school, 200),
        major: s(b.major, 200),
        resume_file_url: s(b.resume_file_url, 500),
        resume_file_name: s(b.resume_file_name, 300),
        portfolio_url: s(b.portfolio_url, 500),
        motivation: s(b.motivation, 5000),
        privacy_consent: true,
        privacy_consent_at: new Date().toISOString()
    };

    try {
        var { data, error } = await sb
            .from('48_통역사지원서')
            .insert(payload)
            .select('id')
            .single();

        if (error) {
            console.error('지원서 저장 실패:', error);
            return res.status(500).json({ error: '저장 실패. 잠시 후 다시 시도해주세요.' });
        }

        return res.status(200).json({ ok: true, applicationId: data.id });
    } catch (e) {
        console.error('Submit application error:', e);
        return res.status(500).json({ error: '서버 오류가 발생했습니다.' });
    }
};
