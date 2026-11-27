import 'package:flutter/material.dart';
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

  test('B6 token discipline: Tím, Cam, flexer text, dark thumb, no pink buttons on quiet/flexer', () {
    expect(OurneyUi.light.brandText, const Color(0xFFB4470F));
    expect(OurneyUi.dark.brandText, const Color(0xFFFFC39B));
    expect(OurneyUi.dark.switchThumb, const Color(0xFF1B1916));

    final squadTimLight = uiSkinById('squad').apply(OurneyUi.light, variantIndex: 1);
    final squadTimDark = uiSkinById('squad').apply(OurneyUi.dark, variantIndex: 1);
    expect(squadTimLight.accent, const Color(0xFFA13CC9));
    expect(squadTimDark.accent, const Color(0xFFC77DE0));
    expect(squadTimLight.brand, const Color(0xFFFF9F1C));
    expect(squadTimDark.brand, const Color(0xFFFF9F1C));

    final minimalCamLight = uiSkinById('minimal').apply(OurneyUi.light, variantIndex: 0);
    final minimalCamDark = uiSkinById('minimal').apply(OurneyUi.dark, variantIndex: 0);
    expect(minimalCamLight.accent, const Color(0xFFEA580C));
    expect(minimalCamLight.brand, const Color(0xFFEA580C));
    expect(minimalCamLight.accentText, const Color(0xFFB4470F));
    expect(minimalCamDark.accentText, const Color(0xFFFFC39B));

    final flexerLight = uiSkinById('flexer').apply(OurneyUi.light, variantIndex: 0);
    final flexerDark = uiSkinById('flexer').apply(OurneyUi.dark, variantIndex: 0);
    expect(flexerLight.accent, const Color(0xFF3DE88C));
    expect(flexerLight.accentText, const Color(0xFF047857));
    expect(flexerDark.accentText, const Color(0xFF3DE88C));
    expect(flexerLight.brand, isNot(const Color(0xFFFF4D6D)));

    final quietLight = uiSkinById('quiet').apply(OurneyUi.light, variantIndex: 0);
    expect(quietLight.brand, isNot(const Color(0xFFFF4D6D)));
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
      expect(contrast(ui.inkSoft, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.inkSoft, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.brandText, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.brandText, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.accentText, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.accentText, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.onBrand, ui.brand), greaterThanOrEqualTo(4.5));
    });

    test('${entry.key}: switch thumbs meet 3:1 on active and inactive tracks', () {
      expect(contrast(ui.switchThumb, ui.brand), greaterThanOrEqualTo(3.0));
      expect(contrast(ui.ink, ui.fill), greaterThanOrEqualTo(3.0));
    });

    test('${entry.key}: danger reads on the background (3:1)', () {
      expect(contrast(ui.danger, ui.bg), greaterThanOrEqualTo(3.0));
    });

    test('${entry.key}: warn and timeCue meet 4.5:1 on bg and surface', () {
      expect(contrast(ui.warn, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.warn, ui.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.timeCue, ui.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ui.timeCue, ui.surface), greaterThanOrEqualTo(4.5));
    });
  }

  // All 18 skin variants (6 skins × 3 variants) × light/dark:
  // text >= 4.5:1, switch thumbs >= 3:1.
  for (final skin in uiSkins) {
    for (var i = 0; i < skin.variants.length; i++) {
      final variantName = skin.variant(i).name;
      for (final base in [OurneyUi.light, OurneyUi.dark]) {
        final mode = base.brightness.name;
        final ui = skin.apply(base, variantIndex: i);

        test(
          '${skin.id}[$i] ($variantName) $mode: text roles >= 4.5:1 and switch thumbs >= 3:1',
          () {
            for (final layer in [ui.bg, ui.surface]) {
              expect(
                contrast(ui.ink, layer),
                greaterThanOrEqualTo(4.5),
                reason: '${skin.id}[$i] $mode ink on $layer',
              );
              expect(
                contrast(ui.inkMuted, layer),
                greaterThanOrEqualTo(4.5),
                reason: '${skin.id}[$i] $mode inkMuted on $layer',
              );
              expect(
                contrast(ui.inkSoft, layer),
                greaterThanOrEqualTo(4.5),
                reason: '${skin.id}[$i] $mode inkSoft on $layer',
              );
              expect(
                contrast(ui.accentText, layer),
                greaterThanOrEqualTo(4.5),
                reason: '${skin.id}[$i] $mode accentText on $layer',
              );
              expect(
                contrast(ui.brandText, layer),
                greaterThanOrEqualTo(4.5),
                reason: '${skin.id}[$i] $mode brandText on $layer',
              );
            }

            // Labels on button and accent fills.
            expect(
              contrast(ui.onBrand, ui.brand),
              greaterThanOrEqualTo(4.5),
              reason: '${skin.id}[$i] $mode onBrand on brand',
            );
            expect(
              contrast(ui.onAccent, ui.accent),
              greaterThanOrEqualTo(4.5),
              reason: '${skin.id}[$i] $mode onAccent on accent',
            );

            // Switch thumbs (active on brand track, inactive on fill track).
            expect(
              contrast(ui.switchThumb, ui.brand),
              greaterThanOrEqualTo(3.0),
              reason: '${skin.id}[$i] $mode active switchThumb on brand',
            );
            expect(
              contrast(ui.ink, ui.fill),
              greaterThanOrEqualTo(3.0),
              reason: '${skin.id}[$i] $mode inactive switch thumb on fill',
            );

            final themeSwitch = OurneyTheme.fromUi(ui).switchTheme;
            const selected = {WidgetState.selected};
            const unselected = <WidgetState>{};
            expect(
              contrast(
                themeSwitch.thumbColor!.resolve(selected)!,
                themeSwitch.trackColor!.resolve(selected)!,
              ),
              greaterThanOrEqualTo(3.0),
              reason: '${skin.id}[$i] $mode SwitchTheme selected thumb',
            );
            expect(
              contrast(
                themeSwitch.thumbColor!.resolve(unselected)!,
                themeSwitch.trackColor!.resolve(unselected)!,
              ),
              greaterThanOrEqualTo(3.0),
              reason: '${skin.id}[$i] $mode SwitchTheme unselected thumb',
            );
          },
        );
      }
    }
  }

  // The journey styles: label on the accent fill, ink on the paper.
  for (final style in uiJourneyStyles) {
    test('${style.name}: onAccent on accent and ink on paper read', () {
      expect(contrast(style.onAccent, style.accent), greaterThanOrEqualTo(4.5));
      expect(contrast(style.ink, style.paper), greaterThanOrEqualTo(4.5));
    });
  }
}
