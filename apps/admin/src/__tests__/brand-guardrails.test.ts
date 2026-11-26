import crypto from 'node:crypto'
import fs from 'node:fs'
import path from 'node:path'
import vm from 'node:vm'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { injectCloudflareBeacon } from '../lib/cfBeacon'

function collectSourceFiles(dir: string): string[] {
  const entries = fs.readdirSync(dir, { withFileTypes: true })
  const files: string[] = []
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      files.push(...collectSourceFiles(fullPath))
    } else if (/\.(ts|tsx|css)$/.test(entry.name)) {
      files.push(fullPath)
    }
  }
  return files
}

describe('CLAUDE.md Brand & Security Guardrails', () => {
  const adminRoot = path.resolve(__dirname, '../..')
  const srcRoot = path.resolve(__dirname, '..')

  it('has zero prohibited stock icon packages in package.json', () => {
    const pkgRaw = fs.readFileSync(
      path.join(adminRoot, 'package.json'),
      'utf8',
    )
    const prohibited = [
      'lucide-react',
      '@heroicons',
      '@mui',
      '@phosphor-icons',
      'react-icons',
      'feather-icons',
    ]
    for (const pkg of prohibited) {
      expect(pkgRaw).not.toContain(pkg)
    }
  })

  it('contains zero emoji or Unicode symbol glyphs in apps/admin/src/**/*.{ts,tsx,css}', () => {
    const files = collectSourceFiles(srcRoot)
    expect(files.length).toBeGreaterThan(10)

    const emojiRegex = /\p{Extended_Pictographic}/u
    const forbiddenSymbolsRegex = /[●★♥✓➔→🔥⚖📚✈💞💪✨👋👏]/u

    for (const file of files) {
      if (file.endsWith('brand-guardrails.test.ts')) continue
      const content = fs.readFileSync(file, 'utf8')
      const rel = path.relative(adminRoot, file)
      expect(emojiRegex.test(content), `Emoji found in ${rel}`).toBe(false)
      expect(
        forbiddenSymbolsRegex.test(content),
        `Forbidden Unicode symbol glyph found in ${rel}`,
      ).toBe(false)
    }
  })

  it('contains zero demo-mode auth bypasses, DEMO_* fixtures, or service_role secrets in production source files', () => {
    const prodDirs = [
      path.join(srcRoot, 'lib'),
      path.join(srcRoot, 'pages'),
      path.join(srcRoot, 'ui'),
    ]
    const prodFiles = [
      path.join(srcRoot, 'App.tsx'),
      path.join(srcRoot, 'main.tsx'),
      ...prodDirs.flatMap((d) => collectSourceFiles(d)),
    ]

    const prohibitedPatterns = [
      /isDemoMode/,
      /ourney_admin_demo/,
      /\bDEMO_/,
      /SERVICE_ROLE/i,
      /sb_secret_/i,
    ]

    for (const file of prodFiles) {
      const content = fs.readFileSync(file, 'utf8')
      const rel = path.relative(adminRoot, file)
      for (const pattern of prohibitedPatterns) {
        expect(
          pattern.test(content),
          `Prohibited production pattern ${String(pattern)} found in ${rel}`,
        ).toBe(false)
      }
    }
  })

  it('enforces strict production Content-Security-Policy in public/_headers (and legacy vercel.json) without localhost or missing object-src', () => {
    const headersRaw = fs.readFileSync(
      path.join(adminRoot, 'public', '_headers'),
      'utf8',
    )
    expect(headersRaw).toContain("object-src 'none'")
    expect(headersRaw).toContain("frame-ancestors 'none'")
    expect(headersRaw).toContain('https://static.cloudflareinsights.com')
    expect(headersRaw).toContain('https://cloudflareinsights.com')
    expect(headersRaw).not.toContain('localhost')
    expect(headersRaw).not.toContain('127.0.0.1')

    const vercelRaw = fs.readFileSync(
      path.join(adminRoot, 'vercel.json'),
      'utf8',
    )
    expect(vercelRaw).toContain("object-src 'none'")
    expect(vercelRaw).toContain("frame-ancestors 'none'")
    expect(vercelRaw).not.toContain('localhost')
    expect(vercelRaw).not.toContain('127.0.0.1')
  })

  describe('Cloudflare Web Analytics beacon injection (VITE_CF_BEACON_TOKEN)', () => {
    beforeEach(() => {
      document
        .querySelectorAll('script[data-cf-beacon]')
        .forEach((node) => node.remove())
    })

    it('injects nothing when VITE_CF_BEACON_TOKEN is unset or blank', () => {
      expect(injectCloudflareBeacon(undefined, document)).toBeNull()
      expect(injectCloudflareBeacon('', document)).toBeNull()
      expect(injectCloudflareBeacon('   ', document)).toBeNull()
      expect(document.querySelector('script[data-cf-beacon]')).toBeNull()
    })

    it('injects the Cloudflare beacon script when VITE_CF_BEACON_TOKEN is set and avoids duplicate tags', () => {
      const script = injectCloudflareBeacon('cf-admin-token-123', document)
      expect(script).not.toBeNull()
      expect(script?.src).toBe(
        'https://static.cloudflareinsights.com/beacon.min.js',
      )
      expect(script?.defer).toBe(true)
      expect(script?.getAttribute('data-cf-beacon')).toBe(
        JSON.stringify({ token: 'cf-admin-token-123' }),
      )

      const second = injectCloudflareBeacon('cf-admin-token-123', document)
      expect(second).toBe(script)
      expect(document.querySelectorAll('script[data-cf-beacon]').length).toBe(1)
    })
  })

  describe('Landing Invite Privacy & Anti-Cache Guardrails (F-22 & F-23)', () => {
    const landingRoot = path.resolve(adminRoot, '../landing')

    it('excludes Cloudflare Web Analytics beacon and includes no-referrer meta on /f and /j invite pages (F-22)', () => {
      for (const page of ['f.html', 'j.html', 'p.html']) {
        const html = fs.readFileSync(path.join(landingRoot, page), 'utf8')
        expect(
          html,
          `${page} must declare <meta name="referrer" content="no-referrer">`,
        ).toContain('<meta name="referrer" content="no-referrer">')
        expect(
          html,
          `${page} must not load Cloudflare Web Analytics beacon.min.js`,
        ).not.toContain('static.cloudflareinsights.com/beacon.min.js')
        expect(
          html,
          `${page} must not contain data-cf-beacon`,
        ).not.toContain('data-cf-beacon')
      }

      // Marketing pages (index.html, 404.html) retain Cloudflare Web Analytics
      for (const pubPage of ['index.html', '404.html']) {
        const html = fs.readFileSync(path.join(landingRoot, pubPage), 'utf8')
        expect(html).toContain('static.cloudflareinsights.com/beacon.min.js')
      }
    })

    it('sets Cache-Control: private, no-store on Pages Functions /f/:token and /j/:code without caches.default storage, and revalidates live in link.js (F-23)', () => {
      for (const fnRel of ['functions/f/[token].js', 'functions/j/[code].js']) {
        const fnSrc = fs.readFileSync(path.join(landingRoot, fnRel), 'utf8')
        expect(fnSrc).toContain(
          "headers.set('Cache-Control', 'private, no-store')",
        )
        expect(fnSrc).toContain(
          "headers.set('Referrer-Policy', 'no-referrer')",
        )
        expect(fnSrc).not.toContain('stale-while-revalidate')
        expect(fnSrc).not.toContain('caches.default')
        expect(fnSrc).not.toContain('edgeCache.put')
      }

      const linkJs = fs.readFileSync(path.join(landingRoot, 'link.js'), 'utf8')
      expect(linkJs).toContain('const hadEmbedded = Boolean(embedded);')
      expect(linkJs).toContain("getRpcEndpoint('preview_friend_invite')")
      expect(linkJs).toContain("getRpcEndpoint('preview_group_invite')")
    })

    it('preserves exact CSP inline script SHA-256 hash across all 5 landing HTML files and revalidates revoked/full invites live in link.js (F-22 & F-23)', async () => {
      const landingHeaders = fs.readFileSync(
        path.join(landingRoot, '_headers'),
        'utf8',
      )
      for (const page of [
        'index.html',
        '404.html',
        'f.html',
        'j.html',
        'p.html',
      ]) {
        const html = fs.readFileSync(path.join(landingRoot, page), 'utf8')
        const inlineScripts = [
          ...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi),
        ]
        for (const m of inlineScripts) {
          if (m[0].includes('application/ld+json')) continue
          const hash = crypto
            .createHash('sha256')
            .update(m[1], 'utf8')
            .digest('base64')
          expect(
            landingHeaders,
            `CSP hash for inline script in ${page}`,
          ).toContain(`'sha256-${hash}'`)
        }
      }

      // Execute link.js against f.html with an embedded 'ok' preview whose token was subsequently revoked in Supabase (returns null)
      const fHtml = fs.readFileSync(path.join(landingRoot, 'f.html'), 'utf8')
      const linkJs = fs.readFileSync(path.join(landingRoot, 'link.js'), 'utf8')
      document.documentElement.setAttribute('data-link-page', 'friend')
      document.documentElement.setAttribute(
        'data-invite-preview',
        JSON.stringify({
          status: 'ok',
          token: 'abc123def456',
          data: {
            display_name: 'Stale Cached Inviter',
            handle: 'stale_user',
            avatar_initial: 'S',
          },
        }),
      )
      document.body.innerHTML = fHtml.replace(
        /^[\s\S]*<body[^>]*>|<\/body>[\s\S]*$/gi,
        '',
      )
      window.history.replaceState({}, '', '/f/abc123def456')

      const fetchMock = vi.fn().mockResolvedValueOnce(
        new Response(JSON.stringify(null), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        }),
      )
      vi.stubGlobal('fetch', fetchMock)
      vi.stubGlobal('matchMedia', () => ({
        matches: false,
        addEventListener: () => {},
        removeEventListener: () => {},
      }))

      vm.runInThisContext(linkJs)
      await new Promise((r) => setTimeout(r, 30))

      expect(fetchMock).toHaveBeenCalledTimes(1)
      expect(
        document.getElementById('f-expired-card')?.hasAttribute('hidden'),
      ).toBe(false)
      expect(
        document.getElementById('f-valid-card')?.hasAttribute('hidden'),
      ).toBe(true)

      document.documentElement.removeAttribute('data-link-page')
      document.documentElement.removeAttribute('data-invite-preview')
      vi.unstubAllGlobals()

      // Execute Pages Functions /f/:token and /j/:code at runtime and assert Cache-Control: private, no-store and Referrer-Policy: no-referrer
      const loadPagesFunction = (relPath: string) => {
        const src = fs
          .readFileSync(path.join(landingRoot, relPath), 'utf8')
          .replace(/\bexport\s+/g, '')
        return vm.runInThisContext(
          `(() => { ${src}\n return { onRequestGet, onRequestHead }; })()`,
        ) as {
          onRequestGet: (ctx: unknown) => Promise<Response>
        }
      }
      const fMod = loadPagesFunction('functions/f/[token].js')
      const jMod = loadPagesFunction('functions/j/[code].js')

      const fnFetchMock = vi.fn().mockResolvedValue(
        new Response(JSON.stringify(null), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        }),
      )
      vi.stubGlobal('fetch', fnFetchMock)

      const fRes = await fMod.onRequestGet({
        params: { token: 'abc123def456' },
        request: new Request('https://ourney.tech/f/abc123def456'),
        env: {
          ASSETS: {
            fetch: async () =>
              new Response(fHtml, {
                status: 200,
                headers: {
                  'Content-Type': 'text/html; charset=utf-8',
                  ETag: '"v1"',
                },
              }),
          },
        },
      })
      expect(fRes.headers.get('Cache-Control')).toBe('private, no-store')
      expect(fRes.headers.get('Referrer-Policy')).toBe('no-referrer')
      expect(fRes.headers.get('ETag')).toBeNull()

      const jHtml = fs.readFileSync(path.join(landingRoot, 'j.html'), 'utf8')
      const jRes = await jMod.onRequestGet({
        params: { code: 'ABCD1234' },
        request: new Request('https://ourney.tech/j/ABCD1234'),
        env: {
          ASSETS: {
            fetch: async () =>
              new Response(jHtml, {
                status: 200,
                headers: {
                  'Content-Type': 'text/html; charset=utf-8',
                  'Last-Modified': 'Wed, 26 Nov 2026 00:00:00 GMT',
                },
              }),
          },
        },
      })
      expect(jRes.headers.get('Cache-Control')).toBe('private, no-store')
      expect(jRes.headers.get('Referrer-Policy')).toBe('no-referrer')
      expect(jRes.headers.get('Last-Modified')).toBeNull()

      vi.unstubAllGlobals()
    })
  })
})
