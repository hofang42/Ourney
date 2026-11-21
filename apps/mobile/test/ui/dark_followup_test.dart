import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/ui/journey_style.dart';
import 'package:ourney/ui/ui.dart';

Widget _app(Brightness b, Widget child) => MaterialApp(
  theme: OurneyTheme.build(b),
  home: Scaffold(body: child),
);

void main() {
  test('light dialog is the surface, dark dialog the sheet', () {
    expect(
      OurneyTheme.build(Brightness.light).dialogTheme.backgroundColor,
      OurneyUi.light.surface,
    );
    expect(
      OurneyTheme.build(Brightness.dark).dialogTheme.backgroundColor,
      OurneyUi.dark.sheet,
    );
  });

  testWidgets('JourneyPalette follows the scoped variant accent', (t) async {
    JourneyPalette? scoped;
    JourneyPalette? bare;
    final style = uiJourneyStyles.first;
    final skin = uiSkinById('squad');
    await t.pumpWidget(
      _app(
        Brightness.dark,
        Column(
          children: [
            Builder(
              builder: (c) {
                bare = JourneyPalette.of(c, style);
                return const SizedBox();
              },
            ),
            UiSkinScope(
              skinId: 'squad',
              variant: 1,
              child: Builder(
                builder: (c) {
                  scoped = JourneyPalette.of(c, style);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
    final v = skin.resolvedVariant(1, Brightness.dark);
    expect(scoped!.accent, v.accent);
    expect(bare!.accent, style.accent);
    expect(scoped!.outline, isNot(scoped!.ink));
  });

  testWidgets(
    'skin scope notifies when only the accent changes (light to dark)',
    (t) async {
      // A variant whose dark accent differs while skin, index and button stay.
      String? skinId;
      int? index;
      for (final skin in uiSkins) {
        for (var i = 0; i < skin.variants.length; i++) {
          final l = skin.resolvedVariant(i, Brightness.light);
          final d = skin.resolvedVariant(i, Brightness.dark);
          if (l.button == d.button && l.accent != d.accent) {
            skinId = skin.id;
            index = i;
          }
        }
      }
      expect(skinId, isNotNull, reason: 'a variant with a distinct accentDark');
      var builds = 0;
      final probe = Builder(
        builder: (c) {
          UiSkinScope.of(c);
          builds++;
          return const SizedBox();
        },
      );
      Widget app(Brightness b) => MaterialApp(
        home: Theme(
          data: OurneyTheme.build(b),
          child: UiSkinScope(skinId: skinId!, variant: index!, child: probe),
        ),
      );
      await t.pumpWidget(app(Brightness.light));
      builds = 0;
      await t.pumpWidget(app(Brightness.dark));
      expect(builds, greaterThan(0));
    },
  );

  testWidgets(
    'light mode: palette outline is the style ink, accent the variant',
    (t) async {
      final style = uiJourneyStyles.first;
      JourneyPalette? bare;
      JourneyPalette? scoped;
      await t.pumpWidget(
        MaterialApp(
          theme: OurneyTheme.build(Brightness.light),
          home: Column(
            children: [
              Builder(
                builder: (c) {
                  bare = JourneyPalette.of(c, style);
                  return const SizedBox();
                },
              ),
              UiSkinScope(
                skinId: 'squad',
                variant: 1,
                child: Builder(
                  builder: (c) {
                    scoped = JourneyPalette.of(c, style);
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      );
      expect(bare!.outline, style.ink);
      expect(scoped!.accent, uiSkinById('squad').variant(1).accent);
    },
  );
}
