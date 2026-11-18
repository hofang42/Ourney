import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
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
  final ok = await showUiSheet<bool>(
    context: context,
    builder: (context) {
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
          const SizedBox(height: UiSpace.xl),
          UiButton(
            key: const ValueKey('profile-signout-confirm'),
            label: l10n.profile_signOut,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: UiSpace.sm),
          UiButton.secondary(
            key: const ValueKey('profile-signout-cancel'),
            label: AppLocalizations.of(context).common_cancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
  if (ok != true || !context.mounted) return;
  final errorText = AppLocalizations.of(context).common_errorGeneric;
  try {
    await auth.signOut();
  } on Object {
    if (context.mounted) showUiToast(context, errorText);
  }
}
