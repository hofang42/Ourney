import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/features/camera/camera_providers.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/camera/capture_services.dart';
import 'package:ourney/features/camera/routes.dart';
import 'package:ourney/personas/memory_collectors/camera_hud.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart';

/// F3: the capture screen draws the HUD of the selected journey's persona
/// over a preview that is never restarted by a persona switch.
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

  OurneyPersonaTheme persona(WidgetTester tester) => OurneyPersonaTheme.of(
    tester.element(find.byKey(const ValueKey('placeholder-camera'))),
  );

  testWidgets('the first journey sets the persona of the screen', (
    tester,
  ) async {
    await pump(tester);
    expect(persona(tester).skinId, PersonaSkinId.aestheticFlexer);
    expect(persona(tester).background.computeLuminance(), lessThan(0.1));
    expect(find.byType(DisposableFilmStampHud), findsNothing);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
  });

  testWidgets('picking another journey swaps the HUD and the colors but '
      'never restarts the camera', (tester) async {
    await pump(tester);
    expect(camera.starts, 1);

    await tester.tap(find.byKey(const ValueKey('journey-chip-j2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(persona(tester).skinId, PersonaSkinId.memoryCollectors);
    expect(find.byType(DisposableFilmStampHud), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
    expect(camera.starts, 1, reason: 'switching journey must not restart');
    expect(camera.stops, 0);

    await tester.tap(find.byKey(const ValueKey('journey-chip-j1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(persona(tester).skinId, PersonaSkinId.aestheticFlexer);
    expect(find.byType(DisposableFilmStampHud), findsNothing);
    expect(camera.starts, 1);
    expect(camera.stops, 0);
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
      expect(persona(tester).skinId, PersonaSkinId.memoryCollectors);
      expect(camera.starts, 1);
      expect(camera.stops, 0);
    },
  );
}
