import 'package:test/test.dart';
import 'package:ourney_core/ourney_core.dart';

void main() {
  test('caption cap trims whitespace at code point 140', () {
    final prefix = List.filled(139, '\u{1F600}').join();
    for (final whitespace in [' ', '\t', '\n']) {
      expect(normalizeCaption('$prefix${whitespace}tail'), prefix);
    }
  });

  test('caption read-out trims blanks and caps Unicode code points', () {
    expect(normalizeCaption(null), isNull);
    expect(normalizeCaption(''), isNull);
    expect(normalizeCaption(' \n\t '), isNull);
    expect(normalizeCaption('  Kỷ niệm ở Hội An 😀  '), 'Kỷ niệm ở Hội An 😀');
    for (final char in ['a', '😀', 'ệ']) {
      final atLimit = List.filled(140, char).join();
      expect(validateCaption(normalizeCaption(atLimit)), isNull);
      expect(normalizeCaption('$atLimit$char'), atLimit);
      expect(validateCaption(normalizeCaption('$atLimit$char')), isNull);
    }
    expect(normalizeCaption('e\u0302\u0323'), 'e\u0302\u0323');
  });
}
