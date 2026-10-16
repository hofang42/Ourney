import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Journey-local calendar dates ("today" in the journey's IANA timezone),
/// used for the once-a-day rule (FR-C7) and streaks. Injectable so tests do
/// not load the timezone database.
abstract interface class JourneyClock {
  DateTime nowUtc();

  /// The journey-local date of [instant] in [timezone] (IANA name).
  LocalDate localDate(DateTime instant, String timezone);
}

extension JourneyClockToday on JourneyClock {
  LocalDate today(String timezone) => localDate(nowUtc(), timezone);
}

/// [JourneyClock] using the `timezone` package. The database (~0.5 MB) is
/// loaded on first use, i.e. on `/checkin`, never on the camera screen.
class TzJourneyClock implements JourneyClock {
  TzJourneyClock();

  static bool _loaded = false;

  @override
  DateTime nowUtc() => clock.now().toUtc();

  @override
  LocalDate localDate(DateTime instant, String timezone) {
    if (!_loaded) {
      tzdata.initializeTimeZones();
      _loaded = true;
    }
    Duration offset;
    try {
      final loc = tz.getLocation(timezone);
      offset = loc.timeZone(instant.millisecondsSinceEpoch).offset;
    } on Object {
      // Unknown zone name: fall back to the device offset.
      offset = instant.toLocal().timeZoneOffset;
    }
    return localDateOf(instant, offset);
  }
}

final journeyClockProvider = Provider<JourneyClock>((ref) => TzJourneyClock());
