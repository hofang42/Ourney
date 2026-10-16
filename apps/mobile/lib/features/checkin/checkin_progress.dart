import 'package:ourney_core/ourney_core.dart';

import 'journey_clock.dart';

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

/// The milestone (core [milestoneFor], shared with the share card) that
/// this check-in just reached, or null. Celebrations fire once: a
/// replacement of today's photo, a second check-in the same day, or a
/// journey that was already complete never celebrate again.
Milestone? detectMilestone({
  required Journey journey,
  required StreakSummary before,
  required StreakSummary after,
  required bool replaced,
}) {
  if (replaced || before.checkedInToday || !after.checkedInToday) return null;
  final milestone = milestoneFor(after, journey);
  if (milestone == Milestone.completed) {
    final duration = journey.durationDays!;
    return before.completed < duration ? milestone : null;
  }
  return milestone;
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
