import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';

/// V2 `MissedDayOverlay` (quiet and squad skins only): a dashed capsule chip
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

  /// `squad` or `quiet`; other skins render nothing, as in V2.
  final String skinId;
  final int day;
  final bool visible;
  final VoidCallback? onDismiss;

  static bool isSupportedSkin(String skinId) =>
      skinId == 'squad' || skinId == 'quiet';

  @override
  State<MissedDayOverlay> createState() => _MissedDayOverlayState();
}

class _MissedDayOverlayState extends State<MissedDayOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: UiMotion.normal,
    reverseDuration: UiMotion.fast,
  )..addStatusListener(_onStatusChanged);
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _ctrl,
    curve: UiCurves.easeOutStrong,
    reverseCurve: UiCurves.easeOutStrong,
  );

  String? _activeSkinId;
  int? _activeDay;
  bool _didInit = false;

  bool get _shouldShow =>
      widget.visible && MissedDayOverlay.isSupportedSkin(widget.skinId);

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted && !_shouldShow) {
      setState(() {
        _activeSkinId = null;
        _activeDay = null;
      });
      widget.onDismiss?.call();
    }
  }

  void _syncDurations() {
    _ctrl.duration = UiMotion.fadeOf(context, UiMotion.normal);
    _ctrl.reverseDuration = UiMotion.fadeOf(context, UiMotion.fast);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDurations();
    if (!_didInit) {
      _didInit = true;
      if (_shouldShow) {
        _activeSkinId = widget.skinId;
        _activeDay = widget.day;
        if (UiMotion.reduced(context)) {
          _ctrl.value = 1.0;
        } else {
          _ctrl.forward(from: 0.0);
        }
      }
    } else if (UiMotion.reduced(context) && _ctrl.isAnimating) {
      if (_shouldShow) {
        _ctrl.value = 1.0;
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
    if (nowShowing) {
      _activeSkinId = widget.skinId;
      _activeDay = widget.day;
      if (!wasShowing) {
        _ctrl.forward(from: 0.0);
      }
    } else if (wasShowing && _activeSkinId != null) {
      if (!MissedDayOverlay.isSupportedSkin(widget.skinId)) {
        _ctrl.stop();
        _ctrl.value = 0.0;
        _activeSkinId = null;
        _activeDay = null;
      } else {
        _ctrl.reverse();
      }
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
    final Widget faded = FadeTransition(
      opacity: reduced ? _ctrl : _curved,
      child: rotated,
    );
    if (reduced) return faded;
    return AnimatedBuilder(
      animation: _curved,
      child: faded,
      builder: (context, child) {
        final isReverse = _ctrl.status == AnimationStatus.reverse;
        final dy = isReverse
            ? (1.0 - _curved.value) * -16.0
            : (1.0 - _curved.value) * 6.0;
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
