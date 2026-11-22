import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/auth/phone_format.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../profile/fakes.dart';

Future<void> tapVisible(WidgetTester tester, String key) async {
  await tester.ensureVisible(byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  group('phone formatting', () {
    test('normalises Vietnamese numbers to E.164', () {
      expect(toE164Vietnam('0912 345 678'), '+84912345678');
      expect(toE164Vietnam('+84 912 345 678'), '+84912345678');
      expect(toE164Vietnam('912345678'), '+84912345678');
      expect(toE164Vietnam('12345'), isNull);
      expect(toE164Vietnam(''), isNull);
      expect(formatPhoneForDisplay('+84912345678'), '+84 912 345 678');
    });
  });

  group('sign-in methods (FR-A1 v2)', () {
    testWidgets('phone tab: validates, sends SMS, verifies the code', (
      tester,
    ) async {
      final auth = RecordingAuthRepository();
      final c = await pumpBackendApp(tester, auth: auth, phoneAvailable: true);
      await tester.tap(byKey('auth-tab-phone'));
      await tester.pumpAndSettle();

      await tester.enterText(byKey('auth-phone'), '123');
      await tapVisible(tester, 'auth-send');
      expect(auth.calls, isEmpty);
      expect(byKey('auth-step-phoneCode'), findsOneWidget);

      await tester.enterText(byKey('auth-phone'), '0912 345 678');
      await tapVisible(tester, 'auth-send');
      expect(auth.calls, ['sendPhoneOtp:+84912345678']);
      expect(byKey('auth-step-code'), findsOneWidget);

      await tester.enterText(byKey('auth-code'), '123456');
      await tester.pumpAndSettle();
      expect(auth.calls.last, 'verifyPhoneOtp:+84912345678:123456');
      expect(location(c), isNot(AppRoutes.auth));
    });

    testWidgets('email + password sign-in', (tester) async {
      final auth = RecordingAuthRepository();
      final c = await pumpBackendApp(tester, auth: auth);
      await tapVisible(tester, 'auth-use-password');
      expect(byKey('auth-password'), findsOneWidget);

      await tester.enterText(byKey('auth-email'), 'A@b.co');
      await tester.enterText(byKey('auth-password'), 'hunter2hunter2');
      await tapVisible(tester, 'auth-send');
      expect(auth.calls, ['signIn:a@b.co']);
      expect(location(c), isNot(AppRoutes.auth));
    });

    testWidgets('wrong password shows a mapped error', (tester) async {
      final auth = RecordingAuthRepository()
        ..signInError = const OurneyException(OurneyErrorCode.invalid);
      await pumpBackendApp(tester, auth: auth);
      await tapVisible(tester, 'auth-use-password');
      await tester.enterText(byKey('auth-email'), 'a@b.co');
      await tester.enterText(byKey('auth-password'), 'wrongwrong');
      await tapVisible(tester, 'auth-send');
      expect(
        find.text('Sai mật khẩu. Thử lại hoặc đăng nhập bằng mã.'),
        findsOneWidget,
      );
    });

    testWidgets('forgot password: code + new password', (tester) async {
      final auth = RecordingAuthRepository();
      await pumpBackendApp(tester, auth: auth);
      await tapVisible(tester, 'auth-use-password');
      await tapVisible(tester, 'auth-forgot');
      await tester.enterText(byKey('auth-email'), 'a@b.co');
      await tapVisible(tester, 'auth-send');
      expect(auth.calls, ['sendReset:a@b.co']);
      expect(byKey('auth-new-password'), findsOneWidget);

      await tester.enterText(byKey('auth-code'), '123456');
      await tester.pumpAndSettle();
      // Not verified until the new password is long enough.
      expect(auth.calls, ['sendReset:a@b.co']);
      await tester.enterText(byKey('auth-new-password'), 'brandnewpass');
      await tapVisible(tester, 'auth-verify');
      expect(auth.calls.last, 'reset:a@b.co:123456');
    });

    testWidgets('phone option is hidden when the server has phone off', (
      tester,
    ) async {
      await pumpBackendApp(tester, auth: RecordingAuthRepository());
      expect(byKey('auth-tab-phone'), findsNothing);
      expect(byKey('auth-tab-email'), findsNothing);
      expect(byKey('auth-email'), findsOneWidget);
    });

    testWidgets('phone option shows when the server has phone on', (
      tester,
    ) async {
      await pumpBackendApp(
        tester,
        auth: RecordingAuthRepository(),
        phoneAvailable: true,
      );
      expect(byKey('auth-tab-phone'), findsOneWidget);
      expect(byKey('auth-tab-email'), findsOneWidget);
    });

    testWidgets('start screen: subtitle visible, no create-account link', (
      tester,
    ) async {
      await pumpBackendApp(tester, auth: RecordingAuthRepository());
      expect(byKey('auth-subtitle'), findsOneWidget);
      await tapVisible(tester, 'auth-use-password');
      expect(byKey('auth-create-account'), findsNothing);
      expect(byKey('auth-forgot'), findsOneWidget);
      await tester.tap(byKey('auth-flow-back'));
      await tester.pumpAndSettle();
      expect(byKey('auth-step-email'), findsOneWidget);
    });

    testWidgets('SMS provider off: clear message, Phone disappears', (
      tester,
    ) async {
      final auth = RecordingAuthRepository()
        ..phoneError = const OurneyException(OurneyErrorCode.unavailable);
      await pumpBackendApp(tester, auth: auth, phoneAvailable: true);
      await tester.tap(byKey('auth-tab-phone'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('auth-phone'), '0912 345 678');
      await tapVisible(tester, 'auth-send');
      expect(
        find.text(
          'Đăng nhập bằng SMS tạm thời chưa dùng được. Dùng email nhé.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('9–10 số'), findsNothing);
      expect(byKey('auth-tab-phone'), findsNothing);
      expect(byKey('auth-email'), findsOneWidget);
    });

    testWidgets('code step after phone shows the SMS helper', (tester) async {
      await pumpBackendApp(
        tester,
        auth: RecordingAuthRepository(),
        phoneAvailable: true,
      );
      await tester.tap(byKey('auth-tab-phone'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('auth-phone'), '0912 345 678');
      await tapVisible(tester, 'auth-send');
      expect(find.textContaining('SMS'), findsWidgets);
      expect(find.textContaining('Thư rác'), findsNothing);
    });

    for (final dark in [false, true]) {
      testWidgets('${dark ? 'dark' : 'light'}: start fits at 320dp 1.35x', (
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
        await pumpBackendApp(
          tester,
          auth: RecordingAuthRepository(),
          phoneAvailable: true,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(byKey('auth-tab-phone'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no Google button anywhere', (tester) async {
      await pumpBackendApp(tester, auth: RecordingAuthRepository());
      expect(find.textContaining('Google'), findsNothing);
    });
  });

  group('UiButton sanity', () {
    testWidgets('primary action is enabled on the default form', (
      tester,
    ) async {
      await pumpBackendApp(tester, auth: RecordingAuthRepository());
      expect(
        tester.widget<UiFlowButton>(byKey('auth-send')).onPressed,
        isNotNull,
      );
    });
  });
}
