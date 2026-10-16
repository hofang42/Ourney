import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/safety_providers.dart';
import '../l10n/generated/safety_localizations.dart';
import 'safety_common.dart';

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
    messenger?.showSnackBar(SnackBar(content: Text(l10n.safety_needsAccount)));
    return false;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('safety-block-dialog'),
      title: Text(l10n.safety_blockTitle(shown)),
      content: Text(l10n.safety_blockBody),
      actions: [
        TextButton(
          key: const ValueKey('safety-block-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.safety_blockCancel),
        ),
        FilledButton(
          key: const ValueKey('safety-block-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.safety_blockConfirm),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  return blockUser(container, messenger, l10n, userId: userId, name: name);
}

/// Blocks without asking (the caller already confirmed). Shows a snack bar.
Future<bool> blockUser(
  ProviderContainer container,
  ScaffoldMessengerState? messenger,
  SafetyL10n l10n, {
  required String userId,
  String? name,
}) async {
  final shown = (name == null || name.isEmpty) ? l10n.safety_unknownUser : name;
  try {
    await container.read(safetyActionsProvider).block(userId, name: name);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.safety_blocked(shown))),
    );
    return true;
  } on Object catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text(safetyFailureMessage(l10n, e))),
    );
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
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('safety-unblock-dialog'),
      title: Text(l10n.safety_unblockTitle(shown)),
      content: Text(l10n.safety_unblockBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.safety_blockCancel),
        ),
        FilledButton(
          key: const ValueKey('safety-unblock-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.safety_unblockConfirm),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  try {
    await container.read(safetyActionsProvider).unblock(userId);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.safety_unblocked(shown))),
    );
    return true;
  } on Object catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text(safetyFailureMessage(l10n, e))),
    );
    return false;
  }
}
