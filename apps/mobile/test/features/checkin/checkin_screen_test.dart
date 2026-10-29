import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/checkin/captured_photo.dart';
import 'package:ourney/features/checkin/checkin_clock.dart';
import 'package:ourney/features/checkin/checkin_success.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/checkin/routes.dart';
import 'package:ourney/shared/stamp_animation.dart';
import 'package:ourney/shared/streak_flame.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'fakes.dart';

void main() {
  late FakeJourneyRepository journeys;
  late FakeCheckInRepository checkIns;
  late FakePhotoCompressor compressor;
  late RouteLog log;

  final photo = CapturedPhoto(
    journeyId: 'j1',
    path: '/tmp/shot.jpg',
    capturedAt: testNowUtc,
  );

  setUp(() {
    journeys = FakeJourneyRepository();
    checkIns = FakeCheckInRepository();
    compressor = FakePhotoCompressor();
    log = RouteLog();
  });

  Future<void> pump(
    WidgetTester tester, {
    CapturedPhoto? extra,
    bool noPhoto = false,
    Map<String, Object> prefsValues = const {},
  }) async {
    final prefs = await testPrefs(prefsValues);
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(prefs: prefs, journeys: journeys, checkIns: checkIns),
        photoCompressorProvider.overrideWithValue(compressor),
        checkinClockProvider.overrideWithValue(FakeCheckinClock()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      routedTestApp(
        container: container,
        routes: checkinRoutes,
        initialLocation: '/checkin',
        initialExtra: noPhoto ? null : (extra ?? photo),
        log: log,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapPost(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('checkin-post')));
    await tester.tap(find.byKey(const ValueKey('checkin-post')));
    await tester.pump();
    await tester.pump();
  }

  /// Lets the stamp and the auto-close timer run out. Not for milestones:
  /// confetti moves particles with wall-clock time, so it never settles
  /// under the test's fake clock.
  Future<void> finishSuccess(WidgetTester tester) async {
    await tester.pump(CheckinSuccessView.autoCloseDelay);
    await tester.pumpAndSettle();
  }

  testWidgets('one tap on Post saves through the repository (FR-C4/C5)', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(
      find.byKey(const ValueKey('checkin-caption')),
      '  Ngày đầu  ',
    );
    await tapPost(tester);

    expect(compressor.sources, ['/tmp/shot.jpg']);
    expect(checkIns.submitted, hasLength(1));
    final draft = checkIns.submitted.single;
    expect(draft.journeyId, 'j1');
    expect(draft.capturedAt, testNowUtc);
    expect(draft.photoFile, '/tmp/shot.jpg.1080.jpg');
    expect(draft.thumbFile, '/tmp/shot.jpg.thumb.jpg');
    expect(draft.caption, 'Ngày đầu');
    expect(draft.fromLibrary, isFalse);
    expect(draft.metricValue, isNull);

    expect(find.byKey(const ValueKey('checkin-success')), findsOneWidget);
    expect(find.text('Giữ được chuỗi.'), findsOneWidget);
    expect(find.text('+1 ngày'), findsOneWidget);
    expect(find.byKey(const ValueKey('checkin-milestone')), findsNothing);

    // No milestone: closes by itself back to the camera.
    await finishSuccess(tester);
    expect(find.byKey(const ValueKey('stub-capture')), findsOneWidget);
  });

  testWidgets('streak goes +1 on success (FR-C8)', (tester) async {
    checkIns.existing.addAll([
      testCheckIn(const LocalDate(2026, 10, 14)),
      testCheckIn(const LocalDate(2026, 10, 15)),
    ]);
    await pump(tester);
    await tapPost(tester);
    final stamp = tester.widget<StampAnimation>(find.byType(StampAnimation));
    expect(stamp.haptic, isTrue);
    final flame = tester.widget<StreakFlame>(
      find.byKey(const ValueKey('checkin-streak')),
    );
    expect(flame.days, 3);
    await finishSuccess(tester);
  });

  testWidgets('empty caption is sent as null', (tester) async {
    await pump(tester);
    await tapPost(tester);
    expect(checkIns.submitted.single.caption, isNull);
    await finishSuccess(tester);
  });

  testWidgets('library photo shows the from-library label (FR-C3)', (
    tester,
  ) async {
    await pump(
      tester,
      extra: CapturedPhoto(
        journeyId: 'j1',
        path: '/tmp/lib.jpg',
        capturedAt: testNowUtc,
        fromLibrary: true,
      ),
    );
    expect(find.byKey(const ValueKey('checkin-from-library')), findsOneWidget);
    await tapPost(tester);
    expect(checkIns.submitted.single.fromLibrary, isTrue);
    await finishSuccess(tester);
  });

  group('caption limit (FR-C4)', () {
    testWidgets('stops at 140 characters and shows the counter', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('0/140'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('checkin-caption')),
        'a' * 150,
      );
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('checkin-caption')),
      );
      expect(field.controller!.text.length, 140);
      expect(find.text('140/140'), findsOneWidget);
    });

    testWidgets('counts code points like the server (emoji = 1)', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('checkin-caption')),
        '💪' * 141,
      );
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('checkin-caption')),
      );
      expect(field.controller!.text.runes.length, 140);
      expect(find.text('140/140'), findsOneWidget);
    });
  });

  group('replace today (FR-C7)', () {
    testWidgets('asks before replacing; cancel keeps the old photo', (
      tester,
    ) async {
      checkIns.existing.add(testCheckIn(testToday));
      await pump(tester);
      await tapPost(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('checkin-replace-dialog')), findsOne);

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(checkIns.submitted, isEmpty);
      expect(find.byKey(const ValueKey('checkin-success')), findsNothing);
    });

    testWidgets('confirm replaces and does not count the streak twice', (
      tester,
    ) async {
      checkIns.existing.add(testCheckIn(testToday));
      await pump(tester);
      await tapPost(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checkin-replace-confirm')));
      await tester.pump();
      await tester.pump();

      expect(checkIns.submitted, hasLength(1));
      expect(find.text('Đã thay ảnh hôm nay'), findsOneWidget);
      expect(find.text('+1 ngày'), findsNothing);
      await finishSuccess(tester);
    });

    testWidgets('a check-in yesterday does not ask', (tester) async {
      checkIns.existing.add(testCheckIn(testToday.addDays(-1)));
      await pump(tester);
      await tapPost(tester);
      expect(
        find.byKey(const ValueKey('checkin-replace-dialog')),
        findsNothing,
      );
      expect(checkIns.submitted, hasLength(1));
      await finishSuccess(tester);
    });
  });

  group('metric', () {
    testWidgets('weight loss: metric is private by default (FR-B7)', (
      tester,
    ) async {
      journeys = FakeJourneyRepository(
        journeys: [
          testJourney(
            templateId: TemplateId.weightLoss,
            metricName: 'Cân nặng',
            metricUnit: 'kg',
            hideMetricDefault: true,
          ),
        ],
      );
      await pump(tester);
      expect(find.text('Cân nặng (kg)'), findsOneWidget);
      expect(find.text('Chỉ mình bạn thấy số này'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('checkin-metric')),
        '72,5',
      );
      await tapPost(tester);
      expect(checkIns.submitted.single.metricValue, 72.5);
      await finishSuccess(tester);
    });

    testWidgets('membership hideMetric=false overrides the default', (
      tester,
    ) async {
      journeys = FakeJourneyRepository(
        journeys: [
          testJourney(metricName: 'Cân nặng', hideMetricDefault: true),
        ],
        membership: Membership(
          journeyId: 'j1',
          userId: 'me',
          role: MemberRole.owner,
          status: MemberStatus.active,
          joinedAt: DateTime.utc(2026, 10, 1),
        ),
      );
      await pump(tester);
      expect(find.byKey(const ValueKey('checkin-metric')), findsOneWidget);
      expect(find.text('Chỉ mình bạn thấy số này'), findsNothing);
    });

    testWidgets('invalid value blocks posting', (tester) async {
      journeys = FakeJourneyRepository(
        journeys: [testJourney(metricName: 'Phút')],
      );
      await pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('checkin-metric')),
        '1.2.3',
      );
      await tapPost(tester);
      expect(find.text('Nhập một số hợp lệ'), findsOneWidget);
      expect(checkIns.submitted, isEmpty);
    });

    testWidgets('no metric field when the journey has none', (tester) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('checkin-metric')), findsNothing);
    });
  });

  group('milestones (FR-C8)', () {
    testWidgets('7-day streak: confetti and share offer', (tester) async {
      checkIns.existing.addAll([
        for (var i = 1; i <= 6; i++) testCheckIn(testToday.addDays(-i)),
      ]);
      await pump(tester);
      await tapPost(tester);

      expect(find.text('7 ngày liên tục!'), findsOneWidget);
      final confetti = tester.widget<ConfettiWidget>(
        find.byType(ConfettiWidget),
      );
      expect(
        confetti.confettiController.state,
        ConfettiControllerState.playing,
      );

      await tester.pump(CheckinSuccessView.autoCloseDelay);
      // A milestone does not auto-close.
      expect(find.byKey(const ValueKey('checkin-success')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('checkin-share')));
      await tester.tap(find.byKey(const ValueKey('checkin-share')));
      // The success view (and its confetti) is replaced by /share.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('stub-share')), findsOneWidget);
      expect(log.locations.last, '/share/j1');
    });

    testWidgets('finish line wins over the streak milestone', (tester) async {
      journeys = FakeJourneyRepository(
        journeys: [testJourney(start: testToday.addDays(-6), durationDays: 7)],
      );
      checkIns.existing.addAll([
        for (var i = 1; i <= 6; i++) testCheckIn(testToday.addDays(-i)),
      ]);
      await pump(tester);
      await tapPost(tester);
      expect(find.text('Về đích rồi!'), findsOneWidget);
      expect(find.byKey(const ValueKey('checkin-share')), findsOneWidget);
      // Let the confetti controller's emission timer expire.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('reduce motion: no confetti', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      checkIns.existing.addAll([
        for (var i = 1; i <= 6; i++) testCheckIn(testToday.addDays(-i)),
      ]);
      await pump(tester);
      await tapPost(tester);
      expect(find.text('7 ngày liên tục!'), findsOneWidget);
      final confetti = tester.widget<ConfettiWidget>(
        find.byType(ConfettiWidget),
      );
      expect(
        confetti.confettiController.state,
        ConfettiControllerState.stopped,
      );
      await tester.pumpAndSettle();
    });
  });

  testWidgets('haptics toggle off: the stamp has no haptic', (tester) async {
    await pump(tester, prefsValues: {HapticsEnabled.prefsKey: false});
    await tapPost(tester);
    final stamp = tester.widget<StampAnimation>(find.byType(StampAnimation));
    expect(stamp.haptic, isFalse);
    await finishSuccess(tester);
  });

  group('errors', () {
    testWidgets('ended journey shows a message and keeps the form', (
      tester,
    ) async {
      checkIns.submitError = const OurneyException(OurneyErrorCode.ended);
      await pump(tester);
      await tapPost(tester);
      await tester.pump();
      expect(
        find.text('Hành trình đã kết thúc nên không check-in thêm được.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('checkin-post')), findsOneWidget);
    });

    testWidgets('compression failure shows a photo error', (tester) async {
      compressor.fail = true;
      await pump(tester);
      await tapPost(tester);
      await tester.pump();
      expect(
        find.text('Không xử lý được ảnh này. Thử ảnh khác nhé.'),
        findsOneWidget,
      );
      expect(checkIns.submitted, isEmpty);
    });

    testWidgets('opened without a photo shows a way back', (tester) async {
      await pump(tester, noPhoto: true);
      expect(find.byKey(const ValueKey('checkin-missing-photo')), findsOne);
    });

    testWidgets('unknown journey shows a way back', (tester) async {
      journeys.journeys.clear();
      await pump(tester);
      expect(find.byKey(const ValueKey('checkin-missing-journey')), findsOne);
    });
  });
}
