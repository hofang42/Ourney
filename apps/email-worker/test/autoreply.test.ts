import { describe, expect, it } from 'vitest';
import { handleAutoReply, threadHeaders } from '../src/autoreply';
import { dayKey, senderKey, SENDER_TTL_SECONDS } from '../src/rate-limit';
import { FakeKV, humanHeaders, makeEnv, okFetch } from './helpers';

const NOW = new Date('2026-11-28T10:00:00Z');

function message(headers = humanHeaders(), from = 'lan@gmail.com') {
  return { from, to: 'support@ourney.tech', headers };
}

describe('threadHeaders', () => {
  it('threads on Message-ID and keeps the chain', () => {
    const headers = humanHeaders({ References: '<a@x> <b@x>' });
    expect(threadHeaders(headers)).toEqual({
      'In-Reply-To': '<abc123@mail.gmail.com>',
      References: '<a@x> <b@x> <abc123@mail.gmail.com>',
    });
  });

  it('caps long reference chains', () => {
    const chain = Array.from({ length: 150 }, (_, i) => `<m${i}@x>`).join(' ');
    const refs = threadHeaders(humanHeaders({ References: chain })).References;
    expect(refs.split(' ')).toHaveLength(20);
    expect(refs.endsWith('<abc123@mail.gmail.com>')).toBe(true);
  });

  it('returns nothing without a Message-ID', () => {
    const headers = humanHeaders();
    headers.delete('Message-ID');
    expect(threadHeaders(headers)).toEqual({});
  });
});

describe('handleAutoReply', () => {
  it('sends one reply from Ourney Support with threading', async () => {
    const kv = new FakeKV();
    const { impl, calls } = okFetch();
    const encoded = humanHeaders({
      Subject: '=?UTF-8?B?S2jDtG5nIMSRxINuZyBuaOG6rXAgxJHGsOG7o2M=?=',
    });

    expect(await handleAutoReply(message(encoded), makeEnv(kv), impl, NOW)).toBe('sent');

    expect(calls).toHaveLength(1);
    expect(calls[0].url).toBe('https://api.resend.com/emails');
    const body = JSON.parse(String(calls[0].init.body));
    expect(body.from).toBe('Ourney Support <support@ourney.tech>');
    expect(body.to).toEqual(['lan@gmail.com']);
    expect(body.reply_to).toBe('support@ourney.tech');
    expect(body.subject).toBe('Re: Không đăng nhập được');
    expect(body.headers['In-Reply-To']).toBe('<abc123@mail.gmail.com>');
    expect(body.headers['Auto-Submitted']).toBe('auto-replied');
    expect(body.text.indexOf('Chào bạn')).toBeLessThan(body.text.indexOf('Hi,'));
    expect(JSON.stringify(body)).not.toContain('owner-inbox@example.com');

    const stored = kv.store.get(await senderKey('lan@gmail.com'));
    expect(stored?.ttl).toBe(SENDER_TTL_SECONDS);
    expect(kv.store.get(dayKey(NOW))?.value).toBe('1');
    expect([...kv.store.keys()].join()).not.toContain('lan@gmail.com');
  });

  it('replies at most once per sender in 24h, case-insensitively', async () => {
    const kv = new FakeKV();
    const { impl, calls } = okFetch();
    const env = makeEnv(kv);

    await handleAutoReply(message(), env, impl, NOW);
    const again = await handleAutoReply(message(humanHeaders(), 'LAN@gmail.com'), env, impl, NOW);

    expect(again).toBe('skip:rate-limited');
    expect(calls).toHaveLength(1);
  });

  it('stops at the daily cap', async () => {
    const kv = new FakeKV();
    await kv.put(dayKey(NOW), '30');
    const { impl, calls } = okFetch();

    expect(await handleAutoReply(message(), makeEnv(kv), impl, NOW)).toBe('skip:daily-cap');
    expect(calls).toHaveLength(0);
  });

  it('throws and records nothing when Resend fails', async () => {
    const kv = new FakeKV();
    const failing = (async () => new Response('quota', { status: 429 })) as unknown as typeof fetch;

    await expect(handleAutoReply(message(), makeEnv(kv), failing, NOW)).rejects.toThrow('429');
    expect(kv.store.size).toBe(0);
  });

  it('skips filtered mail without calling Resend', async () => {
    const { impl, calls } = okFetch();
    const headers = humanHeaders({ From: 'Ourney <moderation@ourney.tech>' });

    const outcome = await handleAutoReply(
      message(headers, 'moderation@ourney.tech'),
      makeEnv(),
      impl,
      NOW,
    );
    expect(outcome).toBe('skip:own-domain');
    expect(calls).toHaveLength(0);
  });

  it('only answers mail addressed to the support address', async () => {
    const { impl, calls } = okFetch();
    const msg = { ...message(), to: 'hello@ourney.tech' };
    expect(await handleAutoReply(msg, makeEnv(), impl, NOW)).toBe('skip:not-support-address');
    expect(calls).toHaveLength(0);
  });

  it('skips when the Resend key is not set', async () => {
    const { impl } = okFetch();
    const env = makeEnv(new FakeKV(), { RESEND_API_KEY: undefined });
    expect(await handleAutoReply(message(), env, impl, NOW)).toBe('skip:no-api-key');
  });
});
