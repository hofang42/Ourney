import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/camera/capture_overlays.dart';
import 'package:ourney/features/camera/journey_picker_sheet.dart';
import 'package:ourney/features/camera/l10n/generated/camera_localizations.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../checkin/fakes.dart';

Widget _host(Widget child, {required bool dark, double scale = 1.35}) =>
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: CameraL10n.localizationsDelegates,
      supportedLocales: CameraL10n.supportedLocales,
      theme: OurneyTheme.build(dark ? Brightness.dark : Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 640),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(body: SizedBox(width: 240, height: 320, child: child)),
      ),
    );

void main() {
  const noHud = [
    PersonaSkinId.accountabilitySquad,
    PersonaSkinId.memoryCollectors,
    PersonaSkinId.aestheticFlexer,
    PersonaSkinId.minimalistHabit,
  ];

  for (final dark in [false, true]) {
    for (final skin in noHud) {
      testWidgets('${skin.name} draws nothing on the preview '
          '(${dark ? 'dark' : 'light'})', (tester) async {
        await tester.pumpWidget(
          _host(
            Stack(children: [CaptureSkinOverlay(skin: skin)]),
            dark: dark,
          ),
        );
        expect(find.byKey(const ValueKey('overlay-none')), findsOneWidget);
        expect(find.byType(Text), findsNothing);
        expect(find.byKey(const ValueKey('overlay-ghost')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('quiet ghost follows showGhost', (tester) async {
    Future<void> show(bool ghost) => tester.pumpWidget(
      _host(
        Stack(
          children: [
            Positioned.fill(
              child: CaptureSkinOverlay(
                skin: PersonaSkinId.quietTransformer,
                showGhost: ghost,
              ),
            ),
          ],
        ),
        dark: true,
      ),
    );
    await show(true);
    expect(find.byKey(const ValueKey('overlay-ghost')), findsOneWidget);
    await show(false);
    expect(find.byKey(const ValueKey('overlay-ghost')), findsNothing);
  });

  group('couple partner PiP', () {
    Future<void> show(WidgetTester tester, {String? file}) => tester.pumpWidget(
      _host(
        Stack(
          children: [
            Positioned.fill(
              child: CaptureSkinOverlay(
                skin: PersonaSkinId.coupleRituals,
                partnerPhotoFile: file,
              ),
            ),
          ],
        ),
        dark: true,
        scale: 1,
      ),
    );

    testWidgets('is a 72x96 thumbnail at the top-start corner', (tester) async {
      await show(tester, file: 'missing-partner.jpg');
      final pip = find.byKey(const ValueKey('overlay-partner-pip'));
      expect(pip, findsOneWidget);
      expect(tester.getSize(pip), const Size(72, 96));
      final box = tester.getRect(find.byType(Stack).first);
      expect(tester.getTopLeft(pip).dx - box.left, 14);
      expect(
        find.byKey(const ValueKey('overlay-partner-photo')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows nothing without a partner photo', (tester) async {
      await show(tester);
      expect(find.byKey(const ValueKey('overlay-partner-pip')), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('tap enlarges to a half frame for 3s', (tester) async {
      await show(tester, file: 'missing-partner.jpg');
      await tester.tap(find.byKey(const ValueKey('overlay-partner-pip')));
      await tester.pump();
      final half = find.byKey(const ValueKey('overlay-partner-half'));
      expect(half, findsOneWidget);
      expect(find.byKey(const ValueKey('overlay-partner-pip')), findsNothing);
      await tester.pump(const Duration(seconds: 3, milliseconds: 100));
      expect(half, findsNothing);
      expect(find.byKey(const ValueKey('overlay-partner-pip')), findsOneWidget);
    });

    testWidgets(
      'F-39: quietTransformer renders ghost guide alongside partner PiP',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const Stack(
              children: [
                Positioned.fill(
                  child: CaptureSkinOverlay(
                    skin: PersonaSkinId.quietTransformer,
                    showGhost: true,
                    partnerPhotoFile: 'missing-partner.jpg',
                  ),
                ),
              ],
            ),
            dark: true,
            scale: 1,
          ),
        );
        expect(find.byKey(const ValueKey('overlay-ghost')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('overlay-partner-pip')),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('journey picker filters by search', (tester) async {
    final list = [
      testJourney(title: 'Chạy bộ'),
      testJourney(id: 'j2', title: 'Đà Lạt', templateId: TemplateId.travel),
    ];
    String? picked;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (c) => TextButton(
            onPressed: () async => picked = await showJourneyPickerSheet(
              c,
              journeys: list,
              selectedId: list.first.id,
            ),
            child: const Text('open'),
          ),
        ),
        dark: true,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Bug 12: the sheet frame (and its grabber) is drawn once, not twice.
    expect(find.byKey(const ValueKey('ui-sheet-outline')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey-picker-j2')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('journey-picker-search')),
      'lạt',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('journey-picker-${'j1'}')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('journey-picker-search')),
      'zzz',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('journey-picker-empty')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('journey-picker-search')),
      'lạt',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('journey-picker-j2')));
    await tester.pumpAndSettle();
    expect(picked, 'j2');
  });

  testWidgets('picker groups not shot / shot and excludes ended (UX-16)', (
    tester,
  ) async {
    final list = [
      testJourney(id: 'a', title: 'Alpha'),
      testJourney(id: 'b', title: 'Beta'),
      testJourney(id: 'c', title: 'Gamma', status: JourneyStatus.ended),
    ];
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (c) => TextButton(
            onPressed: () => showJourneyPickerSheet(
              c,
              journeys: list,
              selectedId: 'a',
              shotTodayIds: {'b'},
            ),
            child: const Text('open'),
          ),
        ),
        dark: false,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    for (final k in ['not-shot', 'shot']) {
      expect(find.byKey(ValueKey('journey-picker-section-$k')), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey('journey-picker-section-ended')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('journey-picker-c')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinned section sorts first in the picker sheet', (tester) async {
    final list = [
      testJourney(title: 'Alpha'),
      testJourney(id: 'j2', title: 'Beta'),
    ];
    await tester.pumpWidget(
      // The sheet content scrolls inside showUiSheet (bug 12 removed its
      // own UiSheet wrapper); a bare 320dp host needs the scroll here.
      _host(
        SingleChildScrollView(
          child: JourneyPickerSheet(
            journeys: list,
            selectedId: null,
            pinnedIds: const {'j2'},
          ),
        ),
        dark: false,
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('journey-picker-section-pinned')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('journey-picker-j2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
