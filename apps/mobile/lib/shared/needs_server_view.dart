import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'empty_state.dart';

/// Local-only mode (FR-A5) state for features that need the backend
/// (groups, invites, reactions). Show it when
/// `ref.watch(appConfigProvider).localOnly` is true instead of calling
/// server-backed repositories.
class NeedsServerView extends StatelessWidget {
  const NeedsServerView({this.actionLabel, this.onAction, super.key});

  /// Optional call to action, e.g. "Create a solo journey".
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      key: const ValueKey('needs-server'),
      icon: Icons.cloud_off_rounded,
      title: l10n.needsServer_title,
      message: l10n.needsServer_message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
