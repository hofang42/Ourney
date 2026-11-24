import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/bars.dart';
import 'package:ourney/ui/theme.dart';

void main() {
  testWidgets('1x without a subtitle is the plain 56dp bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OurneyTheme.build(Brightness.light),
        home: Scaffold(
          body: UiBackHeader(
            key: const ValueKey('bar'),
            onBack: () {},
            backLabel: 'Back',
            title: 'Bạn bè',
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const ValueKey('bar'))).height, 56);
  });

  for (final scale in [1.0, 1.35, 2.0]) {
    testWidgets('UiBackHeader keeps air and alignment at x$scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: OurneyTheme.build(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 640),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: UiBackHeader(
                key: const ValueKey('bar'),
                onBack: () {},
                backLabel: 'Back',
                title: 'Bạn bè',
                subtitle: '2 người bạn · chỉ bạn thấy danh sách này',
                trailing: const Text('Thêm'),
              ),
            ),
          ),
        ),
      );
      final bar = tester.getRect(find.byKey(const ValueKey('bar')));
      final sub = tester.getRect(find.textContaining('2 người bạn'));
      final back = tester.getRect(find.byType(UiBarIconButton));
      final trail = tester.getRect(find.text('Thêm'));
      if (scale == 1.0) {
        // 1x keeps the single-row 56dp layout even with a long subtitle.
        expect(bar.height, 56);
        expect(
          bar.bottom - sub.bottom,
          greaterThanOrEqualTo(2.5),
          reason: '1x subtitle must stay clear of the bottom hairline',
        );
        expect(back.center.dy, closeTo(bar.center.dy, 1.0));
        expect(trail.center.dy, closeTo(bar.center.dy, 1.0));
        return;
      }
      expect(
        bar.bottom - sub.bottom,
        greaterThanOrEqualTo(8 - 0.01),
        reason: 'subtitle must keep 8dp above the hairline',
      );
      final title = tester.getRect(find.text('Bạn bè'));
      expect(back.center.dy, closeTo(title.center.dy, 1.0));
      expect(trail.center.dy, closeTo(title.center.dy, 1.0));
      expect(sub.top, greaterThanOrEqualTo(title.bottom - 0.5));
    });
  }
}
