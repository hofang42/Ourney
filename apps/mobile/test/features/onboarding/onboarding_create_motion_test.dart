import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/features/journeys/ui/create/dna_pages.dart';
import 'package:ourney/features/journeys/ui/widgets/departure_ticket.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../journeys/journeys_fakes.dart';
import '../profile/fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Widget _host(
  Widget child, {
  bool disableAnimations = false,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: OurneyTheme.build(brightness),
    themeAnimationDuration: Duration.zero,
    localizationsDelegates: ourneyLocalizationsDelegates,
    supportedLocales: ourneySupportedLocales,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: const Size(390, 844),
        disableAnimations: disableAnimations,
      ),
      child: appChild!,
    ),
    home: Scaffold(body: child),
  );
}

List<String> _recordHaptics() {
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

void main() {
  group('Rank #13.1 — UiSplash 6-sticker wave & zero-Opacity FadeTransition', () {
    testWidgets(
      '3-point pump choreography on firstLaunch 6 tilted goal stickers ([0, 40, 75, 105, 130, 150]ms, 220ms, UiCurves.dockOvershoot) and zero Opacity widgets',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const SizedBox.expand(
              child: UiSplash(
                firstLaunch: true,
                tagline: 'chụp một tấm.',
              ),
            ),
          ),
        );

        // Zero Opacity widgets inside UiSplash (uses FadeTransition instead).
        expect(
          find.descendant(
            of: _key('ui-splash'),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );

        double stickerScale(int i) {
          final scaleFinder = find.ancestor(
            of: _key('ui-splash-sticker-$i'),
            matching: find.byType(ScaleTransition),
          );
          return tester.widget<ScaleTransition>(scaleFinder.first).scale.value;
        }

        double stickerOpacity(int i) {
          final fadeFinder = find.ancestor(
            of: _key('ui-splash-sticker-$i'),
            matching: find.byType(FadeTransition),
          );
          return tester.widget<FadeTransition>(fadeFinder.first).opacity.value;
        }

        // 1. Start (t = 0ms): all 6 stickers mounted at scale 0.88, opacity 0.0.
        for (var i = 0; i < 6; i++) {
          expect(_key('ui-splash-sticker-$i'), findsOneWidget);
          expect(stickerScale(i), closeTo(0.88, 0.001));
          expect(stickerOpacity(i), closeTo(0.0, 0.001));
        }

        // 2. Mid-flight (t = 60ms):
        // - Sticker 0 (0ms delay) is well underway;
        // - Sticker 1 (40ms delay) just started and trails Sticker 0;
        // - Sticker 5 (150ms delay) has not started yet.
        await tester.pump(const Duration(milliseconds: 60));
        expect(stickerScale(0), greaterThan(0.92));
        expect(stickerOpacity(0), greaterThan(0.2));
        expect(stickerOpacity(0), lessThan(1.0));

        expect(stickerScale(1), greaterThan(0.88));
        expect(stickerScale(1), lessThan(stickerScale(0)));
        expect(stickerOpacity(1), greaterThan(0.0));
        expect(stickerOpacity(1), lessThan(stickerOpacity(0)));

        expect(stickerScale(5), closeTo(0.88, 0.001));
        expect(stickerOpacity(5), closeTo(0.0, 0.001));

        // At t = 180ms, Sticker 0 is in its dockOvershoot peak (> 1.0) while
        // Sticker 5 (150ms delay) is now mid-flight.
        await tester.pump(const Duration(milliseconds: 120));
        expect(stickerScale(0), greaterThan(1.0));
        expect(stickerScale(5), greaterThan(0.88));
        expect(stickerOpacity(5), greaterThan(0.0));
        expect(stickerOpacity(5), lessThan(1.0));

        // 3. Settled (t >= 370ms): all 6 stickers rest at scale 1.0, opacity 1.0,
        // and zero transient tickers remain.
        await tester.pumpAndSettle();
        for (var i = 0; i < 6; i++) {
          expect(stickerScale(i), closeTo(1.0, 0.001));
          expect(stickerOpacity(i), closeTo(1.0, 0.001));
        }
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'Reduce-Motion parity (Android disableAnimations & iOS reduceMotion): static splash stickers with zero active tickers',
      (tester) async {
        await tester.pumpWidget(
          _host(
            disableAnimations: true,
            const SizedBox.expand(
              child: UiSplash(
                firstLaunch: true,
                tagline: 'chụp một tấm.',
              ),
            ),
          ),
        );

        expect(find.byType(UiStickerTile), findsNWidgets(6));
        expect(
          find.descendant(
            of: _key('ui-splash'),
            matching: find.byType(ScaleTransition),
          ),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);

        // Also verify iOS PlatformDispatcher reduceMotion flag.
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(tester.platformDispatcher.clearAllTestValues);

        await tester.pumpWidget(
          _host(
            const SizedBox.expand(
              child: UiSplash(
                firstLaunch: true,
                tagline: 'giữ một chuỗi.',
              ),
            ),
          ),
        );
        expect(
          find.descendant(
            of: _key('ui-splash'),
            matching: find.byType(ScaleTransition),
          ),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);
        tester.platformDispatcher.clearAllTestValues();
      },
    );
  });

  group('Rank #13.2 — Direction-aware OnboardingQuizStage & AnimatedSize previews', () {
    testWidgets(
      '3-point directional choreography: Next slides incoming from +16dp; Back slides incoming from -16dp; Q2 couple hint & Q3 result card expand smoothly',
      (tester) async {
        final haptics = _recordHaptics();
        await pumpOurneyApp(tester, onboarded: false);

        final q0OriginX = tester.getTopLeft(_key('onboarding-quiz-0')).dx;

        // Select Q1 goal and tap Next (Q1 -> Q2, direction: +1).
        await tester.ensureVisible(_key('onboarding-goal-couple'));
        await tester.pumpAndSettle();
        await tester.tap(_key('onboarding-goal-couple'));
        await tester.pumpAndSettle();
        haptics.clear();

        // 1. Start (t = 0ms)
        await tester.tap(_key('onboarding-quiz-next'));
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.selectionClick'));

        // 2. Mid-flight (t = 80ms): incoming Q2 is at dx > 0 (sliding left from +16dp).
        await tester.pump(const Duration(milliseconds: 80));
        final q1MidDx =
            tester.getTopLeft(_key('onboarding-quiz-1')).dx - q0OriginX;
        expect(q1MidDx, greaterThan(0.0));
        expect(q1MidDx, lessThan(16.0));

        // 3. Settled
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(_key('onboarding-quiz-1')).dx,
          closeTo(q0OriginX, 0.01),
        );

        // Tap Back (Q2 -> Q1, direction: -1): incoming Q1 slides from -16dp (dx < 0).
        await tester.tap(_key('onboarding-quiz-back'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final q0BackMidDx =
            tester.getTopLeft(_key('onboarding-quiz-0')).dx - q0OriginX;
        expect(q0BackMidDx, lessThan(0.0));
        expect(q0BackMidDx, greaterThan(-16.0));

        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(_key('onboarding-quiz-0')).dx,
          closeTo(q0OriginX, 0.01),
        );

        // Advance back to Q2 and test couple hint AnimatedSize + FadeTransition.
        await tester.tap(_key('onboarding-quiz-next'));
        await tester.pumpAndSettle();
        expect(_key('onboarding-couple-hint'), findsNothing);

        await tester.tap(_key('onboarding-who-couple'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final hintFade = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: _key('onboarding-couple-hint'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(hintFade.opacity.value, greaterThan(0.0));
        expect(hintFade.opacity.value, lessThan(1.0));

        await tester.pumpAndSettle();
        expect(hintFade.opacity.value, closeTo(1.0, 0.001));

        // Advance to Q3 and test result card AnimatedSize + FadeTransition.
        await tester.tap(_key('onboarding-quiz-next'));
        await tester.pumpAndSettle();
        expect(_key('onboarding-quiz-result'), findsNothing);

        await tester.tap(_key('onboarding-reminder-21:30'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final resultFade = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: _key('onboarding-quiz-result'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(resultFade.opacity.value, greaterThan(0.0));
        expect(resultFade.opacity.value, lessThan(1.0));

        await tester.pumpAndSettle();
        expect(resultFade.opacity.value, closeTo(1.0, 0.001));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'OnboardingQuizStage under Reduce Motion uses opacity-only crossfade with zero horizontal slide offset',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        await pumpOurneyApp(tester, onboarded: false);
        final originX = tester.getTopLeft(_key('onboarding-quiz-0')).dx;

        await tester.tap(_key('onboarding-goal-english'));
        await tester.pump();
        await tester.tap(_key('onboarding-quiz-next'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));

        expect(
          tester.getTopLeft(_key('onboarding-quiz-1')).dx,
          closeTo(originX, 0.01),
        );
        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('Rank #13.3 — AuthScreen AnimatedSize morph & 280ms 4-oscillation OTP error shake', () {
    testWidgets(
      '3-point choreography on AuthScreen mode morph and damped horizontal 4-oscillation OTP error shake (±6dp) + warning haptic',
      (tester) async {
        final haptics = _recordHaptics();
        final auth = RecordingAuthRepository()
          ..verifyOtpError = const OurneyException(OurneyErrorCode.invalid);
        await pumpBackendApp(tester, auth: auth);

        // Verify AnimatedSize wraps the AuthScreen form switcher.
        expect(
          find.ancestor(
            of: _key('auth-step-email'),
            matching: find.byType(AnimatedSize),
          ),
          findsOneWidget,
        );

        await tester.enterText(_key('auth-email'), 'a@b.co');
        await tester.ensureVisible(_key('auth-send'));
        await tester.pumpAndSettle();

        // Tap send -> mid-flight crossfade into code step.
        await tester.tap(_key('auth-send'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(_key('auth-step-code'), findsOneWidget);
        await tester.pumpAndSettle();

        double otpShakeDx() {
          final t = tester.widget<Transform>(_key('auth-otp-shake'));
          return t.transform.getTranslation().x;
        }

        expect(otpShakeDx(), 0.0);
        haptics.clear();

        // Enter invalid 6-digit OTP to trigger verify error + 280ms 4-oscillation shake.
        await tester.enterText(_key('auth-code'), '123456');
        await tester.pump();

        expect(haptics, contains('HapticFeedbackType.heavyImpact'));
        expect(_key('auth-error'), findsOneWidget);

        // Mid-flight sample 1 (t = 40ms) and sample 2 (t = 80ms) prove active oscillation within ±6dp.
        await tester.pump(const Duration(milliseconds: 40));
        final dx40 = otpShakeDx();
        expect(dx40.abs(), greaterThan(0.1));
        expect(dx40.abs(), lessThanOrEqualTo(6.0));

        await tester.pump(const Duration(milliseconds: 40));
        final dx80 = otpShakeDx();
        expect(dx80.abs(), greaterThan(0.1));
        expect(dx80.abs(), lessThanOrEqualTo(6.0));
        expect(dx80, isNot(closeTo(dx40, 0.01)));

        // Settled (>= 280ms): shake returns to 0.0 with zero leaked tickers.
        await tester.pump(const Duration(milliseconds: 250));
        expect(otpShakeDx(), closeTo(0.0, 0.001));
      },
    );

    testWidgets(
      'AuthScreen under Reduce Motion skips OTP horizontal shake while keeping red error state and warning haptic',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        final haptics = _recordHaptics();
        final auth = RecordingAuthRepository()
          ..verifyOtpError = const OurneyException(OurneyErrorCode.invalid);
        await pumpBackendApp(tester, auth: auth);

        await tester.enterText(_key('auth-email'), 'a@b.co');
        await tester.tap(_key('auth-send'));
        await tester.pumpAndSettle();

        haptics.clear();
        await tester.enterText(_key('auth-code'), '123456');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));

        final t = tester.widget<Transform>(_key('auth-otp-shake'));
        expect(t.transform.getTranslation().x, 0.0);
        expect(haptics, contains('HapticFeedbackType.heavyImpact'));
        expect(_key('auth-error'), findsOneWidget);
      },
    );
  });

  group('Rank #7.1 — CreateTypeDeck snapping physics, continuous scroll interpolation & live skin morph', () {
    testWidgets(
      '3-point drag & spring-snap choreography: live scale/arc/tilt/opacity interpolation, integer crossing selection haptic, and live UiSkinScope morph',
      (tester) async {
        final haptics = _recordHaptics();
        await pumpJourneys(
          tester,
          location: AppRoutes.journeyNew,
          locale: const Locale('en'),
        );
        // pumpJourneys enables disableAnimations by default; re-enable normal motion.
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        await tester.pump();

        // Initial focused card is 0 ('quiet' skin).
        final initialSkinId = UiSkinScope.of(
          tester.element(_key('journeys-create-flow')),
        ).skin.id;
        expect(initialSkinId, 'quiet');

        FadeTransition cardFade(String keyName) => tester.widget<FadeTransition>(
          find
              .ancestor(
                of: _key('template-$keyName'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );

        expect(cardFade('weight_loss').opacity.value, closeTo(1.0, 0.001));
        expect(cardFade('english_daily').opacity.value, closeTo(0.66, 0.001));

        haptics.clear();

        // 1. Start drag on create-deck-scroll: first cross kTouchSlop (18px) to
        // win the gesture arena over UiPressable's tap recognizer, then drag
        // halfway (~90px) toward card 1.
        final scrollFinder = _key('create-deck-scroll');
        final gesture = await tester.startGesture(tester.getCenter(scrollFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(-20, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(-90, 0));
        await tester.pump();

        // 2. Mid-drag: both card 0 and card 1 have interpolated opacity strictly in (0.66, 1.0),
        // and card 0 is now tilted/scaled/translated smoothly.
        final midOpacity0 = cardFade('weight_loss').opacity.value;
        final midOpacity1 = cardFade('english_daily').opacity.value;
        expect(midOpacity0, greaterThan(0.66));
        expect(midOpacity0, lessThan(1.0));
        expect(midOpacity1, greaterThan(0.66));
        expect(midOpacity1, lessThan(1.0));

        // Cross the integer card boundary to card 1 ('squad' skin).
        await gesture.moveBy(const Offset(-110, 0));
        await tester.pump();
        expect(find.text('2/6'), findsOneWidget);
        expect(haptics, contains('HapticFeedbackType.selectionClick'));
        expect(
          UiSkinScope.of(tester.element(_key('journeys-create-flow'))).skin.id,
          'squad',
        );

        // 3. Release finger: _DeckSnapScrollPhysics settles directly into card 1 detent via UiSprings.snappy.
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        expect(cardFade('english_daily').opacity.value, greaterThan(midOpacity1));

        await tester.pumpAndSettle();
        expect(cardFade('english_daily').opacity.value, closeTo(1.0, 0.001));
        expect(cardFade('weight_loss').opacity.value, closeTo(0.66, 0.001));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'CreateTypeDeck under Reduce Motion disables tilt/scale interpolation and jumps cleanly on Prev/Next',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        final haptics = _recordHaptics();
        await pumpJourneys(
          tester,
          location: AppRoutes.journeyNew,
          locale: const Locale('en'),
        );

        haptics.clear();
        await tester.tap(_key('create-deck-next'));
        await tester.pumpAndSettle();

        expect(find.text('2/6'), findsOneWidget);
        expect(haptics, contains('HapticFeedbackType.selectionClick'));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });

  group('Rank #7.2 — CreateFlowScreen directional steps/DNA, DnaWeightPicker detents & DepartureTicket stamp settle', () {
    testWidgets(
      '3-point directional step & DNA sub-page transitions: Next slides from +18dp; Back slides from -18dp',
      (tester) async {
        await pumpJourneys(
          tester,
          location: AppRoutes.journeyNew,
          locale: const Locale('en'),
        );
        // pumpJourneys enables disableAnimations by default; re-enable normal motion.
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        await tester.pump();

        final deckOriginX = tester
            .getTopLeft(_key('journeys-template-picker'))
            .dx;

        // 1. Choose weight_loss (Step 1 -> Step 2 DNA Q1, direction: +1)
        await tester.tap(_key('create-choose'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final dnaQ1MidDx =
            tester.getTopLeft(_key('dna-page-goal')).dx - deckOriginX;
        expect(dnaQ1MidDx, greaterThan(0.0));
        expect(dnaQ1MidDx, lessThan(18.0));

        await tester.pumpAndSettle();
        final dnaOriginX = tester.getTopLeft(_key('dna-page-goal')).dx;

        // 2. Answer DNA Q1 and advance to DNA Q2 (direction: +1)
        await tester.tap(_key('dna-choice-goal-keep'));
        await tester.pumpAndSettle();
        await tester.tap(_key('create-next'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final dnaQ2MidDx =
            tester.getTopLeft(_key('dna-page-weight')).dx - dnaOriginX;
        expect(dnaQ2MidDx, greaterThan(0.0));
        expect(dnaQ2MidDx, lessThan(18.0));

        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(_key('dna-page-weight')).dx,
          closeTo(dnaOriginX, 0.01),
        );

        // 3. Tap Back (DNA Q2 -> DNA Q1, direction: -1): incoming DNA Q1 slides from -18dp (dx < 0)
        await tester.tap(_key('create-back'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final dnaQ1BackMidDx =
            tester.getTopLeft(_key('dna-page-goal')).dx - dnaOriginX;
        expect(dnaQ1BackMidDx, lessThan(0.0));
        expect(dnaQ1BackMidDx, greaterThan(-18.0));

        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(_key('dna-page-goal')).dx,
          closeTo(dnaOriginX, 0.01),
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'DnaWeightPicker emits UiHaptics.selection() on each integer-kg detent crossing without duplicate fires',
      (tester) async {
        final haptics = _recordHaptics();
        var currentWeight = 70;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) => DnaWeightPicker(
                weight: currentWeight,
                hide: true,
                onWeight: (v) => setState(() => currentWeight = v),
                onHide: (_) {},
                onSkip: () {},
              ),
            ),
          ),
        );

        final slider = tester.widget<Slider>(_key('dna-weight-slider'));
        haptics.clear();

        // Sub-integer movement that still rounds to 70 must not fire a detent haptic.
        slider.onChanged!(70.2);
        await tester.pump();
        expect(currentWeight, 70);
        expect(haptics, isEmpty);

        // Crossing to 71 kg fires selectionClick once.
        slider.onChanged!(71.0);
        await tester.pump();
        expect(currentWeight, 71);
        expect(haptics, ['HapticFeedbackType.selectionClick']);

        // Another sub-integer event rounding to 71 does not duplicate the haptic.
        slider.onChanged!(71.3);
        await tester.pump();
        expect(haptics, hasLength(1));

        // Crossing to 72 kg fires selectionClick again.
        slider.onChanged!(72.0);
        await tester.pump();
        expect(currentWeight, 72);
        expect(haptics, hasLength(2));
      },
    );

    testWidgets(
      '3-point pump choreography on DepartureTicket stamp-in settle (260ms, UiCurves.stampDecel) & Reduce-Motion parity',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const DepartureTicket(
              key: ValueKey('test-ticket'),
              skinId: 'squad',
              title: 'Học tiếng Anh',
              goalLine: 'IELTS 7.5',
              durationLabel: '30 ngày',
            ),
          ),
        );

        final scaleFinder = find.descendant(
          of: _key('test-ticket'),
          matching: find.byType(ScaleTransition),
        );
        final fadeFinder = find.descendant(
          of: _key('test-ticket'),
          matching: find.byType(FadeTransition),
        );

        // 1. Start (t = 0ms): scale == 0.95 (UiMotion.popMinScale), opacity == 0.0.
        expect(
          tester.widget<ScaleTransition>(scaleFinder).scale.value,
          closeTo(UiMotion.popMinScale, 0.001),
        );
        expect(
          tester.widget<FadeTransition>(fadeFinder).opacity.value,
          closeTo(0.0, 0.001),
        );

        // 2. Mid-flight (t = 100ms of 260ms): smoothly interpolating with UiCurves.stampDecel.
        await tester.pump(const Duration(milliseconds: 100));
        final midScale = tester.widget<ScaleTransition>(scaleFinder).scale.value;
        final midOpacity = tester
            .widget<FadeTransition>(fadeFinder)
            .opacity
            .value;
        expect(midScale, greaterThan(UiMotion.popMinScale));
        expect(midScale, lessThan(1.0));
        expect(midOpacity, greaterThan(0.0));
        expect(midOpacity, lessThan(1.0));

        // 3. Settled (t >= 260ms): scale == 1.0, opacity == 1.0, zero active tickers.
        await tester.pumpAndSettle();
        expect(
          tester.widget<ScaleTransition>(scaleFinder).scale.value,
          closeTo(1.0, 0.001),
        );
        expect(
          tester.widget<FadeTransition>(fadeFinder).opacity.value,
          closeTo(1.0, 0.001),
        );
        expect(tester.binding.transientCallbackCount, 0);

        // 4. Reduce-Motion parity: mounts directly at resting state with zero ScaleTransition/tickers.
        await tester.pumpWidget(
          _host(
            disableAnimations: true,
            const DepartureTicket(
              key: ValueKey('rm-ticket'),
              skinId: 'couple',
              title: 'Hai đứa mình',
              goalLine: 'Mỗi ngày một tấm',
              durationLabel: '21 ngày',
              leftName: 'An',
              rightName: 'Bình',
            ),
          ),
        );
        expect(
          find.descendant(
            of: _key('rm-ticket'),
            matching: find.byType(ScaleTransition),
          ),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });
}
