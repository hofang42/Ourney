import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/groups/ui/group_safety_hooks.dart';
import 'package:ourney/features/groups/ui/squad_tab_sections.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
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
      await tester.tap(find.byKey(const ValueKey('squad-join-open')));
      await tester.pump();
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

    testWidgets(
      'Today heading is above squad-join-open; join field opens on tap and focuses',
      (tester) async {
        await pumpGroups(
          tester,
          journeys: FakeJourneyRepository(journeys: [groupJourney()]),
        );
        final heading = find.text('Today');
        final openBtn = find.byKey(const ValueKey('squad-join-open'));
        expect(heading, findsOneWidget);
        expect(openBtn, findsOneWidget);
        expect(
          tester.getTopLeft(heading).dy,
          lessThan(tester.getTopLeft(openBtn).dy),
        );
        expect(find.byKey(const ValueKey('squad-join-field')), findsNothing);

        await tester.tap(openBtn);
        await tester.pump();
        expect(openBtn, findsNothing);
        final field = tester.widget<TextField>(
          find.byKey(const ValueKey('squad-join-field')),
        );
        expect(field.focusNode!.hasFocus, isTrue);
      },
    );

    testWidgets(
      'paste fills valid code and shows toast without overwriting on invalid text',
      (tester) async {
        String? clipboard = 'not-code!';
        await tester.pumpWidget(
          testApp(
            Scaffold(
              body: SquadJoinInline(
                enabled: true,
                onPasteRead: () async => clipboard,
              ),
            ),
            locale: const Locale('en'),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('squad-join-paste')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        final fieldFinder = find.byKey(const ValueKey('squad-join-field'));
        expect(tester.widget<TextField>(fieldFinder).controller!.text, isEmpty);
        expect(find.text('No invite code in your clipboard'), findsOneWidget);

        clipboard = 'k7q2m9xa';
        await tester.tap(find.byKey(const ValueKey('squad-join-paste')));
        await tester.pump();
        expect(
          tester.widget<TextField>(fieldFinder).controller!.text,
          'K7Q2-M9XA',
        );
      },
    );

    testWidgets(
      'own member sheet shows status and check-in action, hides report/block',
      (tester) async {
        final h = await pumpGroups(
          tester,
          journeys: FakeJourneyRepository(journeys: [groupJourney()]),
          groups: FakeGroupRepository(
            today: {
              'g1': [
                memberToday(me, 'Linh', streak: 3),
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
            }) async {},
            onBlock: (
              context, {
              required userId,
              required displayName,
            }) async {},
          ),
        );

        await tester.tap(find.byKey(const ValueKey('squad-member-u1')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('squad-member-sheet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('squad-member-status')),
          findsOneWidget,
        );
        expect(find.text('Not checked in yet today'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('squad-member-streak')),
          findsOneWidget,
        );
        expect(find.text('3-day streak'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('squad-member-checkin')),
          findsOneWidget,
        );
        expect(find.text('Check in now'), findsOneWidget);
        expect(find.byKey(const ValueKey('squad-member-report')), findsNothing);
        expect(find.byKey(const ValueKey('squad-member-block')), findsNothing);

        await tester.tap(find.byKey(const ValueKey('squad-member-checkin')));
        await tester.pumpAndSettle();
        expect(h.location, '/capture?journeyId=g1');

        await h.go(tester, '/groups');
        h.groups.setToday('g1', [
          memberToday(
            me,
            'Linh',
            today: testCheckIn('g1', testToday, userId: me),
          ),
        ]);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('squad-member-u1')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Checked in at '), findsOneWidget);
        expect(find.text('Add a photo'), findsOneWidget);
      },
    );

    testWidgets(
      'other member sheet shows checked/not-yet status, streak, report and block',
      (tester) async {
        final calls = <String>[];
        await pumpGroups(
          tester,
          journeys: FakeJourneyRepository(journeys: [groupJourney()]),
          groups: FakeGroupRepository(
            today: {
              'g1': [
                memberToday(me, 'Linh'),
                memberToday(
                  'u2',
                  'An',
                  today: testCheckIn('g1', testToday, userId: 'u2'),
                  streak: 5,
                ),
                memberToday('u3', 'Binh', streak: 0),
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

        // Checked-in other member with streak > 0.
        await tester.tap(find.byKey(const ValueKey('squad-member-u2')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('squad-member-status')),
          findsOneWidget,
        );
        expect(find.textContaining('Checked in at '), findsOneWidget);
        expect(
          find.byKey(const ValueKey('squad-member-streak')),
          findsOneWidget,
        );
        expect(find.text('5-day streak'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('squad-member-report')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('squad-member-block')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('squad-member-checkin')),
          findsNothing,
        );
        await tester.tap(find.byKey(const ValueKey('squad-member-report')));
        await tester.pumpAndSettle();
        expect(calls, ['report:u2']);

        // Not-yet checked-in other member with streak == 0.
        await tester.tap(find.byKey(const ValueKey('squad-member-u3')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('squad-member-status')),
          findsOneWidget,
        );
        expect(find.text('Not checked in yet today'), findsOneWidget);
        expect(find.byKey(const ValueKey('squad-member-streak')), findsNothing);
        expect(
          find.byKey(const ValueKey('squad-member-report')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('squad-member-block')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Vietnamese report label in member sheet stays on a single line',
      (tester) async {
        await pumpGroups(
          tester,
          locale: const Locale('vi'),
          journeys: FakeJourneyRepository(journeys: [groupJourney()]),
          groups: FakeGroupRepository(
            today: {
              'g1': [memberToday(me, 'Linh'), memberToday('u2', 'An')],
            },
          ),
          hooks: GroupSafetyHooks(
            onReport: (
              context, {
              required userId,
              required displayName,
              checkInId,
            }) async {},
            onBlock: (
              context, {
              required userId,
              required displayName,
            }) async {},
          ),
        );

        await tester.tap(find.byKey(const ValueKey('squad-member-u2')));
        await tester.pumpAndSettle();
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.byKey(const ValueKey('squad-member-report')),
            matching: find.byType(RichText),
          ),
        );
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
          maxLines: paragraph.maxLines,
        )..layout(maxWidth: paragraph.constraints.maxWidth);
        addTearDown(painter.dispose);
        expect(painter.computeLineMetrics().length, 1);
      },
    );

    testWidgets(
      'ended group moves under Finished, no check-in action (C-B13)',
      (tester) async {
        await pumpGroups(
          tester,
          journeys: FakeJourneyRepository(
            journeys: [groupJourney(status: JourneyStatus.ended)],
          ),
          groups: FakeGroupRepository(
            today: {
              'g1': [memberToday(me, 'Linh'), memberToday('u2', 'An')],
            },
          ),
        );
        expect(
          find.byKey(const ValueKey('squad-finished-heading')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('squad-member-u1')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('squad-member-sheet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('squad-member-checkin')),
          findsNothing,
        );
      },
    );

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

    testWidgets('pending invites from a blocked inviter are hidden (C-B3)', (
      tester,
    ) async {
      final h = await pumpGroups(
        tester,
        journeys: FakeJourneyRepository(journeys: [groupJourney()]),
        invites: FakeGroupInviteRepository(
          invitations: [groupInvitation('i1')],
        ),
      );
      expect(find.byKey(const ValueKey('squad-invite-i1')), findsOneWidget);
      await h.safety.block('ha');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('squad-invite-i1')), findsNothing);
      expect(find.byKey(const ValueKey('squad-pending-invites')), findsNothing);
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
