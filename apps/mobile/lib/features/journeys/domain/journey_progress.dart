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
  });

  final LocalDate date;

  /// 1-based day of the journey (from the journey start date).
  final int dayNumber;
  final DayState state;

  /// Also true for a checked-in today (highlight ring on top of the photo).
  final bool isToday;
  final CheckIn? checkIn;
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
    final byDate = <LocalDate, CheckIn>{};
    for (final c in checkIns) {
      final existing = byDate[c.localDate];
      // One check-in per day; keep the latest capture if duplicates leak in.
      if (existing == null || c.capturedAt.isAfter(existing.capturedAt)) {
        byDate[c.localDate] = c;
      }
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
    );
  }

  final Journey journey;
  final LocalDate today;

  /// First day that counts for the caller (later of start and join date).
  final LocalDate memberStart;
  final StreakSummary summary;
  final Map<LocalDate, CheckIn> checkInsByDate;

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
    if (end != null) {
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
    );
  }
}

/// Splits the journeys list (FR-B6): running journeys first, then ended and
/// archived ones. [activeCount] feeds the 3-active-journeys rule (FR-B3).
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
  bool get canCreate => canCreateJourney(activeCount);
  bool get isEmpty => active.isEmpty && finished.isEmpty;
}
