import 'package:ourney_core/ourney_core.dart';

import '../l10n/generated/journeys_localizations.dart';
import 'journey_progress.dart';

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
  });

  factory WrappedStats.from(JourneyProgress p) {
    final byDate = p.checkInsByDate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final all = [for (final e in byDate) e.value];
    var km = 0.0;
    String? pace;
    String? place;
    for (final c in all) {
      km += c.extras.km ?? 0;
      pace = c.extras.pace ?? pace;
      place = c.extras.place ?? place;
    }
    String? caption;
    for (final c in all.reversed) {
      if ((c.caption ?? '').trim().isNotEmpty) {
        caption = c.caption!.trim();
        break;
      }
    }
    return WrappedStats(
      days: all.length,
      moments: all.length,
      total: p.totalDays ?? (all.isEmpty ? 1 : all.length),
      streak: p.summary.best,
      totalKm: km,
      photos: all,
      lastCaption: caption,
      lastPlace: place,
      pace: pace,
    );
  }

  /// Distinct check-in days.
  final int days;

  /// Photos taken (one per day until multi-photo lands).
  final int moments;
  final int total;

  /// Best streak.
  final int streak;
  final double totalKm;

  /// Oldest first.
  final List<CheckIn> photos;
  final String? lastCaption;
  final String? lastPlace;
  final String? pace;

  int get percent => total == 0 ? 0 : (days * 100 / total).round();

  String get kmText =>
      totalKm.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
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
        l10n.journeys_wrapped_streak(s.streak),
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
      return [
        summary.toUpperCase(),
        l10n.journeys_wrapped_km(s.kmText),
        (s.pace ?? '').isNotEmpty
            ? l10n.journeys_wrapped_pace(s.pace!)
            : journey.title,
        l10n.journeys_wrapped_flexStreak(s.streak),
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
  PersonaSkinId.memoryCollectors => l10n.journeys_wrapped_sumMemory(
    s.total,
    journey.title.toUpperCase(),
  ),
  PersonaSkinId.coupleRituals => l10n.journeys_wrapped_sumCouple(
    s.total,
    s.moments,
  ),
  PersonaSkinId.aestheticFlexer => l10n.journeys_wrapped_sumFlexer(
    s.total,
    s.kmText,
  ),
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
