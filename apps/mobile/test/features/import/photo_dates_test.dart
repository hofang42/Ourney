import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/import/data/import_draft.dart';
import 'package:ourney/features/import/data/import_photo_picker.dart';
import 'package:ourney/features/import/data/photo_dates.dart';
import 'package:ourney_core/ourney_core.dart';

import '../journeys/journeys_fakes.dart' show testNow, testTz;
import 'import_fakes.dart';

/// A minimal JPEG whose EXIF block holds only `DateTimeOriginal` (big endian).
Uint8List jpegWithExif(String dateTimeOriginal) {
  final text = [...dateTimeOriginal.codeUnits, 0]; // 20 bytes
  final tiff = BytesBuilder()
    ..add([0x4D, 0x4D, 0x00, 0x2A, 0, 0, 0, 8]) // header, IFD0 at 8
    ..add([0x00, 0x01]) // IFD0: one entry
    ..add([0x87, 0x69, 0x00, 0x04, 0, 0, 0, 1, 0, 0, 0, 26]) // ExifIFD at 26
    ..add([0, 0, 0, 0]) // no next IFD
    ..add([0x00, 0x01]) // ExifIFD: one entry
    ..add([0x90, 0x03, 0x00, 0x02, 0, 0, 0, 20, 0, 0, 0, 44]) // string at 44
    ..add([0, 0, 0, 0])
    ..add(text);
  final body = BytesBuilder()
    ..add('Exif\x00\x00'.codeUnits)
    ..add(tiff.toBytes());
  final len = body.length + 2;
  return Uint8List.fromList([
    0xFF, 0xD8, // SOI
    0xFF, 0xE1, len >> 8, len & 0xFF, // APP1
    ...body.toBytes(),
    0xFF, 0xD9, // EOI
  ]);
}

void main() {
  final today = const LocalDate(2026, 10, 16);

  group('parseExifDateTime', () {
    test('reads the wall clock and the offset', () {
      final m = parseExifDateTime('2024:02:03 09:15:30', offset: '+07:00')!;
      expect(m.date, const LocalDate(2024, 2, 3));
      expect(m.secondsOfDay, 9 * 3600 + 15 * 60 + 30);
      expect(m.offsetMinutes, 420);
      expect(
        parseExifDateTime(
          '2024:02:03 09:15:30',
          offset: '-05:30',
        )!.offsetMinutes,
        -330,
      );
    });

    test('rejects zeroed and impossible times', () {
      expect(parseExifDateTime(null), isNull);
      expect(parseExifDateTime('0000:00:00 00:00:00'), isNull);
      expect(parseExifDateTime('2024:02:31 10:00:00'), isNull);
      expect(parseExifDateTime('not a date'), isNull);
      expect(parseExifDateTime('2024:02:03 09:15:30')!.offsetMinutes, isNull);
    });

    test('reads DateTimeOriginal out of real JPEG bytes', () async {
      final m = await readExifMoment(jpegWithExif('2023:07:04 18:30:00'));
      expect(m!.date, const LocalDate(2023, 7, 4));
      expect(m.secondsOfDay, 18 * 3600 + 30 * 60);
    });

    test('a JPEG without EXIF has no capture time', () async {
      expect(
        await readExifMoment(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9])),
        isNull,
      );
    });
  });

  group('resolvePhotoMoment fallbacks', () {
    PhotoMoment? resolve({ExifMoment? exif, DateTime? modified}) =>
        resolvePhotoMoment(
          exif: exif,
          modified: modified,
          now: DateTime(2026, 10, 16, 12),
          today: today,
        );

    test('EXIF wins over the file time', () {
      final m = resolve(
        exif: parseExifDateTime('2024:02:03 09:00:00'),
        modified: DateTime(2020, 1, 1),
      )!;
      expect(m.source, PhotoDateSource.exif);
      expect(m.date, const LocalDate(2024, 2, 3));
    });

    test('a plausible file time is the fallback', () {
      final m = resolve(modified: DateTime(2021, 5, 6, 8))!;
      expect(m.source, PhotoDateSource.file);
      expect(m.date, const LocalDate(2021, 5, 6));
    });

    test('a file time near now (the picker copy) leaves it undated', () {
      expect(resolve(modified: DateTime(2026, 10, 16, 11, 50)), isNull);
    });

    test('a file time before 1990 leaves it undated', () {
      expect(resolve(modified: DateTime(1970)), isNull);
    });

    test('an EXIF date in the future or before 1990 is ignored', () {
      expect(resolve(exif: parseExifDateTime('2031:01:01 10:00:00')), isNull);
      expect(
        resolve(
          exif: parseExifDateTime('1980:01:01 10:00:00'),
          modified: DateTime(2022, 3, 3),
        )!.source,
        PhotoDateSource.file,
      );
    });
  });

  group('same-day ordering', () {
    const date = LocalDate(2024, 2, 3);
    DateTime at(int sec, int pos, {DateTime? now}) => importCapturedAt(
      date: date,
      secondsOfDay: sec,
      timezone: testTz,
      now: now ?? testNow,
      position: pos,
    );

    test('EXIF times order the photos, noon plus index otherwise', () {
      expect(at(9 * 3600, 0).isBefore(at(10 * 3600, 1)), isTrue);
      expect(
        at(importNoonSeconds, 0).isBefore(at(importNoonSeconds + 1, 1)),
        isTrue,
      );
      // Noon in Ho Chi Minh City is 05:00 UTC.
      expect(at(importNoonSeconds, 0), DateTime.utc(2024, 2, 3, 5));
    });

    test('equal times still get distinct, ordered instants', () {
      final a = at(9 * 3600, 0);
      final b = at(9 * 3600, 1);
      expect(a.isBefore(b), isTrue);
    });

    test('today is clamped behind now by the margin', () {
      final c = importCapturedAt(
        date: today,
        secondsOfDay: importNoonSeconds + 3000,
        timezone: testTz,
        now: testNow,
      );
      expect(c, testNow.subtract(importClampMargin));
      expect(journeyLocalDateOf(c), today);
    });

    test('the camera offset gives the true instant on the same day', () {
      final c = importCapturedAt(
        date: date,
        secondsOfDay: 9 * 3600,
        timezone: testTz,
        now: testNow,
        offsetMinutes: 420,
      );
      expect(c, DateTime.utc(2024, 2, 3, 2));
    });

    test('several photos today stay strictly ordered after the clamp', () {
      // Noon + 50 min is past the clamp limit (11:45); the earlier one is not.
      final times = [
        importCapturedAt(
          date: today,
          secondsOfDay: 9 * 3600,
          timezone: testTz,
          now: testNow,
          position: 0,
        ),
        for (var i = 1; i < 6; i++)
          importCapturedAt(
            date: today,
            secondsOfDay: importNoonSeconds + 3000 + i * 10,
            timezone: testTz,
            now: testNow,
            position: i,
          ),
      ];
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue, reason: 'photo $i');
      }
      expect(times.last.isBefore(testNow), isTrue);
    });

    test('draft photos sort by date, time, then picking order', () {
      final list = <DraftPhoto>[];
      addPickedPhotos(
        list,
        [
          fakePhoto('c', taken: DateTime(2024, 2, 3, 9), size: 3),
          fakePhoto('a', taken: DateTime(2024, 2, 2, 9), size: 1),
          fakePhoto('b', taken: DateTime(2024, 2, 3, 9), size: 2),
        ],
        now: testNow,
        today: today,
      );
      expect([for (final p in datedSorted(list)) p.path], ['a', 'c', 'b']);
    });
  });

  group('picking', () {
    test('duplicates are skipped by content hash and by EXIF time + size', () {
      final list = <DraftPhoto>[];
      final r = addPickedPhotos(
        list,
        [
          fakePhoto('a', fingerprint: 'h1'),
          fakePhoto('a2', fingerprint: 'h1'),
          fakePhoto('b', taken: DateTime(2024, 1, 1, 8), size: 10),
          fakePhoto('b2', taken: DateTime(2024, 1, 1, 8), size: 10),
          fakePhoto('c', taken: DateTime(2024, 1, 1, 8), size: 11),
        ],
        now: testNow,
        today: today,
      );
      expect(r.added, 3);
      expect(r.duplicates, 2);
    });

    test('the list stops at the cap', () {
      final list = <DraftPhoto>[];
      final r = addPickedPhotos(
        list,
        [for (var i = 0; i < 205; i++) fakePhoto('p$i')],
        now: testNow,
        today: today,
      );
      expect(list, hasLength(importMaxPhotos));
      expect(r.overLimit, 5);
    });
  });

  group('range and timeline', () {
    DraftPhoto photo(int order, LocalDate? d) => DraftPhoto(
      id: 'id$order',
      path: 'p$order',
      dedupeKey: 'k$order',
      order: order,
      date: d,
    );

    test('the range follows the dated photos', () {
      final r = dateRangeOf([
        photo(0, const LocalDate(2024, 2, 6)),
        photo(1, const LocalDate(2024, 2, 3)),
        photo(2, null),
      ])!;
      expect(r.first, const LocalDate(2024, 2, 3));
      expect(r.last, const LocalDate(2024, 2, 6));
    });

    test('undated blocks, and so does a span over 366 days', () {
      expect(timelineIssue([]), TimelineIssue.noPhotos);
      expect(timelineIssue([photo(0, null)]), TimelineIssue.undated);
      expect(
        timelineIssue([
          photo(0, const LocalDate(2020, 1, 1)),
          photo(1, const LocalDate(2021, 1, 2)),
        ]),
        TimelineIssue.tooLong,
      );
      expect(
        timelineIssue([
          photo(0, const LocalDate(2020, 1, 1)),
          photo(1, const LocalDate(2020, 12, 31)),
        ]),
        isNull,
      );
    });

    test('runs of empty days collapse to one row', () {
      final rows = buildTimeline([
        photo(0, const LocalDate(2024, 2, 1)),
        photo(1, const LocalDate(2024, 2, 1)),
        photo(2, const LocalDate(2024, 2, 10)),
        photo(3, const LocalDate(2024, 2, 11)),
        photo(4, null),
      ]);
      expect(rows.first, isA<UndatedHeaderRow>());
      final gaps = rows.whereType<GapRow>().toList();
      expect(gaps, hasLength(1));
      expect(gaps.single.days, 8);
      expect(gaps.single.firstDay, 2);
      expect(rows.whereType<DayHeaderRow>().map((r) => r.day), [1, 10, 11]);
    });
  });

  test('a manual date resets the time of day and the offset', () {
    final p = DraftPhoto(
      id: 'x',
      path: 'x',
      dedupeKey: 'x',
      order: 3,
      date: const LocalDate(2024, 1, 1),
      secondsOfDay: 100,
      offsetMinutes: 60,
      source: PhotoDateSource.exif,
    )..setDate(const LocalDate(2024, 1, 5));
    expect(p.date, const LocalDate(2024, 1, 5));
    expect(p.secondsOfDay, importNoonSeconds + 3);
    expect(p.offsetMinutes, isNull);
    expect(p.source, PhotoDateSource.manual);
  });
}

LocalDate journeyLocalDateOf(DateTime instant) {
  final local = instant.add(const Duration(hours: 7));
  return LocalDate(local.year, local.month, local.day);
}
