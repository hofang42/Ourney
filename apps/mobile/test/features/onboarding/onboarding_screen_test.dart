import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/locale_override.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/onboarding/permission_sheets.dart';

import '../../app/test_helpers.dart';
import '../profile/fakes.dart';

void main() {
  group('onboarding (FR-A3, V1.0)', () {
    testWidgets('three pages, then lands on capture (local-only)', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester, onboarded: false);
      expect(location(c), AppRoutes.onboarding);
      expect(byKey('onboarding-page-0'), findsOneWidget);
      expect(find.text('Từng tấm ảnh. Cả một câu chuyện.'), findsOneWidget);
      expect(find.bySemanticsLabel('Trang 1 trên 3'), findsOneWidget);
      // Page 1 carries the language chip.
      expect(byKey('onboarding-language'), findsOneWidget);

      await tester.tap(byKey('onboarding-next'));
      await tester.pumpAndSettle();
      expect(byKey('onboarding-page-1'), findsOneWidget);
      expect(byKey('onboarding-language'), findsNothing);

      await tester.tap(byKey('onboarding-next'));
      await tester.pumpAndSettle();
      expect(byKey('onboarding-page-2'), findsOneWidget);
      expect(
        find.text('Biến hành trình thành thứ đáng để chia sẻ.'),
        findsOneWidget,
      );
      expect(c.read(onboardingCompleteProvider), isFalse);

      await tester.tap(byKey('onboarding-next'));
      await tester.pumpAndSettle();
      expect(c.read(onboardingCompleteProvider), isTrue);
      expect(location(c), AppRoutes.capture);
    });

    testWidgets('language chip switches the app to English and persists', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester, onboarded: false);
      expect(find.text('English'), findsOneWidget);
      await tester.tap(byKey('onboarding-language'));
      await tester.pumpAndSettle();
      expect(c.read(localeOverrideProvider), const Locale('en'));
      expect(find.text('One photo at a time. A whole story.'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
    });

    testWidgets('skip completes and continues to sign-in with a backend', (
      tester,
    ) async {
      final c = await pumpBackendApp(
        tester,
        auth: RecordingAuthRepository(),
        onboarded: false,
      );
      expect(location(c), AppRoutes.onboarding);
      await tester.tap(byKey('onboarding-skip'));
      await tester.pumpAndSettle();
      expect(c.read(onboardingCompleteProvider), isTrue);
      expect(location(c), startsWith(AppRoutes.auth));
      expect(byKey('auth-screen'), findsOneWidget);
    });

    testWidgets('keeps the deep-link target in ?from=', (tester) async {
      final c = await pumpOurneyApp(tester, onboarded: false);
      await goTo(tester, c, AppRoutes.journeys);
      expect(location(c), startsWith(AppRoutes.onboarding));
      await tester.tap(byKey('onboarding-skip'));
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.journeys);
    });

    testWidgets('swiping changes page; reduced motion still advances', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpOurneyApp(tester, onboarded: false);
      await tester.tap(byKey('onboarding-next'));
      await tester.pumpAndSettle();
      expect(byKey('onboarding-page-1'), findsOneWidget);
      await tester.fling(
        byKey('onboarding-page-1'),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(byKey('onboarding-page-2'), findsOneWidget);
    });

    for (final dark in [false, true]) {
      testWidgets('no overflow at 1.35x and 2x text on small and large phones, '
          '${dark ? 'dark' : 'light'}', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.view.reset);
        for (final scale in [1.35, 2.0]) {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          for (final size in const [Size(320, 640), Size(390, 844)]) {
            tester.view.physicalSize = size * 3;
            tester.view.devicePixelRatio = 3;
            await tester.pumpWidget(const SizedBox());
            await pumpOurneyApp(tester, onboarded: false);
            for (var i = 0; i < 3; i++) {
              expect(tester.takeException(), isNull, reason: '$scale $size');
              if (i < 2) {
                await tester.tap(byKey('onboarding-next'));
                await tester.pumpAndSettle();
              }
            }
          }
        }
      });
    }
  });

  group('permission sheets', () {
    Future<void> open(
      WidgetTester tester,
      Future<bool> Function(BuildContext) show,
      void Function(bool) onResult,
    ) async {
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open'),
              onPressed: () async => onResult(await show(context)),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(byKey('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('camera sheet resolves true on Allow', (tester) async {
      bool? result;
      await open(tester, showCameraPermissionSheet, (v) => result = v);
      expect(find.text('Cho phép dùng camera'), findsOneWidget);
      await tester.tap(byKey('camera-permission-allow'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('camera sheet resolves false on Not now', (tester) async {
      bool? result;
      await open(tester, showCameraPermissionSheet, (v) => result = v);
      await tester.tap(byKey('camera-permission-later'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('notification sheet names the reminder time', (tester) async {
      bool? result;
      await open(
        tester,
        (c) => showNotificationSheet(c, timeLabel: '21:00'),
        (v) => result = v,
      );
      expect(find.text('Nhắc bạn lúc 21:00 ngày mai nhé?'), findsOneWidget);
      await tester.tap(byKey('notification-turn-on'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });
}
