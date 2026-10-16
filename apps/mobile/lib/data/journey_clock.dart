import 'package:ourney_core/ourney_core.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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

bool _tzReady = false;

/// Offset from the bundled tz database (loaded lazily on first use so app
/// start stays fast). Unknown zones fall back to the device offset.
Duration ianaOffset(String timezone, DateTime instant) {
  if (!_tzReady) {
    tzdata.initializeTimeZones();
    _tzReady = true;
  }
  try {
    final location = tz.getLocation(timezone);
    return location.timeZone(instant.toUtc().millisecondsSinceEpoch).offset;
  } on Object {
    return instant.toLocal().timeZoneOffset;
  }
}
