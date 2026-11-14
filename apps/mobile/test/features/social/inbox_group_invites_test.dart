import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/groups/data/groups_providers.dart';
import 'package:ourney/features/social/social_paths.dart';

import '../groups/groups_fakes.dart'
    show FakeGroupInviteRepository, groupInvitation;
import 'social_fakes.dart';

void main() {
  testWidgets('pending group invitation shows Join / Skip in Activity', (
    tester,
  ) async {
    final invites = FakeGroupInviteRepository(
      invitations: [groupInvitation('i1')],
    );
    final router = await pumpSocial(
      tester,
      location: SocialPaths.inbox,
      overrides: [groupInviteRepositoryProvider.overrideWithValue(invites)],
    );
    expect(find.text('Ha invited you to Hoi IELTS'), findsOneWidget);
    expect(find.text('5 of 10 members'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('inbox-group-invite-skip-i1')));
    await tester.pumpAndSettle();
    expect(invites.calls, contains('decline:i1'));
    expect(find.byKey(const ValueKey('inbox-group-invite-i1')), findsNothing);
    expect(router.state.uri.path, SocialPaths.inbox);
  });

  testWidgets('Join accepts the invitation and opens the group', (
    tester,
  ) async {
    final invites = FakeGroupInviteRepository(
      invitations: [groupInvitation('i1')],
    );
    final router = await pumpSocial(
      tester,
      location: SocialPaths.inbox,
      overrides: [groupInviteRepositoryProvider.overrideWithValue(invites)],
    );
    await tester.tap(find.byKey(const ValueKey('inbox-group-invite-join-i1')));
    await tester.pump();
    await tester.pump();
    expect(invites.calls, contains('accept:i1'));
    expect(router.routeInformationProvider.value.uri.path, '/groups/g1');
  });

  testWidgets('without a group invite backend the feed is unchanged', (
    tester,
  ) async {
    await pumpSocial(tester, location: SocialPaths.inbox);
    expect(find.byKey(const ValueKey('inbox-screen')), findsOneWidget);
    expect(find.textContaining('invited you to'), findsNothing);
  });
}
