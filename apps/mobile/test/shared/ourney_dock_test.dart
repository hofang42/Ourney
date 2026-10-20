import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/app/theme/tokens.dart';
import 'package:ourney/shared/ourney_dock.dart';
import 'package:ourney_core/ourney_core.dart';

import '../personas/pump_persona.dart';

void main() {
  Finder dock() => find.byType(OurneyDock);

  for (final skin in allSkins) {
    for (final brightness in bothBrightness) {
      testWidgets('${skin.name} ${brightness.name}: same 3 tabs on every '
          'screen, snap pill in the persona accent', (tester) async {
        for (final index in [
          OurneyDock.journeysIndex,
          OurneyDock.groupsIndex,
        ]) {
          await pumpPersona(
            tester,
            Align(
              alignment: Alignment.bottomCenter,
              child: OurneyDock(currentIndex: index, onSelect: (_) {}),
            ),
            skin: skin,
            brightness: brightness,
            width: 320,
            textScale: 1.35,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Journeys'), findsOneWidget);
          expect(find.text('Nhóm'), findsOneWidget);
          expect(find.byIcon(Icons.map_rounded), findsOneWidget);
          expect(find.byIcon(Icons.groups_rounded), findsOneWidget);

          final pill = find.byKey(const ValueKey('ourney-pill-button-face'));
          expect(tester.getSize(pill), const Size(56, 40));
          final deco =
              tester.widget<Container>(pill).decoration! as BoxDecoration;
          expect(
            deco.color,
            OurneyPersonaTheme.forSkin(skin, brightness).primaryAccent,
          );
          expect(find.byKey(const ValueKey('dock-hero-shutter')), findsNothing);
        }
      });
    }
  }

  testWidgets('on the camera the snap button is a 76x76 hero shutter and the '
      'dock is dark', (tester) async {
    await pumpPersona(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: OurneyDock(
          currentIndex: OurneyDock.captureIndex,
          onSelect: (_) {},
        ),
      ),
      skin: PersonaSkinId.memoryCollectors,
      brightness: Brightness.light,
    );
    await tester.pump(const Duration(milliseconds: 300));
    final hero = find.byKey(const ValueKey('dock-hero-shutter'));
    expect(tester.getSize(hero), const Size(76, 76));
    expect(find.byKey(const ValueKey('ourney-pill-button-face')), findsNothing);
    final material = tester.widget<Material>(
      find.descendant(of: dock(), matching: find.byType(Material)).first,
    );
    expect(material.color, OurneyColors.cameraBg);
  });

  testWidgets('every control is at least 48dp and taps select the tab', (
    tester,
  ) async {
    final picked = <int>[];
    await pumpPersona(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: OurneyDock(
          currentIndex: OurneyDock.journeysIndex,
          onSelect: picked.add,
        ),
      ),
      width: 320,
    );
    for (final key in ['dock-journeys', 'dock-snap-pill', 'dock-groups']) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
    await tester.tap(find.byKey(const ValueKey('dock-journeys')));
    await tester.tap(find.byKey(const ValueKey('dock-snap-pill')));
    await tester.tap(find.byKey(const ValueKey('dock-groups')));
    expect(picked, [
      OurneyDock.journeysIndex,
      OurneyDock.captureIndex,
      OurneyDock.groupsIndex,
    ]);
  });

  testWidgets('the selected tab is announced, not only colored', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPersona(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: OurneyDock(
          currentIndex: OurneyDock.groupsIndex,
          onSelect: (_) {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('dock-groups'))),
      matchesSemantics(
        label: 'Nhóm',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
