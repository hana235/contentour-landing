# 🚀 ctconfex.com 출시 체크리스트

> 이 문서는 배포되지 않습니다 (`.vercelignore` 의 `*.md`). 내부 전용.
> 현재 사이트는 **출시 전(pre-launch) 모드**: 전 페이지 noindex + robots.txt 전면 차단 + PW 게이트.
> 출시일에 아래 순서대로 진행할 것. **⚠️ 표시 항목은 놓치면 색인/보안 사고로 직결.**

---

## 0. 출시 직전 (코드 배포 없이 Vercel 대시보드에서)

- [ ] **⚠️ PW 게이트 해제** — Vercel → Settings → Environment Variables 에서 **`GATE_TOKEN` 삭제**.
      (`middleware.js` 는 fail-safe: 토큰이 없으면 게이트가 자동 비활성. 코드 수정 불필요.)
      → 삭제 후 재배포(Redeploy) 필요할 수 있음.

---

## 1. ⚠️ noindex 해제 — 색인시킬 "공개 마케팅 페이지"만

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

- [ ] `https://www.ctconfex.com/schema.json` , `/supabase-spec.json` → **404** 확인 (스키마 노출 차단됐는지)
- [ ] **결제 흐름(PortOne)** 실제 동작 — CSP enforce 로 결제창/스크립트가 안 막히는지
- [ ] **대시보드 3종** 로딩·이미지(통역사 프로필, flagcdn 국기)·차트 정상
- [ ] 브라우저 콘솔에 `Content-Security-Policy` 위반 에러 없는지 (있으면 해당 호스트를 `vercel.json` CSP 에 추가)
- [ ] 응답 헤더에 `Strict-Transport-Security` 존재 확인
- [ ] 관리자 액션(예: 지원서 승인) 1회 후 `99_감사로그` 에 기록 남는지 (log_audit 동작 확인)
- [ ] 게이트 해제 후 소스보기로 대시보드 HTML 이 노출돼도 무방한지 재확인 (데이터는 RLS 로 보호되나 구조는 공개됨)

## 8. 검색엔진 등록 (출시 후)

- [ ] Google Search Console 에 사이트 등록 + `sitemap.xml` 제출
- [ ] 네이버 서치어드바이저 등록 + sitemap 제출
- [ ] Google Rich Results Test 로 JSON-LD 구조화 데이터 검증

---

## 참고: 관련 파일
- 게이트: `middleware.js` (GATE_TOKEN), `api/verify-pw.js`, `pw-gate.js`
- SEO: `robots.txt`, `sitemap.xml`, 각 `*.html` 의 `<head>` robots 메타
- 보안 헤더: `vercel.json` (CSP / HSTS)
