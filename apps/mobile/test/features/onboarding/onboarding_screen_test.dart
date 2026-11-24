import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/onboarding/onboarding_providers.dart';
import 'package:ourney/features/onboarding/permission_sheets.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../profile/fakes.dart';

/// Pumps [OurneyApp] without settling, so the splash can be observed.
Future<ProviderContainer> pumpUnsettled(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.platformDispatcher.localesTestValue = [const Locale('vi')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final prefs = await testPrefs();
  final c = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      supabaseClientProvider.overrideWithValue(null),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const OurneyApp()),
  );
  await tester.pump(const Duration(milliseconds: 100));
  return c;
}

void main() {
  group('splash (V2 SplashFlow)', () {
    testWidgets('first launch: wordmark, six stickers and the tagline', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const SizedBox.expand(child: UiSplash(tagline: 'giữ một chuỗi.')),
        ),
      );
      expect(byKey('ui-splash'), findsOneWidget);
      expect(find.text('giữ một chuỗi.'), findsOneWidget);
      expect(find.bySemanticsLabel('ourney'), findsOneWidget);
      expect(find.byType(UiStickerTile), findsNWidgets(6));
    });

    testWidgets('returning launch: wordmark and spinner, no stickers', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(const SizedBox.expand(child: UiSplash(returning: true))),
      );
      expect(find.byType(UiStickerTile), findsNothing);
      expect(find.byType(UiRansomWordmark), findsOneWidget);
      expect(
        find.descendant(
          of: byKey('ui-splash'),
          matching: find.byType(RotationTransition),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the gate rotates taglines, then fades out', (tester) async {
      await pumpUnsettled(tester);
      expect(find.text('chụp một tấm.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('giữ một chuỗi.'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(byKey('ui-splash'), findsNothing);
    });

    testWidgets('a tap skips the hold', (tester) async {
      await pumpUnsettled(tester);
      await tester.tap(byKey('ui-splash'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(byKey('ui-splash'), findsNothing);
      await tester.pumpAndSettle();
    });
  });

  group('onboarding quiz (V2 OnboardingFlow)', () {
    testWidgets('opens on question 1 with six goals; skip finishes', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester, onboarded: false);
      expect(location(c), AppRoutes.onboarding);
      expect(byKey('onboarding-quiz-0'), findsOneWidget);
      expect(find.text('Câu 1/3'), findsOneWidget);
      expect(find.text('bạn đang muốn kiên trì điều gì?'), findsOneWidget);
      for (final g in const [
        'weight_loss',
        'english',
        'workout',
        'trip',
        'couple',
        'habit',
      ]) {
        expect(byKey('onboarding-goal-$g'), findsOneWidget);
      }
      // No back button on question 1; Continue is disabled until a choice.
      expect(byKey('onboarding-quiz-back'), findsNothing);
      // M1: local-only mode has no /auth, so "Have an account? Sign in" is hidden.
      expect(byKey('onboarding-have-account'), findsNothing);
      expect(
        tester.widget<UiFlowButton>(byKey('onboarding-quiz-next')).onPressed,
        isNull,
      );
      expect(c.read(onboardingCompleteProvider), isFalse);

      await tester.tap(byKey('onboarding-skip'));
      await tester.pumpAndSettle();
      expect(c.read(onboardingCompleteProvider), isTrue);
      expect(c.read(onboardingQuizProvider), isNull);
      expect(location(c), AppRoutes.capture);
    });

    testWidgets('choosing a goal fills the card, shows the badge, enables', (
      tester,
    ) async {
      await pumpOurneyApp(tester, onboarded: false);
      expect(byKey('ui-choice-check'), findsNothing);
      await tester.tap(byKey('onboarding-goal-english'));
      await tester.pumpAndSettle();
      expect(byKey('ui-choice-check'), findsOneWidget);
      expect(
        tester.widget<UiFlowButton>(byKey('onboarding-quiz-next')).onPressed,
        isNotNull,
      );
    });

    testWidgets('quiz answers are stored and suggest a template', (
      tester,
    ) async {
      final c = await pumpOurneyApp(tester, onboarded: false);
      await tester.tap(byKey('onboarding-goal-english'));
      await tester.pump();
      await tester.tap(byKey('onboarding-quiz-next'));
      await tester.pumpAndSettle();
      expect(find.text('Câu 2/3'), findsOneWidget);
      await tester.tap(byKey('onboarding-who-group'));
      await tester.pump();
      await tester.tap(byKey('onboarding-quiz-next'));
      await tester.pumpAndSettle();
      expect(find.text('Câu 3/3'), findsOneWidget);
      await tester.tap(byKey('onboarding-reminder-21:30'));
      await tester.pumpAndSettle();
      expect(byKey('onboarding-quiz-result'), findsOneWidget);
      expect(find.text('học tiếng anh.'), findsOneWidget);
      expect(find.text('Nhắc 21:30'), findsOneWidget);
      expect(find.text('Bắt đầu thôi'), findsOneWidget);
      await tester.ensureVisible(byKey('onboarding-quiz-next'));
      await tester.tap(byKey('onboarding-quiz-next'));
      await tester.pumpAndSettle();

      expect(c.read(onboardingCompleteProvider), isTrue);
      final quiz = c.read(onboardingQuizProvider)!;
      expect(quiz.goal, QuizGoal.english);
      expect(quiz.company, QuizCompany.group);
      expect(quiz.reminder, '21:30');
      final s = c.read(journeySuggestionProvider)!;
      expect(s.templateId, TemplateId.englishDaily);
      expect(s.kind, JourneyKind.group);
      expect(s.reminder, '21:30');
    });

    testWidgets('couple answer shows the style hint and the couple result', (
      tester,
    ) async {
      await pumpOurneyApp(tester, onboarded: false);
      await tester.tap(byKey('onboarding-goal-trip'));
      await tester.pump();
      await tester.tap(byKey('onboarding-quiz-next'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('onboarding-who-couple'));
      await tester.pumpAndSettle();
      expect(find.text('mình sẽ dùng phong cách Hai đứa mình'), findsOneWidget);
      await tester.tap(byKey('onboarding-quiz-next'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('onboarding-reminder-07:00'));
      await tester.pumpAndSettle();
      expect(find.text('hai đứa mình.'), findsOneWidget);
    });

    testWidgets('back returns to the previous question', (tester) async {
      await pumpOurneyApp(tester, onboarded: false);
      await tester.ensureVisible(byKey('onboarding-goal-habit'));
      await tester.tap(byKey('onboarding-goal-habit'));
      await tester.pump();
      await tester.tap(byKey('onboarding-quiz-next'));
      await tester.pumpAndSettle();
      expect(byKey('onboarding-quiz-1'), findsOneWidget);
      await tester.tap(byKey('onboarding-quiz-back'));
      await tester.pumpAndSettle();
      expect(byKey('onboarding-quiz-0'), findsOneWidget);
    });

    testWidgets('step segments: done, current and pending look different', (
      tester,
    ) async {
      await pumpOurneyApp(tester, onboarded: false);
      await tester.tap(byKey('onboarding-goal-english'));
      await tester.pump();
      await tester.tap(byKey('onboarding-quiz-next'));
      await tester.pumpAndSettle();
      BoxDecoration deco(int i) =>
          (tester.widget<AnimatedContainer>(byKey('onboarding-step-$i')))
                  .decoration!
              as BoxDecoration;
      double h(int i) => tester.getSize(byKey('onboarding-step-$i')).height;
      final done = deco(0), current = deco(1), pending = deco(2);
      expect(done.color, isNot(pending.color));
      expect(done.color, isNot(current.color));
      expect(h(1), greaterThan(h(0)));
      expect(h(0), h(2));
      expect(
        (current.border! as Border).top.width,
        greaterThan((done.border! as Border).top.width),
      );
    });

    testWidgets('skip completes and continues to sign-in with a backend', (
      tester,
    ) async {
      final c = await pumpBackendApp(
        tester,
        auth: RecordingAuthRepository(),
        onboarded: false,
      );
      expect(location(c), AppRoutes.onboarding);
      await tester.tap(byKey('onboarding-skip'));
      await tester.pumpAndSettle();
      expect(c.read(onboardingCompleteProvider), isTrue);
      expect(location(c), startsWith(AppRoutes.auth));
      expect(byKey('auth-screen'), findsOneWidget);
    });

    testWidgets(
      'have-account link shows only on Q1 with a backend and jumps to /auth '
      '(M1)',
      (tester) async {
        final c = await pumpBackendApp(
          tester,
          auth: RecordingAuthRepository(),
          onboarded: false,
        );
        expect(byKey('onboarding-have-account'), findsOneWidget);

        // Hidden on question 2.
        await tester.tap(byKey('onboarding-goal-english'));
        await tester.pump();
        await tester.tap(byKey('onboarding-quiz-next'));
        await tester.pumpAndSettle();
        expect(byKey('onboarding-have-account'), findsNothing);

        // Back to question 1, then tap "Đã có tài khoản? Đăng nhập".
        await tester.tap(byKey('onboarding-quiz-back'));
        await tester.pumpAndSettle();
        expect(byKey('onboarding-have-account'), findsOneWidget);
        await tester.ensureVisible(byKey('onboarding-have-account'));
        await tester.tap(byKey('onboarding-have-account'));
        await tester.pumpAndSettle();

        expect(c.read(onboardingCompleteProvider), isTrue);
        expect(c.read(onboardingQuizProvider), isNull);
        expect(location(c), startsWith(AppRoutes.auth));
        expect(byKey('auth-screen'), findsOneWidget);
      },
    );

    testWidgets('keeps the deep-link target in ?from=', (tester) async {
      final c = await pumpOurneyApp(tester, onboarded: false);
      await goTo(tester, c, AppRoutes.journeys);
      expect(location(c), startsWith(AppRoutes.onboarding));
      await tester.tap(byKey('onboarding-skip'));
      await tester.pumpAndSettle();
      expect(location(c), AppRoutes.journeys);
    });

    testWidgets('reduced motion still advances', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpOurneyApp(tester, onboarded: false);
      await tester.tap(byKey('onboarding-goal-workout'));
      await tester.pump();
      await tester.tap(byKey('onboarding-quiz-next'));
      await tester.pumpAndSettle();
      expect(byKey('onboarding-quiz-1'), findsOneWidget);
    });

    for (final dark in [false, true]) {
      testWidgets('no overflow at 1.35x and 2x text on small and large phones, '
          '${dark ? 'dark' : 'light'}', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.view.reset);
        for (final scale in [1.35, 2.0]) {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          for (final size in const [Size(320, 640), Size(390, 844)]) {
            tester.view.physicalSize = size * 3;
            tester.view.devicePixelRatio = 3;
            await tester.pumpWidget(const SizedBox());
            await pumpOurneyApp(tester, onboarded: false);
            Future<void> tapKey(String key) async {
              await tester.ensureVisible(byKey(key));
              await tester.tap(byKey(key));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: '$scale $size');
            }

            await tapKey('onboarding-goal-couple');
            await tapKey('onboarding-quiz-next');
            await tapKey('onboarding-who-couple');
            await tapKey('onboarding-quiz-next');
            await tapKey('onboarding-reminder-21:30');
          }
        }
      });
    }
  });

  group('permission sheets', () {
    Future<void> open(
      WidgetTester tester,
      Future<bool> Function(BuildContext) show,
      void Function(bool) onResult,
    ) async {
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open'),
              onPressed: () async => onResult(await show(context)),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(byKey('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('camera sheet resolves true on Allow', (tester) async {
      bool? result;
      await open(tester, showCameraPermissionSheet, (v) => result = v);
      expect(find.text('cho ourney dùng camera.'), findsOneWidget);
      await tester.tap(byKey('camera-permission-allow'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('camera sheet resolves false on Not now', (tester) async {
      bool? result;
      await open(tester, showCameraPermissionSheet, (v) => result = v);
      await tester.tap(byKey('camera-permission-later'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('camera sheet resolves false on the close button', (
      tester,
    ) async {
      bool? result;
      await open(tester, showCameraPermissionSheet, (v) => result = v);
      await tester.tap(find.bySemanticsLabel('Đóng'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('notification sheet names the reminder time', (tester) async {
      bool? result;
      await open(
        tester,
        (c) => showNotificationSheet(c, timeLabel: '21:00'),
        (v) => result = v,
      );
      expect(
        find.text('để mình khẽ nhắc trước khi chuỗi đứt.'),
        findsOneWidget,
      );
      expect(find.textContaining('21:00'), findsOneWidget);
      await tester.tap(byKey('notification-turn-on'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });
}
