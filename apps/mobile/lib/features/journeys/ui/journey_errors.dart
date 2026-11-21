import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../data/journeys_providers.dart';
import '../l10n/generated/journeys_localizations.dart';

/// User-facing message for a repository error (codes from
/// [OurneyErrorCode]; raw server details are never shown).
String journeyErrorMessage(BuildContext context, Object error) {
  final l10n = JourneysL10n.of(context);
  final app = AppLocalizations.of(context);
  final e = rootError(error);
  debugPrint('journeyError: $e (original: $error)');
  if (e is! OurneyException) return app.common_errorGeneric;
  return switch (e.error) {
    OurneyErrorCode.notAlone => l10n.journeys_errorNotAlone,
    OurneyErrorCode.forbidden => l10n.journeys_errorForbidden,
    OurneyErrorCode.ended => l10n.journeys_errorEnded,
    OurneyErrorCode.notFound => l10n.journeys_errorNotFound,
    OurneyErrorCode.invalid =>
      (e.detail ?? '').toLowerCase().contains('visib')
          ? l10n.journeys_errorVisibility
          : l10n.journeys_errorInvalid,
    OurneyErrorCode.limit => l10n.journeys_errorLimit,
    OurneyErrorCode.serverOutdated => app.common_serverOutdated,
    OurneyErrorCode.offline => app.common_offline,
    OurneyErrorCode.syncPending => l10n.journeys_errorSyncPending,
    _ => app.common_errorGeneric,
  };
}

/// Journey screens pin their primary button to the bottom: lift the toast
/// above it so it never covers the action.
void showJourneySnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) => showUiToast(
  context,
  message,
  bottomOffset: 110,
  actionLabel: actionLabel,
  onAction: onAction,
);

/// Confirmation (end / delete). Resolves to true on confirm.
Future<bool> confirmJourneyAction(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: UiText.h2(color: ui.ink)),
          ),
          const SizedBox(height: UiSpace.sm),
          Text(message, style: UiText.muted(color: ui.inkMuted)),
          const SizedBox(height: UiSpace.xxl),
          UiButton(
            key: const ValueKey('journeys-confirm'),
            label: confirmLabel,
            accent: destructive ? ui.danger : null,
            onAccent: destructive ? ui.onDanger : null,
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
