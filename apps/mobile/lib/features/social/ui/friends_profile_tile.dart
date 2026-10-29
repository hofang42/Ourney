import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../data/social_providers.dart';
import '../l10n/generated/social_localizations.dart';
import '../social_paths.dart';

/// Profile (SCR-70) row "Friends · N" opening `/friends` (S4: the count is
/// only ever shown to the account owner). Pending incoming requests show
/// as a sub-line. Hidden in local-only mode.
class FriendsProfileTile extends ConsumerWidget {
  const FriendsProfileTile({super.key});

  static const tileKey = ValueKey('friends-profile-tile');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appConfigProvider).localOnly) return const SizedBox.shrink();
    final l10n = SocialL10n.of(context);
    final list = ref.watch(friendshipsProvider).value;
    final friends = list?.where((f) => f.isFriend).length;
    final requests = list?.where((f) => f.isIncomingRequest).length ?? 0;
    return UiRow(
      key: tileKey,
      leading: Icon(
        Icons.people_outline_rounded,
        size: 22,
        color: context.ui.ink,
      ),
      title: friends == null
          ? l10n.social_friendsTitle
          : l10n.social_profileFriends(friends),
      subtitle: requests > 0
          ? Text(
              l10n.social_profileRequests(requests),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(
                size: 12,
                height: 1.4,
                color: context.ui.inkMuted,
              ),
            )
          : null,
      onPressed: () => context.push(SocialPaths.friends),
    );
  }
}
