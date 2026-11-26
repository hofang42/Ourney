import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import { chromium, firefox, webkit } from 'playwright';

const site = 'http://landing.test';
const root = new URL('../', import.meta.url);
const landingUrl = site + '/?lang=en&plat=ios#beta';
const mime = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.woff2': 'font/woff2',
};

async function landingContext(browser, options) {
  const context = await browser.newContext(options);
  context.setDefaultTimeout(5000);
  await context.route('**/*', async (route) => {
    const url = new URL(route.request().url());
    if (url.origin !== site) return route.abort();
    const file = new URL(url.pathname === '/' ? 'index.html' : '.' + url.pathname, root);
    const type = mime[extname(url.pathname === '/' ? 'index.html' : url.pathname)];
    if (!type || !file.href.startsWith(root.href)) return route.abort();
    return route.fulfill({ contentType: type, path: fileURLToPath(file) });
  });
  return context;
}

const engines = {
  chrome: () => chromium.launch({ channel: 'chrome' }),
  firefox: () => firefox.launch(),
  webkit: () => webkit.launch(),
};
const engine = process.env.LANDING_BROWSER || 'chrome';
const launch = engines[engine];
assert.ok(launch, 'LANDING_BROWSER must be chrome, firefox, or webkit');

test(`${engine} loads and shapes the landing fonts`, async (t) => {
  const browser = await launch();
  t.after(() => browser.close());
  const context = await landingContext(browser);
  const page = await context.newPage();
  const fontErrors = [];
  page.on('console', (message) => {
    if (/OTS parsing error|Failed to decode downloaded font|downloadable font.*(?:rejected|error)/i.test(message.text())) {
      fontErrors.push(message.text());
    }
  });
  await page.goto(landingUrl);

  const faces = [
    { family: 'Space Grotesk', weight: 700 },
    { family: 'Be Vietnam Pro', weight: 400 },
    { family: 'Be Vietnam Pro', weight: 600 },
  ];
  for (const { family, weight } of faces) {
    const font = `${weight} 72px "${family}"`;
    const results = await page.evaluate(async ({ font, family }) => {
      const vietnamese = 'Nguyễn Thị Ánh · Đà Lạt · ệ ữ ấ ễ ặ ộ ỳ ỵ';
      const loaded = await document.fonts.load(font, vietnamese + ' 35mm film roll fl');
      const specimen = document.createElement('span');
      specimen.style.cssText = 'position:absolute; display:inline-block; white-space:pre; letter-spacing:normal';
      specimen.style.font = font;
      specimen.lang = 'vi';
      document.body.append(specimen);
      function width(text, ligatures) {
        specimen.textContent = text;
        specimen.style.fontFeatureSettings = ligatures ? '"liga" 1' : '"liga" 0';
        return specimen.getBoundingClientRect().width;
      }
      const film = width('35mm film roll', true);
      const measures = {
        loaded: loaded.some((face) => face.family.replace(/["']/g, '') === family && face.status === 'loaded'),
        vietnameseDelta: Math.abs(width(vietnamese, true) - width(vietnamese.normalize('NFD'), true)),
        film,
        separatedFilm: width('35mm film roll', false),
        unicodeFilm: width('35mm \uFB01lm roll', true),
        fl: width('fl', true),
        unicodeFl: width('\uFB02', true),
      };
      specimen.remove();
      return measures;
    }, { font, family });
    assert.ok(results.loaded, `${font} was not loaded`);
    assert.ok(results.vietnameseDelta < 1, `${font} shapes decomposed Vietnamese differently`);
    if (family === 'Be Vietnam Pro') {
      assert.ok(Math.abs(results.film - results.separatedFilm) > 0.1, `${font} did not substitute fi in film`);
      assert.ok(Math.abs(results.film - results.unicodeFilm) < 1, `${font} did not render the fi ligature glyph`);
      assert.ok(Math.abs(results.fl - results.unicodeFl) < 1, `${font} did not render the fl ligature glyph`);
    }
  }
  assert.deepEqual(fontErrors, []);
});

test(`${engine} shows waitlist help with JavaScript disabled or main.js unavailable`, async (t) => {
  const browser = await launch();
  t.after(() => browser.close());
  for (const javaScriptEnabled of [false, true]) {
    const context = await landingContext(browser, { javaScriptEnabled });
    try {
      if (javaScriptEnabled) await context.route('**/main.js', (route) => route.abort());
      const page = await context.newPage();
      await page.goto(landingUrl);
      assert.equal(await page.locator('#beta-form').getAttribute('method'), 'post');
      assert.equal(await page.locator('#email').isVisible(), false);
      assert.equal(await page.locator('#beta-waitlist-help').isVisible(), true);
      assert.equal(page.url(), landingUrl);
    } finally {
      await context.close();
    }
  }
});

test(`${engine} submits JSON and shows failures and enrollment independently of mail`, async (t) => {
  const browser = await launch();
  t.after(() => browser.close());
  const context = await landingContext(browser);
  const html = await readFile(new URL('index.html', root), 'utf8');
  const endpoint = html.match(/name="ourney-waitlist-endpoint" content="([^"]+)"/)[1];
  const requests = [];
  let status = 500;
  await context.route(endpoint, async (route) => {
    const request = route.request();
    if (request.method() !== 'OPTIONS') {
      requests.push({ method: request.method(), url: request.url(), body: request.postDataJSON(),
        contentType: request.headers()['content-type'] });
    }
    await route.fulfill({
      status: request.method() === 'OPTIONS' ? 204 : status,
      headers: {
        'access-control-allow-origin': site,
        'access-control-allow-methods': 'POST, OPTIONS',
        'access-control-allow-headers': 'content-type',
      },
      body: request.method() === 'OPTIONS' ? undefined : JSON.stringify(
        status === 200 ? { ok: true, mailSent: false } : { error: 'internal' },
      ),
      contentType: 'application/json',
    });
  });
  const page = await context.newPage();
  await page.goto(landingUrl);
  const email = page.getByRole('textbox', { name: 'Email' });
  const submit = page.getByRole('button', { name: 'get beta updates' });
  const statusMessage = page.locator('#form-msg');
  await email.fill('reader@example.test');
  await submit.click();
  await statusMessage.getByText('Couldn’t send that. Please try again in a few minutes.').waitFor();
  assert.equal(await email.inputValue(), 'reader@example.test');
  status = 200;
  await submit.click();
  await statusMessage.getByText('You’re on the iOS beta waitlist!', { exact: true }).waitFor();
  assert.equal(await email.inputValue(), '');
  assert.equal(page.url(), landingUrl);
  assert.deepEqual(requests, Array(2).fill({
    method: 'POST',
    url: endpoint,
    contentType: 'application/json',
    body: { email: 'reader@example.test', lang: 'en', platforms: ['ios'], source: 'landing', website: '' },
  }));
});
