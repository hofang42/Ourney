import 'dart:math' as math;

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

/// Label line height at 1x (10.5 * 1.35).
const double dockLabelLineHeight = 10.5 * 1.35;

/// Usable horizontal chord inside a 56dp-tall selection capsule of width
/// [pillW] (within a tab slot of width [slotW]) when the label renders at
/// [effectiveScale] x of its 1x size.
double dockLabelChordWidth(
  double slotW,
  double pillW, {
  double effectiveScale = 1.0,
}) {
  const r = 28.0;
  final growth = math.max(0.0, effectiveScale - 1.0) * dockLabelLineHeight / 2;
  final labelBottom = (19.0 - dockTabLift + growth).clamp(0.0, r - 1.0);
  final inset = r - math.sqrt(r * r - labelBottom * labelBottom);
  return math.min(slotW, math.max(0.0, pillW - 2 * inset - 3.0));
}

/// One shrink factor for all tab labels: the largest `f <= 1` at which the
/// widest label still fits [maxWidth] (or the capsule chord of [pillW] within
/// [slotW] at the actual fitted label height).
double dockLabelFit(
  BuildContext context,
  Iterable<String> labels,
  double maxWidth, {
  double? slotW,
  double? pillW,
}) {
  final scaler = MediaQuery.textScalerOf(context)
      .clamp(maxScaleFactor: dockLabelMaxScale);
  final s = scaler.scale(1);
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
            ).copyWith(letterSpacing: 0),
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

  // Width and capsule chord height depend on the fitted font size, so converge.
  var fit = 1.0;
  for (var i = 0; i < 6; i++) {
    final avail = (slotW != null && pillW != null)
        ? dockLabelChordWidth(slotW, pillW, effectiveScale: fit * s)
        : maxWidth;
    final w = widestAt(fit);
    if (w <= 0) break;
    if (fit >= 1.0 && w <= avail) break;
    fit = (fit * (avail / w) * 0.998).clamp(0.1, 1.0);
  }
  return fit;
}

class DockTab extends StatelessWidget {
  const DockTab({
    required this.item,
    required this.camera,
    this.onAccent,
    this.labelFit = 1,
    this.labelMaxWidth,
    super.key,
  });

  /// Shared label shrink factor (<= 1), the same for every tab of the dock so
  /// all labels render at one font size (see [dockLabelFit]).
  final double labelFit;

  /// Chord width inside the selection capsule at the label row; constrains
  /// the label without shrinking the 48dp [UiPressable] hit target.
  final double? labelMaxWidth;

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
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: labelMaxWidth ?? double.infinity,
                  ),
                  child: FittedBox(
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
                        ).copyWith(letterSpacing: 0),
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
