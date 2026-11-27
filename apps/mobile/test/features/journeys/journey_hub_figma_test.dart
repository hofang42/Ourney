import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/data/create_progress.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_intro.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

class _Resume extends CreateProgressController {
  @override
  int? build() => 3;
}

class _Pending extends FakeJourneyRepository {
  _Pending() : super();

  @override
  Stream<List<Journey>> watchActive() => const Stream.empty();
}

Future<void> _pump(
  WidgetTester tester, {
  bool offline = false,
  bool resume = false,
  bool empty = false,
  Size size = const Size(420, 1800),
}) async {
  final j = testJourney();
  await pumpJourneys(
    tester,
    locale: const Locale('en'),
    journeys: empty
        ? FakeJourneyRepository()
        : FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
    checkIns: FakeCheckInRepository([testCheckIn(j.id, testToday)]),
    extraOverrides: [
      journeyHomeOfflineProvider.overrideWith((ref) => Stream.value(offline)),
      if (resume) createProgressProvider.overrideWith(_Resume.new),
    ],
  );
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
}

void main() {
  group('Hub (Figma HubScreen)', () {
    testWidgets('title, greeting, section heading and new-journey card', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.bySemanticsLabel('Ourney'), findsOneWidget);
      expect(find.byType(UiCompactWordmark), findsOneWidget);
      expect(_key('hub-greeting'), findsOneWidget);
      expect(find.text('your journeys.'), findsOneWidget);
      expect(find.text('1 running'), findsOneWidget);
      await tester.ensureVisible(_key('journeys-new-card'));
      expect(find.text('new journey.'), findsOneWidget);
      expect(find.text('pick a world to start'), findsOneWidget);
    });

    testWidgets('offline banner', (tester) async {
      await _pump(tester, offline: true);
      expect(_key('hub-offline-banner'), findsOneWidget);
      expect(
        find.text('saved on this phone, will send when you are online'),
        findsOneWidget,
      );
    });

    testWidgets('resume-create card shows the step and opens the flow', (
      tester,
    ) async {
      await _pump(tester, resume: true);
      expect(_key('hub-create-progress'), findsOneWidget);
      expect(find.text('Continue creating a journey'), findsOneWidget);
      expect(find.text('step 3/5'), findsOneWidget);
      await tester.tap(_key('hub-create-progress'));
      await tester.pumpAndSettle();
      expect(_key('journeys-create-flow'), findsOneWidget);
    });

    testWidgets('empty state: fanned Polaroid trio with the one-photo line', (
      tester,
    ) async {
      await _pump(tester, empty: true);
      expect(_key('day-zero-polaroid-trio'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        expect(_key('day-zero-photo-$i'), findsOneWidget);
      }
      expect(
        find.descendant(
          of: _key('day-zero-polaroid-trio'),
          matching: find.byType(Image),
        ),
        findsNWidgets(3),
      );
      // F5: Every _DayZero Polaroid errorBuilder uses a valid OurneyIcon name
      // with non-null path geometry and onPastel ink.
      final ctx = tester.element(_key('day-zero-polaroid-trio'));
      final expectedFallbacks = ['fitness', 'heart', 'book'];
      final images = tester
          .widgetList<Image>(
            find.descendant(
              of: _key('day-zero-polaroid-trio'),
              matching: find.byType(Image),
            ),
          )
          .toList();
      expect(images, hasLength(3));
      for (var i = 0; i < images.length; i++) {
        expect(images[i].errorBuilder, isNotNull);
        final fallback = images[i].errorBuilder!(ctx, StateError('missing'), null);
        expect(fallback, isA<Center>());
        final icon = (fallback as Center).child! as OurneyIcon;
        expect(icon.name, expectedFallbacks[i]);
        expect(ourneyIconNames, contains(icon.name));
        expect(ourneyIconPath(icon.name), isNotNull);
        expect(icon.inkColor, UiFlowColors.onPastel);
      }
      expect(find.text('no journeys yet.'), findsOneWidget);
      expect(
        find.text('one photo a day keeps the whole road.'),
        findsOneWidget,
      );
      expect(find.text('Start your first journey'), findsOneWidget);
    });

    testWidgets('loading shows skeletons, not a spinner card', (tester) async {
      await pumpJourneys(
        tester,
        locale: const Locale('en'),
        journeys: _Pending(),
      );
      expect(_key('journeys-loading'), findsOneWidget);
    });

    testWidgets(
      'UX-21: Hub hero never shows 0 streak or partial remaining count while check-ins load',
      (tester) async {
        final j1 = testJourney(id: 'j1', title: 'Run');
        final j2 = testJourney(id: 'j2', title: 'Read');
        final pendingCheckIns = StreamController<List<CheckIn>>();
        addTearDown(pendingCheckIns.close);
        await pumpJourneys(
          tester,
          locale: const Locale('en'),
          journeys: FakeJourneyRepository(
            journeys: [j1, j2],
            memberships: {
              j1.id: testMembership(j1),
              j2.id: testMembership(j2),
            },
          ),
          extraOverrides: [
            // j1 has emitted (not checked in today), while j2 is still loading.
            myCheckInsProvider('j1').overrideWith(
              (ref) => Stream.value(const <CheckIn>[]),
            ),
            myCheckInsProvider('j2').overrideWith(
              (ref) => pendingCheckIns.stream,
            ),
          ],
        );
        await tester.pump();
        final hero = tester.widget<UiStreakHero>(_key('journeys-hub-hero'));
        expect(hero.loading, isTrue);
        expect(hero.title, 'Loading');
        expect(hero.semanticLabel, 'Loading');
        expect(
          find.descendant(of: _key('journeys-hub-hero'), matching: find.text('—')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _key('journeys-hub-hero'), matching: find.text('0')),
          findsNothing,
        );
      },
    );

    for (final dark in [false, true]) {
      for (final empty in [false, true]) {
        for (final scale in [1.35, 2.0]) {
          testWidgets(
            '${empty ? 'empty' : 'list'} fits 320dp at ${scale}x (${dark ? 'dark' : 'light'})',
            (tester) async {
              tester.platformDispatcher.platformBrightnessTestValue = dark
                  ? Brightness.dark
                  : Brightness.light;
              addTearDown(
                tester.platformDispatcher.clearPlatformBrightnessTestValue,
              );
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue,
              );
              await _pump(
                tester,
                offline: true,
                resume: true,
                empty: empty,
                size: const Size(320, 640),
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });
}
