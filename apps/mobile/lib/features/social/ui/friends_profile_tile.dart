import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
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
    final c = OurneyColors.of(context);
    final list = ref.watch(friendshipsProvider).value;
    final friends = list?.where((f) => f.isFriend).length;
    final requests = list?.where((f) => f.isIncomingRequest).length ?? 0;
    return InkWell(
      key: tileKey,
      onTap: () => context.push(SocialPaths.friends),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            Icon(Icons.people_outline_rounded, size: 22, color: c.ink),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    friends == null
                        ? l10n.social_friendsTitle
                        : l10n.social_profileFriends(friends),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: c.ink,
                    ),
                  ),
                  if (requests > 0)
                    Text(
                      l10n.social_profileRequests(requests),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 12,
                        height: 1.35,
                        color: c.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}
