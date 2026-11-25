import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/social/data/social_providers.dart';
import 'package:ourney/features/social/social_paths.dart';
import 'package:ourney/ui/ui.dart' show UiSkeleton;
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

/// The feed is a lazy list: scroll the row at [key] into view.
Future<void> reveal(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    f,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

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
    // Opening the tab marks everything read (Figma markActivityRead).
    expect(dotsIn('inbox-request-khoa'), findsNothing);
    expect(dotsIn('inbox-consent-dalat'), findsNothing);
    expect(dotsIn('inbox-conversation-c1'), findsNothing);
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

    expect(dotsIn('inbox-conversation-c2'), findsNothing);
    expect(dotsIn('inbox-public-hoi-an'), findsNothing);
    expect(find.byKey(const ValueKey('unread-badge')), findsOneWidget);
  });

  testWidgets('tapping New shares opens the Shared segment in Hub (DE-18)', (
    tester,
  ) async {
    final router = await pumpSocial(
      tester,
      location: SocialPaths.inbox,
      fakes: fullInbox(),
    );
    await tester.tap(find.byKey(const ValueKey('inbox-shares-open')));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/journeys?segment=shared');
  });

  testWidgets('blocking someone drops their request and thread at once '
      '(C-B3)', (tester) async {
    final fakes = fullInbox();
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fakes);
    expect(find.text('Friend request from Khoa Le'), findsOneWidget);
    expect(find.byKey(const ValueKey('inbox-conversation-c1')), findsOneWidget);

    await fakes.safety.block('khoa');
    await fakes.safety.block('nam');
    await tester.pumpAndSettle();
    expect(find.text('Friend request from Khoa Le'), findsNothing);
    expect(find.byKey(const ValueKey('inbox-accept-khoa')), findsNothing);
    expect(find.byKey(const ValueKey('inbox-conversation-c1')), findsNothing);
  });

  testWidgets('V2 header, Today / This week, no back button as a tab', (
    tester,
  ) async {
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fullInbox());
    expect(find.text('activity.'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Mark all read'), findsNothing);
    expect(find.byKey(const ValueKey('social-back')), findsNothing);
    expect(find.byKey(const ValueKey('inbox-filter-all')), findsOneWidget);
  });

  testWidgets('vi header and sections', (tester) async {
    await pumpSocial(
      tester,
      location: SocialPaths.inbox,
      fakes: fullInbox(),
      locale: const Locale('vi'),
    );
    expect(find.text('hoạt động.'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Tuần này'), findsOneWidget);
  });

  testWidgets('UX-21: items older than 7 days group under Earlier / Trước đó', (
    tester,
  ) async {
    final fakes = SocialFakes(
      friends: FakeFriendRepository([
        request(
          'recent',
          name: 'Recent Friend',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        request(
          'old',
          name: 'Old Friend',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      ]),
      insights: FakeInsightsRepository(
        const InboxCounts(
          friendRequests: 2,
          publicRequests: 0,
          newShares: 0,
          unreadMessages: 0,
          consentRequests: 0,
        ),
      ),
    );
    await pumpSocial(
      tester,
      location: SocialPaths.inbox,
      fakes: fakes,
      locale: const Locale('vi'),
    );
    expect(find.text('Tuần này'), findsOneWidget);
    expect(find.text('Trước đó'), findsOneWidget);
  });

  testWidgets('rows carry a full-sentence label and a weekday time', (
    tester,
  ) async {
    await pumpSocial(
      tester,
      location: SocialPaths.inbox,
      fakes: fullInbox(),
      locale: const Locale('vi'),
    );
    // Friend request created on a past day: weekday abbreviation on the right.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('inbox-request-khoa')),
        matching: find.byKey(const ValueKey('activity-time')),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Khoa Le.* · @khoa · (T[2-7]|CN)$')),
      findsOneWidget,
    );
  });

  testWidgets('accept a friend request inline', (tester) async {
    final fakes = fullInbox();
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fakes);
    await reveal(tester, 'inbox-accept-khoa');
    await tester.tap(find.byKey(const ValueKey('inbox-accept-khoa')));
    await tester.pumpAndSettle();
    expect(fakes.friends.calls, ['accept:khoa']);
    expect(find.byKey(const ValueKey('inbox-request-khoa')), findsNothing);
  });

  testWidgets('agree / decline a share consent', (tester) async {
    final fakes = fullInbox();
    await pumpSocial(tester, location: SocialPaths.inbox, fakes: fakes);
    await reveal(tester, 'consent-agree-dalat');
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
    expect(find.text('Decline all friend requests?'), findsOneWidget);
    expect(
      find.text('Decline all 2 friend requests from this journey?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('social-confirm')));
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
    await pumpSocial(
      tester,
      location: SocialPaths.inbox,
      locale: const Locale('vi'),
    );
    expect(find.byKey(const ValueKey('inbox-empty')), findsOneWidget);
    expect(find.text('chưa có gì mới.'), findsOneWidget);
    expect(
      find.text('Những cập nhật từ hành trình sẽ xuất hiện ở đây.'),
      findsOneWidget,
    );
  });

  group('states at 320dp, 1.35x', () {
    for (final brightness in Brightness.values) {
      final tag = brightness.name;

      testWidgets('empty $tag', (tester) async {
        await pumpSocial(
          tester,
          location: SocialPaths.inbox,
          brightness: brightness,
          width: 320,
          textScale: 1.35,
          locale: const Locale('vi'),
        );
        expect(find.byKey(const ValueKey('inbox-empty')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('loading skeleton $tag', (tester) async {
        final never = StreamController<List<Friendship>>();
        final neverC = StreamController<List<Conversation>>();
        addTearDown(never.close);
        addTearDown(neverC.close);
        await pumpSocial(
          tester,
          location: SocialPaths.inbox,
          brightness: brightness,
          width: 320,
          textScale: 1.35,
          settle: false,
          overrides: [
            friendshipsProvider.overrideWith((ref) => never.stream),
            conversationsProvider.overrideWith((ref) => neverC.stream),
          ],
        );
        expect(find.byKey(const ValueKey('inbox-loading')), findsOneWidget);
        expect(find.byType(UiSkeleton), findsNWidgets(5));
        expect(tester.takeException(), isNull);
      });

      testWidgets('error $tag', (tester) async {
        await pumpSocial(
          tester,
          location: SocialPaths.inbox,
          brightness: brightness,
          width: 320,
          textScale: 1.35,
          overrides: [
            friendshipsProvider.overrideWith(
              (ref) => Stream.error(
                const OurneyException(OurneyErrorCode.forbidden),
              ),
            ),
            conversationsProvider.overrideWith(
              (ref) => Stream.error(
                const OurneyException(OurneyErrorCode.forbidden),
              ),
            ),
          ],
        );
        expect(find.byKey(const ValueKey('inbox-error')), findsOneWidget);
        expect(find.byKey(const ValueKey('inbox-offline')), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('offline strip over cached feed $tag', (tester) async {
        Stream<List<T>> cachedThenOffline<T>(List<T> v) async* {
          yield v;
          throw const OurneyException(OurneyErrorCode.offline);
        }

        await pumpSocial(
          tester,
          location: SocialPaths.inbox,
          fakes: fullInbox(),
          brightness: brightness,
          width: 320,
          textScale: 1.35,
          locale: const Locale('vi'),
          overrides: [
            friendshipsProvider.overrideWith(
              (ref) => cachedThenOffline([request('khoa', name: 'Khoa Le')]),
            ),
          ],
        );
        expect(find.byKey(const ValueKey('inbox-offline')), findsOneWidget);
        expect(find.text('Đang xem bản đã lưu.'), findsOneWidget);
        await reveal(tester, 'inbox-request-khoa');
        expect(
          find.byKey(const ValueKey('inbox-request-khoa')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
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
