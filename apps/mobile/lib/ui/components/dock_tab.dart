import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'dock.dart' show UiDockItem;
import 'ourney_icons.dart';
import 'pressable.dart';

/// Internal parts of [UiDock] (`dock.dart`): one tab and the selection pill
/// look. Not exported from `ui.dart`.
///
/// V2 `app.css` (`.app-dock .dock-tab`, `.dock-selection-capsule`):
/// * tab glyphs stay coloured stickers in every state; the active one gets
///   the die-cut sticker tier and grows to 1.08x, the label turns full ink;
/// * inactive labels are ink at 72%;
/// * the selection capsule is the accent at 30% over the surface with a 1.5dp
///   ink outline and a 2dp hard shadow, so ink text and glyphs read on it.

/// Fill of the selection capsule: `color-mix(accent 30%, surface)`.
Color dockSelectionFill(Color accent, Color surface) =>
    Color.alphaBlend(accent.withValues(alpha: 0.30), surface);

/// The non-liquid selection capsule.
BoxDecoration dockSelectionDecoration({
  required Color accent,
  required Color surface,
  required Color outline,
  required Color shadow,
  bool camera = false,
}) => BoxDecoration(
  // The always-dark camera dock keeps the solid accent pill.
  color: camera ? accent : dockSelectionFill(accent, surface),
  borderRadius: BorderRadius.circular(UiRadius.capsule),
  border: Border.all(color: outline, width: UiBorder.thin),
  boxShadow: UiShadow.hard(shadow, UiShadow.tiny),
);

class DockTab extends StatelessWidget {
  const DockTab({
    required this.item,
    required this.camera,
    this.onAccent,
    super.key,
  });

  final UiDockItem item;
  final bool camera;

  /// Camera dock only: foreground on the solid accent pill.
  final Color? onAccent;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final active = item.active;
    final Color labelColor;
    if (camera) {
      labelColor = active ? (onAccent ?? ui.onBrand) : UiCamera.ink;
    } else {
      labelColor = active ? ui.ink : ui.ink.withValues(alpha: 0.72);
    }
    final Widget glyph;
    if (item.glyph == null) {
      glyph = Icon(item.icon, size: 22, color: labelColor);
    } else if (camera) {
      // Camera chrome: one flat colour, no sticker fill (unchanged).
      glyph = OurneyIcon(
        name: item.glyph!,
        size: 22,
        color: labelColor,
        inkColor: labelColor,
      );
    } else {
      // Bug #11: the active (just pressed) tab used to repaint its glyph as
      // one solid onBrand colour, i.e. a black blob. Keep the sticker
      // palette and the ink outline in every state.
      glyph = AnimatedScale(
        scale: active ? 1.08 : 1,
        duration: UiMotion.of(context, UiMotion.press),
        child: OurneyIcon(name: item.glyph!, active: active),
      );
    }
    return UiPressable(
      key: item.itemKey,
      onPressed: item.onPressed,
      selected: active,
      semanticLabel: item.label,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.menu),
      minSize: const Size(UiSize.tap, 56),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        // Shrink-wrap vertically: a bottom bar slot gives loose constraints
        // as tall as the screen and `alignment` would fill them.
        child: Center(
          heightFactor: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              glyph,
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: UiText.body(
                  size: 10.5,
                  weight: active ? FontWeight.w700 : FontWeight.w600,
                  height: 1.35,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
