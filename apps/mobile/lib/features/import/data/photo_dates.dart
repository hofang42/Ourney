import 'package:ourney_core/ourney_core.dart';

import '../../../shared/time_zones.dart';

/// Most photos one retold journey takes (the picker, the timeline and the
/// upload all stay light below this).
const int importMaxPhotos = 200;

/// Longest retold journey (server: `duration_days` 1..366).
const int importMaxDays = 366;

/// Photos dated before this year carry no real date (a zeroed camera clock).
const int importMinYear = 1990;

/// A file modified this close to "now" is the picker's cache copy, not the
/// day the photo was taken.
const Duration importCacheCopyWindow = Duration(minutes: 30);

/// `captured_at` stays this far behind the clock: the server refuses a time
/// more than 10 minutes ahead of its own, and phone clocks drift.
const Duration importClampMargin = Duration(minutes: 15);

/// Noon in seconds since midnight: the time of day of a photo with no time.
const int importNoonSeconds = 12 * 3600;

/// Where a photo's date came from.
enum PhotoDateSource {
  /// The camera's `DateTimeOriginal` tag.
  exif('exif'),

  /// The file's modified time, trusted only when it is plausible.
  file('file'),

  /// Typed in by the person.
  manual('manual');

  const PhotoDateSource(this.wire);
  final String wire;

  static PhotoDateSource fromWire(String wire) =>
      values.firstWhere((v) => v.wire == wire, orElse: () => manual);
}

/// A camera wall-clock time: what the EXIF tags say, with no zone attached.
class ExifMoment {
  const ExifMoment({
    required this.date,
    required this.secondsOfDay,
    this.offsetMinutes,
  });

  final LocalDate date;
  final int secondsOfDay;

  /// `OffsetTimeOriginal` in minutes east of UTC, when the camera wrote it.
  final int? offsetMinutes;
}

final RegExp _exifDateTime = RegExp(
  r'^\s*(\d{4})[:\-](\d{2})[:\-](\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
);
final RegExp _exifOffset = RegExp(r'^\s*([+-])(\d{2}):?(\d{2})\s*$');

/// Parses `YYYY:MM:DD HH:MM:SS` (+ `OffsetTimeOriginal`, `+07:00`). Null for
/// anything that is not a real calendar time, such as the zeroed
/// `0000:00:00 00:00:00` some phones write.
ExifMoment? parseExifDateTime(String? raw, {String? offset}) {
  if (raw == null) return null;
  final m = _exifDateTime.firstMatch(raw);
  if (m == null) return null;
  final y = int.parse(m[1]!);
  final mo = int.parse(m[2]!);
  final d = int.parse(m[3]!);
  final h = int.parse(m[4]!);
  final mi = int.parse(m[5]!);
  final s = int.parse(m[6]!);
  if (y == 0 || mo < 1 || mo > 12 || d < 1 || h > 23 || mi > 59 || s > 59) {
    return null;
  }
  // Rejects 31 Feb and the like (DateTime would roll them over).
  final check = DateTime.utc(y, mo, d);
  if (check.month != mo || check.day != d) return null;
  int? minutes;
  if (offset != null) {
    final o = _exifOffset.firstMatch(offset);
    if (o != null) {
      final total = int.parse(o[2]!) * 60 + int.parse(o[3]!);
      if (total <= 14 * 60) minutes = o[1] == '-' ? -total : total;
    }
  }
  return ExifMoment(
    date: LocalDate(y, mo, d),
    secondsOfDay: h * 3600 + mi * 60 + s,
    offsetMinutes: minutes,
  );
}

/// When one photo was taken, as the timeline places it.
class PhotoMoment {
  const PhotoMoment({
    required this.date,
    required this.secondsOfDay,
    required this.source,
    this.offsetMinutes,
  });

  final LocalDate date;
  final int secondsOfDay;
  final PhotoDateSource source;
  final int? offsetMinutes;
}

bool _plausibleDate(LocalDate d, LocalDate today) =>
    d.year >= importMinYear && !d.isAfter(today);

/// The date of a picked photo, best source first:
///
/// 1. the EXIF capture time (`DateTimeOriginal`);
/// 2. the file's modified time, only when it is plausible (not before 1990,
///    not in the future, not within [importCacheCopyWindow] of [now], which is
///    when the picker copied the file);
/// 3. otherwise null: the photo is "undated" and the person must date it.
PhotoMoment? resolvePhotoMoment({
  required ExifMoment? exif,
  required DateTime? modified,
  required DateTime now,
  required LocalDate today,
}) {
  if (exif != null && _plausibleDate(exif.date, today)) {
    return PhotoMoment(
      date: exif.date,
      secondsOfDay: exif.secondsOfDay,
      offsetMinutes: exif.offsetMinutes,
      source: PhotoDateSource.exif,
    );
  }
  if (modified != null) {
    final local = modified.toLocal();
    final date = LocalDate(local.year, local.month, local.day);
    final near = local.difference(now.toLocal()).abs() <= importCacheCopyWindow;
    if (!near && _plausibleDate(date, today)) {
      return PhotoMoment(
        date: date,
        secondsOfDay: local.hour * 3600 + local.minute * 60 + local.second,
        source: PhotoDateSource.file,
      );
    }
  }
  return null;
}

/// Time of day for a photo with [date] at [index] in the list: the EXIF time
/// when it has one, else noon plus [index] seconds (so photos of one day keep
/// the order they were picked in).
int secondsOfDayFor(PhotoMoment? moment, int index) =>
    moment != null && moment.source == PhotoDateSource.exif
    ? moment.secondsOfDay
    : importNoonSeconds + index;

/// The instant of [date] + [secondsOfDay] on the wall clock of [timezone].
DateTime instantInZone(LocalDate date, int secondsOfDay, String timezone) {
  final naive = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).add(Duration(seconds: secondsOfDay));
  return naive.subtract(timeZoneOffsetAt(timezone, naive));
}

/// `captured_at` of a retold photo (what the server turns into its
/// `local_date`, so it always falls on [date] in [timezone]).
///
/// * the wall-clock time of the photo, or its true instant when the camera
///   wrote a UTC offset and that still lands on [date];
/// * plus [position] milliseconds, so photos of one day keep a stable order;
/// * never later than [now] minus [importClampMargin] (a clock that runs a bit
///   ahead would make the server refuse `invalid_captured_at`).
DateTime importCapturedAt({
  required LocalDate date,
  required int secondsOfDay,
  required String timezone,
  required DateTime now,
  int position = 0,
  int? offsetMinutes,
}) {
  var at = instantInZone(date, secondsOfDay, timezone);
  if (offsetMinutes != null) {
    final naive = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).add(Duration(seconds: secondsOfDay));
    final exact = naive.subtract(Duration(minutes: offsetMinutes));
    if (journeyLocalDate(timezone, exact) == date) at = exact;
  }
  if (journeyLocalDate(timezone, at) != date) {
    at = instantInZone(date, importNoonSeconds, timezone);
  }
  // Clamp first, then add the position: photos of one day keep a strictly
  // increasing order even when several are clamped to the same limit.
  final offset = Duration(milliseconds: position);
  final limit = now.toUtc().subtract(importClampMargin);
  if (!at.isAfter(limit)) return at.add(offset);
  if (journeyLocalDate(timezone, limit) == date) return limit.add(offset);
  // The limit slipped into yesterday: the earliest instant of the day.
  final start = instantInZone(date, 0, timezone);
  return (start.isAfter(now.toUtc()) ? at : start).add(offset);
}
