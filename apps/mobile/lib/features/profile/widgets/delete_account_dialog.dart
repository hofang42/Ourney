import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../safety/data/safety_providers.dart';
import '../l10n/generated/profile_localizations.dart';

/// Strong confirmation for FR-A4: the user must type [phrase] (their
/// username, or a fixed word when it is unknown) before the destructive
/// button enables. Calls `AuthRepository.deleteAccount()` itself so errors
/// (safe to retry) are shown in place; on success it resets onboarding and
/// the EULA acceptance and pops `true`. The router then leaves the signed-in
/// area by itself. Shown in a kit sheet.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({
    required this.phrase,
    this.caseSensitive = true,
    super.key,
  });

  final String phrase;
  final bool caseSensitive;

  static Future<bool?> show(
    BuildContext context, {
    required String phrase,
    bool caseSensitive = true,
  }) => showUiSheet<bool>(
    context: context,
    dismissible: false,
    builder: (_) =>
        DeleteAccountDialog(phrase: phrase, caseSensitive: caseSensitive),
  );

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches {
    final typed = _controller.text.trim();
    return widget.caseSensitive
        ? typed == widget.phrase
        : typed.toUpperCase() == widget.phrase.toUpperCase();
  }

  Future<void> _delete() async {
    final l10n = ProfileL10n.of(context);
    final navigator = Navigator.of(context);
    final auth = ref.read(authRepositoryProvider);
    final onboarding = ref.read(onboardingCompleteProvider.notifier);
    final eula = ref.read(eulaAcceptedProvider.notifier);
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await auth.deleteAccount();
    } on Object catch (e) {
      if (!mounted) return;
      final code = e is OurneyException ? e.error : OurneyErrorCode.unknown;
      setState(() {
        _deleting = false;
        _error = switch (code) {
          OurneyErrorCode.unauthenticated => l10n.profile_deleteErrorReauth,
          OurneyErrorCode.offline => l10n.profile_offlineError,
          _ => l10n.profile_deleteErrorRetry,
        };
      });
      return;
    }
    await onboarding.reset();
    // A new account on this device must accept the terms again (FR-F3).
    await eula.reset();
    // The router may already have replaced the stack (signed out), which
    // removes this sheet too.
    if (mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    return PopScope(
      canPop: !_deleting,
      child: Column(
        key: const ValueKey('profile-delete-dialog'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: ui.danger, size: 28),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.profile_deleteTitle,
                    style: UiText.h2(color: ui.ink),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.sm),
          Text(
            l10n.profile_deleteMessage,
            style: UiText.muted(color: ui.inkMuted, size: 14),
          ),
          const SizedBox(height: UiSpace.lg),
          UiTextField(
            fieldKey: const ValueKey('profile-delete-confirm-field'),
            label: l10n.profile_deleteTypeToConfirm(widget.phrase),
            hint: widget.phrase,
            controller: _controller,
            enabled: !_deleting,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: UiSpace.md),
            UiInlineError(
              key: const ValueKey('profile-delete-error'),
              message: _error!,
            ),
          ],
          if (_deleting) ...[
            const SizedBox(height: UiSpace.md),
            Text(
              l10n.profile_deleting,
              style: UiText.body(size: 13, color: ui.inkMuted),
            ),
          ],
          const SizedBox(height: UiSpace.xl),
          UiButton(
            key: const ValueKey('profile-delete-confirm'),
            label: l10n.profile_deleteConfirmButton,
            icon: Icons.delete_outline_rounded,
            loading: _deleting,
            accent: ui.danger,
            onAccent: Colors.white,
            onPressed: _matches && !_deleting ? _delete : null,
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton.secondary(
            key: const ValueKey('profile-delete-cancel'),
            label: AppLocalizations.of(context).common_cancel,
            onPressed: _deleting
                ? null
                : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
