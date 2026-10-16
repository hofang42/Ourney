import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

void main() {
  const vn = Duration(hours: 7);
  const la = Duration(hours: -8);

  test('+07:00 rolls over to next day after 17:00 UTC', () {
    expect(localDateOf(DateTime.utc(2026, 10, 5, 16, 59, 59), vn), LocalDate(2026, 10, 5));
    expect(localDateOf(DateTime.utc(2026, 10, 5, 17, 0), vn), LocalDate(2026, 10, 6));
  });

  test('-08:00 stays on previous day until 08:00 UTC', () {
    expect(localDateOf(DateTime.utc(2026, 10, 5, 7, 59), la), LocalDate(2026, 10, 4));
    expect(localDateOf(DateTime.utc(2026, 10, 5, 8, 0), la), LocalDate(2026, 10, 5));
  });

  test('midnight boundary exactly at local 00:00', () {
    expect(localDateOf(DateTime.utc(2026, 10, 4, 17, 0), vn), LocalDate(2026, 10, 5));
  });

  test('leap day is reached through offset', () {
    expect(localDateOf(DateTime.utc(2028, 2, 28, 18, 0), vn), LocalDate(2028, 2, 29));
    expect(localDateOf(DateTime.utc(2028, 3, 1, 3, 0), la), LocalDate(2028, 2, 29));
  });

  test('year boundary', () {
    expect(localDateOf(DateTime.utc(2026, 12, 31, 20, 0), vn), LocalDate(2027, 1, 1));
  });

  test('fractional offset +05:30', () {
    expect(localDateOf(DateTime.utc(2026, 10, 5, 18, 30), const Duration(hours: 5, minutes: 30)),
        LocalDate(2026, 10, 6));
  });

  test('accepts a non-UTC DateTime by normalising to UTC', () {
    final instant = DateTime.parse('2026-10-05T23:30:00+07:00'); // 16:30Z
    expect(localDateOf(instant, vn), LocalDate(2026, 10, 5));
  });

  test('localToday equals localDateOf', () {
    final now = DateTime.utc(2026, 10, 5, 20, 0);
    expect(localToday(now, vn), LocalDate(2026, 10, 6));
  });
}
