import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/ui/day_ticker.dart';

void main() {
  test('next quarter hour is always ahead, on the UTC grid (B-B3)', () {
    // 2026-11-01 05:00Z..07:00Z covers the repeated 01:00 hour of the
    // America/New_York fall-back, where local arithmetic went negative.
    final start = DateTime.utc(2026, 11, 1, 5);
    for (var s = 0; s < 2 * 3600; s += 37) {
      final now = start.add(Duration(seconds: s)).toLocal();
      final wait = untilNextQuarterHour(now);
      expect(wait, greaterThan(Duration.zero));
      expect(wait, lessThanOrEqualTo(const Duration(minutes: 15)));
      final next = now.add(wait).toUtc();
      expect(next.minute % 15, 0);
      expect(next.second, 0);
    }
  });

  test('exactly on a quarter waits a full quarter', () {
    expect(
      untilNextQuarterHour(DateTime.utc(2026, 11, 1, 6, 15)),
      const Duration(minutes: 15),
    );
    expect(
      untilNextQuarterHour(DateTime.utc(2026, 11, 1, 6, 14, 30)),
      const Duration(seconds: 30),
    );
  });
}
