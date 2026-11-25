import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/redirect.dart' show kMalformedInviteSegment;
import 'package:ourney_core/ourney_core.dart';

import 'groups_fakes.dart';

void main() {
  group('Join by code (FR-D1/D2)', () {
    testWidgets('deep link pre-fills the code; joining opens Today', (
      tester,
    ) async {
      final g = groupJourney();
      final h = await pumpGroups(
        tester,
        location: AppRoutes.join('abcd1234'),
        journeys: FakeJourneyRepository(journeys: [g]),
        groups: FakeGroupRepository(
          today: {
            'g1': [memberToday(me, 'Me')],
          },
        ),
      );
      expect(find.text("You're invited to a squad journey"), findsOneWidget);
      expect(find.text('ABCD1234'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('groups-join-submit')));
      await tester.pumpAndSettle();
      expect(h.groups.calls, ['join:ABCD1234']);
      expect(h.location, '/groups/g1');
      expect(find.byKey(const ValueKey('group-today')), findsOneWidget);
    });

    testWidgets('manual entry: button enabled only for 8 characters', (
      tester,
    ) async {
      final h = await pumpGroups(tester, location: '/join');
      final submit = find.byKey(const ValueKey('groups-join-submit'));
      await tester.enterText(
        find.byKey(const ValueKey('groups-join-code')),
        'ab-12',
      );
      await tester.pump();
      await tester.tap(submit);
      await tester.pump();
      expect(h.groups.calls, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('groups-join-code')),
        'zz99yy88',
      );
      await tester.pump();
      expect(find.text('ZZ99YY88'), findsOneWidget);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(h.groups.calls, ['join:ZZ99YY88']);
    });

    testWidgets('UX-30: changing the invite path resets the join screen', (
      tester,
    ) async {
      final invites = FakeGroupInviteRepository(preview: groupPreview());
      final h = await pumpGroups(
        tester,
        location: AppRoutes.join('ABCD1234'),
        invites: invites,
      );
      final error = find.byKey(const ValueKey('groups-join-error'));
      expect(find.text('ABCD1234'), findsOneWidget);
      expect(error, findsNothing);

      await h.go(tester, AppRoutes.join(kMalformedInviteSegment));
      expect(error, findsOneWidget);
      expect(find.text('ABCD1234'), findsNothing);

      await h.go(tester, AppRoutes.join('ZZ99YY88'));
      expect(error, findsNothing);
      expect(find.text('ZZ99YY88'), findsOneWidget);
      expect(invites.calls.where((call) => call.startsWith('preview:')), [
        'preview:ABCD1234',
        'preview:ZZ99YY88',
      ]);
    });

    testWidgets(
      'UX-15 & UX-30: Paste button fills code from clipboard, and malformed deep link shows error',
      (tester) async {
        final h = await pumpGroups(
          tester,
          location: AppRoutes.join('bad'),
          clipboardText: 'https://ourney.tech/j/abcd2345',
        );
        // Malformed initial deep link `/join/bad` immediately shows invalid-code error (UX-30).
        expect(find.byKey(const ValueKey('groups-join-error')), findsOneWidget);

        // Tapping Paste extracts the 8-char invite code from the clipboard URL (UX-15).
        await tester.tap(find.byKey(const ValueKey('groups-join-paste')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('groups-join-error')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('groups-join-submit')));
        await tester.pumpAndSettle();
        expect(h.groups.calls, ['join:ABCD2345']);
      },
    );

    final errors = {
      OurneyErrorCode.notFound: 'No squad uses this code.',
      OurneyErrorCode.full: 'This squad is full (10 members).',
      OurneyErrorCode.blocked: "You can't join this squad.",
      OurneyErrorCode.ended: 'This journey has ended.',
      OurneyErrorCode.offline: "You're offline.",
    };
    for (final entry in errors.entries) {
      testWidgets('maps ${entry.key.wireName}', (tester) async {
        final repo = FakeGroupRepository()
          ..joinError = GroupException(entry.key.wireName);
        final h = await pumpGroups(
          tester,
          location: AppRoutes.join('ABCD1234'),
          groups: repo,
        );
        await tester.tap(find.byKey(const ValueKey('groups-join-submit')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('groups-join-error')), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(h.location, '/join/ABCD1234');
      });
    }
  });
}
