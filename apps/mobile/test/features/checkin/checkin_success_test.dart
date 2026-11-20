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
  for (final size in const [Size(320, 640), Size(390, 844), Size(430, 932)]) {
    for (final scale in const [1.0, 1.35]) {
      testWidgets('memory done: polaroid, title, streak never overlap '
          '${size.width.toInt()}dp x$scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final journey = testJourney(templateId: TemplateId.travel);
        await tester.pumpWidget(
          ProviderScope(
            child: testApp(
              CheckinSuccessView(
                outcome: CheckInOutcome(
                  checkIn: testCheckIn(journey.startDate.addDays(2)),
                  streakBefore: 1,
                  streakAfter: 2,
                  photoOfDay: 2,
                ),
                journey: journey,
                haptics: false,
                onDone: () {},
                onShare: () {},
              ),
            ),
          ),
        );
        await tester.pump();
        final photo = tester.getRect(
          find.byKey(const ValueKey('checkin-polaroid')),
        );
        final title = tester.getRect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == 'Chain kept.' || w.data == 'Giữ được chuỗi.'),
          ),
        );
        final streak = tester.getRect(
          find.byKey(const ValueKey('checkin-streak')),
        );
        expect(photo.bottom, lessThanOrEqualTo(title.top));
        expect(title.bottom, lessThanOrEqualTo(streak.top));
        expect(tester.takeException(), isNull);
        await tester.pump(CheckinSuccessView.autoCloseDelay);
      });
    }
  }
}
