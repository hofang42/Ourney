// One auto-reply per sender per 24h, plus a daily cap that keeps the shared
// Resend quota free for Auth OTP and moderation mail. KV is eventually
// consistent, so two messages from one sender within a minute can both get a
// reply; that is acceptable here.

export const SENDER_TTL_SECONDS = 24 * 60 * 60;
const COUNTER_TTL_SECONDS = 2 * 24 * 60 * 60;

/** KV key for a sender. Hashed so the store never holds raw addresses. */
export async function senderKey(address: string): Promise<string> {
  const bytes = new TextEncoder().encode(address.trim().toLowerCase());
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  const hex = [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `sender:${hex}`;
}

export function dayKey(now: Date): string {
  return `count:${now.toISOString().slice(0, 10)}`;
}

export async function recentlyReplied(
  kv: KVNamespace,
  address: string,
): Promise<boolean> {
  return (await kv.get(await senderKey(address))) !== null;
}

export async function repliesToday(kv: KVNamespace, now: Date): Promise<number> {
  const value = Number.parseInt((await kv.get(dayKey(now))) ?? '0', 10);
  return Number.isFinite(value) ? value : 0;
}

export async function recordReply(
  kv: KVNamespace,
  address: string,
  now: Date,
): Promise<void> {
  const count = await repliesToday(kv, now);
  await Promise.all([
    kv.put(await senderKey(address), '1', { expirationTtl: SENDER_TTL_SECONDS }),
    kv.put(dayKey(now), String(count + 1), {
      expirationTtl: COUNTER_TTL_SECONDS,
    }),
  ]);
}
