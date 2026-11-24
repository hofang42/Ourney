import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../tokens.dart';
import '../typography.dart';
import 'ourney_icons.dart';
import 'pressable.dart';

/// `.eyebrow`: 12px bold, 0.12em tracking, muted.
class UiEyebrow extends StatelessWidget {
  const UiEyebrow(this.text, {this.color, this.textAlign, super.key});

  final String text;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: textAlign,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: UiText.eyebrow(color: color ?? context.ui.inkMuted),
  );
}

/// Hairline between rows (`border-bottom: 1px solid #e6e6e0`).
class UiDivider extends StatelessWidget {
  const UiDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: context.ui.divider);
}

/// Sticker surface (`.create-deck-card`, `.settings-card`, `.hub-all-done`):
/// 2dp outline, 16dp radius, 4dp hard shadow, never glass. Interactive cards
/// use the sticker press (translate by the offset, shadow drops). Pass
/// [shadowOffset] 0 for a flat outlined card.
class UiCard extends StatelessWidget {
  const UiCard({
    required this.child,
    this.padding = const EdgeInsets.all(UiSpace.lg),
    this.radius = UiRadius.menu,
    this.color,
    this.borderColor,
    this.onPressed,
    this.semanticLabel,
    this.excludeChildSemantics = false,
    this.shadowOffset = UiShadow.large,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool excludeChildSemantics;
  final double shadowOffset;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final shape = BorderRadius.circular(radius);
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? ui.surface,
        borderRadius: shape,
        border: Border.all(
          color: borderColor ?? ui.outline,
          width: UiBorder.standard,
        ),
        boxShadow: onPressed == null && shadowOffset > 0
            ? ui.hardShadow(shadowOffset)
            : null,
      ),
      child: child,
    );
    if (onPressed == null) return box;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      excludeChildSemantics: excludeChildSemantics,
      borderRadius: shape,
      shadowOffset: shadowOffset,
      child: box,
    );
  }
}

/// `.journey-row`: leading thumb, two lines of copy, chevron, hairline below
/// (12% ink). Pass [sticker] to render it as an outlined 16dp card with the
/// 4dp hard shadow instead of a divider row.
class UiRow extends StatelessWidget {
  const UiRow({
    required this.title,
    this.leading,
    this.subtitle,
    this.meta,
    this.trailing,
    this.onPressed,
    this.selected,
    this.inMutuallyExclusiveGroup,
    this.showChevron = true,
    this.minHeight = 64,
    this.divider = true,
    this.sticker = false,
    super.key,
  });

  final String title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? meta;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool? selected;
  final bool? inMutuallyExclusiveGroup;
  final bool showChevron;
  final double minHeight;
  final bool divider;
  final bool sticker;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final shape = BorderRadius.circular(UiRadius.menu);
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: UiText.body(
        size: 15,
        weight: FontWeight.w700,
        height: 1.35,
        color: ui.ink,
      ),
    );
    final row = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.symmetric(
        vertical: sticker ? 10 : 13,
        horizontal: sticker ? 14 : 0,
      ),
      decoration: sticker
          ? BoxDecoration(
              color: ui.surface,
              borderRadius: shape,
              border: ui.stickerBorder(),
              boxShadow: onPressed == null ? ui.hardShadow() : null,
            )
          : BoxDecoration(
              border: divider
                  ? Border(
                      bottom: BorderSide(color: ui.ink.withValues(alpha: 0.12)),
                    )
                  : null,
            ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onPressed != null && trailing != null)
                  ExcludeSemantics(child: titleText)
                else
                  titleText,
                if (subtitle != null) ...[const SizedBox(height: 3), subtitle!],
                if (meta != null) ...[const SizedBox(height: 3), meta!],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          if (onPressed != null && showChevron) ...[
            const SizedBox(width: 8),
            OurneyIcon(
              name: 'chevron-right',
              size: 20,
              flat: true,
              color: sticker ? ui.ink : ui.chevron,
            ),
          ],
        ],
      ),
    );
    if (onPressed == null) return row;
    return UiPressable(
      onPressed: onPressed,
      selected: selected,
      inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
      semanticLabel: trailing == null ? null : title,
      borderRadius: sticker ? shape : BorderRadius.zero,
      shadowOffset: sticker ? UiShadow.large : 0,
      minSize: const Size(UiSize.tap, 64),
      child: row,
    );
  }
}

/// `.list-heading` / `.section-title`: h2 + trailing quiet action.
class UiListHeading extends StatelessWidget {
  const UiListHeading({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.h2(size: 18, color: ui.ink),
            ),
          ),
        ),
        if (actionLabel != null)
          UiPressable(
            onPressed: onAction,
            semanticLabel: actionLabel,
            excludeChildSemantics: true,
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: UiSize.tap),
              padding: const EdgeInsets.only(left: UiSpace.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: UiText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: ui.inkMuted,
                    ),
                  ),
                  OurneyIcon(
                    name: 'chevron-right',
                    size: 16,
                    flat: true,
                    color: ui.chevron,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// `.hub-add-menu` / `.overflow-menu`: floating action list.
class UiMenuSurface extends StatelessWidget {
  const UiMenuSurface({required this.children, this.width = 238, super.key});

  final List<Widget> children;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Container(
      width: width,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ui.surface,
        borderRadius: BorderRadius.circular(UiRadius.menu),
        border: ui.stickerBorder(),
        boxShadow: ui.hardShadow(),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Floats [menu] (usually a [UiMenuSurface]) under the end edge of [anchor],
/// like the Figma `.hub-add-menu` / `.overflow-menu` (`position: absolute`).
///
/// The menu lives in the overlay, so opening it never reflows the screen
/// below the anchor. Tapping outside or the system back closes it through
/// [onClose].
class UiMenuAnchor extends StatefulWidget {
  const UiMenuAnchor({
    required this.open,
    required this.onClose,
    required this.anchor,
    required this.menu,
    this.gap = 6,
    super.key,
  });

  final bool open;
  final VoidCallback onClose;
  final Widget anchor;
  final Widget menu;

  /// Space between the anchor's bottom edge and the menu.
  final double gap;

  @override
  State<UiMenuAnchor> createState() => _UiMenuAnchorState();
}

class _UiMenuAnchorState extends State<UiMenuAnchor>
    with SingleTickerProviderStateMixin {
  static const Duration _kMenuEnter = Duration(milliseconds: 180);
  static const Duration _kMenuExit = Duration(milliseconds: 130);

  final _link = LayerLink();
  final _portal = OverlayPortalController();

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: _kMenuEnter,
    reverseDuration: _kMenuExit,
    value: widget.open ? 1.0 : 0.0,
  )..addStatusListener(_onStatusChanged);
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _ctrl,
    curve: UiCurves.easeOutStrong,
    reverseCurve: UiCurves.easeOutStrong.flipped,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: UiMotion.popMinScale,
    end: 1.0,
  ).animate(_curved);

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed &&
        mounted &&
        !widget.open &&
        _portal.isShowing) {
      _hidePortalSafely();
    }
  }

  void _showPortalSafely({required bool animateForward}) {
    if (_portal.isShowing) {
      if (animateForward) _ctrl.forward();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.open) return;
      if (!_portal.isShowing) {
        _portal.show();
      }
      if (animateForward) {
        _ctrl.forward(from: 0.0);
      }
    });
  }

  void _hidePortalSafely() {
    if (!_portal.isShowing) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.open && _portal.isShowing) {
          _portal.hide();
        }
      });
    } else {
      _portal.hide();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.open) {
      _showPortalSafely(animateForward: false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = UiMotion.reduced(context);
    _ctrl.duration = reduced ? UiMotion.reducedFade : _kMenuEnter;
    _ctrl.reverseDuration = reduced ? UiMotion.reducedFade : _kMenuExit;
  }

  @override
  void didUpdateWidget(UiMenuAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) return;
    final reduced = UiMotion.reduced(context);
    _ctrl.duration = reduced ? UiMotion.reducedFade : _kMenuEnter;
    _ctrl.reverseDuration = reduced ? UiMotion.reducedFade : _kMenuExit;
    if (widget.open) {
      unawaited(UiHaptics.selection());
      _showPortalSafely(animateForward: true);
    } else if (_ctrl.isDismissed) {
      _hidePortalSafely();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_onStatusChanged);
    _curved.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final reduced = UiMotion.reduced(context);
    final triggerAlignment = rtl ? Alignment.topLeft : Alignment.topRight;
    return PopScope(
      canPop: !widget.open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onClose();
      },
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) {
          Widget menuSurface = Material(
            type: MaterialType.transparency,
            child: widget.menu,
          );
          if (!reduced) {
            menuSurface = ScaleTransition(
              key: const ValueKey('ui-menu-scale'),
              alignment: triggerAlignment,
              scale: _scale,
              child: menuSurface,
            );
          }
          menuSurface = FadeTransition(
            key: const ValueKey('ui-menu-fade'),
            opacity: reduced ? _ctrl : _curved,
            child: menuSurface,
          );
          return Stack(
            children: [
              if (widget.open)
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey('ui-menu-barrier'),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onClose,
                  ),
                ),
              Positioned(
                left: 0,
                top: 0,
                child: CompositedTransformFollower(
                  link: _link,
                  showWhenUnlinked: false,
                  targetAnchor: rtl
                      ? Alignment.bottomLeft
                      : Alignment.bottomRight,
                  followerAnchor: triggerAlignment,
                  offset: Offset(0, widget.gap),
                  child: ExcludeSemantics(
                    excluding: !widget.open,
                    child: IgnorePointer(
                      ignoring: !widget.open,
                      child: menuSurface,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: CompositedTransformTarget(link: _link, child: widget.anchor),
      ),
    );
  }
}

/// One entry of a [UiMenuSurface].
class UiMenuItem extends StatelessWidget {
  const UiMenuItem({
    required this.label,
    required this.onPressed,
    @Deprecated('Use glyph: an OurneyIcon name') this.icon,
    this.glyph,
    this.destructive = false,
    super.key,
  });

  final String label;
  final IconData? icon;

  /// [OurneyIcon] name drawn flat in the label color (e.g. `'trash'`).
  final String? glyph;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final color = destructive ? ui.danger : ui.ink;
    return UiPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: UiSize.tap),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            if (icon != null || glyph != null) ...[
              glyph != null
                  ? OurneyIcon(name: glyph!, size: 18, flat: true, color: color)
                  : Icon(icon, size: 17, color: color),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 13,
                  weight: FontWeight.w700,
                  height: 1.35,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
