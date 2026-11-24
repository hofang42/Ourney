import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

void main() {
  localStatsTests();
  group('OnboardingQuiz', () {
    test('json round trip and tolerance', () {
      const q = OnboardingQuiz(
        goal: QuizGoal.workout,
        company: QuizCompany.group,
        reminder: '21:30',
      );
      expect(OnboardingQuiz.fromJson(q.toJson()), q);
      expect(
        OnboardingQuiz.fromJson({'goal': 'nope', 'reminder': '25:00'})!.isEmpty,
        isTrue,
      );
      expect(OnboardingQuiz.fromJson('x'), isNull);
    });

    test('suggestion maps goal to template and skin', () {
      final s = const OnboardingQuiz(
        goal: QuizGoal.english,
        company: QuizCompany.solo,
        reminder: '07:00',
      ).suggestion!;
      expect(s.templateId, TemplateId.englishDaily);
      expect(s.skin, PersonaSkinId.accountabilitySquad);
      expect(s.kind, JourneyKind.solo);
      expect(s.reminder, '07:00');
      expect(const OnboardingQuiz().suggestion, isNull);
    });

    test('couple answer selects the couple ritual', () {
      final s = const OnboardingQuiz(
        goal: QuizGoal.workout,
        company: QuizCompany.couple,
      ).suggestion!;
      expect(s.coupleRitual, isTrue);
      expect(s.skin, PersonaSkinId.coupleRituals);
      expect(s.kind, JourneyKind.group);
    });
  });

  group('stats and badges', () {
    test('fromJson accepts list or object', () {
      final a = ProfileStats.fromJson([
        {
          'total_snaps': 148,
          'longest_streak': 41,
          'current_streak': 3,
          'journeys_completed': 3,
          'journeys_total': 5,
        },
      ]);
      expect(a.totalSnaps, 148);
      expect(ProfileStats.fromJson({'total_snaps': 2}).totalSnaps, 2);
      expect(ProfileStats.fromJson(null).totalSnaps, 0);
    });

    test('badges unlock at thresholds', () {
      final b = badgesFor(
        const ProfileStats(totalSnaps: 99, longestStreak: 7),
      );
      expect([for (final x in b) x.unlocked], [true, false, false, false]);
      final all = badgesFor(
        const ProfileStats(
          totalSnaps: 100,
          longestStreak: 30,
          journeysCompleted: 1,
        ),
      );
      expect(all.every((x) => x.unlocked), isTrue);
    });
  });
}

void localStatsTests() {
  test('computeLocalProfileStats sums snaps and picks best streaks', () {
    final start = LocalDate(2026, 1, 1);
    final journey = Journey(
      id: 'j1',
      ownerId: 'u',
      kind: JourneyKind.solo,
      templateId: TemplateId.custom,
      title: 't',
      emoji: 'x',
      startDate: start,
      timezone: 'UTC',
      visibility: JourneyVisibility.private,
      status: JourneyStatus.ended,
      durationDays: 30,
    );
    CheckIn c(int day) => CheckIn(
          id: 'c$day',
          journeyId: 'j1',
          userId: 'u',
          localDate: start.addDays(day),
          capturedAt: DateTime.utc(2026, 1, 1 + day),
          photoPath: 'p',
          thumbPath: 't',
        );
    final stats = computeLocalProfileStats(
      journeys: [journey],
      checkInsByJourney: {
        'j1': [c(0), c(1), c(2), c(5)]
      },
      today: (_) => start.addDays(10),
    );
    expect(stats.totalSnaps, 4);
    expect(stats.longestStreak, 3);
    expect(stats.currentStreak, 0, reason: 'ended journey has 0 live streak');
    expect(stats.journeysCompleted, 1);
    expect(stats.journeysTotal, 1);
  });

  test(
      'computeLocalProfileStats excludes imported journeys from streaks (S12 / FS-25) '
      'and counts archived or elapsed journeys as completed', () {
    final start = LocalDate(2026, 1, 1);
    final imported = Journey(
      id: 'imp',
      ownerId: 'u',
      kind: JourneyKind.solo,
      templateId: TemplateId.travel,
      title: 'Trip',
      emoji: '✈️',
      startDate: start,
      timezone: 'UTC',
      visibility: JourneyVisibility.private,
      status: JourneyStatus.ended,
      origin: JourneyOrigin.imported,
      durationDays: 10,
    );
    final elapsedActive = Journey(
      id: 'elapsed',
      ownerId: 'u',
      kind: JourneyKind.solo,
      templateId: TemplateId.custom,
      title: 'Elapsed',
      emoji: '🔥',
      startDate: start,
      timezone: 'UTC',
      visibility: JourneyVisibility.private,
      status: JourneyStatus.active,
      durationDays: 7,
    );
    final liveActive = Journey(
      id: 'live',
      ownerId: 'u',
      kind: JourneyKind.solo,
      templateId: TemplateId.custom,
      title: 'Live',
      emoji: '🔥',
      startDate: start.addDays(8),
      timezone: 'UTC',
      visibility: JourneyVisibility.private,
      status: JourneyStatus.active,
      durationDays: 30,
    );
    CheckIn c(String jid, int day) => CheckIn(
          id: '$jid-$day',
          journeyId: jid,
          userId: 'u',
          localDate: start.addDays(day),
          capturedAt: DateTime.utc(2026, 1, 1 + day),
          photoPath: 'p',
          thumbPath: 't',
        );
    final stats = computeLocalProfileStats(
      journeys: [imported, elapsedActive, liveActive],
      checkInsByJourney: {
        'imp': [for (var i = 0; i < 10; i++) c('imp', i)],
        'elapsed': [c('elapsed', 0), c('elapsed', 1), c('elapsed', 2)],
        'live': [c('live', 9), c('live', 10)],
      },
      today: (_) => start.addDays(10),
    );
    expect(stats.totalSnaps, 15);
    expect(stats.longestStreak, 3, reason: 'imported 10-day run ignored (S12)');
    expect(stats.currentStreak, 2, reason: 'only active unelapsed journey');
    expect(stats.journeysCompleted, 2, reason: 'ended + elapsed active');
    expect(stats.journeysTotal, 3);
  });

  test('computeLocalProfileStats counts streaks from the join date', () {
    final start = LocalDate(2026, 1, 1);
    final journey = Journey(
      id: 'j1',
      ownerId: 'o',
      kind: JourneyKind.group,
      templateId: TemplateId.custom,
      title: 't',
      emoji: 'x',
      startDate: start,
      timezone: 'UTC',
      visibility: JourneyVisibility.group,
      status: JourneyStatus.active,
      durationDays: 30,
    );
    CheckIn c(int day) => CheckIn(
          id: 'c$day',
          journeyId: 'j1',
          userId: 'u',
          localDate: start.addDays(day),
          capturedAt: DateTime.utc(2026, 1, 1 + day),
          photoPath: 'p',
          thumbPath: 't',
        );
    final stats = computeLocalProfileStats(
      journeys: [journey],
      // Days 0-2 predate the join (day 5) and must not count.
      checkInsByJourney: {
        'j1': [c(0), c(1), c(2), c(5), c(6)]
      },
      joinedLocalDateByJourney: {'j1': start.addDays(5)},
      today: (_) => start.addDays(6),
    );
    expect(stats.longestStreak, 2);
    expect(stats.currentStreak, 2);
  });
}
