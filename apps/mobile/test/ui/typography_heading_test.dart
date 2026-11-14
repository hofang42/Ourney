import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/skins.dart';
import 'package:ourney/ui/typography.dart';

void main() {
  group('UiFonts.forHeading', () {
    test('accepts the StyleGuide spelling', () {
      expect(UiFonts.forHeading('Fraunces'), UiFonts.fraunces);
      expect(UiFonts.forHeading('Playfair Display'), UiFonts.playfair);
      expect(UiFonts.forHeading('Barlow Condensed'), UiFonts.barlowCondensed);
      expect(UiFonts.forHeading('Space Grotesk'), UiFonts.spaceGrotesk);
    });

    test('accepts the normalized bundled family names (idempotent)', () {
      for (final f in [
        UiFonts.fraunces,
        UiFonts.playfair,
        UiFonts.barlowCondensed,
        UiFonts.spaceGrotesk,
      ]) {
        expect(UiFonts.forHeading(f), f);
      }
    });

    test('accepts skin ids and falls back to Space Grotesk', () {
      expect(UiFonts.forHeading('couple'), UiFonts.playfair);
      expect(UiFonts.forHeading('flexer'), UiFonts.barlowCondensed);
      expect(UiFonts.forHeading('quiet'), UiFonts.fraunces);
      expect(UiFonts.forHeading('nonsense'), UiFonts.spaceGrotesk);
    });

    test('every skin round-trips through the family name', () {
      for (final skin in uiSkins) {
        final family = UiFonts.forHeading(skin.headingFont);
        expect(UiFonts.forHeading(family), family, reason: skin.id);
        expect(UiText.heading(font: family, size: 20).fontFamily, family);
      }
    });
  });
}
