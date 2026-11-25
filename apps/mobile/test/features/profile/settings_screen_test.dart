import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/locale_override.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/auth/auth_providers.dart';
import 'package:ourney/features/profile/settings_providers.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart'
    show OurneyErrorCode, OurneyException;

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

          // Haptics moved here from Profile.
          await tester.ensureVisible(byKey('settings-haptics'));
          await tester.pumpAndSettle();
          final before = c.read(hapticsEnabledProvider);
          await tester.tap(byKey('settings-haptics'));
          await tester.pump();
          expect(c.read(hapticsEnabledProvider), !before);

          // App-icon picker renders all 8 V2 icon variants.
          expect(byKey('settings-app-icons'), findsOneWidget);
          expect(byKey('settings-icon-default'), findsOneWidget);

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
    testWidgets('named groups in order, account id, app icons, sign out and delete', (
      tester,
    ) async {
      final c = await pumpBackendApp(
        tester,
        auth: RecordingAuthRepository(userId: 'u1'),
        profiles: FakeProfileRepository(aliceProfile),
      );
      await goTo(tester, c, '/profile/settings');
      expect(tester.takeException(), isNull);
      expect(byKey('settings-screen'), findsOneWidget);
      expect(byKey('settings-account-id'), findsOneWidget);
      expect(find.text('me@example.com'), findsOneWidget);
      final headings = [
        'tài khoản',
        'bảo mật',
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

      // The selected app icon carries a check badge, not just a border (U14),
      // and all 8 preview tiles render >= 48x48dp targets.
      await tester.ensureVisible(byKey('settings-app-icons'));
      await tester.pumpAndSettle();
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
      expect(byKey('settings-password'), findsNothing);
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
        // Phone-only account shows read-only SMS explanation row in Bảo mật.
        expect(byKey('settings-password'), findsOneWidget);
        expect(find.text('Mật khẩu'), findsOneWidget);
        expect(
          find.text('Tài khoản số điện thoại đăng nhập bằng mã SMS'),
          findsOneWidget,
        );
        expect(
          tester.widget<UiRow>(byKey('settings-password')).onPressed,
          isNull,
        );
      },
    );
  });

  group('settings security / password (Bảo mật)', () {
    testWidgets(
      'first-time set password (hasPassword=false): recovery-code flow, leaves other devices signed in, flips row to Đổi mật khẩu',
      (tester) async {
        final auth = RecordingAuthRepository(
          userId: 'u1',
          hasPasswordValue: false,
        );
        final c = await pumpBackendApp(
          tester,
          auth: auth,
          profiles: FakeProfileRepository(aliceProfile),
        );
        await goTo(tester, c, '/profile/settings');

        expect(byKey('settings-password'), findsOneWidget);
        expect(find.text('Đặt mật khẩu'), findsOneWidget);
        expect(
          find.text('Tùy chọn — bạn vẫn luôn đăng nhập được bằng mã 6 số'),
          findsOneWidget,
        );

        await tester.ensureVisible(byKey('settings-password'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('settings-password'));
        await tester.pumpAndSettle();

        expect(byKey('profile-password-sheet'), findsOneWidget);
        expect(find.text('đặt mật khẩu.'), findsOneWidget);
        // R-5: Step 1 CTA shows 'Tiếp tục' when no code has been verified yet.
        expect(
          tester.widget<UiButton>(byKey('password-sheet-continue')).label,
          'Tiếp tục',
        );
        // First-time set does NOT offer sign-out-others switch.
        expect(byKey('password-sheet-sign-out-others'), findsNothing);

        // Short password rejected client-side without calling sendPasswordReset.
        await tester.enterText(byKey('password-sheet-new'), 'short');
        await tester.tap(byKey('password-sheet-continue'));
        await tester.pumpAndSettle();
        expect(find.text('Mật khẩu cần ít nhất 8 ký tự.'), findsOneWidget);
        expect(auth.calls, isEmpty);

        // Send failure shows password-specific send error (never profile save error).
        auth.sendOtpError = const OurneyException(OurneyErrorCode.internal);
        await tester.enterText(byKey('password-sheet-new'), 'strongpass123');
        await tester.tap(byKey('password-sheet-continue'));
        await tester.pumpAndSettle();
        expect(
          find.text('Chưa gửi được mã xác minh. Thử lại nhé.'),
          findsOneWidget,
        );
        expect(find.textContaining('Không lưu được hồ sơ'), findsNothing);

        // Valid password sends 6-digit recovery code and advances to Step 2.
        auth.sendOtpError = null;
        await tester.tap(byKey('password-sheet-continue'));
        await tester.pumpAndSettle();
        expect(
          auth.calls,
          ['sendReset:me@example.com', 'sendReset:me@example.com'],
        );
        expect(find.text('xác minh bằng mã.'), findsOneWidget);
        expect(byKey('password-sheet-otp'), findsOneWidget);

        // Entering 6 digits submits updatePassword with code and signOutOthers=false.
        await tester.enterText(byKey('password-sheet-otp'), '654321');
        await tester.pumpAndSettle();
        expect(
          auth.calls.last,
          'updatePassword:strongpass123:code=654321:signOutOthers=false',
        );
        expect(byKey('profile-password-sheet'), findsNothing);
        expect(c.read(hasPasswordProvider), isTrue);
        expect(
          c
              .read(sharedPreferencesProvider)
              .getBool(AuthMethodPrefs.hasPasswordKeyFor('u1')),
          isTrue,
        );
        expect(
          c
              .read(sharedPreferencesProvider)
              .getString(AuthMethodPrefs.lastMethodKey),
          RememberedAuthMethod.password.wireName,
        );
        // Settings row now displays "Đổi mật khẩu".
        expect(find.text('Đổi mật khẩu'), findsOneWidget);
      },
    );

    testWidgets(
      'change password (hasPassword=true): recovery-code flow, sign-out-others default ON and toggleable, wrong code clears OTP, same_password keeps verified session without burning a second email',
      (tester) async {
        final auth = RecordingAuthRepository(
          userId: 'u1',
          hasPasswordValue: true,
        );
        final c = await pumpBackendApp(
          tester,
          auth: auth,
          profiles: FakeProfileRepository(aliceProfile),
        );
        await goTo(tester, c, '/profile/settings');
        await tester.pumpAndSettle();

        expect(find.text('Đổi mật khẩu'), findsOneWidget);
        expect(
          find.text('Đang bật song song với mã đăng nhập 6 số'),
          findsOneWidget,
        );

        await tester.ensureVisible(byKey('settings-password'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('settings-password'));
        await tester.pumpAndSettle();

        expect(find.text('đổi mật khẩu.'), findsOneWidget);
        expect(byKey('password-sheet-sign-out-others'), findsOneWidget);
        expect(
          tester
              .widget<UiSwitchRow>(byKey('password-sheet-sign-out-others'))
              .value,
          isTrue,
        );

        await tester.enterText(byKey('password-sheet-new'), 'rotatedpass99');
        await tester.tap(byKey('password-sheet-continue'));
        await tester.pumpAndSettle();
        expect(auth.calls, ['sendReset:me@example.com']);

        // 1. Wrong/expired recovery code clears OTP field and shows inline error.
        auth.updatePasswordError = const OurneyException(
          OurneyErrorCode.invalid,
          '400 (otp_expired): Token has expired or is invalid',
        );
        await tester.enterText(byKey('password-sheet-otp'), '111111');
        await tester.pumpAndSettle();
        expect(
          find.text('Mã chưa đúng hoặc đã hết hạn. Kiểm tra lại nhé.'),
          findsOneWidget,
        );
        expect(byKey('password-sheet-otp'), findsOneWidget);
        expect(
          tester.widget<UiOtpField>(byKey('password-sheet-otp')).controller.text,
          isEmpty,
        );

        // Generic server error on save shows password-specific save error.
        auth.updatePasswordError = const OurneyException(
          OurneyErrorCode.internal,
        );
        await tester.enterText(byKey('password-sheet-otp'), '121212');
        await tester.pumpAndSettle();
        expect(
          find.text('Chưa lưu được mật khẩu. Thử lại nhé.'),
          findsOneWidget,
        );
        expect(find.textContaining('Không lưu được hồ sơ'), findsNothing);

        // Resend is disabled during 60s cooldown, enabled after cooldown expires,
        // and announces confirmation in a liveRegion.
        expect(
          tester.widget<UiTextAction>(byKey('password-sheet-resend')).onPressed,
          isNull,
        );
        await tester.pump(const Duration(seconds: 60));
        expect(
          tester.widget<UiTextAction>(byKey('password-sheet-resend')).onPressed,
          isNotNull,
        );
        await tester.tap(byKey('password-sheet-resend'));
        await tester.pumpAndSettle();
        expect(find.text('Đã gửi mã mới.'), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('Đã gửi mã mới.'),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && (w.properties.liveRegion ?? false),
            ),
          ),
          findsOneWidget,
        );

        // 2. same_password returns to Step 1 while keeping the verified session.
        auth.updatePasswordError = const OurneyException(
          OurneyErrorCode.invalid,
          '422 (same_password): New password should be different',
        );
        await tester.enterText(byKey('password-sheet-otp'), '222222');
        await tester.pumpAndSettle();
        expect(
          find.text('Mật khẩu mới cần khác mật khẩu hiện tại.'),
          findsOneWidget,
        );
        expect(byKey('password-sheet-new'), findsOneWidget);
        // R-5: Once _verifiedCode is set, Step 1 CTA shows 'Lưu mật khẩu'.
        expect(
          tester.widget<UiButton>(byKey('password-sheet-continue')).label,
          'Lưu mật khẩu',
        );

        // Client-side validation rejects submitting the known same password again
        // without making any network call.
        final callsBeforeSameRetry = auth.calls.length;
        await tester.tap(byKey('password-sheet-continue'));
        await tester.pumpAndSettle();
        expect(
          find.text('Mật khẩu mới cần khác mật khẩu hiện tại.'),
          findsOneWidget,
        );
        expect(auth.calls, hasLength(callsBeforeSameRetry));

        // 3. Entering a different password saves directly on the kept verified
        // session without burning a second email or showing Step 2 again.
        auth.updatePasswordError = null;
        await tester.enterText(byKey('password-sheet-new'), 'brandnewpass99');
        await tester.tap(byKey('password-sheet-continue'));
        await tester.pumpAndSettle();
        expect(auth.calls, hasLength(callsBeforeSameRetry + 1));
        expect(
          auth.calls.last,
          'updatePassword:brandnewpass99:code=222222:signOutOthers=true',
        );
        expect(byKey('profile-password-sheet'), findsNothing);

        // 4. Re-open: test R-4 (_backToPassword preserves 60s cooldown so fixing a typo
        // on Step 1 returns to Step 2 without sending a duplicate email) and R-2 (cancel
        // calls cancelPasswordFlow).
        await tester.tap(byKey('settings-password'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('password-sheet-sign-out-others'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<UiSwitchRow>(byKey('password-sheet-sign-out-others'))
              .value,
          isFalse,
        );
        await tester.enterText(byKey('password-sheet-new'), 'anotherpass99');
        await tester.tap(byKey('password-sheet-continue'));
        await tester.pumpAndSettle();
        final sendCountAfterStep1 = auth.calls
            .where((c) => c.startsWith('sendReset:'))
            .length;

        // Tap Back on Step 2 -> edit password typo on Step 1 -> tap Continue within 60s cooldown.
        await tester.tap(byKey('password-sheet-back'));
        await tester.pumpAndSettle();
        expect(byKey('password-sheet-new'), findsOneWidget);
        await tester.enterText(byKey('password-sheet-new'), 'correctedpass99');
        await tester.tap(byKey('password-sheet-continue'));
        await tester.pumpAndSettle();
        expect(byKey('password-sheet-otp'), findsOneWidget);
        expect(
          auth.calls.where((c) => c.startsWith('sendReset:')).length,
          sendCountAfterStep1,
          reason: 'R-4: submitting Step 1 during active cooldown must not re-send recovery email',
        );
        expect(
          tester.widget<UiTextAction>(byKey('password-sheet-resend')).onPressed,
          isNull,
          reason: 'R-4: 60s resend cooldown stays active across _backToPassword',
        );

        await tester.enterText(byKey('password-sheet-otp'), '444444');
        await tester.pumpAndSettle();
        expect(
          auth.calls.last,
          'updatePassword:correctedpass99:code=444444:signOutOthers=false',
        );

        // 5. Re-open and cancel -> invokes cancelPasswordFlow (R-2).
        final cancelsBefore = auth.cancelPasswordFlowCalls;
        await tester.tap(byKey('settings-password'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('password-sheet-cancel'));
        await tester.pumpAndSettle();
        expect(
          auth.cancelPasswordFlowCalls,
          greaterThan(cancelsBefore),
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

  group('DE-12: privacy toggles sync ON and OFF', () {
    testWidgets(
      'toggling Hide kg and Blur photos ON then OFF syncs both true and false '
      'to server memberships',
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
