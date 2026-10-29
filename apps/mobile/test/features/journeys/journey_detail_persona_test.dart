import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_dock.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/features/journeys/ui/timeline_grid.dart';
import 'package:ourney/personas/accountability_squad/timeline.dart';
import 'package:ourney/personas/aesthetic_flexer/timeline.dart';
import 'package:ourney/personas/couple_rituals/timeline.dart';
import 'package:ourney/personas/memory_collectors/timeline.dart';
import 'package:ourney/personas/minimalist_habit/timeline.dart';
import 'package:ourney/personas/quiet_transformer/timeline.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

/// F3: the journey detail timeline is the one of the journey's persona.
void main() {
  Future<void> pumpDetail(WidgetTester tester, TemplateId template) async {
    final j = testJourney(templateId: template);
    await pumpJourneys(
      tester,
      locale: const Locale('en'),
      location: AppRoutes.journey(j.id),
      journeys: FakeJourneyRepository(
        journeys: [j],
        memberships: {j.id: testMembership(j)},
      ),
      checkIns: FakeCheckInRepository([
        for (final d in [10, 11, 13, 14, 15])
          testCheckIn(j.id, LocalDate(2026, 10, d)),
      ]),
    );
  }

  testWidgets('opening a journey makes it the active one, so the dock and '
      'the theme follow it', (tester) async {
    final other = testJourney(id: 'other', templateId: TemplateId.weightLoss);
    final trip = testJourney(id: 'trip', templateId: TemplateId.travel);
    final h = await pumpJourneys(
      tester,
      locale: const Locale('en'),
      location: AppRoutes.journey(trip.id),
      journeys: FakeJourneyRepository(
        journeys: [other, trip],
        memberships: {trip.id: testMembership(trip)},
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.container.read(activeJourneyIdProvider), 'trip');
    final dock = tester.element(find.byType(AppDock));
    expect(OurneyPersonaTheme.of(dock).skinId, PersonaSkinId.memoryCollectors);
  });

  testWidgets('travel draws the scrapbook thread', (tester) async {
    await pumpDetail(tester, TemplateId.travel);
    expect(find.byType(ScrapbookThreadTimeline), findsOneWidget);
    expect(find.byType(SteppingStoneQuestTimeline), findsNothing);
    expect(find.byType(TimelineGrid), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('english draws the stepping-stone quest', (tester) async {
    await pumpDetail(tester, TemplateId.englishDaily);
    expect(find.byType(SteppingStoneQuestTimeline), findsOneWidget);
    expect(find.byType(ScrapbookThreadTimeline), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weight loss draws the connected weight curve timeline in '
      'quietTransformer colors', (tester) async {
    await pumpDetail(tester, TemplateId.weightLoss);
    expect(find.byType(ConnectedWeightCurveTimeline), findsOneWidget);
    final inner = tester.element(find.byType(ConnectedWeightCurveTimeline));
    expect(OurneyPersonaTheme.of(inner).skinId, PersonaSkinId.quietTransformer);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workout30 draws athletic telemetry', (tester) async {
    await pumpDetail(tester, TemplateId.workout30);
    expect(find.byType(AthleticTelemetryTimeline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom draws chain grid', (tester) async {
    await pumpDetail(tester, TemplateId.custom);
    expect(find.byType(ChainCalendarGridTimeline), findsOneWidget);
    expect(find.byType(DuoSplitTimeline), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the screen stays in step with the persona it shows even when '
      'the app theme is another', (tester) async {
    await pumpDetail(tester, TemplateId.travel);
    final inner = tester.element(find.byType(ScrapbookThreadTimeline));
    expect(OurneyPersonaTheme.of(inner).skinId, PersonaSkinId.memoryCollectors);
  });
}
