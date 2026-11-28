import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/account_reset.dart' show accountSessionResetProvider;
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/import/data/import_draft.dart';
import 'package:ourney/features/import/data/import_job.dart';
import 'package:ourney/features/import/data/import_photo_picker.dart';
import 'package:ourney/features/import/data/import_types.dart';
import 'package:ourney/features/import/ui/import_parts.dart';
import 'package:ourney/ui/ui.dart' show UiButton;
import 'package:ourney_core/ourney_core.dart';

import '../sharing/sharing_fakes.dart';
import 'import_fakes.dart';

const _second = Duration(seconds: 1);

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _tap(WidgetTester t, String k) async {
  await t.ensureVisible(_key(k));
  await t.pump();
  await t.tap(_key(k));
  await t.pumpAndSettle();
}

/// Check-ins that fail for the given capture instants (and record what
/// landed, by the id the import job gave each photo).
class FlakyCheckIns extends SubmittingCheckInRepository {
  /// Blocks the [gateAt]th attempt until [gate] completes.
  Completer<void>? gate;
  int gateAt = -1;
  final Set<DateTime> failAt = {};
  final Map<String, CheckInDraft> landed = {};
  int attempts = 0;

  @override
  Future<CheckIn> submit(CheckInDraft draft) async {
    attempts++;
    if (attempts == gateAt) await gate!.future;
    if (failAt.any((t) => draft.capturedAt.difference(t).abs() < _second)) {
      throw const OurneyException(OurneyErrorCode.offline);
    }
    landed.putIfAbsent(draft.id!, () => draft);
    return super.submit(draft);
  }
}

List<ImportPhoto> threePhotos() => [
  fakePhoto('b.jpg', taken: DateTime(2024, 2, 6, 9), size: 2),
  fakePhoto('a.jpg', taken: DateTime(2024, 2, 3, 9), size: 1),
  fakePhoto('c.jpg', taken: DateTime(2024, 2, 3, 15), size: 3),
];

bool _off(WidgetTester t, String k) =>
    t.widget<UiButton>(_key(k)).onPressed == null;

Future<void> _toDetails(WidgetTester t) async {
  await _tap(t, 'import-next');
  await _tap(t, 'import-to-details');
}

void main() {
  testWidgets('done write action opens Day 1 with the caption editor request', (
    tester,
  ) async {
    Future<void> step(String action) async {
      await tester.pump();
      await tester.ensureVisible(_key(action));
      await tester.tap(_key(action));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    final sharing = FakeSharingRepository();
    final h = await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: FlakyCheckIns(),
      picker: FakeImportPicker(threePhotos()),
    );
    await step('import-next');
    await step('import-to-details');
    await tester.enterText(_key('import-title'), 'Hoi An');
    await step('import-save');
    expect(_key('import-done-write'), findsOneWidget);
    expect(find.text('Add a few words to the journey'), findsOneWidget);
    await step('import-done-write');
    expect(
      h.location,
      '/journey/${sharing.importedDraft!.id}/day/2024-02-03?caption=edit',
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets(
    'caption row opens sheet, date control stays separate, discard warns',
    (tester) async {
      await pumpSharing(
        tester,
        location: '/import',
        picker: FakeImportPicker(threePhotos()),
      );
      await _tap(tester, 'import-next');
      await _tap(tester, 'import-row-1');
      expect(_key('import-caption-sheet'), findsOneWidget);
      expect(_key('import-date-confirm'), findsNothing);
      await tester.enterText(_key('import-caption-field'), 'Một ngày ở Hội An');
      await _tap(tester, 'import-caption-done');
      expect(find.text('Một ngày ở Hội An'), findsOneWidget);
      await _tap(tester, 'import-calendar-1');
      expect(_key('import-date-confirm'), findsOneWidget);
      await _tap(tester, 'import-date-cancel');
      await _tap(tester, 'import-back');
      await _tap(tester, 'import-back');
      expect(
        find.textContaining('Captions you wrote will be lost too.'),
        findsOneWidget,
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets('caption entered on timeline reaches the saved check-in', (
    tester,
  ) async {
    final checkIns = FlakyCheckIns();
    await pumpSharing(
      tester,
      location: '/import',
      checkIns: checkIns,
      picker: FakeImportPicker(threePhotos()),
    );
    await _tap(tester, 'import-next');
    await _tap(tester, 'import-row-1');
    await tester.enterText(
      _key('import-caption-field'),
      '  Hội An ngày ấy 😀  ',
    );
    await _tap(tester, 'import-caption-done');
    await _tap(tester, 'import-to-details');
    await tester.enterText(_key('import-title'), 'Hội An');
    await tester.pumpAndSettle();
    await _tap(tester, 'import-save');
    expect(
      checkIns.landed.values.where((d) => d.caption != null).single.caption,
      'Hội An ngày ấy 😀',
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('opens the picker at once, then timeline, details, save', (
    tester,
  ) async {
    final sharing = FakeSharingRepository();
    final checkIns = FlakyCheckIns();
    final picker = FakeImportPicker(threePhotos());
    final h = await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: checkIns,
      picker: picker,
    );
    expect(picker.picks, 1);
    expect(_key('import-photo-0'), findsOneWidget);
    expect(find.text('3 of 3 selected'), findsOneWidget);

    await _tap(tester, 'import-next');
    // The range follows the EXIF dates: 3 - 6 Feb 2024, two photos on day 1.
    expect(find.textContaining('Feb 3, 2024'), findsWidgets);
    expect(_key('import-range'), findsOneWidget);
    expect(_key('import-gap-2'), findsOneWidget);
    await _tap(tester, 'import-to-details');

    await tester.enterText(_key('import-title'), 'Hoi An');
    await tester.pumpAndSettle();
    await _tap(tester, 'import-type-weight');
    expect(_key('import-layout-quiet'), findsOneWidget);
    await _tap(tester, 'import-layout-quiet');
    await _tap(tester, 'import-continue');
    await _tap(tester, 'import-save');

    final draft = sharing.importedDraft!;
    expect(draft.title, 'Hoi An');
    expect(draft.firstDate, const LocalDate(2024, 2, 3));
    expect(draft.lastDate, const LocalDate(2024, 2, 6));
    expect(draft.templateId, TemplateId.weightLoss);
    expect(draft.layout, PersonaSkinId.quietTransformer);
    expect(draft.continues, isTrue);
    expect(draft.timezone, testTz);
    // The check-in ids are the job's photo ids, in timeline order, with the
    // EXIF times of day (09:00 and 15:00 on the 3rd, local).
    expect(checkIns.landed, hasLength(3));
    final ordered = checkIns.submitted.map((d) => d.capturedAt).toList();
    // (a position offset of a few milliseconds keeps same-day order stable)
    for (final (i, want) in [
      DateTime.utc(2024, 2, 3, 2),
      DateTime.utc(2024, 2, 3, 8),
      DateTime.utc(2024, 2, 6, 2),
    ].indexed) {
      expect(ordered[i].difference(want).abs() < _second, isTrue);
    }
    expect(ordered[0].isBefore(ordered[1]), isTrue);
    expect(checkIns.submitted.every((d) => d.fromLibrary), isTrue);
    expect(_key('import-open'), findsOneWidget);
    expect(find.text('3 photos saved'), findsOneWidget);
    await _tap(tester, 'import-open');
    expect(h.location, '/journey/${sharing.importedDraft!.id}');
  });

  testWidgets('select all and none, and the broken-image state', (
    tester,
  ) async {
    // Earlier tests used the same fake paths: start with a cold image cache.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await pumpSharing(
      tester,
      location: '/import',
      picker: FakeImportPicker(threePhotos()),
    );
    // The fake paths are not files: a broken-image state, not fake art.
    // The file read is real IO: wait for it (longer when the suite is busy).
    for (
      var i = 0;
      i < 60 && _key('import-thumb-broken').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(_key('import-thumb-broken'), findsWidgets);
    await _tap(tester, 'import-select-none');
    expect(find.text('0 of 3 selected'), findsOneWidget);
    expect(_off(tester, 'import-next'), isTrue);
    await _tap(tester, 'import-select-all');
    expect(find.text('3 of 3 selected'), findsOneWidget);
    await _tap(tester, 'import-photo-1');
    expect(find.text('2 of 3 selected'), findsOneWidget);
  });

  testWidgets('duplicates are skipped and the count is told', (tester) async {
    await pumpSharing(
      tester,
      location: '/import',
      picker: FakeImportPicker([
        fakePhoto('a.jpg', taken: DateTime(2024, 2, 3, 9), size: 1),
        fakePhoto('a-copy.jpg', taken: DateTime(2024, 2, 3, 9), size: 1),
      ]),
    );
    expect(find.text('1 of 1 selected'), findsOneWidget);
    expect(find.text('1 duplicate photo was skipped'), findsOneWidget);
  });

  testWidgets('an undated photo blocks Next until it gets a date', (
    tester,
  ) async {
    await pumpSharing(
      tester,
      location: '/import',
      picker: FakeImportPicker([
        fakePhoto('a.jpg', taken: DateTime(2026, 10, 10, 9), size: 1),
        // No EXIF and a zeroed file time: nothing dates it.
        fakePhoto('x.jpg', modified: DateTime(1970), size: 2),
      ]),
    );
    await _tap(tester, 'import-next');
    expect(_key('import-undated'), findsOneWidget);
    expect(_off(tester, 'import-to-details'), isTrue);
    expect(find.text('Set a date for all'), findsOneWidget);
    // Date it (the picker starts on today); Next opens up.
    await tester.tap(_key('import-row-1'));
    await tester.pumpAndSettle();
    await tester.tap(_key('import-date-confirm'));
    await tester.pumpAndSettle();
    expect(_key('import-undated'), findsNothing);
    expect(_off(tester, 'import-to-details'), isFalse);
  });

  testWidgets('one photo date can be edited, many can be set at once', (
    tester,
  ) async {
    final sharing = FakeSharingRepository();
    await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: FlakyCheckIns(),
      picker: FakeImportPicker(threePhotos()),
    );
    await _tap(tester, 'import-next');
    // Edit a.jpg (order 1): the picker opens on its date; OK keeps it.
    await tester.tap(_key('import-calendar-1'));
    await tester.pumpAndSettle();
    expect(_key('import-date-confirm'), findsOneWidget);
    // The wheels move the date: one step up on the day wheel is the 4th.
    await tester.drag(
      find.byWidgetPredicate((w) => '${w.key}'.contains('import-date-day')),
      const Offset(0, -48),
    );
    await tester.pumpAndSettle();
    await tester.tap(_key('import-date-confirm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Feb 4, 2024'), findsWidgets);

    // Cancel leaves the date alone.
    await tester.tap(_key('import-calendar-1'));
    await tester.pumpAndSettle();
    await tester.tap(_key('import-date-cancel'));
    await tester.pumpAndSettle();
    expect(_key('import-date-confirm'), findsNothing);
    expect(find.textContaining('Feb 4, 2024'), findsWidgets);
    expect(find.textContaining('Date taken'), findsWidgets);
    expect(find.textContaining('Set by you'), findsWidgets);

    // Bulk: select b.jpg and c.jpg, set one date for both.
    await _tap(tester, 'import-select-mode');
    await tester.tap(_key('import-row-0'));
    await tester.tap(_key('import-row-2'));
    await tester.pumpAndSettle();
    expect(find.text('Set date · 2'), findsOneWidget);
    await _tap(tester, 'import-bulk-date');
    await tester.tap(_key('import-date-confirm'));
    await tester.pumpAndSettle();
    // b and c now share the sheet's default (their own first date).
    expect(find.textContaining('Set by you'), findsNWidgets(3));
    await _tap(tester, 'import-to-details');
    await tester.enterText(_key('import-title'), 'Trip');
    await tester.pumpAndSettle();
    await _tap(tester, 'import-save');
    expect(sharing.importedDraft!.firstDate, const LocalDate(2024, 2, 4));
  });

  testWidgets('a photo can be removed from the timeline and undone (UX-22)', (
    tester,
  ) async {
    await pumpSharing(
      tester,
      location: '/import',
      picker: FakeImportPicker(threePhotos()),
    );
    await _tap(tester, 'import-next');
    await _tap(tester, 'import-remove-0');
    expect(_key('import-row-0'), findsNothing);
    expect(find.text('Day 1 · Feb 3, 2024 · 2 photos'), findsOneWidget);
    expect(find.text('Removed 1 photo.'), findsOneWidget);
    await tester.tap(_key('ui-toast-action'));
    await tester.pumpAndSettle();
    expect(_key('import-row-0'), findsOneWidget);

    // Removing the last photo kicks back to Step 1; Undo restores both the
    // photo and Step 2 (_Stage.timeline).
    await _tap(tester, 'import-select-mode');
    await tester.tap(_key('import-row-0'));
    await tester.tap(_key('import-row-1'));
    await tester.tap(_key('import-row-2'));
    await tester.pumpAndSettle();
    await _tap(tester, 'import-bulk-remove');
    expect(_key('import-empty'), findsOneWidget);
    await tester.tap(_key('ui-toast-action'));
    await tester.pumpAndSettle();
    expect(_key('import-to-details'), findsOneWidget);
    expect(_key('import-row-0'), findsOneWidget);
  });

  testWidgets('back goes one step; leaving with photos asks first', (
    tester,
  ) async {
    final h = await pumpSharing(
      tester,
      location: '/journeys',
      picker: FakeImportPicker(threePhotos()),
    );
    unawaited(h.container.read(routerProvider).push('/import'));
    await tester.pumpAndSettle();
    await _toDetails(tester);
    expect(_key('import-title'), findsOneWidget);
    await _tap(tester, 'import-back');
    expect(_key('import-to-details'), findsOneWidget);
    await _tap(tester, 'import-back');
    expect(_key('import-next'), findsOneWidget);
    expect(find.text('Leave without saving?'), findsNothing);

    await _tap(tester, 'import-back');
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(_key('import-next'), findsOneWidget);
    await _tap(tester, 'import-back');
    await _tap(tester, 'import-discard-confirm');
    expect(_key('import-next'), findsNothing);
    expect(h.location, '/journeys');
  });

  testWidgets('the system back gesture asks as well', (tester) async {
    final h = await pumpSharing(
      tester,
      location: '/journeys',
      picker: FakeImportPicker(threePhotos()),
    );
    unawaited(h.container.read(routerProvider).push('/import'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
  });

  testWidgets('the name is checked inline, with a counter and a cap', (
    tester,
  ) async {
    await pumpSharing(
      tester,
      location: '/import',
      picker: FakeImportPicker(threePhotos()),
    );
    await _toDetails(tester);
    // Save is off, and no error shows before the person touched the field.
    expect(_off(tester, 'import-save'), isTrue);
    expect(_key('import-title-error'), findsNothing);
    expect(find.text('0/$journeyTitleMax'), findsOneWidget);

    await tester.enterText(_key('import-title'), '  ');
    await tester.pumpAndSettle();
    expect(_key('import-title-error'), findsOneWidget);
    expect(_off(tester, 'import-save'), isTrue);

    await tester.enterText(_key('import-title'), 'x' * 80);
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(_key('import-title'));
    expect(field.controller!.text.length, journeyTitleMax);
    expect(_key('import-title-error'), findsNothing);
    expect(_off(tester, 'import-save'), isFalse);
    // The privacy note says only what is true.
    expect(
      find.textContaining('Only you can see this journey until you share it'),
      findsOneWidget,
    );
    // No couple type: it would need the couple skin and both names.
    expect(_key('import-type-couple'), findsNothing);
  });

  testWidgets('a failed photo is named, and retry sends only that one', (
    tester,
  ) async {
    final checkIns = FlakyCheckIns()
      // c.jpg: 15:00 on the 3rd in Ho Chi Minh City.
      ..failAt.add(DateTime.utc(2024, 2, 3, 8));
    await pumpSharing(
      tester,
      location: '/import',
      checkIns: checkIns,
      picker: FakeImportPicker(threePhotos()),
    );
    await _toDetails(tester);
    await tester.enterText(_key('import-title'), 'Trip');
    await tester.pumpAndSettle();
    await _tap(tester, 'import-save');
    expect(find.text('2 photos saved · 1 photo not saved'), findsOneWidget);
    // Not "Done." while a photo is left out.
    expect(find.text('Some photos are not saved.'), findsOneWidget);
    expect(find.text('Done.'), findsNothing);
    expect(find.text('No connection'), findsOneWidget);
    expect(checkIns.landed, hasLength(2));

    checkIns.failAt.clear();
    final before = checkIns.attempts;
    await _tap(tester, 'import-retry-failed');
    expect(checkIns.attempts, before + 1);
    expect(checkIns.landed, hasLength(3));
    expect(find.text('3 photos saved'), findsOneWidget);
    expect(_key('import-open'), findsOneWidget);
  });

  testWidgets('a kill mid-import resumes on reopening, with no new journey', (
    tester,
  ) async {
    final store = InMemoryImportJobStore();
    final job = buildImportJob(
      id: 'jobA',
      ownerId: 'u1',
      title: 'Hoi An',
      type: importTypes.first,
      layout: 'memory',
      continues: false,
      timezone: testTz,
      now: testNow,
      photos: [
        for (var i = 0; i < 3; i++)
          DraftPhoto(
            id: 'ph$i',
            path: 's$i.jpg',
            dedupeKey: 'k$i',
            order: i,
            date: LocalDate(2024, 2, 1 + i),
          ),
      ],
    );
    await store.create(job);
    await store.setPhase('jobA', ImportPhase.uploading);
    for (var i = 0; i < 3; i++) {
      await store.updatePhoto(
        'jobA',
        'ph$i',
        photoFile: 's$i.c',
        thumbFile: 's$i.t',
      );
    }
    await store.updatePhoto(
      'jobA',
      'ph0',
      state: ImportPhotoState.saved,
      clearFiles: true,
      clearSource: true,
    );
    final sharing = FakeSharingRepository();
    final checkIns = FlakyCheckIns();
    final picker = FakeImportPicker(threePhotos());
    final h = await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: checkIns,
      picker: picker,
      importStore: store,
    );
    // The launch resume finished the job on its own: the same journey, only
    // the photos that were not saved yet, nothing created twice.
    expect(checkIns.landed.keys, ['ph1', 'ph2']);
    expect(sharing.importedDraft, isNull);
    // Opening the flow now finds nothing left, so it starts fresh.
    expect(await store.get('jobA'), isNull);
    expect(picker.picks, 1);
    expect(h.location, '/import');
  });

  testWidgets('failures kept on exit come back on reopening', (tester) async {
    final store = InMemoryImportJobStore();
    await store.create(
      buildImportJob(
        id: 'jobC',
        ownerId: 'u1',
        title: 'Hoi An',
        type: importTypes.first,
        layout: 'memory',
        continues: false,
        timezone: testTz,
        now: testNow,
        photos: [
          for (var i = 0; i < 2; i++)
            DraftPhoto(
              id: 'ph$i',
              path: 's$i.jpg',
              dedupeKey: 'k$i',
              order: i,
              date: LocalDate(2024, 2, 1 + i),
            ),
        ],
      ),
    );
    await store.setPhase('jobC', ImportPhase.done);
    await store.updatePhoto('jobC', 'ph0', state: ImportPhotoState.saved);
    await store.updatePhoto(
      'jobC',
      'ph1',
      state: ImportPhotoState.failed,
      failure: ImportFailure.offline,
      photoFile: 'a',
      thumbFile: 'b',
    );
    final checkIns = FlakyCheckIns();
    final picker = FakeImportPicker(threePhotos());
    await pumpSharing(
      tester,
      location: '/import',
      checkIns: checkIns,
      picker: picker,
      importStore: store,
    );
    expect(picker.picks, 0);
    expect(find.text('1 photo saved · 1 photo not saved'), findsOneWidget);
    expect(find.text('No connection'), findsOneWidget);
    await _tap(tester, 'import-retry-failed');
    expect(checkIns.landed.keys, ['ph1']);
    expect(find.text('2 photos saved'), findsOneWidget);
  });

  testWidgets('a job killed before the journey exists creates it once', (
    tester,
  ) async {
    final store = InMemoryImportJobStore();
    await store.create(
      buildImportJob(
        id: 'jobB',
        ownerId: 'u1',
        title: 'Hoi An',
        type: importTypes.first,
        layout: 'memory',
        continues: false,
        timezone: testTz,
        now: testNow,
        photos: [
          DraftPhoto(
            id: 'ph0',
            path: 's0.jpg',
            dedupeKey: 'k0',
            order: 0,
            date: const LocalDate(2024, 2, 1),
          ),
        ],
      ),
    );
    await store.updatePhoto('jobB', 'ph0', photoFile: 'a', thumbFile: 'b');
    await store.setPhase('jobB', ImportPhase.creating);
    final sharing = FakeSharingRepository();
    final checkIns = FlakyCheckIns();
    await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: checkIns,
      importStore: store,
    );
    expect(sharing.importedDraft!.id, 'jobB');
    expect(sharing.calls.where((c) => c == 'imported'), hasLength(1));
    expect(checkIns.landed.keys, ['ph0']);
  });

  testWidgets('200 photos build lazily', (tester) async {
    await pumpSharing(
      tester,
      location: '/import',
      picker: FakeImportPicker([
        for (var i = 0; i < 200; i++)
          fakePhoto(
            'p$i.jpg',
            taken: DateTime(2024, 1, 1 + i % 28, 9, i % 60, i ~/ 60),
            size: 1000 + i,
          ),
      ]),
    );
    expect(find.text('200 of 200 selected'), findsOneWidget);
    final tiles = find.byType(ImportPhotoTile).evaluate().length;
    expect(tiles, greaterThan(0));
    expect(tiles, lessThan(60));
    await _tap(tester, 'import-next');
    final rows = find.byType(ImportTimelineTile).evaluate().length;
    expect(rows, greaterThan(0));
    expect(rows, lessThan(60));
  });

  group('entry points', () {
    final ended = testJourney(id: 'e1', status: JourneyStatus.ended);

    testWidgets('the Hub shelf tile opens the flow', (tester) async {
      final h = await pumpSharing(
        tester,
        location: '/journeys',
        journeys: FakeJourneyRepository(
          journeys: [ended],
          memberships: {ended.id: testMembership(ended)},
        ),
      );
      await _tap(tester, 'hub-segment-shelf');
      await _tap(tester, 'journeys-retell');
      expect(h.location, '/import');
      expect(_key('import-empty'), findsOneWidget);
    });

    testWidgets('the Hub menu opens the flow', (tester) async {
      final j = testJourney();
      final h = await pumpSharing(
        tester,
        location: '/journeys',
        journeys: FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: testMembership(j)},
        ),
      );
      await _tap(tester, 'journeys-new');
      await _tap(tester, 'journeys-menu-retell');
      expect(h.location, '/import');
    });

    testWidgets('the create wizard link opens the flow', (tester) async {
      final h = await pumpSharing(tester, location: '/journeys/new');
      await _tap(tester, 'create-import-link');
      expect(h.location, '/import');
    });

    testWidgets('the old /retell path redirects', (tester) async {
      final h = await pumpSharing(tester, location: '/retell');
      expect(h.location, '/import');
    });
  });

  testWidgets('a double tap on Save makes one job', (tester) async {
    final sharing = FakeSharingRepository();
    final store = InMemoryImportJobStore();
    await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: FlakyCheckIns(),
      picker: FakeImportPicker(threePhotos()),
      importStore: store,
    );
    await _toDetails(tester);
    await tester.enterText(_key('import-title'), 'Trip');
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('import-save'));
    await tester.pump();
    await tester.tap(_key('import-save'));
    await tester.tap(_key('import-save'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(sharing.calls.where((c) => c == 'imported'), hasLength(1));
    expect(store.jobs, hasLength(1));
  });

  testWidgets('edit details after a refused create reuses the journey id', (
    tester,
  ) async {
    final sharing = _FailOnceSharing(
      error: const OurneyException(OurneyErrorCode.invalid),
    );
    final store = InMemoryImportJobStore();
    final files = FakeImportFiles();
    final checkIns = FlakyCheckIns();
    await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: checkIns,
      picker: FakeImportPicker(threePhotos()),
      importStore: store,
      importFiles: files,
    );
    await _toDetails(tester);
    await tester.enterText(_key('import-title'), 'Hoi An');
    await tester.pumpAndSettle();
    await _tap(tester, 'import-save');
    expect(_key('import-create-failed'), findsOneWidget);
    expect(_key('import-maybe-landed'), findsNothing);
    final firstId = sharing.ids.single;

    await _tap(tester, 'import-edit-details');
    // Back on the details with what the person had typed and picked.
    expect(
      tester.widget<TextField>(_key('import-title')).controller!.text,
      'Hoi An',
    );
    expect(store.jobs, isEmpty);
    expect(
      files.deletedJobs,
      isNot(contains(firstId)),
      reason: 'the kept originals stay for the next Save',
    );
    // The restored photos are still recognised: picking them again adds none.
    await _tap(tester, 'import-back');
    await _tap(tester, 'import-back');
    await _tap(tester, 'import-pick');
    expect(find.text('3 duplicate photos were skipped'), findsOneWidget);
    // Let the toast leave: it sits over the Next button.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await _toDetails(tester);
    await tester.enterText(_key('import-title'), 'Hoi An 2');
    await tester.pumpAndSettle();
    await _tap(tester, 'import-save');
    // The same id: if the first create reached the server it is deduplicated.
    expect(sharing.ids, [firstId, firstId]);
    expect(sharing.importedDraft!.title, 'Hoi An 2');
    expect(checkIns.landed, hasLength(3));
    expect(_key('import-open'), findsOneWidget);
  });

  testWidgets('after an offline create failure the details are not editable', (
    tester,
  ) async {
    final sharing = _FailOnceSharing();
    await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      picker: FakeImportPicker(threePhotos()),
    );
    await _toDetails(tester);
    await tester.enterText(_key('import-title'), 'Hoi An');
    await tester.pumpAndSettle();
    await _tap(tester, 'import-save');
    // The journey may exist already: say so, offer Try again, not Edit.
    expect(_key('import-maybe-landed'), findsOneWidget);
    expect(_key('import-edit-details'), findsNothing);
    await _tap(tester, 'import-retry');
    expect(sharing.ids, hasLength(2));
    expect(sharing.ids.first, sharing.ids.last);
    expect(_key('import-open'), findsNothing); // photos fail on the fake
    expect(_key('import-done-write'), findsNothing);
  });

  testWidgets('a create that keeps failing can be discarded', (tester) async {
    final store = InMemoryImportJobStore();
    final h = await pumpSharing(
      tester,
      location: '/import',
      sharing: _FailOnceSharing(failures: 99),
      picker: FakeImportPicker(threePhotos()),
      importStore: store,
    );
    await _toDetails(tester);
    await tester.enterText(_key('import-title'), 'Hoi An');
    await tester.pumpAndSettle();
    await _tap(tester, 'import-save');
    expect(_key('import-create-failed'), findsOneWidget);
    await _tap(tester, 'import-abandon');
    // The sheet says what is lost; Keep going leaves everything as it is.
    expect(
      find.textContaining('may still appear in your list'),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(store.jobs, hasLength(1));
    await _tap(tester, 'import-abandon');
    await _tap(tester, 'import-abandon-confirm');
    expect(store.jobs, isEmpty);
    expect(h.location, '/journeys');
  });

  testWidgets('a create that fails in the launch resume reaches the screen', (
    tester,
  ) async {
    final store = InMemoryImportJobStore();
    await _seedJob(store, 'jobD', phase: ImportPhase.creating);
    await pumpSharing(
      tester,
      location: '/import',
      sharing: _FailOnceSharing(failures: 99),
      importStore: store,
    );
    // The launch resume ran the job and failed; the screen shows that, it
    // does not wait for a result of its own.
    expect(_key('import-create-failed'), findsOneWidget);
    expect((await store.get('jobD'))!.createFailure, ImportFailure.offline);
  });

  testWidgets('pause stops saving and Continue finishes it', (tester) async {
    final store = InMemoryImportJobStore();
    final checkIns = FlakyCheckIns()
      ..gate = Completer<void>()
      ..gateAt = 2;
    await pumpSharing(
      tester,
      location: '/import',
      checkIns: checkIns,
      picker: FakeImportPicker(threePhotos()),
      importStore: store,
    );
    await _toDetails(tester);
    await tester.enterText(_key('import-title'), 'Trip');
    await tester.pumpAndSettle();
    await tester.ensureVisible(_key('import-save'));
    await tester.pump();
    await tester.tap(_key('import-save'));
    await tester.pumpAndSettle();
    expect(_key('import-pause-hint'), findsOneWidget);
    await _tap(tester, 'import-pause');
    checkIns.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Paused.'), findsOneWidget);
    expect(find.text('Done.'), findsNothing);
    expect(_key('import-resume'), findsOneWidget);
    expect(store.jobs.values.single.paused, isTrue);
    expect(checkIns.landed, hasLength(2));

    await _tap(tester, 'import-resume');
    expect(checkIns.landed, hasLength(3));
    expect(find.text('Done.'), findsOneWidget);
    expect(_key('import-open'), findsOneWidget);
  });

  testWidgets('a job left by another account is dropped, not shown', (
    tester,
  ) async {
    final store = InMemoryImportJobStore();
    await _seedJob(store, 'theirs', owner: 'someone-else');
    final checkIns = FlakyCheckIns();
    final picker = FakeImportPicker(threePhotos());
    await pumpSharing(
      tester,
      location: '/import',
      checkIns: checkIns,
      picker: picker,
      importStore: store,
    );
    expect(checkIns.landed, isEmpty);
    expect(await store.get('theirs'), isNull);
    expect(picker.picks, 1, reason: 'a fresh flow opens the picker');
  });

  testWidgets('local-only needs server', (tester) async {
    await pumpSharing(
      tester,
      location: '/import',
      config: const AppConfig.localOnly(),
    );
    expect(_key('needs-server'), findsOneWidget);
  });

  testWidgets(
    'paused job in local-only mode drops foreign jobs, shows Resume, and completes without Signed out (DE-05)',
    (tester) async {
      final store = InMemoryImportJobStore();
      await _seedJob(store, 'foreign-job', owner: 'u1');
      await _seedJob(store, 'local-job', owner: 'local');
      await store.setPaused('local-job', paused: true);
      final checkIns = SubmittingCheckInRepository();
      await pumpSharing(
        tester,
        location: '/import',
        config: const AppConfig.localOnly(),
        checkIns: checkIns,
        importStore: store,
      );
      expect(await store.get('foreign-job'), isNull);
      expect(find.text('Signed out.'), findsNothing);
      expect(find.text('Paused.'), findsOneWidget);
      expect(_key('import-resume'), findsOneWidget);

      await _tap(tester, 'import-resume');
      expect(find.text('Done.'), findsOneWidget);
      expect(_key('import-open'), findsOneWidget);
    },
  );

  testWidgets(
    'signed out during a job in backend mode offers Sign in CTA (DE-05)',
    (tester) async {
      final store = InMemoryImportJobStore();
      await _seedJob(store, 'job-1', owner: 'u1');
      await store.setPaused('job-1', paused: true);
      final h = await pumpSharing(
        tester,
        location: '/import',
        importStore: store,
        extraOverrides: [
          authStatusProvider.overrideWith((ref) => AuthStatus.signedIn),
          accountSessionResetProvider.overrideWith((ref) {}),
        ],
      );
      expect(find.text('Paused.'), findsOneWidget);
      await h.container.read(authRepositoryProvider).signOut();
      await tester.pumpAndSettle();
      expect(find.text('Signed out.'), findsOneWidget);
      expect(_key('import-sign-in'), findsOneWidget);
    },
  );

  for (final b in Brightness.values) {
    testWidgets('320dp 1.35x $b vi no overflow on every step', (tester) async {
      await pumpSharing(
        tester,
        location: '/import',
        locale: const Locale('vi'),
        size: const Size(320, 640),
        textScale: 1.35,
        brightness: b,
        picker: FakeImportPicker([
          fakePhoto('a.jpg', taken: DateTime(2026, 10, 10, 9), size: 1),
          fakePhoto('b.jpg', taken: DateTime(2026, 10, 12, 9), size: 2),
          fakePhoto('x.jpg', modified: DateTime(1970), size: 9),
        ]),
      );
      expect(tester.takeException(), isNull, reason: 'photos step');
      await _tap(tester, 'import-next');
      expect(tester.takeException(), isNull, reason: 'timeline step');
      // Dated by hand, then on to the details and the saving screen.
      for (
        var i = 0;
        i < 10 && _key('import-undated-all').evaluate().isEmpty;
        i++
      ) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(_key('import-undated-all'));
      await tester.pumpAndSettle();
      await tester.tap(_key('import-undated-all'));
      await tester.pumpAndSettle();
      await tester.tap(_key('import-date-confirm'));
      await tester.pumpAndSettle();
      await _tap(tester, 'import-to-details');
      expect(tester.takeException(), isNull, reason: 'details step');
      for (var i = 0; i < 10 && _key('import-title').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(_key('import-title'));
      await tester.pumpAndSettle();
      await tester.enterText(_key('import-title'), 'Hội An ệ ữ ấ');
      await tester.pumpAndSettle();
      await _tap(tester, 'import-save');
      expect(tester.takeException(), isNull, reason: 'saving step');
    });
  }
}

/// A sharing repository whose first create fails (the answer is lost).
class _FailOnceSharing extends FakeSharingRepository {
  _FailOnceSharing({
    this.failures = 1,
    this.error = const OurneyException(OurneyErrorCode.offline),
  });

  final OurneyException error;

  /// How many creates fail before one works.
  int failures;
  final List<String> ids = [];

  @override
  Future<Journey> createImported(ImportedJourneyDraft draft) async {
    ids.add(draft.id);
    if (failures > 0) {
      failures--;
      throw error;
    }
    return super.createImported(draft);
  }
}

Future<void> _seedJob(
  InMemoryImportJobStore store,
  String id, {
  ImportPhase phase = ImportPhase.uploading,
  String owner = 'u1',
}) async {
  await store.create(
    buildImportJob(
      id: id,
      ownerId: owner,
      title: 'Hoi An',
      type: importTypes.first,
      layout: 'memory',
      continues: false,
      timezone: testTz,
      now: testNow,
      photos: [
        DraftPhoto(
          id: '$id-ph0',
          path: 's0.jpg',
          dedupeKey: 'k0',
          order: 0,
          date: const LocalDate(2024, 2, 1),
        ),
      ],
    ),
  );
  await store.updatePhoto(id, '$id-ph0', photoFile: 'a', thumbFile: 'b');
  await store.setPhase(id, phase);
}
