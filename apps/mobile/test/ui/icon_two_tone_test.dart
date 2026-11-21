import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

OurneyIconPainter _painterOf(WidgetTester tester, Widget w) {
  final paint = tester.widget<CustomPaint>(
    find
        .descendant(of: find.byWidget(w), matching: find.byType(CustomPaint))
        .first,
  );
  return paint.painter! as OurneyIconPainter;
}

Future<void> _pump(WidgetTester tester, OurneyUi ui, List<Widget> kids) =>
    tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: ui.brightness, extensions: [ui]),
        home: Column(children: kids),
      ),
    );

void main() {
  for (final skin in uiSkins) {
    for (final base in [OurneyUi.light, OurneyUi.dark]) {
      for (var v = 0; v < skin.variants.length; v++) {
        final label = '${skin.id} v$v dark=${base.isDark}';
        final ui = skin.apply(base, variantIndex: v);

        test('palette stickers never collapse ($label)', () {
          for (final name in ourneyIconNames) {
            expect(
              OurneyIconPainter.collapses(ourneyIconColor(name), ui.ink),
              isFalse,
              reason: '$name collapses into ink ${ui.ink}',
            );
          }
        });

        testWidgets('explicit tones ($label)', (tester) async {
          final on = OurneyIcon(
            name: 'heart',
            color: ui.accent,
            inkColor: ui.ink,
          );
          final off = OurneyIcon(name: 'heart', flat: true, color: ui.inkMuted);
          final disabled = OurneyIcon(
            name: 'back',
            flat: true,
            color: ui.divider,
          );
          const enabled = OurneyIcon(name: 'back');
          final onAccent = uiJourneyGlyph(
            '✈',
            TemplateId.travel,
            color: ui.brand,
          );
          await _pump(tester, ui, [on, off, disabled, enabled, onAccent]);
          expect(_painterOf(tester, on).flat, isFalse);
          expect(_painterOf(tester, off).flat, isTrue);
          expect(_painterOf(tester, disabled).flat, isTrue);
          expect(_painterOf(tester, enabled).flat, isFalse);
          expect(_painterOf(tester, onAccent).flat, isTrue);
        });
      }
    }
  }

  testWidgets('an explicit-color journey glyph is theme independent', (
    tester,
  ) async {
    const white = Color(0xFFFFFFFF);
    final states = <(bool, Color)>[];
    for (final base in [OurneyUi.light, OurneyUi.dark]) {
      final glyph = uiJourneyGlyph('💪', TemplateId.workout30, color: white);
      await _pump(tester, base, [glyph]);
      final painter = _painterOf(tester, glyph);
      states.add((painter.flat, painter.color));
    }
    expect(states[0], states[1]);
    expect(states[0].$1, isTrue);
  });

  test('safety net: equal or indistinguishable fills collapse', () {
    expect(
      OurneyIconPainter.collapses(OurneyUi.light.ink, OurneyUi.light.ink),
      isTrue,
    );
    expect(
      OurneyIconPainter.collapses(const Color(0xFFFFFFFF), OurneyUi.dark.ink),
      isTrue,
    );
    expect(
      OurneyIconPainter.collapses(const Color(0xFFFF9F1C), OurneyUi.light.ink),
      isFalse,
    );
  });

  testWidgets('saturated fills on the cream dark ink are not blobs', (
    tester,
  ) async {
    final ink = OurneyUi.dark.ink;
    for (final fill in const [
      Color(0xFFFFD84D), // yellow
      Color(0xFFC6FF00), // lime neon
      Color(0xFF7EE8A2), // mint
      Color(0xFFA8D8F0), // ice
    ]) {
      expect(
        OurneyIconPainter.collapses(fill, ink),
        isFalse,
        reason: '$fill collapses into the cream ink',
      );
      final icon = OurneyIcon(name: 'star', color: fill);
      await _pump(tester, OurneyUi.dark, [icon]);
      final painter = _painterOf(tester, icon);
      expect(painter.flat, isFalse);
      // The halo falls back to the hard shadow, never the (near) fill color.
      expect(painter.haloFallback, OurneyUi.dark.hardShadowColor);
    }
  });
}
