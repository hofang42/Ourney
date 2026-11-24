import 'package:clock/clock.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/features/camera/camera_providers.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/camera/capture_overlays.dart';
import 'package:ourney/features/camera/capture_services.dart';
import 'package:ourney/features/camera/routes.dart';
import 'package:ourney/features/checkin/captured_photo.dart';
import 'package:ourney/features/checkin/checkin_clock.dart';
import 'package:ourney/features/checkin/checkin_progress.dart';
import 'package:ourney/features/checkin/checkin_success.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/checkin/routes.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'fakes.dart';

Widget _overlayHost(
  Widget child, {
  bool disableAnimations = false,
  Brightness brightness = Brightness.dark,
}) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: ourneyLocalizationsDelegates,
    supportedLocales: ourneySupportedLocales,
    theme: OurneyTheme.build(brightness),
    themeAnimationDuration: Duration.zero,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: const Size(390, 844),
        disableAnimations: disableAnimations,
      ),
      child: appChild!,
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 240, height: 320, child: child),
      ),
    ),
  );
}

Widget _successHost(
  Widget child, {
  bool disableAnimations = false,
  Brightness brightness = Brightness.light,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: ourneyLocalizationsDelegates,
      supportedLocales: ourneySupportedLocales,
      theme: OurneyTheme.build(brightness),
      themeAnimationDuration: Duration.zero,
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: const Size(390, 844),
          disableAnimations: disableAnimations,
        ),
        child: appChild!,
      ),
      home: child,
    ),
  );
}

void main() {
  List<String> recordHaptics() {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String? ?? '');
          }
          return null;
        });
    addTearDown(() {
      UiHaptics.enabled = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    return calls;
  }

  group('Moment #1a & #1b — Camera Shutter Flash & Viewfinder -> Compose UiHero', () {
    testWidgets(
      '3-point pump choreography on shutter flash (30ms attack -> 140ms decay) and UiHero borderRadius flight (32dp -> 20dp)',
      (tester) async {
        final haptics = recordHaptics();
        final camera = FakeCameraSession();
        final prefs = await testPrefs({CameraPrefs.permissionAsked: true});
        final container = ProviderContainer(
          overrides: [
            ...baseOverrides(
              prefs: prefs,
              journeys: FakeJourneyRepository(
                journeys: [testJourney(templateId: TemplateId.weightLoss)],
              ),
              checkIns: FakeCheckInRepository(),
            ),
            cameraSessionFactoryProvider.overrideWithValue(() => camera),
            galleryPickerProvider.overrideWithValue(FakeGalleryPicker()),
            appSettingsOpenerProvider.overrideWithValue(FakeSettingsOpener()),
            photoCompressorProvider.overrideWithValue(FakePhotoCompressor()),
            checkinClockProvider.overrideWithValue(FakeCheckinClock()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          routedTestApp(
            container: container,
            routes: [...cameraRoutes, ...checkinRoutes],
            initialLocation: '/capture',
            log: RouteLog(),
          ),
        );
        await tester.pumpAndSettle();

        double flashOpacity() => tester
            .widget<FadeTransition>(
              find.byKey(const ValueKey('capture-shutter-flash')),
            )
            .opacity
            .value;

        expect(flashOpacity(), 0.0);

        // 1. Start (t = 0ms): tap shutter -> fires shutterMedium haptic.
        await tester.tap(find.byKey(const ValueKey('capture-shutter')));
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.mediumImpact'));

        // 2. Peak attack (t = 30ms) & mid-flight Hero shuttle (t = 90ms):
        await tester.pump(const Duration(milliseconds: 30));
        expect(flashOpacity(), closeTo(0.88, 0.05));

        // Latch reverse ticker start time, then advance 60ms into the 140ms decay.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        expect(flashOpacity(), greaterThan(0.0));
        expect(flashOpacity(), lessThan(0.88));

        // Shared-element UiHero shuttle is in flight with interpolated borderRadius (between 20 and 32).
        final shuttle = find.byKey(const ValueKey('ui-hero-shuttle'));
        expect(shuttle, findsOneWidget);
        final shuttleClip = tester.widget<ClipRRect>(
          find.descendant(of: shuttle, matching: find.byType(ClipRRect)).first,
        );
        final midRadius = (shuttleClip.borderRadius as BorderRadius).topLeft.x;
        expect(midRadius, greaterThan(UiRadius.card));
        expect(midRadius, lessThan(UiRadius.viewfinder));

        // 3. Settled: Hero lands in CheckinScreen with zero active tickers.
        await tester.pumpAndSettle();
        expect(shuttle, findsNothing);
        expect(find.byKey(const ValueKey('checkin-retake')), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'Reduce Motion parity: skips shutter flash peak (<= 0.25 alpha) and disables Hero flight shuttle',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(
              disableAnimations: true,
              reduceMotion: true,
            );
        addTearDown(tester.platformDispatcher.clearAllTestValues);

        final camera = FakeCameraSession();
        final prefs = await testPrefs({CameraPrefs.permissionAsked: true});
        final container = ProviderContainer(
          overrides: [
            ...baseOverrides(
              prefs: prefs,
              journeys: FakeJourneyRepository(
                journeys: [testJourney(templateId: TemplateId.weightLoss)],
              ),
              checkIns: FakeCheckInRepository(),
            ),
            cameraSessionFactoryProvider.overrideWithValue(() => camera),
            galleryPickerProvider.overrideWithValue(FakeGalleryPicker()),
            appSettingsOpenerProvider.overrideWithValue(FakeSettingsOpener()),
            photoCompressorProvider.overrideWithValue(FakePhotoCompressor()),
            checkinClockProvider.overrideWithValue(FakeCheckinClock()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          routedTestApp(
            container: container,
            routes: [...cameraRoutes, ...checkinRoutes],
            initialLocation: '/capture',
            log: RouteLog(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('capture-shutter')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));

        final flash = tester.widget<FadeTransition>(
          find.byKey(
            const ValueKey('capture-shutter-flash'),
            skipOffstage: false,
          ),
        );
        expect(flash.opacity.value, lessThanOrEqualTo(0.25));
        expect(find.byKey(const ValueKey('ui-hero-shuttle')), findsNothing);

        await tester.pump(const Duration(milliseconds: 160));
        expect(find.byKey(const ValueKey('checkin-retake')), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('Moment #1c — Compose Caption Focus Morph & Minimal 3..2..1 Countdown Ring', () {
    final photo = CapturedPhoto(
      journeyId: 'j1',
      path: '/tmp/shot.jpg',
      capturedAt: testNowUtc,
    );

    testWidgets(
      '3-point pump choreography on caption focus morph (520dp preview <-> 72x96 thumb) without duplicating caption TextField',
      (tester) async {
        final prefs = await testPrefs(const {});
        final container = ProviderContainer(
          overrides: [
            ...baseOverrides(
              prefs: prefs,
              journeys: FakeJourneyRepository(
                journeys: [testJourney(templateId: TemplateId.weightLoss)],
              ),
              checkIns: FakeCheckInRepository(),
            ),
            photoCompressorProvider.overrideWithValue(FakePhotoCompressor()),
            checkinClockProvider.overrideWithValue(FakeCheckinClock()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          routedTestApp(
            container: container,
            routes: checkinRoutes,
            initialLocation: '/checkin',
            initialExtra: photo,
            log: RouteLog(),
          ),
        );
        await tester.pumpAndSettle();

        final previewSizeBox = find.byKey(
          const ValueKey('checkin-preview-size'),
        );
        final initialPreviewHeight = tester.getSize(previewSizeBox).height;
        expect(initialPreviewHeight, greaterThan(200.0));
        expect(find.byKey(const ValueKey('checkin-photo-thumb')), findsNothing);

        // 1. Start (t = 0ms): focus caption field.
        await tester.tap(find.byKey(const ValueKey('checkin-caption')));
        await tester.pump(); // Focus microtask -> setState
        await tester.pump(); // Rebuild AnimatedSwitcher with typing=true
        await tester.pump(const Duration(milliseconds: 16)); // Latch Ticker startTime

        // Only ONE caption TextField is ever mounted during transition.
        expect(
          find.byKey(const ValueKey('checkin-caption')),
          findsOneWidget,
        );

        // 2. Mid-flight (t = 100ms of 220ms UiMotion.medium):
        await tester.pump(const Duration(milliseconds: 100));
        final midPreviewHeight = tester.getSize(previewSizeBox).height;
        expect(midPreviewHeight, greaterThan(0.0));
        expect(midPreviewHeight, lessThan(initialPreviewHeight));

        final thumbFade = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: find.byKey(const ValueKey('checkin-photo-thumb')),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(thumbFade.opacity.value, greaterThan(0.0));
        expect(thumbFade.opacity.value, lessThan(1.0));

        // 3. Settled: preview collapsed to 0, 72x96 thumbnail settled beside caption.
        await tester.pumpAndSettle();
        expect(tester.getSize(previewSizeBox).height, 0.0);
        expect(
          tester.getSize(find.byKey(const ValueKey('checkin-photo-thumb'))),
          const Size(72, 96),
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'Minimalist 3..2..1 countdown uses RepaintBoundary + CustomPaint progress ring + UiCountRoll digit tick',
      (tester) async {
        final haptics = recordHaptics();
        final prefs = await testPrefs(const {});
        final container = ProviderContainer(
          overrides: [
            ...baseOverrides(
              prefs: prefs,
              journeys: FakeJourneyRepository(
                journeys: [testJourney(templateId: TemplateId.custom)],
              ),
              checkIns: FakeCheckInRepository(),
            ),
            photoCompressorProvider.overrideWithValue(FakePhotoCompressor()),
            checkinClockProvider.overrideWithValue(FakeCheckinClock()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          routedTestApp(
            container: container,
            routes: checkinRoutes,
            initialLocation: '/checkin',
            initialExtra: photo,
            log: RouteLog(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('checkin-countdown-ring-boundary')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('checkin-countdown-ring')),
          findsOneWidget,
        );
        expect(find.text('3'), findsOneWidget);

        // 1. Advance 1s to trigger tick 3 -> 2.
        haptics.clear();
        await tester.pump(const Duration(seconds: 1));
        expect(haptics, contains('HapticFeedbackType.selectionClick'));

        // 2. Mid-flight (t = 80ms into 220ms tick): both '3' and '2' are rolling.
        await tester.pump(const Duration(milliseconds: 80));
        expect(find.text('3'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        // 3. Settled tick: only '2' remains.
        await tester.pumpAndSettle();
        expect(find.text('3'), findsNothing);
        expect(find.text('2'), findsOneWidget);

        // Touching screen stops countdown cleanly.
        await tester.tap(find.byKey(const ValueKey('checkin-caption')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('checkin-countdown-ring')),
          findsNothing,
        );
      },
    );
  });

  group('Moment #1 (Phases 2a–2d) & Moment #2 — 6-Skin Check-in Celebrations, Streak Roll, Stamp Slam & Milestone Confetti', () {
    CheckInOutcome buildOutcome({
      int streakBefore = 6,
      int streakAfter = 7,
      Milestone? milestone,
    }) {
      return CheckInOutcome(
        checkIn: testCheckIn(testToday),
        streakBefore: streakBefore,
        streakAfter: streakAfter,
        milestone: milestone,
      );
    }

    testWidgets(
      'quiet skin: calm critically damped card settle (0.97 -> 1.0, never > 1.0) + breathing dots RepaintBoundary',
      (tester) async {
        final journey = testJourney(templateId: TemplateId.weightLoss);
        await tester.pumpWidget(
          _successHost(
            CheckinSuccessView(
              outcome: buildOutcome(milestone: Milestone.sevenDays),
              journey: journey,
              haptics: true,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );

        double sealScale() => tester
            .widget<Transform>(find.byKey(const ValueKey('checkin-quiet-seal')))
            .transform
            .storage[0];

        // 1. Start (t = 0ms)
        expect(sealScale(), closeTo(0.97, 0.005));
        expect(
          find.byKey(const ValueKey('checkin-quiet-dots')),
          findsOneWidget,
        );

        // 2. Mid-flight (t = 160ms): strictly between 0.97 and 1.0, never overshoots > 1.0.
        await tester.pump(const Duration(milliseconds: 160));
        expect(sealScale(), greaterThan(0.97));
        expect(sealScale(), lessThanOrEqualTo(1.0));

        // 3. Settled
        await tester.pumpAndSettle();
        expect(sealScale(), closeTo(1.0, 0.001));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'squad skin: rising trophy (48dp -> 0), streak odometer roll (6 -> 7) + flame ignition, and rubber UiStamp slam (360..680ms)',
      (tester) async {
        final haptics = recordHaptics();
        var doneTapped = 0;
        final journey = testJourney(templateId: TemplateId.englishDaily);
        await tester.pumpWidget(
          _successHost(
            CheckinSuccessView(
              outcome: buildOutcome(milestone: Milestone.thirtyDays),
              journey: journey,
              haptics: true,
              onDone: () => doneTapped++,
              onShare: () {},
            ),
          ),
        );

        double trophyDy() => tester
            .widget<Transform>(
              find.byKey(const ValueKey('checkin-squad-trophy')),
            )
            .transform
            .getTranslation()
            .y;

        // 1. Start (t = 0ms): trophy starts at +48dp; CTA is immediately interactive at t=0ms.
        expect(trophyDy(), closeTo(48.0, 0.1));
        await tester.tap(find.byKey(const ValueKey('checkin-done')));
        expect(doneTapped, 1);

        // 2a. Mid-flight at t = 250ms: trophy is rising (0 < dy < 48), streak digit is rolling (6 -> 7) and flame is ignited.
        await tester.pump(const Duration(milliseconds: 250));
        expect(trophyDy(), greaterThan(0.0));
        expect(trophyDy(), lessThan(48.0));
        expect(find.text('6'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);

        final flameScale = tester
            .widget<Transform>(
              find.byKey(const ValueKey('ui-streak-flame-scale')),
            )
            .transform
            .storage[0];
        expect(flameScale, isNot(closeTo(1.0, 0.001)));

        // 2b. Mid-slam at t = 420ms (360ms + 60ms): rubber UiStamp is slamming from 1.22 -> 1.0.
        await tester.pump(const Duration(milliseconds: 170));
        final stampScale = tester
            .widget<Transform>(
              find.byKey(const ValueKey('ui-stamp-slam-scale')),
            )
            .transform
            .storage[0];
        expect(stampScale, greaterThan(1.0));
        expect(stampScale, lessThanOrEqualTo(1.22));

        // 3. Settled: trophy at 0dp, only '7' remains, stamp settled, haptics fired at contact frames.
        await tester.pumpAndSettle();
        expect(trophyDy(), closeTo(0.0, 0.01));
        expect(find.text('6'), findsNothing);
        expect(find.text('7'), findsOneWidget);
        expect(haptics, contains('HapticFeedbackType.mediumImpact'));
        expect(haptics, contains('HapticFeedbackType.selectionClick'));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'memory skin: Polaroid chemical develop (opacity 0.35 -> 1.0 + ColorFiltered matrix over 1100ms)',
      (tester) async {
        final journey = testJourney(templateId: TemplateId.travel);
        await tester.pumpWidget(
          _successHost(
            CheckinSuccessView(
              outcome: buildOutcome(milestone: Milestone.sevenDays),
              journey: journey,
              haptics: false,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );

        double polaroidOpacity() => tester
            .widget<FadeTransition>(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('checkin-polaroid')),
                    matching: find.byType(FadeTransition),
                  )
                  .first,
            )
            .opacity
            .value;

        // 1. Start (t = 0ms)
        expect(polaroidOpacity(), closeTo(0.35, 0.01));
        expect(
          find.byKey(const ValueKey('checkin-memory-develop-filter')),
          findsOneWidget,
        );

        // 2. Mid-develop (t = 400ms of 1100ms)
        await tester.pump(const Duration(milliseconds: 400));
        expect(polaroidOpacity(), greaterThan(0.35));
        expect(polaroidOpacity(), lessThan(1.0));
        expect(
          find.byKey(const ValueKey('checkin-memory-develop-filter')),
          findsOneWidget,
        );

        // 3. Settled
        await tester.pumpAndSettle();
        expect(polaroidOpacity(), closeTo(1.0, 0.001));
        expect(
          find.byKey(const ValueKey('checkin-memory-develop-filter')),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'couple skin: left & right diptych halves slide from +-36dp into 2dp seam click + heart seal spring pop',
      (tester) async {
        final journey = Journey(
          id: 'j-couple',
          ownerId: 'me',
          kind: JourneyKind.group,
          maxMembers: 2,
          templateId: TemplateId.custom,
          layout: PersonaSkinId.coupleRituals,
          title: 'Hai đứa',
          emoji: '💞',
          startDate: const LocalDate(2026, 10, 1),
          durationDays: 30,
          timezone: 'Asia/Ho_Chi_Minh',
          visibility: JourneyVisibility.private,
          status: JourneyStatus.active,
        );
        await tester.pumpWidget(
          _successHost(
            CheckinSuccessView(
              outcome: buildOutcome(milestone: Milestone.sevenDays),
              journey: journey,
              haptics: false,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );

        double leftDx() => tester
            .widget<Transform>(
              find.byKey(const ValueKey('checkin-couple-left')),
            )
            .transform
            .getTranslation()
            .x;
        double rightDx() => tester
            .widget<Transform>(
              find.byKey(const ValueKey('checkin-couple-right')),
            )
            .transform
            .getTranslation()
            .x;
        double heartScale() => tester
            .widget<Transform>(
              find.byKey(const ValueKey('checkin-couple-heart')),
            )
            .transform
            .storage[0];

        // 1. Start (t = 0ms)
        expect(leftDx(), closeTo(-36.0, 0.1));
        expect(rightDx(), closeTo(36.0, 0.1));
        expect(heartScale(), closeTo(0.84, 0.01));

        // 2. Mid-click (t = 140ms)
        await tester.pump(const Duration(milliseconds: 140));
        expect(leftDx(), greaterThan(-36.0));
        expect(leftDx(), lessThan(0.0));
        expect(rightDx(), lessThan(36.0));
        expect(rightDx(), greaterThan(0.0));
        expect(heartScale(), greaterThan(0.84));

        // 3. Settled
        await tester.pumpAndSettle();
        expect(leftDx(), closeTo(0.0, 0.05));
        expect(rightDx(), closeTo(0.0, 0.05));
        expect(heartScale(), closeTo(1.0, 0.02));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'flexer & minimal skins: flexer telemetry ring sweep (0.94 -> 1.02 -> 1.0) and minimal ink-dot bloom (0.86 -> 1.0)',
      (tester) async {
        // 1. Flexer skin
        final flexerJourney = testJourney(templateId: TemplateId.workout30);
        await tester.pumpWidget(
          _successHost(
            CheckinSuccessView(
              outcome: buildOutcome(milestone: Milestone.sevenDays),
              journey: flexerJourney,
              haptics: false,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );

        double flexerScale() => tester
            .widget<Transform>(
              find.byKey(const ValueKey('checkin-flexer-ring')),
            )
            .transform
            .storage[0];

        expect(flexerScale(), closeTo(0.94, 0.01));
        await tester.pump(const Duration(milliseconds: 240));
        expect(flexerScale(), greaterThan(0.94));
        await tester.pumpAndSettle();
        expect(flexerScale(), closeTo(1.0, 0.005));

        // 2. Minimal skin
        final minimalJourney = testJourney(templateId: TemplateId.custom);
        await tester.pumpWidget(
          _successHost(
            CheckinSuccessView(
              key: const ValueKey('minimal-success'),
              outcome: buildOutcome(milestone: Milestone.sevenDays),
              journey: minimalJourney,
              haptics: false,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );

        double minimalScale() => tester
            .widget<Transform>(
              find.byKey(const ValueKey('checkin-minimal-dot')),
            )
            .transform
            .storage[0];

        expect(minimalScale(), closeTo(0.86, 0.01));
        await tester.pump(const Duration(milliseconds: 160));
        expect(minimalScale(), greaterThan(0.86));
        expect(minimalScale(), lessThan(1.0));
        await tester.pumpAndSettle();
        expect(minimalScale(), closeTo(1.0, 0.005));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'Moment #2 milestone climax: fires ConfettiWidget at 440ms, double-beat haptics (440ms + 550ms), Share CTA highlight pulse at 520..780ms, and auto-stops cleanly',
      (tester) async {
        final haptics = recordHaptics();
        final journey = testJourney(templateId: TemplateId.englishDaily);
        await tester.pumpWidget(
          _successHost(
            CheckinSuccessView(
              outcome: buildOutcome(milestone: Milestone.sevenDays),
              journey: journey,
              haptics: true,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );

        final confettiFinder = find.byType(ConfettiWidget);
        expect(confettiFinder, findsOneWidget);
        final controller = tester
            .widget<ConfettiWidget>(confettiFinder)
            .confettiController;

        // 1. Before 440ms (t = 200ms): confetti has not fired yet.
        await tester.pump(const Duration(milliseconds: 200));
        expect(controller.state, ConfettiControllerState.stopped);
        expect(
          find.byKey(const ValueKey('checkin-share-highlight')),
          findsNothing,
        );

        // 2. At t = 450ms (past 440ms climax): confetti plays & first beat (mediumImpact) fires.
        haptics.clear();
        await tester.pump(const Duration(milliseconds: 250));
        expect(controller.state, ConfettiControllerState.playing);
        expect(haptics, contains('HapticFeedbackType.mediumImpact'));

        // 3. At t = 620ms (past 550ms second haptic beat & inside 520..780ms Share highlight pulse):
        haptics.clear();
        await tester.pump(const Duration(milliseconds: 170));
        expect(haptics, contains('HapticFeedbackType.lightImpact'));
        expect(
          find.byKey(const ValueKey('checkin-share-highlight')),
          findsOneWidget,
        );

        // 4. Settled: ConfettiController auto-stops and clears particles; zero active tickers remain.
        await tester.pumpAndSettle();
        expect(controller.state, ConfettiControllerState.stopped);
        expect(
          find.byKey(const ValueKey('checkin-share-highlight')),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'Milestone Reduce Motion parity: mounts ZERO ConfettiWidget, has zero spatial Transform offsets, and settles by 160ms',
      (tester) async {
        final journey = testJourney(templateId: TemplateId.englishDaily);
        await tester.pumpWidget(
          _successHost(
            disableAnimations: true,
            CheckinSuccessView(
              outcome: buildOutcome(milestone: Milestone.sevenDays),
              journey: journey,
              haptics: true,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );

        // Zero ConfettiWidget mounted under Reduce Motion.
        expect(find.byType(ConfettiWidget), findsNothing);
        expect(
          find.byKey(const ValueKey('checkin-cta-translate')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('ui-stamp-slam-scale')),
          findsNothing,
        );

        // Final streak value and milestone text reached after a single 160ms pump.
        await tester.pump(const Duration(milliseconds: 160));
        expect(find.text('7'), findsOneWidget);
        expect(find.text('6'), findsNothing);
        expect(find.byKey(const ValueKey('checkin-milestone')), findsOneWidget);
        expect(find.byKey(const ValueKey('checkin-share')), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('Moment #14 — Camera Viewfinder Overlays, Lens Flip Scrim & Directional Journey Chip', () {
    testWidgets(
      '3-point pump choreography on Couple Partner PiP (72x96 corner <-> 50% half-frame) and 3s auto-collapse',
      (tester) async {
        final haptics = recordHaptics();
        await tester.pumpWidget(
          _overlayHost(
            const Stack(
              children: [
                Positioned.fill(
                  child: CaptureSkinOverlay(
                    skin: PersonaSkinId.coupleRituals,
                    partnerPhotoFile: 'missing-partner.jpg',
                  ),
                ),
              ],
            ),
          ),
        );

        final pipFinder = find.byKey(const ValueKey('overlay-partner-pip'));
        final halfFinder = find.byKey(const ValueKey('overlay-partner-half'));
        final stackOrigin = tester.getTopLeft(find.byType(Stack).first);

        expect(tester.getSize(pipFinder), const Size(72, 96));
        expect(tester.getTopLeft(pipFinder).dx - stackOrigin.dx, 14.0);

        // 1. Start (t = 0ms): tap PiP -> fires selection haptic and switches key to overlay-partner-half.
        await tester.tap(pipFinder);
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.selectionClick'));
        expect(halfFinder, findsOneWidget);

        // 2. Mid-flight (t = 120ms of 260ms UiMotion.sheetEnter):
        await tester.pump(const Duration(milliseconds: 120));
        final midSize = tester.getSize(halfFinder);
        final midDx = tester.getTopLeft(halfFinder).dx - stackOrigin.dx;
        expect(midSize.width, greaterThan(72.0));
        expect(midSize.width, lessThan(120.0));
        expect(midSize.height, greaterThan(96.0));
        expect(midSize.height, lessThan(320.0));
        expect(midDx, greaterThan(0.0));
        expect(midDx, lessThan(14.0));

        // 3. Settled (t = 260ms): fills left half (120x320 at dx = 0).
        await tester.pump(const Duration(milliseconds: 160));
        expect(tester.getSize(halfFinder), const Size(120, 320));
        expect(tester.getTopLeft(halfFinder).dx - stackOrigin.dx, 0.0);

        // Auto-collapse after 3s timer fires and morphs back to 72x96.
        await tester.pump(const Duration(seconds: 3));
        expect(pipFinder, findsOneWidget);
        await tester.pump(const Duration(milliseconds: 120));
        expect(tester.getSize(pipFinder).width, greaterThan(72.0));
        expect(tester.getSize(pipFinder).width, lessThan(120.0));
        await tester.pumpAndSettle();
        expect(tester.getSize(pipFinder), const Size(72, 96));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      '3-point pump choreography on Quiet Ghost silhouette fade (160ms UiMotion.fast)',
      (tester) async {
        var showGhost = true;
        late StateSetter setHost;

        await tester.pumpWidget(
          _overlayHost(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CaptureSkinOverlay(
                        skin: PersonaSkinId.quietTransformer,
                        showGhost: showGhost,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        double ghostOpacity() => tester
            .widget<FadeTransition>(
              find.descendant(
                of: find.byKey(const ValueKey('overlay-ghost-fade')),
                matching: find.byType(FadeTransition),
              ),
            )
            .opacity
            .value;

        expect(find.byKey(const ValueKey('overlay-ghost')), findsOneWidget);
        expect(ghostOpacity(), 1.0);

        // 1. Toggle off at t = 0ms
        setHost(() => showGhost = false);
        await tester.pump();
        expect(find.byKey(const ValueKey('overlay-ghost')), findsNothing);

        // 2. Mid-fade at t = 80ms
        await tester.pump(const Duration(milliseconds: 80));
        expect(ghostOpacity(), greaterThan(0.0));
        expect(ghostOpacity(), lessThan(1.0));

        // 3. Settled at t = 160ms
        await tester.pumpAndSettle();
        expect(ghostOpacity(), 0.0);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      '3-point pump choreography on Lens Flip frosted scrim (220ms) and directional viewfinder journey swipe without camera restart',
      (tester) async {
        await withClock(Clock.fixed(testNowUtc), () async {
          final camera = FakeCameraSession();
          final prefs = await testPrefs({CameraPrefs.permissionAsked: true});
          final container = ProviderContainer(
            overrides: [
              ...baseOverrides(
                prefs: prefs,
                journeys: FakeJourneyRepository(
                  journeys: [
                    testJourney(id: 'j1', title: 'Chạy bộ'),
                    testJourney(
                      id: 'j2',
                      title: 'Đà Lạt',
                      templateId: TemplateId.travel,
                    ),
                    testJourney(
                      id: 'j3',
                      title: 'Tiếng Anh',
                      templateId: TemplateId.englishDaily,
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
          expect(camera.starts, 1);

          // A. Lens flip frosted scrim 3-point check (110ms in + 110ms out = 220ms)
          double lensScrimOpacity() => tester
              .widget<FadeTransition>(
                find.byKey(const ValueKey('capture-lens-flip-scrim')),
              )
              .opacity
              .value;

          expect(lensScrimOpacity(), 0.0);
          await tester.tap(find.byKey(const ValueKey('capture-switch')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 55));
          expect(lensScrimOpacity(), greaterThan(0.0));
          expect(lensScrimOpacity(), lessThan(1.0));

          await tester.pumpAndSettle();
          expect(lensScrimOpacity(), 0.0);
          expect(camera.isFront, isTrue);
          expect(camera.starts, 2);

          // B. Horizontal viewfinder swipe: left fling (+1 direction) vs right fling (-1 direction)
          final chipOriginX = tester
              .getTopLeft(find.textContaining('Chạy bộ'))
              .dx;

          await tester.fling(
            find.byKey(const ValueKey('capture-preview')),
            const Offset(-300, 0),
            1200,
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));

          final incomingJ2MidX = tester
              .getTopLeft(find.textContaining('Đà Lạt'))
              .dx;
          expect(incomingJ2MidX - chipOriginX, greaterThan(0.0));
          expect(incomingJ2MidX - chipOriginX, lessThanOrEqualTo(10.0));

          await tester.pumpAndSettle();
          expect(
            tester.getTopLeft(find.textContaining('Đà Lạt')).dx,
            closeTo(chipOriginX, 0.1),
          );
          // Camera session never restarted during journey swipe!
          expect(camera.starts, 2);

          // Swipe right (direction: -1) back to 'Chạy bộ' -> incoming enters from -dx.
          await tester.fling(
            find.byKey(const ValueKey('capture-preview')),
            const Offset(300, 0),
            1200,
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));

          final incomingJ1MidX = tester
              .getTopLeft(find.textContaining('Chạy bộ'))
              .dx;
          expect(incomingJ1MidX - chipOriginX, lessThan(0.0));
          expect(incomingJ1MidX - chipOriginX, greaterThanOrEqualTo(-10.0));

          await tester.pumpAndSettle();
          expect(camera.starts, 2);
          expect(tester.binding.transientCallbackCount, 0);
        });
      },
    );
  });
}
