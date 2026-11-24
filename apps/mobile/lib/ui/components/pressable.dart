import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// Soft Neo-Brutalism tactile press (`CLAUDE.md` §2.2) + `:focus-visible` 3px
/// ring. Every tappable surface in the kit is built on this. Guarantees a
/// 48x48 hit area.
///
/// - When [shadowOffset] > 0 (sticker surfaces: buttons, cards, chips,
///   shutters), renders a static background hard-shadow block offset by
///   `([shadowOffset], [shadowOffset])` and translates the foreground surface
///   by `([shadowOffset], [shadowOffset])` over [UiMotion.press] (`110ms`,
///   [UiCurves.easeOutStrong]) with **zero scale-down** and **zero per-frame
///   `BoxShadow` lerp**.
/// - When [shadowOffset] == 0 and [pressOffset] > 0 (flat outlined controls
///   like [UiBarIconButton] that have no idle shadow), renders **no shadow at
///   idle** and translates the foreground surface by `([pressOffset],
///   [pressOffset])` on press without scaling down.
/// - When [shadowOffset] == 0 and [pressOffset] == 0 (shadowless ghost /
///   chromeless targets), scales to [pressScale] (`0.96` default) over
///   [UiMotion.press] (`110ms`). If [pressScale] == `1.0`, no
///   [AnimationController] or [Ticker] is allocated.
class UiPressable extends StatefulWidget {
  const UiPressable({
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.semanticHint,
    this.minSize = const Size(UiSize.tap, UiSize.tap),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(UiRadius.capsule),
    ),
    this.excludeChildSemantics = false,
    this.selected,
    this.inMutuallyExclusiveGroup,
    this.centerChild = false,
    this.shadowColor,
    this.shadowOffset = 0,
    this.pressOffset = 0,
    this.pressScale = UiMotion.pressScale,
    this.haptic = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  /// Screen-reader hint (the action), kept out of [semanticLabel].
  final String? semanticHint;
  final Size minSize;
  final BorderRadius borderRadius;
  final bool excludeChildSemantics;
  final bool? selected;
  final bool? inMutuallyExclusiveGroup;

  /// Center [child] inside the (>= 48dp) hit area instead of stretching it
  /// to fill it: a 44dp button or 40dp pill keeps its visual size.
  final bool centerChild;

  /// V2 sticker press: a hard offset shadow of [shadowOffset] dp in
  /// [shadowColor]. On press the child translates by the offset and the
  /// visible shadow collapses to 0 (`translate(4px,4px); box-shadow: none`)
  /// instead of scaling. Leave [shadowOffset] at 0 for flat controls.
  final Color? shadowColor;
  final double shadowOffset;

  /// Optional flat press translation (in dp) when [shadowOffset] == 0 (e.g.
  /// header icon buttons that remain shadowless at idle but translate slightly
  /// on press instead of shrinking).
  final double pressOffset;

  /// Press scale factor when both [shadowOffset] and [pressOffset] are 0
  /// (`0.96` default; pass `1.0` to disable scaling).
  final double pressScale;

  /// Whether tapping fires [UiHaptics.pressLight] (enabled on primary
  /// [UiButton]s and hero triggers; off by default on generic list rows).
  final bool haptic;

  @override
  State<UiPressable> createState() => _UiPressableState();
}

class _UiPressableState extends State<UiPressable>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  bool _focused = false;
  bool _reduced = false;
  bool _active = false;

  AnimationController? _ctrl;
  CurvedAnimation? _curved;

  /// A pressable nested inside this one is being pressed: it owns the touch,
  /// so this one must not show its pressed state too (a member chip inside a
  /// tappable card).
  int _childPointers = 0;
  final Set<int> _claimedPointers = <int>{};
  _UiPressableState? _claimedAncestor;

  bool get _enabled => widget.onPressed != null;

  double get _translateDistance =>
      widget.shadowOffset > 0 ? widget.shadowOffset : widget.pressOffset;

  bool get _hasPressMotion =>
      _translateDistance > 0 || widget.pressScale != 1.0;

  CurvedAnimation _ensureAnimation() {
    var curved = _curved;
    if (curved != null) return curved;
    final ctrl = AnimationController(
      vsync: this,
      duration: UiMotion.press,
      reverseDuration: UiMotion.press,
    );
    _ctrl = ctrl;
    curved = CurvedAnimation(
      parent: ctrl,
      curve: UiCurves.easeOutStrong,
      reverseCurve: UiCurves.easeOutStrong,
    );
    _curved = curved;
    return curved;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _active = true;
    _reduced = UiMotion.reduced(context);
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  void _syncPressAnimation() {
    if (!_hasPressMotion) return;
    final pressed = _down && _enabled;
    if (_reduced) {
      _ctrl?.stop();
      _ctrl?.value = pressed ? 1.0 : 0.0;
      return;
    }
    if (pressed) {
      _ensureAnimation();
      _ctrl!.forward();
    } else {
      _ctrl?.reverse();
    }
  }

  void _childPointer(bool down) {
    _childPointers = (_childPointers + (down ? 1 : -1)).clamp(0, 1 << 20);
    if (down && _down && mounted) {
      setState(() {
        _down = false;
        _syncPressAnimation();
      });
    }
  }

  void _claimAncestorPointer(int pointer) {
    if (!_enabled) return;
    final ancestor = _claimedAncestor ??= context
        .findAncestorStateOfType<_UiPressableState>();
    if (ancestor != null && _claimedPointers.add(pointer)) {
      ancestor._childPointer(true);
    }
  }

  void _releaseAncestorPointer(int pointer) {
    if (_claimedPointers.remove(pointer)) {
      _claimedAncestor?._childPointer(false);
      if (_claimedPointers.isEmpty) _claimedAncestor = null;
    }
  }

  void _releaseAllAncestorPointers() {
    final count = _claimedPointers.length;
    if (count == 0) return;
    _claimedPointers.clear();
    final ancestor = _claimedAncestor;
    _claimedAncestor = null;
    for (var i = 0; i < count; i++) {
      ancestor?._childPointer(false);
    }
  }

  @override
  void didUpdateWidget(covariant UiPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _releaseAllAncestorPointers();
      if (_down ||
          (_ctrl?.value ?? 0.0) > 0.0 ||
          (_ctrl?.isAnimating ?? false)) {
        _down = false;
        _ctrl?.stop();
        _ctrl?.value = 0.0;
      }
    }
  }

  @override
  void deactivate() {
    _active = false;
    _down = false;
    _ctrl?.stop();
    _releaseAllAncestorPointers();
    super.deactivate();
  }

  @override
  void dispose() {
    _curved?.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  void _setDown(bool v) {
    if (!_active || !mounted) return;
    if (v && _childPointers > 0) return;
    if (_down != v) {
      setState(() {
        _down = v;
        _syncPressAnimation();
      });
    }
  }

  void _handleTap() {
    final cb = widget.onPressed;
    if (cb == null) return;
    if (widget.haptic) {
      unawaited(UiHaptics.pressLight());
    }
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final sticker = widget.shadowOffset > 0;
    final translateDist = _translateDistance;
    final pressed = _down && _enabled;
    final reduced = UiMotion.reduced(context);

    Widget content = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: _focused
            ? Border.all(color: ui.focus, width: 3)
            : const Border.fromBorderSide(BorderSide.none),
      ),
      child: widget.child,
    );

    if (translateDist > 0) {
      content = AnimatedBuilder(
        animation: _curved ?? kAlwaysDismissedAnimation,
        child: content,
        builder: (context, child) {
          final t = reduced ? (pressed ? 1.0 : 0.0) : (_curved?.value ?? 0.0);
          final d = t * translateDist;
          return Transform.translate(
            key: const ValueKey('ui-pressable-surface-translate'),
            offset: Offset(d, d),
            child: child,
          );
        },
      );
    } else if (widget.pressScale != 1.0) {
      content = AnimatedBuilder(
        animation: _curved ?? kAlwaysDismissedAnimation,
        child: content,
        builder: (context, child) {
          final t = reduced ? (pressed ? 1.0 : 0.0) : (_curved?.value ?? 0.0);
          final scale = lerpDouble(1.0, widget.pressScale, t)!;
          return Transform.scale(
            key: const ValueKey('ui-pressable-surface-scale'),
            scale: scale,
            child: child,
          );
        },
      );
    }

    if (sticker) {
      final offset = widget.shadowOffset;
      final shadowColor = widget.shadowColor ?? ui.hardShadowColor;
      content = Stack(
        clipBehavior: Clip.none,
        fit: StackFit.passthrough,
        children: [
          if (_enabled)
            Positioned.fill(
              child: IgnorePointer(
                child: Transform.translate(
                  offset: Offset(offset, offset),
                  child: DecoratedBox(
                    key: const ValueKey('ui-pressable-static-shadow'),
                    decoration: BoxDecoration(
                      color: shadowColor,
                      borderRadius: widget.borderRadius,
                    ),
                  ),
                ),
              ),
            ),
          content,
        ],
      );
    }

    content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.minSize.width,
        minHeight: widget.minSize.height,
      ),
      child: widget.centerChild
          ? Center(widthFactor: 1, heightFactor: 1, child: content)
          : content,
    );
    final Widget node = Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      excludeSemantics: widget.excludeChildSemantics,
      onTap: _enabled ? _handleTap : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleTap();
              return null;
            },
          ),
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) => _claimAncestorPointer(e.pointer),
          onPointerUp: (e) => _releaseAncestorPointer(e.pointer),
          onPointerCancel: (e) => _releaseAncestorPointer(e.pointer),
          child: GestureDetector(
            behavior: _enabled
                ? HitTestBehavior.opaque
                : HitTestBehavior.deferToChild,
            // The outer Semantics already carries the tap action; a second
            // tap node would stay unlabeled and separate from it.
            excludeFromSemantics: true,
            onTapDown: _enabled ? (_) => _setDown(true) : null,
            onTapUp: _enabled ? (_) => _setDown(false) : null,
            onTapCancel: _enabled ? () => _setDown(false) : null,
            onTap: _enabled ? _handleTap : null,
            child: content,
          ),
        ),
      ),
    );
    // Without an explicit label the button is named by its content (U3):
    // merge the children into the one tappable node, so screen readers read
    // e.g. a choice card's text instead of an empty "button".
    if (widget.semanticLabel == null && !widget.excludeChildSemantics) {
      return MergeSemantics(child: node);
    }
    return node;
  }
}
