// Bug #5 (device, 2026-11-15): camera rebuilt to the Figma V2 camera and
// design-v2 bugs.md A1. Discs are image-only, one title block names the
// selected journey in full (never "..."), the top chip shows only the name
// and opens the picker once, and today's photos show as a counted thumb.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/camera/camera_providers.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/camera/capture_services.dart';
import 'package:ourney/features/camera/routes.dart';
import 'package:ourney/features/camera/widgets/journey_disc_strip.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart';

const _long = 'Một hành trình có tên rất dài để thử xem có bị cắt chữ không';

void main() {
  late FakeCameraSession camera;

  Future<void> pump(
    WidgetTester tester, {
    required List<Journey> journeys,
    List<CheckIn> checkIns = const [],
    Brightness brightness = Brightness.dark,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    camera = FakeCameraSession();
    final prefs = await testPrefs({CameraPrefs.permissionAsked: true});
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(journeys: journeys),
          checkIns: FakeCheckInRepository(existing: [...checkIns]),
        ),
        cameraSessionFactoryProvider.overrideWithValue(() => camera),
        galleryPickerProvider.overrideWithValue(FakeGalleryPicker()),
        appSettingsOpenerProvider.overrideWithValue(FakeSettingsOpener()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      routedTestApp(
        container: container,
        routes: cameraRoutes,
        initialLocation: '/capture',
        log: RouteLog(),
        brightness: brightness,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Camera texts (outside the shared dock) cut because they did not fit.
  List<String> cutTexts(WidgetTester tester) => [
    for (final e
        in find
            .byType(RichText)
            .evaluate()
            .toSet()
            .difference(
              find
                  .descendant(
                    of: find.byType(UiDock),
                    matching: find.byType(RichText),
                  )
                  .evaluate()
                  .toSet(),
            ))
      if ((e.renderObject! as RenderParagraph).didExceedMaxLines)
        '${(e.widget as RichText).text.toPlainText()} @ '
            '${e.findAncestorWidgetOfExactType<KeyedSubtree>()?.key ?? ''}'
            '${[
              for (final k in ['capture-title', 'capture-journey-chip'])
                if (find.descendant(of: find.byKey(ValueKey(k)), matching: find.byWidget(e.widget)).evaluate().isNotEmpty) k,
            ]}',
  ];

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name}: a long name is shown in full, '
        'discs carry no text', (tester) async {
      await withClock(Clock.fixed(testNowUtc), () async {
        await pump(
          tester,
          brightness: brightness,
          journeys: [
            testJourney(title: _long),
            testJourney(id: 'j2', title: 'Học tiếng Anh'),
          ],
        );
        expect(tester.takeException(), isNull);
        // One title block with the full name, no cut text anywhere.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('capture-title')),
            matching: find.text(_long),
          ),
          findsOneWidget,
        );
        expect(cutTexts(tester), isEmpty);
        // Discs are images: no Text inside a journey disc.
        for (final id in ['j1', 'j2']) {
          expect(
            find.descendant(
              of: find.byKey(ValueKey('journey-chip-$id')),
              matching: find.byType(Text),
            ),
            findsNothing,
          );
        }
        expect(find.textContaining('Ngày 16/30'), findsOneWidget);
        expect(find.textContaining('chưa chụp hôm nay'), findsOneWidget);
      });
    });
  }

  testWidgets('320dp at 1.35x text: no overflow, controls stay 48dp', (
    tester,
  ) async {
    await pump(
      tester,
      size: const Size(320, 640),
      textScale: 1.35,
      journeys: [
        testJourney(title: _long),
        testJourney(id: 'j2', title: 'Học tiếng Anh'),
      ],
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final chip = tester.getSize(
      find.byKey(const ValueKey('capture-journey-chip')),
    );
    expect(chip.height, greaterThanOrEqualTo(48));
  });

  testWidgets('tapping a disc selects that journey and updates the title', (
    tester,
  ) async {
    await pump(
      tester,
      journeys: [
        testJourney(),
        testJourney(id: 'j2', title: 'Học tiếng Anh'),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('journey-chip-j2')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('capture-journey-chip')),
        matching: find.text('Học tiếng Anh'),
      ),
      findsOneWidget,
    );
    expect(camera.starts, 1, reason: 'switching journey never restarts');
  });

  testWidgets('the name chip opens the picker sheet exactly once', (
    tester,
  ) async {
    await pump(
      tester,
      journeys: [
        testJourney(),
        testJourney(id: 'j2', title: 'Học tiếng Anh'),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('capture-journey-chip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journey-picker-search')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey-picker-j2')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('capture-journey-chip')),
        matching: find.text('Học tiếng Anh'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('six journeys: four discs plus "All (6)"', (tester) async {
    await pump(
      tester,
      journeys: [
        for (var i = 1; i <= 6; i++) testJourney(id: 'j$i', title: 'J$i'),
      ],
    );
    expect(find.byKey(const ValueKey('journey-picker-open')), findsOneWidget);
    var discs = 0;
    for (var i = 1; i <= 6; i++) {
      if (find.byKey(ValueKey('journey-chip-j$i')).evaluate().isNotEmpty) {
        discs++;
      }
    }
    expect(discs, kCameraQuickDiscs);
    await tester.tap(find.byKey(const ValueKey('journey-picker-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journey-picker-search')), findsOneWidget);
  });

  testWidgets('two photos today: thumb shows "2 ảnh" (bug #2 + A1)', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNowUtc), () async {
      await pump(
        tester,
        journeys: [testJourney()],
        checkIns: [testCheckIn(testToday), testCheckIn(testToday)],
      );
      expect(
        find.byKey(const ValueKey('capture-latest-photo')),
        findsOneWidget,
      );
      expect(find.text('2 ảnh'), findsOneWidget);
      expect(find.textContaining('đã có 2 ảnh hôm nay'), findsOneWidget);
      // The shutter stays enabled: more photos the same day are allowed.
      final shutter = tester.widget<UiShutter>(
        find.byKey(const ValueKey('capture-shutter')),
      );
      expect(shutter.onPressed, isNotNull);
    });
  });

  group('quickCameraJourneys (SDS §8.8)', () {
    final all = [for (var i = 1; i <= 7; i++) testJourney(id: 'j$i')];

    test('keeps every journey when five fit', () {
      expect(
        quickCameraJourneys(all.take(5).toList(), selectedId: null),
        hasLength(5),
      );
    });

    test('pinned, then not shot, then shot; selected stays visible', () {
      final quick = quickCameraJourneys(
        all,
        selectedId: 'j7',
        pinnedIds: const {'j5'},
        shotTodayIds: const {'j1', 'j2'},
      );
      expect(quick.map((j) => j.id), ['j5', 'j3', 'j4', 'j7']);
    });
  });
}
