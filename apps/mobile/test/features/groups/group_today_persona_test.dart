import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/personas/accountability_squad/share_card.dart';
import 'package:ourney_core/ourney_core.dart';

import 'groups_fakes.dart';

/// F3: the squad persona shows its polaroid wall on the group "Today"
/// screen, and every member keeps the report / block actions.
void main() {
  Journey squadJourney(TemplateId template) {
    final g = groupJourney();
    return Journey(
      id: g.id,
      ownerId: g.ownerId,
      kind: g.kind,
      templateId: template,
      title: g.title,
      emoji: g.emoji,
      startDate: g.startDate,
      durationDays: g.durationDays,
      timezone: g.timezone,
      visibility: g.visibility,
      status: g.status,
      inviteCode: g.inviteCode,
    );
  }

  Future<void> pump(WidgetTester tester, TemplateId template) async {
    final g = squadJourney(template);
    final ann = testCheckIn('g1', testToday, userId: 'u2');
    await pumpGroups(
      tester,
      location: '/groups/g1',
      journeys: FakeJourneyRepository(
        journeys: [g],
        memberships: {'g1': groupMembership(g)},
      ),
      checkIns: FakeCheckInRepository([ann]),
      safety: FakeSafetyRepository(const {}),
      groups: FakeGroupRepository(
        today: {
          'g1': [
            memberToday(me, 'Minh', role: MemberRole.owner, streak: 0),
            memberToday('u2', 'Ann', today: ann, streak: 5),
          ],
        },
      ),
    );
  }

  testWidgets('English journey: wall on top, member cards with the report '
      'menu below', (tester) async {
    await pump(tester, TemplateId.englishDaily);
    expect(find.byType(SquadPolaroidWall), findsOneWidget);
    expect(find.byKey(const ValueKey('group-member-u2')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-member-menu-u2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('other journeys keep the header and the member list', (
    tester,
  ) async {
    await pump(tester, TemplateId.workout30);
    expect(find.byType(SquadPolaroidWall), findsNothing);
    expect(find.byKey(const ValueKey('group-today-header')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-member-u2')), findsOneWidget);
  });
}
