import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: OurneyTheme.build(brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

const _mark = SizedBox(key: ValueKey('mark'), width: 18, height: 18);

void main() {
  for (final brightness in Brightness.values) {
    group('glyph parameter (${brightness.name})', () {
      testWidgets('UiButton shows the glyph instead of an IconData', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            UiButton(label: 'Go', glyph: _mark, onPressed: () {}),
            brightness: brightness,
          ),
        );
        expect(find.byKey(const ValueKey('mark')), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
      });

      testWidgets('UiIconButton and UiBarIconButton accept a glyph', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiIconButton(glyph: _mark, label: 'a', onPressed: () {}),
                UiBarIconButton(
                  glyph: const SizedBox(key: ValueKey('mark2'), width: 9),
                  label: 'b',
                  onPressed: () {},
                ),
              ],
            ),
            brightness: brightness,
          ),
        );
        expect(find.byKey(const ValueKey('mark')), findsOneWidget);
        expect(find.byKey(const ValueKey('mark2')), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
      });

      testWidgets('UiEmptyState, UiChip and UiTag accept a glyph', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            SingleChildScrollView(
              child: Column(
                children: [
                  const UiEmptyState(glyph: _mark, title: 'Trống'),
                  UiChip(
                    label: 'chip',
                    glyph: const SizedBox(key: ValueKey('chip-mark')),
                    onPressed: () {},
                  ),
                  const UiTag(
                    label: 'tag',
                    glyph: SizedBox(key: ValueKey('tag-mark')),
                  ),
                ],
              ),
            ),
            brightness: brightness,
          ),
        );
        expect(find.byKey(const ValueKey('mark')), findsOneWidget);
        expect(find.byKey(const ValueKey('chip-mark')), findsOneWidget);
        expect(find.byKey(const ValueKey('tag-mark')), findsOneWidget);
        expect(find.byType(Icon), findsNothing);
      });
    });
  }

  testWidgets('icon-less widgets without icon or glyph assert', (tester) async {
    expect(
      () => UiIconButton(label: 'x', onPressed: () {}),
      throwsAssertionError,
    );
  });

  testWidgets('dock draws one outside-only hard shadow (no double shadow)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        UiDock(
          snapLabel: 'Chụp',
          onSnap: () {},
          left: UiDockItem(
            icon: Icons.map,
            label: 'A',
            onPressed: () {},
            active: true,
          ),
          right: UiDockItem(icon: Icons.group, label: 'B', onPressed: () {}),
        ),
      ),
    );
    expect(
      find.descendant(of: find.byType(UiDock), matching: find.byType(ClipPath)),
      findsOneWidget,
    );
  });
}
