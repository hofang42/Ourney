import 'models.dart';
import 'contracts/social.dart' show JourneyOrigin;

/// Caption edits require an active membership on a journey still in the cache.
/// The server applies the closing date to the photo's day, even when [today]
/// is later, as long as the journey still has active status.
bool canEditCheckInCaption({
  required CheckIn c,
  required Journey? j,
  required String me,
  required LocalDate today,
  required Membership? membership,
}) {
  if (j == null ||
      c.journeyId != j.id ||
      c.userId != me ||
      c.moderated ||
      membership == null ||
      membership.journeyId != j.id ||
      membership.userId != me ||
      !membership.isActive) {
    return false;
  }
  final end = j.endDate;
  if (j.status == JourneyStatus.active) {
    return end == null || !c.localDate.isAfter(end);
  }
  // The server checks an ended retold journey's photo against its date range.
  return j.origin == JourneyOrigin.imported &&
      j.ownerId == me &&
      end != null &&
      !c.localDate.isBefore(j.startDate) &&
      !c.localDate.isAfter(end);
}

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
