import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/journeys_providers.dart';
import '../l10n/generated/journeys_localizations.dart';

/// User-facing message for a repository error (codes from
/// [OurneyErrorCode]; raw server details are never shown).
String journeyErrorMessage(BuildContext context, Object error) {
  final l10n = JourneysL10n.of(context);
  final app = AppLocalizations.of(context);
  final e = rootError(error);
  if (e is! OurneyException) return app.common_errorGeneric;
  return switch (e.error) {
    OurneyErrorCode.limit => l10n.journeys_limitMessage,
    OurneyErrorCode.notAlone => l10n.journeys_errorNotAlone,
    OurneyErrorCode.forbidden => l10n.journeys_errorForbidden,
    OurneyErrorCode.ended => l10n.journeys_errorEnded,
    OurneyErrorCode.notFound => l10n.journeys_errorNotFound,
    OurneyErrorCode.invalid => l10n.journeys_errorVisibility,
    OurneyErrorCode.offline => app.common_offline,
    _ => app.common_errorGeneric,
  };
}

void showJourneySnack(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// FR-B3 friendly block shown before the create flow when 3 journeys run.
Future<void> showJourneyLimitDialog(BuildContext context) {
  final l10n = JourneysL10n.of(context);
  final app = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('journeys-limit-dialog'),
      icon: const Icon(Icons.local_fire_department_rounded),
      title: Text(l10n.journeys_limitTitle),
      content: SingleChildScrollView(child: Text(l10n.journeys_limitMessage)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(app.common_ok),
        ),
      ],
    ),
  );
}

/// Destructive confirmation (end / delete). Resolves to true on confirm.
Future<bool> confirmJourneyAction(
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
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(app.common_cancel),
        ),
        TextButton(
          key: const ValueKey('journeys-confirm'),
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
