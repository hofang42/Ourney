import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/bars.dart';
import 'package:ourney/ui/theme.dart';

void main() {
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
      expect(
        bar.bottom - sub.bottom,
        greaterThanOrEqualTo(8 - 0.01),
        reason: 'subtitle must keep 8dp above the hairline',
      );
      final title = tester.getRect(find.text('Bạn bè'));
      final back = tester.getRect(find.byType(UiBarIconButton));
      expect(back.center.dy, closeTo(title.center.dy, 1.0));
      final trail = tester.getRect(find.text('Thêm'));
      expect(trail.center.dy, closeTo(title.center.dy, 1.0));
      expect(sub.top, greaterThanOrEqualTo(title.bottom - 0.5));
    });
  }
}
