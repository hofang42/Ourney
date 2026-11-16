import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/checkin/checkin_progress.dart';
import 'package:ourney/features/checkin/checkin_success.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'fakes.dart';

void main() {
  // One template per skin.
  final byTemplate = <PersonaSkinId, TemplateId>{};
  for (final t in TemplateId.values) {
    byTemplate.putIfAbsent(personaSkinForTemplate(t), () => t);
  }

  for (final entry in byTemplate.entries) {
    for (final brightness in Brightness.values) {
      for (final milestone in <Milestone?>[null, Milestone.sevenDays]) {
        testWidgets('${entry.key.name} ${brightness.name} '
            '${milestone?.name ?? 'plain'}: done fits 320dp at 1.35x', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 640);
          addTearDown(tester.view.reset);
          tester.platformDispatcher.textScaleFactorTestValue = 1.35;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final journey = testJourney(templateId: entry.value);
          final day = journey.startDate.addDays(6);
          await tester.pumpWidget(
            ProviderScope(
              child: testApp(
                CheckinSuccessView(
                  outcome: CheckInOutcome(
                    checkIn: testCheckIn(day),
                    streakBefore: 6,
                    streakAfter: 7,
                    milestone: milestone,
                  ),
                  journey: journey,
                  haptics: false,
                  onDone: () {},
                  onShare: () {},
                ),
                brightness: brightness,
              ),
            ),
          );
          await tester.pump();
          expect(
            find.byKey(const ValueKey('checkin-success-screen')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('checkin-streak')), findsOneWidget);
          expect(find.byKey(const ValueKey('checkin-done')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('checkin-milestone')),
            milestone == null ? findsNothing : findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('checkin-share')),
            milestone == null ? findsNothing : findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pump(CheckinSuccessView.autoCloseDelay);
        });
      }
    }
  }
}
