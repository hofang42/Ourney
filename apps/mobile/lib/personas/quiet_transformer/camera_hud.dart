import 'package:flutter/material.dart';

import '../../app/theme/motion.dart';
import '../../app/theme/persona_theme.dart';
import '../../app/theme/tokens.dart';
import '../../shared/layout.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import 'l10n/generated/quiet_transformer_localizations.dart';
import 'metric_curve_painter.dart';

/// **Task Q2** (`PersonaSkinId.quietTransformer` — `ghostAlignVault`):
/// - Translucent Day 1 silhouette alignment overlay (`30%` opacity toggle,
///   rendered strictly on-device over [PersonaCameraData.viewfinder]).
/// - Top `Private Vault · Day N` pill with a vector lock icon.
/// - Bottom horizontal metric/weight slider bar (`62.0 KG`), hidden when
///   `data.hideMetric` is true or the journey tracks no metric.
class GhostAlignVaultHud extends StatefulWidget {
  const GhostAlignVaultHud({
    required this.data,
    this.onMetricChanged,
    super.key,
  });

  final PersonaCameraData data;
  final ValueChanged<double>? onMetricChanged;

  @override
  State<GhostAlignVaultHud> createState() => _GhostAlignVaultHudState();
}

class _GhostAlignVaultHudState extends State<GhostAlignVaultHud> {
  bool _ghostEnabled = true;
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = (widget.data.metricValue ?? 62.0).clamp(30.0, 150.0);
  }

  @override
  void didUpdateWidget(GhostAlignVaultHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.metricValue != null &&
        widget.data.metricValue != oldWidget.data.metricValue) {
      _sliderValue = widget.data.metricValue!.clamp(30.0, 150.0);
    }
  }

  int get _dayNumber {
    final days = widget.data.journey.startDate.daysUntil(widget.data.date) + 1;
    return days < 1 ? 1 : days;
  }

  void _toggleGhost() {
    OurneyHaptics.selection();
    setState(() => _ghostEnabled = !_ghostEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = QuietTransformerL10n.of(context);
    final journey = widget.data.journey;
    final showMetricBar =
        !widget.data.hideMetric &&
        journey.metricName != null &&
        journey.metricName!.trim().isNotEmpty;

    return Stack(
      key: const ValueKey('q2-ghost-align-vault-hud'),
      fit: StackFit.expand,
      children: [
        widget.data.viewfinder,
        // 30% opacity Day-1 ghost alignment guide (never burned into the file).
        IgnorePointer(
          child: AnimatedOpacity(
            key: const ValueKey('q2-ghost-overlay'),
            opacity: _ghostEnabled ? 0.30 : 0.0,
            duration: OurneyMotion.duration(
              context,
              const Duration(milliseconds: 180),
            ),
            child: widget.data.firstPhoto != null
                ? Image(image: widget.data.firstPhoto!, fit: BoxFit.cover)
                : CustomPaint(
                    painter: _GhostSilhouettePainter(
                      color: pTheme.primaryAccent,
                    ),
                  ),
          ),
        ),
        // Top Private Vault · Day N pill + Ghost toggle button.
        Positioned(
          top: 10,
          left: 12,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonaPill(
                key: const ValueKey('q2-vault-pill'),
                icon: Icons.lock_rounded,
                label: l10n.quiet_transformer_vaultPill(_dayNumber),
              ),
              const SizedBox(height: 6),
              Semantics(
                button: true,
                toggled: _ghostEnabled,
                label: _ghostEnabled
                    ? l10n.quiet_transformer_ghostOn
                    : l10n.quiet_transformer_ghostOff,
                excludeSemantics: true,
                child: GestureDetector(
                  key: const ValueKey('q2-ghost-toggle'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleGhost,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: OurneyLayout.minTouchTarget,
                      minWidth: OurneyLayout.minTouchTarget,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: OurneyColors.mediaBlack.withValues(
                            alpha: 0.62,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _ghostEnabled
                                ? pTheme.primaryAccent
                                : OurneyColors.mediaWhite.withValues(
                                    alpha: 0.24,
                                  ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _ghostEnabled
                                  ? Icons.accessibility_new_rounded
                                  : Icons.visibility_off_outlined,
                              size: 15,
                              color: _ghostEnabled
                                  ? pTheme.primaryAccent
                                  : OurneyColors.mediaWhite.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _ghostEnabled
                                    ? l10n.quiet_transformer_ghostOn
                                    : l10n.quiet_transformer_ghostOff,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: OurneyColors.mediaWhite,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom horizontal weight/metric slider overlay.
        if (showMetricBar)
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Container(
              key: const ValueKey('q2-metric-slider-card'),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              decoration: BoxDecoration(
                color: OurneyColors.mediaBlack.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: pTheme.primaryAccent.withValues(alpha: 0.55),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.monitor_weight_outlined,
                        size: 16,
                        color: pTheme.primaryAccent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.quiet_transformer_metricSliderLabel(
                            journey.metricName!,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: OurneyColors.mediaWhite.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        MetricSeries.formatValue(
                          _sliderValue,
                          journey.metricUnit,
                        ),
                        key: const ValueKey('q2-metric-value-text'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: pTheme.primaryAccent,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: pTheme.primaryAccent,
                      inactiveTrackColor: OurneyColors.mediaWhite.withValues(
                        alpha: 0.24,
                      ),
                      thumbColor: pTheme.primaryAccent,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                    ),
                    child: SizedBox(
                      height: OurneyLayout.minTouchTarget,
                      child: Slider(
                        key: const ValueKey('q2-metric-slider'),
                        value: _sliderValue,
                        min: 30.0,
                        max: 150.0,
                        divisions: 1200,
                        onChanged: (v) {
                          setState(() => _sliderValue = v);
                          widget.onMetricChanged?.call(v);
                          widget.data.onMetricChanged?.call(v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GhostSilhouettePainter extends CustomPainter {
  _GhostSilhouettePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Alignment crosshair & head/shoulder posture frame.
    final headR = size.shortestSide * 0.10;
    final headCenter = Offset(cx, cy - size.height * 0.14);
    canvas.drawCircle(headCenter, headR, paint);

    final shoulderW = size.width * 0.44;
    final torsoH = size.height * 0.30;
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(cx, headCenter.dy + headR + torsoH / 2 + 8),
        width: shoulderW,
        height: torsoH,
      ),
      topLeft: const Radius.circular(28),
      topRight: const Radius.circular(28),
      bottomLeft: const Radius.circular(14),
      bottomRight: const Radius.circular(14),
    );
    canvas.drawRRect(bodyRect, paint);

    // Center vertical alignment axis.
    final axisPaint = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(cx, size.height * 0.12),
      Offset(cx, size.height * 0.82),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(_GhostSilhouettePainter oldDelegate) =>
      oldDelegate.color != color;
}
