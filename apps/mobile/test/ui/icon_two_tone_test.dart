import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';

void main() {
  for (final ui in [OurneyUi.light, OurneyUi.dark]) {
    test('sticker fill never matches the ink outline (dark=${ui.isDark})', () {
      for (final name in ourneyIconNames) {
        final fill = ourneyIconColor(name);
        expect(
          OurneyIconPainter.collapses(fill, ui.ink),
          isFalse,
          reason: '$name fill $fill collapses into ink ${ui.ink}',
        );
      }
    });
  }

  test('a fill equal or close to the ink is detected as a blob', () {
    expect(
      OurneyIconPainter.collapses(OurneyUi.light.ink, OurneyUi.light.ink),
      isTrue,
    );
    expect(
      OurneyIconPainter.collapses(const Color(0xFFFFFFFF), OurneyUi.dark.ink),
      isTrue,
    );
    expect(
      OurneyIconPainter.collapses(const Color(0xFFFF9F1C), OurneyUi.light.ink),
      isFalse,
    );
  });
}
