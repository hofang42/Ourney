export interface WaitlistExportRow {
  email: string
  lang: string
  platforms: string[] | string
  source: string | null
  created_at: string
  confirmation_sent_at: string | null
  registered_in_app: boolean
}

const FORMULA_PREFIX_RE = /^[\t\r\n ]*[=+\-@|]|^[\t\r\n]/

export function neutralizeCsvFormula(raw: string): string {
  if (raw.length === 0) return ''
  if (FORMULA_PREFIX_RE.test(raw)) {
    return `'${raw}`
  }
  return raw
}

export function escapeCsvCell(
  value: string | number | boolean | null | undefined,
): string {
  if (value === null || value === undefined) return ''
  const raw = neutralizeCsvFormula(String(value))
  if (
    raw.includes('"') ||
    raw.includes(',') ||
    raw.includes('\n') ||
    raw.includes('\r')
  ) {
    return `"${raw.replace(/"/g, '""')}"`
  }
  return raw
}

export function buildWaitlistCsv(rows: WaitlistExportRow[]): string {
  const header = [
    'email',
    'lang',
    'platforms',
    'source',
    'created_at',
    'confirmation_sent_at',
    'registered_in_app',
  ].join(',')

  const lines = rows.map((row) => {
    const platformsStr = Array.isArray(row.platforms)
      ? row.platforms.join('|')
      : String(row.platforms ?? '')
    return [
      escapeCsvCell(row.email),
      escapeCsvCell(row.lang),
      escapeCsvCell(platformsStr),
      escapeCsvCell(row.source ?? ''),
      escapeCsvCell(row.created_at),
      escapeCsvCell(row.confirmation_sent_at ?? ''),
      escapeCsvCell(row.registered_in_app ? 'true' : 'false'),
    ].join(',')
  })

  return `\uFEFF${[header, ...lines].join('\r\n')}\r\n`
}

function parseCsvRows(csvText: string): string[][] {
  const stripped = csvText.startsWith('\uFEFF') ? csvText.slice(1) : csvText
  const rows: string[][] = []
  let currentRow: string[] = []
  let currentCell = ''
  let inQuotes = false

  for (let i = 0; i < stripped.length; i++) {
    const ch = stripped[i]
    if (inQuotes) {
      if (ch === '"') {
        if (stripped[i + 1] === '"') {
          currentCell += '"'
          i += 1
        } else {
          inQuotes = false
        }
      } else {
        currentCell += ch
      }
    } else if (ch === '"') {
      inQuotes = true
    } else if (ch === ',') {
      currentRow.push(currentCell)
      currentCell = ''
    } else if (ch === '\r') {
      if (stripped[i + 1] === '\n') {
        i += 1
      }
      currentRow.push(currentCell)
      rows.push(currentRow)
      currentRow = []
      currentCell = ''
    } else if (ch === '\n') {
      currentRow.push(currentCell)
      rows.push(currentRow)
      currentRow = []
      currentCell = ''
    } else {
      currentCell += ch
    }
  }

  if (currentCell.length > 0 || currentRow.length > 0) {
    currentRow.push(currentCell)
    rows.push(currentRow)
  }

  return rows
}

export function sanitizeRawCsvString(rawCsv: string): string {
  const parsed = parseCsvRows(rawCsv)
  if (parsed.length === 0) return '\uFEFF'
  const lines = parsed.map((row, rowIdx) =>
    row
      .map((cell) => {
        if (rowIdx === 0) {
          return escapeCsvCell(cell.trim())
        }
        return escapeCsvCell(cell)
      })
      .join(','),
  )
  return `\uFEFF${lines.join('\r\n')}\r\n`
}

export function triggerCsvDownload(csvWithBom: string, filename: string): void {
  const blob = new Blob([csvWithBom], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.setAttribute('download', filename)
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}
