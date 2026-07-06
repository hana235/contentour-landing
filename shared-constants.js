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

// ── 개최지 한→영 변환 (계약서 표기용) ──
// 계약서의 '개최 장소·주소'는 영문 표기 원칙. DB에는 견적 문의의 한글 개최지("일본 / 도쿄")가
// 저장될 수 있어 렌더 시점에 변환한다. 이미 영문이면 그대로 통과 (멱등).
CT.KO_EN_COUNTRIES = {
    '미국': 'USA', '일본': 'Japan', '중국': 'China', '독일': 'Germany', '프랑스': 'France',
    '영국': 'UK', '이탈리아': 'Italy', '스페인': 'Spain', '네덜란드': 'Netherlands', '벨기에': 'Belgium',
    '폴란드': 'Poland', '체코': 'Czech Republic', '헝가리': 'Hungary', '핀란드': 'Finland', '러시아': 'Russia',
    '터키': 'Turkey', '튀르키예': 'Turkey', '그리스': 'Greece', '포르투갈': 'Portugal', '스위스': 'Switzerland',
    '오스트리아': 'Austria', '스웨덴': 'Sweden', '노르웨이': 'Norway', '덴마크': 'Denmark', '아일랜드': 'Ireland',
    '대만': 'Taiwan', '베트남': 'Vietnam', '태국': 'Thailand', '말레이시아': 'Malaysia', '인도네시아': 'Indonesia',
    '필리핀': 'Philippines', '인도': 'India', '방글라데시': 'Bangladesh', '우즈베키스탄': 'Uzbekistan',
    '카자흐스탄': 'Kazakhstan', '몽골': 'Mongolia', 'UAE': 'UAE', '아랍에미리트': 'UAE',
    '사우디아라비아': 'Saudi Arabia', '사우디': 'Saudi Arabia', '카타르': 'Qatar', '쿠웨이트': 'Kuwait',
    '이스라엘': 'Israel', '이집트': 'Egypt', '모로코': 'Morocco', '남아공': 'South Africa',
    '남아프리카공화국': 'South Africa', '캐나다': 'Canada', '멕시코': 'Mexico', '브라질': 'Brazil',
    '아르헨티나': 'Argentina', '콜롬비아': 'Colombia', '칠레': 'Chile', '페루': 'Peru',
    '호주': 'Australia', '뉴질랜드': 'New Zealand', '한국': 'Korea', '대한민국': 'Korea', '유럽': 'Europe'
};
CT.KO_EN_CITIES = {
    // 아시아
    '도쿄': 'Tokyo', '오사카': 'Osaka', '나고야': 'Nagoya', '요코하마': 'Yokohama', '후쿠오카': 'Fukuoka',
    '베이징': 'Beijing', '상하이': 'Shanghai', '광저우': 'Guangzhou', '선전': 'Shenzhen', '심천': 'Shenzhen',
    '홍콩': 'Hong Kong', '타이페이': 'Taipei', '타이베이': 'Taipei', '싱가포르': 'Singapore',
    '방콕': 'Bangkok', '하노이': 'Hanoi', '호치민': 'Ho Chi Minh City', '자카르타': 'Jakarta',
    '쿠알라룸푸르': 'Kuala Lumpur', '마닐라': 'Manila', '파사이': 'Pasay', '다카': 'Dhaka',
    '뉴델리': 'New Delhi', '뭄바이': 'Mumbai', '벵갈루루': 'Bengaluru', '아흐메다바드': 'Ahmedabad',
    '타슈켄트': 'Tashkent', '알마티': 'Almaty', '울란바토르': 'Ulaanbaatar',
    // 중동·아프리카
    '두바이': 'Dubai', '아부다비': 'Abu Dhabi', '리야드': 'Riyadh', '제다': 'Jeddah', '도하': 'Doha',
    '이스탄불': 'Istanbul', '텔아비브': 'Tel Aviv', '카이로': 'Cairo', '카사블랑카': 'Casablanca',
    '요하네스버그': 'Johannesburg', '케이프타운': 'Cape Town',
    // 유럽
    '런던': 'London', '버밍엄': 'Birmingham', '파리': 'Paris', '리옹': 'Lyon', '칸': 'Cannes',
    '베를린': 'Berlin', '뮌헨': 'Munich', '프랑크푸르트': 'Frankfurt', '함부르크': 'Hamburg',
    '뒤셀도르프': 'Dusseldorf', '쾰른': 'Cologne', '뉘른베르크': 'Nuremberg', '슈투트가르트': 'Stuttgart',
    '에센': 'Essen', '하노버': 'Hannover', '프리드리히스하펜': 'Friedrichshafen', '라이프치히': 'Leipzig',
    '밀라노': 'Milan', '볼로냐': 'Bologna', '베로나': 'Verona', '리미니': 'Rimini', '파르마': 'Parma',
    '로마': 'Rome', '마드리드': 'Madrid', '바르셀로나': 'Barcelona', '리스본': 'Lisbon',
    '암스테르담': 'Amsterdam', '마스트리히트': 'Maastricht', '브뤼셀': 'Brussels', '빈': 'Vienna',
    '취리히': 'Zurich', '제네바': 'Geneva', '바르샤바': 'Warsaw', '포즈난': 'Poznan', '키엘체': 'Kielce',
    '프라하': 'Prague', '브르노': 'Brno', '부다페스트': 'Budapest', '헬싱키': 'Helsinki',
    '스톡홀름': 'Stockholm', '코펜하겐': 'Copenhagen', '오슬로': 'Oslo', '더블린': 'Dublin',
    '모스크바': 'Moscow', '예카테린부르크': 'Yekaterinburg',
    // 미주
    '뉴욕': 'New York', '라스베이거스': 'Las Vegas', '라스베가스': 'Las Vegas', 'LA': 'Los Angeles',
    '로스앤젤레스': 'Los Angeles', '시카고': 'Chicago', '보스턴': 'Boston', '마이애미': 'Miami',
    '올랜도': 'Orlando', '애틀랜타': 'Atlanta', '달라스': 'Dallas', '댈러스': 'Dallas',
    '휴스턴': 'Houston', '디트로이트': 'Detroit', '샌디에이고': 'San Diego', '샌프란시스코': 'San Francisco',
    '토론토': 'Toronto', '몬트리올': 'Montreal', '캘거리': 'Calgary', '멕시코시티': 'Mexico City',
    '과달라하라': 'Guadalajara', '몬테레이': 'Monterrey', '상파울루': 'Sao Paulo',
    '부에노스아이레스': 'Buenos Aires', '보고타': 'Bogota', '메데인': 'Medellin',
    // 오세아니아
    '시드니': 'Sydney', '멜버른': 'Melbourne', '브리즈번': 'Brisbane', '오클랜드': 'Auckland',
    // 국내 (도시·전시장)
    '서울': 'Seoul', '부산': 'Busan', '인천': 'Incheon', '대구': 'Daegu', '광주': 'Gwangju',
    '대전': 'Daejeon', '고양': 'Goyang', '수원': 'Suwon', '창원': 'Changwon', '제주': 'Jeju'
};
CT.KO_EN_VENUES = {
    '코엑스': 'COEX', '킨텍스': 'KINTEX', '벡스코': 'BEXCO', '엑스코': 'EXCO', '세텍': 'SETEC',
    '송도컨벤시아': 'Songdo Convensia', '빅사이트': 'Big Sight', '마쿠하리멧세': 'Makuhari Messe'
};
CT.locationToEn = function(str) {
    if (!str) return '';
    var s = String(str).trim();
    if (!/[가-힣]/.test(s)) return s; // 이미 영문
    var tokens = s.split(/[\s\/,·]+/).filter(Boolean);
    var city = null, country = null, extras = [];
    tokens.forEach(function(t) {
        if (CT.KO_EN_VENUES[t]) { extras.push(CT.KO_EN_VENUES[t]); return; }
        var ci = CT.KO_EN_CITIES[t];
        if (ci) { if (!city) city = ci; else extras.push(ci); return; }
        var co = CT.KO_EN_COUNTRIES[t];
        if (co) { if (!country) country = co; else extras.push(co); return; }
        extras.push(t);
    });
    if (city || country) {
        // 영문 관례: "City, Country" 순서. 사전에 없는 토큰(전시장명 등)은 앞에 유지
        var parts = [];
        if (extras.length) parts.push(extras.join(' '));
        if (city) parts.push(city);
        if (country) parts.push(country);
        return parts.join(', ');
    }
    // 토큰 단위 매칭 실패 시(붙여쓰기 등) 부분 문자열 치환 fallback
    var out = s;
    Object.keys(CT.KO_EN_VENUES).forEach(function(k) { if (out.indexOf(k) >= 0) out = out.split(k).join(CT.KO_EN_VENUES[k]); });
    Object.keys(CT.KO_EN_CITIES).forEach(function(k) { if (out.indexOf(k) >= 0) out = out.split(k).join(CT.KO_EN_CITIES[k]); });
    Object.keys(CT.KO_EN_COUNTRIES).forEach(function(k) { if (out.indexOf(k) >= 0) out = out.split(k).join(CT.KO_EN_COUNTRIES[k]); });
    return out;
};

// ── 취소 확인서 (Cancellation Certificate) ──
// 분쟁 대비용 정식 문서. 51_취소내역 row를 받아 인쇄 가능한 새 창으로 렌더.
// row: 51_취소내역 row (snake_case). optional: row.contract(42_통역계약 join), row._applicantName, row._companyName
CT.CANCEL_STATUS_LABEL = { pending: '접수됨 (승인 대기)', approved: '승인됨', refunded: '환불 완료', rejected: '반려됨' };

CT._fmtDateTime = function(s) {
    if (!s) return '-';
    var d = new Date(s);
    if (isNaN(d.getTime())) return String(s);
    var p = function(n){ return String(n).padStart(2,'0'); };
    return d.getFullYear() + '.' + p(d.getMonth()+1) + '.' + p(d.getDate()) + ' ' + p(d.getHours()) + ':' + p(d.getMinutes());
};

// contract_id로 본인 취소내역 1건 조회 (RLS: 본인/관리자만) — 고객사/통역사 대시보드용
CT.fetchCancellationByContract = async function(contractId) {
    var sb = CT.getClient();
    if (!sb || !contractId) return null;
    try {
        var res = await sb.from('51_취소내역')
            .select('*, contract:42_통역계약(exhibition_name, contract_no, total_amount, deposit_amount)')
            .eq('contract_id', contractId)
            .order('created_at', { ascending: false })
            .limit(1);
        return (res.data && res.data[0]) || null;
    } catch (e) { console.warn('취소내역 조회 실패:', e); return null; }
};

CT.openCancellationCertificate = function(row) {
    if (!row) { alert('취소 정보를 찾을 수 없습니다.'); return; }
    var c = row.contract || {};
    var esc = CT.escHtml;
    var byLabel = (CT.USER_ROLES[row.cancelled_by] || row.cancelled_by || '-');
    var statusLabel = CT.CANCEL_STATUS_LABEL[row.status] || row.status || '-';
    var contractNo = c.contract_no || CT.contractNo({ id: row.contract_id, created_at: row.created_at }) || '-';
    var cancelDate = row.cancel_date || row.created_at;
    var certDigits = String(cancelDate || '').replace(/[^0-9]/g, '').slice(0, 8);
    var certSuffix = String(row.contract_id || row.id || '').replace(/[^a-zA-Z0-9]/g, '').slice(-4).toUpperCase();
    var certNo = 'CXL-' + (certDigits || '00000000') + '-' + (certSuffix || '0000');
    var amount = (row.amount_snapshot != null ? row.amount_snapshot : (c.total_amount || 0));
    var applicant = row._applicantName || '-';
    var company = row._companyName || '';
    var issuedAt = CT._fmtDateTime(new Date().toISOString());

    var rowHtml = function(label, val) {
        return '<tr><th>' + label + '</th><td>' + val + '</td></tr>';
    };

    var html =
      '<!DOCTYPE html><html lang="ko"><head><meta charset="UTF-8"><title>취소 확인서 ' + esc(certNo) + '</title>' +
      '<style>' +
      '*{box-sizing:border-box;} body{font-family:"Pretendard","Noto Sans KR",sans-serif;color:#1a2a4a;margin:0;padding:40px;background:#f4f6fa;}' +
      '.doc{max-width:780px;margin:0 auto;background:#fff;padding:48px 52px;box-shadow:0 4px 24px rgba(0,0,0,0.08);border-radius:8px;}' +
      '.head{text-align:center;border-bottom:3px double #b71c1c;padding-bottom:18px;margin-bottom:8px;}' +
      '.head h1{font-size:1.7rem;letter-spacing:6px;margin:0 0 4px;color:#b71c1c;}' +
      '.head .en{font-size:0.78rem;color:#c98a8a;letter-spacing:2px;}' +
      '.notice{background:#fdecea;border:1.5px solid #f5c6c0;border-radius:8px;padding:12px 16px;font-size:0.8rem;color:#8c3330;line-height:1.6;margin:16px 0 6px;}' +
      '.meta{display:flex;justify-content:space-between;font-size:0.8rem;color:#5b6577;margin:14px 0 26px;}' +
      '.sec-title{font-size:0.92rem;font-weight:800;color:#b71c1c;margin:22px 0 8px;padding-left:8px;border-left:3px solid #c62828;}' +
      'table{width:100%;border-collapse:collapse;font-size:0.86rem;}' +
      'th,td{border:1px solid #e0e5ec;padding:10px 12px;text-align:left;vertical-align:top;}' +
      'th{background:#f7f9fc;width:32%;font-weight:700;color:#3a4660;}' +
      '.badge{display:inline-block;padding:3px 12px;border-radius:6px;font-size:0.8rem;font-weight:700;background:#fdecea;color:#c62828;}' +
      '.reason{white-space:pre-wrap;}' +
      '.foot{margin-top:32px;padding-top:18px;border-top:1px solid #e0e5ec;font-size:0.74rem;color:#8a95a8;line-height:1.7;}' +
      '.foot b{color:#3a4660;}' +
      '.noprint{text-align:center;margin-top:26px;}' +
      '.noprint button{padding:11px 28px;background:#0a2a5e;color:#fff;border:none;border-radius:8px;font-size:0.9rem;font-weight:700;cursor:pointer;font-family:inherit;}' +
      '@media print{body{background:#fff;padding:0;} .doc{box-shadow:none;border-radius:0;} .noprint{display:none;}}' +
      '</style></head><body><div class="doc">' +
      '<div class="head"><h1>취 소 확 인 서</h1><div class="en">CANCELLATION CONFIRMATION</div></div>' +
      '<div class="notice">본 문서는 <b>계약 취소 처리에 대한 확인서</b>로, 계약서를 대체하지 않습니다. 취소 신청 내역과 취소 시점에 동결된 금액 기준의 위약금·환불 산정 내역을 증빙하기 위해 발급됩니다.</div>' +
      '<div class="meta"><span>확인서 번호: <b>' + esc(certNo) + '</b></span><span>발급일시: ' + issuedAt + '</span></div>' +

      '<div class="sec-title">1. 계약 정보</div><table>' +
      rowHtml('계약번호', esc(contractNo)) +
      rowHtml('전시회/행사', esc(c.exhibition_name || row._expoName || '-')) +
      rowHtml('전시 시작일', CT.formatDate(row.exhibition_start)) +
      rowHtml('취소 당시 계약 금액', '<b>' + CT.formatMoney(amount) + '</b> <span style="color:#8a95a8;font-size:0.78rem;">(취소 시점 동결)</span>') +
      '</table>' +

      '<div class="sec-title">2. 취소 신청 내역</div><table>' +
      rowHtml('신청 주체', '<span class="badge">' + esc(byLabel) + '</span>') +
      rowHtml('신청자', esc(applicant) + (company ? ' (' + esc(company) + ')' : '')) +
      rowHtml('신청 일시', CT._fmtDateTime(cancelDate)) +
      rowHtml('취소 사유', '<div class="reason">' + esc(row.cancel_reason || '-') + '</div>') +
      '</table>' +

      '<div class="sec-title">3. 위약금 및 환불</div><table>' +
      rowHtml('전시 시작까지 남은 일수', (row.days_remaining != null ? row.days_remaining + '일' : '-')) +
      rowHtml('위약금', CT.formatMoney(row.penalty_amount) + (row.penalty_rate != null ? ' (' + row.penalty_rate + '%)' : '')) +
      rowHtml('환불 예정액', '<b>' + CT.formatMoney(row.refund_amount) + '</b>') +
      '</table>' +

      '<div class="sec-title">4. 통지 및 처리</div><table>' +
      rowHtml('상대방 통지 시각', CT._fmtDateTime(row.notified_at)) +
      rowHtml('처리 상태', '<span class="badge">' + esc(statusLabel) + '</span>') +
      (row.admin_note ? rowHtml('관리자 처리 메모', '<div class="reason">' + esc(row.admin_note) + '</div>') : '') +
      rowHtml('담당 관리자', '관리자') +
      '</table>' +

      '<div class="foot">' +
      '<b>주식회사 콘텐츄어</b> | 대표이사 이수경<br>' +
      '서울시 구로구 디지털로26길 43, 대륭포스트타워 8차 L동 2층 204호<br>' +
      '사업자등록번호 119-86-68157 | 통신판매업신고 제2017-서울구로-0321호<br>' +
      'info@contentour.co.kr | 02-868-1522<br><br>' +
      '본 확인서는 콘텐츄어 통역 운영 시스템에서 자동 생성되었으며, 취소 시점의 계약 조건을 그대로 보존합니다.' +
      '</div>' +
      '<div class="noprint"><button onclick="window.print()">🖨 인쇄 / PDF 저장</button></div>' +
      '</div></body></html>';

    // Blob URL 방식 (document.write 팝업은 일부 환경에서 빈 about:blank 창이 됨)
    var blobUrl = URL.createObjectURL(new Blob([html], { type: 'text/html;charset=utf-8' }));
    var w = window.open(blobUrl, '_blank');
    if (!w) { alert('팝업이 차단되었습니다. 팝업 허용 후 다시 시도해주세요.'); }
    setTimeout(function () { URL.revokeObjectURL(blobUrl); }, 60000);
};

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
