import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'glass.dart';
import 'ourney_icons.dart';
import 'pressable.dart';
import 'skin_scope.dart';

/// V2 selection pill easing (`cubic-bezier(.2,.9,.3,1.2)`, slight overshoot).
const Curve _pillCurve = Cubic(0.2, 0.9, 0.3, 1.2);
const Duration _pillDuration = Duration(milliseconds: 280);
const Duration _longPress = Duration(milliseconds: 400);
const double _pillW = 68;
const double _pillH = 52;
const double _dockH = 64;
const double _cameraDockH = 92;
const double _centerSlot = 86;

/// One tab of the [UiDock]. Give it a drawn [glyph] (an [OurneyIcon] name such
/// as `journeys`, `squad`, `activity`, `profile`) or, for older callers, a
/// Material [icon].
class UiDockItem {
  const UiDockItem({
    this.icon,
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
/// Hội · [Chụp] · Hoạt động · Hồ sơ.
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
    super.key,
  });

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
    final bottom = media.viewPadding.bottom;
    final skinBorder =
        UiSkinScope.maybeOf(context)?.skin.borderWidth ?? UiBorder.standard;
    final quiet = skinBorder < UiBorder.standard;
    final stroke = skinBorder;
    // Camera dock: cream outline + black 2dp hard shadow (`.camera-dock`).
    final shadowOffset = (quiet || camera) ? UiShadow.tiny : UiShadow.large;
    final outline = camera ? UiCamera.outline : ui.outline;
    final shadowColor = camera ? UiCamera.shadow : ui.outline;

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

    final bar = LayoutBuilder(
      builder: (context, c) {
        final slotW = (c.maxWidth - _centerSlot) / items.length;
        final pillW = _pillW < slotW ? _pillW : slotW;
        double slotX(int i) => i < leftItems.length
            ? i * slotW
            : leftItems.length * slotW +
                  _centerSlot +
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
                top: (c.maxHeight - _pillH) / 2,
                width: pillW,
                height: _pillH,
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey('dock-selection-pill'),
                    decoration: BoxDecoration(
                      color: pillFill,
                      borderRadius: BorderRadius.circular(UiRadius.menu),
                      border: Border.all(color: outline, width: UiBorder.thin),
                      boxShadow: UiShadow.hard(shadowColor, UiShadow.tiny),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                for (final item in leftItems)
                  Expanded(
                    child: _Tab(item: item, camera: camera, onAccent: onAccent),
                  ),
                SizedBox(
                  width: _centerSlot,
                  child: Center(child: centerSlot),
                ),
                for (final item in rightItems)
                  Expanded(
                    child: _Tab(item: item, camera: camera, onAccent: onAccent),
                  ),
              ],
            ),
          ],
        );
      },
    );

    // Fixed height: the Center in the shutter slot would otherwise expand to
    // the full available height (the dock filled the whole screen).
    final surface = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: UiSpace.xs, vertical: 6),
      // Camera: the dark dock tint lives here so glass stays neutral.
      decoration: camera ? const BoxDecoration(color: UiCamera.dock) : null,
      child: bar,
    );

    final glass = UiGlass(
      borderRadius: radius,
      blur: 20,
      saturation: 1.6,
      tint: camera ? Colors.transparent : ui.surface.withValues(alpha: 0.82),
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
        UiSpace.sm + shadowOffset,
        (bottom < UiSpace.sm ? UiSpace.sm : bottom) + shadowOffset,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 358 + 16),
          // UiGlass draws the outside-only hard shadow itself.
          child: glass,
        ),
      ),
    );
  }
}

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

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.camera, this.onAccent});

  final UiDockItem item;
  final bool camera;

  /// Journey accent's foreground for the active tab (falls back to onBrand).
  final Color? onAccent;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final active = item.active;
    // Active tabs sit on the brand pill: solid dark ink glyph and label.
    final Color color = active
        ? (onAccent ?? ui.onBrand)
        : (camera ? UiCamera.ink : ui.ink);
    final Widget glyph = item.glyph != null
        ? OurneyIcon(
            name: item.glyph!,
            size: 22,
            color: active ? color : null,
            inkColor: active ? color : (camera ? UiCamera.ink : null),
          )
        : Icon(item.icon, size: 22, color: color);
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
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
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

  /// Hard shadow color; defaults to [outlineColor].
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
      shadowColor: shadowColor ?? line,
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
    super.key,
  });

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
    final shadow = outlineColor ?? UiCamera.shadow;
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
          border: Border.all(color: line, width: width + 0.5),
        ),
        child: Center(
          child: OurneyIcon(name: 'camera', size: 30, color: fg, inkColor: fg),
        ),
      ),
    );
    if (onLongPress != null) {
      shutter = _LongPress(onLongPress: onLongPress!, child: shutter);
    }
    return shutter;
  }
}
