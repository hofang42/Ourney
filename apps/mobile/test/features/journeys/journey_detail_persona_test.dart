import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/features/journeys/ui/timeline_grid.dart';
import 'package:ourney/personas/accountability_squad/timeline.dart';
import 'package:ourney/personas/memory_collectors/timeline.dart';
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

  testWidgets('a persona still being designed keeps the day grid, in its '
      'own colors', (tester) async {
    await pumpDetail(tester, TemplateId.weightLoss);
    expect(find.byType(TimelineGrid), findsOneWidget);
    final inner = tester.element(find.byType(TimelineGrid));
    expect(OurneyPersonaTheme.of(inner).skinId, PersonaSkinId.quietTransformer);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the screen stays in step with the persona it shows even when '
      'the app theme is another', (tester) async {
    await pumpDetail(tester, TemplateId.travel);
    final inner = tester.element(find.byType(ScrapbookThreadTimeline));
    expect(OurneyPersonaTheme.of(inner).skinId, PersonaSkinId.memoryCollectors);
  });
}
