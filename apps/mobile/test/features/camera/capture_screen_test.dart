import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/camera/camera_providers.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/camera/capture_services.dart';
import 'package:ourney/features/camera/routes.dart';
import 'package:ourney/features/checkin/captured_photo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart';

void main() {
  late FakeCameraSession camera;
  late FakeGalleryPicker gallery;
  late FakeSettingsOpener settings;
  late FakeJourneyRepository journeys;
  late RouteLog log;
  late SharedPreferencesWithCache prefs;

  setUp(() {
    camera = FakeCameraSession();
    gallery = FakeGalleryPicker();
    settings = FakeSettingsOpener();
    journeys = FakeJourneyRepository(
      journeys: [
        testJourney(),
        testJourney(id: 'j2', title: 'Học tiếng Anh'),
      ],
    );
    log = RouteLog();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Map<String, Object> prefsValues = const {CameraPrefs.permissionAsked: true},
    String location = '/capture',
  }) async {
    prefs = await testPrefs(prefsValues);
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(prefs: prefs, journeys: journeys),
        cameraSessionFactoryProvider.overrideWithValue(() => camera),
        galleryPickerProvider.overrideWithValue(gallery),
        appSettingsOpenerProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      routedTestApp(
        container: container,
        routes: cameraRoutes,
        initialLocation: location,
        log: log,
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  CapturedPhoto lastPhoto() => log.extras.last! as CapturedPhoto;

  testWidgets('opens the camera at once and shows the preview (FR-C1)', (
    tester,
  ) async {
    await pump(tester);
    expect(camera.starts, 1);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey-chip-j1')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey-chip-j2')), findsOneWidget);
  });

  testWidgets('shutter has an accessible label naming the journey (NFR-5)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      find.bySemanticsLabel('Chụp ảnh check-in cho Chạy bộ'),
      findsOneWidget,
    );
    expect(find.byTooltip('Đổi camera trước/sau'), findsOneWidget);
    expect(find.byTooltip('Chọn ảnh từ thư viện'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('shutter opens /checkin with the photo and remembers journey', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('journey-chip-j2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('capture-shutter')));
    await tester.pumpAndSettle();

    expect(camera.pictures, 1);
    expect(find.byKey(const ValueKey('stub-checkin')), findsOneWidget);
    final photo = lastPhoto();
    expect(photo.journeyId, 'j2');
    expect(photo.fromLibrary, isFalse);
    expect(photo.path, '/tmp/shot1.jpg');
    expect(prefs.getString(CameraPrefs.lastJourneyId), 'j2');
  });

  testWidgets('remembers the last journey across launches', (tester) async {
    await pump(
      tester,
      prefsValues: {
        CameraPrefs.permissionAsked: true,
        CameraPrefs.lastJourneyId: 'j2',
      },
    );
    await tester.tap(find.byKey(const ValueKey('capture-shutter')));
    await tester.pumpAndSettle();
    expect(lastPhoto().journeyId, 'j2');
  });

  testWidgets('journeyId query parameter preselects that journey', (
    tester,
  ) async {
    await pump(
      tester,
      location: '/capture?journeyId=j2',
      prefsValues: {
        CameraPrefs.permissionAsked: true,
        CameraPrefs.lastJourneyId: 'j1',
      },
    );
    await tester.tap(find.byKey(const ValueKey('capture-shutter')));
    await tester.pumpAndSettle();
    expect(lastPhoto().journeyId, 'j2');
  });

  testWidgets('library pick is flagged as from library (FR-C3)', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('capture-gallery')));
    await tester.pumpAndSettle();
    expect(gallery.calls, 1);
    expect(lastPhoto().fromLibrary, isTrue);
    expect(lastPhoto().path, '/tmp/library.jpg');
  });

  testWidgets('flash cycles off, auto, on (FR-C2)', (tester) async {
    await pump(tester);
    expect(find.byTooltip('Đèn flash: tắt'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('capture-flash')));
    await tester.pump();
    expect(find.byTooltip('Đèn flash: tự động'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('capture-flash')));
    await tester.pump();
    expect(find.byTooltip('Đèn flash: bật'), findsOneWidget);
    expect(camera.flashes.last, FlashSetting.on);
  });

  testWidgets('switch lens restarts on the front camera (FR-C2)', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('capture-switch')));
    await tester.pumpAndSettle();
    expect(camera.isFront, isTrue);
    expect(camera.starts, 2);
    // Front lens: no flash toggle.
    expect(find.byKey(const ValueKey('capture-flash')), findsNothing);
  });

  group('permission', () {
    testWidgets('first launch shows the pre-prompt before the OS prompt', (
      tester,
    ) async {
      await pump(tester, prefsValues: const {});
      expect(find.byKey(const ValueKey('capture-pre-prompt')), findsOneWidget);
      expect(camera.starts, 0);

      await tester.tap(find.text('Cho phép camera'));
      await tester.pumpAndSettle();
      expect(camera.starts, 1);
      expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
      expect(prefs.getBool(CameraPrefs.permissionAsked), isTrue);
    });

    testWidgets('denied permanently shows open-settings', (tester) async {
      camera.failure = CameraFailure.permissionDeniedPermanently;
      await pump(tester);
      expect(find.byKey(const ValueKey('capture-denied')), findsOneWidget);
      // Shutter is disabled, library still works.
      await tester.tap(find.byKey(const ValueKey('capture-shutter')));
      await tester.pump();
      expect(camera.pictures, 0);

      // The panel scrolls inside the viewfinder at large text / short screens.
      await tester.ensureVisible(
        find.byKey(const ValueKey('capture-open-settings')),
      );
      await tester.tap(find.byKey(const ValueKey('capture-open-settings')));
      await tester.pump();
      expect(settings.opened, 1);
    });

    testWidgets('returning from Settings retries the camera', (tester) async {
      camera.failure = CameraFailure.permissionDeniedPermanently;
      await pump(tester);
      camera.failure = null;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
    });

    testWidgets('denied without Settings URL (Android) shows the path', (
      tester,
    ) async {
      camera.failure = CameraFailure.permissionDenied;
      settings = FakeSettingsOpener(supported: false);
      await pump(tester);
      expect(find.byKey(const ValueKey('capture-denied')), findsOneWidget);
      expect(find.byKey(const ValueKey('capture-open-settings')), findsNothing);
      expect(find.textContaining('Cài đặt ›'), findsOneWidget);
      expect(find.byKey(const ValueKey('capture-retry')), findsOneWidget);
    });
  });

  testWidgets('no camera hardware degrades to library only', (tester) async {
    camera.failure = CameraFailure.unavailable;
    await pump(tester);
    expect(find.byKey(const ValueKey('capture-unavailable')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('capture-gallery')));
    await tester.pumpAndSettle();
    expect(lastPhoto().fromLibrary, isTrue);
  });

  testWidgets('no active journey shows a CTA to create one', (tester) async {
    journeys.journeys.clear();
    await pump(tester);
    expect(find.byKey(const ValueKey('capture-no-journeys')), findsOneWidget);
    // The camera is not opened for nothing.
    expect(camera.starts, 0);
    await tester.tap(find.text('Tạo hành trình'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stub-journeys-new')), findsOneWidget);
  });

  testWidgets('journey load error offers retry', (tester) async {
    journeys.activeError = StateError('boom');
    await pump(tester);
    expect(find.text('Không tải được hành trình'), findsOneWidget);
    journeys.activeError = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journey-chip-j1')), findsOneWidget);
  });

  testWidgets('releases the camera when the app is hidden', (tester) async {
    await pump(tester);
    expect(camera.stops, 0);
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    expect(camera.stops, greaterThanOrEqualTo(1));
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.starts, 2);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
  });

  testWidgets('releases the camera on dispose', (tester) async {
    await pump(tester);
    await tester.pumpWidget(const SizedBox());
    expect(camera.stops, greaterThanOrEqualTo(1));
  });

  test('pickInitialJourney prefers the remembered active journey', () {
    final list = [testJourney(), testJourney(id: 'j2')];
    expect(pickInitialJourney(list, 'j2')?.id, 'j2');
    expect(pickInitialJourney(list, 'gone')?.id, 'j1');
    expect(pickInitialJourney(const [], 'j1'), isNull);
  });
}
