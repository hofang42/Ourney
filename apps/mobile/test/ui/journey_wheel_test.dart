import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';

import '../app/test_helpers.dart';

const _items = [
  UiJourneyWheelItem(id: 'a', label: 'Giảm cân', type: 'weight'),
  UiJourneyWheelItem(id: 'b', label: 'Tiếng Anh mỗi ngày', type: 'study'),
  UiJourneyWheelItem(id: 'c', label: 'Chuyến đi Đà Lạt', type: 'trip'),
  UiJourneyWheelItem(id: 'd', label: 'Cặp đôi', type: 'couple'),
  UiJourneyWheelItem(id: 'e', label: 'Tập luyện', type: 'workout'),
  UiJourneyWheelItem(id: 'f', label: 'Tự đặt', type: 'custom'),
];

void main() {
  Future<List<String>> open(
    WidgetTester tester, {
    double width = 320,
    double textScale = 1.0,
    int count = 3,
    bool disableAnimations = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 640);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final picked = <String>[];
    late BuildContext ctx;
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    unawaited(
      showUiJourneyWheel(
        ctx,
        items: _items.take(count).toList(),
        activeId: 'b',
        anchor: Offset(width / 2, 580),
        onSelect: picked.add,
      ),
    );
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('badges sit inside the screen at 320dp and 1.35x', (
    tester,
  ) async {
    await open(tester, textScale: 1.35, count: 6);
    const screen = Rect.fromLTWH(0, 0, 320, 640);
    for (final item in _items) {
      final r = tester.getRect(
        find.byKey(ValueKey('journey-wheel-${item.id}')),
      );
      expect(
        screen.contains(r.topLeft) && screen.contains(r.bottomRight),
        isTrue,
        reason: '${item.id} $r',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a badge selects it and closes without navigating', (
    tester,
  ) async {
    final picked = await open(tester);
    await tester.tap(find.byKey(const ValueKey('journey-wheel-c')));
    await tester.pumpAndSettle();
    expect(picked, ['c']);
    expect(find.byKey(const ValueKey('journey-wheel-c')), findsNothing);
  });

  testWidgets('backdrop tap and close button dismiss without selecting', (
    tester,
  ) async {
    final picked = await open(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journey-wheel-a')), findsNothing);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('journey-wheel-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journey-wheel-a')), findsNothing);
    expect(picked, isEmpty);
  });

  testWidgets('semantics: labelled buttons, active one selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('journey-wheel-b'))),
      matchesSemantics(
        label: 'Tiếng Anh mỗi ngày, đang chọn',
        isButton: true,
        isSelected: true,
        isEnabled: true,
        hasEnabledState: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel('Đóng'), findsWidgets);
    handle.dispose();
  });

  test('layout clamps every center inside the screen', () {
    for (final n in [1, 2, 5, 6, 9]) {
      final pts = UiJourneyWheel.layout(
        n,
        const Offset(160, 580),
        const Size(320, 640),
      );
      expect(pts, hasLength(n));
      for (final p in pts) {
        expect(p.dx, inInclusiveRange(44, 276));
        expect(p.dy, greaterThanOrEqualTo(34));
        expect(p.dy, lessThan(580));
      }
    }
  });
}
