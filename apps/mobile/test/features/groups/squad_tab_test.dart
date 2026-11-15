import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/groups/ui/group_safety_hooks.dart';

import 'groups_fakes.dart';

void main() {
  group('Squad tab (V2 sections)', () {
    testWidgets('join-inline formats the code and opens the join screen', (
      tester,
    ) async {
      final h = await pumpGroups(
        tester,
        journeys: FakeJourneyRepository(journeys: [groupJourney()]),
      );
      final submit = find.byKey(const ValueKey('squad-join-submit'));
      await tester.enterText(
        find.byKey(const ValueKey('squad-join-field')),
        'k7q2m9xa',
      );
      await tester.pump();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(h.location, '/join/K7Q2M9XA');
    });

    testWidgets('today strip: counts, avatar chips, member sheet hooks', (
      tester,
    ) async {
      final calls = <String>[];
      await pumpGroups(
        tester,
        journeys: FakeJourneyRepository(journeys: [groupJourney()]),
        groups: FakeGroupRepository(
          today: {
            'g1': [
              memberToday(
                'u1',
                'Linh',
                today: testCheckIn('g1', testToday, userId: 'u1'),
              ),
              memberToday('u2', 'An'),
            ],
          },
        ),
        hooks: GroupSafetyHooks(
          onReport: (
            context, {
            required userId,
            required displayName,
            checkInId,
          }) async => calls.add('report:$userId'),
          onBlock: (context, {required userId, required displayName}) async =>
              calls.add('block:$userId'),
        ),
      );
      expect(find.byKey(const ValueKey('squad-today-g1')), findsOneWidget);
      expect(find.text('1/2 checked in'), findsOneWidget);
      expect(find.text('not yet'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('squad-member-u2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('squad-member-sheet')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('squad-member-block')));
      await tester.pumpAndSettle();
      expect(calls, ['block:u2']);
    });

    testWidgets('pending invites: join accepts and opens the group', (
      tester,
    ) async {
      final invites = FakeGroupInviteRepository(
        invitations: [groupInvitation('i1')],
      );
      final h = await pumpGroups(
        tester,
        journeys: FakeJourneyRepository(journeys: [groupJourney()]),
        invites: invites,
      );
      expect(
        find.byKey(const ValueKey('squad-pending-invites')),
        findsOneWidget,
      );
      final accept = find.byKey(const ValueKey('squad-invite-accept-i1'));
      await tester.ensureVisible(accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(invites.calls, contains('accept:i1'));
      expect(h.location, '/groups/g1');
    });
  });
}
