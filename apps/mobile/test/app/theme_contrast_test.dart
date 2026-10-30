import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/shared/color_utils.dart';
import 'package:ourney/ui/ui.dart';

double contrast(Color a, Color b) => contrastRatio(a, b);

void main() {
  const white = Color(0xFFFFFFFF);

  // V1.0: the brand coral carries ink labels, never white.
  test('ink on the brand >= 4.5:1, white on the brand is not allowed', () {
    final ui = OurneyUi.light;
    expect(contrast(ui.onBrand, ui.brand), greaterThanOrEqualTo(4.5));
    expect(contrast(white, ui.brand), lessThan(4.5));
  });

  for (final entry in {
    'light': OurneyUi.light,
    'dark': OurneyUi.dark,
  }.entries) {
    final ui = entry.value;
    test('${entry.key}: text pairs meet 4.5:1', () {
      expect(contrast(ui.ink, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.ink, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.inkMuted, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.inkMuted, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.onBrand, ui.brand), greaterThanOrEqualTo(4.5));
    });

    test('${entry.key}: danger reads on the background (3:1)', () {
      expect(contrast(ui.danger, ui.bg), greaterThanOrEqualTo(3.0));
    });
  }

  // The journey styles: label on the accent fill, ink on the paper.
  for (final style in uiJourneyStyles) {
    test('${style.name}: onAccent on accent and ink on paper read', () {
      expect(contrast(style.onAccent, style.accent), greaterThanOrEqualTo(4.5));
      expect(contrast(style.ink, style.paper), greaterThanOrEqualTo(4.5));
    });
  }
}
