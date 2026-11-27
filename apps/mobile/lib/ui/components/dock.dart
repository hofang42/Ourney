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

/// Constants for the E4 (C1) two-island dock layout.
abstract final class _E4 {
  static const double margin = 12;
  static const double gap = 6;
  static const double pad = 5;
  static const double slotMax = 75;
  static const double slotMaxCompactWidth = 72;
  static const double islandH = 64;
  static const double islandHCompact = 52;
  static const double islandRadius = dockE4IslandRadius;
  static const double islandRadiusCompact = dockE4IslandRadiusCompact;
  static const double pillRadius = dockE4CapsuleRadius;
  static const double pillRadiusCompact = dockE4CapsuleRadiusCompact;
  static const double camD = 60;
  static const double camDCompact = 52;
  static const double camDRoute = UiSize.shutter;
  static const double capH = dockE4CapsuleHeight;
  static const double capsuleSlotInset = 2;
  static const double capsuleLabelSidePad = dockE4CapsuleLabelSidePad;
  static const double activeLongCapsuleLabelPad =
      dockE4ActiveLongCapsuleLabelPad;
  static const double capsuleDescenderClearanceMargin =
      dockE4DescenderClearanceMargin;
  static const double capsuleVertPad = dockE4CapsuleVertPad;
  static const double islandOverCapsule = 12;
  static const double ring = 40;
  static const double glyph = dockE4GlyphSize;
  static const double labelGap = dockE4LabelGap;
  static const double camIcon = 28;
  static const double camIconCompact = 24;
  static const double camIconRoute = 30;
  static const double topPad = UiSpace.xs;
  static const double minBottomInset = 8;
  static const double bottomExtra = 8;
  static const double capsuleOpticalLift = dockE4CapsuleOpticalLift;
}

/// Pure E4 (C1) dock layout geometry for a given screen [width] and state.
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

  /// Concentric island corner radius (`22 -> 26`, always `6dp` larger than
  /// [pillRadiusAt] at every morph progress [compactT] in `[0, 1]`).
  static double islandRadiusAt(double compactT) =>
      lerpDouble(_E4.islandRadius, _E4.islandRadiusCompact, compactT)!;

  /// Concentric selection pill corner radius (`16 -> 20`).
  static double pillRadiusAt(double compactT) =>
      lerpDouble(_E4.pillRadius, _E4.pillRadiusCompact, compactT)!;

  /// Desired expanded slot width when a long-label tab (`Hành trình` /
  /// `Hoạt động`) is active at [width]: `72.0dp` (`capW = 70.0dp`) below
  /// `390dp`, `75.0dp` (`capW = 73.0dp`) at `>= 390dp`.
  static double activeLongSlotTargetAt(double width) =>
      width < dockLabelWidthBreakpoint ? _E4.slotMaxCompactWidth : _E4.slotMax;

  /// Maximum label width inside the selection capsule at [width]:
  /// `min(capsuleWidth - 6, activeLongCapW - 17)` (`53.0dp` at `360dp`,
  /// `56.0dp` at `>= 390dp`).
  double get labelMaxWidth {
    final activeLongCapW = activeLongSlotTargetAt(width) - _E4.capsuleSlotInset;
    return math.max(
      0.0,
      math.min(
        capsuleWidth - _E4.capsuleLabelSidePad,
        activeLongCapW - _E4.activeLongCapsuleLabelPad,
      ),
    );
  }

  /// Computes the E4 (C1) geometry.
  ///
  /// [cam] is the centre-slot diameter in the current state (`60` labels shown,
  /// `52` compact, `76` on the camera route, or lerped while animating).
  /// [islandH] is the current island height (`64` shown, `52` compact, or
  /// lerped).
  /// [baseIslandH] is the expanded island height (`64` at 1x, larger at >1x
  /// text scale) used to anchor the constant island bottom edge inside [bandH].
  ///
  /// When [activeTabIndex] (or [targetSlotWidths] + [slotWeights]) is supplied,
  /// the island containing the active tab adaptively widens its active slot if
  /// needed (while short-label tabs keep 50/50 equal slots and partner slots
  /// never drop below `48dp`), lerping back to equal slots via [compactT].
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
    int? activeTabIndex,
    List<bool>? longTabMask,
    List<double>? targetSlotWidths,
    List<double>? slotWeights,
    double compactT = 0,
  }) {
    final resolvedBaseIslandH = baseIslandH ?? math.max(_E4.islandH, islandH);
    final resolvedBandH = bandH ?? resolvedBaseIslandH;
    final maxIslandW = tabsPerSide * _E4.slotMax + 2 * _E4.pad;
    final islandW = math.min(
      maxIslandW,
      (width - 2 * _E4.margin - cam - 2 * _E4.gap) / 2,
    );
    final pad = math.min(
      _E4.pad,
      math.max(0.0, (islandW - tabsPerSide * UiSize.tap) / 2),
    );
    final slot = (islandW - 2 * pad) / tabsPerSide;
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

    final totalTabs = 2 * tabsPerSide;
    List<double>? resolvedTargets = targetSlotWidths;
    List<double>? resolvedWeights = slotWeights;
    if (activeTabIndex != null && activeTabIndex >= 0) {
      final mask = longTabMask ?? const <bool>[true, false, true, false];
      final longTarget = math.max(slot, activeLongSlotTargetAt(width));
      resolvedTargets ??= <double>[
        for (var i = 0; i < totalTabs; i++)
          (i < mask.length && mask[i]) ? longTarget : slot,
      ];
      resolvedWeights ??= <double>[
        for (var i = 0; i < totalTabs; i++) i == activeTabIndex ? 1.0 : 0.0,
      ];
    }

    final flexFactor = 1.0 - compactT.clamp(0.0, 1.0);
    final slotWidths = List<double>.filled(totalTabs, slot);
    if (tabsPerSide == 2 &&
        resolvedTargets != null &&
        resolvedTargets.length == 4 &&
        resolvedWeights != null &&
        resolvedWeights.length == 4 &&
        flexFactor > 0) {
      final innerW = 2 * slot;
      final maxActiveSlot = math.max(slot, innerW - UiSize.tap);
      for (var side = 0; side < 2; side++) {
        final a = 2 * side;
        final b = a + 1;
        final wA = resolvedWeights[a].clamp(0.0, 1.0);
        final wB = resolvedWeights[b].clamp(0.0, 1.0);
        final targetA = lerpDouble(
          slot,
          resolvedTargets[a].clamp(slot, maxActiveSlot),
          flexFactor,
        )!;
        final targetB = lerpDouble(
          slot,
          resolvedTargets[b].clamp(slot, maxActiveSlot),
          flexFactor,
        )!;
        final delta = wA * (targetA - slot) - wB * (targetB - slot);
        slotWidths[a] = slot + delta;
        slotWidths[b] = slot - delta;
      }
    }

    final tabSlots = <Rect>[];
    var leftCursor = x0 + pad;
    for (var i = 0; i < tabsPerSide; i++) {
      final w = slotWidths[i];
      tabSlots.add(Rect.fromLTWH(leftCursor, islandTop, w, islandH));
      leftCursor += w;
    }
    var rightCursor = rightX0 + pad;
    for (var i = 0; i < tabsPerSide; i++) {
      final w = slotWidths[tabsPerSide + i];
      tabSlots.add(Rect.fromLTWH(rightCursor, islandTop, w, islandH));
      rightCursor += w;
    }
    final tabCentersX = <double>[for (final r in tabSlots) r.center.dx];
    final allCentersX = <double>[
      for (var i = 0; i < tabsPerSide; i++) tabCentersX[i],
      width / 2,
      for (var i = tabsPerSide; i < 2 * tabsPerSide; i++) tabCentersX[i],
    ];
    final capW = slot - _E4.capsuleSlotInset;

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

  /// Expanded selection capsule width for [tabIndex] (`tabSlots[tabIndex].width - 2`).
  double capsuleWidthForTab(int tabIndex) =>
      tabSlots[tabIndex].width - _E4.capsuleSlotInset;

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
    expandedWidth: expandedWidth ?? capsuleWidthForTab(tabIndex),
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
  /// Ignored at rest when [camera] is true; if [camera] flips from false to
  /// true while compact, the 220ms camera morph starts from the 52dp compact
  /// geometry.
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
    final activeItemIndex = items.indexWhere((e) => e.active);
    final tabsPerSide = math.max(
      1,
      math.max(leftItems.length, rightItems.length),
    );
    final activeSlotIndex = activeItemIndex < 0
        ? -1
        : (activeItemIndex < leftItems.length
              ? activeItemIndex
              : tabsPerSide + (activeItemIndex - leftItems.length));
    final bottomGap = math.max(bottom, _E4.minBottomInset) + _E4.bottomExtra;
    final pillFill = accent ?? ui.accent;
    final fgOnAccent = onAccent ?? ui.onBrand;
    final shellShadowOffset = useLiquid
        ? 0.0
        : (quiet ? UiShadow.tiny : UiShadow.large);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : media.size.width;
        final baseFontSize = dockBaseLabelSize(width);
        final shownBaseGeo = UiDockGeometry.compute(
          width: width,
          cam: _E4.camD,
          islandH: _E4.islandH,
          tabsPerSide: tabsPerSide,
        );
        final labelMaxW = shownBaseGeo.labelMaxWidth;
        final labels = [for (final e in items) e.label];
        final labelFit = dockLabelFit(
          context,
          labels,
          labelMaxW,
          baseFontSize: baseFontSize,
        );
        final renderedFontSize = baseFontSize * labelFit;
        final textScale = MediaQuery.textScalerOf(context)
            .clamp(maxScaleFactor: dockLabelMaxScale)
            .scale(1);
        final lineH = renderedFontSize * dockLabelHeightRatio * textScale;
        final capH = math.max(
          _E4.capH,
          _E4.glyph + _E4.labelGap + lineH + _E4.capsuleVertPad,
        );
        final baseIslandH = math.max(_E4.islandH, capH + _E4.islandOverCapsule);

        final slotLabels = <String?>[
          for (var i = 0; i < tabsPerSide; i++)
            i < leftItems.length ? leftItems[i].label : null,
          for (var i = 0; i < tabsPerSide; i++)
            i < rightItems.length ? rightItems[i].label : null,
        ];
        final slotLabelWidths = <double>[
          for (final label in slotLabels)
            label == null
                ? 0.0
                : dockMeasureLabelWidth(
                    context,
                    label,
                    fontSize: renderedFontSize,
                  ),
        ];
        final widestLabelW = slotLabelWidths.fold<double>(0.0, math.max);
        final maxActiveSlotCap = UiDockGeometry.activeLongSlotTargetAt(width);
        final neededFlexSlotW = math.min(
          maxActiveSlotCap,
          (widestLabelW + _E4.capsuleDescenderClearanceMargin).roundToDouble() +
              _E4.capsuleSlotInset,
        );
        final targetSlotWidths = <double>[
          for (final lw in slotLabelWidths)
            (lw + _E4.capsuleDescenderClearanceMargin >
                    shownBaseGeo.capsuleWidth)
                ? math.max(shownBaseGeo.slotWidth, neededFlexSlotW)
                : shownBaseGeo.slotWidth,
        ];

        final effectiveCompact = !camera && compact;
        final targetT = effectiveCompact ? 1.0 : 0.0;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: targetT),
          duration: camera
              ? Duration.zero
              : UiMotion.of(context, UiMotion.medium),
          curve: UiCurves.easeOutStrong,
          builder: (context, compactT, _) {
            final liveCompactT = camera
                ? 0.0
                : (UiMotion.reduced(context)
                      ? targetT
                      : compactT.clamp(0.0, 1.0));
            final shellCam = lerpDouble(
              _E4.camD,
              _E4.camDCompact,
              liveCompactT,
            )!;
            final shellCamIcon = lerpDouble(
              _E4.camIcon,
              _E4.camIconCompact,
              liveCompactT,
            )!;

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

            return _UiDockCenterMorph(
              camera: camera,
              fromCompactT: liveCompactT,
              accent: pillFill,
              onAccent: fgOnAccent,
              outlineColor: outline,
              outlineWidth: stroke,
              shellShadowOffset: shellShadowOffset,
              shadowColor: shadowColor,
              child: centerSlot,
              builder: (context, cameraT, shellCompactT, morphingCenter) {
                final effShellCam = lerpDouble(
                  _E4.camD,
                  _E4.camDCompact,
                  shellCompactT,
                )!;
                final effShellIslandH = lerpDouble(
                  baseIslandH,
                  _E4.islandHCompact,
                  shellCompactT,
                )!;
                final effCompactT = lerpDouble(shellCompactT, 0.0, cameraT)!;
                final currentCam = lerpDouble(
                  effShellCam,
                  _E4.camDRoute,
                  cameraT,
                )!;
                final currentIslandH = lerpDouble(
                  effShellIslandH,
                  _E4.islandH,
                  cameraT,
                )!;
                final currentBaseIslandH = lerpDouble(
                  baseIslandH,
                  _E4.islandH,
                  cameraT,
                )!;
                final currentBandH = lerpDouble(
                  baseIslandH,
                  _E4.camDRoute,
                  cameraT,
                )!;
                final effectiveFlexCompactT =
                    1.0 - (1.0 - effCompactT) * (1.0 - cameraT);
                final islandRadius = UiDockGeometry.islandRadiusAt(effCompactT);
                final pillRadius = UiDockGeometry.pillRadiusAt(effCompactT);

                return _DockSelectionSlide(
                  activeIndex: activeSlotIndex,
                  slotCount: 2 * tabsPerSide,
                  compactT: effCompactT,
                  builder: (context, slotWeights, selectionRectBuilder) {
                    final geo = UiDockGeometry.compute(
                      width: width,
                      cam: currentCam,
                      islandH: currentIslandH,
                      topPad: _E4.topPad,
                      bandH: currentBandH,
                      bottomGap: bottomGap,
                      baseIslandH: currentBaseIslandH,
                      capH: capH,
                      tabsPerSide: tabsPerSide,
                      targetSlotWidths: targetSlotWidths,
                      slotWeights: camera ? null : slotWeights,
                      compactT: effectiveFlexCompactT,
                    );
                    final maxActiveSlot = math.max(
                      geo.slotWidth,
                      2 * geo.slotWidth - UiSize.tap,
                    );
                    final settledCapsuleWidths = <double>[
                      for (var i = 0; i < targetSlotWidths.length; i++)
                        lerpDouble(
                              geo.slotWidth,
                              targetSlotWidths[i].clamp(
                                geo.slotWidth,
                                maxActiveSlot,
                              ),
                              1.0 - effectiveFlexCompactT.clamp(0.0, 1.0),
                            )! -
                            _E4.capsuleSlotInset,
                    ];
                    final pillRect = (!camera && activeSlotIndex >= 0)
                        ? selectionRectBuilder(geo, settledCapsuleWidths)
                        : null;
                    final centerBoxSize = math.max(
                      geo.cameraRect.width,
                      _E4.camDRoute,
                    );

                    return SizedBox(
                      width: width,
                      height: geo.dockHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _DockIsland(
                            rect: geo.leftIsland,
                            borderRadius: islandRadius,
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
                            borderRadius: islandRadius,
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
                          if (pillRect != null)
                            _DockSelection(
                              rect: pillRect,
                              borderRadius: pillRadius,
                              accent: pillFill,
                              surface: ui.surface,
                              outline: outline,
                              shadow: shadowColor,
                              useLiquid: useLiquid,
                              dark: dark,
                            ),
                          for (var i = 0; i < leftItems.length; i++)
                            Positioned.fromRect(
                              rect: geo.tabSlots[i],
                              child: DockTab(
                                item: leftItems[i],
                                camera: camera,
                                onAccent: onAccent,
                                baseFontSize: baseFontSize,
                                labelFit: labelFit,
                                labelMaxWidth: labelMaxW,
                                lift: 0,
                                labelGap: _E4.labelGap,
                                compactT: effCompactT,
                              ),
                            ),
                          for (var i = 0; i < rightItems.length; i++)
                            Positioned.fromRect(
                              rect: geo.tabSlots[tabsPerSide + i],
                              child: DockTab(
                                item: rightItems[i],
                                camera: camera,
                                onAccent: onAccent,
                                baseFontSize: baseFontSize,
                                labelFit: labelFit,
                                labelMaxWidth: labelMaxW,
                                lift: 0,
                                labelGap: _E4.labelGap,
                                compactT: effCompactT,
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
          },
        );
      },
    );
  }
}

class _DockIsland extends StatelessWidget {
  const _DockIsland({
    required this.rect,
    required this.borderRadius,
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
  final double borderRadius;
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
    final radius = BorderRadius.circular(borderRadius);
    final Widget island = useLiquid
        ? GlassContainer(
            useOwnLayer: true,
            shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
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
    required this.borderRadius,
    required this.accent,
    required this.surface,
    required this.outline,
    required this.shadow,
    required this.useLiquid,
    required this.dark,
  });

  final Rect rect;
  final double borderRadius;
  final Color accent;
  final Color surface;
  final Color outline;
  final Color shadow;
  final bool useLiquid;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: DecoratedBox(
          key: const ValueKey('dock-selection-pill'),
          decoration: useLiquid
              ? _lensDecoration(accent, dark).copyWith(borderRadius: radius)
              : dockSelectionDecoration(
                  accent: accent,
                  surface: surface,
                  outline: outline,
                  shadow: shadow,
                  borderRadius: radius,
                ),
        ),
      ),
    );
  }
}

class _DockSelectionSlide extends StatefulWidget {
  const _DockSelectionSlide({
    required this.activeIndex,
    required this.slotCount,
    required this.compactT,
    required this.builder,
  });

  final int activeIndex;
  final int slotCount;
  final double compactT;
  final Widget Function(
    BuildContext context,
    List<double> slotWeights,
    Rect Function(UiDockGeometry geo, List<double> settledCapsuleWidths)
    selectionRectBuilder,
  )
  builder;

  @override
  State<_DockSelectionSlide> createState() => _DockSelectionSlideState();
}

class _DockSelectionSlideState extends State<_DockSelectionSlide>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  CurvedAnimation? _curved;
  List<double> _fromWeights = const [];
  int _toSlot = 0;

  List<double> _unitWeights(int slot, int count) {
    if (count <= 0) return const [];
    if (slot < 0) return List<double>.filled(count, 0.0);
    final clamped = slot.clamp(0, count - 1);
    return List<double>.generate(count, (i) => i == clamped ? 1.0 : 0.0);
  }

  double _slotX(UiDockGeometry g, int slot) {
    final centres = g.tabCentersX;
    if (centres.isEmpty) return g.width / 2;
    return centres[slot.clamp(0, centres.length - 1)];
  }

  double _startX(UiDockGeometry g) {
    final centres = g.tabCentersX;
    if (centres.isEmpty) return g.width / 2;
    if (_fromWeights.length != centres.length) {
      return _slotX(g, _toSlot);
    }
    var sum = 0.0;
    for (var i = 0; i < centres.length; i++) {
      sum += _fromWeights[i] * centres[i];
    }
    return sum;
  }

  double _endX(UiDockGeometry g) => _slotX(g, _toSlot);

  List<double> _currentWeights(int count) {
    final curved = _curved;
    final target = _unitWeights(_toSlot, count);
    if (curved == null ||
        !(_ctrl?.isAnimating ?? false) ||
        _fromWeights.length != count) {
      return target;
    }
    final s = curved.value;
    return List<double>.generate(
      count,
      (i) => lerpDouble(_fromWeights[i], target[i], s)!,
    );
  }

  List<double> _clampedSlotWeights(int count) {
    final curved = _curved;
    final target = _unitWeights(_toSlot, count);
    if (curved == null ||
        !(_ctrl?.isAnimating ?? false) ||
        _fromWeights.length != count) {
      return target;
    }
    final s = curved.value.clamp(0.0, 1.0);
    return List<double>.generate(
      count,
      (i) => lerpDouble(_fromWeights[i].clamp(0.0, 1.0), target[i], s)!,
    );
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
    _toSlot = widget.activeIndex;
    _fromWeights = _unitWeights(_toSlot, widget.slotCount);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UiMotion.reduced(context) && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.stop();
      _toSlot = widget.activeIndex;
      _fromWeights = _unitWeights(_toSlot, widget.slotCount);
    }
  }

  @override
  void didUpdateWidget(covariant _DockSelectionSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = widget.slotCount;
    if (widget.activeIndex != oldWidget.activeIndex) {
      if (UiMotion.reduced(context) ||
          widget.activeIndex < 0 ||
          oldWidget.activeIndex < 0) {
        _ctrl?.stop();
        _toSlot = widget.activeIndex;
        _fromWeights = _unitWeights(_toSlot, count);
        return;
      }
      _fromWeights = (_ctrl?.isAnimating ?? false)
          ? _currentWeights(count)
          : _unitWeights(oldWidget.activeIndex, count);
      _toSlot = widget.activeIndex;
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
    final count = widget.slotCount;
    if (UiMotion.reduced(context) ||
        ctrl == null ||
        curved == null ||
        !ctrl.isAnimating) {
      final weights = _unitWeights(widget.activeIndex, count);
      return widget.builder(
        context,
        weights,
        (g, _) => g.selectionRectForTab(
          widget.activeIndex.clamp(0, count - 1),
          compactT: widget.compactT,
        ),
      );
    }

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final weights = _clampedSlotWeights(count);
        return widget.builder(context, weights, (g, settledCapsuleWidths) {
          final cx = lerpDouble(_startX(g), _endX(g), curved.value)!;
          var expandedW = 0.0;
          var weightSum = 0.0;
          for (
            var i = 0;
            i < weights.length && i < settledCapsuleWidths.length;
            i++
          ) {
            expandedW += weights[i] * settledCapsuleWidths[i];
            weightSum += weights[i];
          }
          final resolvedExpandedW = weightSum > 0
              ? expandedW / weightSum
              : g.capsuleWidth;
          return g.selectionRectAt(
            cx,
            widget.compactT,
            expandedWidth: resolvedExpandedW,
          );
        });
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

/// Legacy `.camera-capsule`: 56x40 quick-snap pill in the brand (or [accent])
/// fill with a sticker outline and hard shadow. Retained for standalone kit
/// compatibility (`UiDock` draws its own 60dp/52dp camera circle since E4).
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

/// Animates the center dock trigger between the `60×60` (or `52×52` compact)
/// E4 camera circle and the `76×76` [UiShutter] over [UiMotion.medium]
/// (`220ms`, [UiCurves.easeOutStrong]) while exposing `cameraT` to the dock
/// layout so the two islands and four tabs glide smoothly.
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
    required this.fromCompactT,
    required this.accent,
    required this.onAccent,
    required this.outlineColor,
    required this.outlineWidth,
    required this.shellShadowOffset,
    required this.shadowColor,
    required this.child,
    required this.builder,
  });

  final bool camera;
  final double fromCompactT;
  final Color accent;
  final Color onAccent;
  final Color outlineColor;
  final double outlineWidth;
  final double shellShadowOffset;
  final Color shadowColor;
  final Widget child;
  final Widget Function(
    BuildContext context,
    double cameraT,
    double shellCompactT,
    Widget center,
  )
  builder;

  @override
  State<_UiDockCenterMorph> createState() => _UiDockCenterMorphState();
}

class _UiDockCenterMorphState extends State<_UiDockCenterMorph>
    with SingleTickerProviderStateMixin {
  static _UiDockCenterMorphState? _activeShellOwner;
  static (bool fromCamera, double shellCompactT)? _pendingHandoff;
  static bool _handoffClearScheduled = false;

  static void _recordHandoff(bool fromCamera, double shellCompactT) {
    _pendingHandoff = (fromCamera, shellCompactT);
    if (!_handoffClearScheduled) {
      _handoffClearScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pendingHandoff = null;
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
  late double _shellCompactT = widget.fromCompactT;

  double get _ownCompactT => widget.fromCompactT;

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
    ctrl = AnimationController(vsync: this, duration: UiMotion.medium);
    _ctrl = ctrl;
    _curved = CurvedAnimation(parent: ctrl, curve: UiCurves.easeOutStrong);
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
      final handoff = _pendingHandoff;
      if (tickerEnabled && handoff != null && handoff.$1 != widget.camera) {
        _pendingHandoff = null;
        if (widget.camera) {
          _shellCompactT = handoff.$2;
        }
        _startMorph(from: handoff.$1 ? 1.0 : 0.0, to: target);
      } else {
        if (widget.camera && _activeShellOwner != null) {
          _shellCompactT = _activeShellOwner!._ownCompactT;
        }
        _fromT = target;
        _toT = target;
      }
      if (!widget.camera && tickerEnabled) {
        _activeShellOwner = this;
      }
      return;
    }

    if (reduced && (_ctrl?.isAnimating ?? false)) {
      _ctrl?.stop();
      _fromT = target;
      _toT = target;
    } else if (!_lastTickerEnabled && tickerEnabled) {
      final handoffCompactT =
          _pendingHandoff?.$2 ?? _activeShellOwner?._ownCompactT;
      if (widget.camera && handoffCompactT != null) {
        _shellCompactT = handoffCompactT;
      }
      if (!widget.camera) {
        _activeShellOwner = this;
      }
      _pendingHandoff = null;
      _startMorph(from: widget.camera ? 0.0 : 1.0, to: target);
    } else if (_lastTickerEnabled && !tickerEnabled) {
      _recordHandoff(
        widget.camera,
        widget.camera ? _shellCompactT : widget.fromCompactT,
      );
      if (identical(_activeShellOwner, this)) {
        _activeShellOwner = null;
      }
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
      _shellCompactT = widget.camera
          ? oldWidget.fromCompactT
          : widget.fromCompactT;
      if (!widget.camera && _lastTickerEnabled) {
        _activeShellOwner = this;
      } else if (widget.camera && identical(_activeShellOwner, this)) {
        _activeShellOwner = null;
      }
      final target = widget.camera ? 1.0 : 0.0;
      _startMorph(from: _currentT, to: target);
    } else if (!widget.camera) {
      _shellCompactT = widget.fromCompactT;
      if (_lastTickerEnabled) {
        _activeShellOwner = this;
      }
    }
  }

  @override
  void deactivate() {
    if (_lastTickerEnabled) {
      _recordHandoff(
        widget.camera,
        widget.camera ? _shellCompactT : widget.fromCompactT,
      );
    }
    if (identical(_activeShellOwner, this)) {
      _activeShellOwner = null;
    }
    _ctrl?.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    if (identical(_activeShellOwner, this)) {
      _activeShellOwner = null;
    }
    _curved?.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    final curved = _curved;
    final settledT = widget.camera ? 1.0 : 0.0;
    final effShellCompactT = widget.camera
        ? _shellCompactT
        : widget.fromCompactT;

    if (UiMotion.reduced(context) ||
        ctrl == null ||
        curved == null ||
        (!ctrl.isAnimating && (_fromT - _toT).abs() < 0.001)) {
      return widget.builder(context, settledT, effShellCompactT, widget.child);
    }

    final ui = context.ui;
    final fromDiameter = lerpDouble(
      _E4.camD,
      _E4.camDCompact,
      effShellCompactT,
    )!;
    final fromIconSize = lerpDouble(
      _E4.camIcon,
      _E4.camIconCompact,
      effShellCompactT,
    )!;

    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, settledChild) {
        final t = lerpDouble(_fromT, _toT, curved.value)!;
        if (!ctrl.isAnimating || (t - _toT).abs() < 0.001) {
          return widget.builder(
            context,
            settledT,
            effShellCompactT,
            settledChild!,
          );
        }
        final diameter = lerpDouble(fromDiameter, _E4.camDRoute, t)!;
        final radius = BorderRadius.circular(diameter / 2);
        final iconSize = lerpDouble(fromIconSize, _E4.camIconRoute, t)!;
        final outline = Color.lerp(ui.outline, UiCamera.outline, t)!;
        final shadowColor = Color.lerp(ui.hardShadowColor, UiCamera.shadow, t)!;
        final shadowOff = lerpDouble(
          widget.shellShadowOffset,
          UiShadow.small,
          t,
        )!;

        final morphCenter = SizedBox(
          key: const ValueKey('dock-center-morph'),
          width: diameter,
          height: diameter,
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
        return widget.builder(context, t, effShellCompactT, morphCenter);
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
