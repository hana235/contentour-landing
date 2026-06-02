// OG 이미지 생성 스크립트
// assets/og-template.html을 1200x630 JPEG(q92)로 렌더링하여 assets/og-image.jpg 저장
// 그라디언트 배경이라 PNG(393KB)보다 JPEG(~70KB)가 화질 손실 없이 훨씬 작음
// 실행: node generate-og-image.js

const path = require('path');
const puppeteer = require('puppeteer');

(async () => {
    const templatePath = 'file://' + path.resolve(__dirname, 'assets/og-template.html').replace(/\\/g, '/');
    const outPath = path.resolve(__dirname, 'assets/og-image.jpg');

    const browser = await puppeteer.launch({
        defaultViewport: { width: 1200, height: 630, deviceScaleFactor: 1 }
    });
    const page = await browser.newPage();
    await page.goto(templatePath, { waitUntil: 'networkidle0', timeout: 30000 });
    await page.evaluateHandle('document.fonts.ready');
    await page.screenshot({ path: outPath, type: 'jpeg', quality: 92, omitBackground: false });
    await browser.close();

    console.log('OG image generated:', outPath);
})().catch(e => { console.error(e); process.exit(1); });
