import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';

/// V2 `MissedDayOverlay` (squad skin only): a dashed capsule chip
/// ("NGÀY 9 · NGHỈ" / "NGÀY 9 · LỠ", squad: square corners tilted -3deg) that
/// opens a calm sheet explaining the gap. Placed at bottom-start above the
/// dock alongside the floating Check-in button.
///
/// Animates entrance (`200ms` [UiMotion.normal], [UiCurves.easeOutStrong]) and
/// exit (`160ms` [UiMotion.fast] upward `-16dp` slide + fade before clearing
/// when [visible] becomes `false`), collapsing to a `150ms` opacity-only fade
/// under Reduce Motion.
class MissedDayOverlay extends StatefulWidget {
  const MissedDayOverlay({
    required this.skinId,
    required this.day,
    this.visible = true,
    this.onDismiss,
    super.key,
  });

  /// `squad`; other skins render nothing.
  final String skinId;
  final int day;
  final bool visible;
  final VoidCallback? onDismiss;

  static bool isSupportedSkin(String skinId) =>
      skinId == 'squad';

  @override
  State<MissedDayOverlay> createState() => _MissedDayOverlayState();
}

class _MissedDayOverlayState extends State<MissedDayOverlay>
    with SingleTickerProviderStateMixin {
  static const double _kEnterOffsetDy = 6.0;
  static const double _kExitOffsetDy = -16.0;

  AnimationController? _ctrl;
  CurvedAnimation? _curved;

  String? _activeSkinId;
  int? _activeDay;
  bool _didInit = false;
  double _lastDy = 0.0;
  double _reverseStartT = 1.0;
  double _reverseStartDy = 0.0;

  bool get _shouldShow =>
      widget.visible && MissedDayOverlay.isSupportedSkin(widget.skinId);

  AnimationController _ensureController() {
    var ctrl = _ctrl;
    if (ctrl != null) return ctrl;
    ctrl = AnimationController(
      vsync: this,
      duration: UiMotion.fadeOf(context, UiMotion.normal),
      reverseDuration: UiMotion.fadeOf(context, UiMotion.fast),
    )..addStatusListener(_onStatusChanged);
    _ctrl = ctrl;
    _curved = CurvedAnimation(
      parent: ctrl,
      curve: UiCurves.easeOutStrong,
      reverseCurve: UiCurves.easeOutStrong.flipped,
    );
    return ctrl;
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      _reverseStartT = _curved?.value ?? _ctrl?.value ?? 1.0;
      _reverseStartDy = _lastDy;
    } else if (status == AnimationStatus.forward) {
      _reverseStartT = 1.0;
      _reverseStartDy = 0.0;
    } else if (status == AnimationStatus.dismissed &&
        mounted &&
        !_shouldShow) {
      setState(() {
        _activeSkinId = null;
        _activeDay = null;
      });
      widget.onDismiss?.call();
    }
  }

  void _syncDurations() {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    ctrl.duration = UiMotion.fadeOf(context, UiMotion.normal);
    ctrl.reverseDuration = UiMotion.fadeOf(context, UiMotion.fast);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDurations();
    final reduced = UiMotion.reduced(context);
    if (!_didInit) {
      _didInit = true;
      if (_shouldShow) {
        _activeSkinId = widget.skinId;
        _activeDay = widget.day;
        if (!reduced) {
          _lastDy = _kEnterOffsetDy;
          _ensureController().forward(from: 0.0);
        }
      }
    } else if (reduced && (_ctrl?.isAnimating ?? false)) {
      if (_shouldShow) {
        _ctrl?.stop();
        _ctrl?.value = 1.0;
        _lastDy = 0.0;
      }
    }
  }

  @override
  void didUpdateWidget(covariant MissedDayOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDurations();
    final wasShowing =
        oldWidget.visible && MissedDayOverlay.isSupportedSkin(oldWidget.skinId);
    final nowShowing = _shouldShow;
    final reduced = UiMotion.reduced(context);
    if (nowShowing) {
      _activeSkinId = widget.skinId;
      _activeDay = widget.day;
      if (!wasShowing) {
        if (reduced) {
          _ctrl?.stop();
          _ctrl?.value = 1.0;
          _lastDy = 0.0;
        } else {
          _lastDy = _kEnterOffsetDy;
          _ensureController().forward(from: 0.0);
        }
      }
    } else if (wasShowing && _activeSkinId != null) {
      if (!MissedDayOverlay.isSupportedSkin(widget.skinId)) {
        _ctrl?.stop();
        _ctrl?.value = 0.0;
        _activeSkinId = null;
        _activeDay = null;
      } else {
        final ctrl = _ensureController();
        _syncDurations();
        if (ctrl.value == 0.0 && !ctrl.isAnimating) {
          ctrl.value = 1.0;
        }
        _reverseStartT = _curved?.value ?? ctrl.value;
        _reverseStartDy = _lastDy;
        ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl?.removeStatusListener(_onStatusChanged);
    _curved?.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skinId = _shouldShow ? widget.skinId : _activeSkinId;
    final day = _shouldShow ? widget.day : (_activeDay ?? widget.day);
    if (skinId == null || !MissedDayOverlay.isSupportedSkin(skinId)) {
      return const SizedBox.shrink();
    }
    final squad = skinId == 'squad';
    final ui = context.ui;
    final l = AppLocalizations.of(context);
    final reduced = UiMotion.reduced(context);
    final label = squad
        ? l.missedDay_chipSquad(day)
        : l.missedDay_chipQuiet(day);
    final Widget chip = Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('missed-day-chip'),
        customBorder: squad
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
            : const StadiumBorder(),
        onTap: () {
          unawaited(UiHaptics.selection());
          showUiSheet<void>(
            context: context,
            builder: (context) => _MissedDaySheet(squad: squad),
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: UiSize.tap,
            minHeight: UiSize.tap,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ShapeDecoration(
              color: ui.surface,
              shape: _DashedShape(color: ui.inkMuted, radius: squad ? 4 : 999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(
                      size: 12,
                      weight: FontWeight.w900,
                      height: 1.3,
                      color: ui.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final Widget rotated = squad
        ? Transform.rotate(angle: -3 * math.pi / 180, child: chip)
        : chip;
    final opacityAnim = reduced
        ? (_ctrl ?? kAlwaysCompleteAnimation)
        : (_curved ?? kAlwaysCompleteAnimation);
    final Widget faded = FadeTransition(
      opacity: opacityAnim,
      child: rotated,
    );
    final curved = _curved;
    final ctrl = _ctrl;
    if (reduced || curved == null || ctrl == null) return faded;
    return AnimatedBuilder(
      animation: curved,
      child: faded,
      builder: (context, child) {
        final t = curved.value;
        final double dy;
        if (ctrl.status == AnimationStatus.reverse) {
          final progress = _reverseStartT > 1e-4
              ? (1.0 - (t / _reverseStartT)).clamp(0.0, 1.0)
              : 1.0;
          dy = lerpDouble(_reverseStartDy, _kExitOffsetDy, progress)!;
        } else {
          dy = (1.0 - t) * _kEnterOffsetDy;
        }
        _lastDy = dy;
        return Transform.translate(
          key: const ValueKey('missed-day-translate'),
          offset: Offset(0, dy),
          child: child,
        );
      },
    );
  }
}

class _MissedDaySheet extends StatelessWidget {
  const _MissedDaySheet({required this.squad});
  final bool squad;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(UiSpace.xl, 0, UiSpace.xl, UiSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              squad ? l.missedDay_titleSquad : l.missedDay_titleQuiet,
              style: UiText.heading(
                font: 'Space Grotesk',
                size: 24,
                height: 1.3,
                color: ui.ink,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            squad ? l.missedDay_bodySquad : l.missedDay_bodyQuiet,
            style: UiText.muted(color: ui.inkMuted, size: 14),
          ),
          const SizedBox(height: UiSpace.xl),
          UiButton(
            key: const ValueKey('missed-day-dismiss'),
            label: l.missedDay_dismiss,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// A 2dp dashed rounded outline.
class _DashedShape extends ShapeBorder {
  const _DashedShape({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(2);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(rect.deflate(2), Radius.circular(radius)),
    );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final rr = RRect.fromRectAndRadius(
      rect.deflate(1),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final m in (Path()..addRRect(rr)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}
