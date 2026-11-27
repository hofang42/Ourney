import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/redirect.dart' show safeFrom;
import '../../ui/ui.dart';
import '../onboarding/onboarding_providers.dart';
import '../profile/routes.dart' show profileSetupPath;
import '../safety/data/safety_providers.dart';
import '../safety/safety_paths.dart';
import 'auth_errors.dart';
import 'auth_providers.dart';
import 'l10n/generated/auth_localizations.dart';
import 'phone_format.dart';

/// Sign-in (FR-A1): one flow for new and existing accounts. Emailed code
/// (default) or, when the server has it enabled, a phone SMS code; email +
/// password is an optional method for accounts that set one; plus "forgot
/// password". An account is created by the first verified code.
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
enum _Flow { emailCode, phoneCode, password, reset }

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _codePattern = RegExp(r'^\d{6}$');

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _kOtpShakeDuration = Duration(milliseconds: 280);

  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  AnimationController? _otpShakeCtrl;
  _Flow _flow = _Flow.emailCode;
  int _flowDirection = 1;
  bool _codeStep = false;
  bool _busy = false;
  bool _submitted = false;
  bool _showPassword = false;
  String? _error;
  bool _offline = false;
  bool _success = false;

  /// The server said phone sign-in is off (despite the settings probe).
  bool _phoneDisabled = false;
  bool _passwordSignInFailed = false;
  bool _userTouchedFlowOrInput = false;
  bool _pendingRememberedPhone = false;
  int _cooldown = 0;
  Timer? _timer;
  late final AuthRepository _auth = ref.read(authRepositoryProvider);

  @override
  void initState() {
    super.initState();
    final raw = ref
        .read(sharedPreferencesProvider)
        .getString(AuthMethodPrefs.lastMethodKey);
    switch (RememberedAuthMethod.fromWire(raw)) {
      case RememberedAuthMethod.password:
        _flow = _Flow.password;
      case RememberedAuthMethod.phoneCode:
        final phoneReady =
            ref.read(phoneAuthAvailableProvider).asData?.value ?? false;
        if (phoneReady) {
          _flow = _Flow.phoneCode;
        } else {
          _pendingRememberedPhone = true;
        }
      case RememberedAuthMethod.emailCode || null:
        _flow = _Flow.emailCode;
    }
  }

  _Tab get _tab => _flow == _Flow.phoneCode ? _Tab.phone : _Tab.email;
  String get _normalizedEmail => _email.text.trim().toLowerCase();
  String? get _e164 => toE164Vietnam(_phone.text);
  bool get _isPhone => _flow == _Flow.phoneCode;
  bool get _needsPasswordField => _flow == _Flow.password;

  AnimationController _ensureOtpShakeCtrl() =>
      _otpShakeCtrl ??= AnimationController(
        vsync: this,
        duration: _kOtpShakeDuration,
      );

  /// 4-oscillation damped horizontal shake (`±6dp`) over `280ms`.
  static double _otpShakeDx(double t) {
    if (t <= 0.0 || t >= 1.0) return 0.0;
    final curvedT = UiCurves.easeOutStrong.transform(t);
    return 6.0 * (1.0 - t) * math.sin(curvedT * 4.0 * 2.0 * math.pi);
  }

  void _triggerOtpErrorShake() {
    unawaited(UiHaptics.reject());
    if (!UiMotion.reduced(context)) {
      _ensureOtpShakeCtrl().forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_flow == _Flow.reset && !_success) {
      unawaited(_auth.cancelPasswordFlow());
    }
    _otpShakeCtrl?.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  static bool _isOffline(Object e) =>
      e is OurneyException && e.error == OurneyErrorCode.offline;

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
    if (_flow == _Flow.reset) {
      unawaited(_auth.cancelPasswordFlow());
    }
    final int nextDirection;
    if (_codeStep) {
      nextDirection = -1;
    } else if (_flow == _Flow.reset && flow == _Flow.password) {
      nextDirection = -1;
    } else if (_flow == _Flow.password && flow == _Flow.emailCode) {
      nextDirection = -1;
    } else if (_flow == _Flow.phoneCode && flow == _Flow.emailCode) {
      nextDirection = -1;
    } else {
      nextDirection = 1;
    }
    setState(() {
      _flowDirection = nextDirection;
      _flow = flow;
      _userTouchedFlowOrInput = true;
      _pendingRememberedPhone = false;
      _passwordSignInFailed = false;
      _codeStep = false;
      _submitted = false;
      _error = null;
      _offline = false;
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
      return _password.text.isNotEmpty;
    }
    return true;
  }

  /// One-tap recovery after a failed password sign-in: keeps the typed email,
  /// sends the 6-digit login code while keeping the form in place, and
  /// transitions once directly to `auth-step-code` (or `auth-step-email` with
  /// the error if sending fails).
  Future<void> _sendCodeForCurrentEmail() async {
    if (_busy || !_emailPattern.hasMatch(_normalizedEmail)) return;
    final l10n = AuthL10n.of(context);
    final auth = ref.read(authRepositoryProvider);
    _timer?.cancel();
    setState(() {
      _busy = true;
      _userTouchedFlowOrInput = true;
      _pendingRememberedPhone = false;
      _passwordSignInFailed = false;
      _error = null;
      _offline = false;
    });
    try {
      await auth.sendOtp(_normalizedEmail);
    } on Object catch (e) {
      if (!mounted) return;
      final isOff = _isOffline(e);
      setState(() {
        _busy = false;
        _flowDirection = -1;
        _flow = _Flow.emailCode;
        _codeStep = false;
        _submitted = false;
        _password.clear();
        _showPassword = false;
        _offline = isOff;
        _error = isOff ? null : authErrorMessage(l10n, e, AuthStep.sendOtp);
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _flowDirection = 1;
      _flow = _Flow.emailCode;
      _codeStep = true;
      _submitted = false;
      _password.clear();
      _showPassword = false;
    });
    _startCooldown();
    _codeFocus.requestFocus();
  }

  /// Sends whatever the current form needs (first send and resend).
  Future<void> _submitForm({bool resend = false}) async {
    final l10n = AuthL10n.of(context);
    setState(() {
      _submitted = true;
      _error = null;
      _offline = false;
      _passwordSignInFailed = false;
    });
    if (!_formValid) return;
    final auth = ref.read(authRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final router = GoRouter.of(context);
    final profiles = _profiles();
    final quiz = ref.read(onboardingQuizProvider.notifier);
    final eula = ref.read(eulaAcceptedProvider.notifier);
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
          unawaited(
            prefs.setString(
              AuthMethodPrefs.lastMethodKey,
              RememberedAuthMethod.password.wireName,
            ),
          );
          if (auth.currentUserId case final uid?) {
            unawaited(
              prefs.setBool(AuthMethodPrefs.hasPasswordKeyFor(uid), true),
            );
          }
          await _finishSignIn(
            router,
            auth,
            profiles,
            quiz,
            eula,
            from,
            recordInitialTerms: true,
          );
          return;
      }
    } on Object catch (e) {
      if (!mounted) return;
      final errCode = e is OurneyException ? e.error : OurneyErrorCode.unknown;
      final unavailable = errCode == OurneyErrorCode.unavailable;
      final isPasswordInvalid =
          step == AuthStep.passwordSignIn &&
          (errCode == OurneyErrorCode.invalid ||
              errCode == OurneyErrorCode.unauthenticated);
      setState(() {
        _busy = false;
        _offline = _isOffline(e);
        _error = _offline ? null : authErrorMessage(l10n, e, step);
        _passwordSignInFailed = !_offline && isPasswordInvalid;
        if (unavailable && _flow == _Flow.phoneCode) {
          // SMS is off on the server: hide Phone and go back to email.
          _phoneDisabled = true;
          _pendingRememberedPhone = false;
          _flowDirection = -1;
          _flow = _Flow.emailCode;
          _submitted = false;
        }
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _flowDirection = 1;
      _codeStep = true;
      _submitted = false;
      if (resend) _code.clear();
    });
    _startCooldown();
    _codeFocus.requestFocus();
    if (resend) showUiToast(context, l10n.auth_codeResent);
  }

  Future<void> _verify() async {
    final l10n = AuthL10n.of(context);
    final code = _code.text.trim();
    if (!_codePattern.hasMatch(code)) {
      setState(() {
        _offline = false;
        _error = l10n.auth_errorWrongCode;
      });
      _triggerOtpErrorShake();
      return;
    }
    setState(() {
      _error = null;
      _offline = false;
    });
    if (_flow == _Flow.reset &&
        _password.text.length < AuthScreen.minPassword) {
      setState(() => _submitted = true);
      return;
    }

    // Capture everything before awaiting: the router may replace this screen
    // as soon as the user id is emitted.
    final router = GoRouter.of(context);
    final auth = ref.read(authRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final profiles = _profiles();
    final quiz = ref.read(onboardingQuizProvider.notifier);
    final eula = ref.read(eulaAcceptedProvider.notifier);
    final from = widget.from;

    setState(() => _busy = true);
    var step = AuthStep.verifyOtp;
    try {
      switch (_flow) {
        case _Flow.phoneCode:
          step = AuthStep.verifyPhone;
          await auth.verifyPhoneOtp(_e164!, code);
          unawaited(
            prefs.setString(
              AuthMethodPrefs.lastMethodKey,
              RememberedAuthMethod.phoneCode.wireName,
            ),
          );
        case _Flow.reset:
          step = AuthStep.resetConfirm;
          await auth.resetPassword(_normalizedEmail, code, _password.text);
          unawaited(
            prefs.setString(
              AuthMethodPrefs.lastMethodKey,
              RememberedAuthMethod.password.wireName,
            ),
          );
          if (auth.currentUserId case final uid?) {
            unawaited(
              prefs.setBool(AuthMethodPrefs.hasPasswordKeyFor(uid), true),
            );
          }
        case _Flow.emailCode || _Flow.password:
          await auth.verifyOtp(_normalizedEmail, code);
          unawaited(
            prefs.setString(
              AuthMethodPrefs.lastMethodKey,
              RememberedAuthMethod.emailCode.wireName,
            ),
          );
      }
    } on Object catch (e) {
      if (!mounted) return;
      final isOff = _isOffline(e);
      setState(() {
        _busy = false;
        _offline = isOff;
        _error = isOff ? null : authErrorMessage(l10n, e, step);
      });
      if (!isOff) {
        _triggerOtpErrorShake();
      }
      return;
    }
    final recordInitialTerms = _flow != _Flow.reset;
    if (mounted) setState(() => _success = true);
    await _finishSignIn(
      router,
      auth,
      profiles,
      quiz,
      eula,
      from,
      recordInitialTerms: recordInitialTerms,
    );
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
    AuthRepository auth,
    ProfileRepository? profiles,
    OnboardingQuizNotifier quiz,
    EulaAccepted eula,
    String? from, {
    required bool recordInitialTerms,
  }) async {
    unawaited(UiHaptics.success());
    final result = profiles == null
        ? (profile: null, loaded: true)
        : await _loadProfile(profiles);
    final needsSetup = profiles != null && (!result.loaded || result.profile == null);
    if (!needsSetup) {
      // Push the locally stored onboarding answers once the account has a
      // profile row (`ProfileSetupScreen._save` syncs after `upsertMe` for new
      // accounts, H1).
      unawaited(quiz.syncToServer());
    }
    // §4.4: record initial terms consent only on clickwrap flows (`_flow !=
    // _Flow.reset`, M2) when the account is confirmed to have no recorded
    // version yet (0, or brand-new account with `profile == null`). If the
    // profile fetch failed/timed out and `acceptedTermsVersion` is still null
    // (unknown), defer recording until the profile loads so a returning user
    // on an older version still sees TermsUpdateSheet (H2).
    if (recordInitialTerms) {
      final authVer = auth.acceptedTermsVersion;
      final profileVer = result.profile?.termsVersion;
      final int? knownVer;
      if (authVer != null && profileVer != null) {
        knownVer = authVer > profileVer ? authVer : profileVer;
      } else {
        knownVer = authVer ?? profileVer;
      }
      if (result.loaded) {
        if ((knownVer ?? 0) <= 0) {
          unawaited(eula.accept());
        }
      } else if (knownVer != null) {
        if (knownVer <= 0) {
          unawaited(eula.accept());
        }
      } else {
        eula.deferInitialClickwrap(auth.currentUserId);
      }
    }
    if (needsSetup) {
      final safeTarget = from == null
          ? null
          : safeFrom(
              Uri(
                path: AppRoutes.auth,
                queryParameters: {AppRoutes.fromParam: from},
              ),
            );
      final targetUri = Uri(
        path: profileSetupPath,
        queryParameters: safeTarget == null
            ? null
            : {AppRoutes.fromParam: safeTarget},
      ).toString();
      if (router.state.uri.toString() != targetUri) {
        router.go(targetUri);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  static Future<({Profile? profile, bool loaded})> _loadProfile(
    ProfileRepository repo,
  ) async {
    try {
      final profile = await repo.watchMe().first.timeout(
        AuthScreen.profileCheckTimeout,
      );
      return (profile: profile, loaded: true);
    } on Object {
      // No local profile could be confirmed: go to `/profile/setup` so its
      // offline/error retry and sign-out state handles recovery (DE-04/DE-07).
      return (profile: null, loaded: false);
    }
  }

  void _backToForm() {
    _timer?.cancel();
    if (_flow == _Flow.reset) {
      unawaited(_auth.cancelPasswordFlow());
    }
    setState(() {
      _flowDirection = -1;
      _codeStep = false;
      _code.clear();
      _error = null;
      _cooldown = 0;
    });
  }

  String _title(AuthL10n l10n) => _codeStep
      ? l10n.auth_codeTitle
      : switch (_flow) {
          _Flow.password => l10n.auth_passwordTitle,
          _Flow.reset => l10n.auth_resetTitle,
          _ => l10n.auth_title,
        };

  String _subtitle(AuthL10n l10n) {
    return switch (_flow) {
      _Flow.phoneCode => l10n.auth_phoneSubtitle,
      _Flow.reset => l10n.auth_resetSubtitle,
      _ => l10n.auth_subtitle,
    };
  }

  String _primaryLabel(AuthL10n l10n) {
    if (_busy) return l10n.auth_sending;
    return switch (_flow) {
      _Flow.password => l10n.auth_signIn,
      _ => l10n.auth_sendCode,
    };
  }

  /// Phone is offered only when the server reports it as enabled.
  bool get _phoneAvailable =>
      !_phoneDisabled &&
      (ref.watch(phoneAuthAvailableProvider).asData?.value ?? false);

  /// Password / reset forms sit under a back header to the start form.
  bool get _subForm => _flow == _Flow.password || _flow == _Flow.reset;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(phoneAuthAvailableProvider, (prev, next) {
      if (!_pendingRememberedPhone) return;
      final available = next.asData?.value;
      if (available == null) return;
      _pendingRememberedPhone = false;
      if (available &&
          !_userTouchedFlowOrInput &&
          !_codeStep &&
          !_phoneDisabled &&
          _email.text.isEmpty) {
        setState(() => _flow = _Flow.phoneCode);
      }
    });
    final l10n = AuthL10n.of(context);
    final ui = context.ui;
    final codeStep = _codeStep;
    final showLegal = !codeStep && _flow != _Flow.reset;
    final stepKey = codeStep
        ? 'auth-step-code'
        : (_flow == _Flow.emailCode
              ? 'auth-step-email'
              : 'auth-step-${_flow.name}');

    return UiScaffold(
      key: const ValueKey('auth-screen'),
      // The code step and the sub-forms start under a back header.
      padTop: codeStep || _subForm ? 4 : 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (codeStep)
            Align(
              alignment: Alignment.centerLeft,
              child: UiIconButton(
                key: const ValueKey('auth-back'),
                glyph: OurneyIcon(name: 'back', flat: true, color: ui.ink),
                label: l10n.auth_back,
                onPressed: _busy ? null : _backToForm,
              ),
            )
          else if (_subForm)
            Align(
              alignment: Alignment.centerLeft,
              child: UiIconButton(
                key: const ValueKey('auth-flow-back'),
                glyph: OurneyIcon(name: 'back', flat: true, color: ui.ink),
                label: l10n.auth_back,
                onPressed: _busy
                    ? null
                    : () => _goFlow(
                        _flow == _Flow.reset ? _Flow.password : _Flow.emailCode,
                      ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: UiRansomWordmark(size: _wordmarkSize),
              ),
            ),
          SizedBox(height: codeStep || _subForm ? 12 : 10),
          UiDirectionalSwitcher(
            step: stepKey,
            direction: _flowDirection,
            duration: UiMotion.medium,
            animateSize: true,
            alignment: Alignment.topCenter,
            child: Column(
              key: ValueKey(stepKey),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(_title(l10n), style: _h1Style(ui.ink)),
                ),
                if (codeStep) ...[
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${l10n.auth_codeSentPrefix} '),
                        TextSpan(
                          text: _destination,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    style: UiText.body(
                      size: 16,
                      height: 1.4,
                      color: ui.inkMuted,
                    ),
                  ),
                  UiTextAction(
                    key: const ValueKey('auth-change-email'),
                    label: _isPhone
                        ? l10n.auth_changePhone
                        : l10n.auth_changeEmail,
                    size: 14,
                    underline: true,
                    color: ui.ink,
                    alignment: Alignment.centerLeft,
                    onPressed: _busy ? null : _backToForm,
                  ),
                ] else if (_flow != _Flow.password) ...[
                  const SizedBox(height: 10),
                  Text(
                    _subtitle(l10n),
                    key: const ValueKey('auth-subtitle'),
                    style: UiText.muted(color: ui.inkMuted),
                  ),
                ],
                if (_offline) ...[
                  const SizedBox(height: 12),
                  UiBanner(
                    key: const ValueKey('auth-offline'),
                    message: l10n.auth_offlineBanner,
                    retryLabel: l10n.auth_retry,
                    onRetry: () {
                      ref.invalidate(phoneAuthAvailableProvider);
                      setState(() => _offline = false);
                    },
                  ),
                ],
                SizedBox(height: codeStep ? 14 : 18),
                if (codeStep)
                  ..._codeChildren(l10n, ui)
                else
                  ..._formChildren(l10n, ui, showLegal: showLegal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get _wordmarkSize => 120;

  /// `.flow-screen h1`: Space Grotesk 32 / 700 / -0.045em, lowercase copy.
  TextStyle _h1Style(Color color) => UiText.heading(
    font: 'Space Grotesk',
    size: 32,
    weight: 700,
    height: 1.25,
    tracking: -0.045,
    color: color,
  );

  String get _destination =>
      _isPhone ? formatPhoneForDisplay(_e164 ?? _phone.text) : _normalizedEmail;

  List<Widget> _formChildren(
    AuthL10n l10n,
    OurneyUi ui, {
    required bool showLegal,
  }) {
    final emailError =
        _submitted && !_isPhone && !_emailPattern.hasMatch(_normalizedEmail)
        ? l10n.auth_emailInvalid
        : null;
    final phoneError = _submitted && _isPhone && _e164 == null
        ? l10n.auth_phoneInvalid
        : null;
    final showSwitch =
        (_flow == _Flow.emailCode || _flow == _Flow.phoneCode) &&
        _phoneAvailable;
    return [
      if (showSwitch) ...[
        Semantics(
          container: true,
          label: l10n.auth_methodLabel,
          child: UiSegmented<_Tab>(
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
            onChanged: (t) {
              if (_busy) return;
              _goFlow(t == _Tab.phone ? _Flow.phoneCode : _Flow.emailCode);
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
      if (_isPhone)
        UiTextField(
          fieldKey: const ValueKey('auth-phone'),
          label: l10n.auth_phoneLabel,
          hint: l10n.auth_phoneHint,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OurneyIcon(name: 'phone', size: 22, flat: true, color: ui.ink),
              const SizedBox(width: 10),
              Text(
                l10n.auth_phonePrefix,
                style: UiText.body(
                  size: 16,
                  weight: FontWeight.w700,
                  color: ui.ink,
                ),
              ),
            ],
          ),
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
          leading: OurneyIcon(
            name: 'mail',
            size: 22,
            flat: true,
            color: ui.ink,
          ),
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          textInputAction: _needsPasswordField
              ? TextInputAction.next
              : TextInputAction.send,
          error: emailError,
          onChanged: (_) {
            _userTouchedFlowOrInput = true;
            _pendingRememberedPhone = false;
            if (_passwordSignInFailed) {
              setState(() => _passwordSignInFailed = false);
            }
          },
          onSubmitted: (_) =>
              _busy || _needsPasswordField ? null : _submitForm(),
        ),
      if (_needsPasswordField) ...[
        const SizedBox(height: UiSpace.md),
        _passwordField(l10n, label: l10n.auth_passwordLabel),
      ],
      if (_error != null)
        UiFlowError(key: const ValueKey('auth-error'), message: _error!),
      if (_flow == _Flow.password && _passwordSignInFailed) ...[
        const SizedBox(height: UiSpace.sm),
        UiButton.secondary(
          key: const ValueKey('auth-send-code-instead'),
          label: l10n.auth_sendCodeForEmail,
          compact: true,
          glyph: OurneyIcon(name: 'mail', size: 18, flat: true, color: ui.ink),
          onPressed: _busy ? null : _sendCodeForCurrentEmail,
        ),
      ],
      const SizedBox(height: 20),
      UiFlowButton(
        key: const ValueKey('auth-send'),
        label: _primaryLabel(l10n),
        onPressed: _busy ? null : _submitForm,
      ),
      if (showLegal) ...[
        const SizedBox(height: 14),
        _Legal(
          intro: l10n.auth_legalIntro,
          and: l10n.auth_legalAnd,
          terms: l10n.auth_terms,
          privacy: l10n.auth_privacy,
          onTerms: () => context.push(SafetyPaths.eula),
          onPrivacy: () => context.push(SafetyPaths.privacy),
        ),
      ],
      const SizedBox(height: 4),
      _links(l10n),
    ];
  }

  Widget _passwordField(
    AuthL10n l10n, {
    required String label,
    String? error,
    bool newPassword = false,
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
      newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    textInputAction: TextInputAction.done,
    error: error,
    onChanged: (_) => setState(() {}),
    onSubmitted: (_) => _busy ? null : (_codeStep ? _verify() : _submitForm()),
    trailing: UiIconButton(
      key: const ValueKey('auth-password-toggle'),
      glyph: OurneyIcon(
        name: _showPassword ? 'eye-off' : 'eye',
        size: 20,
        flat: true,
        color: context.ui.ink,
      ),
      label: _showPassword ? l10n.auth_hidePassword : l10n.auth_showPassword,
      onPressed: _busy
          ? null
          : () => setState(() => _showPassword = !_showPassword),
    ),
  );

  /// Secondary method actions: 14dp bold underlined, 48dp targets, left
  /// aligned (one per line so none of them reads as body text).
  Widget _links(AuthL10n l10n) {
    final ink = context.ui.ink;
    Widget link(String key, String label, VoidCallback onPressed) =>
        UiTextAction(
          key: ValueKey(key),
          label: label,
          size: 14,
          underline: true,
          color: ink,
          alignment: Alignment.centerLeft,
          onPressed: _busy ? null : onPressed,
        );
    final links = switch (_flow) {
      _Flow.emailCode => [
        link(
          'auth-use-password',
          l10n.auth_usePassword,
          () => _goFlow(_Flow.password),
        ),
      ],
      _Flow.password => [
        link('auth-forgot', l10n.auth_forgot, () => _goFlow(_Flow.reset)),
        link(
          'auth-use-code',
          l10n.auth_useCode,
          () => _goFlow(_Flow.emailCode),
        ),
      ],
      _Flow.reset => [
        link(
          'auth-back-to-sign-in',
          l10n.auth_backToSignIn,
          () => _goFlow(_Flow.password),
        ),
      ],
      _Flow.phoneCode => <Widget>[],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: links,
    );
  }

  List<Widget> _codeChildren(AuthL10n l10n, OurneyUi ui) {
    final reset = _flow == _Flow.reset;
    final hasError = _error != null;
    final complete = _codePattern.hasMatch(_code.text.trim());
    final reduced = UiMotion.reduced(context);
    final shakeAnim = reduced
        ? kAlwaysDismissedAnimation
        : _ensureOtpShakeCtrl();
    return [
      AnimatedBuilder(
        animation: shakeAnim,
        child: AnimatedOpacity(
          opacity: _busy ? 0.48 : 1,
          duration: UiMotion.of(context, UiMotion.fast),
          curve: UiCurves.easeOutStrong,
          child: UiOtpField(
            key: const ValueKey('auth-code'),
            controller: _code,
            focusNode: _codeFocus,
            digitLabel: l10n.auth_codeLabel,
            enabled: !_busy,
            hasError: hasError,
            onChanged: (value) {
              setState(() {
                if (_error != null) _error = null;
              });
              if (value.length == 6 && !_busy && !reset) _verify();
            },
            onSubmitted: (_) => _busy ? null : _verify(),
          ),
        ),
        builder: (context, child) {
          final dx = UiMotion.reduced(context)
              ? 0.0
              : _otpShakeDx(shakeAnim.value);
          return Transform.translate(
            key: const ValueKey('auth-otp-shake'),
            offset: Offset(dx, 0),
            child: child,
          );
        },
      ),
      const SizedBox(height: 16),
      if (_busy)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l10n.auth_verifying,
            style: UiText.body(size: 13, height: 1.4, color: ui.inkMuted),
          ),
        ),
      if (_success)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l10n.auth_success,
            style: UiText.body(
              size: 13,
              weight: FontWeight.w700,
              height: 1.4,
              color: ui.success,
            ),
          ),
        ),
      if (_error != null)
        UiFlowError(key: const ValueKey('auth-error'), message: _error!),
      if (reset) ...[
        const SizedBox(height: UiSpace.md),
        _passwordField(
          l10n,
          label: l10n.auth_newPasswordLabel,
          newPassword: true,
          fieldKey: const ValueKey('auth-new-password'),
          error: _submitted && _password.text.length < AuthScreen.minPassword
              ? l10n.auth_passwordShort
              : null,
        ),
      ],
      const SizedBox(height: 4),
      UiFlowButton(
        key: const ValueKey('auth-verify'),
        label: reset ? l10n.auth_resetConfirm : l10n.auth_verify,
        onPressed: _busy || !complete ? null : _verify,
      ),
      // `.resend-row`: 52dp, ring + countdown, then an outlined capsule.
      Container(
        constraints: const BoxConstraints(minHeight: 52),
        margin: const EdgeInsets.only(top: 18),
        alignment: Alignment.center,
        child: _cooldown > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiTimerRing(fraction: _cooldown / AuthScreen.resendCooldown),
                  const SizedBox(width: 9),
                  Flexible(
                    child: UiTextAction(
                      key: const ValueKey('auth-resend'),
                      size: 13,
                      color: ui.inkMuted,
                      expand: false,
                      label: l10n.auth_resendIn(_cooldown),
                      onPressed: null,
                    ),
                  ),
                ],
              )
            : UiButton.secondary(
                key: const ValueKey('auth-resend'),
                label: l10n.auth_resend,
                compact: true,
                expand: false,
                onPressed: _busy ? null : () => _submitForm(resend: true),
              ),
      ),
      const SizedBox(height: UiSpace.sm),
      Text(
        _isPhone ? l10n.auth_otpHelperSms : l10n.auth_otpHelperEmail,
        textAlign: TextAlign.center,
        style: UiText.muted(color: ui.inkMuted, size: 13),
      ),
    ];
  }
}

/// `.legal-copy`: "By continuing you agree to the Terms and Privacy Policy",
/// 13dp muted with bold ink links (48dp targets).
class _Legal extends StatelessWidget {
  const _Legal({
    required this.intro,
    required this.and,
    required this.terms,
    required this.privacy,
    required this.onTerms,
    required this.onPrivacy,
  });

  final String intro;
  final String and;
  final String terms;
  final String privacy;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final muted = UiText.body(size: 13, height: 1.4, color: ui.inkMuted);
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(intro, style: muted),
        UiTextAction(
          key: const ValueKey('auth-terms'),
          label: terms,
          size: 13,
          underline: true,
          color: ui.ink,
          expand: false,
          onPressed: onTerms,
        ),
        Text(and, style: muted),
        UiTextAction(
          key: const ValueKey('auth-privacy'),
          label: privacy,
          size: 13,
          underline: true,
          color: ui.ink,
          expand: false,
          onPressed: onPrivacy,
        ),
      ],
    );
  }
}
