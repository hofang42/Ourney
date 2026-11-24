import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/locale_override.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/profile/settings_providers.dart';

import 'fakes.dart';

/// Figma Settings: theme + language pickers, privacy switches, app icon, at
/// 320dp / 1.35x text in light and dark.
void main() {
  for (final dark in [false, true]) {
    testWidgets('${dark ? 'dark' : 'light'}: settings fits and is wired', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.textScaleFactorTestValue = 1.35;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final c = await pumpBackendApp(
        tester,
        auth: RecordingAuthRepository(userId: 'u1'),
        profiles: FakeProfileRepository(aliceProfile),
      );
      await goTo(tester, c, '/profile/settings');
      expect(tester.takeException(), isNull);
      expect(byKey('settings-screen'), findsOneWidget);

      await tester.tap(byKey('settings-theme-dark'));
      await tester.pump();
      expect(c.read(themeModeProvider), ThemeMode.dark);

      await tester.tap(byKey('settings-lang-en'));
      await tester.pump();
      expect(c.read(localeOverrideProvider), const Locale('en'));

      // The selected app icon carries a check badge, not just a border (U14),
      // and all 8 preview tiles render >= 48x48dp targets.
      expect(
        find.descendant(
          of: byKey('settings-icon-default'),
          matching: byKey('settings-icon-check'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: byKey('settings-app-icons'),
          matching: find.byType(Image),
        ),
        findsNWidgets(8),
      );
      for (final id in AppIconController.ids) {
        final size = tester.getSize(byKey('settings-icon-$id'));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }

      await tester.scrollUntilVisible(
        byKey('settings-hide-kg'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(byKey('settings-hide-kg'));
      await tester.pump();
      expect(c.read(hideWeightOnShareProvider), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  group('settings sign out (C-B6 / U6)', () {
    Future<(RecordingAuthRepository, ProviderContainer)> open(
      WidgetTester tester,
    ) async {
      final auth = RecordingAuthRepository(userId: 'u1');
      final c = await pumpBackendApp(
        tester,
        auth: auth,
        profiles: FakeProfileRepository(aliceProfile),
      );
      await goTo(tester, c, '/profile/settings');
      await tester.ensureVisible(byKey('settings-signout'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('settings-signout'));
      await tester.pumpAndSettle();
      return (auth, c);
    }

    testWidgets('asks first; cancel keeps the session', (tester) async {
      final (auth, _) = await open(tester);
      expect(byKey('profile-signout-dialog'), findsOneWidget);
      expect(auth.calls, isEmpty);
      await tester.tap(byKey('profile-signout-cancel'));
      await tester.pumpAndSettle();
      expect(auth.calls, isEmpty);
      expect(byKey('settings-screen'), findsOneWidget);
    });

    testWidgets('the sheet ignores a barrier tap', (tester) async {
      final (auth, _) = await open(tester);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(byKey('profile-signout-dialog'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('confirm signs out and leaves for /auth', (tester) async {
      final (auth, c) = await open(tester);
      await tester.tap(byKey('profile-signout-confirm'));
      await tester.pumpAndSettle();
      expect(auth.calls, ['signOut']);
      expect(location(c), startsWith(AppRoutes.auth));
    });

    testWidgets('a failing sign out shows an error, no crash', (tester) async {
      final (auth, _) = await open(tester);
      auth.signOutError = StateError('offline');
      await tester.tap(byKey('profile-signout-confirm'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(auth.calls, ['signOut']);
      expect(byKey('settings-screen'), findsOneWidget);
    });
  });

  group('app icon picker & channel (ourney/app_icon)', () {
    testWidgets(
      'persists selection, calls ourney/app_icon channel with right names, and moves check badge',
      (tester) async {
        final calls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(PlatformAppIconSwitcher.channel, (
              call,
            ) async {
              calls.add(call);
              return true;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(PlatformAppIconSwitcher.channel, null),
        );

        final c = await pumpBackendApp(
          tester,
          auth: RecordingAuthRepository(userId: 'u1'),
          profiles: FakeProfileRepository(aliceProfile),
        );
        await goTo(tester, c, '/profile/settings');

        expect(byKey('settings-app-icons'), findsOneWidget);
        expect(byKey('settings-app-icon-note'), findsOneWidget);

        // Tap 'yellow' -> AppIcon-Yellow / .IconYellow
        await tester.ensureVisible(byKey('settings-icon-yellow'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('settings-icon-yellow'));
        await tester.pumpAndSettle();

        expect(c.read(appIconProvider), 'yellow');
        expect(
          c.read(sharedPreferencesProvider).getString(AppIconController.prefsKey),
          'yellow',
        );
        expect(
          find.descendant(
            of: byKey('settings-icon-yellow'),
            matching: byKey('settings-icon-check'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: byKey('settings-icon-default'),
            matching: byKey('settings-icon-check'),
          ),
          findsNothing,
        );
        expect(calls, hasLength(1));
        expect(calls.last.method, 'setAlternateIcon');
        expect(calls.last.arguments, {
          'id': 'yellow',
          'iosIconName': 'AppIcon-Yellow',
          'androidAlias': '.IconYellow',
        });

        // Tap 'dark' -> AppIcon-Dark / .IconDark
        await tester.ensureVisible(byKey('settings-icon-dark'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('settings-icon-dark'));
        await tester.pumpAndSettle();

        expect(c.read(appIconProvider), 'dark');
        expect(
          c.read(sharedPreferencesProvider).getString(AppIconController.prefsKey),
          'dark',
        );
        expect(calls, hasLength(2));
        expect(calls.last.arguments, {
          'id': 'dark',
          'iosIconName': 'AppIcon-Dark',
          'androidAlias': '.IconDark',
        });

        // Tap 'default' -> nil / .IconDefault
        await tester.ensureVisible(byKey('settings-icon-default'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('settings-icon-default'));
        await tester.pumpAndSettle();

        expect(c.read(appIconProvider), 'default');
        expect(
          c.read(sharedPreferencesProvider).getString(AppIconController.prefsKey),
          'default',
        );
        expect(calls, hasLength(3));
        expect(calls.last.arguments, {
          'id': 'default',
          'iosIconName': null,
          'androidAlias': '.IconDefault',
        });

        // Unknown icon id is rejected without calling the channel.
        final ok = await c.read(appIconProvider.notifier).set('unknown-id');
        expect(ok, isFalse);
        expect(c.read(appIconProvider), 'default');
        expect(calls, hasLength(3));
      },
    );

    testWidgets(
      'gracefully hides app icon picker on unsupported platforms (desktop)',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          final c = await pumpBackendApp(
            tester,
            auth: RecordingAuthRepository(userId: 'u1'),
            profiles: FakeProfileRepository(aliceProfile),
          );
          await goTo(tester, c, '/profile/settings');
          expect(tester.takeException(), isNull);
          expect(byKey('settings-screen'), findsOneWidget);
          expect(byKey('settings-app-icons'), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
