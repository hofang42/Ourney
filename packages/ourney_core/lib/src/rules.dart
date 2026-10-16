import 'models.dart';

const int maxActiveJourneys = 3;
const int maxGroupMembers = 10;

/// iOS keeps at most 64 pending local notifications per app.
const int iosPendingNotificationLimit = 64;

/// Slots kept free for anything else the app schedules.
const int _safetyMargin = 4;

/// Rolling window of non-repeating reminders per journey (docs/02 §9 #11).
const int rollingReminderDays = 14;

bool canCreateJourney(int activeCount) => activeCount < maxActiveJourneys;

/// Local wall-clock times of the next [days] daily reminders at
/// [hour]:[minute]. Today is included only if that time is still in the
/// future. Dates in [skipDates] (e.g. already checked in today) are dropped.
List<DateTime> rollingReminderTimes({
  required DateTime nowLocal,
  required int hour,
  required int minute,
  int days = rollingReminderDays,
  Set<LocalDate> skipDates = const {},
}) {
  final todayAt = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, hour, minute);
  final firstOffset = todayAt.isAfter(nowLocal) ? 0 : 1;
  final result = <DateTime>[];
  for (var i = 0; i < days; i++) {
    final t = DateTime(nowLocal.year, nowLocal.month, nowLocal.day + firstOffset + i, hour, minute);
    if (skipDates.contains(LocalDate(t.year, t.month, t.day))) continue;
    result.add(t);
  }
  return result;
}

int _perJourneyShare(int activeJourneys) =>
    activeJourneys <= 0 ? 0 : (iosPendingNotificationLimit - _safetyMargin) ~/ activeJourneys;

/// Daily-reminder slots a journey may use. Half of each journey's share of the
/// iOS 64 cap is reserved for the 21:00 "streak at risk" alerts.
int maxReminderSlotsPerJourney(int activeJourneys) {
  final half = _perJourneyShare(activeJourneys) ~/ 2;
  return half > rollingReminderDays ? rollingReminderDays : half;
}

/// Slots reserved per journey for the 21:00 "streak at risk" alert.
int maxAtRiskSlotsPerJourney(int activeJourneys) => maxReminderSlotsPerJourney(activeJourneys);
