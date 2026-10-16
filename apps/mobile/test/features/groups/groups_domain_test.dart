import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/groups/domain/group_today.dart';
import 'package:ourney/features/groups/domain/invite_code.dart';
import 'package:ourney_core/ourney_core.dart';

import 'groups_fakes.dart';

void main() {
  group('invite codes', () {
    test('normalises typed and pasted codes', () {
      expect(parseInviteInput(' abcd-1234 '), 'ABCD1234');
      expect(parseInviteInput('ourney://join/xy12ab34'), 'XY12AB34');
      expect(isValidInviteCode('ABCD1234'), isTrue);
      expect(isValidInviteCode('ABCD123'), isFalse);
      expect(isValidInviteCode('ABCD123!'), isFalse);
    });

    test('share link', () {
      expect(inviteLink('ABCD1234'), 'ourney://join/ABCD1234');
    });
  });

  group('GroupTodayView', () {
    test('late joiner: own streak counts from the join date', () {
      final j = groupJourney();
      // Joined on the 15th (local), check-ins before that are ignored.
      final membership = groupMembership(
        j,
        joinedAt: DateTime.utc(2026, 10, 14, 18),
      );
      final view = GroupTodayView.build(
        journey: j,
        members: [memberToday(me, 'Me')],
        now: testNow,
        myUserId: me,
        myMembership: membership,
        checkIns: [
          testCheckIn('g1', const LocalDate(2026, 10, 13)),
          testCheckIn('g1', const LocalDate(2026, 10, 14)),
          testCheckIn('g1', const LocalDate(2026, 10, 15)),
          testCheckIn('g1', testToday),
        ],
      );
      final e = view.done.single;
      expect(e.checkedInToday, isTrue);
      expect(e.streak, 2);
      expect(e.photo!.localDate, testToday);
    });

    test('reaction summary ignores blocked users and unknown emojis', () {
      final s = ReactionSummary.of(
        [
          Reaction(checkInId: 'c', userId: me, emoji: '🔥', createdAt: testNow),
          Reaction(
            checkInId: 'c',
            userId: 'b',
            emoji: '🔥',
            createdAt: testNow,
          ),
          Reaction(
            checkInId: 'c',
            userId: 'x',
            emoji: '👍',
            createdAt: testNow,
          ),
        ],
        myUserId: me,
        blockedIds: {'b'},
      );
      expect(s.counts['🔥'], 1);
      expect(s.mine, '🔥');
      expect(s.total, 1);
    });
  });
}
