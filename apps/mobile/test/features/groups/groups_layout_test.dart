import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney_core/ourney_core.dart';

import 'groups_fakes.dart';

/// Squad screens on a 320dp phone at 1.35x text, light and dark: no overflow,
/// every tap target 48dp, the polaroid wall in the journey style.
void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    Future<GroupsHarness> pump(WidgetTester tester, String location) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.textScaleFactorTestValue = 1.35;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final g = groupJourney(
        title: 'Một nhóm có cái tên khá là dài để thử cắt chữ',
      );
      final annToday = testCheckIn('g1', testToday, userId: 'u2');
      final h = await pumpGroups(
        tester,
        location: location,
        journeys: FakeJourneyRepository(
          journeys: [g],
          memberships: {'g1': groupMembership(g)},
        ),
        checkIns: FakeCheckInRepository([annToday]),
        groups: FakeGroupRepository(
          today: {
            'g1': [
              memberToday(me, 'Minh', role: MemberRole.owner, streak: 0),
              memberToday('u2', 'Ann', today: annToday, streak: 5),
              memberToday('u3', 'Bao', streak: 0),
            ],
          },
        ),
      );
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('$mode: squad tab', (tester) async {
      await pump(tester, '/groups');
      expect(tester.takeException(), isNull);
      for (final key in ['groups-join', 'groups-create', 'group-card-g1']) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.height, greaterThanOrEqualTo(48), reason: key);
        expect(size.width, greaterThanOrEqualTo(48), reason: key);
      }
      expect(find.byKey(const ValueKey('profile-entry')), findsWidgets);
    });

    testWidgets('$mode: squad wall', (tester) async {
      await pump(tester, '/groups/g1');
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('group-today-header')), findsOneWidget);
      expect(find.text('1 of 3 checked in today'), findsWidgets);
      expect(
        find.byKey(const ValueKey('group-member-photo-u2')),
        findsOneWidget,
      );
      // Waiting members get their own tile, not a photo.
      expect(
        find.byKey(const ValueKey('group-member-nophoto-u3')),
        findsOneWidget,
      );
      for (final key in ['group-invite', 'group-menu']) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.width, greaterThanOrEqualTo(48), reason: key);
        expect(size.height, greaterThanOrEqualTo(48), reason: key);
      }
    });

    testWidgets('$mode: invite and join', (tester) async {
      await pump(tester, '/groups/g1/invite');
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('group-invite-screen')), findsOneWidget);
    });

    testWidgets('$mode: join by code', (tester) async {
      await pump(tester, '/join/ABCD1234');
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('groups-join-screen')), findsOneWidget);
    });
  }
}
