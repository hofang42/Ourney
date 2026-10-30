import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../journeys/data/journeys_providers.dart';
import '../l10n/generated/groups_localizations.dart';

/// User-facing message for a repository error (codes from
/// [OurneyErrorCode]; raw server details are never shown).
String groupErrorMessage(BuildContext context, Object error) {
  final l10n = GroupsL10n.of(context);
  final app = AppLocalizations.of(context);
  final e = rootError(error);
  if (e is! OurneyException) return app.common_errorGeneric;
  return switch (e.error) {
    OurneyErrorCode.notFound => l10n.groups_errorNotFound,
    OurneyErrorCode.full => l10n.groups_errorFull,
    OurneyErrorCode.blocked => l10n.groups_errorBlocked,
    OurneyErrorCode.limit => l10n.groups_errorLimit,
    OurneyErrorCode.ended => l10n.groups_errorEnded,
    OurneyErrorCode.forbidden => l10n.groups_errorForbidden,
    OurneyErrorCode.notAlone => l10n.groups_errorNotAlone,
    OurneyErrorCode.invalid => l10n.groups_errorInvalid,
    OurneyErrorCode.offline => app.common_offline,
    _ => app.common_errorGeneric,
  };
}

void showGroupSnack(BuildContext context, String message) =>
    showUiToast(context, message);

/// Local-only mode (FR-A5): groups need the backend.
class GroupsNeedsServer extends StatelessWidget {
  const GroupsNeedsServer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return UiEmptyState(
      key: const ValueKey('needs-server'),
      icon: Icons.cloud_off_rounded,
      title: l10n.needsServer_title,
      body: l10n.needsServer_message,
    );
  }
}

/// Confirmation sheet. Resolves to true on confirm.
Future<bool> confirmGroupAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final app = AppLocalizations.of(context);
  final result = await showUiSheet<bool>(
    context: context,
    builder: (context) {
      final ui = context.ui;
      return Column(
        key: const ValueKey('groups-confirm-dialog'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: UiText.h2(color: ui.ink)),
          ),
          const SizedBox(height: UiSpace.sm),
          Text(message, style: UiText.muted(color: ui.inkMuted, size: 14)),
          const SizedBox(height: UiSpace.xl),
          UiButton(
            key: const ValueKey('groups-confirm'),
            label: confirmLabel,
            accent: destructive ? ui.danger : null,
            onAccent: destructive ? Colors.white : null,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton.secondary(
            label: app.common_cancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Fallback while the data layer is not wired (`isNotWired`): a plain page
/// keyed `placeholder-<id>` like the router tests expect.
class GroupsNotWired extends StatelessWidget {
  const GroupsNotWired({required this.id, required this.title, super.key});

  final String id;
  final String title;

  @override
  Widget build(BuildContext context) {
    return UiScaffold(
      key: ValueKey('placeholder-$id'),
      scroll: false,
      child: UiFillScroll(
        child: UiEmptyState(
          icon: Icons.construction_rounded,
          title: title,
          body: AppLocalizations.of(context).placeholder_comingSoon,
        ),
      ),
    );
  }
}
