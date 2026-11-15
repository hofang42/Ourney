import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/locale_override.dart';
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
}
