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
