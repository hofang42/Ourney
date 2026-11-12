import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/groups/ui/group_safety_hooks.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import 'groups_fakes.dart';

const _yesterday = LocalDate(2026, 10, 15);
const _older = LocalDate(2026, 10, 12);

Future<GroupsHarness> _pump(
  WidgetTester tester, {
  JourneyStatus status = JourneyStatus.active,
  Set<String> blocked = const {},
  List<Reaction> reactions = const [],
  GroupSafetyHooks hooks = const GroupSafetyHooks(),
}) {
  final g = groupJourney(status: status);
  final annToday = testCheckIn('g1', testToday, userId: 'u2');
  return pumpGroups(
    tester,
    location: '/groups/g1',
    journeys: FakeJourneyRepository(
      journeys: [g],
      memberships: {'g1': groupMembership(g)},
    ),
    checkIns: FakeCheckInRepository([
      annToday,
      testCheckIn('g1', _older, userId: 'u3'),
      testCheckIn('g1', _yesterday, userId: me),
      testCheckIn('g1', const LocalDate(2026, 10, 14), userId: me),
      testCheckIn('g1', _yesterday, userId: 'u4'),
    ]),
    safety: FakeSafetyRepository(blocked),
    hooks: hooks,
    groups: FakeGroupRepository(
      today: {
        'g1': [
          memberToday(me, 'Minh', role: MemberRole.owner, streak: 0),
          memberToday('u2', 'Ann', today: annToday, streak: 5),
          memberToday('u3', 'Bao', streak: 0),
          memberToday('u4', 'Blocky', streak: 2),
        ],
      },
      reactions: {annToday.id: reactions},
    ),
  );
}

void main() {
  group('Group Today (FR-D3/D5)', () {
    testWidgets('done / not-yet sections, status text and streaks', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('1 of 4 checked in today'), findsOneWidget);
      expect(find.text('Day 7 of 30'), findsOneWidget);
      expect(find.text('Checked in today'), findsOneWidget);
      expect(find.text('Not yet today'), findsOneWidget);
      expect(find.text('Done today'), findsOneWidget);
      expect(find.text('Not yet'), findsNWidgets(3));
      expect(find.text('You · Owner'), findsOneWidget);

      // Ann first (done), then the others in join order: no ranking.
      final at = {
        for (final id in [me, 'u2', 'u3', 'u4'])
          id: tester.getCenter(find.byKey(ValueKey('group-member-$id'))),
      };
      // Reading order of the two-column wall (tiles in a row may differ by a
      // few dp because of their tilt).
      bool before(String a, String b) =>
          at[a]!.dy < at[b]!.dy - 20 ||
          ((at[a]!.dy - at[b]!.dy).abs() <= 20 && at[a]!.dx < at[b]!.dx);
      expect(before('u2', me), isTrue);
      expect(before(me, 'u3'), isTrue);
      expect(before('u3', 'u4'), isTrue);

      int streakOf(String id) => int.parse(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(ValueKey('group-member-streak-$id')),
                matching: find.byType(Text),
              ),
            )
            .data!,
      );
      expect(streakOf('u2'), 5);
      // Caller: computed locally from own check-ins (14th + 15th), late-join
      // aware, even though the server row says 0.
      expect(streakOf(me), 2);
      expect(streakOf('u4'), 2);

      // Latest (older) photos for members not done today.
      expect(find.byKey(const ValueKey('group-member-photo-u3')), findsOne);
      expect(find.textContaining('Latest: '), findsNWidgets(3));
    });

    testWidgets('blocked users are hidden, also right after blocking', (
      tester,
    ) async {
      final h = await _pump(tester, blocked: {'u4'});
      expect(find.byKey(const ValueKey('group-member-u4')), findsNothing);
      expect(find.text('1 of 3 checked in today'), findsOneWidget);

      h.safety.setBlocked({'u4', 'u2'});
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('group-member-u2')), findsNothing);
      expect(find.text('0 of 2 checked in today'), findsOneWidget);
    });

    testWidgets('a reported photo disappears at once (FR-F2)', (tester) async {
      final h = await _pump(tester);
      expect(find.byKey(const ValueKey('group-member-photo-u2')), findsOne);
      h.container
          .read(hiddenCheckInIdsProvider.notifier)
          .hide(testCheckIn('g1', testToday, userId: 'u2').id);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('group-member-photo-u2')), findsNothing);
      // Still counted as done today: only the content is hidden.
      expect(find.text('1 of 4 checked in today'), findsOneWidget);
    });

    testWidgets('default hooks open the safety report sheet and hide', (
      tester,
    ) async {
      final h = await _pump(tester, hooks: safetyGroupHooks);
      await tester.tap(find.byKey(const ValueKey('group-member-menu-u2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('group-member-action-block')), findsOne);
      await tester.tap(
        find.byKey(const ValueKey('group-member-action-report')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('safety-report-form')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('safety-reason-spam')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('safety-report-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('safety-report-submit')));
      await tester.pumpAndSettle();
      expect(h.container.read(hiddenCheckInIdsProvider), hasLength(1));
      await tester.tap(find.byKey(const ValueKey('safety-report-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('group-member-photo-u2')), findsNothing);
    });

    testWidgets('ended journey: banner, reactions read-only', (tester) async {
      await _pump(
        tester,
        status: JourneyStatus.ended,
        reactions: [
          Reaction(
            checkInId: 'c-g1-2026-10-16',
            userId: 'u3',
            emoji: '🔥',
            createdAt: testNow,
          ),
        ],
      );
      expect(find.byKey(const ValueKey('group-ended-banner')), findsOneWidget);
      expect(find.byKey(const ValueKey('group-invite')), findsNothing);
      // Only emojis with counts remain, and they are not tappable.
      final bar = find.byKey(
        const ValueKey('groups-reactions-c-g1-2026-10-16'),
      );
      expect(
        find.descendant(of: bar, matching: find.byType(UiPressable)),
        findsOneWidget,
      );
      expect(
        tester
            .widget<UiPressable>(
              find.descendant(of: bar, matching: find.byType(UiPressable)),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('not a member (forbidden) shows a friendly state', (
      tester,
    ) async {
      final g = groupJourney();
      await pumpGroups(
        tester,
        location: '/groups/g1',
        journeys: FakeJourneyRepository(journeys: [g]),
        groups: FakeGroupRepository()
          ..todayError = const GroupException.of(OurneyErrorCode.forbidden),
      );
      expect(find.byKey(const ValueKey('group-not-member')), findsOneWidget);
    });
  });

  group('Reactions (FR-D4)', () {
    testWidgets('react, switch emoji, unreact; counts update', (tester) async {
      final h = await _pump(
        tester,
        reactions: [
          Reaction(
            checkInId: 'c-g1-2026-10-16',
            userId: 'u3',
            emoji: '🔥',
            createdAt: testNow,
          ),
        ],
      );
      const id = 'c-g1-2026-10-16';
      Finder chip(String e) => find.byKey(ValueKey('groups-react-$id-$e'));
      expect(
        find.descendant(of: chip('🔥'), matching: find.text('1')),
        findsOne,
      );

      await tester.tap(chip('💪'));
      await tester.pumpAndSettle();
      expect(h.groups.calls.last, 'react:$id:💪');
      expect(
        find.descendant(of: chip('💪'), matching: find.text('1')),
        findsOne,
      );

      await tester.tap(chip('🔥'));
      await tester.pumpAndSettle();
      expect(h.groups.calls.last, 'react:$id:🔥');
      expect(
        find.descendant(of: chip('🔥'), matching: find.text('2')),
        findsOne,
      );
      expect(
        find.descendant(of: chip('💪'), matching: find.text('1')),
        findsNothing,
      );

      await tester.tap(chip('🔥'));
      await tester.pumpAndSettle();
      expect(h.groups.calls.last, 'unreact:$id');
      expect(
        find.descendant(of: chip('🔥'), matching: find.text('1')),
        findsOne,
      );
    });

    testWidgets('reactions from blocked users are not counted', (tester) async {
      await _pump(
        tester,
        blocked: {'u3'},
        reactions: [
          Reaction(
            checkInId: 'c-g1-2026-10-16',
            userId: 'u3',
            emoji: '😂',
            createdAt: testNow,
          ),
        ],
      );
      final chip = find.byKey(
        const ValueKey('groups-react-c-g1-2026-10-16-😂'),
      );
      expect(find.descendant(of: chip, matching: find.text('1')), findsNothing);
    });

    testWidgets('a failed reaction shows the mapped error', (tester) async {
      final h = await _pump(tester);
      h.groups.reactError = const GroupException.of(OurneyErrorCode.ended);
      await tester.tap(
        find.byKey(const ValueKey('groups-react-c-g1-2026-10-16-👏')),
      );
      await tester.pumpAndSettle();
      expect(find.text('This journey has ended.'), findsOneWidget);
    });
  });
}
