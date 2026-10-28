import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/app/theme/tokens.dart';
import 'package:ourney/shared/color_utils.dart';
import 'package:ourney_core/ourney_core.dart';

double contrast(Color a, Color b) => contrastRatio(a, b);

void main() {
  const white = Color(0xFFFFFFFF);

  // V1.0: the brand coral carries ink labels, never white (5.41:1).
  test('ink on the brand >= 4.5:1, white on the brand is not allowed', () {
    final r = contrast(
      OurneyColors.light.onPrimary,
      OurneyColors.light.primary,
    );
    expect(r, greaterThanOrEqualTo(4.5), reason: 'ratio $r');
    expect(
      contrast(white, OurneyColors.light.primary),
      lessThan(4.5),
      reason: 'white text on #FF3B5C fails AA, so no widget may use it',
    );
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

  // F6: the six personas, light and dark, against WCAG AA.
  for (final skin in PersonaSkinId.values) {
    for (final brightness in Brightness.values) {
      final label = '${skin.name} ${brightness.name}';
      final t = OurneyPersonaTheme.forSkin(skin, brightness);

      test('$label: ink and muted ink read on every surface (4.5:1)', () {
        for (final (name, surface) in {
          'background': t.background,
          'surface': t.surface,
          'surfaceElevated': t.surfaceElevated,
        }.entries.map((e) => (e.key, e.value))) {
          expect(
            contrast(t.ink, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$label ink on $name',
          );
          expect(
            contrast(t.inkMuted, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$label inkMuted on $name',
          );
        }
      });

      test('$label: a label on each accent fill reads (4.5:1)', () {
        for (final (name, accent) in [
          ('primaryAccent', t.primaryAccent),
          ('secondaryAccent', t.secondaryAccent),
        ]) {
          expect(
            contrast(readableOn(accent), accent),
            greaterThanOrEqualTo(4.5),
            reason: '$label label on $name',
          );
        }
      });
    }
  }

  test('the neutral Ourney base meets AA in both modes', () {
    for (final brightness in Brightness.values) {
      final t = OurneyPersonaTheme.editorialNeutralBase(brightness);
      for (final surface in [t.background, t.surface, t.surfaceElevated]) {
        expect(contrast(t.ink, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(t.inkMuted, surface), greaterThanOrEqualTo(4.5));
      }
      expect(
        contrast(readableOn(t.primaryAccent), t.primaryAccent),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
