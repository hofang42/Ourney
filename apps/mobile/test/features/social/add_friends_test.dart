import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/redirect.dart';
import 'package:ourney/features/social/social_paths.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'social_fakes.dart';

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('username-field')), text);
  await tester.tap(find.byKey(const ValueKey('username-search')));
  await tester.pumpAndSettle();
}

void main() {
  group('username search', () {
    testWidgets('no exact match', (tester) async {
      final fakes = SocialFakes();
      await pumpSocial(tester, location: SocialPaths.friendsAdd, fakes: fakes);
      await search(tester, '@Nobody');
      expect(fakes.friends.calls, ['find:Nobody']);
      expect(find.text('No one with that username'), findsOneWidget);
    });

    testWidgets('match → Add friend → Requested', (tester) async {
      final fakes = SocialFakes();
      fakes.friends.directory['tuan.vo'] = person('tuan.vo', name: 'Tuan Vo');
      await pumpSocial(tester, location: SocialPaths.friendsAdd, fakes: fakes);
      await search(tester, '@tuan.vo');

      expect(find.byKey(const ValueKey('username-result')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('username-add')));
      await tester.pumpAndSettle();

      expect(fakes.friends.calls.last, 'send:tuan.vo');
      expect(find.byKey(const ValueKey('username-requested')), findsOneWidget);
      expect(find.byKey(const ValueKey('username-add')), findsNothing);
    });

    testWidgets('already friends', (tester) async {
      final fakes = SocialFakes(
        friends: FakeFriendRepository([friend('nam', name: 'Nam Tran')]),
      );
      fakes.friends.directory['nam'] = person('nam', name: 'Nam Tran');
      await pumpSocial(tester, location: SocialPaths.friendsAdd, fakes: fakes);
      await search(tester, 'nam');
      expect(find.byKey(const ValueKey('username-friends')), findsOneWidget);
    });

    testWidgets('incoming request can be accepted from the result', (
      tester,
    ) async {
      final fakes = SocialFakes(
        friends: FakeFriendRepository([request('khoa')]),
      );
      fakes.friends.directory['khoa'] = person('khoa');
      await pumpSocial(tester, location: SocialPaths.friendsAdd, fakes: fakes);
      await search(tester, 'khoa');
      await tester.tap(find.byKey(const ValueKey('username-accept')));
      await tester.pumpAndSettle();
      expect(fakes.friends.calls.last, 'accept:khoa');
      expect(find.byKey(const ValueKey('username-friends')), findsOneWidget);
    });

    testWidgets('own username', (tester) async {
      final fakes = SocialFakes();
      fakes.friends.directory['me'] = person(me);
      await pumpSocial(tester, location: SocialPaths.friendsAdd, fakes: fakes);
      await search(tester, 'me');
      expect(find.text("That's you"), findsOneWidget);
    });

    testWidgets('rate limited', (tester) async {
      final fakes = SocialFakes();
      fakes.friends.findError = const OurneyException(
        OurneyErrorCode.rateLimited,
      );
      await pumpSocial(tester, location: SocialPaths.friendsAdd, fakes: fakes);
      await search(tester, 'someone');
      expect(find.byKey(const ValueKey('username-error')), findsOneWidget);
      expect(
        find.text("That's a lot of tries. Please wait a bit."),
        findsOneWidget,
      );
    });
  });

  testWidgets('share invite link creates one token and shares the URL', (
    tester,
  ) async {
    final fakes = SocialFakes();
    await pumpSocial(tester, location: SocialPaths.friendsAdd, fakes: fakes);

    await tester.tap(find.byKey(const ValueKey('invite-share')));
    await tester.pumpAndSettle();
    expect(fakes.shared.single, contains('https://ourney.app/f/tok1'));

    await tester.tap(find.byKey(const ValueKey('invite-copy')));
    await tester.pumpAndSettle();
    expect(fakes.copied.single, 'https://ourney.app/f/tok1');
    expect(fakes.friends.invitesCreated, 1);
    expect(find.text('https://ourney.app/f/tok1'), findsOneWidget);
    // The QR code appears once the link exists.
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('QR block creates the link on tap and enlarges', (tester) async {
    final fakes = SocialFakes();
    await pumpSocial(tester, location: SocialPaths.friendsAdd, fakes: fakes);
    expect(find.byType(QrImageView), findsNothing);
    await tester.tap(find.text('My QR code'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('invite-qr')), findsOneWidget);
    await tester.tap(find.text('My QR code'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('invite-qr-large')), findsOneWidget);
  });

  group('invite deep link', () {
    test('ourney://friend/<token> opens /f/<token>', () {
      expect(
        normalizeDeepLink(Uri.parse('ourney://friend/abc123')),
        SocialPaths.invite('abc123'),
      );
    });

    testWidgets('accepts and shows the new friend', (tester) async {
      final fakes = SocialFakes();
      await pumpSocial(
        tester,
        location: SocialPaths.invite('abc'),
        fakes: fakes,
      );
      expect(fakes.friends.calls, ['acceptInvite:abc']);
      expect(find.text('You and Nam Tran are friends now'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('invite-see-friends')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('friends-screen')), findsOneWidget);
    });

    for (final (code, key) in [
      (OurneyErrorCode.notFound, 'invite-not-found'),
      (OurneyErrorCode.invalid, 'invite-own'),
      (OurneyErrorCode.blocked, 'invite-blocked'),
      (OurneyErrorCode.offline, 'invite-error'),
    ]) {
      testWidgets('${code.wireName} shows its state', (tester) async {
        final fakes = SocialFakes();
        fakes.friends.acceptInviteError = OurneyException(code);
        await pumpSocial(
          tester,
          location: SocialPaths.invite('abc'),
          fakes: fakes,
        );
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      });
    }

    testWidgets('local-only shows NeedsServerView and calls nothing', (
      tester,
    ) async {
      final fakes = SocialFakes();
      await pumpSocial(
        tester,
        location: SocialPaths.invite('abc'),
        fakes: fakes,
        localOnly: true,
      );
      expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
      expect(fakes.friends.calls, isEmpty);
    });
  });

  testWidgets('add friends is NeedsServerView in local-only mode', (
    tester,
  ) async {
    await pumpSocial(tester, location: SocialPaths.friendsAdd, localOnly: true);
    expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
  });
}
