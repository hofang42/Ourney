import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/theme/tokens.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const white = Color(0xFFFFFFFF);

  test('white on light primaryDeep >= 4.5:1', () {
    final r = contrast(white, OurneyColors.light.primaryDeep);
    expect(r, greaterThanOrEqualTo(4.5), reason: 'ratio $r');
  });

  test('white on light primary only reaches large-text 3:1', () {
    final r = contrast(white, OurneyColors.light.primary);
    expect(r, greaterThanOrEqualTo(3.0), reason: 'ratio $r');
  });

  for (final entry in {
    'light': OurneyColors.light,
    'dark': OurneyColors.dark,
  }.entries) {
    final c = entry.value;
    test('${entry.key}: text pairs meet 4.5:1', () {
      expect(
        contrast(c.onPrimaryDeep, c.primaryDeep),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(c.ink, c.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(c.ink, c.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(c.inkMuted, c.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(c.inkMuted, c.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(c.primaryDeep, c.bg), greaterThanOrEqualTo(3.0));
    });

    test('${entry.key}: onPrimary on primary >= 3:1 (large bold text)', () {
      expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(3.0));
    });
  }
}
