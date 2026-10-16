import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/shared/chunky_button.dart';
import 'package:ourney/shared/empty_state.dart';
import 'package:ourney/shared/needs_server_view.dart';
import 'package:ourney/shared/ourney_chip.dart';
import 'package:ourney/shared/streak_flame.dart';

import 'test_helpers.dart';

void main() {
  group('text scaling (NFR-5)', () {
    testWidgets('app clamps system text scale to 2x', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpOurneyApp(tester);
      final ctx = tester.element(
        find.byKey(const ValueKey('placeholder-camera')),
      );
      expect(
        MediaQuery.textScalerOf(ctx).scale(10),
        10 * OurneyTextScaleClamp.maxScale,
      );
      // No RenderFlex overflow in the shell or placeholder at max scale.
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('shell renders without overflow at ${scale}x', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320 * 3, 568 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpOurneyApp(
          tester,
          config: testBackendConfig,
          auth: FakeAuthRepository(userId: 'u'),
        );
        await tester.tap(find.text('Nhóm'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('shared widgets render without overflow at ${scale}x', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320 * 3, 568 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: testApp(
              SingleChildScrollView(
                child: Column(
                  children: [
                    ChunkyButton(
                      label: 'Đăng check-in hôm nay',
                      onPressed: () {},
                      icon: Icons.check_rounded,
                    ),
                    const OurneyChip(label: 'Giảm cân 30 ngày', selected: true),
                    const StreakFlame(days: 128, atRisk: true),
                    const SizedBox(height: 400, child: NeedsServerView()),
                    const SizedBox(
                      height: 400,
                      child: EmptyState(
                        title: 'Chưa có hành trình nào',
                        message: 'Tạo hành trình đầu tiên để bắt đầu.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('reduced motion', () {
    testWidgets('page transitions become a plain fade', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light)
                .copyWith(platform: TargetPlatform.iOS),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const Text('next')),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.ancestor(
          of: find.text('next'),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.text('next'),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
      await tester.pumpAndSettle();
      expect(find.text('next'), findsOneWidget);
    });

    testWidgets('platform transition is used normally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light)
              .copyWith(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const Text('next')),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.ancestor(
          of: find.text('next'),
          matching: find.byType(SlideTransition),
        ),
        findsWidgets,
      );
      await tester.pumpAndSettle();
    });
  });
}
