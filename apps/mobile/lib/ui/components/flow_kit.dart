import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'buttons.dart';
import 'ourney_icons.dart';
import 'pressable.dart';

/// Pastel colors of the six journey goals (V2 `flow.tsx` `journeyChoices`).
/// Fixed in both modes: they fill stickers and answer cards whose label and
/// glyph are always ink `#1A1A1A`.
abstract final class UiFlowColors {
  static const weight = Color(0xFF7EE8A2);
  static const english = Color(0xFFFFD84D);
  static const workout = Color(0xFFCF9FFF);
  static const trip = Color(0xFFFFB347);
  static const couple = Color(0xFFFF7E7E);
  static const habit = Color(0xFF7EC8E3);

  /// Ink used on top of the pastel fills (`#1a1a1a`), also in dark mode.
  static const onPastel = Color(0xFF1A1A1A);

  /// White sticker paper that sits on the pastel fills, also in dark mode
  /// (it always carries [onPastel] ink).
  static const paper = Color(0xFFFFFFFF);
}

/// The six journey goals of the quiz and the splash stickers.
enum UiFlowGoal {
  weight(UiFlowColors.weight),
  english(UiFlowColors.english),
  workout(UiFlowColors.workout),
  trip(UiFlowColors.trip),
  couple(UiFlowColors.couple),
  habit(UiFlowColors.habit);

  const UiFlowGoal(this.color);

  final Color color;
}

/// Glyph of a journey goal (V2 `OIcon` scales / book / fitness / trip / two
/// hearts / edit), drawn in the sticker style with an ink outline.
class UiGoalGlyph extends StatelessWidget {
  const UiGoalGlyph({required this.goal, this.size = 27, super.key});

  final UiFlowGoal goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget icon(String name, double s) =>
        OurneyIcon(name: name, size: s, inkColor: UiFlowColors.onPastel);
    return switch (goal) {
      UiFlowGoal.weight => icon('scales', size),
      UiFlowGoal.english => icon('book', size),
      UiFlowGoal.workout => icon('fitness', size),
      UiFlowGoal.trip => icon('trip', size),
      UiFlowGoal.habit => icon('pencil', size),
      // `.double-heart`: 42x34, one 25dp heart low-left, one high-right.
      UiFlowGoal.couple => SizedBox(
        width: size * 42 / 27,
        height: size * 34 / 27,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Transform.rotate(
                angle: -8 * math.pi / 180,
                child: icon('heart', size * 25 / 27),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Transform.rotate(
                angle: 8 * math.pi / 180,
                child: icon('heart', size * 25 / 27),
              ),
            ),
          ],
        ),
      ),
    };
  }
}

/// `.splash-sticker`: a tilted tile with the uneven sticker radii
/// (18 / 13 / 20 / 14), a 2dp ink outline and a 3dp hard shadow.
class UiStickerTile extends StatelessWidget {
  const UiStickerTile({
    required this.color,
    required this.child,
    this.size = 62,
    this.degrees = 0,
    this.borderRadius = radius,
    super.key,
  });

  final Color color;
  final Widget child;
  final double size;
  final double degrees;
  final BorderRadius borderRadius;

  static const radius = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(13),
    bottomRight: Radius.circular(20),
    bottomLeft: Radius.circular(14),
  );

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Transform.rotate(
      angle: degrees * math.pi / 180,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          border: ui.stickerBorder(),
          boxShadow: ui.hardShadow(UiShadow.small),
        ),
        child: child,
      ),
    );
  }
}

class _Letter {
  const _Letter(
    this.char,
    this.family,
    this.weight,
    this.factor,
    this.degrees,
    this.color, {
    this.italic = false,
    this.tile,
    this.tileRadius = BorderRadius.zero,
  });

  final String char;
  final String family;
  final int weight;
  final double factor;
  final double degrees;
  final Color color;
  final bool italic;

  /// Background of a ransom-note paper tile (r, e); null for a cut-out glyph.
  final Color? tile;
  final BorderRadius tileRadius;
}

const _letters = <_Letter>[
  _Letter('o', UiFonts.fraunces, 900, .25, -7, Color(0xFF10B981)),
  _Letter('u', UiFonts.display, 800, .24, 5, Color(0xFFFF9F1C)),
  _Letter(
    'r',
    UiFonts.mono,
    700,
    .19,
    -4,
    Color(0xFFC2452B),
    tile: Color(0xFFF3E3C3),
    tileRadius: BorderRadius.all(Radius.circular(4)),
  ),
  // V2 uses Baloo 2 here; it is not bundled, Bricolage 800 stands in.
  _Letter('n', UiFonts.display, 800, .23, 7, Color(0xFF2AA7E0)),
  _Letter(
    'e',
    UiFonts.barlowCondensed,
    800,
    .25,
    -3,
    Color(0xFFFF4D6D),
    tile: Color(0xFF111111),
    tileRadius: BorderRadius.only(
      topLeft: Radius.circular(3),
      topRight: Radius.circular(11),
      bottomRight: Radius.circular(3),
      bottomLeft: Radius.circular(9),
    ),
  ),
  _Letter('y', UiFonts.fraunces, 900, .24, 8, Color(0xFFA13CC9), italic: true),
];

/// The ransom-note "ourney" wordmark (V2 `Wordmark`, `.ourney-wordmark`):
/// six mismatched cut-out letters, each tilted, with a white die-cut edge and
/// a soft ink drop shadow; `r` and `e` sit on paper tiles. It is a logo, so it
/// ignores the system text scale and is announced as "ourney".
class UiRansomWordmark extends StatelessWidget {
  const UiRansomWordmark({this.size = 174, super.key});

  /// Width of the whole word (V2 `--wordmark-size`).
  final double size;

  static const _shadow = Color(0x57111111);

  @override
  Widget build(BuildContext context) {
    final cellW = size / 6.25;
    final cellH = size * .3;
    final step = cellW - size * .015;
    final start = (size - (step * 5 + cellW)) / 2;
    final edge = math.max(1.0, size * .0172);
    return Semantics(
      label: 'ourney',
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: SizedBox(
          width: size,
          height: cellH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < _letters.length; i++)
                Positioned(
                  left: start + step * i,
                  top: 0,
                  width: cellW,
                  height: cellH,
                  child: Transform.rotate(
                    angle: _letters[i].degrees * math.pi / 180,
                    child: _letters[i].tile == null
                        ? _glyph(_letters[i], cellW, cellH, edge)
                        : _tile(_letters[i], edge),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _style(_Letter l, {Color? color, Paint? foreground}) => TextStyle(
    fontFamily: l.family,
    fontSize: size * l.factor,
    fontWeight: FontWeight.values[(l.weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', l.weight.toDouble())],
    fontStyle: l.italic ? FontStyle.italic : FontStyle.normal,
    height: 1,
    color: foreground == null ? color : null,
    foreground: foreground,
  );

  Widget _tile(_Letter l, double edge) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: l.tile,
      borderRadius: l.tileRadius,
      border: Border.all(color: Colors.white, width: edge),
      boxShadow: const [BoxShadow(color: _shadow, offset: Offset(2, 3))],
    ),
    child: Text(
      l.char,
      maxLines: 1,
      softWrap: false,
      style: _style(l, color: l.color),
    ),
  );

  Widget _glyph(_Letter l, double cellW, double cellH, double edge) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = edge
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Text(
          l.char,
          maxLines: 1,
          softWrap: false,
          style: _style(l, foreground: outline).copyWith(
            shadows: const [Shadow(color: _shadow, offset: Offset(2, 3))],
          ),
        ),
        Text(
          l.char,
          maxLines: 1,
          softWrap: false,
          style: _style(l, color: l.color),
        ),
        if (l.char == 'o')
          // `.wordmark-o::after`: the white counter.
          Positioned(
            left: cellW * .39,
            top: cellH * .37,
            width: cellW * .24,
            height: cellH * .30,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        if (l.char == 'n') ...[
          // `.wordmark-n::before/::after`: two yellow dots.
          Positioned(
            left: cellW * .13,
            top: cellH * .20,
            width: cellW * .10,
            height: cellW * .10,
            child: const _Dot(),
          ),
          Positioned(
            right: cellW * .08,
            bottom: cellH * .18,
            width: cellW * .10,
            height: cellW * .10,
            child: const _Dot(),
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(color: Color(0xFFFFD84D), shape: BoxShape.circle),
  );
}

/// `.step-segments`: one pill per question. Done pills are brand-filled, the
/// current one is taller with a 2dp outline, pending ones are empty outlines.
class UiStepSegments extends StatelessWidget {
  const UiStepSegments({
    required this.count,
    required this.current,
    this.itemKey,
    super.key,
  });

  final int count;

  /// Zero-based index of the current question.
  final int current;
  final Key Function(int index)? itemKey;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final duration = UiMotion.of(context, const Duration(milliseconds: 200));
    return SizedBox(
      height: 7,
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  key: itemKey?.call(i),
                  duration: duration,
                  height: i == current ? 7 : 5,
                  decoration: BoxDecoration(
                    color: i < current ? ui.brand : Colors.transparent,
                    border: Border.all(
                      color: ui.outline,
                      width: i == current ? UiBorder.standard : 1,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.answer-choice`: a selectable sticker card. Resting: surface fill, 2dp
/// outline, 4dp hard shadow. Selected: filled with [color], 3dp outline,
/// pushed down 4dp into its shadow, plus the check badge. [child] is laid
/// out inside [padding]; labels on a selected card are always ink.
class UiChoiceCard extends StatelessWidget {
  const UiChoiceCard({
    required this.color,
    required this.selected,
    required this.onPressed,
    required this.child,
    this.minHeight = 0,
    this.padding = const EdgeInsets.all(14),
    super.key,
  });

  final Color color;
  final bool selected;
  final VoidCallback onPressed;
  final Widget child;
  final double minHeight;
  final EdgeInsetsGeometry padding;

  static const double radius = 16;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final press = UiMotion.of(context, UiMotion.press);
    const shape = BorderRadius.all(Radius.circular(radius));
    return UiPressable(
      onPressed: onPressed,
      selected: selected,
      borderRadius: shape,
      shadowOffset: selected ? 0 : UiShadow.large,
      minSize: Size(UiSize.tap, math.max(UiSize.tap, minHeight)),
      child: AnimatedContainer(
        duration: press,
        curve: Curves.easeOut,
        constraints: BoxConstraints(minHeight: minHeight),
        transform: Matrix4.translationValues(
          selected ? UiShadow.large : 0,
          selected ? UiShadow.large : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: selected ? color : ui.surface,
          borderRadius: shape,
          border: Border.all(
            color: ui.outline,
            width: selected ? 3 : UiBorder.standard,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: padding,
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: selected ? UiFlowColors.onPastel : ui.ink,
                ),
                child: child,
              ),
            ),
            if (selected)
              Positioned(
                top: 13,
                right: 13,
                child: Container(
                  key: const ValueKey('ui-choice-check'),
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: UiFlowColors.onPastel,
                        width: UiBorder.standard,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: UiFlowColors.onPastel,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const OurneyIcon(
                    name: 'check',
                    size: 14,
                    flat: true,
                    color: UiFlowColors.onPastel,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `.flow-primary`: the 52dp capsule of the sign-in / onboarding flow. Brand
/// fill, 2dp outline, 4dp hard shadow. While [onPressed] is null it turns
/// into a dashed ink outline on the surface color with a muted label.
class UiFlowButton extends StatelessWidget {
  const UiFlowButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final enabled = onPressed != null;
    final shape = BorderRadius.circular(UiRadius.capsule);
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      shadowOffset: enabled ? UiShadow.large : 0,
      child: CustomPaint(
        foregroundPainter: enabled
            ? null
            : _DashedPill(color: ui.outline, width: UiBorder.standard),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: UiSize.button),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? ui.brand : ui.surface,
            borderRadius: shape,
            border: enabled ? ui.stickerBorder() : null,
          ),
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: UiText.body(
              size: 16,
              weight: FontWeight.w700,
              height: 1.35,
              color: enabled ? ui.onBrand : ui.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPill extends CustomPainter {
  const _DashedPill({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    const dash = 6.0, gap = 4.0;
    for (final PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        canvas.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPill old) =>
      old.color != color || old.width != width;
}

/// V2 `PermissionSheet` content: a tilted sticker, a lowercase headline, a
/// muted body, the brand "allow" button and a plain "later" action, with a
/// round close button top right. Pops `true` for allow, `false` otherwise.
/// Place it inside `showUiSheet`.
class UiStickerPermissionContent extends StatelessWidget {
  const UiStickerPermissionContent({
    required this.glyph,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.closeLabel,
    this.primaryKey,
    this.secondaryKey,
    super.key,
  });

  final Widget glyph;
  final String title;
  final String body;
  final String primaryLabel;
  final String secondaryLabel;
  final String closeLabel;
  final Key? primaryKey;
  final Key? secondaryKey;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: UiStickerTile(
                color: UiFlowColors.habit,
                size: 72,
                degrees: -3,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(24),
                  bottomLeft: Radius.circular(18),
                ),
                child: glyph,
              ),
            ),
            const Spacer(),
            UiPressable(
              onPressed: () => Navigator.of(context).pop(false),
              semanticLabel: closeLabel,
              excludeChildSemantics: true,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ui.surface,
                  shape: BoxShape.circle,
                  border: ui.stickerBorder(),
                ),
                child: OurneyIcon(
                  name: 'close',
                  size: 22,
                  flat: true,
                  color: ui.ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 310),
              child: Text(
                title,
                style: UiText.heading(
                  font: 'SpaceGrotesk',
                  size: 27,
                  weight: 700,
                  height: 1.2,
                  tracking: -0.04,
                  color: ui.ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(body, style: UiText.muted(color: ui.inkMuted, size: 14)),
        const SizedBox(height: 22),
        UiFlowButton(
          key: primaryKey,
          label: primaryLabel,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 8),
        UiTextAction(
          key: secondaryKey,
          label: secondaryLabel,
          size: 16,
          color: ui.ink,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
