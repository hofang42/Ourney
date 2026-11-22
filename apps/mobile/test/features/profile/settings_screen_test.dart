import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/locale_override.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/profile/settings_providers.dart';

import '../../app/test_helpers.dart' show pumpOurneyApp;
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

      await tester.ensureVisible(byKey('settings-theme-dark'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('settings-theme-dark'));
      await tester.pump();
      expect(c.read(themeModeProvider), ThemeMode.dark);

      await tester.ensureVisible(byKey('settings-lang-en'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('settings-lang-en'));
      await tester.pump();
      expect(c.read(localeOverrideProvider), const Locale('en'));

      // The app-icon picker is gone (it never did anything).
      expect(byKey('settings-icon-default'), findsNothing);

      // Haptics moved here from Profile.
      await tester.ensureVisible(byKey('settings-haptics'));
      await tester.pumpAndSettle();
      final before = c.read(hapticsEnabledProvider);
      await tester.tap(byKey('settings-haptics'));
      await tester.pump();
      expect(c.read(hapticsEnabledProvider), !before);

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

  group('settings structure', () {
    testWidgets('named groups in order, account id, sign out and delete', (
      tester,
    ) async {
      final c = await pumpBackendApp(
        tester,
        auth: RecordingAuthRepository(userId: 'u1'),
        profiles: FakeProfileRepository(aliceProfile),
      );
      await goTo(tester, c, '/profile/settings');
      expect(byKey('settings-account-id'), findsOneWidget);
      expect(find.text('me@example.com'), findsOneWidget);
      final headings = [
        'tài khoản',
        'nhắc nhở',
        'giao diện & ngôn ngữ',
        'riêng tư & an toàn',
        'thông tin',
      ];
      var lastY = -1.0;
      for (final h in headings) {
        final f = find.text(h, skipOffstage: false);
        expect(f, findsOneWidget, reason: h);
        final y = tester.getTopLeft(f).dy;
        expect(y, greaterThan(lastY), reason: h);
        lastY = y;
      }
      expect(byKey('settings-version'), findsOneWidget);
      for (final key in ['settings-signout', 'settings-delete']) {
        await tester.ensureVisible(byKey(key));
        expect(byKey(key), findsOneWidget);
        expect(tester.getSize(byKey(key)).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('local-only has no account, sign out or delete', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester);
      await goTo(tester, c, '/profile/settings');
      expect(byKey('settings-account-id'), findsNothing);
      expect(byKey('settings-signout'), findsNothing);
      expect(byKey('settings-delete'), findsNothing);
      expect(byKey('settings-haptics'), findsOneWidget);
    });
  });

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
}
