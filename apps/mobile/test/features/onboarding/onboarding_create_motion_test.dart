import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
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

    testWidgets(
      '3-point _SplashGate tap-to-skip FadeTransition (zero Opacity saveLayer) & Reduce-Motion parity (Android + iOS)',
      (tester) async {
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final prefs = await testPrefs();
        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            supabaseClientProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const OurneyApp(key: ValueKey('app-normal')),
          ),
        );
        await tester.pump();

        // 1. Start: splash is visible at opacity 1.0 with zero Opacity widgets.
        expect(_key('ui-splash'), findsOneWidget);
        expect(
          find.ancestor(
            of: _key('ui-splash'),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
        final gateFadeFinder = find.ancestor(
          of: _key('ui-splash'),
          matching: find.byType(FadeTransition),
        );
        expect(
          tester.widget<FadeTransition>(gateFadeFinder.first).opacity.value,
          closeTo(1.0, 0.001),
        );

        // Tap splash to skip hold and start 300ms fade-out.
        await tester.tap(_key('ui-splash'));
        await tester.pump();

        // 2. Mid-flight (t = 120ms of 300ms fade): opacity is strictly in (0, 1).
        await tester.pump(const Duration(milliseconds: 120));
        final midOpacity = tester
            .widget<FadeTransition>(gateFadeFinder.first)
            .opacity
            .value;
        expect(midOpacity, greaterThan(0.0));
        expect(midOpacity, lessThan(1.0));

        // 3. Settled: splash unmounts completely and zero tickers remain.
        await tester.pumpAndSettle();
        expect(_key('ui-splash'), findsNothing);
        expect(tester.binding.transientCallbackCount, 0);

        // 4. Reduce-Motion parity (Android disableAnimations & iOS reduceMotion):
        // 4a. Android disableAnimations: true (SemanticsBinding scales normal
        // AnimationController duration to 5%, so tap-to-skip completes within 75ms).
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        final rmAndroidContainer = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            supabaseClientProvider.overrideWithValue(null),
          ],
        );
        addTearDown(rmAndroidContainer.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: rmAndroidContainer,
            child: const OurneyApp(key: ValueKey('app-rm-android')),
          ),
        );
        await tester.pump();
        expect(_key('ui-splash'), findsOneWidget);
        await tester.tap(_key('ui-splash'));
        await tester.pumpAndSettle();
        expect(_key('ui-splash'), findsNothing);

        // 4b. iOS reduceMotion: true (runs 150ms UiMotion.reducedFade linear fade-out).
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        final rmIosContainer = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            supabaseClientProvider.overrideWithValue(null),
          ],
        );
        addTearDown(rmIosContainer.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: rmIosContainer,
            child: const OurneyApp(key: ValueKey('app-rm-ios')),
          ),
        );
        await tester.pump();
        expect(_key('ui-splash'), findsOneWidget);

        await tester.tap(_key('ui-splash'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        final rmMid = tester
            .widget<FadeTransition>(gateFadeFinder.first)
            .opacity
            .value;
        expect(rmMid, closeTo(0.5, 0.05));

        await tester.pumpAndSettle();
        expect(_key('ui-splash'), findsNothing);
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
      'OnboardingQuizStage under Reduce Motion (Android disableAnimations & iOS reduceMotion) uses opacity-only crossfade with zero horizontal slide offset',
      (tester) async {
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        for (final features in const [
          FakeAccessibilityFeatures(disableAnimations: true),
          FakeAccessibilityFeatures(reduceMotion: true),
        ]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();

          tester.platformDispatcher.accessibilityFeaturesTestValue = features;
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
        }
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      },
    );
  });

  group('Rank #13.3 — AuthScreen AnimatedSize morph & 280ms 4-oscillation OTP error shake', () {
    testWidgets(
      '3-point choreography on AuthScreen mode morph, incomplete & invalid OTP error shake (±6dp) + reject (lightImpact) haptic',
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

        // 1. Incomplete (< 6 digits) OTP submitted via soft-keyboard action sets
        // visible error + liveRegion, fires lightImpact (reject, never heavyImpact),
        // and shakes horizontally.
        await tester.enterText(_key('auth-code'), '123');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(haptics, contains('HapticFeedbackType.lightImpact'));
        expect(haptics, isNot(contains('HapticFeedbackType.heavyImpact')));
        expect(_key('auth-error'), findsOneWidget);
        expect(tester.widget<UiOtpField>(_key('auth-code')).hasError, isTrue);

        await tester.pump(const Duration(milliseconds: 40));
        expect(otpShakeDx().abs(), greaterThan(0.1));
        await tester.pumpAndSettle();
        expect(otpShakeDx(), closeTo(0.0, 0.001));
        haptics.clear();

        // 2. Enter invalid 6-digit OTP to trigger server verify error + 280ms 4-oscillation shake.
        await tester.enterText(_key('auth-code'), '123456');
        await tester.pump();

        expect(haptics, contains('HapticFeedbackType.lightImpact'));
        expect(haptics, isNot(contains('HapticFeedbackType.heavyImpact')));
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
      'AuthScreen under Reduce Motion (Android disableAnimations & iOS reduceMotion) skips OTP horizontal shake while keeping red error state, liveRegion & reject haptic on incomplete/invalid codes',
      (tester) async {
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        final haptics = _recordHaptics();
        for (final features in const [
          FakeAccessibilityFeatures(disableAnimations: true),
          FakeAccessibilityFeatures(reduceMotion: true),
        ]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();

          tester.platformDispatcher.accessibilityFeaturesTestValue = features;
          final auth = RecordingAuthRepository()
            ..verifyOtpError = const OurneyException(OurneyErrorCode.invalid);
          await pumpBackendApp(tester, auth: auth);

          await tester.enterText(_key('auth-email'), 'a@b.co');
          await tester.tap(_key('auth-send'));
          await tester.pumpAndSettle();

          // Incomplete (< 6 digits) soft-keyboard submit under Reduce Motion:
          // must still show red error outline + UiFlowError liveRegion + lightImpact.
          haptics.clear();
          await tester.enterText(_key('auth-code'), '12');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 40));
          expect(
            tester
                .widget<Transform>(_key('auth-otp-shake'))
                .transform
                .getTranslation()
                .x,
            0.0,
          );
          expect(haptics, contains('HapticFeedbackType.lightImpact'));
          expect(haptics, isNot(contains('HapticFeedbackType.heavyImpact')));
          expect(_key('auth-error'), findsOneWidget);
          expect(tester.widget<UiOtpField>(_key('auth-code')).hasError, isTrue);

          // Invalid 6-digit code under Reduce Motion:
          haptics.clear();
          await tester.enterText(_key('auth-code'), '123456');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 40));

          final t = tester.widget<Transform>(_key('auth-otp-shake'));
          expect(t.transform.getTranslation().x, 0.0);
          expect(haptics, contains('HapticFeedbackType.lightImpact'));
          expect(haptics, isNot(contains('HapticFeedbackType.heavyImpact')));
          expect(_key('auth-error'), findsOneWidget);
        }
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      },
    );

    testWidgets(
      'AuthScreen method & step switches (email <-> phone <-> password <-> reset <-> codeStep) never overlap outgoing and incoming titles (>0.05 opacity) at midpoint or when keyboard is open, including Reduce Motion',
      (tester) async {
        double effectiveOpacity(Finder target) {
          if (target.evaluate().isEmpty) return 0.0;
          var alpha = 1.0;
          for (final fade in tester.widgetList<FadeTransition>(
            find.ancestor(of: target, matching: find.byType(FadeTransition)),
          )) {
            alpha *= fade.opacity.value;
          }
          for (final op in tester.widgetList<Opacity>(
            find.ancestor(of: target, matching: find.byType(Opacity)),
          )) {
            alpha *= op.opacity;
          }
          return alpha;
        }

        Future<void> assertNoMidFlightOverlap(
          String outgoingStepKey,
          String incomingStepKey,
        ) async {
          // Sample at 20% (44ms), 35% (77ms), 50% midpoint (110ms), and 75% (165ms) of 220ms UiMotion.medium.
          final samples = <int>[44, 33, 33, 55];
          for (var i = 0; i < samples.length; i++) {
            await tester.pump(Duration(milliseconds: samples[i]));
            final outAlpha = effectiveOpacity(_key(outgoingStepKey));
            final inAlpha = effectiveOpacity(_key(incomingStepKey));
            expect(
              outAlpha > 0.05 && inAlpha > 0.05,
              isFalse,
              reason:
                  'Auth overlap between $outgoingStepKey (alpha=$outAlpha) and $incomingStepKey (alpha=$inAlpha)',
            );
            if (i == 0) {
              // At 20% (44ms): outgoing child is actively visible (> 0.1) and incoming is 0.0.
              expect(outAlpha, greaterThan(0.1));
              expect(inAlpha, 0.0);
            } else if (i == 2) {
              // At 50% (110ms): outgoing child has reached 0.0 and incoming is actively visible (> 0.2).
              expect(outAlpha, 0.0);
              expect(inAlpha, greaterThan(0.2));
            }
          }
          await tester.pumpAndSettle();
          expect(_key(outgoingStepKey), findsNothing);
          expect(effectiveOpacity(_key(incomingStepKey)), closeTo(1.0, 0.001));
          expect(tester.takeException(), isNull);
        }

        final auth = RecordingAuthRepository();
        await pumpBackendApp(tester, auth: auth, phoneAvailable: true);

        // 1. Email tab -> Phone tab (header wordmark stays static; height shrinks smoothly from t=0ms)
        final emailHeight = tester
            .getSize(find.byType(UiDirectionalSwitcher))
            .height;
        await tester.tap(_key('auth-tab-phone'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 44)); // 20%
        expect(effectiveOpacity(_key('auth-step-email')), greaterThan(0.1));
        expect(effectiveOpacity(_key('auth-step-phoneCode')), 0.0);
        await tester.pump(const Duration(milliseconds: 66)); // 50% midpoint (110ms)
        expect(effectiveOpacity(_key('auth-step-email')), 0.0);
        expect(effectiveOpacity(_key('auth-step-phoneCode')), greaterThan(0.2));
        expect(
          effectiveOpacity(_key('auth-step-email')) > 0.05 &&
              effectiveOpacity(_key('auth-step-phoneCode')) > 0.05,
          isFalse,
        );
        final midShrinkHeight = tester
            .getSize(find.byType(UiDirectionalSwitcher))
            .height;
        expect(midShrinkHeight, lessThan(emailHeight));
        await tester.pumpAndSettle();
        final phoneHeight = tester
            .getSize(find.byType(UiDirectionalSwitcher))
            .height;
        expect(phoneHeight, lessThan(emailHeight));

        // 2. Phone tab -> Email tab (reverse direction -1)
        await tester.tap(_key('auth-tab-email'));
        await tester.pump();
        await assertNoMidFlightOverlap(
          'auth-step-phoneCode',
          'auth-step-email',
        );

        // 2b. Rapid mid-transition toggle (Email -> Phone -> Email at t = 110ms midpoint):
        // Phone never snaps to 0.0 on the reversal frame and never overlaps Email.
        await tester.tap(_key('auth-tab-phone'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 110)); // 50% midpoint
        final phoneBeforeReverse = effectiveOpacity(_key('auth-step-phoneCode'));
        expect(phoneBeforeReverse, greaterThan(0.4));
        // Outgoing step's tab copy is wrapped in IgnorePointer, leaving exactly one hitTestable tab.
        expect(_key('auth-tab-email').hitTestable(), findsOneWidget);

        await tester.tap(_key('auth-tab-email').hitTestable());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        final phoneAt1ms = effectiveOpacity(_key('auth-step-phoneCode'));
        final emailAt1ms = effectiveOpacity(_key('auth-step-email').last);
        expect(phoneAt1ms, greaterThan(0.4));
        expect(emailAt1ms, 0.0);

        await tester.pump(const Duration(milliseconds: 43)); // +44ms (20% of reversal)
        expect(effectiveOpacity(_key('auth-step-phoneCode')), greaterThan(0.05));
        expect(effectiveOpacity(_key('auth-step-email').last), 0.0);
        await tester.pumpAndSettle();
        expect(_key('auth-step-phoneCode'), findsNothing);
        expect(effectiveOpacity(_key('auth-step-email')), closeTo(1.0, 0.001));

        // 3. Email code -> Password sub-form -> Forgot password reset sub-form -> back
        await tester.ensureVisible(_key('auth-use-password'));
        await tester.pumpAndSettle();
        await tester.tap(_key('auth-use-password'));
        await tester.pump();
        await assertNoMidFlightOverlap('auth-step-email', 'auth-step-password');

        await tester.ensureVisible(_key('auth-forgot'));
        await tester.pumpAndSettle();
        await tester.tap(_key('auth-forgot'));
        await tester.pump();
        await assertNoMidFlightOverlap('auth-step-password', 'auth-step-reset');

        await tester.tap(_key('auth-flow-back'));
        await tester.pump();
        await assertNoMidFlightOverlap('auth-step-reset', 'auth-step-password');

        await tester.tap(_key('auth-flow-back'));
        await tester.pump();
        await assertNoMidFlightOverlap('auth-step-password', 'auth-step-email');

        // 4. Keyboard-open case (viewInsets.bottom = 300): Email form -> Code step -> Back
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();

        await tester.enterText(_key('auth-email'), 'user@ourney.app');
        await tester.ensureVisible(_key('auth-send'));
        await tester.pumpAndSettle();
        await tester.tap(_key('auth-send'));
        await tester.pump();
        await assertNoMidFlightOverlap('auth-step-email', 'auth-step-code');

        await tester.tap(_key('auth-back'));
        await tester.pump();
        await assertNoMidFlightOverlap('auth-step-code', 'auth-step-email');
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();

        // 5. Reduce Motion parity (iOS reduceMotion & Android disableAnimations):
        // never overlaps outgoing and incoming titles at t = 75ms midpoint of 150ms reducedFade.
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pump();

        await tester.ensureVisible(_key('auth-use-password'));
        await tester.pumpAndSettle();
        await tester.tap(_key('auth-use-password'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        final rmOut = effectiveOpacity(_key('auth-step-email'));
        final rmIn = effectiveOpacity(_key('auth-step-password'));
        expect(rmOut > 0.05 && rmIn > 0.05, isFalse);
        await tester.pumpAndSettle();
        expect(_key('auth-step-password'), findsOneWidget);
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
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
      '3-point programmatic Prev/Next button choreography: fires exactly 1 selectionClick haptic without mid-flight focus/counter flicker and caches _DeckCard subtrees during 320ms UiSkinScope morph',
      (tester) async {
        final haptics = _recordHaptics();
        await pumpJourneys(
          tester,
          location: AppRoutes.journeyNew,
          locale: const Locale('en'),
        );
        // Re-enable normal motion (pumpJourneys defaults to disableAnimations).
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        await tester.pump();

        // Verify SingleChildScrollView uses Clip.none so bottom 4dp hard shadows never clip.
        final scrollView = tester.widget<SingleChildScrollView>(
          _key('create-deck-scroll'),
        );
        expect(scrollView.clipBehavior, Clip.none);

        FadeTransition cardFade(String keyName) =>
            tester.widget<FadeTransition>(
              find
                  .ancestor(
                    of: _key('template-$keyName'),
                    matching: find.byType(FadeTransition),
                  )
                  .first,
            );

        haptics.clear();

        // 1. Start (t = 0ms): tap Next (card 0 -> card 1).
        await tester.tap(_key('create-deck-next'));
        await tester.pump();

        expect(find.text('2/6'), findsOneWidget);
        expect(find.text('1/6'), findsNothing);
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        expect(
          UiSkinScope.of(tester.element(_key('journeys-create-flow'))).skin.id,
          'squad',
        );

        // Capture the SingleChildScrollView widget identity after the focus state
        // update to prove that subsequent 320ms UiSkinScope theme-morph ticks do
        // NOT rebuild CreateTypeDeck.build or LayoutBuilder.
        final deckScrollAtStart = tester.widget(_key('create-deck-scroll'));

        // 2. Early & mid-flight ticks (t = 16ms, 48ms, 110ms of 220ms animateTo):
        // At t = 16ms, scroll offset is still < 0.5 * step (nearest == 0),
        // which must NEVER flip _focused back to 0 or fire extra selection haptics.
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.text('2/6'), findsOneWidget);
        expect(find.text('1/6'), findsNothing);
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        expect(
          tester.widget(_key('create-deck-scroll')),
          same(deckScrollAtStart),
        );

        await tester.pump(const Duration(milliseconds: 32));
        expect(find.text('2/6'), findsOneWidget);
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        final midOpacity0 = cardFade('weight_loss').opacity.value;
        final midOpacity1 = cardFade('english_daily').opacity.value;
        expect(midOpacity0, greaterThan(0.66));
        expect(midOpacity0, lessThan(1.0));
        expect(midOpacity1, greaterThan(0.66));
        expect(midOpacity1, lessThan(1.0));
        expect(
          tester.widget(_key('create-deck-scroll')),
          same(deckScrollAtStart),
        );

        await tester.pump(const Duration(milliseconds: 62));
        expect(find.text('2/6'), findsOneWidget);
        expect(haptics, ['HapticFeedbackType.selectionClick']);

        // 3. Settled: card 1 rests at opacity 1.0, total haptics == 1.
        await tester.pumpAndSettle();
        expect(find.text('2/6'), findsOneWidget);
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        expect(cardFade('english_daily').opacity.value, closeTo(1.0, 0.001));
        expect(cardFade('weight_loss').opacity.value, closeTo(0.66, 0.001));

        // Now tap Prev (card 1 -> card 0) and verify 3-point stability in reverse.
        haptics.clear();
        await tester.tap(_key('create-deck-prev'));
        await tester.pump();
        expect(find.text('1/6'), findsOneWidget);
        expect(haptics, ['HapticFeedbackType.selectionClick']);

        await tester.pump(const Duration(milliseconds: 16));
        expect(find.text('1/6'), findsOneWidget);
        expect(find.text('2/6'), findsNothing);
        expect(haptics, ['HapticFeedbackType.selectionClick']);

        await tester.pumpAndSettle();
        expect(find.text('1/6'), findsOneWidget);
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        expect(cardFade('weight_loss').opacity.value, closeTo(1.0, 0.001));
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      'CreateTypeDeck under Reduce Motion (Android disableAnimations & iOS reduceMotion) disables tilt/scale interpolation and jumps cleanly on Prev/Next',
      (tester) async {
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        final haptics = _recordHaptics();
        await pumpJourneys(
          tester,
          location: AppRoutes.journeyNew,
          locale: const Locale('en'),
        );

        // 1. Android disableAnimations: true
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        await tester.pump();

        haptics.clear();
        await tester.tap(_key('create-deck-next'));
        await tester.pumpAndSettle();

        expect(find.text('2/6'), findsOneWidget);
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        expect(tester.binding.transientCallbackCount, 0);

        // 2. iOS reduceMotion: true
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        await tester.pump();

        haptics.clear();
        await tester.tap(_key('create-deck-prev'));
        await tester.pumpAndSettle();

        expect(find.text('1/6'), findsOneWidget);
        expect(haptics, ['HapticFeedbackType.selectionClick']);
        expect(tester.binding.transientCallbackCount, 0);
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
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
        num currentWeight = 70;

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

        // 4. Reduce-Motion parity (Android disableAnimations & iOS reduceMotion):
        // mounts directly at resting state with zero ScaleTransition/tickers.
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

        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          _host(
            const DepartureTicket(
              key: ValueKey('rm-ios-ticket'),
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
            of: _key('rm-ios-ticket'),
            matching: find.byType(ScaleTransition),
          ),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      },
    );

    testWidgets(
      '3-point DnaForge seal breathing pulse & Reduce-Motion parity (Android disableAnimations + iOS reduceMotion at resting scale 1.0 with zero tickers)',
      (tester) async {
        await tester.pumpWidget(_host(const DnaForge()));

        final scaleFinder = find.descendant(
          of: _key('dna-forge'),
          matching: find.byType(ScaleTransition),
        );

        // 1. Start (t = 0ms): begins at 0.9 scale.
        expect(
          tester.widget<ScaleTransition>(scaleFinder).scale.value,
          closeTo(0.9, 0.001),
        );

        // 2. Mid-flight (t = 600ms of 1200ms): passes through 1.0.
        await tester.pump(const Duration(milliseconds: 600));
        final midScale = tester.widget<ScaleTransition>(scaleFinder).scale.value;
        expect(midScale, greaterThan(0.95));
        expect(midScale, lessThan(1.05));

        // 3. Peak (t = 1200ms): reaches 1.1.
        await tester.pump(const Duration(milliseconds: 600));
        expect(
          tester.widget<ScaleTransition>(scaleFinder).scale.value,
          closeTo(1.1, 0.001),
        );

        // 4. Reduce-Motion parity (Android disableAnimations & iOS reduceMotion):
        // omits ScaleTransition (resting scale 1.0) and allocates zero tickers.
        await tester.pumpWidget(
          _host(disableAnimations: true, const DnaForge()),
        );
        expect(
          find.descendant(
            of: _key('dna-forge'),
            matching: find.byType(ScaleTransition),
          ),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);

        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(_host(const DnaForge()));
        expect(
          find.descendant(
            of: _key('dna-forge'),
            matching: find.byType(ScaleTransition),
          ),
          findsNothing,
        );
        expect(tester.binding.transientCallbackCount, 0);
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      },
    );
  });
}
