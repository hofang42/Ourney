import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../auth/auth_providers.dart';
import '../l10n/generated/profile_localizations.dart';
import '../settings_providers.dart';

enum PasswordSheetMode { set, change }

/// 2-step password setup / rotation sheet (`Settings -> Bảo mật`):
///
/// 1. New password (>= 8 chars, show/hide toggle) + in [PasswordSheetMode.change]
///    a default-ON "Sign out of other devices" switch. Submitting triggers
///    `AuthRepository.sendPasswordReset(email)` to email a 6-digit recovery
///    code (or, if a 6-digit code was already verified in this sheet before a
///    `same_password` / `weak_password` response, saves directly on the kept
///    verified session without sending a second email).
/// 2. 6-digit verification code (`UiOtpField`) + 60s resend cooldown. Submitting
///    calls `AuthRepository.updatePassword(newPassword, code: code,
///    signOutOthers: ...)` so GoTrue always verifies the recovery OTP before
///    updating `encrypted_password`.
class PasswordSheet extends ConsumerStatefulWidget {
  const PasswordSheet({
    required this.email,
    required this.mode,
    super.key,
  });

  final String email;
  final PasswordSheetMode mode;

  /// Seconds before "resend code" is enabled again.
  static const int resendCooldown = 60;

  /// Minimum password length (matches `minimum_password_length = 8`).
  static const int minPasswordLength = 8;

  static Future<bool?> show(
    BuildContext context, {
    required String email,
    required PasswordSheetMode mode,
  }) => showUiSheet<bool>(
    context: context,
    dismissible: false,
    builder: (_) => PasswordSheet(email: email, mode: mode),
  );

  @override
  ConsumerState<PasswordSheet> createState() => _PasswordSheetState();
}

enum _Stage { password, code }

class _PasswordSheetState extends ConsumerState<PasswordSheet> {
  final _newPassword = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  final Set<String> _rejectedSamePasswords = <String>{};

  _Stage _stage = _Stage.password;
  int _direction = 1;
  bool _showPassword = false;
  bool _signOutOthers = true;
  bool _submitted = false;
  bool _busy = false;
  bool _saved = false;
  String? _verifiedCode;
  String? _error;
  String? _info;
  int _cooldown = 0;
  Timer? _timer;
  late final AuthRepository _auth = ref.read(authRepositoryProvider);

  bool get _isChange => widget.mode == PasswordSheetMode.change;

  @override
  void dispose() {
    _timer?.cancel();
    if (!_saved) {
      unawaited(_auth.cancelPasswordFlow());
    }
    _newPassword.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _cancelSheet() {
    if (_busy) return;
    _verifiedCode = null;
    unawaited(_auth.cancelPasswordFlow());
    Navigator.of(context).pop(false);
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = PasswordSheet.resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  String _mapError(Object e, ProfileL10n l10n, {required bool isSend}) {
    final code = e is OurneyException ? e.error : OurneyErrorCode.unknown;
    return switch (code) {
      OurneyErrorCode.rateLimited => l10n.profile_password_rateLimited,
      OurneyErrorCode.offline => l10n.profile_offlineError,
      _ =>
        isSend
            ? l10n.profile_password_sendError
            : l10n.profile_password_saveError,
    };
  }

  void _backToPassword() {
    if (_busy) return;
    setState(() {
      _direction = -1;
      _stage = _Stage.password;
      _code.clear();
      _error = null;
      _info = null;
    });
  }

  /// Step 1 -> 2 (or direct save when `_verifiedCode` is already verified):
  /// validates the new password client-side first, then either reuses the
  /// already-verified recovery code, returns to Step 2 while the 60s cooldown
  /// from an already-sent code is active, or sends a 6-digit recovery code to
  /// [widget.email].
  Future<void> _requestCode({bool resend = false}) async {
    final l10n = ProfileL10n.of(context);
    setState(() {
      _submitted = true;
      _error = null;
      _info = null;
    });
    if (_newPassword.text.length < PasswordSheet.minPasswordLength) {
      unawaited(UiHaptics.reject());
      return;
    }
    if (_rejectedSamePasswords.contains(_newPassword.text)) {
      setState(() => _error = l10n.profile_password_sameError);
      unawaited(UiHaptics.reject());
      return;
    }
    if (!resend && _verifiedCode != null) {
      await _submitCode(codeOverride: _verifiedCode);
      return;
    }
    if (!resend && _cooldown > 0) {
      setState(() {
        _direction = 1;
        _stage = _Stage.code;
      });
      _codeFocus.requestFocus();
      return;
    }
    final auth = _auth;
    setState(() => _busy = true);
    try {
      await auth.sendPasswordReset(widget.email);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _mapError(e, l10n, isSend: true);
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _verifiedCode = null;
      _direction = 1;
      _stage = _Stage.code;
      if (resend) {
        _info = l10n.profile_password_codeResent;
        _code.clear();
      }
    });
    _startCooldown();
    _codeFocus.requestFocus();
  }

  /// Step 2 (or direct retry after `same_password`): submits [newPassword]
  /// with the 6-digit recovery [code].
  Future<void> _submitCode({String? codeOverride}) async {
    final l10n = ProfileL10n.of(context);
    final code = (codeOverride ?? _code.text).trim();
    if (code.length != 6 || _busy) return;

    final auth = ref.read(authRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final hasPwNotifier = ref.read(hasPasswordProvider.notifier);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final savedToast = _isChange
        ? l10n.profile_password_savedChanged
        : l10n.profile_password_savedSet;

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    try {
      await auth.updatePassword(
        _newPassword.text,
        code: code,
        signOutOthers: _isChange && _signOutOthers,
      );
    } on Object catch (e) {
      if (!mounted) return;
      final errCode = e is OurneyException ? e.error : OurneyErrorCode.unknown;
      final detail = e is OurneyException ? (e.detail ?? '') : '';
      if (detail.contains('same_password')) {
        _timer?.cancel();
        _rejectedSamePasswords.add(_newPassword.text);
        setState(() {
          _busy = false;
          _verifiedCode = code;
          _direction = -1;
          _stage = _Stage.password;
          _code.clear();
          _cooldown = 0;
          _error = l10n.profile_password_sameError;
        });
        unawaited(UiHaptics.reject());
        return;
      }
      if (detail.contains('weak_password')) {
        _timer?.cancel();
        setState(() {
          _busy = false;
          _verifiedCode = code;
          _direction = -1;
          _stage = _Stage.password;
          _code.clear();
          _cooldown = 0;
          _error = l10n.profile_password_shortError;
        });
        unawaited(UiHaptics.reject());
        return;
      }
      final isBadCode =
          errCode == OurneyErrorCode.invalid ||
          errCode == OurneyErrorCode.unauthenticated;
      setState(() {
        _busy = false;
        _verifiedCode = null;
        if (isBadCode) {
          _code.clear();
        }
        _error = isBadCode
            ? l10n.profile_password_codeWrong
            : _mapError(e, l10n, isSend: false);
      });
      if (isBadCode) unawaited(UiHaptics.reject());
      return;
    }

    await hasPwNotifier.setHasPassword(true);
    await prefs.setString(
      AuthMethodPrefs.lastMethodKey,
      RememberedAuthMethod.password.wireName,
    );
    _saved = true;
    unawaited(UiHaptics.success());
    if (!mounted) return;
    Navigator.of(context).pop(true);
    showUiToast(context, savedToast, messenger: messenger);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    final title = switch (_stage) {
      _Stage.password =>
        _isChange
            ? l10n.profile_password_changeTitle
            : l10n.profile_password_setTitle,
      _Stage.code => l10n.profile_password_codeTitle,
    };

    return PopScope(
      canPop: !_busy,
      child: Column(
        key: const ValueKey('profile-password-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiDirectionalSwitcher(
            step: _stage.name,
            direction: _direction,
            duration: UiMotion.medium,
            animateSize: true,
            alignment: Alignment.topCenter,
            child: Column(
              key: ValueKey('password-sheet-stage-${_stage.name}'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (_stage == _Stage.code) ...[
                      UiIconButton(
                        key: const ValueKey('password-sheet-back'),
                        glyph: OurneyIcon(
                          name: 'back',
                          flat: true,
                          color: ui.ink,
                        ),
                        label: l10n.profile_back,
                        onPressed: _busy ? null : _backToPassword,
                      ),
                      const SizedBox(width: UiSpace.xs),
                    ] else ...[
                      OurneyIcon(
                        name: 'lock',
                        flat: true,
                        color: ui.ink,
                        size: 26,
                      ),
                      const SizedBox(width: UiSpace.sm),
                    ],
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: UiText.h2(color: ui.ink)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UiSpace.sm),
                ...switch (_stage) {
                  _Stage.password => _passwordChildren(l10n, ui),
                  _Stage.code => _codeChildren(l10n, ui),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _passwordChildren(ProfileL10n l10n, OurneyUi ui) {
    final shortError =
        _submitted && _newPassword.text.length < PasswordSheet.minPasswordLength
        ? l10n.profile_password_shortError
        : null;
    return [
      Text(
        l10n.profile_password_setLead(widget.email),
        style: UiText.muted(color: ui.inkMuted, size: 14),
      ),
      const SizedBox(height: UiSpace.lg),
      UiTextField(
        fieldKey: const ValueKey('password-sheet-new'),
        label: l10n.profile_password_newLabel,
        controller: _newPassword,
        enabled: !_busy,
        obscureText: !_showPassword,
        autocorrect: false,
        keyboardType: TextInputType.visiblePassword,
        autofillHints: const [AutofillHints.newPassword],
        textInputAction: TextInputAction.done,
        error: shortError,
        onChanged: (_) {
          if (_submitted || _error != null) {
            setState(() => _error = null);
          }
        },
        onSubmitted: (_) => _busy ? null : _requestCode(),
        trailing: UiIconButton(
          key: const ValueKey('password-sheet-toggle-visibility'),
          glyph: OurneyIcon(
            name: _showPassword ? 'eye-off' : 'eye',
            size: 20,
            flat: true,
            color: ui.ink,
          ),
          label: _showPassword
              ? l10n.profile_password_hide
              : l10n.profile_password_show,
          onPressed: _busy
              ? null
              : () => setState(() => _showPassword = !_showPassword),
        ),
      ),
      if (_isChange) ...[
        const SizedBox(height: UiSpace.sm),
        UiSwitchRow(
          key: const ValueKey('password-sheet-sign-out-others'),
          label: l10n.profile_password_signOutOthers,
          subtitle: l10n.profile_password_signOutOthersSub,
          value: _signOutOthers,
          divider: false,
          onChanged: _busy
              ? null
              : (v) => setState(() => _signOutOthers = v),
        ),
      ],
      if (_error != null) ...[
        const SizedBox(height: UiSpace.sm),
        UiInlineError(
          key: const ValueKey('password-sheet-error'),
          message: _error!,
        ),
      ],
      const SizedBox(height: UiSpace.lg),
      UiButton(
        key: const ValueKey('password-sheet-continue'),
        label: _verifiedCode != null
            ? (_busy ? l10n.profile_password_saving : l10n.profile_password_save)
            : (_busy
                  ? l10n.profile_password_sending
                  : l10n.profile_password_continue),
        loading: _busy,
        onPressed: _busy ? null : _requestCode,
      ),
      const SizedBox(height: UiSpace.sm),
      UiButton.secondary(
        key: const ValueKey('password-sheet-cancel'),
        label: AppLocalizations.of(context).common_cancel,
        onPressed: _busy ? null : _cancelSheet,
      ),
    ];
  }

  List<Widget> _codeChildren(ProfileL10n l10n, OurneyUi ui) {
    final complete = _code.text.trim().length == 6;
    return [
      Text(
        l10n.profile_password_codeLead(widget.email),
        style: UiText.muted(color: ui.inkMuted, size: 14),
      ),
      const SizedBox(height: UiSpace.lg),
      UiOtpField(
        key: const ValueKey('password-sheet-otp'),
        controller: _code,
        focusNode: _codeFocus,
        digitLabel: l10n.profile_password_codeLabel,
        enabled: !_busy,
        hasError: _error != null,
        onChanged: (v) {
          setState(() => _error = null);
          if (v.trim().length == 6 && !_busy) {
            unawaited(_submitCode());
          }
        },
        onSubmitted: (_) => complete && !_busy ? _submitCode() : null,
      ),
      if (_error != null) ...[
        const SizedBox(height: UiSpace.sm),
        UiInlineError(
          key: const ValueKey('password-sheet-error'),
          message: _error!,
        ),
      ],
      if (_info != null) ...[
        const SizedBox(height: UiSpace.sm),
        Semantics(
          liveRegion: true,
          child: Text(_info!, style: UiText.body(size: 13, color: ui.success)),
        ),
      ],
      UiTextAction(
        key: const ValueKey('password-sheet-resend'),
        size: 13,
        color: _cooldown > 0 ? ui.inkMuted : null,
        label: _cooldown > 0
            ? l10n.profile_password_resendIn(_cooldown)
            : l10n.profile_password_resend,
        onPressed: _busy || _cooldown > 0
            ? null
            : () => _requestCode(resend: true),
      ),
      const SizedBox(height: UiSpace.lg),
      UiButton(
        key: const ValueKey('password-sheet-confirm'),
        label: _busy ? l10n.profile_password_saving : l10n.profile_password_save,
        loading: _busy,
        onPressed: complete && !_busy ? _submitCode : null,
      ),
      const SizedBox(height: UiSpace.sm),
      UiButton.secondary(
        key: const ValueKey('password-sheet-cancel'),
        label: AppLocalizations.of(context).common_cancel,
        onPressed: _busy ? null : _cancelSheet,
      ),
    ];
  }
}
