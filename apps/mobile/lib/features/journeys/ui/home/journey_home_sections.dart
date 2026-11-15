import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';

/// Metric samples of a journey, oldest first (check-ins with a value only).
typedef MetricSeries = List<double>;

/// Day numbers of the three milestone cards (`quiet-milestones`): the first
/// week, the middle, the finish. Open-ended journeys use 7 / 14 / 30.
List<int> homeMilestoneDays(int? total) {
  if (total == null) return const [7, 14, 30];
  final days = <int>{
    if (total > 7) 7,
    if (total > 14) (total / 2).round(),
    total,
  }..removeWhere((d) => d < 1);
  return (days.toList()..sort());
}

String _milestoneLabel(JourneysL10n l, int day, int? total) {
  if (total != null && day == total) return l.journeys_home_msFinish;
  if (day == 7) return l.journeys_home_msWeek;
  return l.journeys_home_msHalf;
}

/// `quiet-milestones` / per-skin milestone cards: star disc, "NGÀY 07",
/// label. Reached ones are filled with the skin accent.
class JourneyHomeMilestones extends StatelessWidget {
  const JourneyHomeMilestones({
    required this.day,
    required this.total,
    required this.accent,
    required this.onAccent,
    super.key,
  });

  final int day;
  final int? total;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final days = homeMilestoneDays(total);
    return Row(
      key: const ValueKey('journey-home-milestones'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Semantics(
                container: true,
                label:
                    '${_milestoneLabel(l10n, d, total)}, '
                    '${l10n.journeys_home_msDay(d)}',
                excludeSemantics: true,
                child: Column(
                  children: [
                    Container(
                      key: ValueKey('journey-milestone-$d'),
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: day >= d ? accent : ui.fill,
                        shape: BoxShape.circle,
                        border: Border.all(color: ui.border),
                      ),
                      child: OurneyIcon(
                        name: 'star',
                        size: 17,
                        color: day >= d ? onAccent : ui.inkMuted,
                      ),
                    ),
                    const SizedBox(height: UiSpace.xs),
                    Text(
                      l10n.journeys_home_msDay(d),
                      style: UiText.eyebrow(color: ui.inkMuted),
                    ),
                    Text(
                      _milestoneLabel(l10n, d, total),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 13,
                        weight: FontWeight.w700,
                        height: 1.35,
                        color: ui.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Hội hôm nay" (groups only) and "Tạo thiệp" (`quiet-home-actions`).
class JourneyHomeActions extends StatelessWidget {
  const JourneyHomeActions({
    required this.onShare,
    this.onSquad,
    this.onWrapped,
    super.key,
  });

  final VoidCallback onShare;

  /// Null for solo journeys (no squad row, as in Figma `journey.shared`).
  final VoidCallback? onSquad;

  /// Ended journeys: opens the finish story ("Xem tổng kết").
  final VoidCallback? onWrapped;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    return Column(
      key: const ValueKey('journey-home-actions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onWrapped != null) ...[
          UiButton(
            key: const ValueKey('journey-home-wrapped'),
            glyph: const OurneyIcon(name: 'trophy', size: 19, flat: true),
            label: l10n.journeys_home_viewWrapped,
            onPressed: onWrapped,
          ),
          const SizedBox(height: UiSpace.sm),
        ],
        if (onSquad != null) ...[
          UiButton.secondary(
            key: const ValueKey('journey-home-squad'),
            glyph: const OurneyIcon(name: 'squad', size: 19, flat: true),
            label: l10n.journeys_home_actionSquad,
            onPressed: onSquad,
          ),
          const SizedBox(height: UiSpace.sm),
        ],
        UiButton.secondary(
          key: const ValueKey('journey-home-card'),
          glyph: const OurneyIcon(name: 'share', size: 19, flat: true),
          label: l10n.journeys_home_actionCard,
          onPressed: onShare,
        ),
      ],
    );
  }
}

/// Progress chip of the squad / flexer homes (`squad-progress-chip`,
/// `flexer-attendance-chip`): days shot out of days elapsed.
class JourneyHomeAttendance extends StatelessWidget {
  const JourneyHomeAttendance({
    required this.done,
    required this.total,
    super.key,
  });

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        key: const ValueKey('journey-home-attendance'),
        padding: const EdgeInsets.symmetric(
          horizontal: UiSpace.md,
          vertical: UiSpace.sm,
        ),
        decoration: BoxDecoration(
          color: ui.fill,
          borderRadius: BorderRadius.circular(UiRadius.capsule),
          border: Border.all(color: ui.border),
        ),
        child: Text(
          JourneysL10n.of(context).journeys_home_attendance(done, total),
          style: UiText.eyebrow(color: ui.ink),
        ),
      ),
    );
  }
}

/// Progress chart card. `quiet`: filled weight line with values masked as
/// "••" until "Giữ để xem" is held. `flexer`: pace sparkline, always shown.
class JourneyHomeChart extends StatefulWidget {
  const JourneyHomeChart({
    required this.skin,
    required this.values,
    required this.accent,
    this.unit = '',
    this.maskable = false,
    super.key,
  });

  final String skin;
  final MetricSeries values;
  final Color accent;
  final String unit;

  /// Quiet journeys hide numbers until held (privacy of weight).
  final bool maskable;

  @override
  State<JourneyHomeChart> createState() => _JourneyHomeChartState();
}

class _JourneyHomeChartState extends State<JourneyHomeChart> {
  bool _revealed = false;

  String _fmt(double v) {
    final s = v == v.roundToDouble()
        ? v.round().toString()
        : v.toStringAsFixed(1);
    return widget.unit.isEmpty ? s : '$s ${widget.unit}';
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final v = widget.values;
    if (v.length < 2) return const SizedBox.shrink();
    final show = !widget.maskable || _revealed;
    final lo = v.reduce((a, b) => a < b ? a : b);
    final hi = v.reduce((a, b) => a > b ? a : b);
    String axis(double x) => show ? _fmt(x) : '••,•';
    final quiet = widget.skin == 'quiet';
    return Container(
      key: ValueKey('journey-home-chart-${widget.skin}'),
      padding: const EdgeInsets.all(UiSpace.lg),
      decoration: BoxDecoration(
        color: ui.surface,
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(color: ui.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  axis(v.first),
                  key: const ValueKey('journey-chart-first'),
                  style: UiText.eyebrow(color: ui.inkMuted),
                ),
              ),
              Flexible(
                child: Text(
                  axis(v.last),
                  key: const ValueKey('journey-chart-last'),
                  style: UiText.eyebrow(color: ui.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.sm),
          Semantics(
            image: true,
            label: l10n.journeys_home_chartA11y,
            child: SizedBox(
              height: quiet ? 118 : 90,
              child: CustomPaint(
                painter: _LinePainter(
                  values: v,
                  lo: lo,
                  hi: hi,
                  color: widget.accent,
                  fill: quiet,
                  dot: ui.ink,
                ),
              ),
            ),
          ),
          if (widget.maskable) ...[
            const SizedBox(height: UiSpace.sm),
            Align(
              child: GestureDetector(
                key: const ValueKey('journey-chart-hold'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => setState(() => _revealed = true),
                onTapUp: (_) => setState(() => _revealed = false),
                onTapCancel: () => setState(() => _revealed = false),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: UiSize.tap,
                    minWidth: UiSize.tap,
                  ),
                  child: Semantics(
                    button: true,
                    label: l10n.journeys_home_holdReveal,
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OurneyIcon(
                          name: _revealed ? 'eye-off' : 'eye',
                          size: 20,
                          color: ui.ink,
                        ),
                        const SizedBox(width: UiSpace.sm),
                        Flexible(
                          child: Text(
                            _revealed
                                ? l10n.journeys_home_viewing
                                : l10n.journeys_home_holdReveal,
                            style: UiText.body(
                              size: 14,
                              weight: FontWeight.w700,
                              height: 1.35,
                              color: ui.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.values,
    required this.lo,
    required this.hi,
    required this.color,
    required this.fill,
    required this.dot,
  });

  final List<double> values;
  final double lo;
  final double hi;
  final Color color;
  final bool fill;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    Offset at(int i) => Offset(
      pad + (size.width - 2 * pad) * i / (values.length - 1),
      pad + (size.height - 2 * pad) * (1 - (values[i] - lo) / span),
    );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = at(i - 1);
      final b = at(i);
      final mid = (a.dx + b.dx) / 2;
      path.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    }
    if (fill) {
      final area = Path.from(path)
        ..lineTo(at(values.length - 1).dx, size.height)
        ..lineTo(at(0).dx, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (final i in [0, values.length - 1]) {
      canvas.drawCircle(at(i), 5, Paint()..color = dot);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.color != color || old.fill != fill;
}
