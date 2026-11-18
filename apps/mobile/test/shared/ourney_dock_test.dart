import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_dock.dart';
import 'package:ourney/ui/components/dock_tab.dart';
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
    testWidgets('${brightness.name}: same 5 tabs, snap pill 56x40 in the '
        'journey accent, no overflow at 320dp / 1.35x', (tester) async {
      await pump(
        tester,
        brightness: brightness,
        dock: AppDock(currentIndex: AppDock.journeysIndex, onSelect: (_) {}),
        journeys: [
          testJourney(templateId: TemplateId.travel, durationDays: null),
        ],
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      expect(find.text('Hành trình'), findsOneWidget);
      expect(find.text('Hoạt động'), findsOneWidget);
      expect(find.text('Hồ sơ'), findsOneWidget);
      expect(find.text('Nhóm'), findsOneWidget);
      final pill = find.descendant(
        of: find.byKey(const ValueKey('dock-snap-pill')),
        matching: find.byType(Container),
      );
      final face = tester
          .widgetList<Container>(pill)
          .firstWhere(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color != null,
          );
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
      'dock-activity',
      'dock-profile',
    ]) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
    await tester.tap(find.byKey(const ValueKey('dock-journeys')));
    await tester.tap(find.byKey(const ValueKey('dock-snap-pill')));
    await tester.tap(find.byKey(const ValueKey('dock-groups')));
    await tester.tap(find.byKey(const ValueKey('dock-activity')));
    await tester.tap(find.byKey(const ValueKey('dock-profile')));
    expect(picked, [
      AppDock.journeysIndex,
      AppDock.captureIndex,
      AppDock.groupsIndex,
      AppDock.activityIndex,
      AppDock.profileIndex,
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
        label: 'Hành trình',
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

  testWidgets(
    'selection pill fully contains icon and label without icon/label overlap '
    'at 360, 393, and 430pt across all 4 tabs (vi and en)',
    (tester) async {
      const widths = [360.0, 393.0, 430.0];
      const tabs = [
        (AppDock.journeysIndex, 'dock-journeys'),
        (AppDock.groupsIndex, 'dock-groups'),
        (AppDock.activityIndex, 'dock-activity'),
        (AppDock.profileIndex, 'dock-profile'),
      ];
      final prefs = await testPrefs();
      final container = ProviderContainer(
        overrides: baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(),
        ),
      );
      addTearDown(container.dispose);
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;

      for (final locale in const [Locale('vi'), Locale('en')]) {
        for (final width in widths) {
          tester.view.physicalSize = Size(width, 844);
          for (final (tabIndex, tabKey) in tabs) {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: testApp(
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AppDock(currentIndex: tabIndex, onSelect: (_) {}),
                  ),
                  locale: locale,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            final pillRect = tester.getRect(
              find.byKey(const ValueKey('dock-selection-pill')),
            );
            final tabFinder = find.byKey(ValueKey(tabKey));
            final iconRect = tester.getRect(
              find.descendant(of: tabFinder, matching: find.byType(OurneyIcon)),
            );
            final textRect = tester.getRect(
              find.descendant(of: tabFinder, matching: find.byType(Text)),
            );
            final ctx = '${locale.languageCode} ${width}pt $tabKey';

            expect(
              iconRect.left,
              greaterThanOrEqualTo(pillRect.left),
              reason: 'icon left inside pill ($ctx)',
            );
            expect(
              iconRect.top,
              greaterThanOrEqualTo(pillRect.top),
              reason: 'icon top inside pill ($ctx)',
            );
            expect(
              iconRect.right,
              lessThanOrEqualTo(pillRect.right),
              reason: 'icon right inside pill ($ctx)',
            );
            expect(
              iconRect.bottom,
              lessThanOrEqualTo(pillRect.bottom),
              reason: 'icon bottom inside pill ($ctx)',
            );

            expect(
              textRect.left,
              greaterThanOrEqualTo(pillRect.left),
              reason: 'label left inside pill ($ctx)',
            );
            expect(
              textRect.top,
              greaterThanOrEqualTo(pillRect.top),
              reason: 'label top inside pill ($ctx)',
            );
            expect(
              textRect.right,
              lessThanOrEqualTo(pillRect.right),
              reason: 'label right inside pill ($ctx)',
            );
            expect(
              textRect.bottom,
              lessThanOrEqualTo(pillRect.bottom),
              reason: 'label bottom inside pill ($ctx)',
            );

            expect(
              iconRect.overlaps(textRect),
              isFalse,
              reason: 'icon does not overlap label ($ctx)',
            );
          }
        }
      }
    },
  );

  testWidgets('dock labels are never cut at 360pt (en and vi)', (tester) async {
    final prefs = await testPrefs();
    final container = ProviderContainer(
      overrides: baseOverrides(prefs: prefs, journeys: FakeJourneyRepository()),
    );
    addTearDown(container.dispose);
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);

    for (final locale in const [Locale('en'), Locale('vi')]) {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(
            Align(
              alignment: Alignment.bottomCenter,
              child: AppDock(
                currentIndex: AppDock.journeysIndex,
                onSelect: (_) {},
              ),
            ),
            locale: locale,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final richTexts = find.descendant(
        of: find.byType(DockTab),
        matching: find.byType(RichText),
      );
      expect(richTexts, findsWidgets);
      for (final element in richTexts.evaluate()) {
        final render = element.renderObject! as RenderParagraph;
        expect(
          render.didExceedMaxLines,
          isFalse,
          reason: '${locale.languageCode}: ${render.text.toPlainText()}',
        );
      }
    }
  });
}
