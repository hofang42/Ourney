import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_dock.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../app/test_helpers.dart';
import '../features/checkin/fakes.dart';

/// The shared 3-tab dock (App.tsx `Dock`): Journeys, quick-snap pill in the
/// active journey's accent, Squad; dark with the hero shutter on the camera.
void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required Widget dock,
    Brightness brightness = Brightness.light,
    double width = 320,
    double textScale = 1.35,
    List<Journey>? journeys,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 640);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final prefs = await testPrefs();
    final container = ProviderContainer(
      overrides: baseOverrides(
        prefs: prefs,
        journeys: FakeJourneyRepository(journeys: journeys),
      ),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testApp(
          Align(alignment: Alignment.bottomCenter, child: dock),
          brightness: brightness,
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name}: same 3 tabs, snap pill 56x40 in the '
        'journey accent, no overflow at 320dp / 1.35x', (tester) async {
      await pump(
        tester,
        brightness: brightness,
        dock: AppDock(currentIndex: AppDock.journeysIndex, onSelect: (_) {}),
        journeys: [testJourney(templateId: TemplateId.travel)],
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      expect(find.text('Journeys'), findsOneWidget);
      expect(find.text('Nhóm'), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
      final pill = find.descendant(
        of: find.byKey(const ValueKey('dock-snap-pill')),
        matching: find.byType(Container),
      );
      final face = tester
          .widgetList<Container>(pill)
          .firstWhere((c) => c.decoration is BoxDecoration);
      expect(
        tester.getSize(find.byWidget(face)),
        const Size(UiSize.snapPillW, UiSize.snapPillH),
      );
      expect(
        (face.decoration! as BoxDecoration).color,
        uiJourneyStyles[2].accent,
      );
      expect(find.byKey(const ValueKey('dock-hero-shutter')), findsNothing);
    });
  }

  testWidgets('the camera dock is dark and shows the hero shutter', (
    tester,
  ) async {
    await pump(
      tester,
      dock: AppDock(
        currentIndex: AppDock.captureIndex,
        onSelect: (_) {},
        shutter: const KeyedSubtree(
          key: ValueKey('dock-hero-shutter'),
          child: UiShutter(label: 'Chụp', onPressed: null),
        ),
      ),
    );
    final shutter = tester.getSize(find.byType(UiShutter));
    expect(shutter.height, UiSize.shutter);
    expect(shutter.width, greaterThanOrEqualTo(UiSize.shutter));
    expect(find.byKey(const ValueKey('dock-snap-pill')), findsNothing);
    final bar = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(UiDock),
            matching: find.byType(Container),
          ),
        )
        .firstWhere((c) => c.decoration is BoxDecoration);
    expect((bar.decoration! as BoxDecoration).color, UiCamera.dock);
  });

  testWidgets('every control is at least 48dp and taps select the tab', (
    tester,
  ) async {
    final picked = <int>[];
    await pump(
      tester,
      dock: AppDock(currentIndex: AppDock.groupsIndex, onSelect: picked.add),
    );
    for (final key in const [
      'dock-journeys',
      'dock-snap-pill',
      'dock-groups',
    ]) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
    await tester.tap(find.byKey(const ValueKey('dock-journeys')));
    await tester.tap(find.byKey(const ValueKey('dock-snap-pill')));
    await tester.tap(find.byKey(const ValueKey('dock-groups')));
    expect(picked, [
      AppDock.journeysIndex,
      AppDock.captureIndex,
      AppDock.groupsIndex,
    ]);
  });

  testWidgets('the selected tab is announced as selected', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      dock: AppDock(currentIndex: AppDock.journeysIndex, onSelect: (_) {}),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('dock-journeys'))),
      matchesSemantics(
        label: 'Journeys',
        isButton: true,
        isSelected: true,
        isEnabled: true,
        hasEnabledState: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
