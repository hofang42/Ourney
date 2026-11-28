import 'dart:async';
import 'dart:math' as math;

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../l10n/generated/journeys_localizations.dart';
import 'journey_title.dart';
import 'run_stats.dart';
import 'wrapped_stats.dart';

export 'wrapped_stats.dart';

enum WrappedSignatureKind {
  weight,
  mood,
  minutes,
  places,
  couple,
  run,
  habit,
  highlights,
}

class WrappedBeat {
  const WrappedBeat({
    required this.id,
    required this.eyebrow,
    required this.headline,
    this.sub,
    this.duration,
    this.signatureKind,
  });

  final String id;
  final String eyebrow;
  final String headline;
  final String? sub;
  final Duration? duration;
  final WrappedSignatureKind? signatureKind;

  String get semanticsLabel => [eyebrow, headline, ?sub].join('\n');
}

final _wrappedDateSymbols = initializeDateFormatting();

String formatWrappedDate(LocalDate date, String localeName) {
  // Non-widget callers can build the story before Flutter loads its delegates.
  unawaited(_wrappedDateSymbols);
  final pattern = Intl.shortLocale(localeName) == 'vi' ? 'dd/MM' : 'MMM d';
  return DateFormat(
    pattern,
    localeName,
  ).format(DateTime.utc(date.year, date.month, date.day));
}

List<WrappedBeat> wrappedBeatsFor(
  JourneysL10n l10n,
  Journey journey,
  PersonaSkinId skin,
  WrappedStats stats, {
  required String localeName,
  int reactionCount = 0,
}) {
  String date(LocalDate value) => formatWrappedDate(value, localeName);
  final start = journey.startDate;
  final end = stats.lastDay ?? journey.endDate ?? start;
  final reason = _dnaText(journey, 'reason');
  final trophy = _dnaText(journey, 'trophy');
  final firstPhoto = stats.photos.firstOrNull;
  final busiest = stats.busiestDay;
  final note = stats.noteCaption;
  final signature = _signatureBeat(
    l10n,
    journey,
    skin,
    stats,
    date,
    reactionCount,
  );
  return [
    WrappedBeat(
      id: 'open',
      eyebrow: l10n.journeys_wrapped_eyebrowOpen(date(start)),
      headline: journey.title,
      sub: _lines([
        l10n.journeys_wrapped_openSpan(
          math.max(1, start.daysUntil(end) + 1),
          date(start),
          date(end),
        ),
        if (reason != null) l10n.journeys_wrapped_openReason(reason),
      ]),
      duration: const Duration(milliseconds: 3500),
    ),
    if (firstPhoto != null)
      WrappedBeat(
        id: 'first',
        eyebrow: l10n.journeys_wrapped_eyebrowFirst,
        headline: journey.origin == JourneyOrigin.imported
            ? l10n.journeys_wrapped_firstHeadlineImported(
                date(firstPhoto.localDate),
              )
            : l10n.journeys_wrapped_firstHeadline(date(firstPhoto.localDate)),
        sub: _lines([
          if (stats.photos.length <= 3)
            l10n.journeys_wrapped_firstFew(stats.photos.length),
          if (stats.firstCaption case final caption?) caption.value,
        ]),
        duration: const Duration(milliseconds: 4500),
      ),
    if (stats.photos.length >= 4)
      WrappedBeat(
        id: 'roll',
        eyebrow: l10n.journeys_wrapped_eyebrowRoll,
        headline: l10n.journeys_wrapped_moments(stats.moments, stats.days),
        sub: busiest == null
            ? null
            : l10n.journeys_wrapped_rollBusiest(
                date(busiest.date),
                busiest.photoCount,
              ),
        duration: const Duration(milliseconds: 6500),
      ),
    ?signature,
    if (note != null)
      WrappedBeat(
        id: 'note',
        eyebrow: l10n.journeys_wrapped_eyebrowNote(date(note.date)),
        headline: note.value,
        duration: const Duration(seconds: 5),
      ),
    WrappedBeat(
      id: 'finish',
      eyebrow: l10n.journeys_wrapped_eyebrowFinish,
      headline: journey.title,
      sub: _lines([
        if (stats.days > 0)
          l10n.journeys_wrapped_finishCount(stats.days, stats.moments),
        if (trophy != null) l10n.journeys_wrapped_finishTrophy(trophy),
      ]),
    ),
  ];
}

WrappedBeat? _signatureBeat(
  JourneysL10n l10n,
  Journey journey,
  PersonaSkinId skin,
  WrappedStats stats,
  String Function(LocalDate) date,
  int reactionCount,
) {
  final lines = <String>[];
  WrappedSignatureKind? kind;
  switch (skin) {
    case PersonaSkinId.quietTransformer:
      if (stats.weights.length >= 2) {
        kind = WrappedSignatureKind.weight;
        lines.add(l10n.journeys_wrapped_sigQuietWeight(stats.weights.length));
      } else if (stats.moodLightDays >= 3) {
        kind = WrappedSignatureKind.mood;
        lines.add(l10n.journeys_wrapped_sigQuietMood(stats.moodLightDays));
      }
    case PersonaSkinId.accountabilitySquad:
      if (stats.minutesTotal > 0) {
        kind = WrappedSignatureKind.minutes;
        lines.add(
          l10n.journeys_wrapped_sigSquadTime(
            stats.minutesTotal ~/ 60,
            stats.minutesTotal % 60,
            stats.minutesSessions,
          ),
        );
        if (stats.minutesLongest case final longest?) {
          lines.add(
            l10n.journeys_wrapped_sigSquadLongest(
              longest.value,
              date(longest.date),
            ),
          );
        }
      }
    case PersonaSkinId.memoryCollectors:
      final places = stats.placesInOrder;
      if (places.length >= 2) {
        kind = WrappedSignatureKind.places;
        lines.add(
          l10n.journeys_wrapped_sigMemoryPlaces(
            places.length,
            places.first,
            places.last,
          ),
        );
      }
    case PersonaSkinId.coupleRituals:
      if (stats.couplePairedDays.length >= 2) {
        kind = WrappedSignatureKind.couple;
        lines.add(
          l10n.journeys_wrapped_sigCoupleDays(stats.couplePairedDays.length),
        );
        if (journey.dna?['ritual'] == 'cook' && stats.coupleCookSplit != null) {
          final split = stats.coupleCookSplit!;
          lines.add(
            l10n.journeys_wrapped_sigCoupleCook(
              split.selfName,
              split.self,
              split.partnerName,
              split.partner,
            ),
          );
        }
        if (stats.coupleFiveHeartDishes > 0) {
          lines.add(
            l10n.journeys_wrapped_sigCoupleHearts(stats.coupleFiveHeartDishes),
          );
        }
      }
    case PersonaSkinId.aestheticFlexer:
      if (isRunJourney(journey)) {
        if (stats.totalKm > 0) {
          kind = WrappedSignatureKind.run;
          lines.add(
            l10n.journeys_wrapped_sigFlexerKm(
              stats.kmTextFor(l10n.localeName),
              stats.runSessions == 0 ? stats.days : stats.runSessions,
            ),
          );
          if (stats.fastestPace case final pace?) {
            lines.add(
              l10n.journeys_wrapped_sigFlexerPace(pace.value, date(pace.date)),
            );
          }
        }
      } else if (stats.minutesTotal > 0) {
        kind = WrappedSignatureKind.minutes;
        lines.add(
          l10n.journeys_wrapped_sigFlexerMinutes(
            stats.minutesSessions,
            stats.minutesTotal ~/ 60,
            stats.minutesTotal % 60,
          ),
        );
      }
    case PersonaSkinId.minimalistHabit:
      if (stats.days > 0) {
        kind = WrappedSignatureKind.habit;
        final habit = _dnaText(journey, 'habit');
        lines.add(
          stats.showRatio
              ? [
                  l10n.journeys_wrapped_sigRatio(stats.days, stats.total),
                  ?habit,
                ].join(' · ')
              : habit == null
              ? l10n.journeys_wrapped_sigMinimalDays(stats.days)
              : l10n.journeys_wrapped_sigMinimalDaysHabit(stats.days, habit),
        );
      }
  }
  if (journey.origin != JourneyOrigin.imported && (stats.streak ?? 0) >= 2) {
    lines.add(l10n.journeys_wrapped_sigLongestStreak(stats.streak!));
  }
  if (reactionCount > 0 &&
      (skin == PersonaSkinId.accountabilitySquad ||
          skin == PersonaSkinId.coupleRituals)) {
    lines.add(l10n.journeys_wrapped_sigReactions(reactionCount));
  }
  if (lines.isEmpty) return null;
  return WrappedBeat(
    id: 'signature',
    eyebrow: l10n.journeys_wrapped_eyebrowSignature,
    headline: lines.first,
    sub: _lines(lines.skip(1)),
    duration: const Duration(milliseconds: 5500),
    signatureKind: kind ?? WrappedSignatureKind.highlights,
  );
}

String? _dnaText(Journey journey, String key) {
  final value = journey.dna?[key];
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}

String? _lines(Iterable<String> lines) =>
    lines.isEmpty ? null : lines.join('\n');

/// Headline of the summary card, also used by the share caption.
String wrappedSummaryTitle(
  JourneysL10n l10n,
  Journey journey,
  PersonaSkinId skin,
  WrappedStats s,
) => switch (skin) {
  PersonaSkinId.quietTransformer => l10n.journeys_wrapped_sumQuiet(s.total),
  PersonaSkinId.accountabilitySquad => _summaryCheckIns(l10n, s),
  PersonaSkinId.memoryCollectors =>
    titleStatesLength(journey.title)
        ? journey.title.toUpperCase()
        : l10n.journeys_wrapped_sumMemory(s.total, journey.title.toUpperCase()),
  PersonaSkinId.coupleRituals => l10n.journeys_wrapped_sumCouple(
    s.total,
    s.moments,
  ),
  PersonaSkinId.aestheticFlexer =>
    isRunJourney(journey) && s.totalKm > 0
        ? l10n.journeys_wrapped_sumFlexer(s.total, s.kmTextFor(l10n.localeName))
        : _summaryCheckIns(l10n, s),
  PersonaSkinId.minimalistHabit =>
    s.showRatio
        ? l10n.journeys_wrapped_sumMinimal(s.days, s.total, s.percent)
        : l10n.journeys_wrapped_sumMinimalCount(
            s.days,
            journey.title.toUpperCase(),
          ),
};

String _summaryCheckIns(JourneysL10n l10n, WrappedStats stats) =>
    stats.showRatio
    ? l10n.journeys_wrapped_sumSquad(stats.days, stats.total)
    : l10n.journeys_wrapped_sumSquadCount(stats.days);
