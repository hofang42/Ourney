import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';

void main() {
  for (final b in [Brightness.light, Brightness.dark]) {
    testWidgets('toast clears the UiScaffold pinned bottom slot ($b)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OurneyTheme.build(b),
          home: UiScaffold(
            bottom: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: UiButton(
                key: const ValueKey('pinned-post'),
                label: 'Post',
                onPressed: () {},
              ),
            ),
            child: const SizedBox(height: 40),
          ),
        ),
      );
      // The caller's context sits above the scaffold's pinned slot, like
      // the Post screen's State.
      showUiToast(tester.element(find.byType(UiScaffold)), 'Không đăng được');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final toast = tester.getRect(find.byKey(const ValueKey('ui-toast')));
      final post = tester.getRect(find.byKey(const ValueKey('pinned-post')));
      expect(toast.overlaps(post), isFalse);
      expect(toast.bottom, lessThanOrEqualTo(post.top));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('a caller offset is not added on top of the pinned height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OurneyTheme.build(Brightness.light),
        home: UiScaffold(
          bottom: Padding(
            padding: const EdgeInsets.all(20),
            child: UiButton(
              key: const ValueKey('pinned-post'),
              label: 'Create',
              onPressed: () {},
            ),
          ),
          child: const SizedBox(height: 40),
        ),
      ),
    );
    // Create-flow style: the caller already lifts the toast by 110.
    showUiToast(
      tester.element(find.byType(UiScaffold)),
      'Lỗi',
      bottomOffset: 110,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final toast = tester.getRect(find.byKey(const ValueKey('ui-toast')));
    final post = tester.getRect(find.byKey(const ValueKey('pinned-post')));
    final screenBottom = tester.getRect(find.byType(Scaffold).first).bottom;
    final pinned = screenBottom - post.top + 20;
    expect(toast.bottom, lessThanOrEqualTo(post.top));
    expect(
      screenBottom - toast.bottom,
      closeTo(110 > 36 + pinned ? 110 : 36 + pinned, 1),
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a toast from a bottom sheet still clears the pinned slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OurneyTheme.build(Brightness.light),
        home: UiScaffold(
          bottom: Padding(
            padding: const EdgeInsets.all(20),
            child: UiButton(
              key: const ValueKey('pinned-post'),
              label: 'Post',
              onPressed: () {},
            ),
          ),
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (sheet) => TextButton(
                  onPressed: () => showUiToast(sheet, 'Lỗi'),
                  child: const Text('toast'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final toast = tester.getRect(find.byKey(const ValueKey('ui-toast')));
    final post = tester.getRect(find.byKey(const ValueKey('pinned-post')));
    expect(toast.bottom, lessThanOrEqualTo(post.top));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
