import 'package:test/test.dart';
import 'package:ourney_core/ourney_core.dart';

void main() {
  test('caption read-out trims blanks without clipping code points', () {
    expect(normalizeCaption(null), isNull);
    expect(normalizeCaption(''), isNull);
    expect(normalizeCaption(' \n\t '), isNull);
    expect(normalizeCaption('  Kỷ niệm ở Hội An 😀  '), 'Kỷ niệm ở Hội An 😀');
    for (final char in ['a', '😀', 'ệ']) {
      final atLimit = List.filled(140, char).join();
      expect(validateCaption(normalizeCaption(atLimit)), isNull);
      expect(
        validateCaption(normalizeCaption('$atLimit$char')),
        CaptionError.tooLong,
      );
    }
    expect(normalizeCaption('e\u0302\u0323'), 'e\u0302\u0323');
  });
}
