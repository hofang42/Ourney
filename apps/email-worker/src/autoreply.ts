import { replyHtml, replyText } from './copy';
import { extractAddress, skipReason } from './filter';
import { recordReply, recentlyReplied, repliesToday, senderKey } from './rate-limit';
import { replySubject } from './subject';

export interface Env {
  AUTOREPLY_KV: KVNamespace;
  FORWARD_TO: string;
  RESEND_API_KEY?: string;
  SUPPORT_ADDRESS: string;
  OWN_DOMAIN: string;
  REPLY_FROM: string;
  DAILY_REPLY_CAP: string;
}

/** The parts of ForwardableEmailMessage the auto-reply reads. */
export interface IncomingMessage {
  readonly from: string;
  readonly to: string;
  readonly headers: Headers;
}

export type Outcome = 'sent' | `skip:${string}`;

const RESEND_URL = 'https://api.resend.com/emails';
const MAX_REFERENCES = 20;

/** References for the reply: the original chain plus its Message-ID. */
export function threadHeaders(headers: Headers): Record<string, string> {
  const messageId = headers.get('message-id')?.trim();
  if (!messageId) return {};
  const chain = (headers.get('references') ?? '').match(/<[^<>\s]+>/g) ?? [];
  const references = [...chain, messageId].slice(-MAX_REFERENCES);
  return { 'In-Reply-To': messageId, References: references.join(' ') };
}

export async function handleAutoReply(
  message: IncomingMessage,
  env: Env,
  fetchImpl: typeof fetch = fetch,
  now: Date = new Date(),
): Promise<Outcome> {
  if (extractAddress(message.to) !== env.SUPPORT_ADDRESS.toLowerCase()) {
    return 'skip:not-support-address';
  }
  const reason = skipReason(message.from, message.headers, env.OWN_DOMAIN);
  if (reason) return `skip:${reason}`;
  if (!env.RESEND_API_KEY) return 'skip:no-api-key';

  // RFC 3834: reply to the envelope sender, which SPF checked.
  const recipient = extractAddress(message.from);
  if (await recentlyReplied(env.AUTOREPLY_KV, recipient)) {
    return 'skip:rate-limited';
  }
  const cap = Number.parseInt(env.DAILY_REPLY_CAP, 10);
  if (Number.isFinite(cap) && (await repliesToday(env.AUTOREPLY_KV, now)) >= cap) {
    return 'skip:daily-cap';
  }

  const idSource = message.headers.get('message-id') ?? `${recipient}:${now.toISOString()}`;
  const response = await fetchImpl(RESEND_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
      // A retried Worker run must not send the reply twice.
      'Idempotency-Key': (await senderKey(idSource)).replace('sender:', 'autoreply-'),
    },
    body: JSON.stringify({
      from: env.REPLY_FROM,
      to: [recipient],
      reply_to: env.SUPPORT_ADDRESS,
      subject: replySubject(message.headers.get('subject')),
      text: replyText,
      html: replyHtml,
      headers: {
        ...threadHeaders(message.headers),
        'Auto-Submitted': 'auto-replied',
        'X-Auto-Response-Suppress': 'All',
      },
    }),
  });
  if (!response.ok) {
    throw new Error(`Resend responded ${response.status}`);
  }

  await recordReply(env.AUTOREPLY_KV, recipient, now);
  return 'sent';
}
