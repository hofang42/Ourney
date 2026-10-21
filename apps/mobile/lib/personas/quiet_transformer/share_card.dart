import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/persona_theme.dart';
import '../../features/journeys/ui/journey_photo.dart';
import '../../shared/dashed_placeholder.dart';
import '../../shared/layout.dart';
import '../../shared/ourney_primary_button.dart';
import '../../shared/persona_pill.dart';
import '../persona_contract.dart';
import 'l10n/generated/quiet_transformer_localizations.dart';
import 'metric_curve_painter.dart';

/// **Task Q3** (`PersonaSkinId.quietTransformer` — `sideBySideArchive`):
/// - Side-by-side `DAY 01` vs `DAY N` split comparison frame.
/// - `SwitchListTile` for **"Hide Exact Weight"** (defaults to
///   `data.hideMetric || data.journey.hideMetricDefault` per FR-B7, and user-toggleable).
/// - `Export Progress Card` primary CTA calling `data.onShare`.
class SideBySideArchiveShareCard extends StatefulWidget {
  const SideBySideArchiveShareCard({required this.data, super.key});

  final PersonaShareData data;

  @override
  State<SideBySideArchiveShareCard> createState() =>
      _SideBySideArchiveShareCardState();
}

class _SideBySideArchiveShareCardState
    extends State<SideBySideArchiveShareCard> {
  late bool _hideExactWeight;

  @override
  void initState() {
    super.initState();
    _hideExactWeight =
        widget.data.hideMetric || widget.data.journey.hideMetricDefault;
  }

  @override
  void didUpdateWidget(SideBySideArchiveShareCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.hideMetric != oldWidget.data.hideMetric) {
      _hideExactWeight = widget.data.hideMetric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = QuietTransformerL10n.of(context);
    final sorted = widget.data.sortedCheckIns;
    final first = sorted.firstOrNull;
    final latest = sorted.length >= 2 ? sorted.last : null;
    final unit = widget.data.journey.metricUnit;
    final hasMetric = widget.data.journey.metricName != null;

    final startVal = first?.metricValue;
    final endVal = (latest ?? first)?.metricValue;
    final delta = (startVal != null && endVal != null && latest != null)
        ? (endVal - startVal)
        : null;

    final dayDigits = widget.data.dayNumber.toString().padLeft(2, '0');

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pad = OurneyLayout.cardPadding(width);
        final gap = OurneyLayout.gridSpacing(width);

        return Container(
          key: const ValueKey('q3-side-by-side-archive'),
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: pTheme.surface,
            borderRadius: BorderRadius.circular(pTheme.cardRadius),
            border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PersonaPill(
                    icon: Icons.lock_rounded,
                    label: l10n.quiet_transformer_name,
                  ),
                  if (delta != null && !_hideExactWeight)
                    PersonaPill(
                      key: const ValueKey('q3-delta-pill'),
                      emphasized: true,
                      label: l10n.quiet_transformer_transformationBadge(
                        MetricSeries.formatDelta(delta, unit),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.data.journey.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: displayStyle(
                  size: 19,
                  weight: 700,
                  color: pTheme.ink,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              // Side-by-side Day 01 vs Day N comparison frame.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ComparisonFrame(
                      key: const ValueKey('q3-frame-start'),
                      badge: l10n.quiet_transformer_compareDayStart,
                      checkIn: first,
                      metricLabel: _formatFrameMetric(
                        first?.metricValue,
                        unit: unit,
                        hidden: _hideExactWeight || !hasMetric,
                      ),
                      waitingLabel: l10n.quiet_transformer_waitingPhoto,
                      photoBuilder: widget.data.photoBuilder,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _ComparisonFrame(
                      key: const ValueKey('q3-frame-latest'),
                      badge: l10n.quiet_transformer_compareDayNow(dayDigits),
                      checkIn: latest ?? (sorted.length == 1 ? null : latest),
                      metricLabel: _formatFrameMetric(
                        latest?.metricValue,
                        unit: unit,
                        hidden: _hideExactWeight || !hasMetric,
                      ),
                      waitingLabel: l10n.quiet_transformer_waitingPhoto,
                      photoBuilder: widget.data.photoBuilder,
                      highlight: true,
                    ),
                  ),
                ],
              ),
              if (hasMetric) ...[
                const SizedBox(height: 10),
                SwitchListTile(
                  key: const ValueKey('q3-hide-metric-switch'),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: pTheme.primaryAccent,
                  title: Text(
                    l10n.quiet_transformer_hideExactWeight,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pTheme.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  subtitle: Text(
                    l10n.quiet_transformer_hideExactWeightSub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pTheme.inkMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  value: _hideExactWeight,
                  onChanged: (v) => setState(() => _hideExactWeight = v),
                ),
              ],
              const SizedBox(height: 12),
              OurneyPrimaryButton(
                key: const ValueKey('q3-export-button'),
                label: l10n.quiet_transformer_exportCard,
                icon: Icons.ios_share_rounded,
                onPressed: widget.data.onShare,
              ),
              if (widget.data.publicLinkSection != null &&
                  widget.data.journey.kind == JourneyKind.solo) ...[
                const SizedBox(height: 12),
                widget.data.publicLinkSection!,
              ],
            ],
          ),
        );
      },
    );
  }

  static String? _formatFrameMetric(
    double? value, {
    required String? unit,
    required bool hidden,
  }) {
    if (value == null) return null;
    if (hidden) return '•••';
    return MetricSeries.formatValue(value, unit);
  }
}

class _ComparisonFrame extends StatelessWidget {
  const _ComparisonFrame({
    required this.badge,
    required this.checkIn,
    required this.metricLabel,
    required this.waitingLabel,
    required this.photoBuilder,
    this.highlight = false,
    super.key,
  });

  final String badge;
  final CheckIn? checkIn;
  final String? metricLabel;
  final String waitingLabel;
  final PersonaCheckInPhotoBuilder? photoBuilder;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: pTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? pTheme.primaryAccent : pTheme.border,
          width: highlight ? 1.5 : pTheme.borderWidth,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: highlight ? pTheme.primaryAccent : pTheme.ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: checkIn != null
                  ? (photoBuilder != null
                        ? photoBuilder!(context, checkIn!)
                        : JourneyPhoto(checkIn: checkIn!))
                  : DashedPlaceholder(
                      icon: Icons.photo_camera_outlined,
                      label: waitingLabel,
                      aspectRatio: 3 / 4,
                      radius: 10,
                    ),
            ),
          ),
          if (metricLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              metricLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: pTheme.ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
