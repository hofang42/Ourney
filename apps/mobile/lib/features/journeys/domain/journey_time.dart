import 'package:ourney_core/ourney_core.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Loads the IANA database once (pure Dart, no platform channel).
void ensureTimeZonesLoaded() {
  if (!tz.timeZoneDatabase.isInitialized) tzdata.initializeTimeZones();
}

/// True when [timezone] is a known IANA zone name.
bool isKnownTimezone(String timezone) {
  ensureTimeZonesLoaded();
  try {
    tz.getLocation(timezone);
    return true;
  } on tz.LocationNotFoundException {
    return false;
  }
}

/// UTC offset of the IANA zone [timezone] at [instant]. Falls back to the
/// device's offset when the zone is unknown, so the UI never crashes on a
/// bad value coming from the server.
Duration utcOffsetIn(String timezone, DateTime instant) {
  ensureTimeZonesLoaded();
  try {
    final location = tz.getLocation(timezone);
    return tz.TZDateTime.from(instant, location).timeZoneOffset;
  } on tz.LocationNotFoundException {
    return instant.toLocal().timeZoneOffset;
  }
}

/// Journey-local calendar date of [instant] (same rule as the server's
/// `local_date`).
LocalDate journeyLocalDate(String timezone, DateTime instant) =>
    localDateOf(instant, utcOffsetIn(timezone, instant));

/// Converts a journey-local date to a [DateTime] for display formatting only
/// (date part, no time zone meaning).
DateTime displayDate(LocalDate date) =>
    DateTime(date.year, date.month, date.day);
