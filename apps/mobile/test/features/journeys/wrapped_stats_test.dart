import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/group_daily_checkins_provider.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/domain/wrapped_stats.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

WrappedStats statsFor(
  List<CheckIn> photos, {
  Journey? journey,
  Membership? membership,
  GroupDailySnapshot couple = GroupDailySnapshot.empty,
}) {
  final j =
      journey ?? testJourney(durationDays: 30, status: JourneyStatus.ended);
  return WrappedStats.from(
    JourneyProgress.compute(
      journey: j,
      membership: membership,
      checkIns: photos,
      now: DateTime.utc(2028),
      couple: couple,
    ),
  );
}

void main() {
  test('sampling is ordered, bounded, stable and keeps both endpoints', () {
    final j = testJourney(durationDays: 240, status: JourneyStatus.ended);
    final photos = [
      for (var i = 0; i < 240; i++) testCheckIn(j.id, j.startDate.addDays(i)),
    ];
    final s = statsFor(photos.reversed.toList(), journey: j);
    for (final sample in [s.sampleWall(), s.sampleRiffle()]) {
      expect(sample.first.id, photos.first.id);
      expect(sample.last.id, photos.last.id);
      expect(sample.map((p) => p.id).toSet(), hasLength(sample.length));
      for (var i = 1; i < sample.length; i++) {
        expect(sample[i].localDate.isAfter(sample[i - 1].localDate), isTrue);
      }
    }
    expect(s.sampleWall(), hasLength(30));
    expect(s.sampleRiffle(), hasLength(12));
    expect(s.sampleWall().map((p) => p.id), s.sampleWall().map((p) => p.id));
    expect(s.chainDays, hasLength(240));
  });

  test(
    'counts all moments, latest daily photos, busiest threshold and captions',
    () {
      final j = testJourney();
      final d = j.startDate;
      final photos = [
        testCheckIn(j.id, d, caption: 'First', hour: 1),
        testCheckIn(j.id, d, caption: 'Longest', hour: 2),
        testCheckIn(j.id, d, hour: 3),
        testCheckIn(j.id, d.addDays(1), caption: 'Latest!', hour: 2),
      ];
      final s = statsFor(photos, journey: j);
      expect(s.days, 2);
      expect(s.moments, 4);
      expect(s.photos.first.id, photos[2].id);
      expect(s.firstCaption?.value, 'First');
      expect(s.longestCaption?.value, 'Latest!');
      expect(s.noteCaption?.value, 'Latest!');
      expect(s.busiestDay, (date: d, photoCount: 3));
      expect(statsFor(photos.take(2).toList(), journey: j).busiestDay, isNull);
    },
  );

  test(
    'real extras sums, valid fastest pace, weighted average and ordered places',
    () {
      final j = testJourney();
      final d = j.startDate;
      final s = statsFor([
        testCheckIn(
          j.id,
          d,
          extras: const CheckInExtras(
            km: 2,
            pace: '5:00',
            minutes: 10,
            place: ' A ',
          ),
        ),
        testCheckIn(
          j.id,
          d.addDays(1),
          extras: const CheckInExtras(
            km: 8,
            pace: '6:00',
            minutes: 48,
            place: 'B',
          ),
        ),
        testCheckIn(
          j.id,
          d.addDays(2),
          extras: const CheckInExtras(pace: '1:99', place: 'A'),
        ),
        testCheckIn(
          j.id,
          d.addDays(3),
          extras: const CheckInExtras(pace: 'bad', minutes: -1, km: -2),
        ),
        testCheckIn(j.id, d.addDays(4)),
      ], journey: j);
      expect(s.totalKm, 10);
      expect(s.pace, '5:48');
      expect(s.fastestPace, (value: '5:00', date: d));
      expect(s.minutesTotal, 58);
      expect(s.minutesSessions, 2);
      expect(s.minutesLongest, (value: 48, date: d.addDays(1)));
      expect(s.placesInOrder, ['A', 'B']);
      expect(s.kmTextFor('vi'), '10');
    },
  );

  for (final (days, total, expected) in [
    (69, 100, false),
    (70, 100, true),
    (100, 100, true),
  ]) {
    test('ratio threshold $days/$total', () {
      final j = testJourney(durationDays: total, status: JourneyStatus.ended);
      final s = statsFor([
        for (var i = 0; i < days; i++)
          testCheckIn(j.id, j.startDate.addDays(i)),
      ], journey: j);
      expect(s.showRatio, expected);
    });
  }

  test('late joiner denominator and chain start at membership date', () {
    final j = testJourney(
      kind: JourneyKind.group,
      durationDays: 30,
      status: JourneyStatus.ended,
    );
    final member = Membership(
      journeyId: j.id,
      userId: 'u1',
      role: MemberRole.member,
      status: MemberStatus.active,
      joinedAt: DateTime.utc(2026, 10, 20),
    );
    final s = statsFor(
      [
        testCheckIn(j.id, j.startDate),
        testCheckIn(j.id, const LocalDate(2026, 10, 20)),
      ],
      journey: j,
      membership: member,
    );
    expect(s.memberTotal, 20);
    expect(s.days, 1);
    expect(s.chainDays.first, isTrue);
    expect(s.chainDays.skip(1).any((filled) => filled), isFalse);
  });

  test('couple pairs, cooking and five-heart dishes use both members', () {
    final j = testJourney(
      kind: JourneyKind.group,
      maxMembers: 2,
      status: JourneyStatus.ended,
    );
    final d = j.startDate;
    final own = [
      for (var i = 0; i < 3; i++)
        testCheckIn(
          j.id,
          d.addDays(i),
          extras: const CheckInExtras(cook: 'An', dish: 'Soup', hearts: 5),
        ),
    ];
    final partner = [
      for (var i = 0; i < 2; i++)
        testCheckIn(
          j.id,
          d.addDays(i),
          userId: 'u2',
          hour: 3,
          extras: const CheckInExtras(cook: 'Mai'),
        ),
    ];
    final couple = GroupDailySnapshot.build(
      journey: j,
      allCheckIns: [...own, ...partner],
      myUserId: 'u1',
      members: const [
        MemberToday(userId: 'u1', displayName: 'An', role: MemberRole.owner),
        MemberToday(userId: 'u2', displayName: 'Mai', role: MemberRole.member),
      ],
    );
    final s = statsFor(own, journey: j, couple: couple);
    expect(s.couplePairedDays, [d, d.addDays(1)]);
    expect(s.coupleCookSplit, (
      selfName: 'An',
      partnerName: 'Mai',
      self: 3,
      partner: 2,
    ));
    expect(s.coupleFiveHeartDishes, 3);
  });

  test('imported journeys have no streak', () {
    final base = testJourney();
    final j = Journey(
      id: base.id,
      ownerId: base.ownerId,
      kind: base.kind,
      templateId: base.templateId,
      title: base.title,
      emoji: base.emoji,
      startDate: base.startDate,
      durationDays: 7,
      timezone: testTz,
      visibility: JourneyVisibility.private,
      status: JourneyStatus.ended,
      origin: JourneyOrigin.imported,
    );
    expect(
      statsFor([
        for (var i = 0; i < 3; i++) testCheckIn(j.id, j.startDate.addDays(i)),
      ], journey: j).streak,
      isNull,
    );
  });
}
