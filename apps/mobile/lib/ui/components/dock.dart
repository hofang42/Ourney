import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'pressable.dart';

/// One side tab of the [UiDock].
class UiDockItem {
  const UiDockItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;
}

/// `.dock`: the shared 3-tab bar. Left tab, center quick-snap pill
/// (56x40, filled with [accent]) and right tab, on a blurred paper bar with
/// a hairline on top. Set [camera] for `.camera-dock` (dark bar, white
/// glyphs) and pass a [UiShutter] as [center].
class UiDock extends StatelessWidget {
  const UiDock({
    required this.left,
    required this.right,
    required this.snapLabel,
    required this.onSnap,
    this.accent,
    this.onAccent,
    this.center,
    this.camera = false,
    super.key,
  });

  final UiDockItem left;
  final UiDockItem right;
  final String snapLabel;
  final VoidCallback onSnap;
  final Color? accent;
  final Color? onAccent;

  /// Replaces the snap pill (the camera screen's big shutter).
  final Widget? center;
  final bool camera;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final bg = camera ? UiCamera.dock : ui.dockBg;
    final line = camera ? UiCamera.dockBorder : ui.dockBorder;
    final centerWidth = camera ? 92.0 : UiSize.shutter;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: BoxConstraints(
            minHeight: (camera ? 92 : UiSize.dockMin) + bottom,
          ),
          padding: EdgeInsets.fromLTRB(
            UiSpace.huge + 2,
            UiSpace.sm,
            UiSpace.huge + 2,
            bottom < UiSpace.sm ? UiSpace.sm : bottom,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: Border(top: BorderSide(color: line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Tab(item: left, camera: camera),
              ),
              SizedBox(
                width: centerWidth,
                child:
                    center ??
                    Align(
                      alignment: Alignment.topCenter,
                      child: UiSnapPill(
                        label: snapLabel,
                        onPressed: onSnap,
                        accent: accent,
                        onAccent: onAccent,
                      ),
                    ),
              ),
              Expanded(
                child: _Tab(item: right, camera: camera),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.camera});

  final UiDockItem item;
  final bool camera;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final Color color = camera
        ? UiCamera.ink
        : (item.active ? ui.ink : ui.inkMuted);
    return UiPressable(
      onPressed: item.onPressed,
      selected: item.active,
      semanticLabel: item.label,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(16),
      minSize: const Size(UiSize.tap, 56),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.body(
                size: 11,
                weight: FontWeight.w600,
                height: 1.35,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.camera-capsule`: 56x40 quick-snap pill on Hub / Timeline / Squad.
class UiSnapPill extends StatelessWidget {
  const UiSnapPill({
    required this.label,
    required this.onPressed,
    this.accent,
    this.onAccent,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? accent;
  final Color? onAccent;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      minSize: const Size(UiSize.snapPillW, UiSize.tap),
      centerChild: true,
      child: Container(
        width: UiSize.snapPillW,
        height: UiSize.snapPillH,
        decoration: BoxDecoration(
          color: accent ?? ui.brand,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
        ),
        child: Icon(
          Icons.photo_camera_outlined,
          size: 25,
          color: onAccent ?? ui.onBrand,
        ),
      ),
    );
  }
}

/// `.shutter`: 76dp white ring around a 64dp [accent] disc (Hero Shutter on
/// the camera screen).
class UiShutter extends StatelessWidget {
  const UiShutter({
    required this.label,
    required this.onPressed,
    this.accent,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      minSize: const Size.square(UiSize.shutter),
      child: Container(
        width: UiSize.shutter,
        height: UiSize.shutter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: UiCamera.ink, width: 3),
        ),
        child: Container(
          width: UiSize.shutterInner,
          height: UiSize.shutterInner,
          decoration: BoxDecoration(
            color: accent ?? context.ui.brand,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
