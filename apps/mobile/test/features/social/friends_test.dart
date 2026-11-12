import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/social/social_paths.dart';
import 'package:ourney_core/ourney_core.dart';

import 'social_fakes.dart';

void main() {
  testWidgets('lists requests and friends with an owner-only count', (
    tester,
  ) async {
    final fakes = SocialFakes(
      friends: FakeFriendRepository([
        request('khoa', name: 'Khoa Le'),
        request('mai', direction: FriendDirection.outgoing, name: 'Mai Pham'),
        friend('nam', name: 'Nam Tran'),
        friend('ha', name: 'Ha Vu'),
      ]),
    );
    await pumpSocial(tester, location: SocialPaths.friends, fakes: fakes);

    expect(find.text('2 friends · only you see this'), findsOneWidget);
    expect(find.text('Khoa Le'), findsOneWidget);
    expect(find.byKey(const ValueKey('accept-khoa')), findsOneWidget);
    expect(find.byKey(const ValueKey('cancel-mai')), findsOneWidget);
    expect(find.text('Requested'), findsOneWidget);
    expect(find.text('Nam Tran'), findsOneWidget);
  });

  testWidgets('accept turns a request into a friend', (tester) async {
    final fakes = SocialFakes(
      friends: FakeFriendRepository([request('khoa', name: 'Khoa Le')]),
    );
    await pumpSocial(tester, location: SocialPaths.friends, fakes: fakes);

    await tester.tap(find.byKey(const ValueKey('accept-khoa')));
    await tester.pumpAndSettle();

    expect(fakes.friends.calls, ['accept:khoa']);
    expect(find.byKey(const ValueKey('friend-khoa')), findsOneWidget);
    expect(find.text('No new requests'), findsOneWidget);
    expect(find.text('1 friend · only you see this'), findsOneWidget);
  });

  testWidgets('decline and cancel remove the request', (tester) async {
    final fakes = SocialFakes(
      friends: FakeFriendRepository([
        request('khoa'),
        request('mai', direction: FriendDirection.outgoing),
        friend('nam'),
      ]),
    );
    await pumpSocial(tester, location: SocialPaths.friends, fakes: fakes);

    await tester.tap(find.byKey(const ValueKey('decline-khoa')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cancel-mai')));
    await tester.pumpAndSettle();

    expect(fakes.friends.calls, ['decline:khoa', 'remove:mai']);
    expect(find.byKey(const ValueKey('request-khoa')), findsNothing);
    expect(find.byKey(const ValueKey('request-mai')), findsNothing);
  });

  testWidgets('remove friend asks first, then unfriends', (tester) async {
    final fakes = SocialFakes(
      friends: FakeFriendRepository([friend('nam', name: 'Nam Tran')]),
    );
    await pumpSocial(tester, location: SocialPaths.friends, fakes: fakes);

    await tester.tap(find.byKey(const ValueKey('friend-nam')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('friend-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('friend-remove')));
    await tester.pumpAndSettle();
    expect(
      find.text("You'll stop seeing each other's shared journeys."),
      findsOneWidget,
    );
    // Cancel keeps the friend.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fakes.friends.calls, isEmpty);

    await tester.tap(find.byKey(const ValueKey('friend-nam')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('friend-remove')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('social-confirm')));
    await tester.pumpAndSettle();

    expect(fakes.friends.calls, ['remove:nam']);
    expect(find.byKey(const ValueKey('friend-nam')), findsNothing);
  });

  testWidgets('friend sheet offers Message when a conversation exists', (
    tester,
  ) async {
    final fakes = SocialFakes(
      friends: FakeFriendRepository([friend('nam', name: 'Nam Tran')]),
      chat: FakeChatRepository(conversations: [conversation('c1')]),
    );
    await pumpSocial(tester, location: SocialPaths.friends, fakes: fakes);
    await tester.tap(find.byKey(const ValueKey('friend-nam')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('friend-message')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-screen')), findsOneWidget);
  });

  testWidgets('empty list invites to add friends', (tester) async {
    await pumpSocial(tester, location: SocialPaths.friends);
    expect(find.byKey(const ValueKey('friends-empty')), findsOneWidget);
    await tester.tap(find.text('Add friends'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add-friends-screen')), findsOneWidget);
  });

  testWidgets('more than 10 friends shows a filter', (tester) async {
    final fakes = SocialFakes(
      friends: FakeFriendRepository([
        for (var i = 0; i < 12; i++) friend('u$i', name: 'Friend $i'),
      ]),
    );
    await pumpSocial(tester, location: SocialPaths.friends, fakes: fakes);
    await tester.enterText(find.byKey(const ValueKey('friends-filter')), 'U11');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('friend-u11')), findsOneWidget);
    expect(find.byKey(const ValueKey('friend-u1')), findsNothing);
  });

  testWidgets('local-only shows NeedsServerView', (tester) async {
    await pumpSocial(tester, location: SocialPaths.friends, localOnly: true);
    expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
    expect(find.byKey(const ValueKey('friends-add')), findsNothing);
  });

  testWidgets('profile tile shows the count and opens friends', (tester) async {
    final fakes = SocialFakes(
      friends: FakeFriendRepository([
        friend('nam'),
        friend('ha'),
        request('khoa'),
      ]),
    );
    await pumpSocial(tester, location: '/hub', fakes: fakes);
    expect(find.text('Friends · 2'), findsOneWidget);
    expect(find.text('1 request waiting'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('friends-profile-tile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('friends-screen')), findsOneWidget);
  });

  testWidgets('profile tile is hidden in local-only mode', (tester) async {
    await pumpSocial(tester, location: '/hub', localOnly: true);
    expect(find.byKey(const ValueKey('friends-profile-tile')), findsNothing);
  });
}
