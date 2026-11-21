import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney/features/social/data/social_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import 'social_fakes.dart';

/// C-B3: the server already leaves blocked pairs out of friend requests and
/// group invitations; only unread messages are corrected on the client.
void main() {
  const raw = InboxCounts(
    friendRequests: 2,
    publicRequests: 1,
    newShares: 0,
    unreadMessages: 5,
    consentRequests: 3,
    groupInvitations: 2,
  );

  Future<InboxCounts> counts({Set<String> blocked = const {'nam'}}) async {
    final c = ProviderContainer(
      overrides: [
        rawInboxCountsProvider.overrideWith((ref) => Stream.value(raw)),
        blockedUserIdsProvider.overrideWith((ref) => Stream.value(blocked)),
        conversationsProvider.overrideWith(
          (ref) => Stream.value([
            conversation('c1', unread: 2),
            conversation('c2', other: 'lan', unread: 1),
          ]),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.listen(inboxCountsProvider, (_, _) {});
    await c.read(rawInboxCountsProvider.future);
    await c.read(blockedUserIdsProvider.future);
    if (blocked.isNotEmpty) await c.read(conversationsProvider.future);
    return c.read(inboxCountsProvider).requireValue;
  }

  test('subtracts only blocked unread messages', () async {
    final r = await counts();
    expect(r.unreadMessages, 3);
  });

  test('server-filtered counts are not subtracted twice', () async {
    final r = await counts();
    expect(r.friendRequests, 2);
    expect(r.groupInvitations, 2);
    expect(r.consentRequests, 3);
  });

  test('nobody blocked: counts untouched', () async {
    final r = await counts(blocked: const {});
    expect(r.unreadMessages, 5);
  });
}
