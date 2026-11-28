import { describe, expect, it } from 'vitest';
import { extractAddress, skipReason } from '../src/filter';
import { humanHeaders } from './helpers';

const OWN = 'ourney.tech';

describe('extractAddress', () => {
  it('reads the address inside angle brackets', () => {
    expect(extractAddress('"Lan" <Lan@Gmail.com>')).toBe('lan@gmail.com');
  });
  it('accepts a bare address and an empty value', () => {
    expect(extractAddress(' lan@gmail.com ')).toBe('lan@gmail.com');
    expect(extractAddress(null)).toBe('');
  });
});

describe('skipReason', () => {
  it('allows a normal authenticated person', () => {
    expect(skipReason('lan@gmail.com', humanHeaders(), OWN)).toBeNull();
  });

  it.each(['', '<>', 'not-an-address'])('skips a null sender %j', (from) => {
    expect(skipReason(from, humanHeaders(), OWN)).toBe('null-sender');
  });

  it.each([
    'MAILER-DAEMON@mx.google.com',
    'postmaster@outlook.com',
    'bounce@shop.vn',
    'bounces+123@mail.shop.vn',
    'no-reply@accounts.google.com',
    'noreply@github.com',
    'no_reply@x.com',
    'donotreply@bank.vn',
    'do-not-reply@bank.vn',
    'noreply-dmarc-support@google.com',
  ])('skips system sender %s', (from) => {
    expect(skipReason(from, humanHeaders(), OWN)).toBe('system-sender');
  });

  it('skips a no-reply header From even when the envelope looks human', () => {
    const headers = humanHeaders({ From: 'Shop <noreply@shop.vn>' });
    expect(skipReason('lan@gmail.com', headers, OWN)).toBe('system-sender');
  });

  it.each([
    'moderation@ourney.tech',
    'hello@ourney.tech',
    'bounce-x@send.ourney.tech',
  ])('never replies to our own domain: %s', (from) => {
    const headers = humanHeaders({ From: `Ourney <${from}>` });
    expect(skipReason(from, headers, OWN)).toMatch(/own-domain|system-sender/);
  });

  it('skips own-domain header From behind a foreign envelope', () => {
    const headers = humanHeaders({ From: 'Ourney <moderation@ourney.tech>' });
    expect(skipReason('x@resend.dev', headers, OWN)).toBe('own-domain');
  });

  it('does not treat a lookalike domain as ours', () => {
    const headers = humanHeaders({ From: 'a@notourney.tech' });
    expect(skipReason('a@notourney.tech', headers, OWN)).toBeNull();
  });

  it.each(['auto-replied', 'auto-generated', 'auto-notified'])(
    'skips Auto-Submitted: %s',
    (value) => {
      const headers = humanHeaders({ 'Auto-Submitted': value });
      expect(skipReason('lan@gmail.com', headers, OWN)).toBe('auto-submitted');
    },
  );

  it('allows Auto-Submitted: no', () => {
    const headers = humanHeaders({ 'Auto-Submitted': 'no' });
    expect(skipReason('lan@gmail.com', headers, OWN)).toBeNull();
  });

  it.each(['bulk', 'list', 'junk', 'Bulk '])('skips Precedence: %s', (value) => {
    const headers = humanHeaders({ Precedence: value });
    expect(skipReason('lan@gmail.com', headers, OWN)).toBe('precedence');
  });

  it.each(['List-Id', 'List-Unsubscribe'])('skips mailing lists (%s)', (name) => {
    const headers = humanHeaders({ [name]: '<news.shop.vn>' });
    expect(skipReason('lan@gmail.com', headers, OWN)).toBe('mailing-list');
  });

  it.each([
    ['X-Autoreply', 'yes'],
    ['X-Autorespond', 'Out of office'],
    ['X-Auto-Response-Suppress', 'All'],
    ['X-Auto-Response-Suppress', 'DR, OOF, AutoReply'],
  ])('skips %s: %s', (name, value) => {
    const headers = humanHeaders({ [name]: value });
    expect(skipReason('lan@gmail.com', headers, OWN)).toBe('autoreply-header');
  });

  it('skips delivery status reports', () => {
    const headers = humanHeaders({
      'Content-Type': 'multipart/report; report-type=delivery-status; boundary="b"',
    });
    expect(skipReason('lan@gmail.com', headers, OWN)).toBe('bounce-report');
  });

  it('skips mail that fails SPF and DMARC (forged sender)', () => {
    const headers = humanHeaders({
      'Authentication-Results':
        'mx.cloudflare.net; dkim=none; dmarc=fail header.from=gmail.com; spf=softfail',
    });
    expect(skipReason('lan@gmail.com', headers, OWN)).toBe('unauthenticated');
  });

  it('skips mail without Authentication-Results', () => {
    const headers = humanHeaders();
    headers.delete('Authentication-Results');
    expect(skipReason('lan@gmail.com', headers, OWN)).toBe('unauthenticated');
  });

  it('accepts SPF pass without DMARC (small domains)', () => {
    const headers = humanHeaders({
      'Authentication-Results': 'mx.cloudflare.net; dmarc=none; spf=pass smtp.mailfrom=a@shop.vn',
    });
    expect(skipReason('a@shop.vn', headers, OWN)).toBeNull();
  });
});
