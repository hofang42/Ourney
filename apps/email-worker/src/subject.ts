// Builds the reply subject from the raw Subject header. Vietnamese subjects
// arrive as RFC 2047 encoded words (=?UTF-8?B?...?=), so decode them first or
// the reply would read "Re: =?UTF-8?B?...".

const ENCODED_WORD = /=\?([^?]+)\?([bBqQ])\?([^?]*)\?=/g;
const MAX_SUBJECT_LENGTH = 200;
const FALLBACK_SUBJECT = 'Ourney';

function decodeBytes(charset: string, bytes: Uint8Array): string {
  try {
    return new TextDecoder(charset.toLowerCase()).decode(bytes);
  } catch {
    return new TextDecoder('utf-8').decode(bytes);
  }
}

function decodeWord(charset: string, encoding: string, text: string): string {
  if (encoding.toUpperCase() === 'B') {
    const binary = atob(text);
    const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0));
    return decodeBytes(charset, bytes);
  }
  const qp = text.replace(/_/g, ' ');
  const bytes: number[] = [];
  for (let i = 0; i < qp.length; i++) {
    const hex = qp.slice(i + 1, i + 3);
    if (qp[i] === '=' && /^[0-9a-f]{2}$/i.test(hex)) {
      bytes.push(Number.parseInt(hex, 16));
      i += 2;
    } else {
      bytes.push(qp.charCodeAt(i));
    }
  }
  return decodeBytes(charset, Uint8Array.from(bytes));
}

export function decodeHeader(value: string): string {
  // Whitespace between two adjacent encoded words is not part of the text.
  const joined = value.replace(/(\?=)\s+(=\?)/g, '$1$2');
  return joined.replace(ENCODED_WORD, (match, charset, encoding, text) => {
    try {
      return decodeWord(charset, encoding, text);
    } catch {
      return match;
    }
  });
}

export function replySubject(rawSubject: string | null): string {
  const subject = decodeHeader(rawSubject ?? '')
    .replace(/[\r\n]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, MAX_SUBJECT_LENGTH);
  if (!subject) return `Re: ${FALLBACK_SUBJECT}`;
  return /^re\s*:/i.test(subject) ? subject : `Re: ${subject}`;
}
