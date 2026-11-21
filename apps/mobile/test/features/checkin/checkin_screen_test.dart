import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/checkin/captured_photo.dart';
import 'package:ourney/features/checkin/checkin_clock.dart';
import 'package:ourney/features/checkin/checkin_success.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/checkin/routes.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../reminders/reminders_fakes.dart';
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
    journeys = FakeJourneyRepository(
      journeys: [testJourney(templateId: TemplateId.weightLoss)],
    );
    checkIns = FakeCheckInRepository();
    compressor = FakePhotoCompressor();
    log = RouteLog();
  });

  Future<void> pump(
    WidgetTester tester, {
    CapturedPhoto? extra,
    bool noPhoto = false,
    Map<String, Object> prefsValues = const {},
    Brightness brightness = Brightness.light,
    void Function(ProviderContainer)? before,
    List<Override> overrides = const [],
  }) async {
    final prefs = await testPrefs(prefsValues);
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(prefs: prefs, journeys: journeys, checkIns: checkIns),
        photoCompressorProvider.overrideWithValue(compressor),
        checkinClockProvider.overrideWithValue(FakeCheckinClock()),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    before?.call(container);
    await tester.pumpWidget(
      routedTestApp(
        container: container,
        routes: checkinRoutes,
        initialLocation: '/checkin',
        initialExtra: noPhoto ? null : (extra ?? photo),
        log: log,
        brightness: brightness,
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

  /// Lets the auto-close timer run out (not for milestones, which stay).
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
    expect(find.text('Đã lưu. Chỉ mình bạn thấy.'), findsOneWidget);
    expect(find.byKey(const ValueKey('checkin-milestone')), findsNothing);

    // No milestone: closes by itself back to the camera.
    await finishSuccess(tester);
    expect(find.byKey(const ValueKey('stub-capture')), findsOneWidget);
  });

  group('first check-in notification offer (B-B2)', () {
    testWidgets('the auto-close does not pop the offer sheet', (tester) async {
      final gateway = FakeNotificationGateway();
      await pump(
        tester,
        overrides: [notificationGatewayProvider.overrideWithValue(gateway)],
      );
      await tapPost(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notification-sheet')), findsOneWidget);

      // Reading the sheet for longer than the success delay keeps it up.
      await tester.pump(CheckinSuccessView.autoCloseDelay * 3);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notification-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('checkin-success')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('notification-later')));
      await tester.pumpAndSettle();
      await finishSuccess(tester);
      expect(find.byKey(const ValueKey('stub-capture')), findsOneWidget);
    });

    testWidgets('a slow OS answer still schedules, without a ref error', (
      tester,
    ) async {
      final answer = Completer<bool>();
      final gateway = _SlowGateway(answer.future);
      await pump(
        tester,
        overrides: [notificationGatewayProvider.overrideWithValue(gateway)],
      );
      await tapPost(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notification-turn-on')));
      await tester.pumpAndSettle();
      expect(gateway.requests, 1);

      // The OS dialog is still up long after the success delay.
      await tester.pump(CheckinSuccessView.autoCloseDelay * 2);
      expect(find.byKey(const ValueKey('checkin-success')), findsOneWidget);

      answer.complete(true);
      await tester.pumpAndSettle();
      await finishSuccess(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('stub-capture')), findsOneWidget);
      expect(gateway.granted, isTrue);
    });
  });

  testWidgets('streak goes +1 on success (FR-C8)', (tester) async {
    checkIns.existing.addAll([
      testCheckIn(const LocalDate(2026, 10, 14)),
      testCheckIn(const LocalDate(2026, 10, 15)),
    ]);
    await pump(tester);
    await tapPost(tester);
    final view = tester.widget<CheckinSuccessView>(
      find.byType(CheckinSuccessView),
    );
    expect(view.haptics, isTrue);
    final streak = tester.widget<UiStreakNumber>(find.byType(UiStreakNumber));
    expect(streak.value, 3);
    expect(find.byKey(const ValueKey('checkin-streak')), findsOneWidget);
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

  testWidgets('caption field is a 48dp tap target (U5)', (tester) async {
    await pump(tester);
    final size = tester.getSize(find.byKey(const ValueKey('checkin-caption')));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('U21: weight-loss caption hint does not repeat the mood '
      'question', (tester) async {
    await pump(tester);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('checkin-caption')),
    );
    final hint = field.decoration!.hintText!;
    expect(hint, isNot(contains('cảm thấy')));
  });

  group('caption limit (FR-C4)', () {
    final counter = find.byKey(const ValueKey('checkin-caption-counter'));

    testWidgets('counter shows only from 120 characters', (tester) async {
      await pump(tester);
      expect(counter, findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('checkin-caption')),
        'a' * 119,
      );
      await tester.pump();
      expect(counter, findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('checkin-caption')),
        'a' * 120,
      );
      await tester.pump();
      expect(counter, findsOneWidget);
      expect(find.text('120/140'), findsOneWidget);
    });

    testWidgets('stops at 140 characters, counter turns to danger', (
      tester,
    ) async {
      await pump(tester);
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
      expect(tester.widget<Text>(counter).style!.color, OurneyUi.light.danger);
    });

    testWidgets('screen readers always get the count', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      final node = tester.getSemantics(
        find.byKey(const ValueKey('checkin-caption')),
      );
      expect(node.hint, contains('Đã nhập 0 trên 140 ký tự'));
      handle.dispose();
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

  group('caption field style', () {
    testWidgets('rounded, filled, 1.5dp border, accent focus, no label', (
      tester,
    ) async {
      await pump(tester);
      final deco = tester
          .widget<TextField>(find.byKey(const ValueKey('checkin-caption')))
          .decoration!;
      final rest = deco.enabledBorder! as OutlineInputBorder;
      expect(rest.borderRadius, BorderRadius.circular(16));
      expect(rest.borderSide.width, 1.5);
      final ui = Theme.of(
        tester.element(find.byKey(const ValueKey('checkin-caption'))),
      ).extension<OurneyUi>()!;
      expect(deco.fillColor, ui.fill);
      final focus = deco.focusedBorder! as OutlineInputBorder;
      expect(focus.borderSide.width, 2);
      // The placeholder is the label: no text above the field.
      expect(find.text('Chú thích'), findsNothing);
      expect(deco.hintText, isNotEmpty);
    });
  });

  group('keyboard collapses the photo', () {
    testWidgets('photo becomes a 72x96 thumbnail beside the caption', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('checkin-photo-thumb')), findsNothing);
      final fullPhoto = tester.getSize(
        find.byKey(const ValueKey('checkin-retake')),
      );
      expect(fullPhoto.height, greaterThanOrEqualTo(48));
      await tester.enterText(
        find.byKey(const ValueKey('checkin-caption')),
        'Hello',
      );

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final thumb = find.byKey(const ValueKey('checkin-photo-thumb'));
      expect(thumb, findsOneWidget);
      expect(tester.getSize(thumb), const Size(72, 96));
      expect(find.byKey(const ValueKey('checkin-retake')), findsNothing);
      // Caption keeps its text and sits to the right of the thumbnail.
      final caption = tester.widget<TextField>(
        find.byKey(const ValueKey('checkin-caption')),
      );
      expect(caption.controller!.text, 'Hello');
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('checkin-caption'))).dx,
        greaterThan(tester.getTopRight(thumb).dx),
      );
      // Post stays reachable on top of the keyboard.
      expect(find.byKey(const ValueKey('checkin-post')), findsOneWidget);

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('checkin-photo-thumb')), findsNothing);
      expect(find.byKey(const ValueKey('checkin-retake')), findsOneWidget);
    });
  });

  group('extra photos the same day (FR-C7/C8, bug #2)', () {
    testWidgets('posts at once, adds photo 2, does not count the day twice', (
      tester,
    ) async {
      checkIns.existing.add(testCheckIn(testToday));
      await pump(tester);
      await tapPost(tester);
      expect(
        find.byKey(const ValueKey('checkin-replace-dialog')),
        findsNothing,
      );
      await tester.pump();

      expect(checkIns.submitted, hasLength(1));
      expect(find.text('Đã thêm ảnh thứ 2'), findsOneWidget);
      expect(find.text('+1 ngày'), findsNothing);
      await finishSuccess(tester);
    });

    testWidgets('third photo of the day says photo 3', (tester) async {
      checkIns.existing
        ..add(testCheckIn(testToday))
        ..add(testCheckIn(testToday));
      await pump(tester);
      await tapPost(tester);
      await tester.pump();
      expect(checkIns.submitted, hasLength(1));
      expect(find.text('Đã thêm ảnh thứ 3'), findsOneWidget);
      await finishSuccess(tester);
    });

    testWidgets('a check-in yesterday is the first photo of today', (
      tester,
    ) async {
      checkIns.existing.add(testCheckIn(testToday.addDays(-1)));
      await pump(tester);
      await tapPost(tester);
      expect(checkIns.submitted, hasLength(1));
      expect(find.textContaining('Đã thêm ảnh thứ'), findsNothing);
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

    testWidgets('the metric field starts from the last logged value (B-B1)', (
      tester,
    ) async {
      journeys = FakeJourneyRepository(
        journeys: [
          testJourney(
            templateId: TemplateId.weightLoss,
            metricName: 'Cân nặng',
            metricUnit: 'kg',
          ),
        ],
      );
      await pump(
        tester,
        // What the camera passes: the last logged weight as a fallback.
        extra: CapturedPhoto(
          journeyId: 'j1',
          path: '/tmp/shot.jpg',
          capturedAt: testNowUtc,
          initialMetricValue: 65.2,
        ),
      );
      final field = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('checkin-metric')),
          matching: find.byType(EditableText),
          matchRoot: true,
        ),
      );
      expect(field.controller.text, '65.2');
      await tester.enterText(
        find.byKey(const ValueKey('checkin-metric')),
        '62',
      );
      await tapPost(tester);
      expect(checkIns.submitted.single.metricValue, 62);
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
    testWidgets('7-day streak: milestone title and share offer', (
      tester,
    ) async {
      checkIns.existing.addAll([
        for (var i = 1; i <= 6; i++) testCheckIn(testToday.addDays(-i)),
      ]);
      await pump(tester);
      await tapPost(tester);

      expect(find.text('7 ngày liên tục!'), findsOneWidget);

      await tester.pump(CheckinSuccessView.autoCloseDelay);
      // A milestone does not auto-close.
      expect(find.byKey(const ValueKey('checkin-success')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('checkin-share')));
      await tester.tap(find.byKey(const ValueKey('checkin-share')));
      // The success view is replaced by /share.
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
    });

    testWidgets('reduce motion: the milestone still shows', (tester) async {
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
      expect(find.byKey(const ValueKey('checkin-share')), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  testWidgets('haptics toggle off: the success view gets no haptic', (
    tester,
  ) async {
    await pump(tester, prefsValues: {HapticsEnabled.prefsKey: false});
    await tapPost(tester);
    final view = tester.widget<CheckinSuccessView>(
      find.byType(CheckinSuccessView),
    );
    expect(view.haptics, isFalse);
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

  group('compose + posted (kit UI)', () {
    for (final brightness in Brightness.values) {
      testWidgets('${brightness.name}: compose fits 320dp at 1.35x text', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.35;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester, brightness: brightness);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('checkin-retake')), findsOneWidget);
        expect(find.byKey(const ValueKey('checkin-post')), findsOneWidget);
        expect(find.text('Chỉ mình bạn'), findsOneWidget);
        for (final key in ['checkin-retake', 'checkin-post']) {
          final size = tester.getSize(find.byKey(ValueKey(key)));
          expect(size.height, greaterThanOrEqualTo(44), reason: key);
        }
      });

      testWidgets('${brightness.name}: posted fits 320dp at 1.35x text', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.35;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester, brightness: brightness);
        await tapPost(tester);
        expect(find.byKey(const ValueKey('checkin-success')), findsOneWidget);
        expect(find.byKey(const ValueKey('checkin-streak')), findsOneWidget);
        expect(find.textContaining('NGÀY '), findsOneWidget);
        expect(tester.takeException(), isNull);
        await finishSuccess(tester);
      });
    }

    testWidgets('Retake closes back to the camera', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('checkin-retake')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('stub-capture')), findsOneWidget);
    });
  });
}

class _SlowGateway extends FakeNotificationGateway {
  _SlowGateway(this.answer);

  final Future<bool> answer;

  @override
  Future<bool> requestPermission() async {
    requests++;
    granted = await answer;
    return granted;
  }
}
