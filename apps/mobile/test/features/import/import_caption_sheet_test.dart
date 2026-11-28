import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/import/data/import_draft.dart';
import 'package:ourney/features/import/ui/import_caption_sheet.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';

Finder key(String s) => find.byKey(ValueKey(s));
Future<void> frames(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets(
    'formatter leaves composing Vietnamese intact and caps committed emoji',
    (t) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await t.pumpWidget(
        testApp(
          UiCaptionField(
            controller: controller,
            fieldKey: const ValueKey('field'),
            semanticLabel: 'Caption',
            inputFormatters: const [CodePointLimitFormatter(140)],
          ),
        ),
      );
      await t.showKeyboard(key('field'));
      final text = '${List.filled(139, '😀').join()}ệa';
      t.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
          composing: TextRange(start: text.length - 2, end: text.length),
        ),
      );
      await t.pump();
      expect(controller.text, text);
      t.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
      await t.pump();
      expect(controller.text.runes.length, 140);
      expect(controller.text.endsWith('ệ'), isTrue);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  for (final action in ['next', 'done', 'back', 'scrim', 'date']) {
    testWidgets('caps composing text when saving via $action', (t) async {
      final photos = [
        for (var i = 0; i < 2; i++)
          DraftPhoto(
            id: '$i',
            path: 'missing.jpg',
            dedupeKey: '$i',
            order: i,
            date: LocalDate(2024, 2, i + 1),
          ),
      ];
      await t.pumpWidget(
        testApp(
          Builder(
            builder: (context) => UiButton(
              label: 'Open',
              onPressed: () => showImportCaptionSheet(
                context,
                ordered: photos,
                start: 0,
                onEditDate: (_) async {},
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await frames(t);
      await t.showKeyboard(key('import-caption-field'));
      final text = '${List.filled(139, String.fromCharCode(0x1f600)).join()}ab';
      t.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
          composing: TextRange(start: text.length - 2, end: text.length),
        ),
      );
      await frames(t);
      if (action == 'back') {
        Navigator.of(t.element(key('import-caption-field'))).pop();
      } else if (action == 'scrim') {
        await t.tapAt(const Offset(10, 10));
      } else {
        await t.tap(key('import-caption-$action'));
      }
      await frames(t);
      expect(photos.first.caption!.runes.length, captionMax);
      expect(validateCaption(normalizeCaption(photos.first.caption)), isNull);
      if (action == 'next') {
        await t.tap(key('import-caption-prev'));
        await frames(t);
        final field = t.widget<TextField>(key('import-caption-field'));
        expect(field.controller!.text.runes.length, captionMax);
      }
      await t.pumpWidget(const SizedBox());
      await frames(t);
    }, timeout: const Timeout(Duration(seconds: 30)));
  }

  for (final scrim in [false, true]) {
    testWidgets('dismissal saves current raw text (scrim=$scrim)', (t) async {
      final photo = DraftPhoto(
        id: 'p',
        path: 'missing.jpg',
        dedupeKey: 'p',
        order: 0,
        date: const LocalDate(2024, 2, 1),
      );
      await t.pumpWidget(
        testApp(
          Builder(
            builder: (context) => UiButton(
              label: 'Open',
              onPressed: () => showImportCaptionSheet(
                context,
                ordered: [photo],
                start: 0,
                onEditDate: (_) async {},
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await frames(t);
      await t.enterText(
        key('import-caption-field'),
        '  Chưa cắt khoảng trắng  ',
      );
      await frames(t);
      if (scrim) {
        await t.tapAt(const Offset(10, 10));
      } else {
        final context = t.element(key('import-caption-field'));
        Navigator.of(context).pop();
      }
      await frames(t);
      expect(photo.caption, '  Chưa cắt khoảng trắng  ');
      expect(key('import-caption-sheet'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 30)));
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'sheet retains focus, per-photo text, date selection at 360 / 1.35 ($brightness)',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(360, 800);
        t.platformDispatcher.textScaleFactorTestValue = 1.35;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final photos = [
          for (var i = 0; i < 2; i++)
            DraftPhoto(
              id: '$i',
              path: 'missing.jpg',
              dedupeKey: '$i',
              order: i,
              date: LocalDate(2024, 2, i + 1),
            ),
        ];
        await t.pumpWidget(
          testApp(
            Builder(
              builder: (context) => UiButton(
                label: 'Open',
                onPressed: () => showImportCaptionSheet(
                  context,
                  ordered: photos,
                  start: 0,
                  onEditDate: (p) async {
                    p.setDate(const LocalDate(2024, 2, 5));
                  },
                ),
              ),
            ),
            brightness: brightness,
          ),
        );
        await t.tap(find.text('Open'));
        await frames(t);
        expect(t.takeException(), isNull);
        await t.enterText(key('import-caption-field'), 'Kỷ niệm một');
        await frames(t);
        t.view.viewInsets = const FakeViewPadding(bottom: 280);
        await frames(t);
        TextField field() => t.widget<TextField>(key('import-caption-field'));
        expect(field().focusNode!.hasFocus, isTrue);
        final focus = field().focusNode;
        for (final name in ['next', 'prev']) {
          final rect = t.getRect(key('import-caption-$name'));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
        }
        await t.tap(key('import-caption-next'));
        await frames(t);
        expect(field().focusNode, same(focus));
        expect(focus!.hasFocus, isTrue);
        expect(field().controller!.text, isEmpty);
        await t.enterText(key('import-caption-field'), 'Kỷ niệm hai');
        await t.tap(key('import-caption-prev'));
        await frames(t);
        expect(field().controller!.text, 'Kỷ niệm một');
        await t.tap(key('import-caption-date'));
        await frames(t);
        expect(field().controller!.text, 'Kỷ niệm một');
        expect(photos.first.date, const LocalDate(2024, 2, 5));
        t.view.viewInsets = const FakeViewPadding();
        await frames(t);
        expect(
          focus.hasFocus,
          isFalse,
          reason: 'Android back restores the idle preview',
        );
        expect(t.takeException(), isNull);
        await t.tap(key('import-caption-done'));
        await frames(t);
        expect(photos.map((p) => p.caption), ['Kỷ niệm một', 'Kỷ niệm hai']);
        expect(t.takeException(), isNull);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  }
}
