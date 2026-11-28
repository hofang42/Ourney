import 'dart:math' as math;

import 'package:ourney_core/ourney_core.dart';

import 'journey_progress.dart';

/// DNA is authoritative; older workout journeys used the metric unit alone.
bool isRunJourney(Journey j) {
  if (j.templateId != TemplateId.workout30) return false;
  final sport = j.dna?['sport'];
  final measure = j.dna?['measure'];
  final unit = (j.metricUnit ?? '').trim().toLowerCase();
  return (sport == null || sport == 'run') &&
      (measure == null || measure == 'km') &&
      (unit.isEmpty || unit == 'km');
}

int? paceSeconds(String? mss) {
  if (mss == null || !RegExp(r'^\d{1,2}:[0-5]\d$').hasMatch(mss)) {
    return null;
  }
  final parts = mss.split(':');
  final minutes = int.parse(parts[0]);
  return minutes == 0 ? null : minutes * 60 + int.parse(parts[1]);
}

String formatPace(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

class RunDay {
  const RunDay(this.day, this.km);
  final TimelineDay day;
  final double km;
}

class RunWeek {
  const RunWeek(this.number, this.days);
  final int number;
  final List<RunDay> days;
  double get km => days.fold(0, (sum, d) => sum + d.km);
}

class RunStats {
  const RunStats({
    required this.totalKm,
    required this.runs,
    required this.avgPaceSec,
    required this.maxKm,
    required this.days,
    required this.weeks,
  });

  factory RunStats.from(List<TimelineDay> timeline) {
    final days = <RunDay>[];
    final weeks = <int, List<RunDay>>{};
    var total = 0.0;
    var weighted = 0.0;
    var pacedKm = 0.0;
    final pacedDays = <int>{};
    var maxKm = 0.0;
    for (final d in timeline) {
      if (d.state != DayState.checkedIn) continue;
      var km = 0.0;
      for (final c in d.checkIns) {
        final distance = c.extras.km;
        if (distance == null || !distance.isFinite || distance <= 0) continue;
        km += distance;
        final pace = paceSeconds(c.extras.pace);
        if (pace != null) {
          weighted += distance * pace;
          pacedKm += distance;
          pacedDays.add(d.dayNumber);
        }
      }
      final run = RunDay(d, km);
      days.add(run);
      (weeks[(d.dayNumber - 1) ~/ 7 + 1] ??= []).add(run);
      total += km;
      maxKm = math.max(maxKm, km);
    }
    return RunStats(
      totalKm: total,
      runs: days.length,
      avgPaceSec: pacedDays.length < 2 ? null : (weighted / pacedKm).round(),
      maxKm: maxKm,
      days: List.unmodifiable(days),
      weeks: [
        for (final e in weeks.entries)
          RunWeek(e.key, List.unmodifiable(e.value)),
      ],
    );
  }

  final double totalKm;
  final int runs;
  final int? avgPaceSec;
  final double maxKm;
  final List<RunDay> days;
  final List<RunWeek> weeks;
}
