import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/domain/journey_layouts.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<JourneysHarness> _open(
  WidgetTester tester, {
  Journey? journey,
  String userId = 'u1',
  Size size = const Size(420, 1800),
}) async {
  final j = journey ?? testJourney();
  final h = await pumpJourneys(
    tester,
    locale: const Locale('en'),
    location: JourneysPaths.edit(j.id),
    userId: userId,
    journeys: FakeJourneyRepository(
      journeys: [j],
      memberships: {j.id: testMembership(j, userId: userId)},
    ),
  );
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
  return h;
}

void main() {
  group('availableLayoutsFor', () {
    test('hides layouts that need data the journey lacks', () {
      final solo = testJourney(templateId: TemplateId.custom);
      final layouts = availableLayoutsFor(
        solo,
        current: PersonaSkinId.minimalistHabit,
      );
      expect(layouts, [
        PersonaSkinId.memoryCollectors,
        PersonaSkinId.minimalistHabit,
      ]);
      final group = testJourney(
        kind: JourneyKind.group,
        templateId: TemplateId.workout30,
      );
      expect(
        availableLayoutsFor(group, current: PersonaSkinId.aestheticFlexer),
        containsAll([
          PersonaSkinId.accountabilitySquad,
          PersonaSkinId.aestheticFlexer,
        ]),
      );
    });
  });

  group('Edit journey screen', () {
    testWidgets('renames, picks cover and colour, saves through update', (
      tester,
    ) async {
      final h = await _open(tester);
      expect(_key('journey-edit'), findsOneWidget);
      expect(find.text('update journey.'), findsOneWidget);
      await tester.enterText(_key('edit-name'), 'Renamed run');
      await tester.tap(_key('edit-cover-2'));
      await tester.tap(_key('edit-color-1'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('edit-save-bottom'));
      await tester.tap(_key('edit-save-bottom'));
      await tester.pumpAndSettle();
      final u = h.journeys.updates.single;
      expect(u.title, 'Renamed run');
      expect(u.cover, 2);
      expect(u.color, 1);
      expect(u.reminderTime, matches(RegExp(r'^\d\d:\d\d$')));
    });

    testWidgets('switching layout previews, then stores the override', (
      tester,
    ) async {
      final h = await _open(tester);
      await tester.ensureVisible(_key('edit-layout-memory'));
      await tester.tap(_key('edit-layout-memory'));
      await tester.pumpAndSettle();
      expect(_key('layout-full-preview'), findsOneWidget);
      await tester.tap(_key('layout-use'));
      await tester.pumpAndSettle();
      expect(h.journeys.updates.single.layout, PersonaSkinId.memoryCollectors);
      expect(h.journeys.journeys.single.layout, PersonaSkinId.memoryCollectors);
    });

    testWidgets('cancel in the preview changes nothing', (tester) async {
      final h = await _open(tester);
      await tester.ensureVisible(_key('edit-layout-memory'));
      await tester.tap(_key('edit-layout-memory'));
      await tester.pumpAndSettle();
      await tester.tap(_key('layout-cancel'));
      await tester.pumpAndSettle();
      expect(h.journeys.updates, isEmpty);
    });

    testWidgets('a non-owner cannot edit', (tester) async {
      final j = testJourney(ownerId: 'someone-else');
      await _open(tester, journey: j);
      expect(_key('edit-save'), findsNothing);
      expect(_key('edit-save-bottom'), findsNothing);
      expect(find.text('Only the journey owner can edit.'), findsOneWidget);
    });

    for (final dark in [false, true]) {
      testWidgets('fits 320dp at 1.35x text (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        tester.platformDispatcher.textScaleFactorTestValue = 1.35;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _open(
          tester,
          journey: testJourney(
            templateId: TemplateId.workout30,
            title: 'Một hành trình có tên rất dài để thử tràn chữ',
          ),
          size: const Size(320, 640),
        );
        expect(tester.takeException(), isNull);
        expect(_key('reminder-wheel'), findsOneWidget);
        await tester.scrollUntilVisible(
          _key('edit-save-bottom'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
