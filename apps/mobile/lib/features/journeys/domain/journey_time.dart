import 'package:ourney_core/ourney_core.dart';

import '../../../shared/time_zones.dart';

export '../../../shared/time_zones.dart'
    show canonicalTimeZoneName, ensureTimeZonesLoaded;

/// True when [timezone] is a known IANA zone name (legacy aliases such as
/// `Asia/Saigon` included).
bool isKnownTimezone(String timezone) => isKnownTimeZone(timezone);

/// UTC offset of the IANA zone [timezone] at [instant]. Legacy names map to
/// their canonical zone; an unknown name (bad server value) uses the logged
/// best guess of [resolveTimeZone], so the UI never crashes.
Duration utcOffsetIn(String timezone, DateTime instant) =>
    timeZoneOffsetAt(timezone, instant);

/// Journey-local calendar date of [instant] (same rule as the server's
/// `local_date`).
LocalDate journeyLocalDate(String timezone, DateTime instant) =>
    localDateOf(instant, utcOffsetIn(timezone, instant));

/// Converts a journey-local date to a [DateTime] for display formatting only
/// (date part, no time zone meaning).
DateTime displayDate(LocalDate date) =>
    DateTime(date.year, date.month, date.day);
