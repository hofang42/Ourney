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
/// * inactive labels are ink at 85%;
/// * the selection capsule is the accent at 30% over the surface with a 1.5dp
///   ink outline and a 2dp hard shadow, so ink text and glyphs read on it.

/// Fill of the selection capsule: `color-mix(accent 30%, surface)`.
Color dockSelectionFill(Color accent, Color surface) =>
    Color.alphaBlend(accent.withValues(alpha: 0.30), surface);

/// Corner radius of the selection pill: a full capsule, as in V2 `app.css`
/// (`.dock-selection-capsule`, `border-radius: 999px`). On a narrow ~63dp pill
/// the curve eats into the label row, so the tab keeps its content high and
/// squeezes the label into the capsule's chord (see `UiDock`, U17).
const double dockSelectionRadius = UiRadius.capsule;

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
  borderRadius: BorderRadius.circular(dockSelectionRadius),
  border: Border.all(color: outline, width: UiBorder.thin),
  boxShadow: UiShadow.hard(shadow, UiShadow.tiny),
);

/// How far the tab content sits above the pill's centre (dp).
const double dockTabLift = 6;

/// Largest text scale the tab label follows (Dynamic Type cap).
const double dockLabelMaxScale = 1.35;

/// Label font size at 1x text scale.
const double dockLabelSize = 10.5;

/// One shrink factor for all tab labels: the largest `f <= 1` at which the
/// widest label still fits [maxWidth]. Labels used to scale down one by one
/// (long ones to ~8dp, short ones left at ~14dp).
double dockLabelFit(
  BuildContext context,
  Iterable<String> labels,
  double maxWidth,
) {
  final scaler = MediaQuery.textScalerOf(context)
      .clamp(maxScaleFactor: dockLabelMaxScale);
  double widestAt(double fit) {
    var widest = 0.0;
    for (final label in labels) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          // Same inheritance as the rendered Text (theme tracking etc.).
          style: DefaultTextStyle.of(context).style.merge(
            UiText.body(
              size: dockLabelSize * fit,
              weight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (tp.width > widest) widest = tp.width;
      tp.dispose();
    }
    return widest;
  }

  // Width is not exactly linear in the font size (tracking), so converge.
  var fit = 1.0;
  for (var i = 0; i < 5; i++) {
    final w = widestAt(fit);
    if (w <= 0 || w <= maxWidth) break;
    fit *= maxWidth / w * 0.995;
  }
  return fit;
}

/// Label line height at 1x (10.5 * 1.35).
const double dockLabelLineHeight = 10.5 * 1.35;

/// How far the label row's bottom edge drops below its 1x position at the
/// current text scale (the content is centred, so half the growth).
double dockLabelGrowth(BuildContext context) {
  final s = MediaQuery.textScalerOf(context)
      .clamp(maxScaleFactor: dockLabelMaxScale)
      .scale(1);
  return (s - 1) * dockLabelLineHeight / 2;
}

class DockTab extends StatelessWidget {
  const DockTab({
    required this.item,
    required this.camera,
    this.onAccent,
    this.labelFit = 1,
    super.key,
  });

  /// Shared label shrink factor (<= 1), the same for every tab of the dock so
  /// all labels render at one font size (see [dockLabelFit]).
  final double labelFit;

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
      // 85% (was 72%) keeps inactive labels readable over dark content
      // under the glass (U17).
      labelColor = active ? ui.ink : ui.ink.withValues(alpha: 0.85);
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
          // Lift the content 4dp: the label row then sits where the capsule is
          // still wide (U17).
          child: Padding(
            padding: const EdgeInsets.only(bottom: dockTabLift * 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                glyph,
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: dockLabelMaxScale),
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: UiText.body(
                        size: dockLabelSize * labelFit,
                        weight: active ? FontWeight.w700 : FontWeight.w600,
                        height: 1.35,
                        color: labelColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
