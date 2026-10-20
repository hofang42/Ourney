import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/persona_theme.dart';

/// Paper-framed photo (F5): a slightly tilted card with a thicker bottom
/// border for the caption and an optional strip of masking tape on top.
///
/// The photo area keeps [aspectRatio] (width / height) so a 2x2 grid never
/// overflows; the frame grows with the available width.
class PolaroidFrame extends StatelessWidget {
  const PolaroidFrame({
    required this.child,
    this.caption,
    this.angle = 0,
    this.showTape = false,
    this.aspectRatio = 1,
    super.key,
  });

  final Widget child;

  /// Handwritten-style line under the photo.
  final String? caption;

  /// Tilt in radians; keep within about +-0.08 so neighbours do not clash.
  final double angle;
  final bool showTape;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final brightness = Theme.of(context).brightness;
    final radius = math.min(pTheme.cardRadius, 8).toDouble();

    final paper = Container(
      padding: EdgeInsets.fromLTRB(10, 10, 10, caption == null ? 14 : 8),
      decoration: BoxDecoration(
        color: pTheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: brightness == Brightness.dark ? 0.45 : 0.14,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius / 2),
            child: AspectRatio(aspectRatio: aspectRatio, child: child),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: pTheme.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );

    final tilted = Transform.rotate(angle: angle, child: paper);
    if (!showTape) return tilted;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: const EdgeInsets.only(top: 8), child: tilted),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.rotate(
              angle: -0.05 + angle,
              child: Container(
                key: const ValueKey('polaroid-tape'),
                width: 56,
                height: 18,
                color: brightness == Brightness.dark
                    ? const Color(0xFFD6C7A9).withValues(alpha: 0.42)
                    : const Color(0xFFE4D8BE).withValues(alpha: 0.88),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
