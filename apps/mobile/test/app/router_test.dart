import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';

import 'test_helpers.dart';

String location(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

void main() {
  group('camera-first shell', () {
    testWidgets('opens on the capture tab (FR-C1), vi by default', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester);
      expect(location(c), AppRoutes.capture);
      expect(find.byKey(const ValueKey('placeholder-camera')), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
      expect(find.text('Nhóm'), findsOneWidget);
      expect(find.text('Journeys'), findsOneWidget);
    });

    testWidgets('falls back to Vietnamese for unsupported locales', (
      tester,
    ) async {
      await pumpOurneyApp(tester, locale: const Locale('fr'));
      expect(find.text('Nhóm'), findsOneWidget);
    });

    testWidgets('English when the device is English', (tester) async {
      await pumpOurneyApp(tester, locale: const Locale('en'));
      expect(find.text('Groups'), findsOneWidget);
    });

    testWidgets('tabs switch between journeys, capture and groups', (
      tester,
    ) async {
      final c = await pumpOurneyApp(
        tester,
        config: testBackendConfig,
        auth: FakeAuthRepository(userId: 'u1'),
      );

      await tester.tap(find.text('Nhóm'));
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.groups);
      expect(find.byKey(const ValueKey('placeholder-groups')), findsOneWidget);

      await tester.tap(find.text('Journeys'));
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.journeys);
      expect(
        find.byKey(const ValueKey('placeholder-journeys')),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.capture);
    });

    testWidgets('local-only: groups tab shows the needs-server state', (
      tester,
    ) async {
      await pumpOurneyApp(tester);
      await tester.tap(find.text('Nhóm'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
      expect(find.text('Cần kết nối máy chủ'), findsOneWidget);
    });
  });

  group('onboarding gate', () {
    testWidgets('first launch goes to onboarding, then to capture', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester, onboarded: false);
      expect(location(c), AppRoutes.onboarding);
      expect(find.byKey(const ValueKey('onboarding-screen')), findsOneWidget);

      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.capture);
      expect(c.read(onboardingCompleteProvider), isTrue);
      expect(
        c.read(sharedPreferencesProvider).getBool(OnboardingComplete.prefsKey),
        isTrue,
      );
    });

    testWidgets('a deep link survives onboarding', (tester) async {
      final c = await pumpOurneyApp(tester, onboarded: false);
      c.read(routerProvider).go('/journey/j-7');
      await tester.pumpAndSettle();
      expect(location(c), startsWith(AppRoutes.onboarding));

      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();
      expect(location(c), '/journey/j-7');
    });
  });

  group('auth gate (backend configured only)', () {
    testWidgets('local-only never shows /auth', (tester) async {
      final c = await pumpOurneyApp(tester);
      c.read(routerProvider).go(AppRoutes.auth);
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.capture);
    });

    testWidgets('signed out goes to /auth; signing in returns', (tester) async {
      final auth = FakeAuthRepository();
      final c = await pumpOurneyApp(
        tester,
        config: testBackendConfig,
        auth: auth,
      );
      expect(location(c), AppRoutes.auth);
      expect(find.byKey(const ValueKey('auth-screen')), findsOneWidget);

      auth.emit('u1');
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.capture);

      auth.emit(null);
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.auth);
    });

    testWidgets('unwired auth repository behaves as signed out', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester, config: testBackendConfig);
      expect(location(c), AppRoutes.auth);
    });

    testWidgets('safety pages are reachable before sign-in', (tester) async {
      final c = await pumpOurneyApp(
        tester,
        config: testBackendConfig,
        auth: FakeAuthRepository(),
      );
      c.read(routerProvider).go(AppRoutes.safety);
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.safety);
    });
  });

  group('deep links', () {
    for (final entry in {
      'ourney://join/ABC123': '/join/ABC123',
      'ourney://journey/j-42': '/journey/j-42',
    }.entries) {
      testWidgets('${entry.key} opens ${entry.value}', (tester) async {
        final router = createRouter(initialLocation: entry.key);
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(await testPrefs()),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: ourneyLocalizationsDelegates,
              supportedLocales: ourneySupportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          entry.value,
        );
      });
    }
  });

  test('createRouter builds without throwing for the full registry', () {
    final GoRouter router = createRouter();
    addTearDown(router.dispose);
    expect(router.configuration.routes, isNotEmpty);
  });
}
