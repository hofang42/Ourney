import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/data_providers.dart' show deadUploadsProvider;
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../l10n/generated/profile_localizations.dart';

/// Shared sign-out flow for Profile and Settings (C-B6 / U6).
///
/// Signing out wipes local data, including check-ins that have not been
/// sent yet, so it always asks first and warns about that. Errors show a
/// toast instead of escaping as an unhandled async error. The router leaves
/// the signed-in area by itself once the user id becomes null.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final l10n = ProfileL10n.of(context);
  // Read before any await: the screen may be gone once the sheet closes.
  final auth = ref.read(authRepositoryProvider);
  final pending = await _pendingUploads(ref);
  if (!context.mounted) return;
  final errorText = AppLocalizations.of(context).common_errorGeneric;
  var busy = false;
  var failed = false;
  await showUiSheet<bool>(
    context: context,
    // Not dismissible by barrier or drag: the sheet owns the busy state while
    // the outbox flushes and the session ends. Cancel closes it.
    dismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        final ui = context.ui;
        return Column(
          key: const ValueKey('profile-signout-dialog'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.profile_signOutTitle,
                style: UiText.h2(color: ui.ink),
              ),
            ),
            const SizedBox(height: UiSpace.sm),
            Text(
              l10n.profile_signOutMessage,
              style: UiText.muted(color: ui.inkMuted, size: 14),
            ),
            if (pending > 0) ...[
              const SizedBox(height: UiSpace.sm),
              Text(
                l10n.profile_signOutPending(pending),
                key: const ValueKey('profile-signout-pending'),
                style: UiText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: ui.danger,
                ),
              ),
            ],
            const SizedBox(height: UiSpace.xl),
            UiButton(
              key: const ValueKey('profile-signout-confirm'),
              label: l10n.profile_signOut,
              loading: busy,
              onPressed: busy
                  ? null
                  : () async {
                      // Busy while the outbox flushes and the session ends.
                      setSheet(() => busy = true);
                      try {
                        await auth.signOut();
                      } on Object {
                        failed = true;
                      }
                      if (context.mounted) Navigator.of(context).pop(!failed);
                    },
            ),
            const SizedBox(height: UiSpace.sm),
            UiButton.secondary(
              key: const ValueKey('profile-signout-cancel'),
              label: AppLocalizations.of(context).common_cancel,
              onPressed: busy ? null : () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    ),
  );
  if (failed && context.mounted) showUiToast(context, errorText);
}

/// Check-ins still waiting to upload; 0 when unknown (never blocks the sheet).
Future<int> _pendingUploads(WidgetRef ref) async {
  try {
    final live = await ref
        .read(checkInRepositoryProvider)
        .watchPendingUploads()
        .first
        .timeout(const Duration(seconds: 1));
    // Uploads the outbox gave up on are lost by the wipe too.
    final dead =
        await ref
            .read(deadUploadsProvider)
            ?.watch()
            .first
            .timeout(const Duration(seconds: 1)) ??
        const [];
    return live + dead.length;
  } on Object {
    return 0;
  }
}
