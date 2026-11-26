import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

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
// hero shutter, and the 76dp hero shutter never overlaps Squad or Activity.
const double _centerSlot = UiSize.shutter;
const double _dockSideInset = 10;

/// Constants for the E4 two-island dock layout.
abstract final class _E4 {
  static const double margin = 12;
  static const double gap = 6;
  static const double pad = 4;
  static const double slotMax = 76;
  static const double islandH = 64;
  static const double islandHCompact = 52;
  static const double camD = 60;
  static const double camDCompact = 52;
  static const double camDRoute = UiSize.shutter;
  static const double capH = 52;
  static const double ring = 40;
  static const double glyph = 24;
  static const double glyphActiveScale = 1.08;
  static const double labelGap = 3;
  static const double camIcon = 28;
  static const double camIconCompact = 24;
  static const double camIconRoute = 30;
  static const double topPad = UiSpace.xs;
  static const double minBottomInset = 8;
  static const double bottomExtra = 8;
  static const double capsuleOpticalLift =
      glyph * (glyphActiveScale - 1) / 4; // 0.48
}

/// Pure E4 dock layout geometry for a given screen [width] and state.
@visibleForTesting
@immutable
class UiDockGeometry {
  const UiDockGeometry({
    required this.width,
    required this.dockHeight,
    required this.slotWidth,
    required this.islandWidth,
    required this.islandHeight,
    required this.capsuleWidth,
    required this.capsuleHeight,
    required this.centerY,
    required this.leftIsland,
    required this.rightIsland,
    required this.cameraRect,
    required this.tabSlots,
    required this.tabCentersX,
    required this.allCentersX,
  });

  final double width;
  final double dockHeight;
  final double slotWidth;
  final double islandWidth;
  final double islandHeight;
  final double capsuleWidth;
  final double capsuleHeight;
  final double centerY;
  final Rect leftIsland;
  final Rect rightIsland;
  final Rect cameraRect;

  /// The [2 * tabsPerSide] tab slot rects (left to right, excluding camera).
  final List<Rect> tabSlots;

  /// X centres of the [2 * tabsPerSide] tab slots.
  final List<double> tabCentersX;

  /// X centres of all controls in visual order: left tabs, camera (`width / 2`),
  /// right tabs.
  final List<double> allCentersX;

  /// Computes the E4 geometry.
  ///
  /// [cam] is the centre-slot diameter in the current state (`60` labels shown,
  /// `52` compact, `76` on the camera route, or lerped while animating).
  /// [islandH] is the current island height (`64` shown, `52` compact, or
  /// lerped).
  /// [baseIslandH] is the expanded island height (`64` at 1x, larger at >1x
  /// text scale) used to anchor the constant island bottom edge inside [bandH].
  static UiDockGeometry compute({
    required double width,
    required double cam,
    required double islandH,
    double topPad = _E4.topPad,
    double? bandH,
    double bottomGap = _E4.minBottomInset + _E4.bottomExtra,
    double? baseIslandH,
    double capH = _E4.capH,
    int tabsPerSide = 2,
  }) {
    // Keep _E4 constants referenced before Step 2 replaces the old build body.
    assert(
      _E4.islandHCompact == 52 &&
          _E4.camD == 60 &&
          _E4.camDCompact == 52 &&
          _E4.camDRoute == 76 &&
          _E4.labelGap == 3 &&
          _E4.camIcon == 28 &&
          _E4.camIconCompact == 24 &&
          _E4.camIconRoute == 30,
    );
    final resolvedBaseIslandH = baseIslandH ?? math.max(_E4.islandH, islandH);
    final resolvedBandH = bandH ?? resolvedBaseIslandH;
    final dockHeight = topPad + resolvedBandH + bottomGap;
    final slot = math.min(
      _E4.slotMax,
      (width - 2 * _E4.margin - cam - 2 * _E4.gap - 4 * _E4.pad) /
          (2 * tabsPerSide),
    );
    final islandW = tabsPerSide * slot + 2 * _E4.pad;
    final total = 2 * islandW + 2 * _E4.gap + cam;
    final x0 = (width - total) / 2;
    final rightX0 = x0 + islandW + _E4.gap + cam + _E4.gap;

    final islandBottom =
        topPad + resolvedBandH - (resolvedBandH - resolvedBaseIslandH) / 2;
    final islandTop = islandBottom - islandH;
    final cy = islandBottom - islandH / 2;

    final leftIsland = Rect.fromLTRB(x0, islandTop, x0 + islandW, islandBottom);
    final rightIsland = Rect.fromLTRB(
      rightX0,
      islandTop,
      rightX0 + islandW,
      islandBottom,
    );
    final cameraRect = Rect.fromCenter(
      center: Offset(width / 2, cy),
      width: cam,
      height: cam,
    );

    final tabSlots = <Rect>[
      for (var i = 0; i < tabsPerSide; i++)
        Rect.fromLTWH(x0 + _E4.pad + i * slot, islandTop, slot, islandH),
      for (var i = 0; i < tabsPerSide; i++)
        Rect.fromLTWH(rightX0 + _E4.pad + i * slot, islandTop, slot, islandH),
    ];
    final tabCentersX = <double>[for (final r in tabSlots) r.center.dx];
    final allCentersX = <double>[
      for (var i = 0; i < tabsPerSide; i++) tabCentersX[i],
      width / 2,
      for (var i = tabsPerSide; i < 2 * tabsPerSide; i++) tabCentersX[i],
    ];
    final capW = slot - 2;

    return UiDockGeometry(
      width: width,
      dockHeight: dockHeight,
      slotWidth: slot,
      islandWidth: islandW,
      islandHeight: islandH,
      capsuleWidth: capW,
      capsuleHeight: capH,
      centerY: cy,
      leftIsland: leftIsland,
      rightIsland: rightIsland,
      cameraRect: cameraRect,
      tabSlots: List.unmodifiable(tabSlots),
      tabCentersX: List.unmodifiable(tabCentersX),
      allCentersX: List.unmodifiable(allCentersX),
    );
  }

  /// Expanded selection capsule rect centred horizontally on [centerX].
  Rect capsuleRectAt(double centerX, {double? width}) {
    final w = width ?? capsuleWidth;
    return Rect.fromLTWH(
      centerX - w / 2,
      centerY - capsuleHeight / 2 - _E4.capsuleOpticalLift,
      w,
      capsuleHeight,
    );
  }

  /// Compact 40×40 selection circle rect centred on ([centerX], [centerY]).
  Rect circleRectAt(double centerX) => Rect.fromCenter(
    center: Offset(centerX, centerY),
    width: _E4.ring,
    height: _E4.ring,
  );

  /// Lerped selection rect at morph progress [compactT] (`0` = capsule,
  /// `1` = circle) centred horizontally on [centerX].
  Rect selectionRectAt(
    double centerX,
    double compactT, {
    double? expandedWidth,
  }) => Rect.lerp(
    capsuleRectAt(centerX, width: expandedWidth),
    circleRectAt(centerX),
    compactT,
  )!;

  /// Selection rect for [tabIndex] (`0..tabSlots.length - 1`) at [compactT].
  Rect selectionRectForTab(
    int tabIndex, {
    double compactT = 0,
    double? expandedWidth,
  }) => selectionRectAt(
    tabCentersX[tabIndex],
    compactT,
    expandedWidth: expandedWidth,
  );
}

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
        // On 360dp phones (slotW = 61dp) let the centered selection capsule be
        // 66dp wide so 10.25dp Vietnamese labels stay inside its curved ends,
        // while keeping pillW == slotW at 320dp (51dp) and >= 390dp (68.5dp+).
        final pillW = math.min(
          _pillW,
          slotW < 66
              ? math.min(66.0, slotW + (slotW - 51.0).clamp(0.0, 5.0))
              : slotW,
        );
        final labels = [for (final e in items) e.label];
        final labelFit = dockLabelFit(
          context,
          labels,
          slotW,
          slotW: slotW,
          pillW: pillW,
        );
        final effectiveScale =
            labelFit *
            MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: dockLabelMaxScale).scale(1);
        final labelMaxW = dockLabelChordWidth(
          slotW,
          pillW,
          effectiveScale: effectiveScale,
        );
        final tabMaxW = math.min(slotW, math.max(UiSize.tap, labelMaxW));
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
                duration: UiMotion.of(context, UiMotion.dockPill),
                curve: UiCurves.dockOvershoot,
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
                            labelMaxWidth: labelMaxW,
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
                            labelMaxWidth: labelMaxW,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Center(
              child: _UiDockCenterMorph(
                camera: camera,
                accent: accent ?? ui.accent,
                onAccent: onAccent ?? ui.onBrand,
                outlineColor: outline,
                outlineWidth: stroke,
                shadowOffset: shadowOffset,
                shadowColor: shadowColor,
                child: centerSlot,
              ),
            ),
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
      haptic: true,
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

/// Animates the center dock trigger between the `56×40` [UiSnapPill] and the
/// `76×76` [UiShutter] over [UiMotion.medium] (`220ms`, [UiCurves.easeOutStrong])
/// without non-uniformly scaling the `2dp` Neo-Brutalist border or warping the
/// `1:1` camera glyph.
///
/// Triggers when:
/// 1. [camera] flips on a mounted [UiDock],
/// 2. [TickerMode] transitions `false -> true` on an offstage tab branch
///    (entering Tab 2 Camera in `UiShellBranchContainer`), or
/// 3. Another active [UiDock] with the opposite [camera] mode hands off within
///    the same frame (leaving Tab 2 Camera back to the shell dock).
class _UiDockCenterMorph extends StatefulWidget {
  const _UiDockCenterMorph({
    required this.camera,
    required this.accent,
    required this.onAccent,
    required this.outlineColor,
    required this.outlineWidth,
    required this.shadowOffset,
    required this.shadowColor,
    required this.child,
  });

  final bool camera;
  final Color accent;
  final Color onAccent;
  final Color outlineColor;
  final double outlineWidth;
  final double shadowOffset;
  final Color shadowColor;
  final Widget child;

  @override
  State<_UiDockCenterMorph> createState() => _UiDockCenterMorphState();
}

class _UiDockCenterMorphState extends State<_UiDockCenterMorph>
    with SingleTickerProviderStateMixin {
  static bool? _pendingHandoffFromCamera;
  static bool _handoffClearScheduled = false;

  static void _recordHandoff(bool fromCamera) {
    _pendingHandoffFromCamera = fromCamera;
    if (!_handoffClearScheduled) {
      _handoffClearScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pendingHandoffFromCamera = null;
        _handoffClearScheduled = false;
      });
    }
  }

  AnimationController? _ctrl;
  CurvedAnimation? _curved;
  bool _didInit = false;
  bool _lastTickerEnabled = true;
  late double _fromT = widget.camera ? 1.0 : 0.0;
  late double _toT = widget.camera ? 1.0 : 0.0;

  double get _currentT {
    final curved = _curved;
    if (curved == null || !(_ctrl?.isAnimating ?? false)) {
      return _toT;
    }
    return lerpDouble(_fromT, _toT, curved.value)!;
  }

  AnimationController _ensureController() {
    var ctrl = _ctrl;
    if (ctrl != null) return ctrl;
    ctrl = AnimationController(
      vsync: this,
      duration: UiMotion.medium,
    );
    _ctrl = ctrl;
    _curved = CurvedAnimation(
      parent: ctrl,
      curve: UiCurves.easeOutStrong,
    );
    return ctrl;
  }

  void _startMorph({required double from, required double to}) {
    if (UiMotion.reduced(context) || (from - to).abs() < 0.001) {
      _ctrl?.stop();
      _fromT = to;
      _toT = to;
      return;
    }
    _fromT = from;
    _toT = to;
    final ctrl = _ensureController();
    ctrl
      ..duration = UiMotion.of(context, UiMotion.medium)
      ..forward(from: 0.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    final reduced = UiMotion.reduced(context);
    final target = widget.camera ? 1.0 : 0.0;

    if (!_didInit) {
      _didInit = true;
      _lastTickerEnabled = tickerEnabled;
      final handoffFromCamera = _pendingHandoffFromCamera;
      if (tickerEnabled &&
          handoffFromCamera != null &&
          handoffFromCamera != widget.camera) {
        _pendingHandoffFromCamera = null;
        _startMorph(from: handoffFromCamera ? 1.0 : 0.0, to: target);
      } else {
        _fromT = target;
        _toT = target;
      }
      return;
    }

    if (reduced && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.stop();
      _fromT = target;
      _toT = target;
    } else if (!_lastTickerEnabled && tickerEnabled) {
      _pendingHandoffFromCamera = null;
      _startMorph(from: widget.camera ? 0.0 : 1.0, to: target);
    } else if (_lastTickerEnabled && !tickerEnabled) {
      _recordHandoff(widget.camera);
      _ctrl?.stop();
      _fromT = target;
      _toT = target;
    }
    _lastTickerEnabled = tickerEnabled;
  }

  @override
  void didUpdateWidget(covariant _UiDockCenterMorph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.camera != widget.camera) {
      final target = widget.camera ? 1.0 : 0.0;
      _startMorph(from: _currentT, to: target);
    }
  }

  @override
  void deactivate() {
    if (_lastTickerEnabled) {
      _recordHandoff(widget.camera);
    }
    _ctrl?.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _curved?.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    final curved = _curved;
    if (UiMotion.reduced(context) ||
        ctrl == null ||
        curved == null ||
        (!ctrl.isAnimating && (_fromT - _toT).abs() < 0.001)) {
      return widget.child;
    }

    final ui = context.ui;
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, settledChild) {
        final t = lerpDouble(_fromT, _toT, curved.value)!;
        if (!ctrl.isAnimating || (t - _toT).abs() < 0.001) {
          return settledChild!;
        }
        final width = lerpDouble(UiSize.snapPillW, UiSize.shutter, t)!;
        final height = lerpDouble(UiSize.snapPillH, UiSize.shutter, t)!;
        final radius = BorderRadius.circular(height / 2);
        final iconSize = lerpDouble(24.0, 30.0, t)!;
        final outline = Color.lerp(ui.outline, UiCamera.outline, t)!;
        final shadowColor = Color.lerp(ui.hardShadowColor, UiCamera.shadow, t)!;
        final shellShadow = widget.camera ? UiShadow.large : widget.shadowOffset;
        final shadowOff = lerpDouble(shellShadow, UiShadow.small, t)!;

        return SizedBox(
          key: const ValueKey('dock-center-morph'),
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              if (shadowOff > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(shadowOff, shadowOff),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: shadowColor,
                          borderRadius: radius,
                        ),
                      ),
                    ),
                  ),
                ),
              DecoratedBox(
                key: const ValueKey('dock-center-morph-box'),
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: radius,
                  border: Border.all(
                    color: outline,
                    width: widget.outlineWidth,
                  ),
                ),
                child: Center(
                  child: OurneyIcon(
                    name: 'camera',
                    size: iconSize,
                    color: widget.onAccent,
                    inkColor: widget.onAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
