import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/profile/routes.dart';
import 'package:ourney/ui/ui.dart';

import 'fakes.dart';

void main() {
  group('profile setup (V1.0 UI)', () {
    testWidgets('shows the kit form and saves display name + username', (
      tester,
    ) async {
      final profiles = FakeProfileRepository();
      final c = await pumpBackendApp(
        tester,
        auth: RecordingAuthRepository(userId: 'u1'),
        profiles: profiles,
      );
      await goTo(tester, c, profileSetupPath);
      expect(byKey('profile-setup-screen'), findsOneWidget);
      expect(find.byType(UiAvatarPicker), findsOneWidget);
      expect(find.text('Hồ sơ của bạn'), findsOneWidget);

      await tester.enterText(byKey('profile-display-name'), 'Linh Tran');
      await tester.enterText(byKey('profile-username'), 'linh.tran');
      await tester.pumpAndSettle();
      // Valid username gets the green check.
      expect(find.byIcon(Icons.check_rounded), findsWidgets);

      await tester.ensureVisible(byKey('profile-save'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('profile-save'));
      await tester.pumpAndSettle();
      expect(profiles.calls, ['upsertMe:linh.tran:Linh Tran']);
      expect(location(c), AppRoutes.capture);
    });

    for (final dark in [false, true]) {
      testWidgets(
        'no overflow at 2x text on 320dp, ${dark ? 'dark' : 'light'}',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          tester.view.physicalSize = const Size(320 * 3, 640 * 3);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          final c = await pumpBackendApp(
            tester,
            auth: RecordingAuthRepository(userId: 'u1'),
            profiles: FakeProfileRepository(),
          );
          await goTo(tester, c, profileSetupPath);
          await tester.tap(byKey('profile-save'), warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
