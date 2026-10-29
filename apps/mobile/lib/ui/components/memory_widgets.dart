import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';

/// `.success-mark`: 44dp green disc with a white check (Posted screen).
class UiSuccessMark extends StatelessWidget {
  const UiSuccessMark({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF15803D),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          size: size * 0.55,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// `.stamp`: rotated double-border rubber stamp ("DAY 25").
class UiStamp extends StatelessWidget {
  const UiStamp(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.ui.warn;
    return Transform.rotate(
      angle: -8 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: context.ui.surface.withValues(alpha: 0.6),
          border: Border.all(color: c, width: 3),
        ),
        child: Text(
          text,
          maxLines: 1,
          style: UiText.body(
            size: 12,
            weight: FontWeight.w700,
            height: 1.3,
            tracking: 0.04,
            color: c,
          ),
        ),
      ),
    );
  }
}

/// Flame + big number + unit (`.streak-celebrate`, `.shared-streak`).
class UiStreakNumber extends StatelessWidget {
  const UiStreakNumber({
    required this.value,
    required this.unit,
    this.size = 86,
    this.semanticLabel,
    super.key,
  });

  final int value;
  final String unit;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Semantics(
      label: semanticLabel ?? '$value $unit',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: size * 0.38,
              color: ui.flame,
            ),
            Text(
              '$value',
              style: UiText.display(
                size: size,
                weight: 800,
                height: 1.1,
                tracking: -0.07,
                color: ui.ink,
              ),
            ),
            const SizedBox(width: 8),
            Text(unit, style: UiText.body(size: 16, color: ui.inkMuted)),
          ],
        ),
      ),
    );
  }
}

/// `.polaroid`: tilted card with a hard border and offset shadow (squad
/// wall). [photo] fills the top; [footer] sits under it.
class UiPolaroid extends StatelessWidget {
  const UiPolaroid({
    required this.photo,
    required this.footer,
    this.tilt = -1,
    super.key,
  });

  final Widget photo;
  final Widget footer;

  /// Degrees; odd/even tiles alternate -1 / +1.2.
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final edge = ui.isDark ? ui.border : const Color(0xFF1E1B18);
    return Transform.rotate(
      angle: tilt * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ui.isDark ? ui.surface : const Color(0xFFFFFDF9),
          border: Border.all(color: edge, width: 2),
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [photo, footer],
        ),
      ),
    );
  }
}

/// Centers [child] in the available area and scrolls when it is taller
/// (empty / error states at large text on short phones).
class UiFillScroll extends StatelessWidget {
  const UiFillScroll({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: c.hasBoundedHeight ? c.maxHeight : 0,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
