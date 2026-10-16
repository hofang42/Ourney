import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_routes.dart';
import '../l10n/generated/app_localizations.dart';

/// App-bar entry point to `/profile` (settings, reminders, safety). Shown on
/// the Journeys and Groups tabs and, smaller, on the capture screen, in
/// local-only mode too (the profile then shows the guest state).
class ProfileButton extends StatelessWidget {
  const ProfileButton({this.compact = false, super.key});

  /// Smaller variant for the camera chrome.
  final bool compact;

  static const buttonKey = ValueKey('profile-entry');

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: buttonKey,
      tooltip: AppLocalizations.of(context).nav_profile,
      iconSize: compact ? 24 : null,
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () => context.push(AppRoutes.profile),
    );
  }
}
