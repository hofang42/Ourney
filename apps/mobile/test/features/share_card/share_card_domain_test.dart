import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/share_card/data/share_card_exporter.dart';
import 'package:ourney/features/share_card/domain/share_card_content.dart';
import 'package:ourney_core/ourney_core.dart';

import 'share_card_fakes.dart';

StreakSummary _streak({
  int current = 0,
  int completed = 0,
  int dayIndex = 1,
}) => StreakSummary(
  current: current,
  best: current,
  completed: completed,
  checkedInToday: false,
  atRisk: current > 0,
  progress: 0,
  dayIndex: dayIndex,
);

ShareCardContent _content(
  Journey j, {
  Membership? membership,
  StreakSummary? streak,
  int dayNumber = 7,
  List<CheckIn> checkIns = const [],
  ShareCardNumber number = ShareCardNumber.streak,
}) => ShareCardContent.from(
  journey: j,
  membership: membership,
  streak: streak ?? _streak(current: 6, completed: 6),
  dayNumber: dayNumber,
  checkIns: checkIns,
  number: number,
);

void main() {
  group('ShareCardFormat (FR-E1)', () {
    test('story is 1080x1920 at x3 with the IG safe zones', () {
      const f = ShareCardFormat.story;
      expect((f.pixelWidth, f.pixelHeight), (1080, 1920));
      expect(f.pixelRatio, 3);
      expect(f.logicalSize, const Size(360, 640));
      expect(f.contentPadding.top * 3, greaterThanOrEqualTo(250));
      expect(f.contentPadding.bottom * 3, greaterThanOrEqualTo(340));
    });

    test('feed is 1080x1350 at x3', () {
      const f = ShareCardFormat.feed;
      expect((f.pixelWidth, f.pixelHeight), (1080, 1350));
      expect(f.logicalSize, const Size(360, 450));
      expect(f.logicalSize * f.pixelRatio, const Size(1080, 1350));
    });

    test('file names only keep safe characters', () {
      expect(
        shareCardBaseName('a/../b c', ShareCardFormat.feed),
        'ourney-abc-feed',
      );
      expect(shareCardBaseName('', ShareCardFormat.story), 'ourney-journey-story');
    });
  });

  group('ShareCardContent', () {
    test('live streak -> streak number', () {
      final c = _content(testJourney());
      expect(c.headline, ShareCardHeadline.streak);
      expect(c.number, 6);
      expect(c.title, 'Tập mỗi ngày');
      expect(c.emoji, '💪');
    });

    test('no live streak -> checked-in days', () {
      final c = _content(
        testJourney(),
        streak: _streak(completed: 4),
      );
      expect(c.headline, ShareCardHeadline.checkedIn);
      expect(c.number, 4);
    });

    test('completed journey wins (milestone)', () {
      final c = _content(
        testJourney(durationDays: 7),
        streak: _streak(current: 7, completed: 7),
      );
      expect(c.headline, ShareCardHeadline.finished);
      expect(c.number, 7);
      expect(c.totalDays, 7);
      expect(c.milestone, Milestone.completed);
    });

    test('7-day milestone on the exact day', () {
      final c = _content(testJourney(), streak: _streak(current: 7));
      expect(c.milestone, Milestone.sevenDays);
    });

    test('day N mode', () {
      final c = _content(testJourney(), number: ShareCardNumber.day);
      expect(c.headline, ShareCardHeadline.day);
      expect(c.number, 7);
    });
  });

  group('privacy (FR-B7)', () {
    test('weight loss: no metric value and photo blurred', () {
      final j = weightLossJourney();
      final c = _content(
        j,
        membership: testMembership(j),
        checkIns: [testCheckIn(j.id, const LocalDate(2026, 10, 15), metricValue: 71.5)],
      );
      expect(c.metricHidden, isTrue);
      expect(c.metricValue, isNull);
      expect(c.metricUnit, isNull);
      expect(c.blurPhoto, isTrue);
    });

    test('weight loss template hides kg even without hideMetricDefault', () {
      final j = testJourney(
        templateId: TemplateId.weightLoss,
        metricName: 'Cân nặng',
        metricUnit: 'kg',
      );
      expect(metricHiddenFor(j, testMembership(j)), isTrue);
    });

    test('other metric journeys show the latest value unless hidden', () {
      final j = testJourney(metricName: 'Phút', metricUnit: 'phút');
      final checkIns = [
        testCheckIn(j.id, const LocalDate(2026, 10, 14), metricValue: 20),
        testCheckIn(j.id, const LocalDate(2026, 10, 15), metricValue: 25),
      ];
      final shown = _content(j, membership: testMembership(j), checkIns: checkIns);
      expect(shown.metricValue, 25);
      expect(shown.metricUnit, 'phút');
      expect(shown.metricHidden, isFalse);

      final hidden = _content(
        j,
        membership: testMembership(j, hideMetric: true),
        checkIns: checkIns,
      );
      expect(hidden.metricValue, isNull);
      expect(hidden.metricHidden, isTrue);
    });

    test('membership blurMedia blurs any journey', () {
      final j = testJourney();
      expect(_content(j, membership: testMembership(j)).blurPhoto, isFalse);
      expect(
        _content(j, membership: testMembership(j, blurMedia: true)).blurPhoto,
        isTrue,
      );
    });
  });

  group('public link eligibility (FR-E3)', () {
    test('solo owner with a backend', () {
      final j = testJourney();
      expect(
        canHavePublicLink(
          journey: j,
          membership: testMembership(j),
          currentUserId: 'u1',
          hasBackend: true,
        ),
        isTrue,
      );
    });

    test('never for group journeys, local-only, archived or non-owners', () {
      final group = testJourney(kind: JourneyKind.group);
      expect(
        canHavePublicLink(
          journey: group,
          membership: testMembership(group),
          currentUserId: 'u1',
          hasBackend: true,
        ),
        isFalse,
      );
      final solo = testJourney();
      expect(
        canHavePublicLink(
          journey: solo,
          membership: testMembership(solo),
          currentUserId: null,
          hasBackend: false,
        ),
        isFalse,
      );
      final archived = testJourney(status: JourneyStatus.archived);
      expect(
        canHavePublicLink(
          journey: archived,
          membership: testMembership(archived),
          currentUserId: 'u1',
          hasBackend: true,
        ),
        isFalse,
      );
      expect(
        canHavePublicLink(
          journey: solo,
          membership: testMembership(solo, userId: 'u2'),
          currentUserId: 'u2',
          hasBackend: true,
        ),
        isFalse,
      );
    });

    test('active token only for a valid solo link token', () {
      expect(
        activePublicToken(
          testJourney(visibility: JourneyVisibility.link, publicToken: testToken),
        ),
        testToken,
      );
      expect(activePublicToken(testJourney()), isNull);
      expect(
        activePublicToken(
          testJourney(visibility: JourneyVisibility.link, publicToken: 'BAD'),
        ),
        isNull,
      );
    });
  });

  test('photo candidates: newest day first, one per day', () {
    final a = testCheckIn('j1', const LocalDate(2026, 10, 12));
    final b = testCheckIn('j1', const LocalDate(2026, 10, 15));
    final c = testCheckIn('j1', const LocalDate(2026, 10, 13));
    expect(photoCandidates([a, b, c]).map((x) => x.localDate.day), [15, 13, 12]);
  });
}
