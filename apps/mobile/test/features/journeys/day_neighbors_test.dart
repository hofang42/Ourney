import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/domain/day_neighbors.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

void main() {
  LocalDate d(int day) => LocalDate(2026, 10, day);
  test('neighbors handle empty, single, edges, gaps, duplicates and absent current', () {
    expect(dayNeighbors([], d(12)), (prev: null, next: null));
    expect(dayNeighbors([d(12)], d(12)), (prev: null, next: null));
    expect(dayNeighbors([d(12)], d(11)), (prev: null, next: d(12)));
    expect(dayNeighbors([d(12)], d(13)), (prev: d(12), next: null));
    final dates = [d(18), d(10), d(12), d(12)];
    expect(dayNeighbors(dates, d(10)), (prev: null, next: d(12)));
    expect(dayNeighbors(dates, d(12)), (prev: d(10), next: d(18)));
    expect(dayNeighbors(dates, d(18)), (prev: d(12), next: null));
    expect(dayNeighbors(dates, d(14)), (prev: d(12), next: d(18)));
  }, timeout: const Timeout(Duration(seconds: 10)));
  test('partner-only dates participate in neighbors', () {
    final mine = [d(10), d(18)];
    final partner = [d(12)];
    expect(dayNeighbors([...mine, ...partner], d(10)), (
      prev: null,
      next: d(12),
    ));
  }, timeout: const Timeout(Duration(seconds: 10)));
  test(
    'ordinal includes day one, open terms, past end and rejects before start',
    () {
      final j = testJourney(durationDays: 14);
      expect(journeyDayOrdinal(j, d(10)), 1);
      expect(journeyDayOrdinal(j, d(16)), 7);
      expect(journeyDayOrdinal(j, const LocalDate(2026, 11, 10)), 32);
      expect(journeyDayOrdinal(j, d(9)), null);
      expect(journeyDayOrdinal(testJourney(durationDays: null), d(16)), 7);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
