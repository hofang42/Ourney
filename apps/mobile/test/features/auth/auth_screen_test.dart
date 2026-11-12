import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/auth/auth_errors.dart';
import 'package:ourney/features/auth/auth_screen.dart';
import 'package:ourney/features/auth/l10n/generated/auth_localizations_en.dart';
import 'package:ourney/features/profile/routes.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../profile/fakes.dart';

Future<void> enterEmail(WidgetTester tester, String email) async {
  await tester.enterText(byKey('auth-email'), email);
  await tester.ensureVisible(byKey('auth-send'));
  await tester.pumpAndSettle();
  await tester.tap(byKey('auth-send'));
  await tester.pumpAndSettle();
}

void main() {
  group('auth screen (FR-A1)', () {
    testWidgets('signed out with a backend goes to /auth', (tester) async {
      final c = await pumpBackendApp(tester, auth: RecordingAuthRepository());
      expect(location(c), AppRoutes.auth);
      expect(byKey('auth-step-email'), findsOneWidget);
    });

    testWidgets('rejects a malformed email without calling the server', (
      tester,
    ) async {
      final auth = RecordingAuthRepository();
      await pumpBackendApp(tester, auth: auth);
      await enterEmail(tester, 'not-an-email');
      expect(find.text('Email này chưa đúng định dạng.'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('email -> code step, cooldown, resend', (tester) async {
      final auth = RecordingAuthRepository();
      await pumpBackendApp(tester, auth: auth);
      await enterEmail(tester, '  Alice@Example.com ');
      expect(auth.calls, ['sendOtp:alice@example.com']);
      expect(byKey('auth-step-code'), findsOneWidget);

      UiTextAction resend() =>
          tester.widget<UiTextAction>(byKey('auth-resend'));
      Future<void> wait(int seconds) async {
        for (var i = 0; i < seconds; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
      }

      // Resend is blocked for the 60 s cooldown, with a countdown label.
      expect(resend().onPressed, isNull);
      expect(find.textContaining('59'), findsNothing);
      await wait(1);
      expect(find.textContaining('59'), findsOneWidget);
      await wait(58);
      expect(resend().onPressed, isNull);
      await wait(2);
      expect(resend().onPressed, isNotNull);

      await tester.tap(byKey('auth-resend'));
      await tester.pump();
      expect(auth.calls, hasLength(2));
      expect(byKey('auth-step-code'), findsOneWidget);
      expect(resend().onPressed, isNull);

      await tester.tap(byKey('auth-change-email'));
      await tester.pumpAndSettle();
      expect(byKey('auth-step-email'), findsOneWidget);
    });

    testWidgets('wrong code shows a mapped error and stays', (tester) async {
      final auth = RecordingAuthRepository()
        ..verifyOtpError = const OurneyException(OurneyErrorCode.invalid);
      final c = await pumpBackendApp(tester, auth: auth);
      await enterEmail(tester, 'a@b.co');
      await tester.enterText(byKey('auth-code'), '123456');
      await tester.pumpAndSettle();
      expect(auth.calls.last, 'verifyOtp:a@b.co:123456');
      expect(byKey('auth-error'), findsOneWidget);
      expect(location(c), AppRoutes.auth);
    });

    testWidgets('rate limit on send is shown', (tester) async {
      final auth = RecordingAuthRepository()
        ..sendOtpError = const OurneyException(OurneyErrorCode.rateLimited);
      await pumpBackendApp(tester, auth: auth);
      await enterEmail(tester, 'a@b.co');
      expect(byKey('auth-error'), findsOneWidget);
      expect(byKey('auth-step-email'), findsOneWidget);
    });

    testWidgets('first sign-in continues to profile setup', (tester) async {
      final auth = RecordingAuthRepository();
      final c = await pumpBackendApp(
        tester,
        auth: auth,
        profiles: FakeProfileRepository(),
      );
      await goTo(tester, c, '${AppRoutes.auth}?from=%2Fjourneys');
      await enterEmail(tester, 'a@b.co');
      await tester.enterText(byKey('auth-code'), '654321');
      await tester.pumpAndSettle();
      expect(
        location(c),
        Uri(
          path: profileSetupPath,
          queryParameters: {AppRoutes.fromParam: AppRoutes.journeys},
        ).toString(),
      );
      expect(byKey('profile-setup-screen'), findsOneWidget);
    });

    testWidgets('returning user lands on the from target', (tester) async {
      final auth = RecordingAuthRepository();
      final c = await pumpBackendApp(
        tester,
        auth: auth,
        profiles: FakeProfileRepository(aliceProfile),
      );
      await enterEmail(tester, 'a@b.co');
      await tester.enterText(byKey('auth-code'), '654321');
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.capture);
    });

    testWidgets('no overflow at 2x text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpBackendApp(tester, auth: RecordingAuthRepository());
      expect(tester.takeException(), isNull);
      await enterEmail(tester, 'someone.with.a.long.address@example.com');
      expect(tester.takeException(), isNull);
      expect(byKey('auth-step-code'), findsOneWidget);
    });
  });

  group('authErrorMessage', () {
    final l10n = AuthL10nEn();
    String msg(OurneyErrorCode code, AuthStep step) =>
        authErrorMessage(l10n, OurneyException(code), step);

    test('maps codes per step', () {
      expect(
        msg(OurneyErrorCode.rateLimited, AuthStep.sendOtp),
        l10n.auth_errorRateLimited,
      );
      expect(
        msg(OurneyErrorCode.offline, AuthStep.verifyOtp),
        l10n.auth_errorOffline,
      );
      expect(
        msg(OurneyErrorCode.invalid, AuthStep.sendOtp),
        l10n.auth_emailInvalid,
      );
      expect(
        msg(OurneyErrorCode.invalid, AuthStep.verifyOtp),
        l10n.auth_errorWrongCode,
      );
      expect(
        msg(OurneyErrorCode.unauthenticated, AuthStep.verifyOtp),
        l10n.auth_errorWrongCode,
      );
      expect(
        msg(OurneyErrorCode.internal, AuthStep.sendOtp),
        l10n.auth_errorGeneric,
      );
      expect(
        authErrorMessage(l10n, StateError('x'), AuthStep.sendOtp),
        l10n.auth_errorGeneric,
      );
    });

    test('resend cooldown is a minute', () {
      expect(AuthScreen.resendCooldown, 60);
    });
  });
}
