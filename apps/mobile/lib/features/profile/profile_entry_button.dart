import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';
import 'profile_providers.dart';

/// Top-bar entry to `/profile` (settings, reminders, safety), built on the
/// kit's [UiProfileEntry]: the user's initials avatar, or a neutral person
/// glyph when there is no profile (guest / local-only).
class ProfileEntryButton extends ConsumerWidget {
  const ProfileEntryButton({this.onDark = false, this.size = 36, super.key});

  /// On the always-dark camera chrome.
  final bool onDark;
  final double size;

  static const buttonKey = ValueKey('profile-entry');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(myProfileProvider).value?.displayName;
    return UiProfileEntry(
      key: buttonKey,
      label: AppLocalizations.of(context).nav_profile,
      name: name,
      size: size,
      onDark: onDark,
      onPressed: () => context.push(AppRoutes.profile),
    );
  }
}
