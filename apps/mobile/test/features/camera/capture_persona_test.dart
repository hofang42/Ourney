import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/camera/camera_providers.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/camera/capture_services.dart';
import 'package:ourney/features/camera/routes.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart';

/// Switching journey recolours the camera chrome (shutter accent, theme)
/// over a preview that is never restarted (CLAUDE.md section 5).
void main() {
  late FakeCameraSession camera;
  late SharedPreferencesWithCache prefs;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    camera = FakeCameraSession();
    prefs = await testPrefs({CameraPrefs.permissionAsked: true});
    container = ProviderContainer(
      overrides: [
        ...baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(
            journeys: [
              testJourney(templateId: TemplateId.workout30),
              testJourney(
                id: 'j2',
                title: 'Đà Lạt',
                templateId: TemplateId.travel,
              ),
            ],
          ),
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
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Fill of the shutter's inner disc.
  Color? shutterAccent(WidgetTester tester) {
    final inner = find.descendant(
      of: find.byType(UiShutter),
      matching: find.byType(Container),
    );
    for (final e in inner.evaluate()) {
      final deco = (e.widget as Container).decoration;
      if (deco is BoxDecoration && deco.color != null) return deco.color;
    }
    return null;
  }

  testWidgets('the first journey sets the shutter accent and day pill', (
    tester,
  ) async {
    await pump(tester);
    expect(shutterAccent(tester), uiJourneyStyles[4].accent);
    expect(find.byKey(const ValueKey('capture-day-hud')), findsOneWidget);
    expect(find.byKey(const ValueKey('dock-hero-shutter')), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
  });

  testWidgets('picking another journey recolours the chrome but never '
      'restarts the camera', (tester) async {
    await pump(tester);
    expect(camera.starts, 1);

    await tester.tap(find.byKey(const ValueKey('journey-chip-j2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(shutterAccent(tester), uiJourneyStyles[2].accent);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
    expect(camera.starts, 1, reason: 'switching journey must not restart');
    expect(camera.stops, 0);

    await tester.tap(find.byKey(const ValueKey('journey-chip-j1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(shutterAccent(tester), uiJourneyStyles[4].accent);
    expect(camera.starts, 1);
    expect(camera.stops, 0);
  });

  testWidgets('swiping the viewfinder moves to the next journey', (
    tester,
  ) async {
    await pump(tester);
    await tester.fling(
      find.byKey(const ValueKey('capture-preview')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(container.read(activeJourneyIdProvider), 'j2');
    expect(camera.starts, 1);
  });

  testWidgets('the chip choice becomes the active journey and is remembered', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('journey-chip-j2')));
    await tester.pump();
    await tester.pump();
    expect(container.read(activeJourneyIdProvider), 'j2');
    expect(prefs.getString('camera.lastJourneyId'), 'j2');
  });

  testWidgets(
    'a journey picked elsewhere (the Hub) is followed by the camera',
    (tester) async {
      await pump(tester);
      await container.read(activeJourneyIdProvider.notifier).select('j2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(shutterAccent(tester), uiJourneyStyles[2].accent);
      expect(camera.starts, 1);
      expect(camera.stops, 0);
    },
  );
}
