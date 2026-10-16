import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';

import '../../app/test_helpers.dart';
import '../profile/fakes.dart';

void main() {
  group('onboarding (FR-A3)', () {
    testWidgets('three pages, then lands on capture (local-only)', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester, onboarded: false);
      expect(location(c), AppRoutes.onboarding);
      expect(byKey('onboarding-page-0'), findsOneWidget);
      expect(find.bySemanticsLabel('Trang 1 trên 3'), findsOneWidget);

      await tester.tap(byKey('onboarding-next'));
      await tester.pumpAndSettle();
      expect(byKey('onboarding-page-1'), findsOneWidget);

      await tester.tap(byKey('onboarding-next'));
      await tester.pumpAndSettle();
      expect(byKey('onboarding-page-2'), findsOneWidget);
      // Skip disappears on the last page; the CTA finishes.
      expect(byKey('onboarding-skip'), findsNothing);
      expect(find.text('Bắt đầu'), findsOneWidget);

      await tester.tap(byKey('onboarding-next'));
      await tester.pumpAndSettle();
      expect(c.read(onboardingCompleteProvider), isTrue);
      expect(location(c), AppRoutes.capture);
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

    testWidgets('no overflow at 2x text in English', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpOurneyApp(tester, onboarded: false, locale: const Locale('en'));
      for (var i = 0; i < 3; i++) {
        expect(tester.takeException(), isNull);
        await tester.tap(byKey('onboarding-next'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  });
}
