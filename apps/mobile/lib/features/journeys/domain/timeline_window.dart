import 'dart:math' as math;

import 'package:ourney_core/ourney_core.dart';

import 'journey_progress.dart';
import 'wrapped_story.dart';

/// A journey with more days than this has passed gets the windowed timeline
/// (Recent window + By month archive). Shorter ones render every day.
const int longJourneyDays = 31;

/// Days shown up to today in the Recent window.
const int recentWindowDays = 14;

/// Upcoming days shown after today in the Recent window.
const int recentPeekDays = 2;

/// Most points a curve or sparkline ever draws.
const int maxCurvePoints = 90;

/// Days of the "30D" range of the quiet curve.
const int shortRangeDays = 30;

/// True when [p] has passed more than [longJourneyDays] days.
bool isLongJourney(JourneyProgress p) => p.elapsedDays > longJourneyDays;

/// Reduces [values] to at most [max] points, always keeping the first and the
/// last value and, per bucket, the lowest and the highest one (so the shape
/// and both extremes survive). Returns [values] itself when it already fits.
List<double> downsample(List<double> values, {int max = maxCurvePoints}) {
  if (values.length <= max || max < 4) return values;
  final interior = values.length - 2;
  final buckets = (max - 2) ~/ 2;
  final out = <double>[values.first];
  for (var b = 0; b < buckets; b++) {
    final from = 1 + b * interior ~/ buckets;
    final to = 1 + (b + 1) * interior ~/ buckets;
    if (from >= to) continue;
    var lo = from;
    var hi = from;
    for (var i = from + 1; i < to; i++) {
      if (values[i] < values[lo]) lo = i;
      if (values[i] > values[hi]) hi = i;
    }
    if (lo == hi) {
      out.add(values[lo]);
    } else {
      out
        ..add(values[math.min(lo, hi)])
        ..add(values[math.max(lo, hi)]);
    }
  }
  out.add(values.last);
  return out;
}

/// Cumulative check-in count per day up to today (the "pace" series).
List<double> cumulativeSeries(List<TimelineDay> days) {
  var n = 0;
  final out = <double>[];
  for (final d in days) {
    if (d.state == DayState.future) break;
    if (d.state == DayState.checkedIn) n++;
    out.add(n.toDouble());
  }
  return out;
}

/// Month key: 12 * year + (month - 1). Sorts like the calendar.
int monthIdOf(LocalDate d) => d.year * 12 + d.month - 1;

/// One calendar month of the journey, up to today (never a future day).
class MonthBucket {
  const MonthBucket({
    required this.year,
    required this.month,
    required this.first,
    required this.firstDayNumber,
    required this.heat,
    required this.photos,
    required this.covers,
    required this.isCurrent,
  });

  final int year;
  final int month;

  /// First journey day of this month that has started.
  final LocalDate first;
  final int firstDayNumber;

  /// One flag per day from [first]: checked in or not.
  final List<bool> heat;

  /// Photos of the month (every photo of every day).
  final int photos;

  /// Up to three of the latest check-ins (one per day), oldest first.
  final List<CheckIn> covers;

  /// The month of today.
  final bool isCurrent;

  int get id => year * 12 + month - 1;

  int get days => heat.length;

  int get checked => heat.where((c) => c).length;

  LocalDate get last => first.addDays(days - 1);
}

/// What the Recent window shows.
class TimelineWindow {
  const TimelineWindow({
    required this.days,
    required this.earlierDays,
    required this.earlierChecked,
    required this.earlierMonthId,
    required this.daysToGo,
    required this.finishDay,
    this.startsIn,
  });

  /// The window's cells: up to [recentWindowDays] days to today plus
  /// [recentPeekDays] upcoming ones.
  final List<TimelineDay> days;

  /// Days of the journey before the window (the "Earlier" link covers
  /// day 1 .. [earlierDays]).
  final int earlierDays;
  final int earlierChecked;

  /// The month just before the window (target of the "Earlier" link).
  final int? earlierMonthId;

  /// Fixed-term journeys only: days left after today (null: no end cap).
  final int? daysToGo;
  final int? finishDay;

  /// Journey not started yet: days until day 1.
  final int? startsIn;

  bool get hasEarlier => earlierDays > 0;
  bool get hasEndCap => daysToGo != null && daysToGo! > 0;
}

/// Numbers the variants show above the days: curves over the whole journey
/// (downsampled), the check-in totals and the film-roll frame count.
class TimelineSummary {
  const TimelineSummary({
    required this.curve,
    required this.metricCount,
    required this.metricFirst,
    required this.metricLast,
    required this.pace,
    required this.done,
    required this.frames,
    required this.totalDays,
    required this.currentDay,
    this.curve30,
    this.metric30Count = 0,
    this.isOpenEnded = false,
  });

  /// What the cells of [days] say: the whole list is the whole journey.
  factory TimelineSummary.fromDays(List<TimelineDay> days) {
    final metric = <double>[for (final d in days) ?d.metricValue];
    final pace = cumulativeSeries(days);
    var done = 0;
    var frames = 0;
    var current = 1;
    for (final d in days) {
      if (d.state == DayState.checkedIn) done++;
      if (d.state == DayState.checkedIn || d.state == DayState.today) {
        frames += d.photoCount;
      }
      if (d.state != DayState.future) current = math.max(current, d.dayNumber);
    }
    return TimelineSummary(
      curve: metric.length >= 2 ? metric : pace,
      metricCount: metric.length,
      metricFirst: metric.isEmpty ? null : metric.first,
      metricLast: metric.isEmpty ? null : metric.last,
      pace: pace,
      done: done,
      frames: frames,
      totalDays: days.isEmpty ? 0 : days.last.dayNumber,
      currentDay: current,
    );
  }

  /// The curve to draw: the metric when there are two values, else the pace.
  /// At most [maxCurvePoints] points.
  final List<double> curve;

  /// The "30D" range of [curve] (long journeys only).
  final List<double>? curve30;

  /// Metric values inside the 30D range.
  final int metric30Count;
  final int metricCount;
  final double? metricFirst;
  final double? metricLast;

  /// Cumulative check-ins per day, at most [maxCurvePoints] points.
  final List<double> pace;
  final int done;

  /// Every photo of the journey (film roll).
  final int frames;

  /// Length of the journey (fixed term) or of its timeline (open-ended).
  final int totalDays;

  /// Day N of today, clamped to the journey.
  final int currentDay;

  /// True when the journey has no fixed duration (`durationDays == null`).
  final bool isOpenEnded;
}

/// Everything the long-journey screen needs, computed once per change of the
/// check-ins or of today (see `journeyTimelineIndexProvider`): month
/// buckets, totals, the missed-day chip and the downsampled curves.
class TimelineIndex {
  TimelineIndex._({
    required this.progress,
    required this.months,
    required this.lastMissedDay,
    required this.timelineLength,
    required this.summary,
    required this.checkedPrefix,
  });

  factory TimelineIndex.build(JourneyProgress progress) {
    final start = progress.journey.startDate;
    final today = progress.today;
    final end = progress.journey.endDate;
    // A journey that has ended stops at its last day.
    final last = progress.lastDay;

    final months = <MonthBucket>[];
    final prefix = <int>[0];
    final metric = <double>[];
    final metric30 = <double>[];
    final pace = <double>[];
    final elapsed = progress.elapsedDays;
    var done = 0;
    var frames = 0;
    int? lastMissed;

    // Per-month accumulators.
    var heat = <bool>[];
    var monthPhotos = 0;
    var covers = <CheckIn>[];
    LocalDate? monthFirst;
    var monthFirstNo = 1;

    void flush(LocalDate monthDate) {
      final first = monthFirst;
      if (first == null) return;
      months.add(
        MonthBucket(
          year: monthDate.year,
          month: monthDate.month,
          first: first,
          firstDayNumber: monthFirstNo,
          heat: heat,
          photos: monthPhotos,
          covers: covers,
          isCurrent:
              monthDate.year == last.year && monthDate.month == last.month,
        ),
      );
    }

    var date = start;
    var dayNo = 1;
    LocalDate? prev;
    while (!date.isAfter(last)) {
      if (prev == null || prev.month != date.month || prev.year != date.year) {
        if (prev != null) flush(prev);
        heat = <bool>[];
        monthPhotos = 0;
        covers = <CheckIn>[];
        monthFirst = date;
        monthFirstNo = dayNo;
      }
      final latest = progress.checkInsByDate[date];
      heat.add(latest != null);
      if (latest != null) {
        done++;
        final all = progress.checkInsOn(date);
        frames += all.length;
        monthPhotos += all.length;
        covers.add(latest);
        if (covers.length > 3) covers.removeAt(0);
        final m = latestMetric(all);
        if (m != null) {
          metric.add(m);
          if (dayNo > elapsed - shortRangeDays) metric30.add(m);
        }
      } else if (date.isBefore(today) && !date.isBefore(progress.memberStart)) {
        lastMissed = dayNo;
      }
      pace.add(done.toDouble());
      prefix.add(done);
      prev = date;
      date = date.addDays(1);
      dayNo++;
    }
    if (prev != null) flush(prev);

    // Timeline length, as `JourneyProgress.timeline()` computes it.
    final int length;
    if (!progress.isActive) {
      // Ended: the timeline stops at its last day.
      length = math.max(1, start.daysUntil(progress.lastDay) + 1);
    } else if (end != null) {
      length = start.daysUntil(end) + 1;
    } else {
      var tail = today;
      for (final d in progress.checkInsByDate.keys) {
        if (d.isAfter(tail)) tail = d;
      }
      if (tail.isBefore(start)) tail = start;
      length = start.daysUntil(tail) + 1;
    }

    final pace30 = pace.length > shortRangeDays
        ? pace.sublist(pace.length - shortRangeDays)
        : pace;
    final summary = TimelineSummary(
      curve: downsample(metric.length >= 2 ? metric : pace),
      curve30: isLongJourney(progress)
          ? downsample(metric30.length >= 2 ? metric30 : pace30)
          : null,
      metric30Count: metric30.length,
      metricCount: metric.length,
      metricFirst: metric.isEmpty ? null : metric.first,
      metricLast: metric.isEmpty ? null : metric.last,
      pace: downsample(pace),
      done: done,
      frames: frames,
      totalDays: length,
      currentDay: math.max(1, math.min(elapsed, length)),
      isOpenEnded: progress.isOpenEnded,
    );
    return TimelineIndex._(
      progress: progress,
      months: List.unmodifiable(months),
      lastMissedDay: lastMissed,
      timelineLength: length,
      summary: summary,
      checkedPrefix: prefix,
    );
  }

  final JourneyProgress progress;

  /// Oldest first, up to the month of today.
  final List<MonthBucket> months;

  /// Highest day number that was missed (the missed-day chip).
  final int? lastMissedDay;

  /// Days of the timeline (fixed term, or open-ended up to today).
  final int timelineLength;

  /// Whole-journey numbers and downsampled curves.
  final TimelineSummary summary;

  /// `checkedPrefix[n]` = checked days among the first n days.
  final List<int> checkedPrefix;

  bool get isLong => isLongJourney(progress);

  /// Metric values of the journey, oldest first, downsampled for the home
  /// chart (first and last value kept). Empty with fewer than two values.
  List<double> get metricSeries =>
      summary.metricCount >= 2 ? summary.curve : const [];

  /// Numbers of the end-of-journey story and the skin header, built once.
  late final WrappedStats wrapped = WrappedStats.from(progress);

  /// Checked days among the first [n] days of the journey.
  int checkedAmongFirst(int n) =>
      checkedPrefix[n.clamp(0, checkedPrefix.length - 1)];

  MonthBucket? monthById(int id) {
    for (final m in months) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// The Recent window of the persona timeline.
  late final TimelineWindow recent = _window(minimal: false);

  /// Fixed-term journey with 31 days or fewer passed: every elapsed day, two
  /// upcoming days and the finish card (never the whole term).
  late final TimelineWindow shortWindow = _window(minimal: false, all: true);

  /// The Recent window of the minimal skin: its calendar shows the month of
  /// today (plus the previous month in the first week of a month).
  late final TimelineWindow recentMinimal = _window(minimal: true);

  TimelineWindow _window({required bool minimal, bool all = false}) {
    final j = progress.journey;
    final start = j.startDate;
    final end = j.endDate;
    final today = progress.today;
    final active = progress.isActive;
    // Not started yet: the preview is days 1-3 (start + 2 upcoming days).
    final notStarted = today.isBefore(start);
    final anchor = notStarted ? start : progress.lastDay;
    var from = anchor.addDays(1 - recentWindowDays);
    if (minimal) {
      final monthStart = LocalDate(anchor.year, anchor.month, 1);
      final prevEnd = monthStart.addDays(-1);
      from = anchor.day <= 7
          ? LocalDate(prevEnd.year, prevEnd.month, 1)
          : monthStart;
    }
    if (all || from.isBefore(start)) from = start;
    // An ended journey has no upcoming days and no "days to go".
    var to = anchor.addDays(active ? recentPeekDays : 0);
    if (end != null && to.isAfter(end)) to = end;
    final earlier = start.daysUntil(from);
    final toGo = end == null || !active
        ? null
        : math.max(0, today.daysUntil(end));
    return TimelineWindow(
      days: List.unmodifiable(progress.range(from, to)),
      earlierDays: earlier,
      earlierChecked: checkedAmongFirst(earlier),
      earlierMonthId: earlier > 0 ? monthIdOf(from.addDays(-1)) : null,
      daysToGo: toGo,
      finishDay: end == null || !active ? null : timelineLength,
      startsIn: notStarted ? today.daysUntil(start) : null,
    );
  }
}