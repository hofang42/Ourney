import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/social/ui/chat_screen.dart';

TextEditingValue v(String t, {TextRange composing = TextRange.empty}) =>
    TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
      composing: composing,
    );

void main() {
  const f = ChatLengthFormatter(10);

  test('within the limit nothing changes', () {
    expect(f.formatEditUpdate(v('abc'), v('abcd')).text, 'abcd');
  });

  test('a typed character over the limit keeps the old value', () {
    final old = v('0123456789');
    final out = f.formatEditUpdate(old, v('01234x56789'));
    expect(out, old);
  });

  test('a paste is truncated to the limit', () {
    final out = f.formatEditUpdate(v('ab'), v('ab0123456789'));
    expect(out.text, 'ab01234567');
  });

  test('code points count, not UTF-16 units', () {
    // 10 emoji = 10 code points (20 UTF-16 units): allowed.
    final ok = '😀' * 10;
    expect(f.formatEditUpdate(v(''), v(ok)).text, ok);
    final out = f.formatEditUpdate(v(ok), v('$ok😀'));
    expect(out.text, ok);
  });

  test('an active IME composition is never cut (Telex)', () {
    final old = v('012345678a');
    const composing = TextRange(start: 9, end: 11);
    final out = f.formatEditUpdate(old, v('012345678ab', composing: composing));
    expect(out.text, '012345678ab');
    expect(out.composing, composing);
  });

  test('N5 deletions are allowed while over the limit', () {
    final over = v('0123456789ab');
    final out = f.formatEditUpdate(over, v('0123456789a'));
    expect(out.text, '0123456789a');
  });

  test('N5 a composition that commits over the limit is trimmed', () {
    final old = v('012345678a', composing: const TextRange(start: 9, end: 10));
    final out = f.formatEditUpdate(old, v('012345678áb'));
    expect(out.text, '012345678á');
  });

  test('R4 a composition that commits over the limit is trimmed even when the net length did not grow', () {
    // Already over the limit (12) with an active composition of 1 char; the
    // commit swaps it for another char: added == 0, still over.
    final old = v(
      '0123456789ab',
      composing: const TextRange(start: 11, end: 12),
    );
    final out = f.formatEditUpdate(old, v('0123456789aá'));
    expect(out.text, '0123456789');
  });

  test(
    'R4 without a composition a same-length edit over the limit is kept',
    () {
      final old = v('0123456789ab');
      final out = f.formatEditUpdate(old, v('0123456789ac'));
      expect(out.text, '0123456789ac');
    },
  );
}
