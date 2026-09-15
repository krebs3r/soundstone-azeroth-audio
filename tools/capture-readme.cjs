/** Export README mockups from the production-asset browser preview.
 * Run python tools/preview.py first. Requires Playwright and Chromium (or Edge).
 * PLAYWRIGHT_MODULE may point to an existing Playwright installation.
 * BROWSER_CHANNEL=msedge selects an installed Edge without a browser download.
 */
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('node:fs/promises');
const path = require('node:path');

async function main() {
  const root = path.resolve(__dirname, '..');
  const toc = await fs.readFile(path.join(root, 'Soundstone/Soundstone.toc'), 'utf8');
  const version = toc.match(/^## Version: ([\d.]+)$/m)[1];
  const browser = await chromium.launch({
    headless: true,
    ...(process.env.BROWSER_CHANNEL ? { channel: process.env.BROWSER_CHANNEL } : {}),
  });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 1200 }, deviceScaleFactor: 2 });
    // One origin keeps canvas pixels readable without relaxing file security.
    // Fulfill every request from docs; no network server or remote request.
    await page.route('**/*', async route => {
      const url = new URL(route.request().url());
      const relative = decodeURIComponent(url.pathname).replace(/^\/+/, '');
      const docs = path.join(root, 'docs');
      const file = path.resolve(docs, relative);
      if (url.origin !== 'http://soundstone.local' || !file.startsWith(docs + path.sep)) {
        return route.abort();
      }
      await route.fulfill({ path: file, contentType: file.endsWith('.png') ? 'image/png' : 'text/html; charset=utf-8' });
    });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('requestfailed', request => errors.push(request.url()));
    const shots = [
      { name: 'retail', theme: 'Retail', view: 'expanded', popup: 'none', language: 'en', width: 600, height: 320 },
      { name: 'classic', theme: 'Classic', view: 'expanded', popup: 'none', language: 'en', width: 600, height: 320 },
      { name: 'compact-classic', theme: 'Classic', view: 'compact', popup: 'options', language: 'de', width: 552, height: 552 },
    ];
    for (const shot of shots) {
      const url = new URL('http://soundstone.local/ui-preview.html');
      url.search = new URLSearchParams({ capture: '1', zoom: '2', theme: shot.theme, view: shot.view, popup: shot.popup, language: shot.language }).toString();
      await page.goto(url.href);
      await page.waitForFunction(() => document.body.dataset.ready === 'true');
      await page.evaluate(width => {
        const canvas = document.querySelector('section > div:not([hidden]) canvas');
        // The compact view uses 276 of the renderer's 300 UI units.
        canvas.parentElement.style.width = width + 'px';
        canvas.parentElement.style.overflow = 'hidden';
      }, shot.width);
      const target = page.locator('section > div:not([hidden])');
      const bounds = await target.boundingBox();
      if (bounds.width !== shot.width || bounds.height !== shot.height) {
        throw new Error(`Unexpected dimensions for ${shot.name}: ${JSON.stringify(bounds)}`);
      }
      const output = path.join(root, `docs/screenshots/soundstone-${version}-${shot.name}.png`);
      await target.screenshot({ path: output });
      console.log(`${path.basename(output)}: ${shot.width * 2} x ${shot.height * 2}`);
    }
    if (errors.length) throw new Error(errors.join('\n'));
  } finally {
    await browser.close();
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
