import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app.dart';
import 'package:ourney/app/router.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('app opens on capture tab', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: OurneyApp()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('placeholder-camera')), findsOneWidget);
    // Vietnamese is the default locale.
    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
    expect(find.text('Nhóm'), findsOneWidget);
    expect(find.text('Journeys'), findsOneWidget);
  });

  testWidgets('tabs switch between journeys, capture and groups',
      (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: OurneyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nhóm'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('placeholder-groups')), findsOneWidget);

    await tester.tap(find.text('Journeys'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('placeholder-journeys')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('placeholder-camera')), findsOneWidget);
  });

  group('deep links', () {
    test('normalizeDeepLink maps custom scheme to in-app paths', () {
      expect(
        normalizeDeepLink(Uri.parse('ourney://join/ABC123')),
        '/join/ABC123',
      );
      expect(
        normalizeDeepLink(Uri.parse('ourney://journey/j-42')),
        '/journey/j-42',
      );
      expect(normalizeDeepLink(Uri.parse('/capture')), isNull);
    });

    testWidgets('ourney://join/<code> opens join route', (tester) async {
      final router = createRouter(initialLocation: 'ourney://join/ABC123');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: appLocalizationsForTest,
            supportedLocales: appSupportedLocalesForTest,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/join/ABC123',
      );
    });

    testWidgets('ourney://journey/<id> opens journey route', (tester) async {
      final router = createRouter(initialLocation: 'ourney://journey/j-42');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: appLocalizationsForTest,
            supportedLocales: appSupportedLocalesForTest,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/journey/j-42',
      );
    });
  });
}
