import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/group_daily_checkins_provider.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/domain/wrapped_story.dart';
import 'package:ourney_core/ourney_core.dart';

const _first = LocalDate(2026, 11, 25);
const _second = LocalDate(2026, 11, 26);
const _third = LocalDate(2026, 11, 27);
const _journey = Journey(
  id: 'couple',
  ownerId: 'zoe',
  kind: JourneyKind.group,
  maxMembers: 2,
  templateId: TemplateId.custom,
  title: 'Daily',
  emoji: '',
  startDate: _first,
  timezone: 'Asia/Bangkok',
  visibility: JourneyVisibility.group,
  status: JourneyStatus.active,
  layout: PersonaSkinId.minimalistHabit,
);
const _zoe = MemberToday(
  userId: 'zoe',
  displayName: 'Zoe',
  role: MemberRole.owner,
);
const _an = MemberToday(
  userId: 'an',
  displayName: 'An',
  role: MemberRole.member,
);

CheckIn _photo(String id, String author, LocalDate date, DateTime capturedAt) =>
    CheckIn(
      id: id,
      journeyId: _journey.id,
      userId: author,
      localDate: date,
      capturedAt: capturedAt,
      photoPath: '$id.jpg',
      thumbPath: '${id}_t.jpg',
      partnerPhotoPath: author == 'zoe' ? '${id}_p.jpg' : null,
      uploaded: true,
    );

void main() {
  final beforeMidnight = DateTime.utc(2026, 11, 25, 16, 59);
  final afterMidnight = DateTime.utc(2026, 11, 25, 17);
  final zoeFirst = _photo('before', 'zoe', _first, beforeMidnight);
  final zoeToday = _photo('after', 'zoe', _second, afterMidnight);
  final anOlder = _photo('older', 'an', _second, afterMidnight);
  final anTieLow = _photo(
    'a',
    'an',
    _second,
    afterMidnight.add(const Duration(hours: 1)),
  );
  final anTieHigh = _photo('b', 'an', _second, anTieLow.capturedAt);
  final anThird = _photo('next', 'an', _third, DateTime.utc(2026, 11, 26, 17));
  final stranger = _photo('other', 'stranger', _third, anThird.capturedAt);

  GroupDailySnapshot snapshot({
    String me = 'zoe',
    List<MemberToday> members = const [_zoe, _an],
    LocalDate? today,
    Set<String> blocked = const {},
  }) => GroupDailySnapshot.build(
    journey: _journey,
    allCheckIns: [
      anTieLow,
      zoeFirst,
      anTieHigh,
      zoeToday,
      anThird,
      anOlder,
      stranger,
    ],
    members: members,
    myUserId: me,
    blockedIds: blocked,
    today: today,
  );

  test('join order holds for both viewers and the open slot', () {
    final beforeAccept = snapshot(members: [_zoe]);
    expect(beforeAccept.canInvitePartner, isTrue);
    expect(beforeAccept.memberIds, ['zoe', null]);
    expect(beforeAccept.slotsOn(_second).map((s) => s.checkIn), [
      zoeToday,
      null,
    ]);
    final first = snapshot();
    final second = snapshot(me: 'an');
    expect(first.memberIds, ['zoe', 'an']);
    expect(second.memberIds, first.memberIds);
    expect(second.slotsOn(_second).map((s) => s.isMine), [false, true]);
  });

  test('journey-day boundary, latest capture and ID tiebreak select authored slots', () {
    final couple = snapshot();
    expect(couple.slotsOn(_first).map((s) => s.checkIn), [zoeFirst, null]);
    expect(couple.slotsOn(_second).map((s) => s.checkIn), [
      zoeToday,
      anTieHigh,
    ]);
    expect(couple.slotsOn(_third).map((s) => s.checkIn), [null, anThird]);
    expect(
      couple.photosOn(_second),
      unorderedEquals([zoeToday, anOlder, anTieLow, anTieHigh]),
    );
    expect(couple.latestPartnerCheckIn, anThird);
  });

  test(
    'blocked or hidden partners cannot contribute a photo or PiP thumbnail',
    () {
      final hidden = snapshot(
        today: _second,
        members: [
          _zoe,
          const MemberToday(
            userId: 'an',
            displayName: 'An',
            role: MemberRole.member,
            checkedInHidden: true,
          ),
        ],
      );
      expect(hidden.partnerPostedOn(_second), isTrue);
      expect(hidden.slotsOn(_second).last.photoUnavailable, isTrue);
      expect(hidden.slotsOn(_second).last.checkIn, isNull);
      expect(hidden.photosOn(_second), [zoeToday]);
      final blocked = snapshot(blocked: {'an'});
      expect(blocked.latestPartnerCheckIn, isNull);
      expect(blocked.slotsOn(_second).last.checkIn, isNull);
      expect(blocked.canInvitePartner, isFalse);
    },
  );

  test('partner-only day opens in the timeline and Wrapped without changing my streak', () {
    JourneyProgress progress({
      GroupDailySnapshot couple = GroupDailySnapshot.empty,
    }) => JourneyProgress.compute(
      journey: _journey,
      membership: null,
      checkIns: [zoeFirst, zoeToday],
      now: DateTime.utc(2026, 11, 27, 5),
      couple: couple,
    );
    final paired = progress(couple: snapshot());
    expect(paired.summary.current, progress().summary.current);
    expect(paired.summary.best, progress().summary.best);
    expect(paired.checkedInToday, isFalse);
    expect(paired.dayAt(_third).viewerPhoto, anThird);
    expect(paired.dayAt(_third).canOpen, isTrue);
    expect(WrappedStats.from(paired).coupleSlots.map((s) => s.checkIn), [
      null,
      anThird,
    ]);
  });

  test(
    'F-12: partner todayCheckIn from group_today RPC renders before local cache pulls it',
    () {
      final rpcOnly = GroupDailySnapshot.build(
        journey: _journey,
        allCheckIns: [zoeToday],
        members: [
          _zoe,
          MemberToday(
            userId: 'an',
            displayName: 'An',
            role: MemberRole.member,
            todayCheckIn: anTieHigh,
          ),
        ],
        myUserId: 'zoe',
        today: _second,
      );
      expect(rpcOnly.slotsOn(_second).map((s) => s.checkIn), [
        zoeToday,
        anTieHigh,
      ]);
      expect(rpcOnly.slotsOn(_second).last.photoUnavailable, isFalse);
      expect(rpcOnly.latestPartnerCheckIn, anTieHigh);

      // When partner posts a 2nd photo today and RPC refreshes before SQLite
      // pulls the 2nd row, the new RPC photo fills the slot and the older
      // cached photo remains in photosOn(today).
      final secondPostToday = GroupDailySnapshot.build(
        journey: _journey,
        allCheckIns: [zoeToday, anOlder],
        members: [
          _zoe,
          MemberToday(
            userId: 'an',
            displayName: 'An',
            role: MemberRole.member,
            todayCheckIn: anTieHigh,
          ),
        ],
        myUserId: 'zoe',
        today: _second,
      );
      expect(secondPostToday.slotsOn(_second).map((s) => s.checkIn), [
        zoeToday,
        anTieHigh,
      ]);
      expect(secondPostToday.slotsOn(_second).last.photoUnavailable, isFalse);
      expect(
        secondPostToday.photosOn(_second),
        unorderedEquals([zoeToday, anOlder, anTieHigh]),
      );
    },
  );

  test(
    'F-13: offline snapshot derives partner from cachedMembers and keeps cached partner photos visible',
    () {
      final offline = GroupDailySnapshot.build(
        journey: _journey,
        allCheckIns: [zoeFirst, zoeToday, anOlder, anTieHigh, anThird],
        members: const [],
        cachedMembers: const [_zoe, _an],
        hasLoadedMembers: false,
        myUserId: 'zoe',
        today: _second,
      );
      expect(offline.memberIds, ['zoe', 'an']);
      expect(offline.partnerId, 'an');
      expect(offline.slotsOn(_first).map((s) => s.checkIn), [zoeFirst, null]);
      expect(offline.slotsOn(_second).map((s) => s.checkIn), [
        zoeToday,
        anTieHigh,
      ]);
      expect(offline.latestPartnerCheckIn, anThird);
    },
  );

  test(
    'F-36: canInvitePartner ignores unrelated global blocks but hides when partner is blocked or reverse-blocked',
    () {
      final withUnrelatedBlock = snapshot(
        members: const [_zoe],
        blocked: const {'stranger-1', 'stranger-2'},
      );
      expect(withUnrelatedBlock.canInvitePartner, isTrue);

      final withBlockedPartner = GroupDailySnapshot.build(
        journey: _journey,
        allCheckIns: const [],
        members: const [_zoe],
        cachedMembers: const [_zoe, _an],
        myUserId: 'zoe',
        blockedIds: const {'an'},
      );
      expect(withBlockedPartner.canInvitePartner, isFalse);

      // Non-owner caller seeing only themselves because owner reverse-blocked them.
      final reverseBlocked = GroupDailySnapshot.build(
        journey: _journey,
        allCheckIns: const [],
        members: const [_an],
        myUserId: 'an',
      );
      expect(reverseBlocked.canInvitePartner, isFalse);
    },
  );
}
