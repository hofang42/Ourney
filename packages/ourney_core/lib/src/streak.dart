import 'models.dart';

/// Result of [computeStreak]. Streaks are never stored; they are derived from
/// the set of check-in local dates (docs/02-requirements-v2.md §9 #3).
class StreakSummary {
  const StreakSummary({
    required this.current,
    required this.best,
    required this.completed,
    required this.checkedInToday,
    required this.atRisk,
    required this.progress,
    required this.dayIndex,
  });

  /// Consecutive days ending today, or yesterday if today is still open.
  final int current;

  /// Longest run of consecutive check-in days.
  final int best;

  /// Distinct check-in days inside the journey window (up to today).
  final int completed;
  final bool checkedInToday;

  /// No check-in yet today while a streak is alive.
  final bool atRisk;

  /// `completed / durationDays` in 0..1; 0.0 for open-ended journeys.
  final double progress;

  /// 1-based day of the journey for `today`, clamped to 1..durationDays.
  final int dayIndex;
}

/// Pure daily/strict streak computation. Semantics follow
/// `docs/contracts/streak_vectors.json`:
///
/// * duplicates and ordering are irrelevant; dates after [today] are ignored;
/// * [best] is the longest run over all given dates (even outside the window);
/// * [current] only counts dates inside the journey window, anchored on today
///   or, when today has no check-in yet, on yesterday;
/// * [completed] counts distinct dates in `[start, start + duration - 1]`
///   (or `[start, today]` when open-ended).
StreakSummary computeStreak({
  required LocalDate start,
  int? durationDays,
  required LocalDate today,
  required Iterable<LocalDate> dates,
}) {
  final todayIdx = start.daysUntil(today);
  final lastIdx = durationDays == null ? todayIdx : durationDays - 1;

  // Day offsets from `start`, distinct, not in the future.
  final all = <int>{
    for (final d in dates)
      if (!d.isAfter(today)) start.daysUntil(d),
  };

  final sorted = all.toList()..sort();
  var best = 0;
  var run = 0;
  int? prev;
  for (final i in sorted) {
    run = (prev != null && i == prev + 1) ? run + 1 : 1;
    if (run > best) best = run;
    prev = i;
  }

  bool inWindow(int i) => i >= 0 && i <= lastIdx;
  final windowed = {for (final i in all) if (inWindow(i)) i};

  var cursor = windowed.contains(todayIdx) ? todayIdx : todayIdx - 1;
  var current = 0;
  while (windowed.contains(cursor)) {
    current++;
    cursor--;
  }

  final completed = windowed.length;
  final checkedInToday = all.contains(todayIdx);
  final progress = (durationDays == null || durationDays <= 0)
      ? 0.0
      : (completed / durationDays).clamp(0.0, 1.0);

  var dayIndex = todayIdx + 1;
  if (dayIndex < 1) dayIndex = 1;
  if (durationDays != null && dayIndex > durationDays) dayIndex = durationDays;

  return StreakSummary(
    current: current,
    best: best,
    completed: completed,
    checkedInToday: checkedInToday,
    atRisk: !checkedInToday && current > 0,
    progress: progress,
    dayIndex: dayIndex,
  );
}

/// First day that counts for a member's personal streak/progress: the later
/// of the journey start and the journey-local date of `memberships.joined_at`
/// (server: `journey_streak`, docs/02 §9.1). Late joiners are never penalised
/// for days before they joined.
LocalDate effectiveStreakStart(LocalDate journeyStart, LocalDate joinedLocalDate) =>
    joinedLocalDate.isAfter(journeyStart) ? joinedLocalDate : journeyStart;

/// Per-member streak matching SQL `journey_streak(journey, member)`. Use this
/// (not [computeStreak] with the journey start) for any member of a journey,
/// solo owners included (for them joined == start so results are identical).
///
/// * dates before [joinedLocalDate] are ignored (also for `best`);
/// * the window is `[effectiveStreakStart, journey end]`; the journey end
///   stays `journeyStart + durationDays - 1` (null = open-ended);
/// * `progress` and `dayIndex` are relative to the member's window.
///
/// [joinedLocalDate] is `localDateOf(membership.joinedAt, journeyUtcOffset)`.
StreakSummary computeMemberStreak({
  required LocalDate journeyStart,
  int? durationDays,
  required LocalDate joinedLocalDate,
  required LocalDate today,
  required Iterable<LocalDate> dates,
}) {
  final start = effectiveStreakStart(journeyStart, joinedLocalDate);
  int? memberDuration;
  if (durationDays != null) {
    final end = journeyStart.addDays(durationDays - 1);
    final n = start.daysUntil(end) + 1;
    memberDuration = n < 0 ? 0 : n;
  }
  return computeStreak(
    start: start,
    durationDays: memberDuration,
    today: today,
    dates: dates.where((d) => !d.isBefore(joinedLocalDate)),
  );
}
