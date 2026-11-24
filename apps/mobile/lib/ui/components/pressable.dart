import 'package:flutter/material.dart';

import '../tokens.dart';

/// `button:active { transform: scale(.96); transition: transform 110ms }`
/// plus the `:focus-visible` 3px ring. Every tappable surface in the kit is
/// built on this. Guarantees a 48x48 hit area.
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
  /// shadow disappears (`translate(4px,4px); box-shadow: none`) instead of
  /// scaling. Leave [shadowOffset] at 0 for the plain 0.96 scale press.
  final Color? shadowColor;
  final double shadowOffset;

  @override
  State<UiPressable> createState() => _UiPressableState();
}

class _UiPressableState extends State<UiPressable> {
  bool _down = false;
  bool _focused = false;

  /// A pressable nested inside this one is being pressed: it owns the touch,
  /// so this one must not show its pressed state too (a member chip inside a
  /// tappable card).
  int _childPointers = 0;
  final Set<int> _claimedPointers = <int>{};
  _UiPressableState? _claimedAncestor;

  void _childPointer(bool down) {
    _childPointers = (_childPointers + (down ? 1 : -1)).clamp(0, 1 << 20);
    if (down && _down && mounted) setState(() => _down = false);
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
      if (_down) _down = false;
    }
  }

  @override
  void deactivate() {
    _releaseAllAncestorPointers();
    super.deactivate();
  }

  bool get _enabled => widget.onPressed != null;

  void _setDown(bool v) {
    if (v && _childPointers > 0) return;
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final sticker = widget.shadowOffset > 0;
    final pressed = _down && _enabled;
    Widget content = AnimatedScale(
      scale: pressed && !sticker ? UiMotion.pressScale : 1,
      duration: UiMotion.of(context, UiMotion.press),
      curve: Curves.easeOut,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: _focused
              ? Border.all(color: ui.focus, width: 3)
              : const Border.fromBorderSide(BorderSide.none),
        ),
        child: widget.child,
      ),
    );
    if (sticker) {
      final offset = widget.shadowOffset;
      content = AnimatedContainer(
        duration: UiMotion.of(context, UiMotion.press),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          pressed ? offset : 0,
          pressed ? offset : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: pressed || !_enabled
              ? const []
              : UiShadow.hard(widget.shadowColor ?? ui.hardShadowColor, offset),
        ),
        child: content,
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
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
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
            onTap: widget.onPressed,
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
