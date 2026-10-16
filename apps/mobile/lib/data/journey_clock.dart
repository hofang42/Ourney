import 'package:ourney_core/ourney_core.dart';

import '../shared/time_zones.dart';

/// UTC offset of IANA zone [timezone] at [instant].
typedef UtcOffsetResolver = Duration Function(
  String timezone,
  DateTime instant,
);

/// Journey-local dates (server: `local_date(captured_at, journeys.timezone)`).
class JourneyClock {
  JourneyClock({DateTime Function()? now, UtcOffsetResolver? offsetOf})
    : now = now ?? DateTime.now,
      _offsetOf = offsetOf ?? ianaOffset;

  final DateTime Function() now;
  final UtcOffsetResolver _offsetOf;

  LocalDate localDate(DateTime instant, String timezone) =>
      localDateOf(instant, _offsetOf(timezone, instant));

  LocalDate today(String timezone) => localDate(now(), timezone);
}

/// Offset from the bundled tz database (shared loader in
/// lib/shared/time_zones.dart: lazy, legacy aliases, logged guess for
/// unknown zones instead of a silent fallback).
Duration ianaOffset(String timezone, DateTime instant) =>
    timeZoneOffsetAt(timezone, instant);
