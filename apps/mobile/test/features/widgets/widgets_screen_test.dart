import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/locale_override.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/groups/data/groups_providers.dart'
    show groupCheckInsProvider, groupTodayProvider;
import 'package:ourney/features/widgets/data/widget_bridge_gateway.dart';
import 'package:ourney/features/widgets/data/widget_sync_controller.dart';
import 'package:ourney/features/widgets/domain/widget_privacy.dart';
import 'package:ourney/ui/components/ourney_icons.dart' show OurneyIcon;
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../journeys/journeys_fakes.dart' show FakeJourneyRepository, testJourney;
import '../profile/fakes.dart';

void _expectNoRenderOverflowsOrTruncations(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  // Zero default Material Icons or CupertinoIcons anywhere on the screen (CLAUDE.md §1.3).
  expect(find.byType(Icon), findsNothing);
}

void main() {
  testWidgets(
    'iOS shows a localized notice when widget data is unavailable',
    (tester) async {
      final bridge = FakeWidgetBridgeGateway(
        capabilities: WidgetCapabilities.fromMap({
          'widgets': true,
          'liveActivity': true,
          'appGroupAvailable': false,
          'appGroup': true,
        }),
      );
      final c = await pumpOurneyApp(
        tester,
        overrides: [widgetBridgeGatewayProvider.overrideWithValue(bridge)],
      );

      await c.read(localeOverrideProvider.notifier).set(const Locale('vi'));
      await goTo(tester, c, AppRoutes.widgets);
      expect(
        find.text(
          'Bản cài này chưa cho widget đọc dữ liệu. Widget sẽ hoạt động ở bản '
          'TestFlight/App Store hoặc khi cài qua AltStore/SideStore.',
        ),
        findsOneWidget,
      );

      await c.read(localeOverrideProvider.notifier).set(const Locale('en'));
      await tester.pumpAndSettle();
      final englishNotice = find.text(
        'This install can’t share data with widgets. Widgets will work with the '
        'TestFlight or App Store version, or when installed through AltStore or SideStore.',
      );
      expect(englishNotice, findsOneWidget);
      expect(byKey('widgets-live-activity-toggle'), findsOneWidget);

      bridge.capabilities = const WidgetCapabilities(
        widgets: true,
        liveActivity: true,
        promotedLiveUpdates: false,
        appGroup: true,
      );
      c.invalidate(widgetCapabilitiesProvider);
      await tester.pumpAndSettle();
      expect(englishNotice, findsNothing);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'iOS shows and copies recent widget diagnostics and refreshes on reopen',
    (tester) async {
      const log = '2026-11-26T01:00:00Z OurneyTodayWidget timeline ready';
      final bridge = FakeWidgetBridgeGateway()..widgetDiagnostics = [log];
      String? copied;
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final c = await pumpOurneyApp(
        tester,
        overrides: [widgetBridgeGatewayProvider.overrideWithValue(bridge)],
      );
      await c.read(localeOverrideProvider.notifier).set(const Locale('en'));
      await goTo(tester, c, AppRoutes.widgets);

      final heading = find.text('Widget diagnostics');
      expect(find.text(log), findsNothing);
      expect(find.text('Copy log'), findsNothing);
      await tester.tap(heading);
      await tester.pumpAndSettle();
      expect(find.text(log), findsOneWidget);
      await tester.tap(find.text('Copy log'));
      await tester.pumpAndSettle();
      expect(copied, log);

      await tester.tap(heading);
      await tester.pumpAndSettle();
      bridge.widgetDiagnostics = const [];
      await c.read(localeOverrideProvider.notifier).set(const Locale('vi'));
      await tester.pumpAndSettle();
      expect(find.text(log), findsNothing);
      await tester.tap(find.text('Chẩn đoán tiện ích'));
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa ghi nhận sự kiện nào của tiện ích.'),
        findsOneWidget,
      );
      expect(find.text('Sao chép nhật ký'), findsNothing);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0, 430.0]) {
      testWidgets(
        '${dark ? 'dark' : 'light'} at ${width.toInt()}dp 1.35x: WidgetsScreen '
        'renders preview gallery, setup steps, and toggles cleanly (§8.3)',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          tester.platformDispatcher.textScaleFactorTestValue = 1.35;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          tester.view.physicalSize = Size(width * 2, 844 * 2);
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);

          final fakeBridge = FakeWidgetBridgeGateway();
          final journeys = FakeJourneyRepository(
            journeys: [
              testJourney(
                id: 'j-1',
                title: 'Tự học IELTS 30 ngày',
                durationDays: null,
              ),
              testJourney(
                id: 'j-2',
                title: 'Giảm cân 60 ngày',
                templateId: TemplateId.weightLoss,
                hideMetricDefault: true,
                durationDays: null,
              ),
            ],
          );

          final c = await pumpOurneyApp(
            tester,
            config: testBackendConfig,
            auth: RecordingAuthRepository(userId: 'u1'),
            overrides: [
              profileRepositoryProvider.overrideWithValue(
                FakeProfileRepository(aliceProfile),
              ),
              journeyRepositoryProvider.overrideWithValue(journeys),
              widgetBridgeGatewayProvider.overrideWithValue(fakeBridge),
            ],
          );

          // Navigate from Settings -> Widgets & Live Activities row.
          await goTo(tester, c, '/profile/settings');
          await tester.ensureVisible(byKey('settings-widgets'));
          await tester.pumpAndSettle();
          await tester.tap(byKey('settings-widgets'));
          await tester.pumpAndSettle();

          expect(location(c), AppRoutes.widgets);
          expect(byKey('widgets-screen'), findsOneWidget);
          _expectNoRenderOverflowsOrTruncations(tester);

          // Preview gallery tabs: Today -> Streak -> Squad.
          expect(byKey('widgets-preview-today-surface'), findsOneWidget);
          await tester.tap(byKey('widgets-preview-tab-streak'));
          await tester.pumpAndSettle();
          expect(byKey('widgets-preview-streak-surface'), findsOneWidget);
          _expectNoRenderOverflowsOrTruncations(tester);

          await tester.tap(byKey('widgets-preview-tab-squad'));
          await tester.pumpAndSettle();
          expect(byKey('widgets-preview-squad-surface'), findsOneWidget);
          _expectNoRenderOverflowsOrTruncations(tester);
        },
      );
    }
  }

  testWidgets(
    'persists privacy and Live Activity settings without a journey picker',
    (tester) async {
      final fakeBridge = FakeWidgetBridgeGateway();
      final journeys = FakeJourneyRepository(
        journeys: [
          testJourney(
            id: 'j-1',
            title: 'Tự học IELTS 30 ngày',
            durationDays: null,
          ),
          testJourney(
            id: 'j-2',
            title: 'Chạy bộ buổi sáng',
            durationDays: null,
          ),
        ],
      );

      final c = await pumpOurneyApp(
        tester,
        initialPrefs: const {'widgets.defaultJourneyId': 'j-2'},
        overrides: [
          journeyRepositoryProvider.overrideWithValue(journeys),
          widgetBridgeGatewayProvider.overrideWithValue(fakeBridge),
        ],
      );

      await goTo(tester, c, AppRoutes.widgets);
      expect(byKey('widgets-screen'), findsOneWidget);
      expect(byKey('widgets-default-journey-auto'), findsNothing);
      expect(byKey('widgets-default-journey-j-2'), findsNothing);
      expect(find.text('tiện ích.'), findsOneWidget);

      // 1. Photo mode defaults to smart; switch to blurred, off, clear.
      expect(c.read(widgetPhotoModeProvider), WidgetPhotoMode.smart);
      await tester.ensureVisible(byKey('widgets-photo-mode-blurred'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('widgets-photo-mode-blurred'));
      await tester.pumpAndSettle();
      expect(c.read(widgetPhotoModeProvider), WidgetPhotoMode.blurred);
      expect(
        c.read(sharedPreferencesProvider).getString(WidgetPrefs.photoMode),
        'blurred',
      );

      await tester.tap(byKey('widgets-photo-mode-off'));
      await tester.pumpAndSettle();
      expect(c.read(widgetPhotoModeProvider), WidgetPhotoMode.off);

      await tester.tap(byKey('widgets-photo-mode-clear'));
      await tester.pumpAndSettle();
      expect(c.read(widgetPhotoModeProvider), WidgetPhotoMode.clear);

      // 2. Toggle Lock Screen title redaction.
      expect(c.read(redactLockScreenTitlesProvider), isFalse);
      await tester.ensureVisible(byKey('widgets-redact-lock-titles'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('widgets-redact-lock-titles'));
      await tester.pumpAndSettle();
      expect(c.read(redactLockScreenTitlesProvider), isTrue);
      expect(
        c
            .read(sharedPreferencesProvider)
            .getBool(WidgetPrefs.redactLockScreenTitles),
        isTrue,
      );

      // 3. Toggle Live Activity off and back on.
      expect(c.read(liveActivityEnabledProvider), isTrue);
      await tester.ensureVisible(byKey('widgets-live-activity-toggle'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('widgets-live-activity-toggle'));
      await tester.pumpAndSettle();
      expect(c.read(liveActivityEnabledProvider), isFalse);
      expect(
        c
            .read(sharedPreferencesProvider)
            .getBool(WidgetPrefs.liveActivityEnabled),
        isFalse,
      );

      await c.read(localeOverrideProvider.notifier).set(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('widgets.'), findsOneWidget);
      expect(
        find.text('2. Search for Ourney in the widget gallery'),
        findsOneWidget,
      );
      expect(find.text('featured widget journey'), findsNothing);
      _expectNoRenderOverflowsOrTruncations(tester);
    },
  );

  testWidgets(
    'Android WidgetsScreen lists placed widgets and updates selection via picker sheet',
    (tester) async {
      final fakeBridge = FakeWidgetBridgeGateway(
        placedWidgets: const [
          PlacedWidgetInfo(
            appWidgetId: 101,
            kind: PlacedWidgetKind.today,
            selectedId: 'auto',
          ),
          PlacedWidgetInfo(
            appWidgetId: 102,
            kind: PlacedWidgetKind.squad,
            selectedId: 'auto',
          ),
        ],
      );
      final journeys = FakeJourneyRepository(
        journeys: [
          testJourney(
            id: 'j-1',
            title: 'Tự học IELTS 30 ngày',
            durationDays: null,
          ),
          testJourney(
            id: 'j-2',
            title: 'Chạy bộ buổi sáng',
            durationDays: null,
          ),
          testJourney(
            id: 'j-squad-1',
            title: 'Nhóm chạy Hồ Tây',
            kind: JourneyKind.group,
            durationDays: null,
          ),
        ],
      );

      final c = await pumpOurneyApp(
        tester,
        overrides: [
          journeyRepositoryProvider.overrideWithValue(journeys),
          widgetBridgeGatewayProvider.overrideWithValue(fakeBridge),
        ],
      );

      await c.read(localeOverrideProvider.notifier).set(const Locale('vi'));
      await goTo(tester, c, AppRoutes.widgets);

      expect(find.text('tiện ích đang đặt'), findsOneWidget);
      expect(byKey('widgets-placed-row-101'), findsOneWidget);
      expect(byKey('widgets-placed-row-102'), findsOneWidget);
      expect(find.text('Ourney · Hôm nay'), findsOneWidget);
      expect(find.text('Ourney · Đồng đội'), findsOneWidget);

      await tester.ensureVisible(byKey('widgets-placed-row-101'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('widgets-placed-row-101'));
      await tester.pumpAndSettle();

      expect(byKey('widget-journey-picker-sheet'), findsOneWidget);
      expect(find.text('Đổi hành trình'), findsOneWidget);
      expect(byKey('widget-picker-option-auto'), findsOneWidget);
      expect(byKey('widget-picker-option-j-2'), findsOneWidget);

      await tester.tap(byKey('widget-picker-option-j-2'));
      await tester.pumpAndSettle();

      expect(fakeBridge.selectionUpdates, [
        (appWidgetId: 101, selectedId: 'j-2'),
      ]);
      expect(
        find.descendant(
          of: byKey('widgets-placed-row-101'),
          matching: find.text('Chạy bộ buổi sáng'),
        ),
        findsOneWidget,
      );
      _expectNoRenderOverflowsOrTruncations(tester);
    },
  );

  testWidgets(
    'iOS WidgetsScreen renders Hôm nay & Chuỗi and Đồng đội & Cặp đôi picker rows and syncs snapshot',
    (tester) async {
      final fakeBridge = FakeWidgetBridgeGateway();
      final journeys = FakeJourneyRepository(
        journeys: [
          testJourney(
            id: 'j-1',
            title: 'Tự học IELTS 30 ngày',
            durationDays: null,
          ),
          testJourney(
            id: 'j-2',
            title: 'Chạy bộ buổi sáng',
            durationDays: null,
          ),
          testJourney(
            id: 'j-couple-1',
            title: 'Đôi mình 365',
            kind: JourneyKind.group,
            maxMembers: 2,
            durationDays: null,
          ),
        ],
      );

      final c = await pumpOurneyApp(
        tester,
        overrides: [
          journeyRepositoryProvider.overrideWithValue(journeys),
          widgetBridgeGatewayProvider.overrideWithValue(fakeBridge),
        ],
      );

      await c.read(localeOverrideProvider.notifier).set(const Locale('vi'));
      await goTo(tester, c, AppRoutes.widgets);

      expect(find.text('đổi hành trình trên tiện ích'), findsOneWidget);
      expect(byKey('widgets-ios-today-journey-row'), findsOneWidget);
      expect(byKey('widgets-ios-squad-journey-row'), findsOneWidget);
      expect(find.text('Hôm nay & Chuỗi'), findsOneWidget);
      expect(find.text('Đồng đội & Cặp đôi'), findsOneWidget);

      // 1. Pick j-2 for Today & Streak
      await tester.ensureVisible(byKey('widgets-ios-today-journey-row'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('widgets-ios-today-journey-row'));
      await tester.pumpAndSettle();

      expect(byKey('widget-journey-picker-sheet'), findsOneWidget);
      await tester.tap(byKey('widget-picker-option-j-2'));
      await tester.pumpAndSettle();

      expect(c.read(defaultWidgetJourneyIdProvider), 'j-2');
      expect(
        c
            .read(sharedPreferencesProvider)
            .getString(WidgetPrefs.defaultJourneyId),
        'j-2',
      );
      expect(
        find.descendant(
          of: byKey('widgets-ios-today-journey-row'),
          matching: find.text('Chạy bộ buổi sáng'),
        ),
        findsOneWidget,
      );

      // 2. Pick j-couple-1 for Squad & Couple
      await tester.ensureVisible(byKey('widgets-ios-squad-journey-row'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('widgets-ios-squad-journey-row'));
      await tester.pumpAndSettle();

      expect(byKey('widget-journey-picker-sheet'), findsOneWidget);
      await tester.tap(byKey('widget-picker-option-j-couple-1'));
      await tester.pumpAndSettle();

      expect(c.read(defaultWidgetSquadIdProvider), 'j-couple-1');
      expect(
        c.read(sharedPreferencesProvider).getString(WidgetPrefs.defaultSquadId),
        'j-couple-1',
      );
      expect(
        find.descendant(
          of: byKey('widgets-ios-squad-journey-row'),
          matching: find.text('Đôi mình 365'),
        ),
        findsOneWidget,
      );
      _expectNoRenderOverflowsOrTruncations(tester);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'UX-26: Day 1 solo journey shows real 0-day streak (no fake 6-day green '
    'strip), and Squad preview shows localized sample when no group journey exists '
    'or real members when a group journey exists',
    (tester) async {
      final now = DateTime.now();
      final today = LocalDate(now.year, now.month, now.day);
      final fakeBridge = FakeWidgetBridgeGateway();
      final soloJourneys = FakeJourneyRepository(
        journeys: [
          testJourney(
            id: 'j-solo-day1',
            title: 'Solo Reading Day 1',
            kind: JourneyKind.solo,
            startDate: today,
            durationDays: 30,
          ),
        ],
      );

      final c = await pumpOurneyApp(
        tester,
        overrides: [
          journeyRepositoryProvider.overrideWithValue(soloJourneys),
          widgetBridgeGatewayProvider.overrideWithValue(fakeBridge),
        ],
      );

      await c.read(localeOverrideProvider.notifier).set(const Locale('en'));
      await goTo(tester, c, AppRoutes.widgets);

      // 1. Today preview for a real Day 1 solo journey with 0 check-ins:
      //    no sample badge, streak is '0', and 0 check icons in the 7-day strip.
      expect(byKey('widgets-preview-sample-badge'), findsNothing);
      expect(
        find.descendant(
          of: byKey('widgets-preview-today-surface'),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      final todayChecks = tester
          .widgetList<OurneyIcon>(
            find.descendant(
              of: byKey('widgets-preview-today-surface'),
              matching: find.byType(OurneyIcon),
            ),
          )
          .where((icon) => icon.name == 'check');
      expect(
        todayChecks,
        isEmpty,
        reason: 'Day 1 journey with 0 check-ins must not render 6 fake checkmarks',
      );

      // 2. Streak preview for the real Day 1 solo journey: shows 0-day streak.
      await tester.tap(byKey('widgets-preview-tab-streak'));
      await tester.pumpAndSettle();
      expect(byKey('widgets-preview-sample-badge'), findsNothing);
      expect(find.text('0-day streak'), findsOneWidget);

      // 3. Squad preview when the user only has a Solo journey:
      //    must NOT overlay the Solo journey's title onto fake squad members;
      //    must show the sample badge, sample title, and localized 'You' (not 'Bạn').
      await tester.tap(byKey('widgets-preview-tab-squad'));
      await tester.pumpAndSettle();
      expect(byKey('widgets-preview-sample-badge'), findsOneWidget);
      expect(
        find.descendant(
          of: byKey('widgets-preview-squad-surface'),
          matching: find.text('30-Day IELTS Study'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: byKey('widgets-preview-squad-surface'),
          matching: find.text('Solo Reading Day 1'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: byKey('widgets-preview-squad-surface'),
          matching: find.text('You'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: byKey('widgets-preview-squad-surface'),
          matching: find.text('Bạn'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'UX-26: Squad preview displays real group journey members and counts when '
    'an active group journey exists',
    (tester) async {
      final now = DateTime.now();
      final today = LocalDate(now.year, now.month, now.day);
      final fakeBridge = FakeWidgetBridgeGateway();
      final groupJourney = testJourney(
        id: 'j-group-1',
        title: 'Morning Coding Squad',
        kind: JourneyKind.group,
        startDate: today,
        durationDays: 30,
      );
      final journeys = FakeJourneyRepository(journeys: [groupJourney]);
      final realMembers = [
        MemberToday(
          userId: 'u-1',
          displayName: 'Alice',
          role: MemberRole.owner,
          currentStreak: 4,
          todayCheckIn: CheckIn(
            id: 'c-alice',
            journeyId: 'j-group-1',
            userId: 'u-1',
            localDate: today,
            capturedAt: DateTime.utc(today.year, today.month, today.day, 8),
            photoPath: 'checkins/j-group-1/u-1/c.jpg',
            thumbPath: 'checkins/j-group-1/u-1/c_t.jpg',
          ),
        ),
        const MemberToday(
          userId: 'u-2',
          displayName: 'Bob',
          role: MemberRole.member,
          currentStreak: 2,
        ),
      ];

      final c = await pumpOurneyApp(
        tester,
        config: testBackendConfig,
        auth: RecordingAuthRepository(userId: 'u-1'),
        overrides: [
          profileRepositoryProvider.overrideWithValue(
            FakeProfileRepository(aliceProfile),
          ),
          journeyRepositoryProvider.overrideWithValue(journeys),
          widgetBridgeGatewayProvider.overrideWithValue(fakeBridge),
          groupTodayProvider('j-group-1').overrideWith(
            (ref) => Stream.value(realMembers),
          ),
          groupCheckInsProvider('j-group-1').overrideWith(
            (ref) => Stream.value(const <CheckIn>[]),
          ),
        ],
      );

      await c.read(localeOverrideProvider.notifier).set(const Locale('en'));
      await goTo(tester, c, AppRoutes.widgets);
      await tester.tap(byKey('widgets-preview-tab-squad'));
      await tester.pumpAndSettle();

      expect(byKey('widgets-preview-sample-badge'), findsNothing);
      expect(
        find.descendant(
          of: byKey('widgets-preview-squad-surface'),
          matching: find.text('Morning Coding Squad'),
        ),
        findsOneWidget,
      );
      expect(find.text('1/2 checked in today'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    },
  );

  testWidgets(
    'UX-40: WidgetsScreen uses platform-correct terminology on Android vs iOS',
    (tester) async {
      try {
        // 1. Android: shows Live Updates & status-bar countdown, no Apple terms.
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final c = await pumpOurneyApp(tester);
        await c.read(localeOverrideProvider.notifier).set(const Locale('en'));
        await goTo(tester, c, AppRoutes.widgets);

        expect(
          find.text('Live Updates & status-bar check-in'),
          findsOneWidget,
        );
        expect(
          find.text(
            'On the Lock Screen, live updates show "Ourney" instead of specific journey names.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('1. Touch and hold your Home Screen'),
          findsOneWidget,
        );
        expect(find.textContaining('Dynamic Island'), findsNothing);
        expect(find.textContaining('Live Activity'), findsNothing);
        expect(find.textContaining('Live Activities'), findsNothing);
        expect(find.textContaining('Lock Screen widgets'), findsNothing);

        // 2. iOS: shows Live Activity & Dynamic Island, no Android launcher terms.
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        await c.read(localeOverrideProvider.notifier).set(const Locale('vi'));
        await tester.pumpAndSettle();
        await c.read(localeOverrideProvider.notifier).set(const Locale('en'));
        await tester.pumpAndSettle();

        expect(
          find.text('Live Activity & check-in window'),
          findsOneWidget,
        );
        expect(
          find.text(
            'On the Lock Screen, widgets and Live Activities show "Ourney" instead of specific journey names.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Dynamic Island'), findsOneWidget);
        expect(find.textContaining('launcher'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
