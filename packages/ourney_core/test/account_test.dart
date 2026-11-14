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
    expect(stats.journeysCompleted, 1);
    expect(stats.journeysTotal, 1);
  });
}
