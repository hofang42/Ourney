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
import 'package:ourney/features/camera/widgets/journey_disc_strip.dart';
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
        final thumbSizeBox = find.byKey(
          const ValueKey('checkin-thumb-size'),
        );
        final initialPreviewHeight = tester.getSize(previewSizeBox).height;
        expect(initialPreviewHeight, greaterThan(200.0));
        expect(tester.getSize(thumbSizeBox).width, 0.0);
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

        // 2. Mid-flight (t = 100ms of 220ms UiMotion.medium): both vertical preview
        // and horizontal thumbnail morph simultaneously in a single 220ms pass.
        await tester.pump(const Duration(milliseconds: 100));
        final midPreviewHeight = tester.getSize(previewSizeBox).height;
        final midThumbWidth = tester.getSize(thumbSizeBox).width;
        expect(midPreviewHeight, greaterThan(0.0));
        expect(midPreviewHeight, lessThan(initialPreviewHeight));
        expect(midThumbWidth, greaterThan(0.0));
        expect(midThumbWidth, lessThan(84.0));

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

        // 3. Settled within a single 220ms pass: preview collapsed to 0, 72x96 thumbnail settled beside caption.
        await tester.pump(const Duration(milliseconds: 130));
        expect(tester.getSize(previewSizeBox).height, 0.0);
        expect(
          tester.getSize(find.byKey(const ValueKey('checkin-photo-thumb'))),
          const Size(72, 96),
        );
        expect(tester.binding.transientCallbackCount, 0);

        // 4. Reverse (unfocus via tapping thumbnail): horizontal thumb collapses simultaneously in one 220ms pass.
        await tester.tap(find.byKey(const ValueKey('checkin-photo-thumb')));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.getSize(thumbSizeBox).width, greaterThan(0.0));
        expect(tester.getSize(thumbSizeBox).width, lessThan(84.0));
        expect(tester.getSize(previewSizeBox).height, greaterThan(0.0));
        expect(tester.getSize(previewSizeBox).height, lessThan(initialPreviewHeight));

        await tester.pump(const Duration(milliseconds: 130));
        expect(tester.getSize(thumbSizeBox).width, 0.0);
        expect(tester.getSize(previewSizeBox).height, closeTo(initialPreviewHeight, 0.5));
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

    testWidgets(
      'Minimalist countdown Reduce Motion parity (Android disableAnimations + iOS reduceMotion): static hint with zero ring tickers allocated',
      (tester) async {
        for (final iosOnly in [false, true]) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(
                disableAnimations: !iosOnly,
                reduceMotion: iosOnly,
              );
          addTearDown(tester.platformDispatcher.clearAllTestValues);

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
            find.byKey(const ValueKey('checkin-countdown-ring')),
            findsNothing,
          );
          expect(tester.binding.transientCallbackCount, 0);
          await tester.pumpWidget(const SizedBox.shrink());
          container.dispose();
          await tester.pump();
        }
      },
    );
  });

  group('Moment #1 (Phases 2a–2d) & Moment #2 — 6-Skin Check-in Celebrations, Streak Roll, Stamp Slam & Milestone Confetti', () {
    CheckInOutcome buildOutcome({
      int streakBefore = 6,
      int streakAfter = 7,
      int photoOfDay = 1,
      Milestone? milestone,
    }) {
      return CheckInOutcome(
        checkIn: testCheckIn(testToday),
        streakBefore: streakBefore,
        streakAfter: streakAfter,
        photoOfDay: photoOfDay,
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
      'squad skin: rising trophy (48dp -> 0), continuous flame ignition + streak odometer roll (6 -> 7), and rubber UiStamp hidden before 360ms slam',
      (tester) async {
        final haptics = recordHaptics();
        var doneTapped = 0;
        final journey = testJourney(templateId: TemplateId.englishDaily);
        await tester.pumpWidget(
          _successHost(
            CheckinSuccessView(
              outcome: buildOutcome(),
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

        double stampOpacity() => tester
            .widget<FadeTransition>(
              find.byKey(const ValueKey('ui-stamp-slam-fade')),
            )
            .opacity
            .value;

        double flameScale() => tester
            .widget<Transform>(
              find.byKey(const ValueKey('ui-streak-flame-scale')),
            )
            .transform
            .storage[0];

        // 1. Start (t = 0ms): trophy starts at +48dp, UiStamp is at 0.0 opacity before 360ms slam,
        // and no redundant 0ms haptic fired on mount. CTA is immediately interactive at t=0ms.
        expect(trophyDy(), closeTo(48.0, 0.1));
        expect(stampOpacity(), 0.0);
        expect(haptics, isEmpty);
        await tester.tap(find.byKey(const ValueKey('checkin-done')));
        expect(doneTapped, 1);

        // 2a. Right after 180ms flame ignition start (t = 185ms): flame scale transitions
        // continuously from 1.0 (no 1-frame snap to 0.84) while UiStamp remains at 0.0 opacity.
        await tester.pump(const Duration(milliseconds: 185));
        expect(flameScale(), greaterThan(0.95));
        expect(flameScale(), lessThan(1.0));
        expect(stampOpacity(), 0.0);

        // 2b. Mid-flight at t = 250ms: trophy is rising (0 < dy < 48), streak digit is rolling (6 -> 7),
        // and UiStamp is still invisible (opacity == 0.0) prior to 360ms.
        await tester.pump(const Duration(milliseconds: 65));
        expect(trophyDy(), greaterThan(0.0));
        expect(trophyDy(), lessThan(48.0));
        expect(find.text('6'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
        expect(flameScale(), isNot(closeTo(1.0, 0.001)));
        expect(stampOpacity(), 0.0);

        // 2c. Mid-slam at t = 400ms (360ms + 40ms): rubber UiStamp fades 0 -> 1 while slamming 1.22 -> 1.0.
        await tester.pump(const Duration(milliseconds: 150));
        expect(stampOpacity(), greaterThan(0.0));
        expect(stampOpacity(), lessThan(1.0));
        final stampScale = tester
            .widget<Transform>(
              find.byKey(const ValueKey('ui-stamp-slam-scale')),
            )
            .transform
            .storage[0];
        expect(stampScale, greaterThan(1.0));
        expect(stampScale, lessThanOrEqualTo(1.22));

        // 3. Settled: trophy at 0dp, only '7' remains, stamp settled at opacity 1.0,
        // and distinct haptics fired at contact frames (460ms mediumImpact, 540ms selectionClick).
        await tester.pump(CheckinSuccessView.autoCloseDelay);
        await tester.pumpAndSettle();
        expect(trophyDy(), closeTo(0.0, 0.01));
        expect(stampOpacity(), 1.0);
        expect(find.text('6'), findsNothing);
        expect(find.text('7'), findsOneWidget);
        expect(
          haptics,
          equals(<String>[
            'HapticFeedbackType.mediumImpact',
            'HapticFeedbackType.selectionClick',
          ]),
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'extraPhoto (2nd photo of the same day) does not replay UiStamp slam, streak roll, or celebration haptics, and UiStamp/UiStreakNumber replay on didUpdateWidget',
      (tester) async {
        final haptics = recordHaptics();
        final journey = testJourney(templateId: TemplateId.englishDaily);
        await tester.pumpWidget(
          _successHost(
            CheckinSuccessView(
              outcome: buildOutcome(
                streakBefore: 7,
                streakAfter: 7,
                photoOfDay: 2,
              ),
              journey: journey,
              haptics: true,
              onDone: () {},
              onShare: () {},
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.byKey(const ValueKey('ui-stamp-slam-scale')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('ui-streak-flame-scale')),
          findsNothing,
        );
        await tester.pump(CheckinSuccessView.autoCloseDelay);
        await tester.pumpAndSettle();
        expect(haptics, isEmpty);

        // Verify didUpdateWidget replays UiStamp and UiStreakNumber when value/text updates.
        var streakVal = 3;
        var stampText = 'DAY 3';
        late StateSetter setHost;
        await tester.pumpWidget(
          _successHost(
            StatefulBuilder(
              builder: (context, setState) {
                setHost = setState;
                return Column(
                  children: [
                    UiStamp(stampText, animate: true),
                    UiStreakNumber(
                      value: streakVal,
                      unit: 'days',
                      animate: true,
                    ),
                  ],
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        setHost(() {
          streakVal = 4;
          stampText = 'DAY 4';
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 220));
        expect(find.text('3'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(
          tester
              .widget<FadeTransition>(
                find.byKey(const ValueKey('ui-stamp-slam-fade')),
              )
              .opacity
              .value,
          0.0,
        );
        await tester.pumpAndSettle();
        expect(find.text('4'), findsOneWidget);
        expect(find.text('DAY 4'), findsOneWidget);
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
        final filterFinder = find.byKey(
          const ValueKey('checkin-memory-develop-filter'),
        );
        expect(filterFinder, findsOneWidget);
        final filterAtStart = tester
            .widget<ColorFiltered>(filterFinder)
            .colorFilter;

        // 2. Mid-develop (t = 400ms of 1100ms)
        await tester.pump(const Duration(milliseconds: 400));
        expect(polaroidOpacity(), greaterThan(0.35));
        expect(polaroidOpacity(), lessThan(1.0));
        expect(filterFinder, findsOneWidget);
        final filterAtMid = tester
            .widget<ColorFiltered>(filterFinder)
            .colorFilter;
        expect(filterAtMid, isNot(equals(filterAtStart)));

        // 3. Settled
        await tester.pumpAndSettle();
        expect(polaroidOpacity(), closeTo(1.0, 0.001));
        expect(filterFinder, findsNothing);
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
      'Moment #2 milestone climax: hides starRow & UiStamp before 360/440ms, fires ConfettiWidget at 440ms, plays exact 2-beat haptics (440ms + 550ms) with zero collisions, pulses Share CTA at 520..780ms, and auto-stops cleanly',
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

        double bannerOpacity() => tester
            .widget<FadeTransition>(
              find.byKey(const ValueKey('checkin-milestone-banner-fade')),
            )
            .opacity
            .value;

        double stampOpacity() => tester
            .widget<FadeTransition>(
              find.byKey(const ValueKey('ui-stamp-slam-fade')),
            )
            .opacity
            .value;

        // 1. Before 360ms/440ms (t = 200ms): confetti has not fired, starRow & UiStamp are at 0.0 opacity.
        await tester.pump(const Duration(milliseconds: 200));
        expect(controller.state, ConfettiControllerState.stopped);
        expect(bannerOpacity(), 0.0);
        expect(stampOpacity(), 0.0);
        expect(
          find.byKey(const ValueKey('checkin-share-highlight')),
          findsNothing,
        );
        expect(haptics, isEmpty);

        // 2. At t = 465ms (past 440ms climax AND past 460ms UiStamp contact):
        // confetti plays, starRow spring-seals (scale > 1.0, opacity > 0.0), and ONLY ONE
        // mediumImpact haptic fired (zero 460ms UiStamp collision).
        await tester.pump(const Duration(milliseconds: 265));
        expect(controller.state, ConfettiControllerState.playing);
        expect(bannerOpacity(), greaterThan(0.0));
        final bannerScale = tester
            .widget<Transform>(
              find.byKey(const ValueKey('checkin-milestone-banner-scale')),
            )
            .transform
            .storage[0];
        expect(bannerScale, greaterThan(1.0));
        expect(
          haptics,
          equals(<String>['HapticFeedbackType.mediumImpact']),
        );

        // 3. At t = 620ms (past 540ms streak lock-in & 550ms second haptic beat, inside 520..780ms Share highlight pulse):
        // ONLY the 550ms lightImpact beat added (zero 540ms selectionClick collision).
        await tester.pump(const Duration(milliseconds: 155));
        expect(
          haptics,
          equals(<String>[
            'HapticFeedbackType.mediumImpact',
            'HapticFeedbackType.lightImpact',
          ]),
        );
        expect(
          find.byKey(const ValueKey('checkin-share-highlight')),
          findsOneWidget,
        );

        // 4. Settled: ConfettiController auto-stops and clears particles; zero active tickers remain.
        await tester.pumpAndSettle();
        expect(controller.state, ConfettiControllerState.stopped);
        expect(bannerOpacity(), 1.0);
        expect(
          find.byKey(const ValueKey('checkin-share-highlight')),
          findsNothing,
        );
        expect(
          haptics,
          equals(<String>[
            'HapticFeedbackType.mediumImpact',
            'HapticFeedbackType.lightImpact',
          ]),
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'Milestone Reduce Motion parity (Android disableAnimations + iOS reduceMotion): mounts ZERO ConfettiWidget, has zero spatial Transform offsets, and settles by 160ms',
      (tester) async {
        final journey = testJourney(templateId: TemplateId.englishDaily);
        for (final iosOnly in [false, true]) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(
                disableAnimations: false,
                reduceMotion: iosOnly,
              );
          addTearDown(tester.platformDispatcher.clearAllTestValues);

          await tester.pumpWidget(
            _successHost(
              disableAnimations: !iosOnly,
              CheckinSuccessView(
                key: ValueKey('reduced-milestone-$iosOnly'),
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
          expect(
            find.byKey(const ValueKey('checkin-milestone')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('checkin-share')), findsOneWidget);
          expect(tester.binding.transientCallbackCount, 0);
        }
      },
    );
  });

  group('Moment #14 — Camera Viewfinder Overlays, Lens Flip Scrim & Directional Journey Chip', () {
    testWidgets(
      '3-point pump choreography on Couple Partner PiP (72x96 corner <-> 50% half-frame), mid-flight borderRadius/border lerp, Image Element preservation, and 3s auto-collapse',
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
        final photoFinder = find.byKey(const ValueKey('overlay-partner-photo'));
        final stackOrigin = tester.getTopLeft(find.byType(Stack).first);

        BoxDecoration frameDecoration() {
          final containerElem = tester.element(find.byType(AnimatedContainer));
          BoxDecoration? found;
          void visit(Element el) {
            if (el.widget is DecoratedBox) {
              final d = (el.widget as DecoratedBox).decoration;
              if (d is BoxDecoration && d.border != null) {
                found ??= d;
              }
            }
            el.visitChildren(visit);
          }

          containerElem.visitChildren(visit);
          return found!;
        }

        expect(tester.getSize(pipFinder), const Size(72, 96));
        expect(tester.getTopLeft(pipFinder).dx - stackOrigin.dx, 14.0);
        final initialPhotoElement = tester.element(photoFinder);
        final initialDeco = frameDecoration();
        expect(
          (initialDeco.borderRadius! as BorderRadius).topLeft.x,
          closeTo(UiRadius.thumb, 0.01),
        );
        expect(
          (initialDeco.borderRadius! as BorderRadius).topRight.x,
          closeTo(UiRadius.thumb, 0.01),
        );

        // 1. Start (t = 0ms): tap PiP -> fires selection haptic, switches key to overlay-partner-half,
        // and preserves the exact Image.file Element without unmounting.
        await tester.tap(pipFinder);
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.selectionClick'));
        expect(halfFinder, findsOneWidget);
        expect(tester.element(photoFinder), same(initialPhotoElement));

        // 2. Mid-flight (t = 120ms of 260ms UiMotion.sheetEnter): bounds, borderRadius, and border alpha interpolate smoothly.
        await tester.pump(const Duration(milliseconds: 120));
        final midSize = tester.getSize(halfFinder);
        final midDx = tester.getTopLeft(halfFinder).dx - stackOrigin.dx;
        expect(midSize.width, greaterThan(72.0));
        expect(midSize.width, lessThan(120.0));
        expect(midSize.height, greaterThan(96.0));
        expect(midSize.height, lessThan(320.0));
        expect(midDx, greaterThan(0.0));
        expect(midDx, lessThan(14.0));

        final midDeco = frameDecoration();
        final midRadius = midDeco.borderRadius! as BorderRadius;
        expect(midRadius.topLeft.x, greaterThan(UiRadius.thumb));
        expect(midRadius.topLeft.x, lessThan(UiRadius.viewfinder));
        expect(midRadius.topRight.x, greaterThan(0.0));
        expect(midRadius.topRight.x, lessThan(UiRadius.thumb));
        final midBorderAlpha = (midDeco.border! as Border).top.color.a;
        expect(midBorderAlpha, greaterThan(0.0));
        expect(midBorderAlpha, lessThan(1.0));

        // 3. Settled (t = 260ms): fills left half (120x320 at dx = 0) with flush inner split seam (topRight == 0) and transparent border.
        await tester.pump(const Duration(milliseconds: 160));
        expect(tester.getSize(halfFinder), const Size(120, 320));
        expect(tester.getSize(photoFinder), const Size(120, 320));
        expect(tester.getTopLeft(halfFinder).dx - stackOrigin.dx, 0.0);
        final settledDeco = frameDecoration();
        final settledRadius = settledDeco.borderRadius! as BorderRadius;
        expect(settledRadius.topLeft.x, closeTo(UiRadius.viewfinder, 0.01));
        expect(settledRadius.topRight.x, closeTo(0.0, 0.01));
        expect((settledDeco.border! as Border).top.color.a, closeTo(0.0, 0.01));

        // Auto-collapse after 3s timer fires and morphs back to 72x96 while preserving Image Element.
        await tester.pump(const Duration(seconds: 3));
        expect(pipFinder, findsOneWidget);
        expect(tester.element(photoFinder), same(initialPhotoElement));
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

    testWidgets(
      'JourneyDiscStrip Soft Neo-Brutalism press physics: selected disc translates onto stationary shadow and unselected disc translates flat without 0.96 scale-down',
      (tester) async {
        final j1 = testJourney(id: 'j1', title: 'Chạy bộ');
        final j2 = testJourney(
          id: 'j2',
          title: 'Đà Lạt',
          templateId: TemplateId.travel,
        );

        await tester.pumpWidget(
          _overlayHost(
            Center(
              child: JourneyDiscStrip(
                journeys: [j1, j2],
                total: 2,
                selectedId: 'j1',
                onSelect: (_) {},
                onOpenAll: () {},
              ),
            ),
          ),
        );

        final selectedDisc = find.byKey(const ValueKey('journey-chip-j1'));
        final unselectedDisc = find.byKey(const ValueKey('journey-chip-j2'));

        // Selected disc has a stationary shadow outside the translated layer and zero scale wrapper.
        expect(
          find.descendant(
            of: selectedDisc,
            matching: find.byKey(const ValueKey('ui-pressable-static-shadow')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: selectedDisc,
            matching: find.byKey(const ValueKey('ui-pressable-surface-scale')),
          ),
          findsNothing,
        );

        final selectedGesture = await tester.startGesture(
          tester.getCenter(selectedDisc),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        final selectedTx = tester
            .widget<Transform>(
              find.descendant(
                of: selectedDisc,
                matching: find.byKey(
                  const ValueKey('ui-pressable-surface-translate'),
                ),
              ),
            )
            .transform
            .getTranslation();
        expect(selectedTx.x, greaterThan(0.0));
        expect(selectedTx.x, lessThan(UiShadow.tiny));
        await selectedGesture.up();
        await tester.pumpAndSettle();

        // Unselected bordered disc translates flat (pressOffset: 2dp) and never shrinks to 0.96.
        expect(
          find.descendant(
            of: unselectedDisc,
            matching: find.byKey(const ValueKey('ui-pressable-surface-scale')),
          ),
          findsNothing,
        );
        final unselectedGesture = await tester.startGesture(
          tester.getCenter(unselectedDisc),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 55));
        final unselectedTx = tester
            .widget<Transform>(
              find.descendant(
                of: unselectedDisc,
                matching: find.byKey(
                  const ValueKey('ui-pressable-surface-translate'),
                ),
              ),
            )
            .transform
            .getTranslation();
        expect(unselectedTx.x, greaterThan(0.0));
        expect(unselectedTx.x, lessThan(UiShadow.tiny));
        await unselectedGesture.up();
        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'Moment #14 Reduce Motion parity (Android disableAnimations + iOS reduceMotion): Partner PiP snaps in 0ms, lens flip scrim stays at 0.0 opacity, journey swipe has 0dp spatial offset, and capture-grid fires selection haptic',
      (tester) async {
        for (final iosOnly in [false, true]) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(
                disableAnimations: !iosOnly,
                reduceMotion: iosOnly,
              );
          addTearDown(tester.platformDispatcher.clearAllTestValues);

          // 1. Partner PiP snaps immediately to 120x320 half-frame on tap (0ms spatial morph).
          await tester.pumpWidget(
            _overlayHost(
              disableAnimations: !iosOnly,
              Stack(
                key: ValueKey('pip-reduced-$iosOnly'),
                children: const [
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
          await tester.tap(find.byKey(const ValueKey('overlay-partner-pip')));
          await tester.pump();
          expect(
            tester.getSize(find.byKey(const ValueKey('overlay-partner-half'))),
            const Size(120, 320),
          );
          await tester.pump(const Duration(seconds: 3));
          await tester.pump();

          // 2. CaptureScreen under Reduce Motion: lens flip scrim stays at 0.0 opacity,
          // viewfinder swipe swaps journey with 0dp spatial offset, and grid tool fires selection haptic.
          await withClock(Clock.fixed(testNowUtc), () async {
            final haptics = recordHaptics();
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
                    ],
                  ),
                ),
                cameraSessionFactoryProvider.overrideWithValue(() => camera),
                galleryPickerProvider.overrideWithValue(FakeGalleryPicker()),
                appSettingsOpenerProvider.overrideWithValue(
                  FakeSettingsOpener(),
                ),
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

            final chipOriginX = tester
                .getTopLeft(find.textContaining('Chạy bộ'))
                .dx;

            // Tap framing grid toggle -> fires selection haptic.
            haptics.clear();
            await tester.tap(find.byKey(const ValueKey('capture-grid')));
            await tester.pump();
            expect(haptics, contains('HapticFeedbackType.selectionClick'));

            // Tap lens switch -> scrim stays at 0.0 opacity under Reduce Motion.
            await tester.tap(find.byKey(const ValueKey('capture-switch')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 55));
            final scrim = tester.widget<FadeTransition>(
              find.byKey(const ValueKey('capture-lens-flip-scrim')),
            );
            expect(scrim.opacity.value, 0.0);
            await tester.pumpAndSettle();

            // Horizontal viewfinder swipe -> incoming chip has 0dp horizontal offset mid-transition.
            await tester.fling(
              find.byKey(const ValueKey('capture-preview')),
              const Offset(-300, 0),
              1200,
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 60));
            expect(
              tester.getTopLeft(find.textContaining('Đà Lạt')).dx,
              closeTo(chipOriginX, 0.1),
            );
            await tester.pumpAndSettle();
            expect(camera.starts, 2);
            expect(tester.binding.transientCallbackCount, 0);
            await tester.pumpWidget(const SizedBox.shrink());
            container.dispose();
            await tester.pump();
          });
        }
      },
    );
  });
}
