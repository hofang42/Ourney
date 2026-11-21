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

  testWidgets('skin scope rebuilds dependents when only the accent changes', (
    t,
  ) async {
    var builds = 0;
    final probe = Builder(
      builder: (c) {
        UiSkinScope.of(c);
        builds++;
        return const SizedBox();
      },
    );
    // Variants of one skin that share the button but differ in accent.
    int? a;
    int? b;
    outer:
    for (final skin in uiSkins) {
      for (var i = 0; i < skin.variants.length; i++) {
        for (var j = i + 1; j < skin.variants.length; j++) {
          final x = skin.variants[i], y = skin.variants[j];
          if (x.button == y.button && x.accent != y.accent) {
            a = i;
            b = j;
            await t.pumpWidget(
              _app(
                Brightness.light,
                UiSkinScope(skinId: skin.id, variant: i, child: probe),
              ),
            );
            builds = 0;
            await t.pumpWidget(
              _app(
                Brightness.light,
                UiSkinScope(skinId: skin.id, variant: j, child: probe),
              ),
            );
            break outer;
          }
        }
      }
    }
    if (a == null) return; // no such variant pair in the current skins
    expect(builds, greaterThan(0), reason: 'variants $a -> $b');
  });
}
