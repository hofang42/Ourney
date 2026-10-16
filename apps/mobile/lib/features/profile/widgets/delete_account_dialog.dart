import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../safety/data/safety_providers.dart';
import '../l10n/generated/profile_localizations.dart';
import 'inline_error.dart';

/// Strong confirmation for FR-A4: the user must type [phrase] (their
/// username, or a fixed word when it is unknown) before the destructive
/// button enables. Calls `AuthRepository.deleteAccount()` itself so errors
/// (safe to retry) are shown in place; on success it resets onboarding and
/// the EULA acceptance and pops `true`. The router then leaves the signed-in area by itself.
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
  }) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
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
    // removes this dialog too.
    if (mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final c = OurneyColors.of(context);
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: !_deleting,
      child: AlertDialog(
        key: const ValueKey('profile-delete-dialog'),
        icon: Icon(Icons.warning_amber_rounded, color: c.danger, size: 40),
        title: Text(l10n.profile_deleteTitle),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.profile_deleteMessage, style: text.bodyMedium),
            const SizedBox(height: OurneySpacing.lg),
            Text(
              l10n.profile_deleteTypeToConfirm(widget.phrase),
              style: text.titleSmall,
            ),
            const SizedBox(height: OurneySpacing.sm),
            TextField(
              key: const ValueKey('profile-delete-confirm-field'),
              controller: _controller,
              enabled: !_deleting,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: widget.phrase),
            ),
            if (_error != null) ...[
              const SizedBox(height: OurneySpacing.md),
              InlineError(
                key: const ValueKey('profile-delete-error'),
                message: _error!,
              ),
            ],
            if (_deleting) ...[
              const SizedBox(height: OurneySpacing.md),
              Row(
                children: [
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: OurneySpacing.sm),
                  Expanded(child: Text(l10n.profile_deleting)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('profile-delete-cancel'),
            onPressed: _deleting
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).common_cancel),
          ),
          FilledButton.icon(
            key: const ValueKey('profile-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: c.danger,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: _matches && !_deleting ? _delete : null,
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text(l10n.profile_deleteConfirmButton),
          ),
        ],
      ),
    );
  }
}
