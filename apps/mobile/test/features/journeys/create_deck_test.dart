import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    testWidgets('all 6 cards render their skin preview, sample photos and HUD', (
      tester,
    ) async {
      await _open(tester);
      const expected = [
        ('weight_loss', 'quiet', ['deck-photo-quiet']),
        (
          'english_daily',
          'squad',
          ['deck-photo-squad-0', 'deck-photo-squad-1', 'deck-photo-squad-2'],
        ),
        ('workout_30', 'flexer', ['deck-photo-flexer']),
        ('travel', 'memory', ['deck-photo-memory']),
        ('couple', 'couple', ['deck-photo-couple-0', 'deck-photo-couple-1']),
        (
          'custom',
          'minimal',
          [
            'deck-photo-minimal-0',
            'deck-photo-minimal-1',
            'deck-photo-minimal-2',
            'deck-photo-minimal-3',
          ],
        ),
      ];
      for (final (keyName, skinId, photoKeys) in expected) {
        final card = _key('template-$keyName');
        expect(card, findsOneWidget);
        final preview = find.descendant(
          of: card,
          matching: _key('deck-preview-$skinId'),
        );
        expect(preview, findsOneWidget);
        expect(
          find.descendant(of: preview, matching: find.byType(Image)),
          findsNWidgets(photoKeys.length),
        );
        for (final pk in photoKeys) {
          expect(find.descendant(of: preview, matching: _key(pk)), findsOneWidget);
        }
        expect(
          find.descendant(of: card, matching: _key('deck-hud-$skinId')),
          findsOneWidget,
        );
      }
      // Memory Polaroid renders the sample photo, not the old trip icon fallback.
      expect(
        find.descendant(
          of: _key('deck-preview-memory'),
          matching: find.byType(OurneyIcon),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'at 393x852 focused card is >= 340pt and import link is <= 120pt above choose button',
      (tester) async {
        await _open(tester, size: const Size(393, 852));
        final cardRect = tester.getRect(_key('template-weight_loss'));
        expect(cardRect.height, greaterThanOrEqualTo(340));

        final counterBottom = tester
            .getBottomLeft(_key('create-deck-counter'))
            .dy;
        final importRect = tester.getRect(_key('create-import-link'));
        final chooseTop = tester.getTopLeft(_key('create-choose')).dy;
        expect(importRect.top, greaterThanOrEqualTo(counterBottom));

        final gap = chooseTop - importRect.bottom;
        expect(gap, greaterThanOrEqualTo(0));
        expect(gap, lessThanOrEqualTo(120));
      },
    );

    for (final dark in [false, true]) {
      for (final scale in [1.35, 2.0]) {
        testWidgets(
          'fits 320dp at ${scale}x (${dark ? 'dark' : 'light'})',
          (tester) async {
            tester.platformDispatcher.platformBrightnessTestValue = dark
                ? Brightness.dark
                : Brightness.light;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await _open(tester, size: const Size(320, 640));
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(_key('create-deck-next'));
            await tester.tap(_key('create-deck-next'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    for (final lang in ['en', 'vi']) {
      for (final size in const [Size(360, 780), Size(393, 852)]) {
        testWidgets(
          'chosen chip sits in the preview, never cut ($lang ${size.width})',
          (tester) async {
            await pumpJourneys(
              tester,
              location: AppRoutes.journeyNew,
              locale: Locale(lang),
            );
            tester.view.physicalSize = size;
            await tester.pumpAndSettle();

            for (var i = 0; i < 6; i++) {
              final chipFinder = _key('create-deck-chosen');
              expect(chipFinder, findsOneWidget);

              final stackFinder = find
                  .ancestor(of: chipFinder, matching: find.byType(Stack))
                  .first;
              final previewFinder = find.descendant(
                of: stackFinder,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith(
                        'deck-preview-',
                      ),
                ),
              );
              expect(previewFinder, findsOneWidget);

              final chipRect = tester.getRect(chipFinder);
              final previewRect = tester.getRect(previewFinder);
              expect(
                chipRect.left,
                greaterThanOrEqualTo(previewRect.left),
                reason: 'card $i left ($lang ${size.width})',
              );
              expect(
                chipRect.top,
                greaterThanOrEqualTo(previewRect.top),
                reason: 'card $i top ($lang ${size.width})',
              );
              expect(
                chipRect.right,
                lessThanOrEqualTo(previewRect.right),
                reason: 'card $i right ($lang ${size.width})',
              );
              expect(
                chipRect.bottom,
                lessThanOrEqualTo(previewRect.bottom),
                reason: 'card $i bottom ($lang ${size.width})',
              );

              final richTextFinder = find.descendant(
                of: chipFinder,
                matching: find.byType(RichText),
              );
              expect(richTextFinder, findsOneWidget);
              final render =
                  richTextFinder.evaluate().single.renderObject!
                      as RenderParagraph;
              expect(
                render.didExceedMaxLines,
                isFalse,
                reason: 'card $i text overflow ($lang ${size.width})',
              );

              if (i < 5) {
                await tester.tap(_key('create-deck-next'));
                await tester.pumpAndSettle();
              }
            }
          },
        );
      }
    }
  });
}
