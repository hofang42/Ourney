import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/dock.dart';
import 'package:ourney/ui/theme.dart';
import 'package:ourney/ui/typography.dart';

const _labels = ['Hành trình', 'Nhóm', 'Hoạt động', 'Hồ sơ'];

Future<void> _loadBodyFont() async {
  final loader = FontLoader(UiFonts.body);
  for (final file in [
    'assets/fonts/BeVietnamPro-Regular.ttf',
    'assets/fonts/BeVietnamPro-Medium.ttf',
    'assets/fonts/BeVietnamPro-SemiBold.ttf',
    'assets/fonts/BeVietnamPro-Bold.ttf',
  ]) {
    final bytes = File(file).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<void> _pump(WidgetTester tester, double width, double scale) async {
  UiDockItem item(String l, int i) => UiDockItem(
    glyph: ['journeys', 'squad', 'activity', 'profile'][i],
    label: l,
    itemKey: ValueKey('t$i'),
    onPressed: () {},
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: OurneyTheme.build(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 700),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: UiDock(
              left: item(_labels[0], 0),
              extraLeft: [item(_labels[1], 1)],
              extraRight: [item(_labels[2], 2)],
              right: item(_labels[3], 3),
              snapLabel: 'Chụp',
              onSnap: () {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(_loadBodyFont);

  for (final (w, s) in [(320.0, 2.0), (360.0, 1.35), (390.0, 1.0)]) {
    testWidgets('all dock labels share one font size at ${w}dp x$s', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(w, 700);
      addTearDown(tester.view.reset);
      await _pump(tester, w, s);
      final sizes = <double>[];
      for (final l in _labels) {
        final text = tester.widget<Text>(find.text(l));
        final fit = tester.widget<FittedBox>(
          find
              .ancestor(of: find.text(l), matching: find.byType(FittedBox))
              .first,
        );
        expect(fit.fit, BoxFit.scaleDown);
        // Rendered size = font size x the FittedBox scale (must be 1).
        final box = tester.getSize(find.text(l));
        final fitted = tester.getSize(
          find
              .ancestor(of: find.text(l), matching: find.byType(FittedBox))
              .first,
        );
        expect(box.width, lessThanOrEqualTo(fitted.width + 0.01), reason: l);
        sizes.add(text.style!.fontSize!);
      }
      expect(sizes.toSet().length, 1, reason: 'sizes: $sizes');
      if (w == 320.0) {
        for (var i = 0; i < 4; i++) {
          final tab = tester.getSize(find.byKey(ValueKey('t$i')));
          expect(tab.width, greaterThanOrEqualTo(48), reason: 'tab $i width');
          expect(tab.height, greaterThanOrEqualTo(48), reason: 'tab $i height');
        }
      }
    });
  }

  for (final w in [360.0, 390.0, 412.0]) {
    testWidgets('Vietnamese dock labels stay >= 10dp at 360dp and 10.5dp from '
        '390dp up (1x, ${w}dp)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(w, 700);
      addTearDown(tester.view.reset);
      await _pump(tester, w, 1);
      for (final l in _labels) {
        final text = tester.widget<Text>(find.text(l));
        expect(
          text.style!.fontSize!,
          w >= 390 ? 10.5 : greaterThanOrEqualTo(10.2),
          reason: '$l at ${w}dp',
        );
      }
      for (var i = 0; i < 4; i++) {
        final box = tester.widget<ConstrainedBox>(
          find
              .ancestor(
                of: find.byKey(ValueKey('t$i')),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
        expect(
          box.constraints.maxWidth,
          greaterThanOrEqualTo(55 * 10 / 10.5),
          reason: 'tab $i',
        );
      }
    });
  }
}
