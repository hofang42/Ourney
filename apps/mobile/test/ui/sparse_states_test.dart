import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/features/profile/widgets/profile_form.dart';
import 'package:ourney/features/reminders/l10n/generated/reminders_localizations.dart';
import 'package:ourney/features/reminders/ui/reminders_screen.dart';
import 'package:ourney/ui/ui.dart';

import '../features/reminders/reminders_fakes.dart';

const sparseCaptureKey = ValueKey('sparse-capture');

Future<GoRouter> pumpSparseState(
  WidgetTester tester, {
  required Widget child,
  Brightness brightness = Brightness.light,
  Size size = const Size(390, 844),
  double scale = 1,
  double bottomInset = 0,
  Locale locale = const Locale('vi'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final harness = await reminderHarness(journeys: []);
  addTearDown(harness.container.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => child),
      GoRoute(
        path: AppRoutes.journeyNew,
        builder: (_, _) => const Scaffold(body: Text('Template picker')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp.router(
        theme: OurneyTheme.build(brightness),
        locale: locale,
        localizationsDelegates: ourneyLocalizationsDelegates,
        supportedLocales: ourneySupportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: RepaintBoundary(key: sparseCaptureKey, child: child!),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return router;
}

Widget sparseProfileForm() => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: ProfileForm(submitLabel: 'Save', onSaved: () {}),
  ),
);

Future<void> openSparseAvatar(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('profile-avatar-pick')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    for (final locale in [const Locale('vi'), const Locale('en')]) {
      testWidgets(
        'reminders create action navigates, 360dp 1.35x $brightness $locale',
        (tester) async {
          final router = await pumpSparseState(
            tester,
            child: const RemindersScreen(),
            brightness: brightness,
            locale: locale,
            size: const Size(360, 780),
            scale: 1.35,
          );
          final context = tester.element(find.byType(RemindersScreen));
          final l10n = RemindersL10n.of(context);
          expect(find.text(l10n.reminders_emptyMessage), findsOneWidget);
          final action = find.byKey(const ValueKey('reminders-empty-create'));
          expect(
            tester.widget<UiButton>(action).variant,
            UiButtonVariant.primary,
          );
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
          await tester.tap(action);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.text('Template picker'), findsOneWidget);
          expect(router.canPop(), isTrue);
          router.pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byType(RemindersScreen), findsOneWidget);
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    }

    for (final compact in [false, true]) {
      testWidgets(
        'sheet sizes content and safe inset: compact=$compact $brightness',
        (tester) async {
          const contentKey = ValueKey('short-sheet-content');
          await pumpSparseState(
            tester,
            brightness: brightness,
            bottomInset: 34,
            child: Scaffold(
              body: UiSheet(
                compact: compact,
                child: const SizedBox(key: contentKey, height: 80),
              ),
            ),
          );
          final height = tester
              .getSize(find.byKey(const ValueKey('ui-sheet-outline')))
              .height;
          if (compact) {
            expect(
              height,
              tester.getSize(find.byKey(contentKey)).height +
                  UiSheet.topPadding +
                  UiSpace.md +
                  34,
            );
          } else {
            expect(height, UiSheet.minHeight);
          }
          expect(tester.takeException(), isNull);
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    }

    testWidgets(
      'avatar picker opts into compact sheet under 200dp $brightness',
      (tester) async {
        await pumpSparseState(
          tester,
          child: sparseProfileForm(),
          brightness: brightness,
        );
        await openSparseAvatar(tester);
        expect(tester.widget<UiSheet>(find.byType(UiSheet)).compact, isTrue);
        expect(
          tester.getSize(find.byKey(const ValueKey('ui-sheet-outline'))).height,
          lessThan(200),
        );
        expect(
          find.byKey(const ValueKey('profile-avatar-gallery')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('profile-avatar-camera')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  }
}
