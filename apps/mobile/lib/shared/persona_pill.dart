import 'package:flutter/material.dart';

import '../app/theme/persona_theme.dart';
import 'color_utils.dart';

/// Small label at the top of a persona screen, e.g. `🏃 30 NGÀY · RUN CLUB`
/// (F5). Reads every color from [OurneyPersonaTheme].
class PersonaPill extends StatelessWidget {
  const PersonaPill({
    required this.label,
    this.icon,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final IconData? icon;

  /// Fill with the accent instead of the elevated surface.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final fill = emphasized ? pTheme.primaryAccent : pTheme.surfaceElevated;
    final fg = emphasized ? readableOn(fill) : pTheme.ink;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
