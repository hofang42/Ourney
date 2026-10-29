import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/camera/camera_providers.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/camera/capture_services.dart';
import 'package:ourney/features/camera/routes.dart';
import 'package:ourney/ui/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart';

/// Camera chrome on a compact phone at 1.35x text, light and dark system
/// themes (the camera itself is always dark), plus the dock and tools.
void main() {
  late FakeCameraSession camera;
  late SharedPreferencesWithCache prefs;

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    CameraFailure? failure,
    bool asked = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    camera = FakeCameraSession()..failure = failure;
    prefs = await testPrefs({if (asked) CameraPrefs.permissionAsked: true});
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(
            journeys: [
              testJourney(
                title: 'Một hành trình có tên rất dài để thử cắt chữ',
              ),
              testJourney(id: 'j2', title: 'Học tiếng Anh'),
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
        brightness: brightness,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name}: ready fits 320dp at 1.35x text', (
      tester,
    ) async {
      await pump(tester, brightness: brightness);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('capture-shutter')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('capture-shutter'))).width,
        greaterThanOrEqualTo(76),
      );
    });

    testWidgets('${brightness.name}: permission denied fits 320dp at 1.35x', (
      tester,
    ) async {
      await pump(
        tester,
        brightness: brightness,
        failure: CameraFailure.permissionDeniedPermanently,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('capture-denied')), findsOneWidget);
      // The library stays reachable when the camera is blocked.
      expect(find.byKey(const ValueKey('capture-gallery')), findsOneWidget);
    });

    testWidgets('${brightness.name}: pre-prompt fits 320dp at 1.35x', (
      tester,
    ) async {
      await pump(tester, brightness: brightness, asked: false);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('capture-pre-prompt')), findsOneWidget);
    });
  }

  testWidgets('every camera control is at least 48dp', (tester) async {
    await pump(tester);
    for (final key in const [
      'capture-gallery',
      'capture-switch',
      'capture-grid',
      'journey-chip-j2',
      'profile-entry',
    ]) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
  });

  testWidgets('the grid button toggles the framing grid', (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.grid_3x3_rounded), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('capture-grid')));
    await tester.pump();
    expect(find.byIcon(Icons.grid_on_rounded), findsOneWidget);
  });

  testWidgets('the camera dock has Journeys, the hero shutter and Squad', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(UiDock), findsOneWidget);
    expect(find.byKey(const ValueKey('dock-journeys')), findsOneWidget);
    expect(find.byKey(const ValueKey('dock-groups')), findsOneWidget);
    expect(find.byKey(const ValueKey('dock-hero-shutter')), findsOneWidget);
    expect(find.byKey(const ValueKey('dock-snap-pill')), findsNothing);
  });
}
