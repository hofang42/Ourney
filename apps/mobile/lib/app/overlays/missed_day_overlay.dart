import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../ui/ui.dart';

/// V2 `MissedDayOverlay` (quiet and squad skins only): a dashed capsule chip
/// ("NGÀY 9 · NGHỈ" / "NGÀY 9 · LỠ", squad: square corners tilted -3deg) that
/// opens a calm sheet explaining the gap. Position it bottom-right above the
/// dock (V2 `right: 18, bottom: 118`).
class MissedDayOverlay extends StatelessWidget {
  const MissedDayOverlay({required this.skinId, required this.day, super.key});

  /// `squad` or `quiet`; other skins render nothing, as in V2.
  final String skinId;
  final int day;

  @override
  Widget build(BuildContext context) {
    if (skinId != 'squad' && skinId != 'quiet') return const SizedBox.shrink();
    final squad = skinId == 'squad';
    final ui = context.ui;
    final l = AppLocalizations.of(context);
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
        onTap: () => showUiSheet<void>(
          context: context,
          builder: (context) => _MissedDaySheet(squad: squad),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: UiSize.tap),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: ui.surface,
              shape: _DashedShape(color: ui.inkMuted, radius: squad ? 4 : 999),
            ),
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
        ),
      ),
    );
    return squad
        ? Transform.rotate(angle: -3 * math.pi / 180, child: chip)
        : chip;
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
