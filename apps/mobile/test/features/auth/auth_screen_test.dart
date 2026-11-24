import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/data/remote/error_mapping.dart';
import 'package:ourney/features/auth/auth_errors.dart';
import 'package:ourney/features/auth/auth_screen.dart';
import 'package:ourney/features/auth/l10n/generated/auth_localizations_en.dart';
import 'package:ourney/features/profile/profile_providers.dart';
import 'package:ourney/features/profile/routes.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../app/test_helpers.dart' show pumpOurneyApp, testBackendConfig;
import '../profile/fakes.dart';

Future<void> enterEmail(WidgetTester tester, String email) async {
  await tester.enterText(byKey('auth-email'), email);
  await tester.ensureVisible(byKey('auth-send'));
  await tester.pumpAndSettle();
  await tester.tap(byKey('auth-send'));
  await tester.pumpAndSettle();
}

/// Delays the initial `watchMe()` emission until [emit] or [emitError] is
/// called, to verify no protected route or RPC runs while the profile check is
/// in flight.
class _DelayedProfileRepository extends FakeProfileRepository {
  _DelayedProfileRepository();

  final StreamController<Profile?> _controller =
      StreamController<Profile?>.broadcast();

  void emit(Profile? value) {
    profile = value;
    _controller.add(value);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  @override
  Stream<Profile?> watchMe() => _controller.stream;
}

class _SpyFriendRepository implements FriendRepository {
  final List<String> acceptedTokens = [];

  @override
  Future<PersonSummary> acceptInvite(String token) async {
    acceptedTokens.add(token);
    throw const OurneyException(OurneyErrorCode.invalid);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyAccountInsightsRepository implements AccountInsightsRepository {
  int saveQuizCalls = 0;
  int fetchQuizCalls = 0;

  @override
  Future<void> saveQuiz(OnboardingQuiz quiz) async {
    saveQuizCalls++;
  }

  @override
  Future<OnboardingQuiz?> fetchQuiz() async {
    fetchQuizCalls++;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
/// Emits the user id, then holds `verifyOtp` open until [release], so the
/// router can unmount `/auth` before the sign-in await returns.
class _SlowVerifyAuth extends RecordingAuthRepository {
  final release = Completer<void>();

  @override
  Future<void> verifyOtp(String email, String code) async {
    await super.verifyOtp(email, code);
    await release.future;
  }
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
      expect(
        find.text('Email chưa đúng dạng. Ví dụ: ten@gmail.com'),
        findsOneWidget,
      );
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

      // Resend is blocked for the 60 s cooldown, with a countdown label that
      // hugs its text beside the ring rather than stretching (L2).
      expect(resend().onPressed, isNull);
      expect(resend().expand, isFalse);
      final screenW = tester.getSize(find.byType(AuthScreen)).width;
      expect(tester.getSize(byKey('auth-resend')).width, lessThan(screenW * 0.75));
      expect(find.textContaining('59'), findsNothing);
      await wait(1);
      expect(find.textContaining('59'), findsOneWidget);
      await wait(58);
      expect(resend().onPressed, isNull);
      await wait(2);
      expect(
        tester.widget<UiButton>(byKey('auth-resend')).onPressed,
        isNotNull,
      );

      await tester.tap(byKey('auth-resend'));
      await tester.pump();
      expect(auth.calls, hasLength(2));
      expect(byKey('auth-step-code'), findsOneWidget);
      expect(resend().onPressed, isNull);

      await tester.ensureVisible(byKey('auth-change-email'));
      await tester.pump();
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

    testWidgets(
      'first sign-in records accept_terms(kTermsVersion) and continues to '
      'profile setup preserving ?from= (§4.1 / §4.4 / DE-04)',
      (tester) async {
        final auth = RecordingAuthRepository();
        final profiles = FakeProfileRepository();
        final c = await pumpBackendApp(
          tester,
          auth: auth,
          profiles: profiles,
        );
        await goTo(tester, c, '${AppRoutes.auth}?from=%2Fjourneys');
        await enterEmail(tester, 'a@b.co');
        await tester.enterText(byKey('auth-code'), '654321');
        await tester.pumpAndSettle();
        expect(auth.recordedTerms, [kTermsVersion]);
        expect(
          location(c),
          Uri(
            path: profileSetupPath,
            queryParameters: {AppRoutes.fromParam: AppRoutes.journeys},
          ).toString(),
        );
        expect(byKey('profile-setup-screen'), findsOneWidget);

        // Saving profile setup finishes the deterministic sequence to ?from=.
        await tester.enterText(byKey('profile-display-name'), 'Alice');
        await tester.enterText(byKey('profile-username'), 'alice');
        await tester.pumpAndSettle();
        await tester.ensureVisible(byKey('profile-save'));
        await tester.tap(byKey('profile-save'));
        await tester.pumpAndSettle();
        expect(location(c), AppRoutes.journeys);
      },
    );

    testWidgets(
      'first sign-in reaches profile setup even if /auth unmounts (C-B5)',
      (tester) async {
        final auth = _SlowVerifyAuth();
        final c = await pumpBackendApp(
          tester,
          auth: auth,
          profiles: FakeProfileRepository(),
        );
        await enterEmail(tester, 'a@b.co');
        await tester.enterText(byKey('auth-code'), '654321');
        await tester.pumpAndSettle();
        // The user id is out: the router has already left /auth.
        expect(byKey('auth-step-code'), findsNothing);
        auth.release.complete();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(location(c), profileSetupPath);
      },
    );

    testWidgets('returning user lands on the from target without re-recording terms (M2)', (tester) async {
      final auth = RecordingAuthRepository()..termsVersion = kTermsVersion;
      final c = await pumpBackendApp(
        tester,
        auth: auth,
        profiles: FakeProfileRepository(aliceProfile),
      );
      await enterEmail(tester, 'a@b.co');
      await tester.enterText(byKey('auth-code'), '654321');
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.capture);
      expect(auth.recordedTerms, isEmpty);
    });

    testWidgets(
      'H1: new user signing in from /f/<token> never mounts InviteAcceptScreen '
      'or fires RPCs before /profile/setup',
      (tester) async {
        final auth = RecordingAuthRepository();
        final profiles = _DelayedProfileRepository();
        final friends = _SpyFriendRepository();
        final insights = _SpyAccountInsightsRepository();
        final c = await pumpOurneyApp(
          tester,
          config: testBackendConfig,
          auth: auth,
          eulaAccepted: false,
          overrides: [
            profileRepositoryProvider.overrideWithValue(profiles),
            friendRepositoryProvider.overrideWithValue(friends),
            accountInsightsRepositoryProvider.overrideWithValue(insights),
          ],
        );
        const token = '0123456789abcdef0123456789abcdef';
        await goTo(tester, c, '${AppRoutes.auth}?from=%2Ff%2F$token');
        await enterEmail(tester, 'new@b.co');
        await tester.enterText(byKey('auth-code'), '654321');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // While watchMe() is in flight, the router must hold on /auth and
        // never mount /f/<token> or fire acceptInvite / quiz sync.
        expect(location(c), '${AppRoutes.auth}?from=%2Ff%2F$token');
        expect(friends.acceptedTokens, isEmpty);
        expect(insights.saveQuizCalls, 0);
        expect(insights.fetchQuizCalls, 0);

        // Profile check completes with null -> router transitions straight to
        // /profile/setup?from=%2Ff%2F<token> without ever mounting /f/<token>.
        profiles.emit(null);
        await tester.pumpAndSettle();
        expect(
          location(c),
          Uri(
            path: profileSetupPath,
            queryParameters: {AppRoutes.fromParam: '/f/$token'},
          ).toString(),
        );
        expect(friends.acceptedTokens, isEmpty);
        expect(insights.saveQuizCalls, 0);
        expect(insights.fetchQuizCalls, 0);
        expect(auth.recordedTerms, [kTermsVersion]);
      },
    );

    testWidgets(
      'H2: offline profile check during sign-in does not forge bumped terms '
      'consent for a returning v1 user',
      (tester) async {
        final auth = RecordingAuthRepository();
        final profiles = _DelayedProfileRepository();
        final c = await pumpOurneyApp(
          tester,
          config: testBackendConfig,
          auth: auth,
          eulaAccepted: false,
          overrides: [
            profileRepositoryProvider.overrideWithValue(profiles),
            termsVersionProvider.overrideWithValue(2),
          ],
        );
        await enterEmail(tester, 'returning@b.co');
        await tester.enterText(byKey('auth-code'), '654321');
        await tester.pump();

        // Simulate watchMe() failing offline before termsVersion is known.
        profiles.emitError(
          const OurneyException(OurneyErrorCode.offline),
        );
        await tester.pumpAndSettle();

        expect(location(c), profileSetupPath);
        expect(auth.recordedTerms, isEmpty);
        expect(
          c
              .read(sharedPreferencesProvider)
              .getInt(SafetyPrefs.termsVersionFor('u1')),
          isNull,
        );
      },
    );

    testWidgets(
      'legal links show zero-tolerance clickwrap on email, phone and password '
      'flows, inline (§4.2 / U13 / L4)',
      (tester) async {
        final c = await pumpBackendApp(
          tester,
          auth: RecordingAuthRepository(),
          phoneAvailable: true,
        );
        // Zero-tolerance clickwrap copy on email flow.
        expect(
          find.text('Tiếp tục đồng nghĩa bạn đồng ý với'),
          findsOneWidget,
        );
        expect(
          find.text('(không dung thứ nội dung phản cảm) và'),
          findsOneWidget,
        );
        expect(find.text('Điều khoản sử dụng'), findsOneWidget);
        expect(find.text('Chính sách quyền riêng tư.'), findsOneWidget);
        expect(
          tester.widget<UiTextAction>(byKey('auth-terms')).underline,
          isTrue,
        );
        expect(
          tester.widget<UiTextAction>(byKey('auth-privacy')).underline,
          isTrue,
        );

        final screen = tester.getSize(find.byType(AuthScreen)).width;
        expect(
          tester.getSize(byKey('auth-terms')).width,
          lessThan(screen * 0.75),
        );
        // L4: left-aligned secondary action aligns flush with the form field
        // and left-aligns wrapped lines.
        final usePwdText = tester.widget<Text>(
          find.descendant(
            of: byKey('auth-use-password'),
            matching: find.byType(Text),
          ),
        );
        expect(usePwdText.textAlign, TextAlign.left);
        expect(
          tester.getTopLeft(byKey('auth-use-password')).dx,
          tester.getTopLeft(byKey('auth-email')).dx,
        );

        // Phone flow also shows the inline legal links.
        await tester.tap(byKey('auth-tab-phone'));
        await tester.pumpAndSettle();
        expect(byKey('auth-terms'), findsOneWidget);
        expect(byKey('auth-privacy'), findsOneWidget);
        await tester.tap(byKey('auth-tab-email'));
        await tester.pumpAndSettle();

        // Password flow also shows the inline legal links (§4.2).
        await tester.ensureVisible(byKey('auth-use-password'));
        await tester.tap(byKey('auth-use-password'));
        await tester.pumpAndSettle();
        expect(byKey('auth-terms'), findsOneWidget);
        expect(byKey('auth-privacy'), findsOneWidget);

        // Reset password sub-flow hides the legal links.
        await tester.ensureVisible(byKey('auth-forgot'));
        await tester.tap(byKey('auth-forgot'));
        await tester.pumpAndSettle();
        expect(byKey('auth-terms'), findsNothing);
        await tester.tap(byKey('auth-flow-back'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('auth-flow-back'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(byKey('auth-terms'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('auth-terms'));
        await tester.pumpAndSettle();
        expect(location(c), '/safety/eula');
        c.read(routerProvider).pop();
        await tester.pumpAndSettle();
        await tester.ensureVisible(byKey('auth-privacy'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('auth-privacy'));
        await tester.pumpAndSettle();
        expect(location(c), '/safety/privacy');
      },
    );

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
        l10n.auth_errorSendFailed,
      );
      expect(
        authErrorMessage(l10n, StateError('x'), AuthStep.sendOtp),
        l10n.auth_errorSendFailed,
      );
    });

    test('maps every GoTrue error code to the right user message (M6)', () {
      String fromGoTrue(String code, AuthStep step, [String status = '400']) =>
          authErrorMessage(
            l10n,
            mapRemoteError(
              AuthException('x', statusCode: status, code: code),
            ),
            step,
          );

      // Server/policy rejections on send must never blame email/phone format.
      for (final code in [
        'signup_disabled',
        'email_provider_disabled',
        'otp_disabled',
        'email_address_not_authorized',
        'captcha_failed',
        'user_banned',
      ]) {
        expect(
          fromGoTrue(code, AuthStep.sendOtp),
          l10n.auth_errorSendFailed,
          reason: 'sendOtp:$code',
        );
        expect(
          fromGoTrue(code, AuthStep.resetSend),
          l10n.auth_errorSendFailed,
          reason: 'resetSend:$code',
        );
      }
      expect(
        fromGoTrue('phone_provider_disabled', AuthStep.sendPhone),
        l10n.auth_errorPhoneUnavailable,
      );
      expect(
        fromGoTrue('sms_provider_disabled', AuthStep.sendPhone),
        l10n.auth_errorPhoneUnavailable,
      );
      expect(
        fromGoTrue('captcha_failed', AuthStep.sendPhone),
        l10n.auth_errorSendFailed,
      );
      expect(
        fromGoTrue('sms_send_failed', AuthStep.sendPhone, '500'),
        l10n.auth_errorSmsFailed,
      );

      // Actual validation codes still report format errors.
      expect(
        fromGoTrue('email_address_invalid', AuthStep.sendOtp),
        l10n.auth_emailInvalid,
      );
      expect(
        fromGoTrue('validation_failed', AuthStep.sendOtp),
        l10n.auth_emailInvalid,
      );
      expect(
        fromGoTrue('phone_invalid', AuthStep.sendPhone),
        l10n.auth_phoneInvalid,
      );

      // user_banned (403) must not tell the user their code or password was wrong.
      expect(
        fromGoTrue('user_banned', AuthStep.verifyOtp, '403'),
        l10n.auth_errorGeneric,
      );
      expect(
        fromGoTrue('user_banned', AuthStep.passwordSignIn, '403'),
        l10n.auth_errorGeneric,
      );

      // Password reset step 2: weak_password and same_password report password
      // errors, never wrong-code.
      expect(
        fromGoTrue('weak_password', AuthStep.resetConfirm, '422'),
        l10n.auth_passwordShort,
      );
      expect(
        fromGoTrue('same_password', AuthStep.resetConfirm, '422'),
        l10n.auth_errorSamePassword,
      );
      expect(
        fromGoTrue('otp_expired', AuthStep.resetConfirm, '403'),
        l10n.auth_errorWrongCode,
      );

      // Rate limit codes.
      for (final code in [
        'over_request_rate_limit',
        'over_email_send_rate_limit',
        'over_sms_send_rate_limit',
      ]) {
        expect(
          fromGoTrue(code, AuthStep.sendOtp, '429'),
          l10n.auth_errorRateLimited,
        );
      }
    });

    test('resend cooldown is a minute', () {
      expect(AuthScreen.resendCooldown, 60);
    });
  });
}
