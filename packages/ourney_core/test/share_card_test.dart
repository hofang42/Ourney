import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

Journey journey({
  int? duration = 30,
  TemplateId template = TemplateId.englishDaily,
  bool hide = false,
  String title = 'Học tiếng Anh',
}) =>
    Journey(
      id: 'j1',
      ownerId: 'u1',
      kind: JourneyKind.solo,
      templateId: template,
      title: title,
      emoji: '📚',
      startDate: LocalDate(2026, 10, 1),
      durationDays: duration,
      timezone: 'Asia/Ho_Chi_Minh',
      visibility: JourneyVisibility.private,
      status: JourneyStatus.active,
      hideMetricDefault: hide,
    );

StreakSummary streak({int current = 0, int best = 0, int completed = 0, int dayIndex = 1}) =>
    StreakSummary(
      current: current,
      best: best,
      completed: completed,
      checkedInToday: true,
      atRisk: false,
      progress: 0,
      dayIndex: dayIndex,
    );

void main() {
  group('milestoneFor', () {
    test('none for ordinary streak', () {
      expect(milestoneFor(streak(current: 5, completed: 5), journey()), isNull);
    });
    test('7-day streak', () {
      expect(milestoneFor(streak(current: 7, completed: 7), journey()), Milestone.sevenDays);
    });
    test('30-day streak on open-ended journey', () {
      expect(milestoneFor(streak(current: 30, completed: 30), journey(duration: null)),
          Milestone.thirtyDays);
    });
    test('completion beats streak milestones', () {
      expect(milestoneFor(streak(current: 30, completed: 30), journey(duration: 30)),
          Milestone.completed);
    });
    test('completion with a 7-day journey', () {
      expect(milestoneFor(streak(current: 7, completed: 7), journey(duration: 7)), Milestone.completed);
    });
    test('completion even when streak was broken', () {
      expect(milestoneFor(streak(current: 0, best: 20, completed: 30), journey(duration: 30)),
          Milestone.completed);
    });
    test('day 8 of a streak is not a milestone', () {
      expect(milestoneFor(streak(current: 8, completed: 8), journey()), isNull);
    });
  });

  group('buildShareCard', () {
    test('headline is current streak when running', () {
      final c = buildShareCard(journey(), streak(current: 5, completed: 9, dayIndex: 10));
      expect(c.headlineNumber, 5);
      expect(c.subtitle, '5 ngày liên tiếp');
      expect(c.milestone, isNull);
    });
    test('falls back to completed days when streak is zero', () {
      final c = buildShareCard(journey(), streak(current: 0, completed: 9, dayIndex: 12));
      expect(c.headlineNumber, 9);
      expect(c.subtitle, '9 ngày đã check-in');
    });
    test('completion subtitle', () {
      final c = buildShareCard(journey(duration: 30), streak(current: 30, completed: 30, dayIndex: 30));
      expect(c.milestone, Milestone.completed);
      expect(c.headlineNumber, 30);
      expect(c.subtitle, 'Hoàn thành 30/30 ngày');
    });
    test('carries title, emoji, displayName', () {
      final c = buildShareCard(journey(), streak(current: 1, completed: 1), displayName: 'Hoàng');
      expect(c.title, 'Học tiếng Anh');
      expect(c.emoji, '📚');
      expect(c.displayName, 'Hoàng');
    });
    test('weight loss journeys ask for photo blur', () {
      final c = buildShareCard(journey(template: TemplateId.weightLoss, hide: true), streak(current: 1));
      expect(c.blurPhoto, isTrue);
    });
    test('other journeys do not blur', () {
      expect(buildShareCard(journey(), streak(current: 1)).blurPhoto, isFalse);
    });
  });
}
