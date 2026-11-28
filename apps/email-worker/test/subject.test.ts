import { describe, expect, it } from 'vitest';
import { decodeHeader, replySubject } from '../src/subject';

describe('decodeHeader', () => {
  it('decodes base64 UTF-8 encoded words', () => {
    // "Không đăng nhập được"
    expect(decodeHeader('=?UTF-8?B?S2jDtG5nIMSRxINuZyBuaOG6rXAgxJHGsOG7o2M=?=')).toBe(
      'Không đăng nhập được',
    );
  });

  it('decodes Q encoding and joins adjacent words', () => {
    expect(decodeHeader('=?utf-8?Q?L=E1=BB=97i_app?= =?utf-8?Q?_tr=C3=AAn_iPhone?=')).toBe(
      'Lỗi app trên iPhone',
    );
  });

  it('keeps plain text and mixed text', () => {
    expect(decodeHeader('Help =?UTF-8?Q?g=E1=BA=A5p?= now')).toBe('Help gấp now');
  });

  it('leaves a malformed word as it is', () => {
    expect(decodeHeader('=?UTF-8?B?***?=')).toBe('=?UTF-8?B?***?=');
  });
});

describe('replySubject', () => {
  it('prefixes Re:', () => {
    expect(replySubject('App bị treo')).toBe('Re: App bị treo');
  });

  it('does not double the prefix', () => {
    expect(replySubject('RE: App bị treo')).toBe('RE: App bị treo');
    expect(replySubject('Re : hi')).toBe('Re : hi');
  });

  it('falls back when the subject is empty', () => {
    expect(replySubject(null)).toBe('Re: Ourney');
    expect(replySubject('   ')).toBe('Re: Ourney');
  });

  it('strips line breaks and caps the length', () => {
    expect(replySubject('a\r\nBcc: x@y.z')).toBe('Re: a Bcc: x@y.z');
    expect(replySubject('x'.repeat(500)).length).toBe(204);
  });
});
