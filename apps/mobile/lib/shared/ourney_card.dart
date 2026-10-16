import 'package:flutter/material.dart';

import '../app/theme/tokens.dart';

/// Surface card: radius 20, 1px border, optional tap target.
class OurneyCard extends StatelessWidget {
  const OurneyCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(OurneySpacing.lg),
    this.gradient,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final radius = BorderRadius.circular(OurneyRadii.card);
    final card = Ink(
      decoration: BoxDecoration(
        color: gradient == null ? c.surface : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: c.border),
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
            : InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: card,
              ),
      ),
    );
  }
}
