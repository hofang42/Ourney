import 'models.dart';

/// Calendar date of [instant] in a zone with fixed [utcOffset].
///
/// The app derives [utcOffset] from the timezone package for the journey's
/// IANA zone at that instant, so this stays pure and DST-agnostic.
LocalDate localDateOf(DateTime instant, Duration utcOffset) {
  final shifted = instant.toUtc().add(utcOffset);
  return LocalDate(shifted.year, shifted.month, shifted.day);
}

/// Today's local date given the current time and the zone's offset.
LocalDate localToday(DateTime nowUtc, Duration utcOffset) => localDateOf(nowUtc, utcOffset);
