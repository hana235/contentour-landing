# 🚀 ctconfex.com 출시 체크리스트

> 이 문서는 배포되지 않습니다 (`.vercelignore` 의 `*.md`). 내부 전용.

## 📌 현재 상태 (2026-07-15 확인)

**사이트는 2026-07-14 출시되어 공개 운영 중입니다.** PW 게이트는 해제됐습니다(`GATE_TOKEN` 삭제).
아래 문서는 원래 "출시일 순서대로 진행" 용도였으나, 지금은 **일부만 완료된 상태**이니 순서대로 읽지 말고
이 표를 먼저 볼 것.

| 항목 | 상태 |
|---|---|
| 0. PW 게이트 해제 | ✅ 완료 (2026-07-14) — 사이트 공개 접근 가능 |
| 1. noindex 해제 | ⏸️ **의도적 보류** — 아래 ⚠️ 참고 |
| 3. robots.txt 복구 | ⏸️ **의도적 보류** — 아래 ⚠️ 참고 |
| 7. 출시 후 검증 | ✅ 완료 (스키마404·HSTS·CSP·결제·소스노출·감사로그·대시보드 3종 전부 검증, 2026-07-22) |
| 8. 검색엔진 등록 | ⏸️ 보류 (1·3 이 선행) |
| 9. PortOne 활성화 전 선행작업 | 📌 결제수단 확대 시에만 — 지금 급하지 않음 |

> ### ⚠️ 색인은 "빠뜨린 것"이 아니라 "일부러 막아둔 것"
> 전 페이지 `noindex` 와 robots.txt 전면 차단은 **콘텐츠를 채운 뒤로 미룬 의도된 결정**입니다.
> 성과사례 등이 아직 플레이스홀더라, 지금 색인시키면 빈 페이지가 검색결과에 박힙니다.
> **이 문서에 미완료로 남아있다는 이유만으로 1·3·8 을 진행하지 마세요.** 콘텐츠가 준비되고
> 사용자가 명시적으로 요청할 때 여는 항목입니다.

---

## 0. 출시 직전 (코드 배포 없이 Vercel 대시보드에서)

- [x] **⚠️ PW 게이트 해제** — Vercel → Settings → Environment Variables 에서 **`GATE_TOKEN` 삭제**.
      **완료 (2026-07-14).** (`middleware.js` 는 fail-safe: 토큰이 없으면 게이트가 자동 비활성.)

---

## 1. ⚠️ noindex 해제 — 색인시킬 "공개 마케팅 페이지"만

> ⏸️ **보류 중 — 임의로 진행하지 말 것** (사유는 위 현재 상태 참고). 2026-07-15 기준 라이브
> 홈은 여전히 `<meta name="robots" content="noindex, nofollow">` 입니다. 아래는 열기로
> 결정했을 때의 작업 목록일 뿐입니다.

각 파일의 `<meta name="robots" content="noindex, nofollow">` → **`index, follow`** 로 변경.
(주석 `출시 전 모드: noindex ... 출시 시 'index, follow'로 복구` 도 함께 정리)

- [ ] `index.html:12`
- [ ] `service.html:10`
- [ ] `cases.html:10`
- [ ] `case-detail.html:8`
- [ ] `interpreters.html:7`  ← 아래 "AI 크롤러" 항목도 함께 판단
- [ ] `interpreter-jobs.html:10`
- [ ] `interpreter-apply.html:8`
- [ ] `support.html:10`
- [ ] `performance.html:10`
- [ ] `terms.html:6`  (선택: 약관은 색인 안 해도 무방. 색인하려면 함께 변경)

## 2. ⚠️ noindex 유지 — 절대 색인하면 안 되는 페이지 (건드리지 말 것)

앱/인증/관리자/유틸 페이지는 출시 후에도 **noindex 유지**. 실수로 index 로 바꾸지 말 것.

- 🔒 `client-auth.html` (로그인)
- 🔒 `customer-dashboard.html`
- 🔒 `interpreter-dashboard.html`
- 🔒 `interpreter-pending.html` (검수 대기)
- 🔒 `admin-dashboard.html`
- 🔒 `admin-showcase-review.html`
- 🔒 `404.html` (404 는 항상 noindex 가 정상)

## 3. ⚠️ robots.txt 복구

> ⏸️ **보류 중 — 임의로 진행하지 말 것** (사유는 위 현재 상태 참고). 1번과 함께 열어야 의미가 있습니다.

`robots.txt` 에서 **일반 검색엔진**만 허용으로 전환. AI 크롤러 차단 블록(GPTBot, anthropic-ai, CCBot 등)은 **의도된 정책이므로 그대로 유지**.

- [ ] `Googlebot` → `Disallow:` (빈 값 = 전체 허용) 또는 `Allow: /`
- [ ] `Yeti` (네이버) → 허용
- [ ] `Bingbot` → 허용
- [ ] `User-agent: *` fallback → `Disallow:` (허용)
- [ ] 상단 주석 `⚠️ 출시 전 모드...` 제거
- [ ] `Sitemap: https://www.ctconfex.com/sitemap.xml` 유지 확인

## 4. AI 크롤러 차단 메타 (선택 — 정책 결정 필요)

`interpreters.html:8-11`, `customer-dashboard.html:8-11` 에 `GPTBot/anthropic-ai/Google-Extended/CCBot` noindex 메타가 있음.
- 공개 페이지(`interpreters.html`)에서 **AI 학습 크롤링을 계속 막을지** 결정.
  막을 거면 그대로 두고, 일반 검색 색인만 원하면 `robots` 메타만 `index, follow` 로(위 1번), AI 메타는 유지.
- 대시보드(`customer-dashboard.html`)의 AI 메타는 유지 (어차피 noindex 페이지).

---

## 5. sitemap.xml 정리

- [x] 로그인 페이지(`/client-auth`) 제거 — **완료** (2026-07-07)
- [ ] 전 URL `lastmod` 를 출시일로 갱신 (현재 2026-06-04 / 05-21 로 오래됨)
- [ ] `interpreter-apply` / `interpreter-jobs` 포함 여부 최종 확인 (공개 페이지면 유지 OK)
- [ ] 잔여 URL 목록 (현재): `/`, `/service`, `/interpreters`, `/cases`, `/interpreter-jobs`, `/performance`, `/support`, `/interpreter-apply`, `/terms`

## 6. canonical / 메타 정합성 (선택, LOW)

- [ ] `index.html` canonical/og:url 은 `https://www.ctconfex.com`(슬래시 없음), sitemap 은 `.../`(슬래시) — 하나로 통일
- [ ] `case-detail.html` 은 모든 동적 케이스가 canonical `/case-detail` 하나를 공유 → 케이스별로 색인시키려면 동적 canonical 필요 (색인 안 하면 무시 가능)

---

## 7. ⚠️ 출시 후 즉시 검증 (배포 확인)

- [x] `https://www.ctconfex.com/schema.json` , `/supabase-spec.json` → **404** 확인 — 둘 다 404 (2026-07-15 확인)
- [x] **결제 흐름** — 현재 운영은 **무통장입금 단독**(`MANUAL_ONLY_PAYMENT = true`)이고, 이 경로는
      2026-07-01 실제 1건 성사됨(`47_결제기록`). **PortOne 경유 결제는 UI 자체가 렌더링되지 않아
      지금 검증 대상이 아님.** 켤 때 필요한 선행 작업은 아래 **9번** 참고. (2026-07-16 확인)
- [x] **대시보드 3종** 로딩·이미지(통역사 프로필, flagcdn 국기)·차트 정상 —
      **2026-07-22 검증 완료:** 관리자·통역사·고객사 대시보드 3종 모두 정상 렌더링, 네트워크 요청 전부 200
      (고객사 PortOne SDK 304=캐시 정상), 콘솔 0건. flagcdn 국기는 `interpreters` 디렉토리에서 13개 전부 200·표시 확인.
      프로필은 이니셜 아바타 렌더 정상. 차트는 코드에 없음(N/A).
- [x] 브라우저 콘솔에 `Content-Security-Policy` 위반 에러 없는지 — **2026-07-21 검진서 검증 완료**
      (홈/대시보드/client-auth 콘솔 메시지 0건). 관리자 대시보드도 2026-07-22 콘솔 0건 확인.
- [x] 응답 헤더에 `Strict-Transport-Security` 존재 확인 — `max-age=31536000; includeSubDomains; preload` (2026-07-15)
- [x] 관리자 액션 후 `99_감사로그` 에 기록 남는지 (log_audit 동작 확인) —
      **2026-07-22 검증 완료:** 관리자 로그인이 `admin_login`으로 실시간 기록(처리자·대상·시간), 과거 기록 누적·필터 정상.
- [x] 게이트 해제 후 소스보기로 대시보드 HTML 이 노출돼도 무방한지 재확인 —
      **2026-07-21 확인:** `.env`/`.git`/`package.json` 등 404, 노출되는 `supabase-config.js`는 anon 키만(무방).

## 8. 검색엔진 등록 (출시 후)

- [ ] Google Search Console 에 사이트 등록 + `sitemap.xml` 제출
- [ ] 네이버 서치어드바이저 등록 + sitemap 제출
- [ ] Google Rich Results Test 로 JSON-LD 구조화 데이터 검증

---

## 9. ⚠️ PortOne 활성화 전 해결할 것 (결제수단 확대 시)

> 현재 `customer-dashboard.html` 의 `MANUAL_ONLY_PAYMENT = true` 가 카드/실시간이체/가상계좌를
> 전부 꺼두고 있습니다. **"한 줄만 false 로 바꾸면 복원"이 아닙니다.** 아래를 먼저 해결해야 합니다.
> (2026-07-16 점검. 결제수단 확대는 "나중에" 로 결정됨 — 지금 급한 항목 아님.)

- [ ] **가상계좌 발급 흐름이 서버에 없음** — `api/payment.js` 의 verify-payment 는 `status === 'PAID'`
      만 통과시킴. 가상계좌는 발급 시점 status 가 `VIRTUAL_ACCOUNT_ISSUED` 라 **발급 즉시 400 으로 튕김.**
      웹훅도 `Transaction.Paid` / `Transaction.Cancelled` 만 처리하고 `VirtualAccountIssued` 핸들러가 없음.
      → 발급 시점 분기 + 발급 대기 상태 기록 + 웹훅 처리까지 **신규 구현 필요** (배선 수준 아님).
- [ ] **`pmRenderVirtualResult()` 가 계좌번호를 지어냄** — `customer-dashboard.html` 에서
      `Math.random()` 으로 만든 번호를 "이 계좌로 입금해주세요"로 표시. PortOne 이 성공한 경우에도
      가짜 번호가 뜸(함수가 발급정보를 인자로 받지 않음). 실제 발급 계좌정보 배선 필요.
      (SDK 미로드 시의 데모 폴백은 2026-07-16 제거됨.)
- [ ] **채널이 테스트인지 실서비스인지 미확인** — `payment-data.js` 의 `PORTONE_STORE_ID` /
      `PORTONE_CHANNEL_KEY` 하드코딩. 원 주석이 "테스트 채널 생성 후 입력"이라 **테스트 채널일 가능성**.
      테스트 채널이면 결제가 성공해 보여도 실제 돈이 안 잡힘. → admin.portone.io 에서 확인 (콘솔 접근 필요).
- [ ] **PG 결제창 CSP 검증** — `frame-src` 는 `*.portone.io` 만, `form-action` 은 `'self'`.
      국내 PG(이니시스 등)가 자기 도메인으로 창을 띄우거나 폼을 전송하면 차단될 수 있음. 실제 결제창을
      띄워봐야 확인 가능.

> 참고: `PORTONE_V2_API_SECRET` / `PORTONE_WEBHOOK_SECRET` 는 프로덕션 런타임에 **정상 설정됨**
> (2026-07-16 확인). `vercel env pull` 로는 빈 값으로 내려오는데 이는 Vercel Sensitive 플래그 때문이며
> 누락이 아님. 서버 검증 로직(금액 재계산·중복결제 차단·customData 대조) 자체는 견고함.

---

## 참고: 관련 파일
- 게이트: `middleware.js` (GATE_TOKEN), `api/verify-pw.js`, `pw-gate.js`
- SEO: `robots.txt`, `sitemap.xml`, 각 `*.html` 의 `<head>` robots 메타
- 보안 헤더: `vercel.json` (CSP / HSTS)
