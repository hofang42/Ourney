import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/groups/ui/group_safety_hooks.dart';
import 'package:ourney_core/ourney_core.dart';

import 'groups_fakes.dart';

Future<GroupsHarness> _pump(
  WidgetTester tester, {
  bool owner = true,
  bool alone = false,
  GroupSafetyHooks hooks = const GroupSafetyHooks(),
}) {
  final g = groupJourney(ownerId: owner ? me : 'u2');
  return pumpGroups(
    tester,
    location: '/groups/g1',
    hooks: hooks,
    journeys: FakeJourneyRepository(
      journeys: [g],
      memberships: {'g1': groupMembership(g)},
    ),
    groups: FakeGroupRepository(
      today: {
        'g1': [
          memberToday(
            me,
            'Minh',
            role: owner ? MemberRole.owner : MemberRole.member,
          ),
          if (!alone)
            memberToday(
              'u2',
              'Ann',
              role: owner ? MemberRole.member : MemberRole.owner,
            ),
        ],
      },
    ),
  );
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('group-menu')));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('groups-confirm')));
  await tester.pumpAndSettle();
}

void main() {
  group('Owner tools vs member (FR-D6/D7)', () {
    testWidgets('owner with members: rotate, end, leave; no delete', (
      tester,
    ) async {
      await _pump(tester);
      await _openMenu(tester);
      expect(find.byKey(const ValueKey('group-action-rotate')), findsOne);
      expect(find.byKey(const ValueKey('group-action-end')), findsOne);
      expect(find.byKey(const ValueKey('group-action-leave')), findsOne);
      expect(find.byKey(const ValueKey('group-action-delete')), findsNothing);
    });

    testWidgets('member: only leave; no remove-member menu', (tester) async {
      await _pump(tester, owner: false);
      expect(find.byKey(const ValueKey('group-member-menu-u2')), findsNothing);
      await _openMenu(tester);
      expect(find.byKey(const ValueKey('group-action-leave')), findsOne);
      expect(find.byKey(const ValueKey('group-action-rotate')), findsNothing);
      expect(find.byKey(const ValueKey('group-action-end')), findsNothing);
      expect(find.byKey(const ValueKey('group-action-delete')), findsNothing);
    });

    testWidgets('leave explains hidden check-ins and owner transfer', (
      tester,
    ) async {
      final h = await _pump(tester);
      await _openMenu(tester);
      await tester.tap(find.byKey(const ValueKey('group-action-leave')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your check-ins will be hidden from the group'),
        findsOneWidget,
      );
      expect(find.textContaining('ownership passes'), findsOneWidget);
      await _confirm(tester);
      expect(h.groups.calls, contains('leave:g1'));
      expect(h.location, '/groups');
    });

    testWidgets('member leave has no owner note; cancel does nothing', (
      tester,
    ) async {
      final h = await _pump(tester, owner: false);
      await _openMenu(tester);
      await tester.tap(find.byKey(const ValueKey('group-action-leave')));
      await tester.pumpAndSettle();
      expect(find.textContaining('ownership passes'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(h.groups.calls, isNot(contains('leave:g1')));
    });

    testWidgets('owner removes a member', (tester) async {
      final h = await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('group-member-menu-u2')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('group-member-action-remove')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remove Ann?'), findsOneWidget);
      await _confirm(tester);
      expect(h.groups.calls, contains('remove:g1:u2'));
      expect(find.byKey(const ValueKey('group-member-u2')), findsNothing);
      expect(find.text('Ann was removed.'), findsOneWidget);
    });

    testWidgets('owner ends the journey', (tester) async {
      final h = await _pump(tester);
      await _openMenu(tester);
      await tester.tap(find.byKey(const ValueKey('group-action-end')));
      await tester.pumpAndSettle();
      await _confirm(tester);
      expect(h.journeys.calls, contains('end:g1'));
      expect(find.byKey(const ValueKey('group-ended-banner')), findsOneWidget);
    });

    testWidgets('alone owner can delete; not_alone is mapped', (tester) async {
      final h = await _pump(tester, alone: true);
      h.journeys.deleteError = const OurneyException(OurneyErrorCode.notAlone);
      await _openMenu(tester);
      await tester.tap(find.byKey(const ValueKey('group-action-delete')));
      await tester.pumpAndSettle();
      await _confirm(tester);
      expect(h.journeys.calls, contains('delete:g1'));
      expect(
        find.textContaining('Other members are still in the group'),
        findsOneWidget,
      );

      h.journeys.deleteError = null;
      await _openMenu(tester);
      await tester.tap(find.byKey(const ValueKey('group-action-delete')));
      await tester.pumpAndSettle();
      await _confirm(tester);
      expect(h.location, '/groups');
    });

    testWidgets('alone owner leaving is told the journey gets archived', (
      tester,
    ) async {
      await _pump(tester, alone: true);
      await _openMenu(tester);
      await tester.tap(find.byKey(const ValueKey('group-action-leave')));
      await tester.pumpAndSettle();
      expect(find.textContaining('will be archived'), findsOneWidget);
    });
  });

  group('Report / block entry points (safety hooks)', () {
    testWidgets('hidden without hooks (member, non-owner)', (tester) async {
      await _pump(tester, owner: false);
      expect(find.byKey(const ValueKey('group-member-menu-u2')), findsNothing);
    });

    testWidgets('hooks receive the member and their photo', (tester) async {
      final reported = <String>[];
      final blocked = <String>[];
      await _pump(
        tester,
        owner: false,
        hooks: GroupSafetyHooks(
          onReport: (
            context, {
            required userId,
            required displayName,
            checkInId,
          }) async => reported.add('$userId:$displayName:$checkInId'),
          onBlock: (context, {required userId, required displayName}) async =>
              blocked.add(userId),
        ),
      );
      expect(find.byKey(const ValueKey('group-member-menu-$me')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('group-member-menu-u2')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('group-member-action-remove')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('group-member-action-report')),
      );
      await tester.pumpAndSettle();
      expect(reported, ['u2:Ann:null']);

      await tester.tap(find.byKey(const ValueKey('group-member-menu-u2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('group-member-action-block')));
      await tester.pumpAndSettle();
      expect(blocked, ['u2']);
    });
  });
}
