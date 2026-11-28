import 'models.dart';
import 'contracts/social.dart' show JourneyOrigin;

/// Retold journeys count only photos taken in the app toward streaks (S12).
bool countsTowardStreak(Journey journey, CheckIn checkIn) =>
    journey.origin != JourneyOrigin.imported || !checkIn.fromLibrary;

/// Latest library-photo date of a retold journey, or null for a live journey.
LocalDate? lastRetoldDate(Journey journey, Iterable<CheckIn> mine) {
  if (journey.origin != JourneyOrigin.imported) return null;
  LocalDate? last;
  for (final c in mine) {
    if (c.fromLibrary && (last == null || c.localDate.isAfter(last))) {
      last = c.localDate;
    }
  }
  return last;
}
