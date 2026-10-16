import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/groups_providers.dart';
import '../l10n/generated/groups_localizations.dart';

/// User-facing message for a repository error (codes from
/// [OurneyErrorCode]; raw server details are never shown).
String groupErrorMessage(BuildContext context, Object error) {
  final l10n = GroupsL10n.of(context);
  final app = AppLocalizations.of(context);
  final e = groupRootError(error);
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

void showGroupSnack(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Confirmation dialog. Resolves to true on confirm.
Future<bool> confirmGroupAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final app = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('groups-confirm-dialog'),
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(app.common_cancel),
        ),
        TextButton(
          key: const ValueKey('groups-confirm'),
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
