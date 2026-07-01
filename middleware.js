// Vercel Edge Middleware — 출시 전 서버단 비밀번호 게이트
// ---------------------------------------------------------------------------
// 인증(ct_gate 쿠키 == GATE_TOKEN) 전에는 실제 페이지 HTML 대신 게이트만 반환한다.
// → curl/소스보기로도 본문·대시보드 구조가 노출되지 않음 (QA #1·#2 대응).
//
// ★ fail-safe: 환경변수 GATE_TOKEN 이 설정돼 있어야만 활성화된다.
//   미설정이면 아무 페이지도 막지 않고 그대로 통과(return) → 잘못 배포해도 잠금 위험 없음.
//   문제 발생 시 Vercel에서 GATE_TOKEN 만 지우면 즉시 비활성.
//
// 정적 자산(js/css/이미지/폰트)·/api·robots·sitemap 은 matcher에서 제외 → 게이트 페이지 동작·인증 API 호출 가능.

export const config = {
  matcher: '/((?!api/|assets/|_next/|.*\\.(?:js|css|png|jpg|jpeg|gif|svg|ico|webp|avif|woff|woff2|ttf|otf|map|txt|xml|json|pdf)).*)'
};

const GATE_HTML = `<!DOCTYPE html><html lang="ko"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>CONTENTOUR</title><style>
*{box-sizing:border-box}body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;font-family:'Pretendard','Apple SD Gothic Neo',-apple-system,sans-serif;background:#0a2a5e}
.box{background:#fff;color:#1a1a2e;padding:40px 32px;border-radius:16px;width:min(90vw,340px);box-shadow:0 20px 60px rgba(0,0,0,.3);text-align:center}
h1{font-size:1.15rem;letter-spacing:.02em;margin:0 0 6px}p{font-size:.82rem;color:#888;margin:0 0 20px}
input{width:100%;padding:12px 14px;border:1.5px solid #e0e5ec;border-radius:10px;font-size:.9rem;margin-bottom:12px;outline:none}
input:focus{border-color:#0a2a5e}
button{width:100%;padding:12px;border:0;border-radius:10px;background:#0a2a5e;color:#fff;font-size:.9rem;font-weight:700;cursor:pointer}
button:disabled{opacity:.6}.err{color:#c62828;font-size:.78rem;min-height:16px;margin-top:8px}
</style></head><body><div class="box">
<h1>CONTENTOUR</h1><p>출시 준비 중입니다. 비밀번호를 입력해주세요.</p>
<input id="pw" type="password" placeholder="비밀번호" autofocus autocomplete="current-password">
<button id="go">확인</button><div class="err" id="err"></div>
</div><script>
var pw=document.getElementById('pw'),err=document.getElementById('err'),go=document.getElementById('go');
async function submit(){var v=pw.value;if(!v)return;go.disabled=true;go.textContent='확인 중...';
try{var r=await fetch('/api/verify-pw',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({password:v})});var d=await r.json();
if(d&&d.ok){try{sessionStorage.setItem('_ct_auth','1')}catch(e){}location.reload();}
else{err.textContent='비밀번호가 올바르지 않습니다.';go.disabled=false;go.textContent='확인';pw.value='';pw.focus();}}
catch(e){err.textContent='오류가 발생했습니다. 잠시 후 다시 시도하세요.';go.disabled=false;go.textContent='확인';}}
go.onclick=submit;pw.addEventListener('keydown',function(e){if(e.key==='Enter')submit();});
</script></body></html>`;

export default function middleware(request) {
  const token = process.env.GATE_TOKEN;
  if (!token) return;                                   // 미설정 → 게이트 비활성 (통과)
  const cookie = request.headers.get('cookie') || '';
  const authed = cookie.split(';').some(function (c) { return c.trim() === 'ct_gate=' + token; });
  if (authed) return;                                   // 인증됨 → 통과
  return new Response(GATE_HTML, {
    status: 200,
    headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store' }
  });
}
