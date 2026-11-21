// Camera redesign (2026-11-20): one shared camera, a large preview, and a
// status pill instead of a toast (the toast covered the shutter).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/camera/camera_providers.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/camera/capture_services.dart';
import 'package:ourney/features/camera/routes.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart';

class _FailingShotCamera extends FakeCameraSession {
  @override
  Future<String> takePicture() =>
      throw const CameraStartException(CameraFailure.failed);
}

void main() {
  late FakeCameraSession camera;

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    List<Journey>? journeys,
    FakeCameraSession? session,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    camera = session ?? FakeCameraSession();
    final prefs = await testPrefs({CameraPrefs.permissionAsked: true});
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(
            journeys:
                journeys ??
                [
                  testJourney(templateId: TemplateId.workout30),
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
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder preview() => find.byKey(const ValueKey('capture-preview'));

  for (final (w, h) in [(320.0, 640.0), (390.0, 844.0), (430.0, 932.0)]) {
    for (final scale in [1.0, 1.35]) {
      testWidgets('preview fills the width minus the 8dp inset at '
          '${w.toInt()}dp, ${scale}x text', (tester) async {
        await pump(tester, size: Size(w, h), textScale: scale);
        expect(tester.takeException(), isNull);
        final size = tester.getSize(preview());
        expect(size.width, closeTo(w - 16, 0.5));
        expect(size.height, closeTo((w - 16) * 4 / 3, 0.5));
        expect(tester.getTopLeft(preview()).dx, closeTo(8, 0.5));
      });
    }
  }

  testWidgets('a short phone shrinks the preview instead of overflowing', (
    tester,
  ) async {
    await pump(tester, size: const Size(320, 480), textScale: 1.35);
    expect(tester.takeException(), isNull);
    final size = tester.getSize(preview());
    expect(size.width, lessThan(304));
    expect(size.width / size.height, closeTo(3 / 4, 0.01));
  });

  testWidgets('controls row: library left, flip right, no title block', (
    tester,
  ) async {
    await pump(tester);
    final lib = tester.getRect(find.byKey(const ValueKey('capture-gallery')));
    final flip = tester.getRect(find.byKey(const ValueKey('capture-switch')));
    expect(lib.left, lessThan(60));
    expect(flip.right, greaterThan(330));
    expect(lib.center.dy, closeTo(flip.center.dy, 1));
    expect(lib.width, greaterThanOrEqualTo(48));
    expect(flip.width, greaterThanOrEqualTo(48));
    expect(find.byKey(const ValueKey('capture-title')), findsNothing);
    // Flip is no longer in the top bar.
    expect(flip.top, greaterThan(tester.getRect(preview()).bottom));
  });

  group('status pill', () {
    testWidgets('flash toggle shows the pill, no toast, clear of the shutter', (
      tester,
    ) async {
      await pump(tester);
      final pill = find.byKey(const ValueKey('ui-camera-status-pill'));
      AnimatedOpacity fade() => tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byKey(const ValueKey('capture-status')),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(fade().opacity, 0);

      await tester.tap(find.byKey(const ValueKey('capture-flash')));
      await tester.pump();
      expect(fade().opacity, 1);
      expect(
        find.descendant(of: pill, matching: find.text('Đèn flash: tự động')),
        findsOneWidget,
      );
      // No SnackBar / toast anywhere.
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byKey(const ValueKey('ui-toast')), findsNothing);
      // Inside the preview, nowhere near the shutter.
      final pillRect = tester.getRect(pill);
      final previewRect = tester.getRect(preview());
      expect(previewRect.contains(pillRect.topLeft), isTrue);
      expect(previewRect.contains(pillRect.bottomRight), isTrue);
      final shutter = tester.getRect(
        find.byKey(const ValueKey('capture-shutter')),
      );
      expect(pillRect.overlaps(shutter), isFalse);
      expect(pillRect.bottom, lessThan(shutter.top));

      // Holds ~1.2s, then fades out.
      await tester.pump(const Duration(milliseconds: 1300));
      expect(fade().opacity, 0);
    });

    testWidgets('the state is announced to screen readers', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('capture-flash')));
      await tester.pump();
      expect(
        tester.takeAnnouncements(),
        contains(isAccessibilityAnnouncement('Đèn flash: tự động')),
      );
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('flash glyph changes shape with each state', (tester) async {
      await pump(tester);
      String glyph() => tester
          .widget<OurneyIcon>(
            find.descendant(
              of: find.byKey(const ValueKey('capture-flash')),
              matching: find.byType(OurneyIcon),
            ),
          )
          .name;
      expect(glyph(), 'flash-off');
      await tester.tap(find.byKey(const ValueKey('capture-flash')));
      await tester.pump();
      expect(glyph(), 'flash-auto');
      await tester.tap(find.byKey(const ValueKey('capture-flash')));
      await tester.pump();
      expect(glyph(), 'lightning');
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('a failed shot uses the pill, not a toast', (tester) async {
      await pump(tester, session: _FailingShotCamera());
      await tester.tap(find.byKey(const ValueKey('capture-shutter')));
      await tester.pump();
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ui-camera-status-pill')),
          matching: find.textContaining('Chụp chưa được'),
        ),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('persona guides', () {
    testWidgets('quiet: the ghost tool toggles the silhouette', (tester) async {
      await pump(
        tester,
        journeys: [testJourney(templateId: TemplateId.weightLoss)],
      );
      expect(find.byKey(const ValueKey('overlay-ghost')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('capture-ghost')));
      await tester.pump();
      expect(find.byKey(const ValueKey('overlay-ghost')), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(camera.starts, 1);
    });

    testWidgets('other personas have no ghost tool and no HUD', (tester) async {
      await pump(
        tester,
        journeys: [testJourney(templateId: TemplateId.workout30)],
      );
      expect(find.byKey(const ValueKey('capture-ghost')), findsNothing);
      expect(find.byKey(const ValueKey('overlay-ghost')), findsNothing);
      expect(find.byKey(const ValueKey('overlay-none')), findsOneWidget);
    });
  });
}
