import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/app_routes.dart';
import '../../app/providers.dart';
import '../../app/theme/motion.dart';
import '../../app/theme/tokens.dart';
import '../../shared/chunky_button.dart';
import '../profile/routes.dart' show profileSetupPath;
import '../profile/widgets/inline_error.dart';
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
    final c = OurneyColors.of(context);
    final text = Theme.of(context).textTheme;
    final isEmail = _step == _Step.email;

    return Scaffold(
      key: const ValueKey('auth-screen'),
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isEmail)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('auth-change-email'),
                    onPressed: _busy ? null : _changeEmail,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(l10n.auth_changeEmail),
                  ),
                )
              else
                const SizedBox(height: OurneySizes.minTap),
              const SizedBox(height: OurneySpacing.lg),
              const _Badge(),
              const SizedBox(height: OurneySpacing.xl),
              AnimatedSwitcher(
                duration: OurneyMotion.duration(
                  context,
                  OurneyDurations.navigation,
                ),
                child: isEmail
                    ? _EmailStep(
                        key: const ValueKey('auth-step-email'),
                        controller: _email,
                        busy: _busy,
                        errorText:
                            _emailSubmitted &&
                                !_emailPattern.hasMatch(_normalizedEmail)
                            ? l10n.auth_emailInvalid
                            : null,
                        onSubmit: _sendOtp,
                      )
                    : _CodeStep(
                        key: const ValueKey('auth-step-code'),
                        email: _normalizedEmail,
                        controller: _code,
                        focusNode: _codeFocus,
                        busy: _busy,
                        cooldown: _cooldown,
                        errorText:
                            _codeSubmitted &&
                                !_codePattern.hasMatch(_code.text.trim())
                            ? l10n.auth_codeInvalidFormat
                            : null,
                        onSubmit: _verify,
                        onResend: () => _sendOtp(resend: true),
                      ),
              ),
              if (_error != null) ...[
                const SizedBox(height: OurneySpacing.lg),
                InlineError(
                  key: const ValueKey('auth-error'),
                  message: _error!,
                ),
              ],
              if (_info != null) ...[
                const SizedBox(height: OurneySpacing.lg),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read_rounded, color: c.accent),
                      const SizedBox(width: OurneySpacing.sm),
                      Expanded(child: Text(_info!, style: text.bodyMedium)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: OurneySpacing.xxl),
              Text(
                l10n.auth_termsNote,
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
              Center(
                child: TextButton(
                  key: const ValueKey('auth-terms'),
                  onPressed: () => context.push(AppRoutes.safety),
                  child: Text(l10n.auth_termsLink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 72,
        height: 72,
        // V1.0 brand mark: coral square, ink glyph.
        decoration: BoxDecoration(
          color: OurneyColors.of(context).primary,
          borderRadius: BorderRadius.circular(OurneyRadii.card),
        ),
        child: Icon(
          Icons.mail_outline_rounded,
          color: OurneyColors.of(context).onPrimary,
          size: 34,
        ),
      ),
    ),
  );
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    required this.controller,
    required this.busy,
    required this.errorText,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController controller;
  final bool busy;
  final String? errorText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AuthL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.auth_title, style: text.displayLarge),
        ),
        const SizedBox(height: OurneySpacing.sm),
        Text(
          l10n.auth_subtitle,
          style: text.bodyLarge?.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: OurneySpacing.xl),
        TextField(
          key: const ValueKey('auth-email'),
          controller: controller,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => busy ? null : onSubmit(),
          decoration: InputDecoration(
            labelText: l10n.auth_emailLabel,
            hintText: l10n.auth_emailHint,
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            errorText: errorText,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: OurneySpacing.xl),
        ChunkyButton(
          key: const ValueKey('auth-send'),
          label: busy ? l10n.auth_sending : l10n.auth_sendCode,
          icon: busy ? null : Icons.send_rounded,
          onPressed: busy ? null : onSubmit,
        ),
      ],
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({
    required this.email,
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.cooldown,
    required this.errorText,
    required this.onSubmit,
    required this.onResend,
    super.key,
  });

  final String email;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final int cooldown;
  final String? errorText;
  final VoidCallback onSubmit;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = AuthL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.auth_codeTitle, style: text.displayLarge),
        ),
        const SizedBox(height: OurneySpacing.sm),
        Text(
          l10n.auth_codeSentTo(email),
          style: text.bodyLarge?.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: OurneySpacing.xl),
        TextField(
          key: const ValueKey('auth-code'),
          controller: controller,
          focusNode: focusNode,
          enabled: !busy,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          style: text.displayMedium?.copyWith(letterSpacing: 8),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (value) {
            if (value.length == 6 && !busy) onSubmit();
          },
          onSubmitted: (_) => busy ? null : onSubmit(),
          decoration: InputDecoration(
            labelText: l10n.auth_codeLabel,
            errorText: errorText,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: OurneySpacing.xl),
        ChunkyButton(
          key: const ValueKey('auth-verify'),
          label: busy ? l10n.auth_verifying : l10n.auth_verify,
          icon: busy ? null : Icons.check_rounded,
          onPressed: busy ? null : onSubmit,
        ),
        const SizedBox(height: OurneySpacing.md),
        Center(
          child: TextButton.icon(
            key: const ValueKey('auth-resend'),
            onPressed: busy || cooldown > 0 ? null : onResend,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              cooldown > 0 ? l10n.auth_resendIn(cooldown) : l10n.auth_resend,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
