import 'package:ourney_core/ourney_core.dart';

import 'journey_time.dart';

/// State of one calendar cell in the journey timeline (FR-B4).
enum DayState {
  /// A check-in exists for that day (thumbnail).
  checkedIn,

  /// Past day inside the member's window with no check-in (dashed cell).
  missed,

  /// Today, not checked in yet (highlighted).
  today,

  /// After today (muted).
  future,

  /// Before the member joined a group journey: not counted, muted.
  notCounted,
}

class TimelineDay {
  const TimelineDay({
    required this.date,
    required this.dayNumber,
    required this.state,
    required this.isToday,
    this.checkIn,
    this._checkIns,
  });

  final LocalDate date;

  /// 1-based day of the journey (from the journey start date).
  final int dayNumber;
  final DayState state;

  /// Also true for a checked-in today (highlight ring on top of the photo).
  final bool isToday;

  /// The latest photo of the day (the one the cell shows).
  final CheckIn? checkIn;

  final List<CheckIn>? _checkIns;

  /// Every photo of the day, oldest first (several since `0014`).
  List<CheckIn> get checkIns => _checkIns ?? [?checkIn];

  int get photoCount => checkIns.length;

  /// The day's latest logged metric: a later photo without a value (e.g. an
  /// evening stretch after the morning weigh-in) does not hide it.
  double? get metricValue => latestMetric(checkIns);

  /// The day's latest photo that carries a partner half (couple diptych).
  CheckIn? get partnerCheckIn {
    for (final c in checkIns.reversed) {
      if (c.partnerPhotoPath != null) return c;
    }
    return null;
  }
}

/// Latest non-null metric value of [dayCheckIns] (oldest first).
double? latestMetric(Iterable<CheckIn> dayCheckIns) {
  double? v;
  for (final c in dayCheckIns) {
    v = c.metricValue ?? v;
  }
  return v;
}

/// Everything the journey list card and the detail screen show, derived from
/// the journey, the caller's membership and the caller's check-ins. Streaks
/// come from `computeMemberStreak` (same rule as the server).
class JourneyProgress {
  const JourneyProgress({
    required this.journey,
    required this.today,
    required this.memberStart,
    required this.summary,
    required this.checkInsByDate,
    this._checkInsOnDate,
    this._lastDay,
  });

  factory JourneyProgress.compute({
    required Journey journey,
    required Membership? membership,
    required Iterable<CheckIn> checkIns,
    required DateTime now,
  }) {
    final today = journeyLocalDate(journey.timezone, now);
    final joined = membership == null
        ? journey.startDate
        : journeyLocalDate(journey.timezone, membership.joinedAt);
    // Several photos a day since `0014`: keep them all (oldest first) and
    // the latest one per day for the cell / streak (B-B5).
    final onDate = <LocalDate, List<CheckIn>>{};
    for (final c in checkIns) {
      (onDate[c.localDate] ??= []).add(c);
    }
    final byDate = <LocalDate, CheckIn>{};
    for (final e in onDate.entries) {
      e.value.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
      byDate[e.key] = e.value.last;
    }
    final summary = computeMemberStreak(
      journeyStart: journey.startDate,
      durationDays: journey.durationDays,
      joinedLocalDate: joined,
      today: today,
      dates: byDate.keys,
    );
    return JourneyProgress(
      journey: journey,
      today: today,
      memberStart: effectiveStreakStart(journey.startDate, joined),
      summary: summary,
      checkInsByDate: byDate,
      lastDay: _lastDayOf(journey, today, byDate.keys),
      checkInsOnDate: onDate,
    );
  }

  final Journey journey;
  final LocalDate today;

  /// First day that counts for the caller (later of start and join date).
  final LocalDate memberStart;
  final StreakSummary summary;

  /// The latest check-in of each day.
  final Map<LocalDate, CheckIn> checkInsByDate;

  final Map<LocalDate, List<CheckIn>>? _checkInsOnDate;
  final LocalDate? _lastDay;

  /// Every check-in of [date], oldest first.
  List<CheckIn> checkInsOn(LocalDate date) {
    final all = _checkInsOnDate?[date];
    if (all != null) return all;
    final one = checkInsByDate[date];
    return one == null ? const [] : [one];
  }

  /// Every check-in of the journey, oldest first.
  List<CheckIn> get allCheckIns {
    final days = checkInsByDate.keys.toList()..sort((a, b) => a.compareTo(b));
    return [for (final d in days) ...checkInsOn(d)];
  }

  bool get isOpenEnded => journey.durationDays == null;
  bool get isActive => journey.status == JourneyStatus.active;

  /// 1-based day N of the journey for today, clamped to the journey window
  /// (journey-wide, not member-relative, so all members agree on "day N").
  int get dayNumber {
    final n = journey.startDate.daysUntil(today) + 1;
    if (n < 1) return 1;
    final total = journey.durationDays;
    if (total != null && n > total) return total;
    return n;
  }

  int? get totalDays => journey.durationDays;

  /// Whole percent of completed days, null for open-ended journeys.
  int? get percentComplete =>
      isOpenEnded ? null : (summary.progress * 100).round();

  bool get checkedInToday => summary.checkedInToday;

  /// Calendar cells from the journey start to its end (or, open-ended, to
  /// the later of today and the latest check-in).
  List<TimelineDay> timeline() {
    final start = journey.startDate;
    LocalDate last;
    final end = journey.endDate;
    if (!isActive) {
      // Ended: never past its last day (see [lastDay]).
      last = lastDay;
      if (last.isBefore(start)) last = start;
    } else if (end != null) {
      last = end;
    } else {
      last = today;
      for (final d in checkInsByDate.keys) {
        if (d.isAfter(last)) last = d;
      }
      if (last.isBefore(start)) last = start;
    }
    final count = start.daysUntil(last) + 1;
    return [for (var i = 0; i < count; i++) _day(start.addDays(i), i + 1)];
  }

  /// The calendar cell of one [date] (1-based day number from the journey
  /// start), built on demand so long journeys never materialise every day.
  TimelineDay dayAt(LocalDate date) =>
      _day(date, journey.startDate.daysUntil(date) + 1);

  /// The calendar cells from [from] to [to], both inclusive (empty when
  /// [to] is before [from]).
  List<TimelineDay> range(LocalDate from, LocalDate to) {
    final count = from.daysUntil(to) + 1;
    return [for (var i = 0; i < count; i++) dayAt(from.addDays(i))];
  }

  /// Days of the journey that have started, today included (0 before the
  /// start). Journeys longer than 31 get the windowed timeline.
  int get elapsedDays {
    final n = journey.startDate.daysUntil(lastDay) + 1;
    final total = journey.durationDays;
    if (total != null && n > total) return total;
    return n < 0 ? 0 : n;
  }

  /// The last day the timeline counts: today, but never past the end of a
  /// fixed term, and for a journey that was ended early (status not active,
  /// today still inside its term or open-ended) the day of its last
  /// check-in, since the end date is not stored.
  LocalDate get lastDay =>
      _lastDay ?? _lastDayOf(journey, today, checkInsByDate.keys);

  static LocalDate _lastDayOf(
    Journey journey,
    LocalDate today,
    Iterable<LocalDate> checkInDates,
  ) {
    final end = journey.endDate;
    var last = end != null && end.isBefore(today) ? end : today;
    final endedEarly =
        journey.status != JourneyStatus.active &&
        (end == null || !today.isAfter(end));
    if (endedEarly) {
      // The journey row carries no "ended at" (only a server `updated_at`
      // that any edit moves), so the last check-in, or the start day when
      // there is none, is the last day.
      LocalDate? latest;
      for (final d in checkInDates) {
        if (!d.isAfter(last) && (latest == null || d.isAfter(latest))) {
          latest = d;
        }
      }
      last = latest ?? (journey.startDate.isAfter(last) ? last : journey.startDate);
    }
    return last;
  }

  TimelineDay _day(LocalDate date, int number) {
    final checkIn = checkInsByDate[date];
    final isToday = date == today;
    final DayState state;
    if (checkIn != null && !date.isAfter(today)) {
      state = DayState.checkedIn;
    } else if (date.isAfter(today)) {
      state = DayState.future;
    } else if (date.isBefore(memberStart)) {
      state = DayState.notCounted;
    } else if (isToday) {
      state = DayState.today;
    } else {
      state = DayState.missed;
    }
    return TimelineDay(
      date: date,
      dayNumber: number,
      state: state,
      isToday: isToday,
      checkIn: checkIn,
      checkIns: checkInsOn(date),
    );
  }
}

/// Splits the journeys list (FR-B6): running journeys first, then ended and
/// archived ones. There is no cap on running journeys (FR-B3).
class JourneyBuckets {
  JourneyBuckets(Iterable<Journey> journeys)
    : active = [
        for (final j in journeys)
          if (j.status == JourneyStatus.active) j,
      ],
      finished = [
        for (final j in journeys)
          if (j.status != JourneyStatus.active) j,
      ];

  final List<Journey> active;
  final List<Journey> finished;

  int get activeCount => active.length;
  bool get isEmpty => active.isEmpty && finished.isEmpty;
}
