import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../ui/ui.dart';
import '../profile/routes.dart' show profileSetupPath;
import 'auth_errors.dart';
import 'l10n/generated/auth_localizations.dart';

/// Email OTP sign-in (FR-A1): email -> 6-digit code.
///
/// Calls `AuthRepository.sendOtp(email)` and `verifyOtp(email, code)`. On
/// success the repository's `watchUserId()` emits and the router leaves
/// `/auth` by itself. If `ProfileRepository.watchMe()` then yields null (first
/// sign-in), this screen sends the user to `/profile/setup?from=<target>`.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({this.from, super.key});

  /// Sanitized `?from=` target to continue to after sign-in.
  final String? from;

  /// Seconds before "resend code" is enabled again.
  static const resendCooldown = 60;

  /// How long to wait for the profile after sign-in before giving up on the
  /// first-sign-in check (the profile screen offers setup later anyway).
  static const profileCheckTimeout = Duration(seconds: 10);

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _Step { email, code }

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _codePattern = RegExp(r'^\d{6}$');

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  _Step _step = _Step.email;
  bool _busy = false;
  bool _emailSubmitted = false;
  bool _codeSubmitted = false;
  String? _error;
  String? _info;
  int _cooldown = 0;
  Timer? _timer;

  String get _normalizedEmail => _email.text.trim().toLowerCase();

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
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

  Future<void> _sendOtp({bool resend = false}) async {
    final l10n = AuthL10n.of(context);
    setState(() {
      _emailSubmitted = true;
      _error = null;
      _info = null;
    });
    if (!_emailPattern.hasMatch(_normalizedEmail)) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(_normalizedEmail);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorMessage(l10n, e, AuthStep.sendOtp);
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _step = _Step.code;
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

    // Capture everything before awaiting: the router may replace this screen
    // as soon as the user id is emitted.
    final router = GoRouter.of(context);
    final auth = ref.read(authRepositoryProvider);
    ProfileRepository? profiles;
    try {
      profiles = ref.read(profileRepositoryProvider);
    } on Object {
      profiles = null; // Not wired: skip the first-sign-in check.
    }
    final from = widget.from;

    setState(() => _busy = true);
    try {
      await auth.verifyOtp(_normalizedEmail, code);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorMessage(l10n, e, AuthStep.verifyOtp);
      });
      return;
    }
    OurneyHaptics.success();

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

  void _changeEmail() {
    _timer?.cancel();
    setState(() {
      _step = _Step.email;
      _code.clear();
      _error = null;
      _info = null;
      _cooldown = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AuthL10n.of(context);
    final ui = context.ui;
    final isEmail = _step == _Step.email;
    final emailError =
        _emailSubmitted && !_emailPattern.hasMatch(_normalizedEmail)
        ? l10n.auth_emailInvalid
        : null;
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
              key: ValueKey(isEmail ? 'auth-step-email' : 'auth-step-code'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiEyebrow(isEmail ? l10n.auth_eyebrow : l10n.auth_eyebrowCheck),
                const SizedBox(height: 5),
                Semantics(
                  header: true,
                  child: Text(l10n.auth_title, style: UiText.h1(color: ui.ink)),
                ),
                const SizedBox(height: 8),
                Text(
                  isEmail
                      ? l10n.auth_subtitle
                      : l10n.auth_codeSentTo(_normalizedEmail),
                  style: UiText.muted(color: ui.inkMuted),
                ),
                const SizedBox(height: 28),
                if (isEmail) ...[
                  UiTextField(
                    fieldKey: const ValueKey('auth-email'),
                    label: l10n.auth_emailLabel,
                    hint: l10n.auth_emailHint,
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    textInputAction: TextInputAction.send,
                    error: emailError,
                    onSubmitted: (_) => _busy ? null : _sendOtp(),
                  ),
                  const SizedBox(height: 18),
                  UiButton(
                    key: const ValueKey('auth-send'),
                    label: _busy ? l10n.auth_sending : l10n.auth_sendCode,
                    loading: _busy,
                    onPressed: _busy ? null : _sendOtp,
                  ),
                ] else ...[
                  UiOtpField(
                    key: const ValueKey('auth-code'),
                    controller: _code,
                    focusNode: _codeFocus,
                    digitLabel: l10n.auth_codeLabel,
                    enabled: !_busy,
                    hasError: codeError != null || _error != null,
                    onChanged: (value) {
                      if (value.length == 6 && !_busy) _verify();
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
                  const SizedBox(height: 18),
                  UiButton(
                    key: const ValueKey('auth-verify'),
                    label: _busy ? l10n.auth_verifying : l10n.auth_verify,
                    loading: _busy,
                    onPressed: _busy ? null : _verify,
                  ),
                  const SizedBox(height: 8),
                  UiTextAction(
                    key: const ValueKey('auth-resend'),
                    size: 13,
                    color: _cooldown > 0 ? ui.inkMuted : null,
                    label: _cooldown > 0
                        ? l10n.auth_resendIn(_cooldown)
                        : l10n.auth_resend,
                    onPressed: _busy || _cooldown > 0
                        ? null
                        : () => _sendOtp(resend: true),
                  ),
                  UiTextAction(
                    key: const ValueKey('auth-change-email'),
                    label: l10n.auth_changeEmail,
                    onPressed: _busy ? null : _changeEmail,
                  ),
                ],
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
                  Icon(Icons.mark_email_read_outlined, color: ui.success),
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
