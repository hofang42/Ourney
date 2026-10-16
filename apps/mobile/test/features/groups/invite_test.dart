import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'groups_fakes.dart';

void main() {
  group('Invite (FR-D1)', () {
    Future<GroupsHarness> pump(WidgetTester tester, {bool owner = true}) {
      final g = groupJourney(ownerId: owner ? me : 'u2');
      return pumpGroups(
        tester,
        location: '/groups/g1',
        journeys: FakeJourneyRepository(
          journeys: [g],
          memberships: {'g1': groupMembership(g)},
        ),
        groups: FakeGroupRepository(
          today: {
            'g1': [memberToday(me, 'Minh')],
          },
        ),
      );
    }

    testWidgets('code, QR, copy and share link', (tester) async {
      final h = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('group-invite')));
      await tester.pumpAndSettle();
      expect(h.location, '/groups/g1/invite');
      expect(find.text('ABCD1234'), findsOneWidget);
      expect(
        tester.widget<QrImageView>(find.byType(QrImageView)).semanticsLabel,
        'QR code of the invite link',
      );

      await tester.tap(find.byKey(const ValueKey('group-invite-copy')));
      await tester.pumpAndSettle();
      expect(h.copied, ['ABCD1234']);
      expect(find.text('Invite code copied.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('group-invite-share')));
      await tester.pumpAndSettle();
      expect(h.shared.single, contains('ourney://join/ABCD1234'));
    });

    testWidgets('owner rotates the code', (tester) async {
      final h = await pump(tester);
      await h.go(tester, '/groups/g1/invite');
      await tester.tap(find.byKey(const ValueKey('group-invite-rotate')));
      await tester.pumpAndSettle();
      expect(find.text('Change the invite code?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('groups-confirm')));
      await tester.pumpAndSettle();
      expect(h.groups.calls, contains('rotate:g1'));
      expect(find.text('NEWCODE9'), findsOneWidget);
    });

    testWidgets('members cannot rotate', (tester) async {
      final h = await pump(tester, owner: false);
      await h.go(tester, '/groups/g1/invite');
      expect(find.text('ABCD1234'), findsOneWidget);
      expect(find.byKey(const ValueKey('group-invite-rotate')), findsNothing);
    });
  });
}
