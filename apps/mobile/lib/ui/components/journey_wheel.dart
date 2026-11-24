import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui_;

import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';
import 'glass.dart';
import 'journey_widgets.dart';
import 'ourney_icons.dart';
import 'pressable.dart';

const double _badge = 52;
const double _cellW = 72;
const double _cellH = _badge + 4 + 26;
const double _edge = 8;
const double _firstRadius = 108;
const double _ringGap = 88;
const Duration _inDuration = Duration(milliseconds: 240);
const Duration _outDuration = Duration(milliseconds: 170);

/// One journey on the [showUiJourneyWheel] wheel.
class UiJourneyWheelItem {
  const UiJourneyWheelItem({
    required this.id,
    required this.label,
    this.type = 'custom',
    this.accent,
  });

  final String id;

  /// Journey title (spoken and shown under the badge).
  final String label;

  /// [UiTypeBadge] type id.
  final String type;

  /// Journey accent; rings the badge when it is the active one.
  final Color? accent;
}

/// Opens the V2 journey wheel: a blurred, dimmed backdrop with one
/// [UiTypeBadge] per journey fanned in an arc above [anchor] (the center of
/// the dock's snap button). Tap a badge to call [onSelect] and close; tap the
/// backdrop, the center close button or press back to dismiss. It never
/// navigates, so the camera underneath keeps running.
///
/// Opens on the root navigator, so it floats over the shell and the camera.
/// Bidirectional transition (`240ms` fan-out / `170ms` fan-in), honoring
/// Reduce Motion (`150ms` opacity-only fade with zero arc translation) and
/// [reduceTransparency] / high contrast (solid scrim, no blur).
Future<void> showUiJourneyWheel(
  BuildContext context, {
  required List<UiJourneyWheelItem> items,
  required String? activeId,
  required ValueChanged<String> onSelect,
  required Offset anchor,
  bool reduceTransparency = false,
  String semanticLabel = 'Chọn hành trình',
  String closeLabel = 'Đóng',
  String activeHint = 'đang chọn',
}) {
  final enterDuration = UiMotion.fadeOf(context, _inDuration);
  final exitDuration = UiMotion.fadeOf(context, _outDuration);
  return Navigator.of(context, rootNavigator: true).push<void>(
    _UiJourneyWheelRoute(
      enterDuration: enterDuration,
      exitDuration: exitDuration,
      barrierLabel: closeLabel,
      pageBuilder: (ctx, animation, _) => UiJourneyWheel(
        items: items,
        activeId: activeId,
        anchor: anchor,
        routeAnimation: animation,
        reduceTransparency: reduceTransparency,
        semanticLabel: semanticLabel,
        closeLabel: closeLabel,
        activeHint: activeHint,
        onDismiss: () => Navigator.of(ctx, rootNavigator: true).pop(),
        onSelect: (id) {
          Navigator.of(ctx, rootNavigator: true).pop();
          onSelect(id);
        },
      ),
    ),
  );
}

class _UiJourneyWheelRoute extends PopupRoute<void> {
  _UiJourneyWheelRoute({
    required this.enterDuration,
    required this.exitDuration,
    required this.barrierLabel,
    required this.pageBuilder,
  });

  final Duration enterDuration;
  final Duration exitDuration;
  final RoutePageBuilder pageBuilder;

  @override
  Duration get transitionDuration => enterDuration;

  @override
  Duration get reverseTransitionDuration => exitDuration;

  @override
  bool get barrierDismissible => true;

  @override
  final String? barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return pageBuilder(context, animation, secondaryAnimation);
  }
}

/// The wheel surface itself (use [showUiJourneyWheel] in the app).
class UiJourneyWheel extends StatefulWidget {
  const UiJourneyWheel({
    required this.items,
    required this.activeId,
    required this.anchor,
    required this.onSelect,
    required this.onDismiss,
    this.routeAnimation,
    this.reduceTransparency = false,
    this.semanticLabel = 'Chọn hành trình',
    this.closeLabel = 'Đóng',
    this.activeHint = 'đang chọn',
    super.key,
  });

  final List<UiJourneyWheelItem> items;
  final String? activeId;

  /// Global center of the snap button the wheel fans out from.
  final Offset anchor;
  final ValueChanged<String> onSelect;
  final VoidCallback onDismiss;
  final Animation<double>? routeAnimation;
  final bool reduceTransparency;
  final String semanticLabel;
  final String closeLabel;
  final String activeHint;

  /// Centers of the [count] badges: rings of 5, 7, 9... fanned over at most
  /// 160 degrees above [anchor], clamped inside [size] (left to right in item
  /// order within a ring).
  @visibleForTesting
  static List<Offset> layout(
    int count,
    Offset anchor,
    Size size, {
    double topInset = 0,
  }) {
    final out = <Offset>[];
    var ring = 0;
    var left = count;
    while (left > 0) {
      final cap = 5 + ring * 2;
      final m = math.min(cap, left);
      final radius = _firstRadius + ring * _ringGap;
      final span = math.min(160.0, (m - 1) * 40.0) * math.pi / 180;
      for (var i = 0; i < m; i++) {
        final a = m == 1
            ? -math.pi / 2
            : -math.pi / 2 - span / 2 + span * i / (m - 1);
        final p = anchor + Offset(math.cos(a), math.sin(a)) * radius;
        final minX = _cellW / 2 + _edge;
        final maxX = math.max(minX, size.width - _cellW / 2 - _edge);
        final minY = topInset + _badge / 2 + _edge;
        out.add(
          Offset(p.dx.clamp(minX, maxX).toDouble(), math.max(minY, p.dy)),
        );
      }
      left -= m;
      ring++;
    }
    return out;
  }

  @override
  State<UiJourneyWheel> createState() => _UiJourneyWheelState();
}

class _UiJourneyWheelState extends State<UiJourneyWheel>
    with SingleTickerProviderStateMixin {
  AnimationController? _fallbackCtrl;
  CurvedAnimation? _fadeCurved;
  CurvedAnimation? _arcCurved;
  Animation<double>? _boundParent;
  bool _started = false;
  int? _dragHoveredIndex;

  Animation<double> get _anim => widget.routeAnimation ?? _ensureFallback();

  AnimationController _ensureFallback() {
    return _fallbackCtrl ??= AnimationController(
      vsync: this,
      duration: _inDuration,
      reverseDuration: _outDuration,
    );
  }

  void _syncCurvedAnimations() {
    final parent = _anim;
    if (identical(parent, _boundParent) &&
        _fadeCurved != null &&
        _arcCurved != null) {
      return;
    }
    _fadeCurved?.dispose();
    _arcCurved?.dispose();
    _boundParent = parent;
    _fadeCurved = CurvedAnimation(
      parent: parent,
      curve: UiCurves.easeOutStrong,
      reverseCurve: UiCurves.easeOutStrong.flipped,
    );
    _arcCurved = CurvedAnimation(
      parent: parent,
      curve: UiCurves.dockOvershoot,
      reverseCurve: UiCurves.easeOutStrong.flipped,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (widget.routeAnimation == null) {
        final ctrl = _ensureFallback();
        ctrl.duration = UiMotion.fadeOf(context, _inDuration);
        ctrl.reverseDuration = UiMotion.fadeOf(context, _outDuration);
        ctrl.forward();
      }
    }
    _syncCurvedAnimations();
  }

  @override
  void didUpdateWidget(covariant UiJourneyWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeAnimation != widget.routeAnimation) {
      _syncCurvedAnimations();
    }
  }

  @override
  void dispose() {
    _fadeCurved?.dispose();
    _arcCurved?.dispose();
    _fallbackCtrl?.dispose();
    super.dispose();
  }

  int? _hitIndex(Offset localPos, List<Offset> centers) {
    for (var i = 0; i < centers.length; i++) {
      final c = centers[i];
      final rect = Rect.fromLTWH(
        c.dx - _cellW / 2,
        c.dy - _badge / 2,
        _cellW,
        _cellH,
      );
      if (rect.contains(localPos)) {
        return i;
      }
    }
    return null;
  }

  void _handlePointerMove(Offset localPos, List<Offset> centers) {
    final hit = _hitIndex(localPos, centers);
    if (hit != null && hit != _dragHoveredIndex) {
      _dragHoveredIndex = hit;
      unawaited(UiHaptics.selection());
    } else if (hit == null) {
      _dragHoveredIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final media = MediaQuery.of(context);
    final size = media.size;
    final reduced = UiMotion.reduced(context);
    final solid = widget.reduceTransparency || media.highContrast;
    final centers = UiJourneyWheel.layout(
      widget.items.length,
      widget.anchor,
      size,
      topInset: media.padding.top,
    );
    _syncCurvedAnimations();
    final anim = _anim;
    final fadeAnim = reduced ? anim : _fadeCurved!;
    final arcAnim = _arcCurved!;
    final scrim = solid
        ? ui.bg.withValues(alpha: 0.94)
        : Colors.black.withValues(alpha: 0.5);
    Widget backdrop = ColoredBox(color: scrim, child: const SizedBox.expand());
    if (!solid) {
      backdrop = BackdropFilter(
        filter: ui_.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: backdrop,
      );
    }
    backdrop = FadeTransition(opacity: fadeAnim, child: backdrop);

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: widget.semanticLabel,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) =>
              _dragHoveredIndex = _hitIndex(e.localPosition, centers),
          onPointerMove: (e) => _handlePointerMove(e.localPosition, centers),
          onPointerUp: (_) => _dragHoveredIndex = null,
          onPointerCancel: (_) => _dragHoveredIndex = null,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: GestureDetector(
                    key: const ValueKey('journey-wheel-backdrop'),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onDismiss,
                    child: backdrop,
                  ),
                ),
              ),
              for (var i = 0; i < widget.items.length; i++)
                if (reduced)
                  Positioned(
                    left: centers[i].dx - _cellW / 2,
                    top: centers[i].dy - _badge / 2,
                    width: _cellW,
                    child: FadeTransition(
                      opacity: fadeAnim,
                      child: _LiftOnPress(
                        child: _WheelItem(
                          key: ValueKey('journey-wheel-${widget.items[i].id}'),
                          item: widget.items[i],
                          active: widget.items[i].id == widget.activeId,
                          activeHint: widget.activeHint,
                          onTap: () => widget.onSelect(widget.items[i].id),
                        ),
                      ),
                    ),
                  )
                else
                  AnimatedBuilder(
                    animation: arcAnim,
                    child: FadeTransition(
                      opacity: fadeAnim,
                      child: _LiftOnPress(
                        child: _WheelItem(
                          key: ValueKey('journey-wheel-${widget.items[i].id}'),
                          item: widget.items[i],
                          active: widget.items[i].id == widget.activeId,
                          activeHint: widget.activeHint,
                          onTap: () => widget.onSelect(widget.items[i].id),
                        ),
                      ),
                    ),
                    builder: (context, child) {
                      final p = Offset.lerp(
                        widget.anchor,
                        centers[i],
                        arcAnim.value,
                      )!;
                      return Positioned(
                        left: p.dx - _cellW / 2,
                        top: p.dy - _badge / 2,
                        width: _cellW,
                        child: child!,
                      );
                    },
                  ),
              Positioned(
                left: widget.anchor.dx - UiSize.tap / 2,
                top: widget.anchor.dy - UiSize.tap / 2,
                child: FadeTransition(
                  opacity: fadeAnim,
                  child: UiGlass(
                    borderRadius: BorderRadius.circular(UiRadius.capsule),
                    blur: 16,
                    tint: ui.surface.withValues(alpha: 0.82),
                    fallback: ui.surface,
                    borderColor: ui.outline,
                    hardShadow: UiShadow.tiny,
                    hardShadowColor: ui.hardShadowColor,
                    reduceTransparency: widget.reduceTransparency,
                    child: UiPressable(
                      key: const ValueKey('journey-wheel-close'),
                      onPressed: widget.onDismiss,
                      semanticLabel: widget.closeLabel,
                      excludeChildSemantics: true,
                      minSize: const Size.square(UiSize.tap),
                      child: SizedBox.square(
                        dimension: UiSize.tap,
                        child: Center(
                          child: OurneyIcon(
                            name: 'close',
                            size: 22,
                            color: ui.ink,
                            inkColor: ui.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pressing the child lifts it (the "lift" of lift-then-tap); the selection
/// still fires on the tap release, so a cancelled press selects nothing.
class _LiftOnPress extends StatefulWidget {
  const _LiftOnPress({required this.child});

  final Widget child;

  @override
  State<_LiftOnPress> createState() => _LiftOnPressState();
}

class _LiftOnPressState extends State<_LiftOnPress> {
  bool _lifted = false;

  void _lift(bool v) {
    if (_lifted != v) setState(() => _lifted = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      key: const ValueKey('journey-wheel-lift'),
      onPointerDown: (_) => _lift(true),
      onPointerUp: (_) => _lift(false),
      onPointerCancel: (_) => _lift(false),
      child: AnimatedSlide(
        offset: _lifted ? const Offset(0, -0.1) : Offset.zero,
        duration: UiMotion.of(context, UiMotion.press),
        curve: UiCurves.easeOutStrong,
        child: widget.child,
      ),
    );
  }
}

class _WheelItem extends StatelessWidget {
  const _WheelItem({
    required this.item,
    required this.active,
    required this.activeHint,
    required this.onTap,
    super.key,
  });

  final UiJourneyWheelItem item;
  final bool active;
  final String activeHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final ring = item.accent ?? ui.accent;
    return UiPressable(
      onPressed: onTap,
      selected: active,
      semanticLabel: active ? '${item.label}, $activeHint' : item.label,
      excludeChildSemantics: true,
      centerChild: true,
      minSize: const Size(UiSize.tap, UiSize.tap),
      child: SizedBox(
        width: _cellW,
        height: _cellH,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _badge,
              height: _badge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: active ? Border.all(color: ring, width: 4) : null,
                boxShadow: active
                    ? UiShadow.hard(ui.hardShadowColor, UiShadow.tiny)
                    : null,
              ),
              child: UiTypeBadge(type: item.type, size: active ? 44 : 48),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxWidth: _cellW),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: ui.surface,
                borderRadius: BorderRadius.circular(UiRadius.capsule),
                border: Border.all(color: ui.outline, width: UiBorder.thin),
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: UiText.body(
                  size: 10.5,
                  weight: active ? FontWeight.w700 : FontWeight.w600,
                  height: 1.35,
                  color: ui.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
