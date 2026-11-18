import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/features/sharing/data/sharing_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../sharing/sharing_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _tap(WidgetTester t, String k) async {
  await t.ensureVisible(_key(k));
  await t.tap(_key(k));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('setup, library, review, save', (tester) async {
    final sharing = FakeSharingRepository();
    final checkIns = SubmittingCheckInRepository();
    final h = await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: checkIns,
      picker: FakeRetellPicker([
        RetellPhoto(path: 'b.jpg', modified: DateTime(2024, 2, 6, 9)),
        RetellPhoto(path: 'a.jpg', modified: DateTime(2024, 2, 3, 9)),
        RetellPhoto(path: 'c.jpg', modified: DateTime(1970)),
      ]),
    );
    expect(_key('import-layout-quiet'), findsNothing);
    await _tap(tester, 'import-type-weight');
    expect(_key('import-layout-quiet'), findsOneWidget);
    await tester.enterText(_key('import-place'), 'Hoi An');
    await _tap(tester, 'import-next');
    expect(_key('import-empty'), findsOneWidget);
    await _tap(tester, 'import-pick');
    await _tap(tester, 'import-review');
    // Undated photo blocks saving until removed.
    await _tap(tester, 'import-save');
    expect(_key('import-save'), findsOneWidget);
    expect(_key('import-day-2'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await _tap(tester, 'import-save');
    expect(sharing.importedDraft!.title, 'Hoi An');
    expect(sharing.importedDraft!.firstDate, const LocalDate(2024, 2, 3));
    expect(checkIns.submitted, hasLength(2));
    expect(h.location, '/journey/imp1');
  });

  group('noonInZone (C-B12)', () {
    const date = LocalDate(2026, 10, 16);
    test('noon of the day in the zone', () {
      expect(noonInZone(date, testTz), DateTime.utc(2026, 10, 16, 5));
      expect(
        noonInZone(date, testTz, now: DateTime.utc(2026, 10, 17)),
        DateTime.utc(2026, 10, 16, 5),
      );
    });

    test('a photo from this morning is not stamped in the future', () {
      // 08:30 in Ho Chi Minh City.
      final now = DateTime.utc(2026, 10, 16, 1, 30);
      expect(noonInZone(date, testTz, now: now), now);
    });
  });

  Future<void> throughToSave(WidgetTester tester, String type) async {
    await _tap(tester, 'import-type-$type');
    await tester.enterText(_key('import-place'), 'Hoi An');
    await _tap(tester, 'import-next');
    await _tap(tester, 'import-pick');
    await _tap(tester, 'import-review');
  }

  final onePhoto = FakeRetellPicker([
    RetellPhoto(path: 'a.jpg', modified: DateTime(2024, 2, 3, 9)),
  ]);

  testWidgets('a couple import keeps the couple heart (C-B11)', (tester) async {
    final sharing = FakeSharingRepository();
    await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: SubmittingCheckInRepository(),
      picker: onePhoto,
    );
    await throughToSave(tester, 'couple');
    await _tap(tester, 'import-save');
    expect(sharing.importedDraft!.templateId, TemplateId.custom);
    expect(sharing.importedDraft!.emoji, '💞');
  });

  testWidgets('the picked skin and "still going" reach the server (C-B11)', (
    tester,
  ) async {
    final sharing = FakeSharingRepository();
    await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: SubmittingCheckInRepository(),
      picker: onePhoto,
    );
    await _tap(tester, 'import-type-weight');
    await tester.enterText(_key('import-place'), 'Hoi An');
    await _tap(tester, 'import-layout-quiet');
    await _tap(tester, 'import-next');
    await _tap(tester, 'import-pick');
    await _tap(tester, 'import-review');
    await _tap(tester, 'import-continue');
    await _tap(tester, 'import-save');
    expect(sharing.importedDraft!.layout, PersonaSkinId.quietTransformer);
    expect(sharing.importedDraft!.continues, isTrue);
  });

  testWidgets('saving waits for the device time zone (C-B12)', (tester) async {
    final zone = Completer<String>();
    final sharing = FakeSharingRepository();
    await pumpSharing(
      tester,
      location: '/import',
      sharing: sharing,
      checkIns: SubmittingCheckInRepository(),
      picker: onePhoto,
      timezone: zone.future,
    );
    await throughToSave(tester, 'trip');
    await tester.ensureVisible(_key('import-save'));
    await tester.tap(_key('import-save'));
    await tester.pump();
    expect(sharing.importedDraft, isNull);
    zone.complete(testTz);
    await tester.pumpAndSettle();
    expect(sharing.importedDraft!.timezone, testTz);
  });

  testWidgets('local-only needs server', (tester) async {
    await pumpSharing(
      tester,
      location: '/import',
      config: const AppConfig.localOnly(),
    );
    expect(_key('needs-server'), findsOneWidget);
  });

  for (final b in Brightness.values) {
    testWidgets('320dp 1.35x $b vi no overflow', (tester) async {
      await pumpSharing(
        tester,
        location: '/import',
        locale: const Locale('vi'),
        size: const Size(320, 640),
        textScale: 1.35,
        brightness: b,
        picker: FakeRetellPicker([
          RetellPhoto(path: 'a.jpg', modified: DateTime(2024, 2, 3, 9)),
        ]),
      );
      await _tap(tester, 'import-next');
      await _tap(tester, 'import-pick');
      await _tap(tester, 'import-review');
      expect(tester.takeException(), isNull);
    });
  }
}
