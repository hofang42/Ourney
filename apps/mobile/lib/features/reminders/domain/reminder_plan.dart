// Pure reminder planning (FR-G1, FR-G2). No Flutter, no plugins: given the
// journeys, their check-in dates and the user's reminder settings, decide
// which local notifications should be pending and when they fire.
//
// The scheduler (`../data/reminder_scheduler.dart`) turns the result into
// flutter_local_notifications calls behind an injectable gateway.
import 'package:ourney_core/ourney_core.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../shared/time_zones.dart';

/// iOS keeps at most 64 pending local notifications per app; anything beyond
/// is silently dropped, so the plan never exceeds it (FR-G1).
const int kMaxPendingNotifications = 64;

/// Rolling scheduling window (FR-G1): the plan covers this many days and is
/// rebuilt on every app start/resume and after each check-in.
const int kReminderWindowDays = 14;

/// Wall-clock time of the "streak about to break" alert (FR-G2).
const ReminderTime kStreakAlertTime = ReminderTime(21, 0);

/// A time of day (24 h clock).
class ReminderTime implements Comparable<ReminderTime> {
  const ReminderTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// Parses `HH:mm`; null when malformed.
  static ReminderTime? tryParse(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return ReminderTime(h, m);
  }

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  @override
  int compareTo(ReminderTime other) => minutesOfDay - other.minutesOfDay;

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  /// `HH:mm`.
  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// What the planner needs to know about one journey.
class JourneyReminderInput {
  const JourneyReminderInput({
    required this.journeyId,
    required this.title,
    required this.timezone,
    required this.status,
    required this.streakStart,
    required this.checkedInDates,
    this.endDate,
    this.reminderTime,
  });

  /// Builds the input from domain objects. [joinedLocalDate] is the
  /// journey-local date of `Membership.joinedAt` (null = journey start).
  factory JourneyReminderInput.fromJourney(
    Journey journey, {
    required Iterable<LocalDate> checkedInDates,
    LocalDate? joinedLocalDate,
    ReminderTime? reminderTime,
  }) => JourneyReminderInput(
    journeyId: journey.id,
    title: journey.title,
    timezone: journey.timezone,
    status: journey.status,
    streakStart: joinedLocalDate == null
        ? journey.startDate
        : effectiveStreakStart(journey.startDate, joinedLocalDate),
    endDate: journey.endDate,
    checkedInDates: checkedInDates.toSet(),
    reminderTime: reminderTime,
  );

  final String journeyId;
  final String title;

  /// IANA zone of the journey: check-in days and the 21:00 alert are
  /// journey-local (same rule as the server's `local_date`).
  final String timezone;
  final JourneyStatus status;

  /// First day that counts for the user (`effectiveStreakStart`). No
  /// notification is planned before it.
  final LocalDate streakStart;

  /// Last journey day (inclusive), null when open-ended.
  final LocalDate? endDate;

  /// Journey-local dates the user already checked in on.
  final Set<LocalDate> checkedInDates;

  /// Daily reminder time in the device's wall clock, null when off.
  final ReminderTime? reminderTime;
}

enum PlannedKind {
  /// Daily "time to check in" reminder at the user's chosen time.
  reminder,

  /// 21:00 "your streak is about to break" alert (FR-G2).
  streakAlert,
}

/// One notification the device should have pending.
class PlannedNotification {
  const PlannedNotification({
    required this.kind,
    required this.journeyId,
    required this.journeyTitle,
    required this.fireAt,
    required this.journeyDate,
    this.streak = 0,
  });

  final PlannedKind kind;
  final String journeyId;
  final String journeyTitle;

  /// Absolute instant (UTC).
  final DateTime fireAt;

  /// Journey-local day the notification is about.
  final LocalDate journeyDate;

  /// For [PlannedKind.streakAlert]: the streak that breaks at midnight.
  final int streak;

  @override
  String toString() =>
      'PlannedNotification(${kind.name}, $journeyId, $journeyDate, '
      '${fireAt.toIso8601String()}, streak: $streak)';
}

/// Plans the pending notifications for the next [windowDays] days.
///
/// Rules:
/// * only `active` journeys; never before `streakStart` or after `endDate`;
/// * daily reminders fire at `reminderTime` in [deviceTimezone] (the user's
///   wall clock) and are skipped for journey days already checked in;
/// * when [streakAlerts] is on, a [kStreakAlertTime] alert (journey-local)
///   is planned for each unchecked day whose streak, assuming no further
///   check-ins, is at least 1 (i.e. today when yesterday was checked in, or
///   tomorrow once today is checked in);
/// * only instants strictly after [now];
/// * sorted by time (nearest first) and capped at [maxPending].
///
/// Nonexistent local times (DST spring-forward gap) move forward by the gap
/// (02:30 -> 03:30); ambiguous ones (fall-back) use the first occurrence.
/// Unknown zone names fall back to UTC. Requires the timezone database to
/// be loaded (`initializeTimeZones()`).
List<PlannedNotification> planReminders({
  required DateTime now,
  required String deviceTimezone,
  required Iterable<JourneyReminderInput> journeys,
  bool streakAlerts = true,
  int windowDays = kReminderWindowDays,
  int maxPending = kMaxPendingNotifications,
  ReminderTime streakAlertTime = kStreakAlertTime,
}) {
  final nowUtc = now.toUtc();
  final device = _location(deviceTimezone);
  final deviceToday = _localDate(nowUtc, device);
  final out = <PlannedNotification>[];

  for (final j in journeys) {
    if (j.status != JourneyStatus.active) continue;
    final zone = _location(j.timezone);
    bool inJourney(LocalDate d) =>
        !d.isBefore(j.streakStart) &&
        (j.endDate == null || !d.isAfter(j.endDate!));

    final time = j.reminderTime;
    if (time != null) {
      for (var i = 0; i < windowDays; i++) {
        final fireAt = wallClockToUtc(device, deviceToday.addDays(i), time);
        if (!fireAt.isAfter(nowUtc)) continue;
        final day = _localDate(fireAt, zone);
        if (!inJourney(day) || j.checkedInDates.contains(day)) continue;
        out.add(
          PlannedNotification(
            kind: PlannedKind.reminder,
            journeyId: j.journeyId,
            journeyTitle: j.title,
            fireAt: fireAt,
            journeyDate: day,
          ),
        );
      }
    }

    if (streakAlerts) {
      final journeyToday = _localDate(nowUtc, zone);
      for (var i = 0; i < windowDays; i++) {
        final day = journeyToday.addDays(i);
        if (!inJourney(day) || j.checkedInDates.contains(day)) continue;
        final fireAt = wallClockToUtc(zone, day, streakAlertTime);
        if (!fireAt.isAfter(nowUtc)) continue;
        final streak = _streakAt(j, day);
        if (streak < 1) continue;
        out.add(
          PlannedNotification(
            kind: PlannedKind.streakAlert,
            journeyId: j.journeyId,
            journeyTitle: j.title,
            fireAt: fireAt,
            journeyDate: day,
            streak: streak,
          ),
        );
      }
    }
  }

  out.sort((a, b) {
    final t = a.fireAt.compareTo(b.fireAt);
    if (t != 0) return t;
    // Same instant: the streak alert matters more than a plain reminder.
    final k = b.kind.index - a.kind.index;
    if (k != 0) return k;
    return a.journeyId.compareTo(b.journeyId);
  });
  return out.length <= maxPending ? out : out.sublist(0, maxPending);
}

/// Streak alive on [day] before any check-in that day (assuming none after
/// today), i.e. the run that ends at midnight if the user does nothing.
int _streakAt(JourneyReminderInput j, LocalDate day) {
  final end = j.endDate;
  return computeStreak(
    start: j.streakStart,
    durationDays: end == null ? null : j.streakStart.daysUntil(end) + 1,
    today: day,
    dates: j.checkedInDates,
  ).current;
}

/// Legacy names map to canonical zones; an unknown name uses the logged
/// best guess of [resolveTimeZone] (never a silent UTC).
tz.Location _location(String name) => resolveTimeZone(name);

/// Calendar date of [instant] in the IANA zone [timezone].
LocalDate localDateIn(String timezone, DateTime instant) =>
    _localDate(instant.toUtc(), _location(timezone));

LocalDate _localDate(DateTime instant, tz.Location zone) {
  return localDateOf(
    instant,
    zone.timeZone(instant.millisecondsSinceEpoch).offset,
  );
}

/// The UTC instant at which the wall clock in [zone] shows [time] on [date].
///
/// Spring-forward gap: the time is moved forward by the gap. Fall-back
/// overlap: the earlier of the two instants.
DateTime wallClockToUtc(tz.Location zone, LocalDate date, ReminderTime time) {
  final wall = DateTime.utc(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  ).millisecondsSinceEpoch;
  int offsetAt(int utcMs) => zone.timeZone(utcMs).offset.inMilliseconds;

  // Offsets in force somewhat before and after the wall time cover any
  // single transition near it (transitions are never < 1 day apart).
  const window = 26 * 3600 * 1000;
  final before = offsetAt(wall - window);
  final after = offsetAt(wall + window);
  final valid = <int>[
    for (final o in {before, after})
      if (offsetAt(wall - o) == o) wall - o,
  ]..sort();
  final utc = valid.isNotEmpty ? valid.first : wall - before;
  return DateTime.fromMillisecondsSinceEpoch(utc, isUtc: true);
}
