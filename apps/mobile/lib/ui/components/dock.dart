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
    final resolvedBaseIslandH = baseIslandH ?? math.max(_E4.islandH, islandH);
    final resolvedBandH = bandH ?? resolvedBaseIslandH;
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
    final dockHeight = islandBottom + bottomGap;
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

/// The E4 floating dock: two glass islands (blur 20, saturation 1.6, solid
/// when transparency is reduced) flanking a free-standing 60dp camera circle
/// (52dp when [compact] on scroll), with a selection capsule that morphs into
/// a 40dp circle when compact.
///
/// 3-slot form: [left], the center camera circle, [right]. 5-tab form (V2):
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
    this.compact = false,
    this.snapKey,
    this.centerAnchorKey,
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

  /// Key of the centre camera button.
  final Key? snapKey;

  /// Optional key attached to the [KeyedSubtree] wrapping the centre slot
  /// (camera circle or [center] shutter) so callers can anchor overlays such as
  /// the journey wheel on its centre.
  final GlobalKey? centerAnchorKey;

  final UiDockItem left;
  final UiDockItem right;

  /// Tabs between [left] and the center (left island).
  final List<UiDockItem> extraLeft;

  /// Tabs between the center and [right] (right island).
  final List<UiDockItem> extraRight;
  final String snapLabel;
  final VoidCallback onSnap;
  final Color? accent;
  final Color? onAccent;

  /// Replaces the camera circle (the camera screen's 76dp hero shutter).
  final Widget? center;
  final bool camera;

  /// E4 compact state (scroll-driven): islands and camera shrink to 52dp,
  /// labels collapse, and the selection capsule morphs into a 40dp circle.
  /// Ignored when [camera] is true.
  final bool compact;

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
    // V2: journey docks tint the skin surface at 62%, the shell dock at 78%
    // (light) / 80% (dark), so content shows through the blur.
    final tintAlpha = UiSkinScope.maybeOf(context) != null
        ? 0.62
        : (dark ? 0.80 : 0.78);

    final leftItems = [left, ...extraLeft];
    final rightItems = [...extraRight, right];
    final items = [...leftItems, ...rightItems];
    final activeIndex = items.indexWhere((e) => e.active);
    final tabsPerSide = math.max(
      1,
      math.max(leftItems.length, rightItems.length),
    );
    final bottomGap = math.max(bottom, _E4.minBottomInset) + _E4.bottomExtra;
    final pillFill = accent ?? ui.accent;
    final fgOnAccent = onAccent ?? ui.onBrand;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : media.size.width;
        final shownBaseGeo = UiDockGeometry.compute(
          width: width,
          cam: _E4.camD,
          islandH: _E4.islandH,
          tabsPerSide: tabsPerSide,
        );
        final labelMaxW = math.max(0.0, shownBaseGeo.capsuleWidth - 6);
        final labels = [for (final e in items) e.label];
        final labelFit = dockLabelFit(context, labels, labelMaxW);
        final textScale = MediaQuery.textScalerOf(
          context,
        ).clamp(maxScaleFactor: dockLabelMaxScale).scale(1);
        final lineH = dockLabelSize * labelFit * 1.35 * textScale;
        final capH = math.max(
          _E4.capH,
          _E4.glyph + _E4.labelGap + lineH + 10.4,
        );
        final baseIslandH = math.max(_E4.islandH, capH + 12);

        final effectiveCompact = !camera && compact;
        final targetT = effectiveCompact ? 1.0 : 0.0;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: targetT),
          duration: UiMotion.of(context, UiMotion.medium),
          curve: UiCurves.easeOutStrong,
          builder: (context, compactT, _) {
            final t = camera
                ? 0.0
                : (UiMotion.reduced(context)
                      ? targetT
                      : compactT.clamp(0.0, 1.0));
            final shellCam = lerpDouble(_E4.camD, _E4.camDCompact, t)!;
            final shellCamIcon = lerpDouble(
              _E4.camIcon,
              _E4.camIconCompact,
              t,
            )!;
            final currentIslandH = camera
                ? _E4.islandH
                : lerpDouble(baseIslandH, _E4.islandHCompact, t)!;
            final currentCam = camera ? _E4.camDRoute : shellCam;
            final currentBandH = camera
                ? _E4.camDRoute
                : baseIslandH;
            final geo = UiDockGeometry.compute(
              width: width,
              cam: currentCam,
              islandH: currentIslandH,
              topPad: _E4.topPad,
              bandH: currentBandH,
              bottomGap: bottomGap,
              baseIslandH: camera ? _E4.islandH : baseIslandH,
              capH: capH,
              tabsPerSide: tabsPerSide,
            );

            final Widget centerChild =
                center ??
                _DockCamera(
                  snapKey: snapKey,
                  label: snapLabel,
                  onPressed: onSnap,
                  onLongPress: onShutterLongPress,
                  diameter: shellCam,
                  iconSize: shellCamIcon,
                  accent: pillFill,
                  onAccent: fgOnAccent,
                  outlineColor: outline,
                  outlineWidth: stroke,
                  shadowOffset: shadowOffset,
                  shadowColor: shadowColor,
                );

            final Widget centerSlot =
                center != null && onShutterLongPress != null
                ? _LongPress(
                    onLongPress: onShutterLongPress!,
                    child: centerChild,
                  )
                : centerChild;

            final Widget morphingCenter = _UiDockCenterMorph(
              camera: camera,
              accent: pillFill,
              onAccent: fgOnAccent,
              outlineColor: outline,
              outlineWidth: stroke,
              shadowOffset: shadowOffset,
              shadowColor: shadowColor,
              child: centerSlot,
            );

            final centerBoxSize = math.max(geo.cameraRect.width, _E4.camDRoute);

            return SizedBox(
              width: width,
              height: geo.dockHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _DockIsland(
                    rect: geo.leftIsland,
                    camera: camera,
                    useLiquid: useLiquid,
                    dark: dark,
                    tintAlpha: tintAlpha,
                    outline: outline,
                    stroke: stroke,
                    shadowOffset: shadowOffset,
                    shadowColor: shadowColor,
                    reduceTransparency: reduceTransparency,
                  ),
                  _DockIsland(
                    rect: geo.rightIsland,
                    camera: camera,
                    useLiquid: useLiquid,
                    dark: dark,
                    tintAlpha: tintAlpha,
                    outline: outline,
                    stroke: stroke,
                    shadowOffset: shadowOffset,
                    shadowColor: shadowColor,
                    reduceTransparency: reduceTransparency,
                  ),
                  if (!camera && activeIndex >= 0)
                    _DockSelectionSlide(
                      activeIndex: activeIndex,
                      geometry: geo,
                      expandedCapsuleWidth: shownBaseGeo.capsuleWidth,
                      compactT: t,
                      accent: pillFill,
                      surface: ui.surface,
                      outline: outline,
                      shadow: shadowColor,
                      camera: camera,
                      useLiquid: useLiquid,
                      dark: dark,
                    ),
                  for (var i = 0; i < leftItems.length; i++)
                    Positioned.fromRect(
                      rect: geo.tabSlots[i],
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: geo.slotWidth),
                        child: DockTab(
                          item: leftItems[i],
                          camera: camera,
                          onAccent: onAccent,
                          labelFit: labelFit,
                          labelMaxWidth: labelMaxW,
                          lift: 0,
                          labelGap: _E4.labelGap,
                          compactT: t,
                        ),
                      ),
                    ),
                  for (var i = 0; i < rightItems.length; i++)
                    Positioned.fromRect(
                      rect: geo.tabSlots[tabsPerSide + i],
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: geo.slotWidth),
                        child: DockTab(
                          item: rightItems[i],
                          camera: camera,
                          onAccent: onAccent,
                          labelFit: labelFit,
                          labelMaxWidth: labelMaxW,
                          lift: 0,
                          labelGap: _E4.labelGap,
                          compactT: t,
                        ),
                      ),
                    ),
                  Positioned(
                    left: (width - centerBoxSize) / 2,
                    top: geo.centerY - centerBoxSize / 2,
                    width: centerBoxSize,
                    height: centerBoxSize,
                    child: Center(
                      child: centerAnchorKey != null
                          ? KeyedSubtree(
                              key: centerAnchorKey,
                              child: morphingCenter,
                            )
                          : morphingCenter,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DockIsland extends StatelessWidget {
  const _DockIsland({
    required this.rect,
    required this.camera,
    required this.useLiquid,
    required this.dark,
    required this.tintAlpha,
    required this.outline,
    required this.stroke,
    required this.shadowOffset,
    required this.shadowColor,
    required this.reduceTransparency,
  });

  final Rect rect;
  final bool camera;
  final bool useLiquid;
  final bool dark;
  final double tintAlpha;
  final Color outline;
  final double stroke;
  final double shadowOffset;
  final Color shadowColor;
  final bool reduceTransparency;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final r = rect.height / 2;
    final radius = BorderRadius.circular(r);
    final Widget island = useLiquid
        ? GlassContainer(
            useOwnLayer: true,
            shape: LiquidRoundedSuperellipse(borderRadius: r),
            settings: _liquidSettings(camera: camera, dark: dark),
            child: const SizedBox.expand(),
          )
        : UiGlass(
            borderRadius: radius,
            blur: camera ? 0 : 20,
            saturation: 1.6,
            tint: camera
                ? UiCamera.dock
                : ui.surface.withValues(alpha: tintAlpha),
            fallback: camera ? UiCamera.dock : ui.surface,
            borderColor: outline,
            borderWidth: stroke,
            hardShadow: shadowOffset,
            hardShadowColor: shadowColor,
            reduceTransparency: reduceTransparency,
            child: const SizedBox.expand(),
          );
    return Positioned.fromRect(rect: rect, child: island);
  }
}

class _DockSelection extends StatelessWidget {
  const _DockSelection({
    required this.rect,
    required this.accent,
    required this.surface,
    required this.outline,
    required this.shadow,
    required this.camera,
    required this.useLiquid,
    required this.dark,
  });

  final Rect rect;
  final Color accent;
  final Color surface;
  final Color outline;
  final Color shadow;
  final bool camera;
  final bool useLiquid;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(rect.height / 2);
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: DecoratedBox(
          key: const ValueKey('dock-selection-pill'),
          decoration: useLiquid
              ? _lensDecoration(accent, dark).copyWith(
                  borderRadius: borderRadius,
                )
              : dockSelectionDecoration(
                  accent: accent,
                  surface: surface,
                  outline: outline,
                  shadow: shadow,
                  camera: camera,
                  borderRadius: borderRadius,
                ),
        ),
      ),
    );
  }
}

class _DockSelectionSlide extends StatefulWidget {
  const _DockSelectionSlide({
    required this.activeIndex,
    required this.geometry,
    required this.expandedCapsuleWidth,
    required this.compactT,
    required this.accent,
    required this.surface,
    required this.outline,
    required this.shadow,
    required this.camera,
    required this.useLiquid,
    required this.dark,
  });

  final int activeIndex;
  final UiDockGeometry geometry;
  final double expandedCapsuleWidth;
  final double compactT;
  final Color accent;
  final Color surface;
  final Color outline;
  final Color shadow;
  final bool camera;
  final bool useLiquid;
  final bool dark;

  @override
  State<_DockSelectionSlide> createState() => _DockSelectionSlideState();
}

class _DockSelectionSlideState extends State<_DockSelectionSlide>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  CurvedAnimation? _curved;
  double _fromU = 0;
  double _toU = 0;

  double _uForTab(UiDockGeometry g, int index) {
    final centres = g.tabCentersX;
    if (centres.length <= 1) return 0;
    final clamped = index.clamp(0, centres.length - 1);
    final first = centres.first;
    final span = centres.last - first;
    return span == 0 ? 0 : (centres[clamped] - first) / span;
  }

  double _centerXFromU(UiDockGeometry g, double u) {
    final centres = g.tabCentersX;
    if (centres.isEmpty) return g.width / 2;
    if (centres.length == 1) return centres.first;
    return lerpDouble(centres.first, centres.last, u)!;
  }

  double _currentU(UiDockGeometry g) {
    final curved = _curved;
    if (curved == null || !(_ctrl?.isAnimating ?? false)) {
      return _uForTab(g, widget.activeIndex);
    }
    return lerpDouble(_fromU, _toU, curved.value)!;
  }

  AnimationController _ensureController() {
    var ctrl = _ctrl;
    if (ctrl != null) return ctrl;
    ctrl = AnimationController(vsync: this, duration: UiMotion.dockPill);
    _ctrl = ctrl;
    _curved = CurvedAnimation(parent: ctrl, curve: UiCurves.dockOvershoot);
    return ctrl;
  }

  @override
  void initState() {
    super.initState();
    _fromU = _uForTab(widget.geometry, widget.activeIndex);
    _toU = _fromU;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.stop();
      _fromU = _uForTab(widget.geometry, widget.activeIndex);
      _toU = _fromU;
    }
  }

  @override
  void didUpdateWidget(covariant _DockSelectionSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex) {
      final targetU = _uForTab(widget.geometry, widget.activeIndex);
      if (UiMotion.reduced(context)) {
        _ctrl?.stop();
        _fromU = targetU;
        _toU = targetU;
        return;
      }
      final startU = (_ctrl?.isAnimating ?? false)
          ? _currentU(widget.geometry)
          : _uForTab(widget.geometry, oldWidget.activeIndex);
      _fromU = startU;
      _toU = targetU;
      _ensureController()
        ..duration = UiMotion.of(context, UiMotion.dockPill)
        ..forward(from: 0.0);
    }
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
    final g = widget.geometry;
    if (UiMotion.reduced(context) ||
        ctrl == null ||
        curved == null ||
        !ctrl.isAnimating) {
      final idx = widget.activeIndex.clamp(0, g.tabCentersX.length - 1);
      final rect = g.selectionRectAt(
        g.tabCentersX[idx],
        widget.compactT,
        expandedWidth: widget.expandedCapsuleWidth,
      );
      return _DockSelection(
        rect: rect,
        accent: widget.accent,
        surface: widget.surface,
        outline: widget.outline,
        shadow: widget.shadow,
        camera: widget.camera,
        useLiquid: widget.useLiquid,
        dark: widget.dark,
      );
    }

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final u = lerpDouble(_fromU, _toU, curved.value)!;
        final cx = _centerXFromU(widget.geometry, u);
        final rect = widget.geometry.selectionRectAt(
          cx,
          widget.compactT,
          expandedWidth: widget.expandedCapsuleWidth,
        );
        return _DockSelection(
          rect: rect,
          accent: widget.accent,
          surface: widget.surface,
          outline: widget.outline,
          shadow: widget.shadow,
          camera: widget.camera,
          useLiquid: widget.useLiquid,
          dark: widget.dark,
        );
      },
    );
  }
}

class _DockCamera extends StatelessWidget {
  const _DockCamera({
    required this.snapKey,
    required this.label,
    required this.onPressed,
    required this.onLongPress,
    required this.diameter,
    required this.iconSize,
    required this.accent,
    required this.onAccent,
    required this.outlineColor,
    required this.outlineWidth,
    required this.shadowOffset,
    required this.shadowColor,
  });

  final Key? snapKey;
  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final double diameter;
  final double iconSize;
  final Color accent;
  final Color onAccent;
  final Color outlineColor;
  final double outlineWidth;
  final double shadowOffset;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    Widget button = UiPressable(
      key: snapKey,
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      haptic: true,
      minSize: const Size.square(UiSize.tap),
      shadowOffset: shadowOffset,
      shadowColor: shadowColor,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
          border: Border.all(color: outlineColor, width: outlineWidth),
        ),
        child: Center(
          child: OurneyIcon(
            name: 'camera',
            size: iconSize,
            color: onAccent,
            inkColor: onAccent,
          ),
        ),
      ),
    );
    if (onLongPress != null) {
      button = _LongPress(onLongPress: onLongPress!, child: button);
    }
    return button;
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
          child: OurneyIcon(
            name: 'camera',
            size: _E4.camIconRoute,
            color: fg,
            inkColor: fg,
          ),
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
