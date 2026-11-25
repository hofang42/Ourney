import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../auth/auth_providers.dart';
import '../../feedback/data/feedback_providers.dart';
import '../../onboarding/onboarding_providers.dart';
import '../../safety/data/safety_providers.dart';
import '../l10n/generated/profile_localizations.dart';

/// 3-step account deletion (FR-A4, Figma `DeleteAccountScreen`):
///
/// 1. confirm: what goes away + "I understand" checkbox,
/// 2. one-time code (sent by the `delete-account` Edge Function to the
///    account's own email / phone; verified again server-side on delete),
/// 3. progress: deleting, done, or a retryable error.
///
/// Calls `AuthRepository.requestDeleteCode()` entering step 2 and
/// `deleteAccount(code:)` from step 2 itself, so errors (safe to retry) show
/// in place. On success it resets onboarding, the quiz and the EULA
/// acceptance and pops `true`. The router then leaves the signed-in area by
/// itself. Local-only repositories skip the code step. Shown in a kit sheet.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  /// Seconds before "resend code" is enabled again.
  static const resendCooldown = 30;

  static Future<bool?> show(BuildContext context) => showUiSheet<bool>(
    context: context,
    dismissible: false,
    builder: (_) => const DeleteAccountDialog(),
  );

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

enum _Stage { confirm, code, progress }

enum _Result { deleting, done, error }

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  _Stage _stage = _Stage.confirm;
  _Result _result = _Result.deleting;
  bool _understood = false;
  bool _busy = false;
  String? _error;
  String? _info;
  String? _finalError;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = DeleteAccountDialog.resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  String _messageFor(Object e, ProfileL10n l10n) {
    final code = e is OurneyException ? e.error : OurneyErrorCode.unknown;
    return switch (code) {
      OurneyErrorCode.unauthenticated => l10n.profile_deleteErrorReauth,
      OurneyErrorCode.offline => l10n.profile_offlineError,
      _ => l10n.profile_deleteErrorRetry,
    };
  }

  /// Step 1 -> 2: asks the server to send the code.
  Future<void> _toCodeStep({bool resend = false}) async {
    final l10n = ProfileL10n.of(context);
    final auth = ref.read(authRepositoryProvider);
    if (auth.isLocalOnly) {
      // Nothing server-side to verify: go straight to the deletion.
      unawaited(_delete(null));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await auth.requestDeleteCode();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _messageFor(e, l10n);
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _stage = _Stage.code;
      if (resend) {
        _info = l10n.profile_deleteCodeSent;
        _code.clear();
      }
    });
    _startCooldown();
    _codeFocus.requestFocus();
  }

  /// Step 2 -> 3: deletes (the server verifies [code] again).
  Future<void> _delete(String? code) async {
    final l10n = ProfileL10n.of(context);
    final auth = ref.read(authRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final onboarding = ref.read(onboardingCompleteProvider.notifier);
    final eula = ref.read(eulaAcceptedProvider.notifier);
    final quiz = ref.read(onboardingQuizProvider.notifier);
    final feedbackDraft = ref.read(feedbackDraftProvider.notifier);
    final feedbackCache = ref.read(feedbackCacheStoreProvider);
    setState(() {
      _stage = _Stage.progress;
      _result = _Result.deleting;
      _busy = true;
      _error = null;
      _finalError = null;
    });
    try {
      await auth.deleteAccount(code: code);
    } on Object catch (e) {
      if (!mounted) return;
      final errCode = e is OurneyException ? e.error : OurneyErrorCode.unknown;
      if (errCode == OurneyErrorCode.invalid) {
        // Wrong or expired code: back to step 2 to retry.
        setState(() {
          _busy = false;
          _stage = _Stage.code;
          _error = l10n.profile_deleteOtpWrong;
          _code.clear();
        });
        return;
      }
      setState(() {
        _busy = false;
        _result = _Result.error;
        _finalError = _messageFor(e, l10n);
      });
      return;
    }
    await onboarding.reset();
    if (prefs.containsKey(AuthMethodPrefs.lastMethodKey)) {
      await prefs.remove(AuthMethodPrefs.lastMethodKey);
    }
    // A new account on this device must accept the terms again (FR-F3).
    await eula.reset();
    await quiz.clear();
    await feedbackDraft.clearAll();
    await feedbackCache.clearAll();
    // The router may already have replaced the stack (signed out), which
    // removes this sheet too; otherwise the "done" view has its own button.
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = _Result.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    final title = switch (_stage) {
      _Stage.confirm => l10n.profile_deleteTitle,
      _Stage.code => l10n.profile_deleteOtpTitle,
      _Stage.progress =>
        _result == _Result.done
            ? l10n.profile_deleteDoneTitle
            : l10n.profile_deleting,
    };
    return PopScope(
      canPop: !_busy,
      child: Column(
        key: const ValueKey('profile-delete-dialog'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OurneyIcon(
                name: _result == _Result.done && _stage == _Stage.progress
                    ? 'check-circle'
                    : 'warning',
                flat: true,
                color: ui.danger,
                size: 28,
              ),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: UiText.h2(color: ui.ink)),
                ),
              ),
              Semantics(
                label: l10n.profile_deleteStepSemantics(
                  _stage.index + 1,
                  _Stage.values.length,
                ),
                excludeSemantics: true,
                child: Text(
                  '${_stage.index + 1}/${_Stage.values.length}',
                  key: const ValueKey('profile-delete-step'),
                  style: UiText.body(size: 13, color: ui.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.sm),
          ...switch (_stage) {
            _Stage.confirm => _confirmChildren(l10n, ui),
            _Stage.code => _codeChildren(l10n, ui),
            _Stage.progress => _progressChildren(l10n, ui),
          },
        ],
      ),
    );
  }

  List<Widget> _confirmChildren(ProfileL10n l10n, OurneyUi ui) => [
    Text(
      l10n.profile_deleteMessage,
      style: UiText.muted(color: ui.inkMuted, size: 14),
    ),
    const SizedBox(height: UiSpace.md),
    for (final (icon, text) in [
      ('profile', l10n.profile_deleteItemProfile),
      ('image', l10n.profile_deleteItemJourneys),
      ('squad', l10n.profile_deleteItemGroups),
    ])
      Padding(
        padding: const EdgeInsets.symmetric(vertical: UiSpace.xs),
        child: Row(
          children: [
            OurneyIcon(name: icon, flat: true, color: ui.ink, size: 20),
            const SizedBox(width: UiSpace.md),
            Expanded(
              child: Text(text, style: UiText.body(size: 14, color: ui.ink)),
            ),
          ],
        ),
      ),
    const SizedBox(height: UiSpace.sm),
    Text(
      l10n.profile_deleteOwnerNote,
      style: UiText.muted(color: ui.inkMuted, size: 13),
    ),
    UiSwitchRow(
      key: const ValueKey('profile-delete-understand'),
      label: l10n.profile_deleteUnderstand,
      value: _understood,
      divider: false,
      onChanged: _busy ? null : (v) => setState(() => _understood = v),
    ),
    if (_error != null) ...[
      const SizedBox(height: UiSpace.sm),
      UiInlineError(
        key: const ValueKey('profile-delete-error'),
        message: _error!,
      ),
    ],
    const SizedBox(height: UiSpace.lg),
    UiButton.secondary(
      key: const ValueKey('profile-delete-cancel'),
      label: l10n.profile_deleteKeep,
      onPressed: _busy ? null : () => Navigator.of(context).pop(false),
    ),
    const SizedBox(height: UiSpace.sm),
    UiButton(
      key: const ValueKey('profile-delete-continue'),
      label: l10n.profile_deleteContinue,
      glyph: const OurneyIcon(name: 'trash', flat: true),
      loading: _busy,
      accent: ui.danger,
      onAccent: ui.onDanger,
      onPressed: _understood && !_busy ? _toCodeStep : null,
    ),
  ];

  List<Widget> _codeChildren(ProfileL10n l10n, OurneyUi ui) {
    final complete = _code.text.trim().length == 6;
    return [
      Text(
        l10n.profile_deleteOtpLead,
        style: UiText.muted(color: ui.inkMuted, size: 14),
      ),
      const SizedBox(height: UiSpace.lg),
      UiOtpField(
        key: const ValueKey('profile-delete-otp'),
        controller: _code,
        focusNode: _codeFocus,
        digitLabel: l10n.profile_deleteOtpLabel,
        enabled: !_busy,
        hasError: _error != null,
        onChanged: (_) => setState(() => _error = null),
        onSubmitted: (_) =>
            complete && !_busy ? _delete(_code.text.trim()) : null,
      ),
      if (_error != null) ...[
        const SizedBox(height: UiSpace.sm),
        UiInlineError(
          key: const ValueKey('profile-delete-error'),
          message: _error!,
        ),
      ],
      if (_info != null) ...[
        const SizedBox(height: UiSpace.sm),
        Text(_info!, style: UiText.body(size: 13, color: ui.success)),
      ],
      UiTextAction(
        key: const ValueKey('profile-delete-resend'),
        size: 13,
        color: _cooldown > 0 ? ui.inkMuted : null,
        label: _cooldown > 0
            ? l10n.profile_deleteResendIn(_cooldown)
            : l10n.profile_deleteResend,
        onPressed: _busy || _cooldown > 0
            ? null
            : () => _toCodeStep(resend: true),
      ),
      const SizedBox(height: UiSpace.lg),
      UiButton(
        key: const ValueKey('profile-delete-confirm'),
        label: l10n.profile_deleteConfirmButton,
        glyph: const OurneyIcon(name: 'trash', flat: true),
        loading: _busy,
        accent: ui.danger,
        onAccent: ui.onDanger,
        onPressed: complete && !_busy ? () => _delete(_code.text.trim()) : null,
      ),
      const SizedBox(height: UiSpace.sm),
      UiButton.secondary(
        key: const ValueKey('profile-delete-cancel'),
        label: AppLocalizations.of(context).common_cancel,
        onPressed: _busy ? null : () => Navigator.of(context).pop(false),
      ),
    ];
  }

  List<Widget> _progressChildren(ProfileL10n l10n, OurneyUi ui) =>
      switch (_result) {
        _Result.deleting => [
          const SizedBox(height: UiSpace.lg),
          Center(
            child: Semantics(
              label: l10n.profile_deleting,
              child: const UiSpinner(key: ValueKey('profile-delete-progress')),
            ),
          ),
          const SizedBox(height: UiSpace.lg),
        ],
        _Result.done => [
          Text(
            l10n.profile_deleteDoneBody,
            style: UiText.muted(color: ui.inkMuted, size: 14),
          ),
          const SizedBox(height: UiSpace.xl),
          UiButton(
            key: const ValueKey('profile-delete-done'),
            label: l10n.profile_deleteDoneButton,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
        _Result.error => [
          UiInlineError(
            key: const ValueKey('profile-delete-error'),
            message: _finalError ?? l10n.profile_deleteErrorRetry,
          ),
          const SizedBox(height: UiSpace.lg),
          UiButton(
            key: const ValueKey('profile-delete-retry'),
            label: AppLocalizations.of(context).common_retry,
            onPressed: () => setState(() {
              _stage = _Stage.code;
              _error = null;
            }),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton.secondary(
            key: const ValueKey('profile-delete-back'),
            label: l10n.profile_deleteBackToSettings,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      };
}
