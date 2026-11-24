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
      expect(parseInviteInput('ourney://j/xy12ab34'), 'XY12AB34');
      expect(parseInviteInput('https://ourney.tech/j/xy12ab34'), 'XY12AB34');
      expect(parseInviteInput('https://ourney.tech/join/xy12-ab34'), 'XY12AB34');
      expect(parseInviteInput('HTTPS://OURNEY.TECH/J/xy12ab34'), 'XY12AB34');
      expect(parseInviteInput('ourney.tech/j/abcd1234'), 'ABCD1234');
      expect(parseInviteInput('ourney.tech/join/abcd-1234'), 'ABCD1234');
      expect(
        parseInviteInput('Join our squad: https://ourney.tech/j/abcd1234!'),
        'ABCD1234',
      );
      expect(
        parseInviteInput('Join our squad: ourney.tech/j/abcd1234!'),
        'ABCD1234',
      );
      expect(parseInviteInput('https://evil.com/j/xy12ab34'), isEmpty);
      expect(parseInviteInput('https://notourney.tech/j/xy12ab34'), isEmpty);
      expect(parseInviteInput('https://evil.ourney.tech/j/xy12ab34'), isEmpty);
      expect(parseInviteInput('evil.com/j/xy12ab34'), isEmpty);
      expect(
        parseInviteInput('Join us https://evil.com/j/xy12ab34'),
        isEmpty,
      );
      expect(
        parseInviteInput('Be my friend on Ourney: https://ourney.tech/f/tok123'),
        isEmpty,
      );
      expect(
        parseInviteInput('Check out https://ourney.tech/p/pubtok123'),
        isEmpty,
      );
      expect(isValidInviteCode('ABCD1234'), isTrue);
      expect(isValidInviteCode('ABCD123'), isFalse);
      expect(isValidInviteCode('ABCD123!'), isFalse);
    });

    test('share link uses https://ourney.tech/j/<code> (DE-03)', () {
      expect(inviteLink('ABCD1234'), 'https://ourney.tech/j/ABCD1234');
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

    CheckIn shot(String id, int hourUtc, {String? caption}) => CheckIn(
      id: id,
      journeyId: 'g1',
      userId: 'u2',
      localDate: testToday,
      capturedAt: DateTime.utc(
        testToday.year,
        testToday.month,
        testToday.day,
        hourUtc,
      ),
      photoPath: 'p/$id.jpg',
      thumbPath: 't/$id.jpg',
      caption: caption,
      uploaded: true,
    );

    GroupMemberEntry entryFor(
      CheckIn? server,
      List<CheckIn> local, {
      Set<String> hidden = const {},
    }) => GroupTodayView.build(
      journey: groupJourney(),
      members: [memberToday('u2', 'An', today: server)],
      now: testNow,
      myUserId: me,
      hiddenCheckInIds: hidden,
      checkIns: local,
    ).done.single;

    test('same check-in: the full local row beats the trimmed server one '
        '(C-B9)', () {
      final e = entryFor(shot('c-first', 1), [
        shot('c-first', 1, caption: 'morning run'),
      ]);
      expect(e.photo!.id, 'c-first');
      expect(e.photo!.caption, 'morning run');
      expect(e.photoIsToday, isTrue);
    });

    test('a newer local photo of today wins over the server one (C-B9)', () {
      final e = entryFor(shot('c-first', 1), [
        shot('c-first', 1),
        shot('c-second', 3),
      ]);
      expect(e.photo!.id, 'c-second');
    });

    test('a newer server photo still wins over an older local one', () {
      final e = entryFor(shot('c-second', 3), [shot('c-first', 1)]);
      expect(e.photo!.id, 'c-second');
    });

    test("hidden today's photo: done today, old photo is not today's "
        '(C-B10)', () {
      final yesterday = CheckIn(
        id: 'c-yesterday',
        journeyId: 'g1',
        userId: 'u2',
        localDate: testToday.addDays(-1),
        capturedAt: DateTime.utc(2026, 1, 1),
        photoPath: 'p/y.jpg',
        thumbPath: 't/y.jpg',
        uploaded: true,
      );
      final e = entryFor(
        shot('c-today', 1),
        [yesterday, shot('c-today', 1)],
        hidden: {'c-today'},
      );
      expect(e.checkedInToday, isTrue);
      expect(e.photo!.id, 'c-yesterday');
      expect(e.photoIsToday, isFalse);
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
