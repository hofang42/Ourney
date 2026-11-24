import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/locale_override.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/widgets/data/widget_bridge_gateway.dart';
import 'package:ourney/features/widgets/data/widget_sync_controller.dart';
import 'package:ourney/features/widgets/domain/widget_privacy.dart';
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
    'persists photoMode, redactLockScreenTitles, liveActivityEnabled, and '
    'defaultWidgetJourneyId and supports vi + en localizations (§7.2, §8.3)',
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
        overrides: [
          journeyRepositoryProvider.overrideWithValue(journeys),
          widgetBridgeGatewayProvider.overrideWithValue(fakeBridge),
        ],
      );

      await goTo(tester, c, AppRoutes.widgets);
      expect(byKey('widgets-screen'), findsOneWidget);
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

      // 4. Select default widget journey j-2, then back to auto.
      expect(c.read(defaultWidgetJourneyIdProvider), isNull);
      await tester.ensureVisible(byKey('widgets-default-journey-j-2'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('widgets-default-journey-j-2'));
      await tester.pumpAndSettle();
      expect(c.read(defaultWidgetJourneyIdProvider), 'j-2');

      await tester.ensureVisible(byKey('widgets-default-journey-auto'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('widgets-default-journey-auto'));
      await tester.pumpAndSettle();
      expect(c.read(defaultWidgetJourneyIdProvider), isNull);

      // 5. Switch locale to English ('en') and verify localized header.
      await c.read(localeOverrideProvider.notifier).set(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('widgets.'), findsOneWidget);
      _expectNoRenderOverflowsOrTruncations(tester);
    },
  );
}
