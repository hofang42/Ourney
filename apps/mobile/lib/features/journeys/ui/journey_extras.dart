import 'package:flutter/widgets.dart';
import 'package:ourney_core/ourney_core.dart';

import '../l10n/generated/journeys_localizations.dart';

String _kmText(double km) =>
    km == km.roundToDouble() ? km.toInt().toString() : km.toStringAsFixed(1);

/// Human readable parts of a check-in's per-skin extras, in a stable order
/// (mood, study time, place, dish, cook, hearts, km, pace). Empty when none.
List<String> journeyExtrasParts(BuildContext context, CheckInExtras e) {
  final l10n = JourneysL10n.of(context);
  final mood = switch (e.mood) {
    'light' => l10n.journeys_extraMoodLight,
    'normal' => l10n.journeys_extraMoodNormal,
    'tired' => l10n.journeys_extraMoodTired,
    final other => other,
  };
  return [
    ?mood,
    if (e.minutes != null) l10n.journeys_extraMinutes(e.minutes!),
    ?e.place,
    ?e.dish,
    if (e.cook != null) l10n.journeys_extraCook(e.cook!),
    if (e.hearts != null) l10n.journeys_extraHearts(e.hearts!),
    if (e.km != null) l10n.journeys_extraKm(_kmText(e.km!)),
    if (e.pace != null) l10n.journeys_extraPace(e.pace!),
  ];
}
