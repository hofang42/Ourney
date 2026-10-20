import 'package:flutter/material.dart';

import '../app/theme/motion.dart';
import '../app/theme/persona_theme.dart';
import '../app/theme/tokens.dart';
import 'color_utils.dart';

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
    // The selected chip wears the active persona's accent (neutral coral on
    // the Hub); its label is white or dark ink, whichever reads better.
    final accent = OurneyPersonaTheme.of(context).primaryAccent;
    final bg = selected ? accent : c.surface;
    final fg = selected ? readableOn(accent) : c.ink;
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
                color: selected ? accent : c.border,
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
                    if (selected) ...[
                      Icon(Icons.check_rounded, size: 16, color: fg),
                      const SizedBox(width: OurneySpacing.xs),
                    ],
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: fg),
                      const SizedBox(width: OurneySpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
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
