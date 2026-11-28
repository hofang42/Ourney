import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../data/group_daily_checkins_provider.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_progress.dart';
import 'journey_title.dart';
import 'run_stats.dart';

/// Numbers the end-of-journey story is built from (Figma
/// `wrappedPagesFor`), taken from the caller's own check-ins.
class WrappedStats {
  const WrappedStats({
    required this.days,
    required this.moments,
    required this.total,
    required this.streak,
    required this.totalKm,
    required this.photos,
    required this.lastCaption,
    required this.lastPlace,
    required this.pace,
    this.weights = const [],
    this.coupleSlots = const [],
  });

  factory WrappedStats.from(JourneyProgress p) {
    final dates = p.checkInsByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    final perDay = [for (final d in dates) p.checkInsByDate[d]!];
    // Every photo counts (several a day since `0014`, B-B5).
    final every = p.allCheckIns;
    final start = p.journey.startDate;
    final last = p.lastDay;
    final runStats = RunStats.from([
      for (final date in dates)
        if (!date.isBefore(start) && !date.isAfter(last)) p.dayAt(date),
    ]);
    final avgPace = runStats.avgPaceSec;
    String? place;
    for (final c in every) {
      place = c.extras.place ?? place;
    }
    String? caption;
    for (final c in every.reversed) {
      if ((c.caption ?? '').trim().isNotEmpty) {
        caption = c.caption!.trim();
        break;
      }
    }
    final coupleDate = p.couple.latestDate ?? dates.lastOrNull ?? p.today;
    return WrappedStats(
      days: perDay.length,
      moments: every.length,
      total:
          p.totalDays ??
          (p.elapsedDays > perDay.length
              ? p.elapsedDays
              : (perDay.isEmpty ? 1 : perDay.length)),
      streak: p.journey.origin == JourneyOrigin.imported
          ? null
          : p.summary.best,
      totalKm: runStats.totalKm,
      photos: perDay,
      lastCaption: caption,
      lastPlace: place,
      pace: avgPace == null ? null : formatPace(avgPace),
      weights: [for (final d in dates) ?latestMetric(p.checkInsOn(d))],
      coupleSlots: p.couple.slotsOn(
        coupleDate,
        ownPhoto: p.checkInsByDate[coupleDate],
      ),
    );
  }

  /// Distinct check-in days.
  final int days;

  /// Photos taken (every photo of every day).
  final int moments;
  final int total;

  /// Best streak.
  final int? streak;
  final double totalKm;

  /// The latest photo of each day, oldest day first.
  final List<CheckIn> photos;
  final List<CouplePhotoSlot> coupleSlots;

  /// The latest metric value logged each day, oldest first.
  final List<double> weights;
  final String? lastCaption;
  final String? lastPlace;
  final String? pace;

  int get percent => total == 0 ? 0 : (days * 100 / total).round();

  String kmTextFor(String locale) =>
      NumberFormat('0.#', locale).format(totalKm);
}

/// The story pages of [journey]'s skin, in order (headline of each page).
List<String> wrappedPagesFor(
  JourneysL10n l10n,
  Journey journey,
  PersonaSkinId skin,
  WrappedStats s,
) {
  final summary = l10n.journeys_wrapped_moments(s.moments, s.days);
  switch (skin) {
    case PersonaSkinId.quietTransformer:
      return [
        summary,
        journey.title,
        s.streak == null
            ? l10n.journeys_wrappedPhotoDays(s.days)
            : l10n.journeys_wrapped_streak(s.streak!),
        l10n.journeys_wrapped_quietEnd,
      ];
    case PersonaSkinId.accountabilitySquad:
      return [
        summary,
        l10n.journeys_wrapped_checkIns(s.days),
        journey.title,
        l10n.journeys_wrapped_squadEnd,
      ];
    case PersonaSkinId.memoryCollectors:
      return [
        summary,
        l10n.journeys_wrapped_frames(s.days),
        _range(journey),
        (s.lastPlace ?? '').isNotEmpty ? s.lastPlace! : journey.title,
      ];
    case PersonaSkinId.coupleRituals:
      return [
        summary,
        journey.title,
        l10n.journeys_wrapped_daysTogether(s.total),
        s.lastCaption ?? l10n.journeys_wrapped_coupleFallback,
      ];
    case PersonaSkinId.aestheticFlexer:
      final isRun = isRunJourney(journey);
      return [
        summary.toUpperCase(),
        isRun
            ? l10n.journeys_wrapped_km(s.kmTextFor(l10n.localeName))
            : l10n.journeys_wrapped_checkIns(s.days).toUpperCase(),
        (s.pace ?? '').isNotEmpty
            ? l10n.journeys_wrapped_pace(s.pace!)
            : journey.title,
        s.streak == null
            ? l10n.journeys_wrappedPhotoDays(s.days)
            : l10n.journeys_wrapped_flexStreak(s.streak!),
      ];
    case PersonaSkinId.minimalistHabit:
      return [
        summary.toUpperCase(),
        l10n.journeys_wrapped_minimalLine(
          s.days,
          s.total,
          journey.title.toUpperCase(),
        ),
      ];
  }
}

/// Headline of the summary card.
String wrappedSummaryTitle(
  JourneysL10n l10n,
  Journey journey,
  PersonaSkinId skin,
  WrappedStats s,
) => switch (skin) {
  PersonaSkinId.quietTransformer => l10n.journeys_wrapped_sumQuiet(s.total),
  PersonaSkinId.accountabilitySquad => l10n.journeys_wrapped_sumSquad(
    s.days,
    s.total,
  ),
  PersonaSkinId.memoryCollectors =>
    titleStatesLength(journey.title)
        ? journey.title.toUpperCase()
        : l10n.journeys_wrapped_sumMemory(s.total, journey.title.toUpperCase()),
  PersonaSkinId.coupleRituals => l10n.journeys_wrapped_sumCouple(
    s.total,
    s.moments,
  ),
  PersonaSkinId.aestheticFlexer =>
    isRunJourney(journey)
        ? l10n.journeys_wrapped_sumFlexer(s.total, s.kmTextFor(l10n.localeName))
        : l10n.journeys_wrapped_sumSquad(s.days, s.total),
  PersonaSkinId.minimalistHabit => l10n.journeys_wrapped_sumMinimal(
    s.days,
    s.total,
    s.percent,
  ),
};

String _range(Journey j) {
  String d(LocalDate x) =>
      '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}';
  final end = j.endDate;
  return end == null ? d(j.startDate) : '${d(j.startDate)} – ${d(end)}';
}
