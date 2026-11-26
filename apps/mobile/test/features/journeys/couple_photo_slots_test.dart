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
}
