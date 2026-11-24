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

describe('CLAUDE.md Brand Guardrails (Zero Stock Icon Packs & Zero Emoji)', () => {
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
      expect(
        emojiRegex.test(content),
        `Emoji found in ${rel}`,
      ).toBe(false)
      expect(
        forbiddenSymbolsRegex.test(content),
        `Forbidden Unicode symbol glyph found in ${rel}`,
      ).toBe(false)
    }
  })
})
