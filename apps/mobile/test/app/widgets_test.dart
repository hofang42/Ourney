import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/shared/avatar.dart';
import 'package:ourney/shared/chunky_button.dart';
import 'package:ourney/shared/stamp_animation.dart';
import 'package:ourney/shared/streak_flame.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('ChunkyButton fires onPressed on tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      testApp(ChunkyButton(label: 'Dang', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Dang'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('ChunkyButton disabled does not fire', (tester) async {
    await tester.pumpWidget(
      testApp(const ChunkyButton(label: 'Dang', onPressed: null)),
    );
    await tester.tap(find.text('Dang'));
    await tester.pump();
    expect(find.text('Dang'), findsOneWidget);
  });

  testWidgets('ChunkyButton sinks 3pt while pressed', (tester) async {
    await tester.pumpWidget(
      testApp(ChunkyButton(label: 'Dang', onPressed: () {})),
    );
    double faceTop() => tester.getTopLeft(find.text('Dang')).dy;
    final rest = faceTop();
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Dang')),
    );
    await tester.pumpAndSettle();
    expect(faceTop() - rest, 3);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(faceTop(), rest);
  });

  testWidgets('StreakFlame static under reduce motion', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: testApp(const StreakFlame(days: 7, atRisk: true)),
      ),
    );
    // pumpAndSettle would hang if a repeating animation were running.
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('StampAnimation completes and respects reduce motion', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(
      testApp(
        StampAnimation(
          haptic: false,
          onCompleted: () => done++,
          child: const Text('stamp'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('stamp'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(done, 1);
  });

  test('Avatar initials', () {
    expect(Avatar.initialsOf('Nguyen Van An'), 'NA');
    expect(Avatar.initialsOf('  an '), 'A');
    expect(Avatar.initialsOf(''), '?');
  });
}
