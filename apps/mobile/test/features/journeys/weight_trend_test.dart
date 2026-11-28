import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/domain/weight_trend.dart';

void main() {
  final timeout = Timeout(const Duration(seconds: 15));
  test('EMA seeds at the first measurement and bridges gaps', () {
    expect(emaTrend([null, 70, null, 72, 71]), [
      null,
      70,
      null,
      closeTo(70.38, .0001),
      closeTo(70.442, .0001),
    ]);
    expect(emaTrend([]), isEmpty);
  }, timeout: timeout);
  test(
    'a single daily spike moves the trend by at most alpha times the spike',
    () {
      const alpha = .1;
      const spike = 10.0;
      final trend = emaTrend([70, 70, 70 + spike, 70], alpha: alpha);
      expect(trend[2]! - trend[1]!, lessThanOrEqualTo(alpha * spike));
      expect(trend.last!, lessThan(trend[2]!));
    },
    timeout: timeout,
  );
  test('weekly weigh-ins are weighted by the seven-day intervals', () {
    final trend = WeightTrend.from([
      80,
      for (final weight in [79.0, 78.0, 77.0]) ...[
        for (var i = 0; i < 6; i++) null,
        weight,
      ],
    ])!;
    expect(trend.count, 4);
    expect(trend.trend[7], closeTo(79.4783, .0001));
    expect(trend.changeSinceFirst, lessThan(-2));
    expect(trend.changeSinceFirst, trend.trend.last! - trend.trend.first!);
    expect(trend.direction, TrendDirection.down);
  }, timeout: timeout);
  test('three measurements are required', () {
    expect(WeightTrend.from([70, null, 71]), isNull);
    final t = WeightTrend.from([70, null, 71, 72])!;
    expect(t.count, 3);
    expect(t.latestTrend, closeTo(70.371, .0001));
    expect(t.changeSinceFirst, closeTo(.371, .0001));
  }, timeout: timeout);
  test('direction uses the last seven trend points and neutral threshold', () {
    expect(WeightTrend.from([70, 70, 70.1])!.direction, TrendDirection.flat);
    expect(WeightTrend.from([70, 72, 74])!.direction, TrendDirection.up);
    expect(WeightTrend.from([70, 68, 66])!.direction, TrendDirection.down);
    expect(
      WeightTrend.from([50, for (var i = 0; i < 100; i++) 70])!.direction,
      TrendDirection.flat,
    );
    expect(WeightTrend.from([70, 70, 72])!.direction, TrendDirection.up);
    expect(WeightTrend.from([70, 70, 68])!.direction, TrendDirection.down);
    expect(WeightTrend.from([70, 70, 71.99])!.direction, TrendDirection.flat);
    expect(emaTrend([70, double.nan, 72]), [70, null, closeTo(70.38, .0001)]);
    expect(() => emaTrend([70], alpha: 0), throwsArgumentError);
  }, timeout: timeout);
}
