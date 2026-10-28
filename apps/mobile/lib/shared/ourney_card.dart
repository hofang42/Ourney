import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';

/// Flat editorial surface (V1.0): square corners, 1px hairline border,
/// optional tap target. Pass [radius] for the rare rounded card.
class OurneyCard extends StatelessWidget {
  const OurneyCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(OurneySpacing.lg),
    this.gradient,
    this.semanticLabel,
    this.radius = OurneyRadii.none,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final String? semanticLabel;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final radius = BorderRadius.circular(this.radius);
    final card = Ink(
      decoration: BoxDecoration(
        color: gradient == null ? c.surface : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: c.divider),
      ),
      child: Padding(padding: padding, child: child),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        child: onTap == null
            ? card
            : InkWell(borderRadius: radius, onTap: onTap, child: card),
      ),
    );
  }
}
