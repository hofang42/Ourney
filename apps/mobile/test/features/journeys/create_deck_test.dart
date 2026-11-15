import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/ui/ui.dart';

import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _open(WidgetTester tester, {Size? size}) async {
  await pumpJourneys(
    tester,
    location: AppRoutes.journeyNew,
    locale: const Locale('en'),
  );
  if (size != null) {
    tester.view.physicalSize = size;
    await tester.pumpAndSettle();
  }
}

void main() {
  group('Create step 1: type deck (Figma CreateStepOne)', () {
    testWidgets('1/6 counter, prev/next buttons and the choose button', (
      tester,
    ) async {
      await _open(tester);
      expect(_key('create-deck'), findsOneWidget);
      expect(find.text('1/6'), findsOneWidget);
      expect(find.text('Chosen'), findsOneWidget);
      expect(
        tester.widget<UiIconButton>(_key('create-deck-prev')).onPressed,
        isNull,
      );
      await tester.tap(_key('create-deck-next'));
      await tester.pumpAndSettle();
      expect(find.text('2/6'), findsOneWidget);
      await tester.tap(_key('create-deck-prev'));
      await tester.pumpAndSettle();
      expect(find.text('1/6'), findsOneWidget);
      // The 6 cards exist, with the Figma semantics label.
      for (final k in [
        'weight_loss',
        'english_daily',
        'workout_30',
        'travel',
        'custom',
        'couple',
      ]) {
        expect(_key('template-$k'), findsOneWidget);
      }
      await tester.tap(_key('create-choose'));
      await tester.pumpAndSettle();
      expect(_key('dna-page-goal'), findsOneWidget);
    });

    testWidgets('next to the last card disables next and shows 6/6', (
      tester,
    ) async {
      await _open(tester);
      for (var i = 0; i < 5; i++) {
        await tester.tap(_key('create-deck-next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('6/6'), findsOneWidget);
      expect(
        tester.widget<UiIconButton>(_key('create-deck-next')).onPressed,
        isNull,
      );
    });

    for (final dark in [false, true]) {
      testWidgets('fits 320dp at 1.35x (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        tester.platformDispatcher.textScaleFactorTestValue = 1.35;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _open(tester, size: const Size(320, 640));
        expect(tester.takeException(), isNull);
        await tester.tap(_key('create-deck-next'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
