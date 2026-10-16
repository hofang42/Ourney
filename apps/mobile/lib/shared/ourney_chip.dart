import 'package:flutter/material.dart';

import '../app/theme/motion.dart';
import '../app/theme/tokens.dart';

/// Chip (radius 12). Selected state does not rely on color alone: it gets a
/// check icon and a thicker border.
class OurneyChip extends StatelessWidget {
  const OurneyChip({
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = OurneyColors.of(context);
    final bg = selected ? c.primaryDeep : c.surface;
    final fg = selected ? c.onPrimaryDeep : c.ink;
    final radius = BorderRadius.circular(OurneyRadii.chip);
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: OurneySizes.minTap),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: selected ? c.primaryDeep : c.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap == null
                  ? null
                  : () {
                      OurneyHaptics.selection();
                      onTap!();
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OurneySpacing.md,
                  vertical: OurneySpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected || icon != null) ...[
                      Icon(
                        selected ? Icons.check_rounded : icon,
                        size: 16,
                        color: fg,
                      ),
                      const SizedBox(width: OurneySpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: fg),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
