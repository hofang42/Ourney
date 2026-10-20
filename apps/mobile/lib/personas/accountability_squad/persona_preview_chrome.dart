import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart' show PersonaSkinId;

import '../../app/theme/persona_theme.dart';

/// Stand-in for the shared 3-tab dock (`F4`, `CLAUDE.md` §2) so the persona
/// preview harness can judge each screen in its real composition. Product
/// code must use the real dock, never this one.
class PreviewTabDock extends StatelessWidget {
  const PreviewTabDock({
    this.leftIcon = Icons.explore_outlined,
    this.leftLabel = 'Journeys',
    this.centerIcon,
    this.middleLabel,
    this.middleIcon,
    this.rightIcon = Icons.groups_outlined,
    this.rightLabel = 'Squad',
    this.center,
    this.dark = false,
    super.key,
  });

  final IconData leftIcon;
  final String leftLabel;

  /// Icon of the centre quick-snap pill; `null` draws the three-dot
  /// placeholder used in the Persona 2 board.
  final IconData? centerIcon;

  /// Optional extra label for a layout with a fourth slot instead of a pill.
  final String? middleLabel;
  final IconData? middleIcon;
  final IconData rightIcon;
  final String rightLabel;

  /// Replaces the snap pill (e.g. the capture screen's hero shutter).
  final Widget? center;

  /// Dark camera surface (no divider, light glyphs).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final fg = dark ? Colors.white70 : pTheme.ink;

    Widget tab(IconData icon, String label) => SizedBox(
      width: 72,
      height: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: fg),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fg, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );

    final heavy = pTheme.borderWidth > 1;
    final pill = Container(
      width: 56,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5A5F),
        borderRadius: BorderRadius.circular(heavy ? 20 : 12),
        border: heavy
            ? Border.all(color: pTheme.border, width: pTheme.borderWidth)
            : null,
        boxShadow: heavy
            ? [BoxShadow(color: pTheme.border, offset: const Offset(0, 3))]
            : null,
      ),
      child: Icon(
        centerIcon ?? Icons.more_horiz_rounded,
        color: Colors.white,
        size: 22,
      ),
    );

    // The snap pill follows the skin's accent, as in the reference boards.
    final snap = pTheme.skinId == PersonaSkinId.memoryCollectors
        ? Container(
            width: 56,
            height: 40,
            decoration: BoxDecoration(
              color: pTheme.primaryAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              centerIcon ?? Icons.photo_camera_outlined,
              color: Colors.white,
              size: 22,
            ),
          )
        : pill;

    return Container(
      decoration: BoxDecoration(
        color: dark ? Colors.transparent : pTheme.background,
        border: dark
            ? null
            : Border(
                top: BorderSide(
                  color: pTheme.border.withValues(
                    alpha: pTheme.borderWidth > 1 ? 1 : 0.5,
                  ),
                  width: pTheme.borderWidth > 1 ? 1.5 : 1,
                ),
              ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom.clamp(8.0, 20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          tab(leftIcon, leftLabel),
          if (center != null)
            center!
          else if (middleLabel != null && middleIcon != null)
            tab(middleIcon!, middleLabel!)
          else
            snap,
          tab(rightIcon, rightLabel),
        ],
      ),
    );
  }
}

/// Camera shutter (hero ring) stand-in for the capture screen's own control.
class PreviewShutter extends StatelessWidget {
  const PreviewShutter({
    required this.color,
    this.ring = Colors.white,
    super.key,
  });

  final Color color;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 3),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
