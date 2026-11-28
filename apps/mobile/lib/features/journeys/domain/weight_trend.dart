import 'dart:math' as math;

/// A neutral direction threshold in kilograms across seven recorded points.
const weightTrendFlatThresholdKg = 0.2;

enum TrendDirection { down, flat, up }

/// Each slot represents a day. Missing days increase the next smoothing factor.
List<double?> emaTrend(List<double?> values, {double alpha = 0.1}) {
  if (!alpha.isFinite || alpha <= 0 || alpha > 1) {
    throw ArgumentError.value(alpha, 'alpha', 'Must be in (0, 1]');
  }
  final trend = List<double?>.filled(values.length, null);
  double? previous;
  var previousDay = 0;
  for (var day = 0; day < values.length; day++) {
    final value = values[day];
    if (value == null || !value.isFinite) continue;
    final days = day - previousDay;
    final weight = days <= 1 ? alpha : 1 - math.pow(1 - alpha, days).toDouble();
    previous = previous == null
        ? value
        : previous + weight * (value - previous);
    trend[day] = previous;
    previousDay = day;
  }
  return trend;
}

class WeightTrend {
  const WeightTrend._(
    this.trend,
    this.raw,
    this.latestTrend,
    this.changeSinceFirst,
    this.count,
    this.direction,
  );

  static WeightTrend? from(List<double?> values) {
    final raw = [for (final v in values) v != null && v.isFinite ? v : null];
    final count = raw.nonNulls.length;
    if (count < 3) return null;
    final trend = emaTrend(raw);
    final points = trend.nonNulls.toList();
    final start = points.length > 7 ? points.length - 7 : 0;
    final delta = points.last - points[start];
    final direction = delta.abs() + 1e-9 < weightTrendFlatThresholdKg
        ? TrendDirection.flat
        : delta < 0
        ? TrendDirection.down
        : TrendDirection.up;
    return WeightTrend._(
      List.unmodifiable(trend),
      List.unmodifiable(raw),
      points.last,
      points.last - points.first,
      count,
      direction,
    );
  }

  final List<double?> trend;
  final List<double?> raw;
  final double latestTrend;
  final double changeSinceFirst;
  final int count;
  final TrendDirection direction;
}
