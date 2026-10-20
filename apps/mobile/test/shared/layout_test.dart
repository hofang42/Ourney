import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/shared/layout.dart';

void main() {
  group('width classes (CLAUDE.md §3)', () {
    test('compact below 360, standard below 410, large below 600', () {
      expect(OurneyLayout.classOf(320), OurneyWidthClass.compact);
      expect(OurneyLayout.classOf(359.9), OurneyWidthClass.compact);
      expect(OurneyLayout.classOf(360), OurneyWidthClass.standard);
      expect(OurneyLayout.classOf(390), OurneyWidthClass.standard);
      expect(OurneyLayout.classOf(410), OurneyWidthClass.large);
      expect(OurneyLayout.classOf(430), OurneyWidthClass.large);
      expect(OurneyLayout.classOf(600), OurneyWidthClass.tablet);
    });

    test('horizontal padding is 16 / 20 / 24', () {
      expect(OurneyLayout.horizontalPadding(320), 16);
      expect(OurneyLayout.horizontalPadding(390), 20);
      expect(OurneyLayout.horizontalPadding(430), 24);
      expect(OurneyLayout.horizontalPadding(834), 24);
    });

    test('card padding 16 and grid gap 12 on standard phones', () {
      expect(OurneyLayout.cardPadding(390), 16);
      expect(OurneyLayout.gridSpacing(390), 12);
      expect(OurneyLayout.cardPadding(320), lessThan(16));
      expect(OurneyLayout.gridSpacing(320), lessThan(12));
    });

    test('content is capped at 480 on phones and 520 on tablets', () {
      expect(OurneyLayout.contentMaxWidth(320), 320);
      expect(OurneyLayout.contentMaxWidth(430), 430);
      expect(OurneyLayout.contentMaxWidth(560), 480);
      expect(OurneyLayout.contentMaxWidth(834), 520);
    });

    test('a 2-column grid always fits its width', () {
      for (final w in [320.0, 360.0, 390.0, 430.0, 600.0, 1024.0]) {
        final cell = OurneyLayout.gridCellWidth(w);
        final used =
            2 * cell +
            OurneyLayout.gridSpacing(w) +
            2 * OurneyLayout.horizontalPadding(w);
        expect(used, lessThanOrEqualTo(w), reason: 'width $w');
        expect(cell, greaterThan(100), reason: 'width $w');
      }
    });
  });

  group('OurneyResponsiveBody', () {
    testWidgets('pads on a phone and centers a 520dp column on a tablet', (
      tester,
    ) async {
      Future<Rect> pumpAt(double width) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = Size(width, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData(),
              child: OurneyResponsiveBody(
                child: SizedBox(key: ValueKey('content'), height: 10),
              ),
            ),
          ),
        );
        return tester.getRect(find.byKey(const ValueKey('content')));
      }

      final phone = await pumpAt(390);
      expect(phone.left, 20);
      expect(phone.width, 390 - 40);

      final tablet = await pumpAt(834);
      expect(tablet.width, 520 - 48);
      expect(tablet.center.dx, closeTo(417, 0.5));
    });
  });
}
