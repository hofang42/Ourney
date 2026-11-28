// Decides whether an incoming message may get an auto-reply (RFC 3834).
// Returns the reason to skip, or null when replying is allowed.

export type SkipReason =
  | 'null-sender'
  | 'system-sender'
  | 'own-domain'
  | 'auto-submitted'
  | 'precedence'
  | 'mailing-list'
  | 'autoreply-header'
  | 'bounce-report'
  | 'unauthenticated';

// mailer-daemon, postmaster, bounce(s), no-reply, noreply+tag, do-not-reply...
const SYSTEM_LOCAL_PART =
  /^(mailer-daemon|postmaster|bounces?|(no|do[-_.]?not)[-_.]?reply)([-+._].*)?$/i;

/** Extracts the bare address from a header such as `"Lan" <lan@x.vn>`. */
export function extractAddress(value: string | null): string {
  if (!value) return '';
  const angle = value.match(/<([^<>]*)>/);
  return (angle ? angle[1] : value).trim().toLowerCase();
}

function splitAddress(address: string): { local: string; domain: string } {
  const at = address.lastIndexOf('@');
  if (at < 0) return { local: address, domain: '' };
  return { local: address.slice(0, at), domain: address.slice(at + 1) };
}

function isOwnDomain(domain: string, ownDomain: string): boolean {
  const own = ownDomain.toLowerCase();
  return domain === own || domain.endsWith(`.${own}`);
}

/**
 * Cloudflare prepends its own Authentication-Results header before the
 * Worker runs. A pass on SPF (the envelope sender we reply to) or DMARC
 * means the address was not forged, so the reply is not backscatter.
 */
export function isAuthenticated(headers: Headers): boolean {
  const results = headers.get('authentication-results') ?? '';
  return /\b(spf|dmarc)=pass\b/i.test(results);
}

export function skipReason(
  envelopeFrom: string,
  headers: Headers,
  ownDomain: string,
): SkipReason | null {
  const envelope = extractAddress(envelopeFrom);
  if (!envelope || envelope === '<>' || !envelope.includes('@')) {
    return 'null-sender';
  }

  const senders = [envelope, extractAddress(headers.get('from'))].filter(
    (a) => a.includes('@'),
  );
  for (const address of senders) {
    const { local, domain } = splitAddress(address);
    if (SYSTEM_LOCAL_PART.test(local)) return 'system-sender';
    if (isOwnDomain(domain, ownDomain)) return 'own-domain';
  }

  const autoSubmitted = headers.get('auto-submitted')?.trim().toLowerCase();
  if (autoSubmitted && autoSubmitted !== 'no') return 'auto-submitted';

  const precedence = headers.get('precedence')?.trim().toLowerCase() ?? '';
  if (/^(bulk|list|junk|auto_reply)$/.test(precedence)) return 'precedence';

  if (headers.has('list-id') || headers.has('list-unsubscribe')) {
    return 'mailing-list';
  }

  if (headers.has('x-autoreply') || headers.has('x-autorespond')) {
    return 'autoreply-header';
  }
  const suppress = headers.get('x-auto-response-suppress') ?? '';
  if (/\b(all|oof|autoreply)\b/i.test(suppress)) return 'autoreply-header';

  const contentType = headers.get('content-type') ?? '';
  if (/^\s*multipart\/report\b/i.test(contentType)) return 'bounce-report';

  if (!isAuthenticated(headers)) return 'unauthenticated';

  return null;
}
