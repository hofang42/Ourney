import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../ui/ui.dart';
import '../onboarding/onboarding_providers.dart';
import '../profile/routes.dart' show profileSetupPath;
import 'auth_errors.dart';
import 'l10n/generated/auth_localizations.dart';
import 'phone_format.dart';

/// Sign-in (FR-A1): emailed code (default), phone SMS code, email + password
/// (sign in / create account) and "forgot password".
///
/// Everything goes through `AuthRepository`. On success the repository's
/// `watchUserId()` emits and the router leaves `/auth` by itself. If
/// `ProfileRepository.watchMe()` then yields null (first sign-in), this screen
/// sends the user to `/profile/setup?from=<target>`.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({this.from, super.key});

  /// Sanitized `?from=` target to continue to after sign-in.
  final String? from;

  /// Seconds before "resend code" is enabled again.
  static const resendCooldown = 60;

  /// How long to wait for the profile after sign-in before giving up on the
  /// first-sign-in check (the profile screen offers setup later anyway).
  static const profileCheckTimeout = Duration(seconds: 10);

  /// Minimum length of a new password (Supabase default is 6).
  static const minPassword = 8;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _Tab { email, phone }

/// Which form is showing / which flow the code step belongs to.
enum _Flow { emailCode, phoneCode, password, signUp, reset }

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _codePattern = RegExp(r'^\d{6}$');

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  _Flow _flow = _Flow.emailCode;
  bool _codeStep = false;
  bool _busy = false;
  bool _submitted = false;
  bool _codeSubmitted = false;
  bool _showPassword = false;
  String? _error;
  String? _info;
  int _cooldown = 0;
  Timer? _timer;

  _Tab get _tab => _flow == _Flow.phoneCode ? _Tab.phone : _Tab.email;
  String get _normalizedEmail => _email.text.trim().toLowerCase();
  String? get _e164 => toE164Vietnam(_phone.text);
  bool get _isPhone => _flow == _Flow.phoneCode;
  bool get _needsPasswordField =>
      _flow == _Flow.password || _flow == _Flow.signUp;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = AuthScreen.resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  void _goFlow(_Flow flow) {
    _timer?.cancel();
    setState(() {
      _flow = flow;
      _codeStep = false;
      _submitted = false;
      _codeSubmitted = false;
      _error = null;
      _info = null;
      _cooldown = 0;
      _code.clear();
      _password.clear();
      _showPassword = false;
    });
  }

  bool get _formValid {
    if (_isPhone) return _e164 != null;
    if (!_emailPattern.hasMatch(_normalizedEmail)) return false;
    if (_needsPasswordField) {
      return _password.text.length >= AuthScreen.minPassword ||
          (_flow == _Flow.password && _password.text.isNotEmpty);
    }
    return true;
  }

  /// Sends whatever the current form needs (first send and resend).
  Future<void> _submitForm({bool resend = false}) async {
    final l10n = AuthL10n.of(context);
    setState(() {
      _submitted = true;
      _error = null;
      _info = null;
    });
    if (!_formValid) return;
    final auth = ref.read(authRepositoryProvider);
    final router = GoRouter.of(context);
    final profiles = _profiles();
    final from = widget.from;
    setState(() => _busy = true);
    var step = AuthStep.sendOtp;
    try {
      switch (_flow) {
        case _Flow.emailCode:
          await auth.sendOtp(_normalizedEmail);
        case _Flow.phoneCode:
          step = AuthStep.sendPhone;
          await auth.sendPhoneOtp(_e164!);
        case _Flow.reset:
          step = AuthStep.resetSend;
          await auth.sendPasswordReset(_normalizedEmail);
        case _Flow.password:
          step = AuthStep.passwordSignIn;
          await auth.signInWithPassword(_normalizedEmail, _password.text);
          await _finishSignIn(router, profiles, from);
          return;
        case _Flow.signUp:
          step = AuthStep.signUp;
          final needsCode = await auth.signUpWithPassword(
            _normalizedEmail,
            _password.text,
          );
          if (!needsCode) {
            await _finishSignIn(router, profiles, from);
            return;
          }
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorMessage(l10n, e, step);
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeStep = true;
      _codeSubmitted = false;
      if (resend) {
        _info = l10n.auth_codeResent;
        _code.clear();
      }
    });
    _startCooldown();
    _codeFocus.requestFocus();
  }

  Future<void> _verify() async {
    final l10n = AuthL10n.of(context);
    setState(() {
      _codeSubmitted = true;
      _error = null;
      _info = null;
    });
    final code = _code.text.trim();
    if (!_codePattern.hasMatch(code)) return;
    if (_flow == _Flow.reset &&
        _password.text.length < AuthScreen.minPassword) {
      setState(() => _submitted = true);
      return;
    }

    // Capture everything before awaiting: the router may replace this screen
    // as soon as the user id is emitted.
    final router = GoRouter.of(context);
    final auth = ref.read(authRepositoryProvider);
    final profiles = _profiles();
    final from = widget.from;

    setState(() => _busy = true);
    var step = AuthStep.verifyOtp;
    try {
      switch (_flow) {
        case _Flow.phoneCode:
          step = AuthStep.verifyPhone;
          await auth.verifyPhoneOtp(_e164!, code);
        case _Flow.signUp:
          step = AuthStep.confirmSignUp;
          await auth.confirmSignUp(_normalizedEmail, code);
        case _Flow.reset:
          step = AuthStep.resetConfirm;
          await auth.resetPassword(_normalizedEmail, code, _password.text);
        case _Flow.emailCode || _Flow.password:
          await auth.verifyOtp(_normalizedEmail, code);
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorMessage(l10n, e, step);
      });
      return;
    }
    await _finishSignIn(router, profiles, from);
  }

  ProfileRepository? _profiles() {
    try {
      return ref.read(profileRepositoryProvider);
    } on Object {
      return null; // Not wired: skip the first-sign-in check.
    }
  }

  Future<void> _finishSignIn(
    GoRouter router,
    ProfileRepository? profiles,
    String? from,
  ) async {
    OurneyHaptics.success();
    // Push the locally stored onboarding answers to the new account (best
    // effort, never blocks sign-in).
    unawaited(ref.read(onboardingQuizProvider.notifier).syncToServer());
    if (profiles != null && await _needsProfileSetup(profiles)) {
      router.go(
        Uri(
          path: profileSetupPath,
          queryParameters: from == null ? null : {AppRoutes.fromParam: from},
        ).toString(),
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  static Future<bool> _needsProfileSetup(ProfileRepository repo) async {
    try {
      final profile = await repo.watchMe().first.timeout(
        AuthScreen.profileCheckTimeout,
      );
      return profile == null;
    } on Object {
      return false;
    }
  }

  void _backToForm() {
    _timer?.cancel();
    setState(() {
      _codeStep = false;
      _code.clear();
      _error = null;
      _info = null;
      _cooldown = 0;
    });
  }

  String _title(AuthL10n l10n) => _codeStep
      ? l10n.auth_codeTitle
      : switch (_flow) {
          _Flow.signUp => l10n.auth_signUpTitle,
          _Flow.reset => l10n.auth_resetTitle,
          _ => l10n.auth_title,
        };

  String _subtitle(AuthL10n l10n) {
    if (_codeStep) {
      return _isPhone
          ? l10n.auth_smsSentTo(formatPhoneForDisplay(_e164 ?? _phone.text))
          : l10n.auth_codeSentTo(_normalizedEmail);
    }
    return switch (_flow) {
      _Flow.phoneCode => l10n.auth_phoneSubtitle,
      _Flow.signUp => l10n.auth_signUpSubtitle,
      _Flow.reset => l10n.auth_resetSubtitle,
      _ => l10n.auth_subtitle,
    };
  }

  String _primaryLabel(AuthL10n l10n) {
    if (_busy) return l10n.auth_sending;
    return switch (_flow) {
      _Flow.phoneCode => l10n.auth_sendSms,
      _Flow.password => l10n.auth_signIn,
      _Flow.signUp => l10n.auth_signUpButton,
      _ => l10n.auth_sendCode,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AuthL10n.of(context);
    final ui = context.ui;
    final codeError =
        _codeSubmitted && !_codePattern.hasMatch(_code.text.trim())
        ? l10n.auth_codeInvalidFormat
        : null;

    return UiScaffold(
      key: const ValueKey('auth-screen'),
      padTop: 0,
      bottom: _Footer(
        terms: l10n.auth_terms,
        privacy: l10n.auth_privacy,
        onOpen: () => context.push(AppRoutes.safety),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.auth-screen header`: wordmark, 110dp tall.
          Container(
            constraints: const BoxConstraints(minHeight: 110),
            alignment: Alignment.centerLeft,
            child: const UiWordmark(size: 36),
          ),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: UiMotion.of(context, const Duration(milliseconds: 240)),
            child: Column(
              key: ValueKey(
                _codeStep
                    ? 'auth-step-code'
                    : (_flow == _Flow.emailCode
                          ? 'auth-step-email'
                          : 'auth-step-${_flow.name}'),
              ),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(_title(l10n), style: UiText.h1(color: ui.ink)),
                ),
                const SizedBox(height: 8),
                Text(_subtitle(l10n), style: UiText.muted(color: ui.inkMuted)),
                const SizedBox(height: 28),
                if (_codeStep)
                  ..._codeChildren(l10n, ui, codeError)
                else
                  ..._formChildren(l10n, ui),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: UiSpace.lg),
            UiInlineError(key: const ValueKey('auth-error'), message: _error!),
          ],
          if (_info != null) ...[
            const SizedBox(height: UiSpace.lg),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  OurneyIcon(name: 'mail', flat: true, color: ui.success),
                  const SizedBox(width: UiSpace.sm),
                  Expanded(
                    child: Text(_info!, style: UiText.body(color: ui.ink)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _formChildren(AuthL10n l10n, OurneyUi ui) {
    final emailError =
        _submitted && !_isPhone && !_emailPattern.hasMatch(_normalizedEmail)
        ? l10n.auth_emailInvalid
        : null;
    final phoneError = _submitted && _isPhone && _e164 == null
        ? l10n.auth_phoneInvalid
        : null;
    final passwordError =
        _submitted &&
            _flow == _Flow.signUp &&
            _password.text.length < AuthScreen.minPassword
        ? l10n.auth_passwordShort
        : null;
    final showTabs =
        _flow == _Flow.emailCode ||
        _flow == _Flow.phoneCode ||
        _flow == _Flow.password;
    return [
      if (showTabs) ...[
        UiSegmented<_Tab>(
          value: _tab,
          segments: [
            UiSegment(
              key: const ValueKey('auth-tab-email'),
              value: _Tab.email,
              label: l10n.auth_tabEmail,
            ),
            UiSegment(
              key: const ValueKey('auth-tab-phone'),
              value: _Tab.phone,
              label: l10n.auth_tabPhone,
            ),
          ],
          onChanged: _busy
              ? (_) {}
              : (t) => _goFlow(
                  t == _Tab.phone ? _Flow.phoneCode : _Flow.emailCode,
                ),
        ),
        const SizedBox(height: UiSpace.lg),
      ],
      if (_isPhone)
        UiTextField(
          fieldKey: const ValueKey('auth-phone'),
          label: l10n.auth_phoneLabel,
          hint: l10n.auth_phoneHint,
          prefixText: '${l10n.auth_phonePrefix} ',
          controller: _phone,
          enabled: !_busy,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          autocorrect: false,
          textInputAction: TextInputAction.send,
          error: phoneError,
          onSubmitted: (_) => _busy ? null : _submitForm(),
        )
      else
        UiTextField(
          fieldKey: const ValueKey('auth-email'),
          label: l10n.auth_emailLabel,
          hint: l10n.auth_emailHint,
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          textInputAction: _needsPasswordField
              ? TextInputAction.next
              : TextInputAction.send,
          error: emailError,
          onSubmitted: (_) =>
              _busy || _needsPasswordField ? null : _submitForm(),
        ),
      if (_needsPasswordField) ...[
        const SizedBox(height: UiSpace.md),
        _passwordField(
          l10n,
          label: l10n.auth_passwordLabel,
          error: passwordError,
          signUp: _flow == _Flow.signUp,
        ),
      ],
      const SizedBox(height: 18),
      UiButton(
        key: const ValueKey('auth-send'),
        label: _primaryLabel(l10n),
        loading: _busy,
        onPressed: _busy ? null : _submitForm,
      ),
      const SizedBox(height: UiSpace.sm),
      ..._links(l10n),
    ];
  }

  Widget _passwordField(
    AuthL10n l10n, {
    required String label,
    String? error,
    bool signUp = false,
    ValueKey<String> fieldKey = const ValueKey('auth-password'),
  }) => UiTextField(
    fieldKey: fieldKey,
    label: label,
    controller: _password,
    enabled: !_busy,
    obscureText: !_showPassword,
    autocorrect: false,
    keyboardType: TextInputType.visiblePassword,
    autofillHints: [
      signUp ? AutofillHints.newPassword : AutofillHints.password,
    ],
    textInputAction: TextInputAction.done,
    error: error,
    onChanged: (_) => setState(() {}),
    onSubmitted: (_) => _busy ? null : (_codeStep ? _verify() : _submitForm()),
    trailing: IconButton(
      key: const ValueKey('auth-password-toggle'),
      tooltip: _showPassword ? l10n.auth_hidePassword : l10n.auth_showPassword,
      onPressed: () => setState(() => _showPassword = !_showPassword),
      icon: OurneyIcon(
        name: _showPassword ? 'eye-off' : 'eye',
        flat: true,
        color: context.ui.inkMuted,
      ),
    ),
  );

  List<Widget> _links(AuthL10n l10n) {
    UiTextAction link(String key, String label, VoidCallback onPressed) =>
        UiTextAction(
          key: ValueKey(key),
          label: label,
          onPressed: _busy ? null : onPressed,
        );
    return switch (_flow) {
      _Flow.emailCode => [
        link(
          'auth-use-password',
          l10n.auth_usePassword,
          () => _goFlow(_Flow.password),
        ),
      ],
      _Flow.password => [
        link(
          'auth-use-code',
          l10n.auth_useCode,
          () => _goFlow(_Flow.emailCode),
        ),
        link('auth-forgot', l10n.auth_forgot, () => _goFlow(_Flow.reset)),
        link(
          'auth-create-account',
          l10n.auth_createAccount,
          () => _goFlow(_Flow.signUp),
        ),
      ],
      _Flow.signUp => [
        link(
          'auth-have-account',
          l10n.auth_haveAccount,
          () => _goFlow(_Flow.password),
        ),
      ],
      _Flow.reset => [
        link(
          'auth-back-to-sign-in',
          l10n.auth_backToSignIn,
          () => _goFlow(_Flow.password),
        ),
      ],
      _Flow.phoneCode => const [],
    };
  }

  List<Widget> _codeChildren(AuthL10n l10n, OurneyUi ui, String? codeError) {
    final reset = _flow == _Flow.reset;
    return [
      UiOtpField(
        key: const ValueKey('auth-code'),
        controller: _code,
        focusNode: _codeFocus,
        digitLabel: l10n.auth_codeLabel,
        enabled: !_busy,
        hasError: codeError != null || _error != null,
        onChanged: (value) {
          if (value.length == 6 && !_busy && !reset) _verify();
        },
        onSubmitted: (_) => _busy ? null : _verify(),
      ),
      if (codeError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            codeError,
            style: UiText.body(size: 12, color: ui.danger),
          ),
        ),
      if (reset) ...[
        const SizedBox(height: UiSpace.md),
        _passwordField(
          l10n,
          label: l10n.auth_newPasswordLabel,
          signUp: true,
          fieldKey: const ValueKey('auth-new-password'),
          error: _submitted && _password.text.length < AuthScreen.minPassword
              ? l10n.auth_passwordShort
              : null,
        ),
      ],
      const SizedBox(height: 18),
      UiButton(
        key: const ValueKey('auth-verify'),
        label: _busy
            ? l10n.auth_verifying
            : (reset ? l10n.auth_resetConfirm : l10n.auth_verify),
        loading: _busy,
        onPressed: _busy ? null : _verify,
      ),
      const SizedBox(height: 8),
      UiTextAction(
        key: const ValueKey('auth-resend'),
        size: 13,
        color: _cooldown > 0 ? ui.inkMuted : null,
        label: _cooldown > 0 ? l10n.auth_resendIn(_cooldown) : l10n.auth_resend,
        onPressed: _busy || _cooldown > 0
            ? null
            : () => _submitForm(resend: true),
      ),
      UiTextAction(
        key: const ValueKey('auth-change-email'),
        label: _isPhone ? l10n.auth_changePhone : l10n.auth_changeEmail,
        onPressed: _busy ? null : _backToForm,
      ),
      const SizedBox(height: UiSpace.sm),
      Text(
        l10n.auth_otpHelper,
        textAlign: TextAlign.center,
        style: UiText.muted(color: ui.inkMuted, size: 13),
      ),
    ];
  }
}

/// `.auth-screen footer`: "Terms · Privacy", both open the safety pages.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.terms,
    required this.privacy,
    required this.onOpen,
  });

  final String terms;
  final String privacy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: UiTextAction(
                key: const ValueKey('auth-terms'),
                label: terms,
                size: 11,
                underline: true,
                color: ui.inkMuted,
                onPressed: onOpen,
              ),
            ),
            Text('·', style: UiText.body(size: 11, color: ui.inkMuted)),
            Flexible(
              child: UiTextAction(
                key: const ValueKey('auth-privacy'),
                label: privacy,
                size: 11,
                underline: true,
                color: ui.inkMuted,
                onPressed: onOpen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
