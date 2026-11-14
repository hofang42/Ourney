import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';

Widget app(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(390, 844),
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
    ),
    child: MaterialApp(
      theme: OurneyTheme.build(brightness),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('sheet: radius, outline, accent shadow and dismiss', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showUiSheet<void>(
                context: context,
                accent: const Color(0xFF00AA55),
                builder: (_) => const Text('Nội dung'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Nội dung'), findsOneWidget);
    final box = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('ui-sheet-outline')),
    );
    final deco = box.decoration as BoxDecoration;
    expect(
      deco.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(24)),
    );
    expect(deco.boxShadow!.single.offset, const Offset(0, -4));
    expect(deco.boxShadow!.single.color, const Color(0xFF00AA55));
    expect(deco.boxShadow!.single.blurRadius, 0);
    expect(deco.color, OurneyUi.light.ink);

    await tester.fling(find.text('Nội dung'), const Offset(0, 500), 2000);
    await tester.pumpAndSettle();
    expect(find.text('Nội dung'), findsNothing);
  });

  testWidgets('sheet default accent is brand', (tester) async {
    await tester.pumpWidget(
      app(const UiSheet(child: Text('x')), brightness: Brightness.dark),
    );
    final deco =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('ui-sheet-outline')),
                )
                .decoration
            as BoxDecoration;
    expect(deco.boxShadow!.single.color, OurneyUi.dark.brand);
    expect(deco.color, OurneyUi.dark.ink);
  });

  for (final b in [Brightness.light, Brightness.dark]) {
    testWidgets('toast shows and auto-hides ($b)', (tester) async {
      final ui = b == Brightness.dark ? OurneyUi.dark : OurneyUi.light;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showUiToast(context, 'Đã lưu'),
              child: const Text('go'),
            ),
          ),
          brightness: b,
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final c = tester.widget<Container>(
        find.byKey(const ValueKey('ui-toast')),
      );
      final d = c.decoration! as BoxDecoration;
      expect(d.color, ui.ink);
      expect(d.boxShadow!.single.color, ui.brand);
      expect(d.boxShadow!.single.offset, const Offset(3, 3));
      expect(tester.widget<Text>(find.text('Đã lưu')).style!.color, ui.bg);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Đã lưu'), findsNothing);
    });
  }

  testWidgets('skeleton animates, and stops with disableAnimations', (
    tester,
  ) async {
    Alignment begin() {
      final c = tester.widget<Container>(find.byType(Container).first);
      return ((c.decoration! as BoxDecoration).gradient! as LinearGradient)
              .begin
          as Alignment;
    }

    await tester.pumpWidget(app(const UiSkeleton(width: 100)));
    await tester.pump(const Duration(milliseconds: 400));
    final moving = begin();
    await tester.pump(const Duration(milliseconds: 400));
    expect(begin(), isNot(moving));

    await tester.pumpWidget(
      app(const UiSkeleton(width: 100), disableAnimations: true),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final still = begin();
    await tester.pump(const Duration(milliseconds: 600));
    expect(begin(), still);
  });

  testWidgets('empty state renders and fires action', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      app(
        UiEmptyState(
          icon: Icons.photo_outlined,
          title: 'Chưa có khoảnh khắc nào',
          body: 'Chụp tấm đầu tiên nhé.',
          actionLabel: 'Chụp ngay',
          onAction: () => n++,
        ),
      ),
    );
    expect(find.text('Chưa có khoảnh khắc nào'), findsOneWidget);
    final deco =
        tester
                .widget<Container>(find.byKey(const ValueKey('ui-empty-icon')))
                .decoration!
            as BoxDecoration;
    expect(deco.shape, BoxShape.circle);
    expect(deco.boxShadow!.single.offset, const Offset(3, 3));
    await tester.tap(find.text('Chụp ngay'));
    expect(n, 1);
  });

  testWidgets('banner semantics and retry', (tester) async {
    var n = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        UiBanner(
          message: 'Mất kết nối mạng',
          kind: UiBannerKind.readOnly,
          retryLabel: 'Thử lại',
          onRetry: () => n++,
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('Mất kết nối mạng')), findsWidgets);
    expect(tester.getSize(find.text('Thử lại')).height, greaterThan(0));
    await tester.tap(find.text('Thử lại'));
    expect(n, 1);
    handle.dispose();
  });

  testWidgets('no overflow at 1.35x text and 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        const SingleChildScrollView(
          child: Column(
            children: [
              UiBanner(
                message: 'Bạn đang ngoại tuyến, thay đổi sẽ được đồng bộ khi có mạng trở lại.',
                retryLabel: 'Thử lại',
                onRetry: _noop,
              ),
              UiBanner(
                message: 'Hành trình đã lưu trữ',
                kind: UiBannerKind.archived,
              ),
              UiEmptyState(
                icon: Icons.inbox_outlined,
                title: 'Chưa có gì ở đây hết, thật đấy',
                body: 'Hãy bắt đầu bằng cách tạo một hành trình mới.',
                actionLabel: 'Tạo hành trình',
                onAction: _noop,
              ),
              UiInlineError(
                message: 'Không thể tải dữ liệu, vui lòng thử lại.',
              ),
              UiSkeleton(height: 40),
            ],
          ),
        ),
        textScale: 1.35,
        size: const Size(320, 640),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
