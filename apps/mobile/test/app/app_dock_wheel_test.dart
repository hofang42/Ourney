import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_dock.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../features/checkin/fakes.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('long-press on Snap opens the journey wheel; picking switches '
      'the active journey without navigating', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    final prefs = await testPrefs();
    final container = ProviderContainer(
      overrides: baseOverrides(
        prefs: prefs,
        journeys: FakeJourneyRepository(
          journeys: [
            testJourney(
              durationDays: null,
              id: 'run',
              templateId: TemplateId.workout30,
              title: 'Chạy bộ',
            ),
            testJourney(
              durationDays: null,
              id: 'trip',
              templateId: TemplateId.travel,
              title: 'Đà Lạt',
            ),
          ],
        ),
      ),
    );
    addTearDown(container.dispose);
    final taps = <int>[];
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testApp(
          Align(
            alignment: Alignment.bottomCenter,
            child: AppDock(
              currentIndex: AppDock.journeysIndex,
              onSelect: taps.add,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.longPress(find.byKey(const ValueKey('dock-snap-pill')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journey-wheel-run')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey-wheel-trip')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('journey-wheel-trip')));
    await tester.pumpAndSettle();
    expect(container.read(activeJourneyIdProvider), 'trip');
    expect(find.byKey(const ValueKey('journey-wheel-trip')), findsNothing);
    expect(taps, isEmpty, reason: 'the wheel never navigates');
  });
}
