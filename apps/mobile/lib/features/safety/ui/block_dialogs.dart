// ignore_for_file: use_build_context_synchronously
// (`_toast` re-checks `context.mounted` before showing.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../data/safety_providers.dart';
import '../l10n/generated/safety_localizations.dart';
import 'safety_common.dart';

void _toast(
  BuildContext? context,
  ScaffoldMessengerState? messenger,
  String m,
) {
  if (context != null && context.mounted) {
    showUiToast(context, m);
  } else {
    messenger?.showSnackBar(SnackBar(content: Text(m)));
  }
}

/// V2 confirm sheet (replaces the Material AlertDialog). Pops true/false.
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.sheetKey,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmKey,
    this.cancelKey,
    this.destructive = false,
  });

  final Key sheetKey;
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final Key confirmKey;
  final Key? cancelKey;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Column(
      key: sheetKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: UiText.h2(color: ui.ink)),
        ),
        const SizedBox(height: UiSpace.sm),
        Text(body, style: UiText.muted(color: ui.inkMuted, size: 14)),
        const SizedBox(height: UiSpace.xl),
        UiButton(
          key: confirmKey,
          label: confirmLabel,
          accent: destructive ? ui.danger : null,
          onAccent: destructive ? ui.onDanger : null,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: UiSpace.sm),
        UiButton.secondary(
          key: cancelKey,
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

/// Asks "Block `name`?" and blocks [userId] on confirm (FR-F2). Shows a
/// snack bar with the result. Returns true when the user is now blocked.
///
/// [name] is the display name shown in the dialog and remembered for the
/// blocked list. Works from any widget under the app's `ProviderScope`.
Future<bool> confirmBlock(
  BuildContext context, {
  required String userId,
  String? name,
}) async {
  final l10n = SafetyL10n.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final shown = (name == null || name.isEmpty) ? l10n.safety_unknownUser : name;

  if (container.read(appConfigProvider).localOnly) {
    _toast(context, messenger, l10n.safety_needsAccount);
    return false;
  }

  final ok = await showUiSheet<bool>(
    context: context,
    builder: (context) => _ConfirmSheet(
      sheetKey: const ValueKey('safety-block-dialog'),
      title: l10n.safety_blockTitle(shown),
      body: l10n.safety_blockBody,
      confirmLabel: l10n.safety_blockConfirm,
      cancelLabel: l10n.safety_blockCancel,
      confirmKey: const ValueKey('safety-block-confirm'),
      cancelKey: const ValueKey('safety-block-cancel'),
      destructive: true,
    ),
  );
  if (ok != true) return false;
  return blockUser(
    container,
    messenger,
    l10n,
    userId: userId,
    name: name,
    toastContext: context,
  );
}

/// Blocks without asking (the caller already confirmed). Shows a snack bar.
Future<bool> blockUser(
  ProviderContainer container,
  ScaffoldMessengerState? messenger,
  SafetyL10n l10n, {
  required String userId,
  String? name,
  BuildContext? toastContext,
}) async {
  final shown = (name == null || name.isEmpty) ? l10n.safety_unknownUser : name;
  try {
    await container.read(safetyActionsProvider).block(userId, name: name);
    _toast(toastContext, messenger, l10n.safety_blocked(shown));
    return true;
  } on Object catch (e) {
    _toast(toastContext, messenger, safetyFailureMessage(l10n, e));
    return false;
  }
}

/// Asks "Unblock `name`?" and unblocks on confirm. Returns true on success.
Future<bool> confirmUnblock(
  BuildContext context, {
  required String userId,
  String? name,
}) async {
  final l10n = SafetyL10n.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final shown = (name == null || name.isEmpty) ? l10n.safety_unknownUser : name;
  final ok = await showUiSheet<bool>(
    context: context,
    builder: (context) => _ConfirmSheet(
      sheetKey: const ValueKey('safety-unblock-dialog'),
      title: l10n.safety_unblockTitle(shown),
      body: l10n.safety_unblockBody,
      confirmLabel: l10n.safety_unblockConfirm,
      cancelLabel: l10n.safety_blockCancel,
      confirmKey: const ValueKey('safety-unblock-confirm'),
    ),
  );
  if (ok != true) return false;
  try {
    await container.read(safetyActionsProvider).unblock(userId);
    _toast(context, messenger, l10n.safety_unblocked(shown));
    return true;
  } on Object catch (e) {
    _toast(context, messenger, safetyFailureMessage(l10n, e));
    return false;
  }
}
