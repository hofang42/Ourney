import 'package:ourney_core/ourney_core.dart';

import 'checkin_clock.dart';

/// The member's streak for [journey], counted from their join date like the
/// server's `journey_streak` (falls back to the journey start when the
/// membership is not known, e.g. a solo journey in local-only mode).
StreakSummary memberStreak({
  required Journey journey,
  required Membership? membership,
  required LocalDate today,
  required Iterable<LocalDate> dates,
  required CheckinClock clock,
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
/// this check-in just reached, or null. Celebrations fire once: an extra
/// photo of a day that already counted, or a journey that was already
/// complete never celebrate again (FR-C8).
Milestone? detectMilestone({
  required Journey journey,
  required StreakSummary before,
  required StreakSummary after,
  required bool extraPhoto,
}) {
  if (extraPhoto || before.checkedInToday || !after.checkedInToday) return null;
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
    this.photoOfDay = 1,
    this.milestone,
  });

  final CheckIn checkIn;
  final int streakBefore;
  final int streakAfter;

  /// Which photo of its day this check-in is (1 = the one that counted the
  /// day). Extra same-day photos only get "Đã thêm ảnh thứ N" (FR-C8).
  final int photoOfDay;

  bool get extraPhoto => photoOfDay > 1;
  final Milestone? milestone;
}
