import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/locale_override.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/profile/settings_providers.dart';
import 'package:ourney/ui/ui.dart';

import '../../app/test_helpers.dart' show pumpOurneyApp, testBackendConfig;
import '../journeys/journeys_fakes.dart' show FakeJourneyRepository, testJourney;
import 'fakes.dart';

void _expectNoTruncatedSegments(WidgetTester tester) {
  for (final seg in tester.widgetList(find.byType(UiSegmented<ThemeMode>))) {
    final texts = find.descendant(
      of: find.byWidget(seg),
      matching: find.byType(RichText),
    );
    for (final e in texts.evaluate()) {
      final ro = e.renderObject;
      if (ro is RenderParagraph) {
        expect(
          ro.didExceedMaxLines,
          isFalse,
          reason: 'truncated theme segment: ${ro.text.toPlainText()}',
        );
      }
    }
  }
  for (final seg in tester.widgetList(find.byType(UiSegmented<String>))) {
    final texts = find.descendant(
      of: find.byWidget(seg),
      matching: find.byType(RichText),
    );
    for (final e in texts.evaluate()) {
      final ro = e.renderObject;
      if (ro is RenderParagraph) {
        expect(
          ro.didExceedMaxLines,
          isFalse,
          reason: 'truncated lang segment: ${ro.text.toPlainText()}',
        );
      }
    }
  }
}

/// Figma Settings: theme + language pickers, privacy switches, at
/// 320dp / 1.35x and 2.0x text in light and dark.
void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.35, 2.0]) {
      testWidgets(
        '${dark ? 'dark' : 'light'}: settings fits without truncation at '
        '320dp ${scale}x and is wired (M4)',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          tester.platformDispatcher.textScaleFactorTestValue = scale;
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
          _expectNoTruncatedSegments(tester);
          await tester.tap(byKey('settings-theme-dark'));
          await tester.pump();
          expect(c.read(themeModeProvider), ThemeMode.dark);

          await tester.ensureVisible(byKey('settings-lang-en'));
          await tester.pumpAndSettle();
          await tester.tap(byKey('settings-lang-en'));
          await tester.pumpAndSettle();
          expect(c.read(localeOverrideProvider), const Locale('en'));
          // Verify English labels ("System", "English") also never truncate at 320dp.
          _expectNoTruncatedSegments(tester);

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
        },
      );
    }
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

    testWidgets(
      'formats raw phone identifier, merges read-only row semantics, and '
      'labels language group (L3)',
      (tester) async {
        final auth = RecordingAuthRepository(userId: 'u1')
          ..identifier = '84912345678';
        final c = await pumpBackendApp(
          tester,
          auth: auth,
          profiles: FakeProfileRepository(aliceProfile),
        );
        await goTo(tester, c, '/profile/settings');
        expect(byKey('settings-account-id'), findsOneWidget);
        expect(find.text('+84 912 345 678'), findsOneWidget);
        expect(
          find.ancestor(
            of: byKey('settings-account-id'),
            matching: find.byType(MergeSemantics),
          ),
          findsOneWidget,
        );
        expect(
          find.ancestor(
            of: byKey('settings-version'),
            matching: find.byType(MergeSemantics),
          ),
          findsOneWidget,
        );
        // Empty appVersionProvider in tests omits the trailing Text node.
        expect(
          tester.widget<UiRow>(byKey('settings-version')).trailing,
          isNull,
        );
        expect(
          find.ancestor(
            of: find.byType(UiSegmented<String>),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.label == 'NGÔN NGỮ',
            ),
          ),
          findsOneWidget,
        );
      },
    );
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

    testWidgets('asks first; cancel keeps the session (L1 copy)', (
      tester,
    ) async {
      final (auth, _) = await open(tester);
      expect(byKey('profile-signout-dialog'), findsOneWidget);
      expect(find.textContaining('bằng tài khoản này'), findsOneWidget);
      expect(find.textContaining('bằng email'), findsNothing);
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

  group('DE-12 & DE-15: privacy toggles sync ON and OFF; no app-icon picker', () {
    testWidgets(
      'toggling Hide kg and Blur photos ON then OFF syncs both true and false '
      'to server memberships, and no app-icon picker tiles exist',
      (tester) async {
        final journeys = FakeJourneyRepository(
          journeys: [
            testJourney(id: 'j-kg', metricName: 'Cân nặng', metricUnit: 'kg'),
            testJourney(
              id: 'j-min',
              metricName: 'Thời gian',
              metricUnit: 'phút',
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
            mediaStoreProvider.overrideWithValue(FakeMediaStore()),
          ],
        );
        await goTo(tester, c, '/profile/settings');

        // DE-15: none of the 7 app-icon picker tiles or checkmarks exist.
        for (final iconKey in const [
          'settings-icon-default',
          'settings-icon-quiet',
          'settings-icon-squad',
          'settings-icon-memory',
          'settings-icon-couple',
          'settings-icon-flexer',
          'settings-icon-minimal',
          'settings-icon-check',
        ]) {
          expect(byKey(iconKey), findsNothing, reason: iconKey);
        }

        // 1. Toggle Hide kg ON -> pushes hideMetric: true to j-kg.
        await tester.scrollUntilVisible(
          byKey('settings-hide-kg'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(byKey('settings-hide-kg'));
        await tester.pumpAndSettle();
        expect(c.read(hideWeightOnShareProvider), isTrue);
        expect(
          [for (final u in journeys.prefUpdates) (u.id, u.hideMetric)],
          [('j-kg', true)],
        );

        // 2. Toggle Hide kg OFF -> pushes hideMetric: false to j-kg (DE-12).
        journeys.prefUpdates.clear();
        await tester.tap(byKey('settings-hide-kg'));
        await tester.pumpAndSettle();
        expect(c.read(hideWeightOnShareProvider), isFalse);
        expect(
          [for (final u in journeys.prefUpdates) (u.id, u.hideMetric)],
          [('j-kg', false)],
        );

        // 3. Toggle Blur photos ON -> pushes blurMedia: true to all journeys.
        journeys.prefUpdates.clear();
        await tester.ensureVisible(byKey('settings-blur-photos'));
        await tester.tap(byKey('settings-blur-photos'));
        await tester.pumpAndSettle();
        expect(c.read(blurPhotosOnShareProvider), isTrue);
        expect(
          {for (final u in journeys.prefUpdates) u.id: u.blurMedia},
          {'j-kg': true, 'j-min': true},
        );

        // 4. Toggle Blur photos OFF -> pushes blurMedia: false to all journeys.
        journeys.prefUpdates.clear();
        await tester.tap(byKey('settings-blur-photos'));
        await tester.pumpAndSettle();
        expect(c.read(blurPhotosOnShareProvider), isFalse);
        expect(
          {for (final u in journeys.prefUpdates) u.id: u.blurMedia},
          {'j-kg': false, 'j-min': false},
        );
      },
    );
  });
}
