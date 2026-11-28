import type { Env } from '../src/autoreply';

export class FakeKV {
  readonly store = new Map<string, { value: string; ttl?: number }>();

  async get(key: string): Promise<string | null> {
    return this.store.get(key)?.value ?? null;
  }

  async put(key: string, value: string, options?: { expirationTtl?: number }) {
    this.store.set(key, { value, ttl: options?.expirationTtl });
  }
}

export const AUTH_PASS =
  'mx.cloudflare.net; dkim=pass header.d=gmail.com; dmarc=pass header.from=gmail.com; spf=pass smtp.mailfrom=lan@gmail.com';

// Header values are ASCII on the wire; non-ASCII subjects arrive RFC 2047
// encoded, as in the subject tests.
export function humanHeaders(extra: Record<string, string> = {}): Headers {
  return new Headers({
    From: 'Lan Nguyen <lan@gmail.com>',
    To: 'support@ourney.tech',
    Subject: 'Khong dang nhap duoc',
    'Message-ID': '<abc123@mail.gmail.com>',
    'Authentication-Results': AUTH_PASS,
    ...extra,
  });
}

export function makeEnv(kv = new FakeKV(), overrides: Partial<Env> = {}): Env {
  return {
    AUTOREPLY_KV: kv as unknown as KVNamespace,
    FORWARD_TO: 'owner-inbox@example.com',
    RESEND_API_KEY: 're_test_key',
    SUPPORT_ADDRESS: 'support@ourney.tech',
    OWN_DOMAIN: 'ourney.tech',
    REPLY_FROM: 'Ourney Support <support@ourney.tech>',
    DAILY_REPLY_CAP: '30',
    ...overrides,
  };
}

export function okFetch() {
  const calls: { url: string; init: RequestInit }[] = [];
  const impl = (async (url: string, init: RequestInit) => {
    calls.push({ url, init });
    return new Response('{"id":"x"}', { status: 200 });
  }) as unknown as typeof fetch;
  return { impl, calls };
}
