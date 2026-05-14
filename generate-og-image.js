// OG 이미지 생성 스크립트
// assets/og-template.html을 1200x630 PNG로 렌더링하여 assets/og-image.png 저장
// 실행: node generate-og-image.js

const path = require('path');
const puppeteer = require('puppeteer');

(async () => {
    const templatePath = 'file://' + path.resolve(__dirname, 'assets/og-template.html').replace(/\\/g, '/');
    const outPath = path.resolve(__dirname, 'assets/og-image.png');

    const browser = await puppeteer.launch({
        defaultViewport: { width: 1200, height: 630, deviceScaleFactor: 1 }
    });
    const page = await browser.newPage();
    await page.goto(templatePath, { waitUntil: 'networkidle0', timeout: 30000 });
    await page.evaluateHandle('document.fonts.ready');
    await page.screenshot({ path: outPath, type: 'png', omitBackground: false });
    await browser.close();

    console.log('OG image generated:', outPath);
})().catch(e => { console.error(e); process.exit(1); });
