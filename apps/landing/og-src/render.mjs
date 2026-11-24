#!/usr/bin/env node
/**
 * Ourney OG & Brand Icon Renderer (apps/landing/og-src/render.mjs)
 * Renders all Open Graph share cards (1200x630 + 1200x1200 square) and
 * app icons (apple-touch-icon 180x180, icon-192, icon-512, favicon.ico)
 * from apps/landing/og-src/*.html using headless Chrome via CDP.
 */
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const LANDING_DIR = path.resolve(__dirname, '..');
const OG_OUT_DIR = path.join(LANDING_DIR, 'assets', 'og');
const BRAND_OUT_DIR = path.join(LANDING_DIR, 'assets', 'brand');
const REPORT_SHOTS_DIR = 'E:/Ourney/agy-work/reports/landing-seo-shots';

fs.mkdirSync(OG_OUT_DIR, { recursive: true });
fs.mkdirSync(BRAND_OUT_DIR, { recursive: true });
fs.mkdirSync(REPORT_SHOTS_DIR, { recursive: true });

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.woff2': 'font/woff2',
  '.ico': 'image/x-icon',
  '.json': 'application/json; charset=utf-8',
  '.webmanifest': 'application/manifest+json; charset=utf-8',
  '.xml': 'application/xml; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
};

const NEW_SCREENS_DIR = fs.existsSync('E:/Ourney/Ourney/.claude/worktrees/landing-screens/apps/landing/assets/screens/hub.webp')
  ? 'E:/Ourney/Ourney/.claude/worktrees/landing-screens/apps/landing/assets/screens'
  : path.join(LANDING_DIR, 'assets', 'screens');

const PHOTO_MAP = {
  '/og-src/photos/ielts-cover.webp': 'E:/Ourney/agy-work/photos/ielts_study/cover.webp',
  '/og-src/photos/ielts-01.webp': 'E:/Ourney/agy-work/photos/ielts_study/01.webp',
  '/og-src/photos/ielts-03.webp': 'E:/Ourney/agy-work/photos/ielts_study/03.webp',
  '/og-src/photos/ielts-04.webp': 'E:/Ourney/agy-work/photos/ielts_study/04.webp',
  '/og-src/photos/run-01.webp': 'E:/Ourney/agy-work/photos/morning_run/01.webp',
  '/og-src/photos/run-02.webp': 'E:/Ourney/agy-work/photos/morning_run/02.webp',
  '/og-src/photos/hub.webp': path.join(NEW_SCREENS_DIR, 'hub.webp'),
  '/og-src/photos/share-travel.webp': path.join(NEW_SCREENS_DIR, 'share-travel.webp'),
  '/og-src/photos/wrapped-run.webp': path.join(NEW_SCREENS_DIR, 'wrapped-run.webp'),
  '/assets/screens/hub.webp': path.join(NEW_SCREENS_DIR, 'hub.webp'),
  '/assets/screens/share-travel.webp': path.join(NEW_SCREENS_DIR, 'share-travel.webp'),
  '/assets/screens/wrapped-run.webp': path.join(NEW_SCREENS_DIR, 'wrapped-run.webp'),
};

function startServer(rootDir) {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const urlPath = decodeURIComponent(req.url.split('?')[0]);
      if (PHOTO_MAP[urlPath] && fs.existsSync(PHOTO_MAP[urlPath])) {
        res.writeHead(200, { 'Content-Type': 'image/webp' });
        fs.createReadStream(PHOTO_MAP[urlPath]).pipe(res);
        return;
      }
      const rel = urlPath === '/' ? '/index.html' : urlPath;
      const filePath = path.join(rootDir, rel);
      if (!filePath.startsWith(rootDir) || !fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      const ext = path.extname(filePath).toLowerCase();
      res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
      fs.createReadStream(filePath).pipe(res);
    });
    server.listen(0, '127.0.0.1', () => resolve({ server, port: server.address().port }));
  });
}

function buildIcoFromPngs(pngBuffersWithSizes) {
  // Standard ICO container with embedded PNG payloads (supported by all modern & legacy browsers since Vista)
  const count = pngBuffersWithSizes.length;
  const headerSize = 6 + count * 16;
  const totalSize = headerSize + pngBuffersWithSizes.reduce((acc, item) => acc + item.buf.length, 0);
  const out = Buffer.alloc(totalSize);
  out.writeUInt16LE(0, 0);     // Reserved
  out.writeUInt16LE(1, 2);     // Type 1 = ICO
  out.writeUInt16LE(count, 4); // Image count

  let dataOffset = headerSize;
  pngBuffersWithSizes.forEach((item, idx) => {
    const entryOffset = 6 + idx * 16;
    const dim = item.size >= 256 ? 0 : item.size;
    out.writeUInt8(dim, entryOffset);      // Width
    out.writeUInt8(dim, entryOffset + 1);  // Height
    out.writeUInt8(0, entryOffset + 2);    // Palette
    out.writeUInt8(0, entryOffset + 3);    // Reserved
    out.writeUInt16LE(1, entryOffset + 4); // Color planes
    out.writeUInt16LE(32, entryOffset + 6);// Bits per pixel
    out.writeUInt32LE(item.buf.length, entryOffset + 8);
    out.writeUInt32LE(dataOffset, entryOffset + 12);
    item.buf.copy(out, dataOffset);
    dataOffset += item.buf.length;
  });
  return out;
}

async function connectCdp(debugPort) {
  for (let i = 0; i < 40; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${debugPort}/json/list`);
      const list = await res.json();
      const page = list.find((t) => t.type === 'page');
      if (page && page.webSocketDebuggerUrl) return page.webSocketDebuggerUrl;
    } catch {}
    await new Promise((r) => setTimeout(r, 150));
  }
  throw new Error('Failed to connect to Chrome CDP');
}

class CdpClient {
  constructor(wsUrl) {
    this.ws = new WebSocket(wsUrl);
    this.id = 0;
    this.pending = new Map();
  }
  async ready() {
    if (this.ws.readyState === WebSocket.OPEN) return;
    await new Promise((resolve, reject) => {
      this.ws.addEventListener('open', resolve, { once: true });
      this.ws.addEventListener('error', reject, { once: true });
    });
    this.ws.addEventListener('message', (ev) => {
      const msg = JSON.parse(ev.data);
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.error) reject(new Error(msg.error.message));
        else resolve(msg.result);
      }
    });
  }
  send(method, params = {}) {
    const id = ++this.id;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }
  close() {
    this.ws.close();
  }
}

async function main() {
  const { server, port } = await startServer(LANDING_DIR);
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const debugPort = 9244;
  const userDataDir = path.join(REPORT_SHOTS_DIR, '.chrome-profile');
  fs.mkdirSync(userDataDir, { recursive: true });

  const chrome = spawn(chromePath, [
    '--headless=new',
    '--disable-gpu',
    '--no-first-run',
    '--no-default-browser-check',
    '--hide-scrollbars',
    `--remote-debugging-port=${debugPort}`,
    `--user-data-dir=${userDataDir}`,
    'about:blank',
  ], { stdio: 'ignore' });

  try {
    const wsUrl = await connectCdp(debugPort);
    const cdp = new CdpClient(wsUrl);
    await cdp.ready();
    await cdp.send('Page.enable');
    await cdp.send('Runtime.enable');

    const cards = [
      { name: 'og-default', file: 'og-default.html', width: 1200, height: 630 },
      { name: 'og-default-en', file: 'og-default-en.html', width: 1200, height: 630 },
      { name: 'og-invite', file: 'og-invite.html', width: 1200, height: 630 },
      { name: 'og-join', file: 'og-join.html', width: 1200, height: 630 },
      { name: 'og-journey', file: 'og-journey.html', width: 1200, height: 630 },
      { name: 'og-default-square', file: 'og-default-square.html', width: 1200, height: 1200 },
    ];

    for (const card of cards) {
      await cdp.send('Emulation.setDeviceMetricsOverride', {
        width: card.width,
        height: card.height,
        deviceScaleFactor: 1,
        mobile: false,
      });
      await cdp.send('Page.navigate', { url: `http://127.0.0.1:${port}/og-src/${card.file}` });
      await cdp.send('Runtime.evaluate', {
        expression: `new Promise(r => {
          const check = async () => {
            if (document.readyState !== 'complete') return setTimeout(check, 50);
            await document.fonts.ready;
            const imgs = [...document.images];
            await Promise.all(imgs.map(img => img.complete ? Promise.resolve() : new Promise(res => { img.onload = res; img.onerror = res; })));
            setTimeout(r, 120);
          };
          check();
        })`,
        awaitPromise: true,
      });

      const pngShot = await cdp.send('Page.captureScreenshot', {
        format: 'png',
        clip: { x: 0, y: 0, width: card.width, height: card.height, scale: 1 },
      });
      const jpgShot = await cdp.send('Page.captureScreenshot', {
        format: 'jpeg',
        quality: 90,
        clip: { x: 0, y: 0, width: card.width, height: card.height, scale: 1 },
      });

      const pngBuf = Buffer.from(pngShot.data, 'base64');
      const jpgBuf = Buffer.from(jpgShot.data, 'base64');

      const pngPath = path.join(OG_OUT_DIR, `${card.name}.png`);
      const jpgPath = path.join(OG_OUT_DIR, `${card.name}.jpg`);
      fs.writeFileSync(pngPath, pngBuf);
      fs.writeFileSync(jpgPath, jpgBuf);
      fs.writeFileSync(path.join(REPORT_SHOTS_DIR, `${card.name}.png`), pngBuf);

      console.log(`Rendered ${card.name} (${card.width}x${card.height}): PNG=${(pngBuf.length / 1024).toFixed(1)}KB, JPG=${(jpgBuf.length / 1024).toFixed(1)}KB`);
    }

    // Render App Icons (apple-touch-icon 180x180, icon-192, icon-512, and 16/32/48 for favicon.ico)
    const iconSizes = [
      { size: 180, out: path.join(BRAND_OUT_DIR, 'apple-touch-icon.png') },
      { size: 192, out: path.join(BRAND_OUT_DIR, 'icon-192.png') },
      { size: 512, out: path.join(BRAND_OUT_DIR, 'icon-512.png') },
      { size: 16, out: null },
      { size: 32, out: null },
      { size: 48, out: null },
    ];
    const icoFrames = [];

    for (const item of iconSizes) {
      await cdp.send('Emulation.setDeviceMetricsOverride', {
        width: item.size,
        height: item.size,
        deviceScaleFactor: 1,
        mobile: false,
      });
      await cdp.send('Page.navigate', { url: `http://127.0.0.1:${port}/og-src/icon-render.html` });
      await cdp.send('Runtime.evaluate', {
        expression: `new Promise(r => setTimeout(r, 80))`,
        awaitPromise: true,
      });
      const shot = await cdp.send('Page.captureScreenshot', {
        format: 'png',
        clip: { x: 0, y: 0, width: item.size, height: item.size, scale: 1 },
      });
      const buf = Buffer.from(shot.data, 'base64');
      if (item.out) {
        fs.writeFileSync(item.out, buf);
        console.log(`Rendered icon ${path.basename(item.out)} (${item.size}x${item.size}): ${(buf.length / 1024).toFixed(1)}KB`);
      } else {
        icoFrames.push({ size: item.size, buf });
      }
    }

    const icoBuf = buildIcoFromPngs(icoFrames);
    fs.writeFileSync(path.join(LANDING_DIR, 'favicon.ico'), icoBuf);
    console.log(`Built favicon.ico (16x16, 32x32, 48x48): ${(icoBuf.length / 1024).toFixed(1)}KB`);

    // Render Messenger & Zalo Unfurl Mockup Preview Sheet
    await cdp.send('Emulation.setDeviceMetricsOverride', {
      width: 1440,
      height: 1120,
      deviceScaleFactor: 1,
      mobile: false,
    });
    await cdp.send('Page.navigate', { url: `http://127.0.0.1:${port}/og-src/preview-cards.html` });
    await cdp.send('Runtime.evaluate', {
      expression: `new Promise(r => {
        const check = async () => {
          if (document.readyState !== 'complete') return setTimeout(check, 50);
          await document.fonts.ready;
          const imgs = [...document.images];
          await Promise.all(imgs.map(img => img.complete ? Promise.resolve() : new Promise(res => { img.onload = res; img.onerror = res; })));
          setTimeout(r, 150);
        };
        check();
      })`,
      awaitPromise: true,
    });
    const previewShot = await cdp.send('Page.captureScreenshot', {
      format: 'png',
      clip: { x: 0, y: 0, width: 1440, height: 1120, scale: 1 },
    });
    const previewBuf = Buffer.from(previewShot.data, 'base64');
    const previewOut = path.join(REPORT_SHOTS_DIR, 'messenger-zalo-unfurl-preview.png');
    fs.writeFileSync(previewOut, previewBuf);
    console.log(`Rendered Messenger/Zalo Unfurl Preview Sheet: ${(previewBuf.length / 1024).toFixed(1)}KB -> ${previewOut}`);

    cdp.close();
  } finally {
    chrome.kill();
    server.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
