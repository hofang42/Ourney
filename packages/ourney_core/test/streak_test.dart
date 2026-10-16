import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

LocalDate d(String s) => LocalDate.parse(s);

StreakSummary run({
  String start = '2026-10-01',
  int? duration = 30,
  String today = '2026-10-05',
  List<String> dates = const [],
}) =>
    computeStreak(
      start: d(start),
      durationDays: duration,
      today: d(today),
      dates: dates.map(d),
    );

void main() {
  group('checkedInToday / atRisk', () {
    test('checked in today is not at risk', () {
      final s = run(dates: ['2026-10-04', '2026-10-05']);
      expect(s.checkedInToday, isTrue);
      expect(s.atRisk, isFalse);
    });
    test('streak alive from yesterday but not today is at risk', () {
      final s = run(dates: ['2026-10-04']);
      expect(s.checkedInToday, isFalse);
      expect(s.atRisk, isTrue);
    });
    test('no streak means not at risk', () {
      final s = run(dates: ['2026-10-01']);
      expect(s.current, 0);
      expect(s.atRisk, isFalse);
    });
  });

  group('progress', () {
    test('completed / duration', () {
      final s = run(duration: 30, dates: ['2026-10-01', '2026-10-02', '2026-10-03']);
      expect(s.progress, closeTo(0.1, 1e-9));
    });
    test('open-ended journey yields 0.0', () {
      expect(run(duration: null, dates: ['2026-10-05']).progress, 0.0);
    });
    test('never exceeds 1.0', () {
      final s = run(duration: 2, dates: ['2026-10-01', '2026-10-02']);
      expect(s.progress, 1.0);
    });
  });

  group('dayIndex', () {
    test('first day is 1', () => expect(run(today: '2026-10-01').dayIndex, 1));
    test('fifth day', () => expect(run().dayIndex, 5));
    test('before start clamps to 1', () => expect(run(today: '2026-09-20').dayIndex, 1));
    test('after end clamps to duration', () {
      expect(run(duration: 3, today: '2026-11-20').dayIndex, 3);
    });
    test('open-ended is not clamped above', () {
      expect(run(duration: null, today: '2026-10-31').dayIndex, 31);
    });
  });

  group('edge cases', () {
    test('future dates are ignored', () {
      final s = run(dates: ['2026-10-05', '2026-10-06', '2026-10-07']);
      expect(s.current, 1);
      expect(s.best, 1);
      expect(s.completed, 1);
    });
    test('leap day Feb 29 bridges Feb 28 to Mar 1', () {
      final s = computeStreak(
        start: d('2028-02-27'),
        today: d('2028-03-01'),
        dates: [d('2028-02-28'), d('2028-02-29'), d('2028-03-01')],
      );
      expect(s.current, 3);
    });
    test('non leap year Feb 28 is followed by Mar 1', () {
      final s = computeStreak(
        start: d('2027-02-26'),
        today: d('2027-03-01'),
        dates: [d('2027-02-28'), d('2027-03-01')],
      );
      expect(s.current, 2);
    });
    test('year boundary', () {
      final s = computeStreak(
        start: d('2026-12-30'),
        today: d('2027-01-02'),
        dates: [d('2026-12-31'), d('2027-01-01'), d('2027-01-02')],
      );
      expect(s.current, 3);
    });
  });
}
