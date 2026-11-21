import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/ui.dart';

void main() {
  for (final ui in [OurneyUi.light, OurneyUi.dark]) {
    test('sticker fill never matches the ink outline (dark=${ui.isDark})', () {
      for (final name in ourneyIconNames) {
        final fill = ourneyIconColor(name);
        expect(
          OurneyIconPainter.collapses(fill, ui.ink),
          isFalse,
          reason: '$name fill $fill collapses into ink ${ui.ink}',
        );
      }
    });
  }

  for (final skin in uiSkins) {
    for (final base in [OurneyUi.light, OurneyUi.dark]) {
      for (var v = 0; v < skin.variants.length; v++) {
        test('palette icons stay two-tone in skin ${skin.id} v$v '
            '(dark=${base.isDark})', () {
          final ui = skin.apply(base, variantIndex: v);
          for (final name in ourneyIconNames) {
            expect(
              OurneyIconPainter.collapses(ourneyIconColor(name), ui.ink),
              isFalse,
              reason: '$name collapses into ink ${ui.ink}',
            );
          }
        });
      }
    }
  }

  test('a fill equal or close to the ink is detected as a blob', () {
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

  testWidgets('neutral tint without inkColor draws a line glyph', (
    tester,
  ) async {
    OurneyIconPainter painterOf(OurneyIcon icon) {
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byWidget(icon),
          matching: find.byType(CustomPaint),
        ),
      );
      return paint.painter! as OurneyIconPainter;
    }

    const muted = OurneyIcon(name: 'star', color: Color(0xFF888888));
    const palette = OurneyIcon(name: 'star');
    const withInk = OurneyIcon(
      name: 'star',
      color: Color(0xFFFFFFFF),
      inkColor: Color(0xFF000000),
    );
    await tester.pumpWidget(
      MaterialApp(home: Column(children: const [muted, palette, withInk])),
    );
    expect(painterOf(muted).flat, isTrue);
    expect(painterOf(palette).flat, isFalse);
    expect(painterOf(withInk).flat, isFalse);
  });

  for (final base in [OurneyUi.light, OurneyUi.dark]) {
    testWidgets('intentional colors stay stickers, greys go line '
        '(dark=${base.isDark})', (tester) async {
      OurneyIconPainter painterOf(Widget w) {
        final paint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byWidget(w),
            matching: find.byType(CustomPaint),
          ),
        );
        return paint.painter! as OurneyIconPainter;
      }

      final flame = OurneyIcon(name: 'flame', color: base.flame);
      final heartOn = OurneyIcon(name: 'heart', color: base.accent);
      final heartOff = OurneyIcon(name: 'heart', color: base.fill);
      final ok = OurneyIcon(name: 'check-circle', color: base.success);
      final bad = OurneyIcon(name: 'warning', color: base.danger);
      final muted = OurneyIcon(name: 'star', color: base.inkMuted);
      final ink = OurneyIcon(name: 'star', color: base.ink);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: base.brightness, extensions: [base]),
          home: Column(
            children: [flame, heartOn, heartOff, ok, bad, muted, ink],
          ),
        ),
      );
      for (final w in [flame, heartOn, heartOff, ok, bad]) {
        expect(painterOf(w).flat, isFalse, reason: '${(w).name}');
      }
      expect(painterOf(muted).flat, isTrue);
      expect(painterOf(ink).flat, isTrue);
    });
  }

  test('saturated pastels / neon never collapse into a similar-light ink', () {
    for (final fill in const [
      Color(0xFFC6FF00), // lime neon
      Color(0xFF7EE8A2), // weight-loss pastel
      Color(0xFF7EC8E3), // custom pastel
      Color(0xFFFFB347), // trip pastel
    ]) {
      for (final ink in [OurneyUi.light.ink, OurneyUi.dark.ink]) {
        expect(OurneyIconPainter.collapses(fill, ink), isFalse);
      }
    }
  });
}
