import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/social/social_paths.dart';
import 'package:ourney_core/ourney_core.dart';

import 'social_fakes.dart';

Finder dotsIn(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byKey(const ValueKey('unread-dot')),
);

SocialFakes fullInbox() => SocialFakes(
  friends: FakeFriendRepository([
    request('khoa', name: 'Khoa Le'),
    request(
      'tuan',
      source: FriendSource.publicJourney,
      journeyId: 'hoi-an',
      journeyTitle: 'Hoi An 2024',
    ),
    request(
      'mia',
      source: FriendSource.publicJourney,
      journeyId: 'hoi-an',
      journeyTitle: 'Hoi An 2024',
    ),
    friend('nam'),
  ]),
  consents: FakeShareConsentRepository([consent('dalat', 'Da Lat Trip', 'ha')]),
  chat: FakeChatRepository(
    conversations: [
      conversation('c1', unread: 2),
      conversation('c2', other: 'lan', journey: 'Run Club'),
    ],
  ),
  insights: FakeInsightsRepository(
    const InboxCounts(
      friendRequests: 1,
      publicRequests: 2,
      newShares: 3,
      unreadMessages: 2,
      consentRequests: 1,
    ),
  ),
);

void main() {
  testWidgets('shows every section; public requests have no dot', (
    tester,
  ) async {
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fullInbox());

    expect(find.text('3 new journeys shared with you'), findsOneWidget);
    expect(find.text('Friend request from Khoa Le'), findsOneWidget);
    expect(
      find.text('User HA wants to share Da Lat Trip outside the squad'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('inbox-conversation-c1')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Run Club'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Run Club'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('inbox-public-hoi-an')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('2 requests from people who saw Hoi An 2024'),
      findsOneWidget,
    );

    expect(dotsIn('inbox-request-khoa'), findsOneWidget);
    expect(dotsIn('inbox-consent-dalat'), findsOneWidget);
    expect(dotsIn('inbox-conversation-c1'), findsOneWidget);
    expect(dotsIn('inbox-conversation-c2'), findsNothing);
    expect(dotsIn('inbox-public-hoi-an'), findsNothing);
    expect(find.byKey(const ValueKey('unread-badge')), findsOneWidget);
  });

  testWidgets('accept a friend request inline', (tester) async {
    final fakes = fullInbox();
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fakes);
    await tester.tap(find.byKey(const ValueKey('inbox-accept-khoa')));
    await tester.pumpAndSettle();
    expect(fakes.friends.calls, ['accept:khoa']);
    expect(find.byKey(const ValueKey('inbox-request-khoa')), findsNothing);
  });

  testWidgets('agree / decline a share consent', (tester) async {
    final fakes = fullInbox();
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fakes);
    await tester.tap(find.byKey(const ValueKey('consent-agree-dalat')));
    await tester.pumpAndSettle();
    expect(fakes.consents.calls, ['agree:dalat']);
    expect(find.byKey(const ValueKey('inbox-consent-dalat')), findsNothing);
  });

  testWidgets('public requests expand and decline all', (tester) async {
    final fakes = fullInbox();
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fakes);
    final summary = find.byKey(const ValueKey('inbox-public-hoi-an'));
    await tester.scrollUntilVisible(
      summary,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(summary);
    await tester.pumpAndSettle();
    await tester.tap(summary);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('inbox-public-request-tuan')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(const ValueKey('inbox-public-request-tuan')),
      findsOneWidget,
    );
    final all = find.byKey(const ValueKey('inbox-decline-all-hoi-an'));
    await tester.ensureVisible(all);
    await tester.pumpAndSettle();
    await tester.tap(all);
    await tester.pumpAndSettle();
    expect(fakes.friends.calls, ['decline:tuan', 'decline:mia']);
    expect(summary, findsNothing);
  });

  testWidgets('new shares row opens the Hub', (tester) async {
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fullInbox());
    await tester.tap(find.byKey(const ValueKey('inbox-new-shares')));
    await tester.pumpAndSettle();
    expect(find.text('hub-journeys'), findsOneWidget);
  });

  testWidgets('filters split replies and invites', (tester) async {
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fullInbox());
    await tester.tap(find.byKey(const ValueKey('inbox-filter-replies')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inbox-conversation-c1')), findsOneWidget);
    expect(find.byKey(const ValueKey('inbox-request-khoa')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('inbox-filter-invites')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inbox-conversation-c1')), findsNothing);
    expect(find.byKey(const ValueKey('inbox-request-khoa')), findsOneWidget);
  });

  testWidgets('conversation row opens the chat', (tester) async {
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fullInbox());
    final row = find.byKey(const ValueKey('inbox-conversation-c1'));
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-screen')), findsOneWidget);
  });

  testWidgets('empty inbox', (tester) async {
    await pumpSocial(tester, location: SocialPaths.inbox);
    expect(find.byKey(const ValueKey('inbox-empty')), findsOneWidget);
  });

  testWidgets('local-only inbox shows NeedsServerView', (tester) async {
    await pumpSocial(tester, location: SocialPaths.inbox, localOnly: true);
    expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
  });

  group('InboxButton', () {
    testWidgets('red dot follows InboxCounts.hasDot', (tester) async {
      await pumpSocial(tester, location: '/hub', fakes: fullInbox());
      expect(find.byKey(const ValueKey('inbox-dot')), findsOneWidget);
      final size = tester.getSize(find.byKey(const ValueKey('inbox-entry')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byKey(const ValueKey('inbox-entry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('inbox-screen')), findsOneWidget);
    });

    testWidgets('public-journey requests alone do not light the dot', (
      tester,
    ) async {
      final fakes = SocialFakes(
        insights: FakeInsightsRepository(
          const InboxCounts(
            friendRequests: 0,
            publicRequests: 5,
            newShares: 0,
            unreadMessages: 0,
            consentRequests: 0,
          ),
        ),
      );
      await pumpSocial(tester, location: '/hub', fakes: fakes);
      expect(find.byKey(const ValueKey('inbox-entry')), findsOneWidget);
      expect(find.byKey(const ValueKey('inbox-dot')), findsNothing);
    });

    testWidgets('renders nothing in local-only mode', (tester) async {
      await pumpSocial(tester, location: '/hub', localOnly: true);
      expect(find.byKey(const ValueKey('inbox-entry')), findsNothing);
    });
  });
}
