import 'package:ourney_core/ourney_core.dart';

import 'journey_clock.dart';

/// Celebrations after a check-in (FR-C8): confetti at a 7- or 30-day streak
/// and when the journey reaches its finish line.
enum Milestone { streak7, streak30, finish }

/// The member's streak for [journey], counted from their join date like the
/// server's `journey_streak` (falls back to the journey start when the
/// membership is not known, e.g. a solo journey in local-only mode).
StreakSummary memberStreak({
  required Journey journey,
  required Membership? membership,
  required LocalDate today,
  required Iterable<LocalDate> dates,
  required JourneyClock clock,
}) {
  final joined = membership == null
      ? journey.startDate
      : clock.localDate(membership.joinedAt, journey.timezone);
  return computeMemberStreak(
    journeyStart: journey.startDate,
    durationDays: journey.durationDays,
    joinedLocalDate: joined,
    today: today,
    dates: dates,
  );
}

/// The milestone reached by going from [before] to [after] with a check-in
/// on [day], or null. A replacement of today's photo never celebrates again.
///
/// * finish: the check-in is on the journey's last day, or it completes the
///   last missing day of a fixed-length journey;
/// * otherwise the current streak just reached 30, or 7.
Milestone? detectMilestone({
  required Journey journey,
  required StreakSummary before,
  required StreakSummary after,
  required LocalDate day,
  required bool replaced,
}) {
  if (replaced || before.checkedInToday || !after.checkedInToday) return null;
  final duration = journey.durationDays;
  final end = journey.endDate;
  if (duration != null && end != null) {
    final completesAll =
        before.completed < duration && after.completed >= duration;
    if (day == end || completesAll) return Milestone.finish;
  }
  for (final (days, milestone) in const [
    (30, Milestone.streak30),
    (7, Milestone.streak7),
  ]) {
    if (before.current < days && after.current >= days) return milestone;
  }
  return null;
}

/// What the success screen shows after [CheckInRepository.submit].
class CheckInOutcome {
  const CheckInOutcome({
    required this.checkIn,
    required this.streakBefore,
    required this.streakAfter,
    required this.replaced,
    this.milestone,
  });

  final CheckIn checkIn;
  final int streakBefore;
  final int streakAfter;

  /// Today's earlier check-in was replaced (FR-C7).
  final bool replaced;
  final Milestone? milestone;
}
