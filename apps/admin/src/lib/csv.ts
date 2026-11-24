export interface WaitlistExportRow {
  email: string
  lang: string
  platforms: string[] | string
  source: string
  created_at: string
  confirmation_sent_at: string | null
  registered_in_app: boolean
}

function escapeCsvCell(value: string | number | boolean | null | undefined): string {
  if (value === null || value === undefined) return ''
  const raw = String(value)
  if (raw.includes('"') || raw.includes(',') || raw.includes('\n') || raw.includes('\r')) {
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
      escapeCsvCell(row.source),
      escapeCsvCell(row.created_at),
      escapeCsvCell(row.confirmation_sent_at ?? ''),
      escapeCsvCell(row.registered_in_app ? 'true' : 'false'),
    ].join(',')
  })

  return `\uFEFF${[header, ...lines].join('\r\n')}\r\n`
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
