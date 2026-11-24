import fs from 'node:fs'
import path from 'node:path'
import { describe, expect, it } from 'vitest'

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

  it('enforces strict production Content-Security-Policy in vercel.json without localhost or missing object-src', () => {
    const vercelRaw = fs.readFileSync(
      path.join(adminRoot, 'vercel.json'),
      'utf8',
    )
    expect(vercelRaw).toContain("object-src 'none'")
    expect(vercelRaw).toContain("frame-ancestors 'none'")
    expect(vercelRaw).not.toContain('localhost')
    expect(vercelRaw).not.toContain('127.0.0.1')
  })
})
