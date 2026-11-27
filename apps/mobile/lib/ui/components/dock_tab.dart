import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'dock.dart' show UiDockItem;
import 'ourney_icons.dart';
import 'pressable.dart';

const Duration _kDockGlyphDuration = Duration(milliseconds: 180);

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
/// (`.dock-selection-capsule`, `border-radius: 999px`). In E4 the expanded
/// capsule is 52dp tall (`r = 26dp`) and labels are constrained to
/// `capW - 6dp` (`dockE4CapsuleLabelSidePad`) per the approved E4 mockup.
const double dockSelectionRadius = UiRadius.capsule;

/// The non-liquid selection capsule.
BoxDecoration dockSelectionDecoration({
  required Color accent,
  required Color surface,
  required Color outline,
  required Color shadow,
  bool camera = false,
  BorderRadius? borderRadius,
}) => BoxDecoration(
  // The always-dark camera dock keeps the solid accent pill.
  color: camera ? accent : dockSelectionFill(accent, surface),
  borderRadius: borderRadius ?? BorderRadius.circular(dockSelectionRadius),
  border: Border.all(color: outline, width: UiBorder.thin),
  boxShadow: UiShadow.hard(shadow, UiShadow.tiny),
);

/// Default vertical lift of tab content for legacy non-E4 callers (dp); E4
/// passes `lift: 0` and uses optical capsule centring (`-0.48dp`).
const double dockTabLift = 6;

/// Largest text scale the tab label follows (Dynamic Type cap).
const double dockLabelMaxScale = 1.35;

/// Label font size at 1x text scale.
const double dockLabelSize = 10.5;

/// Label line-height multiplier.
const double dockLabelHeightRatio = 1.35;

/// Label line height at 1x (`10.5 * 1.35`).
const double dockLabelLineHeight = dockLabelSize * dockLabelHeightRatio;

/// Default E4 capsule height at 1x text scale (dp).
const double dockE4CapsuleHeight = 52.0;

/// Horizontal padding deducted from `capsuleWidth` for the label (`capW - 6`).
const double dockE4CapsuleLabelSidePad = 6.0;

/// Default E4 glyph size (dp).
const double dockE4GlyphSize = 24.0;

/// Default E4 active glyph scale factor.
const double dockE4GlyphActiveScale = 1.08;

/// Default E4 glyph-to-label gap (dp).
const double dockE4LabelGap = 3.0;

/// Default E4 vertical padding inside the capsule (`2 * 5.2dp`).
const double dockE4CapsuleVertPad = 10.4;

/// Default E4 optical capsule lift (`24 * (1.08 - 1) / 4 = 0.48dp`).
const double dockE4CapsuleOpticalLift =
    dockE4GlyphSize * (dockE4GlyphActiveScale - 1) / 4;

/// One shrink factor for all tab labels: the largest `f <= 1` at which the
/// widest label fits within [maxWidth] (`capW - 6` in E4).
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
              height: dockLabelHeightRatio,
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

  var fit = 1.0;
  for (var i = 0; i < 6; i++) {
    final w = widestAt(fit);
    if (w <= 0) break;
    if (fit >= 1.0 && w <= maxWidth) break;
    fit = (fit * (maxWidth / w) * 0.998).clamp(0.1, 1.0);
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
    this.lift = dockTabLift,
    this.labelGap = 2,
    this.compactT = 0,
    super.key,
  });

  /// Shared label shrink factor (<= 1), the same for every tab of the dock so
  /// all labels render at one font size (see [dockLabelFit]).
  final double labelFit;

  /// Max width inside the selection capsule at the label row; constrains
  /// the label without shrinking the 48dp [UiPressable] hit target.
  final double? labelMaxWidth;

  /// Vertical lift above the slot centre (dp). E4 passes `0`.
  final double lift;

  /// Gap between the 24dp glyph and the label when expanded (dp). E4 passes `3`.
  final double labelGap;

  /// E4 compact morph progress (`0` = labels shown, `1` = compact).
  final double compactT;

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
        scale: active ? dockE4GlyphActiveScale : 1,
        duration: UiMotion.of(context, _kDockGlyphDuration),
        curve: UiCurves.dockOvershoot,
        child: OurneyIcon(name: item.glyph!, active: active),
      );
    }
    final t = compactT.clamp(0.0, 1.0);
    final clampedScaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: dockLabelMaxScale);
    final Widget labelBox = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: labelMaxWidth ?? double.infinity),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
          child: Text(
            item.label,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: UiText.body(
              size: dockLabelSize * labelFit,
              weight: active ? FontWeight.w700 : FontWeight.w600,
              height: dockLabelHeightRatio,
              color: labelColor,
            ).copyWith(letterSpacing: 0),
          ),
        ),
      ),
    );
    final Widget clippedLabel = ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1 - t,
        child: Visibility(
          visible: t < 1,
          maintainState: true,
          maintainSize: false,
          child: labelBox,
        ),
      ),
    );
    final Widget labelWidget = t > 0
        ? Opacity(opacity: 1 - t, child: clippedLabel)
        : clippedLabel;
    final effectiveGap = labelGap * (1 - t);
    return UiPressable(
      key: item.itemKey,
      onPressed: () {
        if (!active && !camera) {
          unawaited(UiHaptics.selection());
        }
        item.onPressed();
      },
      selected: active,
      semanticLabel: item.label,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.menu),
      minSize: const Size(UiSize.tap, UiSize.tap),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        // Shrink-wrap vertically: a bottom bar slot gives loose constraints
        // as tall as the screen and `alignment` would fill them.
        child: Center(
          heightFactor: 1,
          child: Padding(
            padding: EdgeInsets.only(bottom: lift * 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                glyph,
                if (effectiveGap > 0) SizedBox(height: effectiveGap),
                labelWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
