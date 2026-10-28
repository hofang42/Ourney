import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_routes.dart';
import '../app/theme/tokens.dart';
import '../features/profile/profile_providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'avatar.dart';

/// App-bar entry point to `/profile` (settings, reminders, safety). Shown on
/// the Journeys and Groups tabs and, smaller, on the capture screen, in
/// local-only mode too (the profile then shows the guest state).
///
/// V1.0: the signed-in user's initials avatar; a neutral person glyph when
/// there is no profile (guest / local-only).
class ProfileButton extends ConsumerWidget {
  const ProfileButton({this.compact = false, super.key});

  /// Smaller variant for the camera chrome.
  final bool compact;

  static const buttonKey = ValueKey('profile-entry');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(myProfileProvider).value?.displayName.trim();
    final size = compact ? 32.0 : 40.0;
    final c = OurneyColors.of(context);
    return IconButton(
      key: buttonKey,
      tooltip: AppLocalizations.of(context).nav_profile,
      padding: EdgeInsets.zero,
      icon: name == null || name.isEmpty
          ? Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surfaceSunken,
                border: Border.all(color: c.border),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: size * 0.55,
                color: c.ink,
              ),
            )
          : ExcludeSemantics(
              child: Avatar(name: name, size: size),
            ),
      onPressed: () => context.push(AppRoutes.profile),
    );
  }
}
