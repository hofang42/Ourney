import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<JourneysHarness> _open(
  WidgetTester tester, {
  Journey? journey,
  Size size = const Size(420, 1000),
}) async {
  final j =
      journey ??
      testJourney(status: JourneyStatus.ended, templateId: TemplateId.custom);
  final days = [10, 11, 12, 14].map((d) => LocalDate(2026, 10, d));
  final h = await pumpJourneys(
    tester,
    locale: const Locale('en'),
    location: JourneysPaths.wrapped(j.id),
    journeys: FakeJourneyRepository(
      journeys: [j],
      memberships: {j.id: testMembership(j)},
    ),
    checkIns: FakeCheckInRepository([
      for (final d in days)
        testCheckIn(j.id, d, caption: 'cap $d', metricValue: 70.0 - d.day),
    ]),
  );
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
  return h;
}

void main() {
  group('Wrapped story', () {
    testWidgets('pages advance by tap, segments jump, then the summary', (
      tester,
    ) async {
      await _open(tester);
      expect(_key('journey-wrapped'), findsOneWidget);
      expect(find.text('Journey complete'), findsOneWidget);
      // Minimal skin has two pages.
      expect(find.text('4 MOMENTS OVER 4 DAYS'), findsOneWidget);
      expect(_key('wrapped-segment-0'), findsOneWidget);
      expect(_key('wrapped-segment-1'), findsOneWidget);
      // U4: the last segment is the summary page.
      expect(_key('wrapped-segment-2'), findsOneWidget);
      expect(_key('wrapped-segment-3'), findsNothing);
      await tester.tapAt(const Offset(380, 500));
      await tester.pumpAndSettle();
      expect(find.textContaining('4/14 DAYS'), findsOneWidget);
      await tester.tapAt(const Offset(380, 500));
      await tester.pumpAndSettle();
      expect(_key('wrapped-summary'), findsOneWidget);
      expect(_key('wrapped-card-story'), findsOneWidget);
      await tester.tap(find.text('4:5'));
      await tester.pumpAndSettle();
      expect(_key('wrapped-card-feed'), findsOneWidget);
      expect(find.text('Export card'), findsOneWidget);
    });

    testWidgets('U4: back arrow steps a page; story exposes scroll actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester);
      final story = tester.getSemantics(_key('wrapped-headline'));
      expect(
        story.getSemanticsData().hasAction(SemanticsAction.scrollLeft),
        isTrue,
      );
      expect(story.label, isNotEmpty);
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        story.id,
        SemanticsAction.scrollLeft,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('4/14 DAYS'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(find.text('4 MOMENTS OVER 4 DAYS'), findsOneWidget);
      expect(_key('journey-wrapped'), findsOneWidget);
      await tester.tap(_key('wrapped-segment-2'));
      await tester.pumpAndSettle();
      expect(_key('wrapped-summary'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('left tap goes back, segment jumps to a page', (tester) async {
      await _open(tester);
      await tester.tap(_key('wrapped-segment-1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('4/14 DAYS'), findsOneWidget);
      await tester.tapAt(const Offset(40, 500));
      await tester.pumpAndSettle();
      expect(find.text('4 MOMENTS OVER 4 DAYS'), findsOneWidget);
    });

    testWidgets('quiet summary has privacy toggles and hides the wordmark', (
      tester,
    ) async {
      await _open(
        tester,
        journey: testJourney(
          status: JourneyStatus.ended,
          templateId: TemplateId.weightLoss,
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.tapAt(const Offset(380, 500));
        await tester.pumpAndSettle();
      }
      expect(_key('wrapped-hide-kg'), findsOneWidget);
      expect(_key('wrapped-blur'), findsOneWidget);
      expect(_key('wrapped-brand'), findsNothing);
      await tester.tap(_key('wrapped-hide-kg'));
      await tester.pumpAndSettle();
      expect(_key('wrapped-weights'), findsOneWidget);
    });

    testWidgets('U4: hide-kg and format are handed to the share card', (
      tester,
    ) async {
      final j = testJourney(
        status: JourneyStatus.ended,
        templateId: TemplateId.weightLoss,
      );
      final h = await _open(tester, journey: j);
      for (var i = 0; i < 4; i++) {
        await tester.tapAt(const Offset(380, 500));
        await tester.pumpAndSettle();
      }
      await tester.tap(_key('wrapped-cta'));
      await tester.pumpAndSettle();
      final uri = Uri.parse(h.location);
      expect(uri.path, '/share/${j.id}');
      expect(uri.queryParameters['hideMetric'], 'true');
      expect(uri.queryParameters['format'], 'story');
      expect(uri.queryParameters.containsKey('blur'), isFalse);
      expect(find.text('Save image'), findsNothing);
    });

    testWidgets('U4: turning hide-kg off is handed over as false', (
      tester,
    ) async {
      final j = testJourney(
        status: JourneyStatus.ended,
        templateId: TemplateId.weightLoss,
      );
      final h = await _open(tester, journey: j);
      for (var i = 0; i < 4; i++) {
        await tester.tapAt(const Offset(380, 500));
        await tester.pumpAndSettle();
      }
      await tester.tap(_key('wrapped-hide-kg'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('wrapped-edit-card'));
      await tester.tap(_key('wrapped-edit-card'));
      await tester.pumpAndSettle();
      expect(Uri.parse(h.location).queryParameters['hideMetric'], 'false');
    });

    for (final skin in [
      TemplateId.weightLoss,
      TemplateId.englishDaily,
      TemplateId.travel,
      TemplateId.workout30,
      TemplateId.custom,
    ]) {
      for (final dark in [false, true]) {
        testWidgets(
          '${skin.wireName} story + summary fit 320dp at 1.35x (${dark ? 'dark' : 'light'})',
          (tester) async {
            tester.platformDispatcher.platformBrightnessTestValue = dark
                ? Brightness.dark
                : Brightness.light;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            tester.platformDispatcher.textScaleFactorTestValue = 1.35;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await _open(
              tester,
              journey: testJourney(
                status: JourneyStatus.ended,
                templateId: skin,
                title: 'Một hành trình có tên rất dài để thử tràn chữ',
              ),
              size: const Size(320, 640),
            );
            for (var i = 0; i < 6; i++) {
              expect(tester.takeException(), isNull);
              await tester.tapAt(const Offset(300, 400));
              await tester.pumpAndSettle();
            }
            expect(_key('wrapped-summary'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.tap(find.text('4:5'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
