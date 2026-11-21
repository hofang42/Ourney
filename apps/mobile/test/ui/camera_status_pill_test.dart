import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';

Widget _host(Widget child, {bool reduce = false}) => MediaQuery(
  data: MediaQueryData(size: const Size(390, 844), disableAnimations: reduce),
  child: MaterialApp(
    theme: OurneyTheme.build(Brightness.dark),
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('pill is 32dp tall and fades with the visible flag', (t) async {
    await t.pumpWidget(
      _host(
        const UiCameraStatusPill(
          message: 'Flash: auto',
          glyph: 'flash-auto',
          visible: false,
        ),
      ),
    );
    final opacity = find.descendant(
      of: find.byType(UiCameraStatusPill),
      matching: find.byType(AnimatedOpacity),
    );
    expect(t.widget<AnimatedOpacity>(opacity).opacity, 0);
    await t.pumpWidget(
      _host(
        const UiCameraStatusPill(
          message: 'Flash: auto',
          glyph: 'flash-auto',
          visible: true,
        ),
      ),
    );
    expect(t.widget<AnimatedOpacity>(opacity).opacity, 1);
    expect(
      t.widget<AnimatedOpacity>(opacity).duration,
      const Duration(milliseconds: 150),
    );
    expect(
      t.getSize(find.byKey(const ValueKey('ui-camera-status-pill'))).height,
      UiCameraStatusPill.height,
    );
  });

  testWidgets('fade out takes 200ms, none under Reduce Motion', (t) async {
    await t.pumpWidget(
      _host(const UiCameraStatusPill(message: 'x', visible: false)),
    );
    final opacity = find.descendant(
      of: find.byType(UiCameraStatusPill),
      matching: find.byType(AnimatedOpacity),
    );
    expect(
      t.widget<AnimatedOpacity>(opacity).duration,
      const Duration(milliseconds: 200),
    );
    await t.pumpWidget(
      _host(
        const UiCameraStatusPill(message: 'x', visible: false),
        reduce: true,
      ),
    );
    expect(t.widget<AnimatedOpacity>(opacity).duration, Duration.zero);
  });

  testWidgets('pill is a live region carrying the message', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(
      _host(const UiCameraStatusPill(message: 'Flash: on', visible: true)),
    );
    final node = t.getSemantics(find.bySemanticsLabel('Flash: on'));
    expect(node.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });

  testWidgets('filled tool uses the accent disc', (t) async {
    await t.pumpWidget(
      _host(
        UiCameraTool(
          glyph: 'lightning',
          label: 'Flash',
          emphasis: UiCameraToolEmphasis.filled,
          accent: const Color(0xFFFF8A3D),
          onPressed: () {},
        ),
      ),
    );
    final disc = t.widget<Container>(
      find.descendant(
        of: find.byType(UiCameraTool),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
      ),
    );
    expect((disc.decoration! as BoxDecoration).color, const Color(0xFFFF8A3D));
  });
}
