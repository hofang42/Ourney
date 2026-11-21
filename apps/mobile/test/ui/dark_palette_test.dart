import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/shared/color_utils.dart';
import 'package:ourney/ui/ui.dart';

double _c(Color a, Color b) => contrastRatio(a, b);

/// Dark-mode "warm lamp-lit paper" checks: a bg floor (no near-black), a text
/// ceiling (no glare), layering, readable accents and a mid-tone outline.
void _checkDark(String label, OurneyUi ui) {
  group('dark $label', () {
    test('bg is not near-black (luminance >= 0.0075)', () {
      expect(ui.bg.computeLuminance(), greaterThanOrEqualTo(0.0075));
    });

    test('ink on bg stays within 12..16:1 (no glare)', () {
      final r = _c(ui.ink, ui.bg);
      expect(r, greaterThanOrEqualTo(12));
      expect(r, lessThanOrEqualTo(16));
    });

    test('ink and muted read on every layer (4.5:1)', () {
      for (final layer in [ui.bg, ui.surface, ui.sheet, ui.fill]) {
        expect(_c(ui.ink, layer), greaterThanOrEqualTo(4.5));
        expect(_c(ui.inkMuted, layer), greaterThanOrEqualTo(4.5));
      }
      expect(_c(ui.ink, ui.fillSelected), greaterThanOrEqualTo(4.5));
      expect(_c(ui.inkMuted, ui.fillSelected), greaterThanOrEqualTo(4.5));
    });

    test('outline is a mid tone (>= 3:1) and the shadow sits below bg', () {
      expect(_c(ui.outline, ui.bg), greaterThanOrEqualTo(3.0));
      expect(_c(ui.outline, ui.surface), greaterThanOrEqualTo(3.0));
      expect(_c(ui.outline, ui.ink), lessThan(_c(ui.ink, ui.bg)));
      expect(
        ui.hardShadowColor.computeLuminance(),
        lessThan(ui.bg.computeLuminance()),
      );
      expect(ui.inputBorder, ui.outline);
      expect(ui.dockBorder, ui.outline);
    });

    test('layering exists: surface over bg >= 1.06, sheet above bg', () {
      expect(_c(ui.surface, ui.bg), greaterThanOrEqualTo(1.06));
      expect(
        ui.sheet.computeLuminance(),
        greaterThan(ui.bg.computeLuminance()),
      );
      expect(
        ui.sheet.computeLuminance(),
        lessThanOrEqualTo(ui.surface.computeLuminance()),
      );
    });

    test('outline reads on the sheet and fill layers (3:1)', () {
      expect(_c(ui.outline, ui.sheet), greaterThanOrEqualTo(3.0));
      expect(_c(ui.outline, ui.fill), greaterThanOrEqualTo(3.0));
    });

    test('surface lifts off bg (>= 1.08)', () {
      expect(_c(ui.surface, ui.bg), greaterThanOrEqualTo(1.08));
    });

    test('label on an accent fill reads (4.5:1)', () {
      expect(_c(ui.onAccent, ui.accent), greaterThanOrEqualTo(4.5));
    });

    test('accent and button label read', () {
      expect(_c(ui.accent, ui.bg), greaterThanOrEqualTo(4.5));
      expect(_c(ui.onBrand, ui.brand), greaterThanOrEqualTo(4.5));
    });
  });
}

void main() {
  _checkDark('shell', OurneyUi.dark);

  test('shell status colours read on bg and surface (4.5:1)', () {
    final ui = OurneyUi.dark;
    for (final c in [ui.danger, ui.warn, ui.success, ui.flame]) {
      expect(_c(c, ui.bg), greaterThanOrEqualTo(4.5));
      expect(_c(c, ui.surface), greaterThanOrEqualTo(4.5));
    }
    expect(_c(ui.onDanger, ui.danger), greaterThanOrEqualTo(4.5));
  });

  test(
    'light mode is unchanged: outline == hard shadow == ink, sheet == bg',
    () {
      final ui = OurneyUi.light;
      expect(ui.outline, ui.ink);
      expect(ui.hardShadowColor, ui.ink);
      expect(ui.sheet, ui.bg);
      for (final skin in uiSkins) {
        for (var i = 0; i < skin.variants.length; i++) {
          final a = skin.apply(OurneyUi.light, variantIndex: i);
          expect(a.outline, a.ink, reason: '${skin.id}/$i');
          expect(a.hardShadowColor, a.ink, reason: '${skin.id}/$i');
          expect(a.sheet, a.bg, reason: '${skin.id}/$i');
          expect(a.inputBorder, a.ink);
          expect(a.dockBorder, a.ink);
          expect(a.accent, skin.variant(i).accent);
        }
      }
    },
  );

  for (final skin in uiSkins) {
    for (var i = 0; i < skin.variants.length; i++) {
      final ui = skin.apply(OurneyUi.dark, variantIndex: i);
      _checkDark('${skin.id} v$i', ui);
    }
  }

  test('label on accent reads in every skin variant, both modes', () {
    for (final base in [OurneyUi.light, OurneyUi.dark]) {
      expect(_c(base.onAccent, base.accent), greaterThanOrEqualTo(4.5));
      for (final skin in uiSkins) {
        for (var i = 0; i < skin.variants.length; i++) {
          final a = skin.apply(base, variantIndex: i);
          expect(
            _c(a.onAccent, a.accent),
            greaterThanOrEqualTo(4.5),
            reason: '${skin.id} v$i ${base.brightness.name}',
          );
        }
      }
    }
  });

  test('onAccentFor keeps the ink when it reads, else white, else black', () {
    expect(
      OurneyUi.onAccentFor(const Color(0xFFFF8A3D)),
      const Color(0xFF1A1A1A),
    );
    expect(
      OurneyUi.onAccentFor(const Color(0xFF7A1F3D)),
      const Color(0xFFFFFFFF),
    );
  });

  test('dark minimal "Than" button uses the softened light fill', () {
    final ui = uiSkinById('minimal').apply(OurneyUi.dark, variantIndex: 1);
    expect(ui.brand, const Color(0xFFE4E4E7));
    expect(ui.onBrand, const Color(0xFF18181A));
  });
}
