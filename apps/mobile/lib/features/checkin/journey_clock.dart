import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../shared/time_zones.dart';

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

  @override
  DateTime nowUtc() => clock.now().toUtc();

  @override
  LocalDate localDate(DateTime instant, String timezone) {
    // Shared loader (latest_all + legacy aliases, no silent UTC).
    return localDateOf(instant, timeZoneOffsetAt(timezone, instant));
  }
}

final journeyClockProvider = Provider<JourneyClock>((ref) => TzJourneyClock());
