const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://jgeqbdrfpekzuumaklvx.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const sb = createClient(SUPABASE_URL, SERVICE_KEY);

const ALLOWED_TYPES = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp'
];

const ALLOWED_EXTS = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif', 'webp'];

module.exports = async function handler(req, res) {
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }
    if (!SERVICE_KEY) {
        return res.status(500).json({ error: '서버 설정 오류' });
    }

    const b = req.body || {};
    const filename = String(b.filename || '').trim();
    const contentType = String(b.contentType || '').trim().toLowerCase();
    const kind = String(b.kind || 'resume').trim();

    if (!filename) {
        return res.status(400).json({ error: 'filename이 필요합니다.' });
    }

    const ext = filename.includes('.')
        ? filename.split('.').pop().toLowerCase().slice(0, 8).replace(/[^a-z0-9]/g, '')
        : '';
    if (!ext || !ALLOWED_EXTS.includes(ext)) {
        return res.status(400).json({ error: '허용되지 않는 파일 형식입니다.' });
    }
    if (contentType && !ALLOWED_TYPES.includes(contentType)) {
        return res.status(400).json({ error: '허용되지 않는 MIME 형식입니다.' });
    }

    const prefix = kind === 'certification' ? 'certifications' : 'applications';
    const rand = Math.random().toString(36).slice(2);
    const path = `${prefix}/${Date.now()}_${rand}.${ext}`;

    try {
        const { data, error } = await sb.storage
            .from('interpreter-docs')
            .createSignedUploadUrl(path);
        if (error) throw error;
        return res.status(200).json({
            ok: true,
            signedUrl: data.signedUrl,
            token: data.token,
            path: path
        });
    } catch (e) {
        console.error('signed upload url 생성 실패:', e);
        return res.status(500).json({ error: '업로드 URL 생성 실패' });
    }
};
