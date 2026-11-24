const CF_BEACON_SRC = 'https://static.cloudflareinsights.com/beacon.min.js'
const CF_BEACON_SELECTOR = 'script[data-cf-beacon]'

/**
 * Optionally injects the Cloudflare Web Analytics beacon at startup when
 * `VITE_CF_BEACON_TOKEN` is configured at build time.
 */
export function injectCloudflareBeacon(
  rawToken: unknown = import.meta.env.VITE_CF_BEACON_TOKEN,
  doc: Document = document,
): HTMLScriptElement | null {
  const token = typeof rawToken === 'string' ? rawToken.trim() : ''
  if (!token) {
    return null
  }

  const existing = doc.querySelector<HTMLScriptElement>(CF_BEACON_SELECTOR)
  if (existing) {
    return existing
  }

  const script = doc.createElement('script')
  script.defer = true
  script.src = CF_BEACON_SRC
  script.setAttribute('data-cf-beacon', JSON.stringify({ token }))
  ;(doc.head ?? doc.body ?? doc.documentElement).appendChild(script)
  return script
}
