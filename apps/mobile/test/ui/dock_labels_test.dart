import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/dock.dart';
import 'package:ourney/ui/theme.dart';

const _labels = ['Hành trình', 'Nhóm', 'Hoạt động', 'Hồ sơ'];

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
    });
  }
}
