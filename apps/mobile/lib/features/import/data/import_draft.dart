import 'package:ourney_core/ourney_core.dart';
import 'package:uuid/uuid.dart';

import 'import_job.dart';
import 'import_photo_picker.dart';
import 'photo_dates.dart';

/// One photo in the flow before it is saved. [id] becomes the id of the
/// check-in the photo turns into (see [ImportJobPhoto.id]).
class DraftPhoto {
  DraftPhoto({
    required this.id,
    required this.path,
    required this.dedupeKey,
    required this.order,
    this.date,
    this.secondsOfDay = importNoonSeconds,
    this.offsetMinutes,
    this.source,
  });

  final String id;
  final String path;
  final String dedupeKey;

  /// Picking order; never reused, so sorting stays stable.
  final int order;

  /// Raw editing text; normalized only when building the durable job.
  String? caption;

  /// Null while the photo has no usable date (the "undated" bucket).
  LocalDate? date;
  int secondsOfDay;
  int? offsetMinutes;
  PhotoDateSource? source;

  /// Step 1 selection (step 2 can drop a photo for good).
  bool selected = true;

  /// A new date typed in by the person: noon plus the picking order keeps
  /// photos of one day in the order they were picked.
  void setDate(LocalDate d) {
    date = d;
    secondsOfDay = importNoonSeconds + order;
    offsetMinutes = null;
    source = PhotoDateSource.manual;
  }
}

/// Result of adding a pick to the list.
class AddPhotosResult {
  const AddPhotosResult({
    required this.added,
    required this.duplicates,
    required this.overLimit,
  });

  final int added;
  final int duplicates;

  /// Photos left out because the list is full.
  final int overLimit;
}

/// Adds [picked] to [list] (in place): duplicates (same content, or same
/// capture time and size) are skipped, the list stops at [importMaxPhotos],
/// and each photo gets its date from EXIF, else a plausible file time.
AddPhotosResult addPickedPhotos(
  List<DraftPhoto> list,
  List<ImportPhoto> picked, {
  required DateTime now,
  required LocalDate today,
  String Function()? newId,
}) {
  final id = newId ?? () => const Uuid().v4();
  final seen = {for (final p in list) p.dedupeKey};
  var order = list.isEmpty ? 0 : list.map((p) => p.order).reduce(_max) + 1;
  var added = 0;
  var dupes = 0;
  var over = 0;
  for (final p in picked) {
    if (!seen.add(p.dedupeKey)) {
      dupes++;
      continue;
    }
    if (list.length >= importMaxPhotos) {
      over++;
      continue;
    }
    final moment = resolvePhotoMoment(
      exif: p.exif,
      modified: p.modified,
      now: now,
      today: today,
    );
    list.add(
      DraftPhoto(
        id: id(),
        path: p.path,
        dedupeKey: p.dedupeKey,
        order: order,
        date: moment?.date,
        secondsOfDay: secondsOfDayFor(moment, order),
        offsetMinutes: moment?.offsetMinutes,
        source: moment?.source,
      ),
    );
    order++;
    added++;
  }
  return AddPhotosResult(added: added, duplicates: dupes, overLimit: over);
}

int _max(int a, int b) => a > b ? a : b;

/// Why the timeline cannot go on to the details yet.
enum TimelineIssue { noPhotos, undated, tooLong }

/// Chosen photos in timeline order: date, then time of day, then picking
/// order. Undated photos are left out.
List<DraftPhoto> datedSorted(Iterable<DraftPhoto> photos) {
  final dated = [
    for (final p in photos)
      if (p.date != null) p,
  ];
  dated.sort((a, b) {
    final c = a.date!.compareTo(b.date!);
    if (c != 0) return c;
    final t = a.secondsOfDay.compareTo(b.secondsOfDay);
    return t != 0 ? t : a.order.compareTo(b.order);
  });
  return dated;
}

/// First and last date of the dated photos (the journey's range), or null.
({LocalDate first, LocalDate last})? dateRangeOf(Iterable<DraftPhoto> photos) {
  final dated = datedSorted(photos);
  if (dated.isEmpty) return null;
  return (first: dated.first.date!, last: dated.last.date!);
}

TimelineIssue? timelineIssue(Iterable<DraftPhoto> photos) {
  final chosen = photos.toList();
  if (chosen.isEmpty) return TimelineIssue.noPhotos;
  if (chosen.any((p) => p.date == null)) return TimelineIssue.undated;
  final range = dateRangeOf(chosen)!;
  if (range.first.daysUntil(range.last) + 1 > importMaxDays) {
    return TimelineIssue.tooLong;
  }
  return null;
}

/// One row of the timeline list. The list is built lazily from these.
sealed class TimelineRow {
  const TimelineRow();
}

/// "No date yet" heading with the number of undated photos.
class UndatedHeaderRow extends TimelineRow {
  const UndatedHeaderRow(this.count);
  final int count;
}

class UndatedPhotoRow extends TimelineRow {
  const UndatedPhotoRow(this.photo);
  final DraftPhoto photo;
}

class DayHeaderRow extends TimelineRow {
  const DayHeaderRow({
    required this.day,
    required this.date,
    required this.count,
  });
  final int day;
  final LocalDate date;
  final int count;
}

class DayPhotoRow extends TimelineRow {
  const DayPhotoRow(this.photo);
  final DraftPhoto photo;
}

/// A run of days with no photo, collapsed to one row.
class GapRow extends TimelineRow {
  const GapRow({required this.firstDay, required this.days});
  final int firstDay;
  final int days;
}

/// Rows for the timeline: the undated bucket first (it blocks Next), then
/// every day that has photos with runs of empty days collapsed to one row.
List<TimelineRow> buildTimeline(Iterable<DraftPhoto> photos) {
  final chosen = photos.toList();
  final rows = <TimelineRow>[];
  final undated = [
    for (final p in chosen)
      if (p.date == null) p,
  ]..sort((a, b) => a.order.compareTo(b.order));
  if (undated.isNotEmpty) {
    rows.add(UndatedHeaderRow(undated.length));
    rows.addAll(undated.map(UndatedPhotoRow.new));
  }
  final dated = datedSorted(chosen);
  if (dated.isEmpty) return rows;
  final start = dated.first.date!;
  LocalDate? previous;
  var i = 0;
  while (i < dated.length) {
    final date = dated[i].date!;
    var j = i;
    while (j < dated.length && dated[j].date == date) {
      j++;
    }
    final day = start.daysUntil(date) + 1;
    if (previous != null) {
      final empty = previous.daysUntil(date) - 1;
      if (empty > 0) {
        rows.add(GapRow(firstDay: start.daysUntil(previous) + 2, days: empty));
      }
    }
    rows.add(DayHeaderRow(day: day, date: date, count: j - i));
    for (var k = i; k < j; k++) {
      rows.add(DayPhotoRow(dated[k]));
    }
    previous = date;
    i = j;
  }
  return rows;
}
