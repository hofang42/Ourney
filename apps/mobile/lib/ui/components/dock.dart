import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../tokens.dart';
import 'dock_tab.dart';
import 'glass.dart';
import 'ourney_icons.dart';
import 'pressable.dart';
import 'skin_scope.dart';

/// V2 selection pill easing (`cubic-bezier(.2,.9,.3,1.2)`, slight overshoot).
const Curve _pillCurve = Cubic(0.2, 0.9, 0.3, 1.2);
const Duration _pillDuration = Duration(milliseconds: 280);
const Duration _longPress = Duration(milliseconds: 400);
const double _pillW = 78;
const double _pillH = 56;
// V2 `.app-dock` is 76 high around the 56 capsule: 10dp of air inside the 2dp
// border (8dp under the capsule's 2dp shadow). At 64 the capsule sat 4dp from
// the border and its shadow touched it (bug #11).
const double _dockH = 76;
const double _cameraDockH = 92;
// One center slot width for both docks: the camera route swaps the snap pill
// for the 76dp hero shutter, and the four tabs must not slide sideways when
// that happens (they used to move 3-7dp because the slots were 64 vs 82).
// One center slot width for the tab row in both docks so the four tabs never
// slide sideways when the camera route swaps the 56dp snap pill for the 76dp
// hero shutter (the center widget itself is centered in the Stack).
const double _centerSlot = UiSize.snapPillW;
const double _dockSideInset = 10;

/// One tab of the [UiDock]. Give it a drawn [glyph] (an [OurneyIcon] name such
/// as `journeys`, `squad`, `activity`, `profile`) or, for older callers, a
/// Material [icon].
class UiDockItem {
  const UiDockItem({
    @Deprecated('Use glyph: an OurneyIcon name') this.icon,
    this.glyph,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.itemKey,
  }) : assert(icon != null || glyph != null, 'Give an icon or a glyph');

  final IconData? icon;

  /// [OurneyIcon] name; wins over [icon].
  final String? glyph;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  /// Key given to the tab (tests / integration).
  final Key? itemKey;
}

/// The V2 floating dock: a glass sticker bar (blur 20, saturation 1.6, solid
/// when transparency is reduced) with a sliding selection pill.
///
/// 3-slot form: [left], the center snap pill, [right]. 5-tab form (V2):
/// pass [extraLeft] / [extraRight] so the order is
/// `left, ...extraLeft, [center], ...extraRight, right`; e.g. Hành trình ·
/// Nhóm · [Chụp] · Hoạt động · Hồ sơ.
///
/// Set [camera] for the dark camera dock and pass a [UiShutter] as [center].
/// [onShutterLongPress] (400ms) opens the journey wheel from the center.
class UiDock extends StatelessWidget {
  const UiDock({
    required this.left,
    required this.right,
    required this.snapLabel,
    required this.onSnap,
    this.extraLeft = const [],
    this.extraRight = const [],
    this.accent,
    this.onAccent,
    this.center,
    this.camera = false,
    this.snapKey,
    this.onShutterLongPress,
    this.reduceTransparency = false,
    this.liquid = false,
    super.key,
  });

  /// Real shader Liquid Glass (ADR 0003) is skipped under `flutter test` and on
  /// web; widget tests get the blurred-capsule path.
  static bool get liquidSupported =>
      !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  /// Opt in to the shader Liquid Glass capsule (ADR 0003). Off by default
  /// (bug #11, CLAUDE.md §2): the shader path drops the 2dp outline and hard
  /// shadow and did not read as glass on the test device, so the dock uses
  /// the V2 `BackdropFilter` glass (blur 20, saturate 1.6, translucent tint,
  /// outline, hard shadow, solid under reduce transparency / high contrast).
  final bool liquid;

  /// Key of the quick-snap pill.
  final Key? snapKey;

  final UiDockItem left;
  final UiDockItem right;

  /// Tabs between [left] and the center (left side).
  final List<UiDockItem> extraLeft;

  /// Tabs between the center and [right].
  final List<UiDockItem> extraRight;
  final String snapLabel;
  final VoidCallback onSnap;
  final Color? accent;
  final Color? onAccent;

  /// Replaces the snap pill (the camera screen's big shutter).
  final Widget? center;
  final bool camera;

  /// Fired after a 400ms press on the center (journey wheel).
  final VoidCallback? onShutterLongPress;

  /// App-level "reduce transparency": solid fill, no blur.
  final bool reduceTransparency;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final media = MediaQuery.of(context);
    final useLiquid =
        liquid && liquidSupported && !reduceTransparency && !media.highContrast;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottom = media.viewPadding.bottom;
    final skinBorder =
        UiSkinScope.maybeOf(context)?.skin.borderWidth ?? UiBorder.standard;
    final quiet = skinBorder < UiBorder.standard;
    final stroke = skinBorder;
    // Camera dock: cream outline + black 2dp hard shadow (`.camera-dock`).
    final shadowOffset = useLiquid
        ? 0.0
        : ((quiet || camera) ? UiShadow.tiny : UiShadow.large);
    final outline = camera ? UiCamera.outline : ui.outline;
    final shadowColor = camera ? UiCamera.shadow : ui.hardShadowColor;
    final solid = reduceTransparency || media.highContrast;
    // V2: journey docks tint the skin surface at 62%, the shell dock at 78%
    // (light) / 80% (dark), so content shows through the blur.
    final tintAlpha = UiSkinScope.maybeOf(context) != null
        ? 0.62
        : (dark ? 0.80 : 0.78);

    final leftItems = [left, ...extraLeft];
    final rightItems = [...extraRight, right];
    final items = [...leftItems, ...rightItems];
    final activeIndex = items.indexWhere((e) => e.active);
    final height = camera ? _cameraDockH : _dockH;
    const radius = BorderRadius.all(Radius.circular(32));

    final Widget centerChild =
        center ??
        UiSnapPill(
          key: snapKey,
          label: snapLabel,
          onPressed: onSnap,
          accent: accent,
          onAccent: onAccent,
          outlineColor: outline,
          outlineWidth: stroke,
          shadowOffset: shadowOffset,
          shadowColor: shadowColor,
          onLongPress: onShutterLongPress,
        );

    final Widget centerSlot = center != null && onShutterLongPress != null
        ? _LongPress(onLongPress: onShutterLongPress!, child: centerChild)
        : centerChild;

    const centerSlotWidth = _centerSlot;
    // The camera dock is 16dp taller and its hard shadow 2dp smaller, so its
    // vertical centre sits (16 / 2 - 2) = 6dp higher than the shell dock's.
    // Push the tab row (not the shutter) back down by that much so Journeys,
    // Squad, Activity and Profile stay exactly where they were.
    final tabDy = camera
        ? (_cameraDockH - _dockH) / 2 - (UiShadow.large - UiShadow.tiny)
        : 0.0;

    final bar = LayoutBuilder(
      builder: (context, c) {
        final slotW = (c.maxWidth - centerSlotWidth) / items.length;
        final pillW = math.min(_pillW, slotW);
        // Label row bottom edge, measured from the pill centre; the capsule's
        // curve narrows the usable width there (U17), so the label is
        // scaled down to the chord instead of touching the outline.
        final labelBottom = 19.0 - dockTabLift + dockLabelGrowth(context);
        const r = _pillH / 2;
        final inset = r - math.sqrt(r * r - labelBottom * labelBottom);
        final tabMaxW = math.min(
          slotW,
          math.max(UiSize.tap, pillW - 2 * inset - 3.0),
        );
        final labelFit = dockLabelFit(context, [
          for (final e in items) e.label,
        ], tabMaxW);
        double slotX(int i) => i < leftItems.length
            ? i * slotW
            : leftItems.length * slotW +
                  centerSlotWidth +
                  (i - leftItems.length) * slotW;
        final pillFill = accent ?? ui.accent;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (activeIndex >= 0)
              AnimatedPositioned(
                duration: UiMotion.of(context, _pillDuration),
                curve: _pillCurve,
                left: slotX(activeIndex) + (slotW - pillW) / 2,
                top: (c.maxHeight - _pillH) / 2 + tabDy,
                width: pillW,
                height: _pillH,
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey('dock-selection-pill'),
                    decoration: useLiquid
                        ? _lensDecoration(pillFill, dark)
                        : dockSelectionDecoration(
                            accent: pillFill,
                            surface: ui.surface,
                            outline: outline,
                            shadow: shadowColor,
                            camera: camera,
                          ),
                  ),
                ),
              ),
            Row(
              children: [
                for (final item in leftItems)
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(0, tabDy),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: tabMaxW),
                          child: DockTab(
                            item: item,
                            camera: camera,
                            onAccent: onAccent,
                            labelFit: labelFit,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: centerSlotWidth),
                for (final item in rightItems)
                  Expanded(
                    child: Transform.translate(
                      offset: Offset(0, tabDy),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: tabMaxW),
                          child: DockTab(
                            item: item,
                            camera: camera,
                            onAccent: onAccent,
                            labelFit: labelFit,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Center(child: centerSlot),
          ],
        );
      },
    );

    // Fixed height: the Center in the shutter slot would otherwise expand to
    // the full available height (the dock filled the whole screen).
    final surface = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: _dockSideInset, vertical: 6),
      // Camera: the dark dock tint lives here so glass stays neutral.
      decoration: camera && !useLiquid
          ? const BoxDecoration(color: UiCamera.dock)
          : null,
      // V2 glass sheen: `inset 0 1px 0 rgb(255 255 255 / 42%)`.
      foregroundDecoration: camera || solid || useLiquid
          ? null
          : BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.05, 0.06],
                colors: [
                  Colors.white.withValues(alpha: dark ? 0.24 : 0.42),
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
      child: bar,
    );

    final Widget glass = useLiquid
        ? GlassContainer(
            useOwnLayer: true,
            shape: const LiquidRoundedSuperellipse(borderRadius: 32),
            settings: _liquidSettings(camera: camera, dark: dark),
            child: surface,
          )
        : UiGlass(
            borderRadius: radius,
            blur: 20,
            saturation: 1.6,
            tint: camera
                ? Colors.transparent
                : ui.surface.withValues(alpha: tintAlpha),
            fallback: camera ? UiCamera.dock : ui.surface,
            borderColor: outline,
            borderWidth: stroke,
            hardShadow: shadowOffset,
            hardShadowColor: shadowColor,
            reduceTransparency: reduceTransparency,
            child: surface,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        UiSpace.sm,
        UiSpace.xs,
        // Same right gutter in every mode (the shell dock's 4dp shadow), so
        // the tabs keep their x when the camera dock swaps in.
        UiSpace.sm + UiShadow.large,
        (bottom < UiSpace.sm ? UiSpace.sm : bottom) + shadowOffset,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380 + 16),
          // UiGlass draws the outside-only hard shadow itself.
          child: glass,
        ),
      ),
    );
  }
}

/// Apple-style Liquid Glass look for the dock capsule: strong refraction,
/// chromatic edge, specular rim, adaptive tint (dark for the camera dock).
LiquidGlassSettings _liquidSettings({
  required bool camera,
  required bool dark,
}) {
  final tint = camera
      ? const Color(0x33111114)
      : (dark ? const Color(0x22FFFFFF) : const Color(0x33FFFFFF));
  return LiquidGlassSettings(
    glassColor: tint,
    thickness: 22,
    blur: 6,
    chromaticAberration: 0.012,
    lightIntensity: 0.7,
    refractiveIndex: 1.25,
    saturation: 1.4,
  );
}

/// The moving selection "lens": the skin accent as a translucent capsule with
/// a specular top-left rim, so it reads as a glass bead sliding in the bar.
BoxDecoration _lensDecoration(Color accent, bool dark) => BoxDecoration(
  borderRadius: BorderRadius.circular(dockSelectionRadius),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent.withValues(alpha: 0.95), accent.withValues(alpha: 0.78)],
  ),
  border: Border.all(
    color: Colors.white.withValues(alpha: dark ? 0.45 : 0.7),
    width: 1,
  ),
  boxShadow: [
    BoxShadow(
      color: accent.withValues(alpha: 0.35),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ],
);

/// Fires [onLongPress] after 400ms (the journey wheel gesture) without
/// stealing taps from the child.
class _LongPress extends StatelessWidget {
  const _LongPress({required this.onLongPress, required this.child});

  final VoidCallback onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: _longPress),
              (r) => r.onLongPress = onLongPress,
            ),
      },
      child: child,
    );
  }
}

/// `.camera-capsule`: 56x40 quick-snap pill on Hub / Timeline / Squad, in the
/// brand (or [accent]) fill with a sticker outline and hard shadow.
class UiSnapPill extends StatelessWidget {
  const UiSnapPill({
    required this.label,
    required this.onPressed,
    this.accent,
    this.onAccent,
    this.outlineColor,
    this.outlineWidth = UiBorder.standard,
    this.shadowOffset = UiShadow.small,
    this.shadowColor,
    this.onLongPress,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? accent;
  final Color? onAccent;
  final Color? outlineColor;
  final double outlineWidth;
  final double shadowOffset;

  /// Hard shadow color; defaults to `ui.hardShadowColor`.
  final Color? shadowColor;

  /// 400ms press (journey wheel).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final line = outlineColor ?? ui.outline;
    final fg = onAccent ?? ui.onBrand;
    Widget pill = UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      minSize: const Size(UiSize.snapPillW, UiSize.tap),
      centerChild: true,
      shadowOffset: shadowOffset,
      shadowColor: shadowColor ?? ui.hardShadowColor,
      child: Container(
        width: UiSize.snapPillW,
        height: UiSize.snapPillH,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent ?? ui.accent,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: Border.all(color: line, width: outlineWidth),
        ),
        child: OurneyIcon(name: 'camera', size: 24, color: fg, inkColor: fg),
      ),
    );
    if (onLongPress != null) {
      pill = _LongPress(onLongPress: onLongPress!, child: pill);
    }
    return pill;
  }
}

/// `.shutter`: 76dp [accent] (brand) disc with a sticker outline and hard
/// shadow (Hero Shutter on the camera screen). [onLongPress] (400ms) opens the
/// journey wheel.
class UiShutter extends StatelessWidget {
  const UiShutter({
    required this.label,
    required this.onPressed,
    this.accent,
    this.onAccent,
    this.onLongPress,
    this.outlineColor,
    this.dimmed = false,
    super.key,
  });

  /// Fades the shutter (animated) while the camera is not ready. A momentary
  /// busy state (a capture in flight) must not dim it.
  final bool dimmed;

  final String label;
  final VoidCallback? onPressed;
  final Color? accent;

  /// Foreground of the camera icon on [accent] (falls back to onBrand).
  final Color? onAccent;
  final VoidCallback? onLongPress;
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    final line = outlineColor ?? UiCamera.outline;
    const shadow = UiCamera.shadow;
    final fg = onAccent ?? context.ui.onBrand;
    final width =
        UiSkinScope.maybeOf(context)?.skin.borderWidth ?? UiBorder.standard;
    Widget shutter = UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      minSize: const Size.square(UiSize.shutter),
      shadowOffset: UiShadow.small,
      shadowColor: shadow,
      child: Container(
        width: UiSize.shutter,
        height: UiSize.shutter,
        decoration: BoxDecoration(
          color: accent ?? context.ui.accent,
          shape: BoxShape.circle,
          border: Border.all(color: line, width: width),
        ),
        child: Center(
          child: OurneyIcon(name: 'camera', size: 30, color: fg, inkColor: fg),
        ),
      ),
    );
    // Camera not ready (starting, no permission): [dimmed] fades it so it
    // does not look live while ignoring taps. The long press (journey wheel)
    // still works.
    shutter = AnimatedOpacity(
      opacity: dimmed ? 0.5 : 1,
      duration: UiMotion.of(context, UiMotion.press),
      child: shutter,
    );
    if (onLongPress != null) {
      shutter = _LongPress(onLongPress: onLongPress!, child: shutter);
    }
    return shutter;
  }
}
