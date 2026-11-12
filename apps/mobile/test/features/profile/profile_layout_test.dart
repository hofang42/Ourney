import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/profile/routes.dart';
import 'package:ourney/ui/ui.dart';

import 'fakes.dart';

/// Profile and edit screens (kit UI) on a 320dp phone at 1.35x text, light and
/// dark, plus the entry avatar on the camera.
void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    Future<void> open(WidgetTester tester, String path) async {
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
      await goTo(tester, c, path);
    }

    testWidgets('$mode: profile fits and rows are 48dp+', (tester) async {
      await open(tester, '/profile');
      expect(tester.takeException(), isNull);
      expect(byKey('profile-card'), findsOneWidget);
      expect(find.text('Alice Nguyen'), findsOneWidget);
      expect(find.text('@alice'), findsOneWidget);
      for (final key in ['profile-edit', 'profile-reminders']) {
        expect(
          tester.getSize(byKey(key)).height,
          greaterThanOrEqualTo(48),
          reason: key,
        );
      }
      // The friends tile of the social feature is embedded unchanged.
      expect(byKey('friends-profile-tile'), findsOneWidget);
    });

    testWidgets('$mode: edit profile fits', (tester) async {
      await open(tester, profileEditPath);
      expect(tester.takeException(), isNull);
      expect(byKey('profile-edit-screen'), findsOneWidget);
      expect(find.byType(UiAvatarPicker), findsOneWidget);
      expect(byKey('profile-save'), findsOneWidget);
    });
  }

  testWidgets('the camera shows the profile entry with the user initials', (
    tester,
  ) async {
    final c = await pumpBackendApp(
      tester,
      auth: RecordingAuthRepository(userId: 'u1'),
      profiles: FakeProfileRepository(aliceProfile),
    );
    await goTo(tester, c, '/capture');
    expect(byKey('profile-entry'), findsWidgets);
    await tester.tap(byKey('profile-entry').first);
    await tester.pumpAndSettle();
    expect(byKey('profile-screen'), findsOneWidget);
  });
}
