import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart' show displayStyle;
import '../../app/theme/motion.dart';
import '../../app/theme/persona_theme.dart';
import '../../shared/layout.dart';
import '../persona_contract.dart';
import '../quiet_transformer/metric_curve_painter.dart';
import 'l10n/generated/aesthetic_flexer_localizations.dart';

/// Overlay styles selectable on the [StravaStickerStudioHud] (`docs/TASKS.md` R2).
enum StravaStickerStyle { boldHud, minimalStamp, filmStrip }

/// **Task R2** (`PersonaSkinId.aestheticFlexer` — `stravaStickerStudio`):
/// - Full-bleed workout viewfinder with a transparent Bricolage Grotesque
///   telemetry overlay (`DAY N · 🔥 STREAK` + metric when available).
/// - Interactive style selector pills (`Bold HUD`, `Minimal Stamp`, `Film Strip`)
///   that switch the overlay style in place without touching the raw photo file.
class StravaStickerStudioHud extends StatefulWidget {
  const StravaStickerStudioHud({required this.data, super.key});

  final PersonaCameraData data;

  @override
  State<StravaStickerStudioHud> createState() => _StravaStickerStudioHudState();
}

class _StravaStickerStudioHudState extends State<StravaStickerStudioHud> {
  StravaStickerStyle _style = StravaStickerStyle.boldHud;

  int get _dayNumber {
    final d = widget.data.journey.startDate.daysUntil(widget.data.date) + 1;
    return d < 1 ? 1 : d;
  }

  void _selectStyle(StravaStickerStyle next) {
    if (_style == next) return;
    OurneyHaptics.selection();
    setState(() => _style = next);
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = AestheticFlexerL10n.of(context);
    final dayDigits = _dayNumber.toString().padLeft(2, '0');
    final streak = widget.data.currentStreak;
    final metricVal = widget.data.hideMetric ? null : widget.data.metricValue;
    final metricStr = metricVal == null
        ? null
        : MetricSeries.formatValue(metricVal, widget.data.journey.metricUnit);

    return Stack(
      key: const ValueKey('r2-strava-sticker-studio-hud'),
      fit: StackFit.expand,
      children: [
        widget.data.viewfinder,
        // Telemetry sticker overlay (never burned into the raw JPEG).
        IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 68),
            child: _TelemetryOverlay(
              key: ValueKey('r2-overlay-${_style.name}'),
              style: _style,
              title: widget.data.journey.title,
              dayLabel: l10n.aesthetic_flexer_milestoneDay(dayDigits),
              streakLabel: '🔥 ${l10n.aesthetic_flexer_streakLabel(streak)}',
              metricLabel: metricStr,
              pTheme: pTheme,
            ),
          ),
        ),
        // Bottom style switcher pills (Bold HUD | Minimal Stamp | Film Strip).
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StylePill(
                    key: const ValueKey('r2-pill-boldHud'),
                    label: l10n.aesthetic_flexer_styleBoldHud,
                    selected: _style == StravaStickerStyle.boldHud,
                    onTap: () => _selectStyle(StravaStickerStyle.boldHud),
                  ),
                  const SizedBox(width: 6),
                  _StylePill(
                    key: const ValueKey('r2-pill-minimalStamp'),
                    label: l10n.aesthetic_flexer_styleMinimalStamp,
                    selected: _style == StravaStickerStyle.minimalStamp,
                    onTap: () => _selectStyle(StravaStickerStyle.minimalStamp),
                  ),
                  const SizedBox(width: 6),
                  _StylePill(
                    key: const ValueKey('r2-pill-filmStrip'),
                    label: l10n.aesthetic_flexer_styleFilmStrip,
                    selected: _style == StravaStickerStyle.filmStrip,
                    onTap: () => _selectStyle(StravaStickerStyle.filmStrip),
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

class _TelemetryOverlay extends StatelessWidget {
  const _TelemetryOverlay({
    required this.style,
    required this.title,
    required this.dayLabel,
    required this.streakLabel,
    required this.metricLabel,
    required this.pTheme,
    super.key,
  });

  final StravaStickerStyle style;
  final String title;
  final String dayLabel;
  final String streakLabel;
  final String? metricLabel;
  final OurneyPersonaTheme pTheme;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      StravaStickerStyle.boldHud => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: pTheme.primaryAccent.withValues(alpha: 0.8),
              ),
            ),
            child: Text(
              '$dayLabel · $streakLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: displayStyle(
                    size: 16,
                    weight: 800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                if (metricLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    metricLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: displayStyle(
                      size: 18,
                      weight: 800,
                      color: pTheme.secondaryAccent,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      StravaStickerStyle.minimalStamp => Align(
        alignment: AlignmentDirectional.topStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            [dayLabel, streakLabel, ?metricLabel].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      StravaStickerStyle.filmStrip => Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(8),
            border: Border.symmetric(
              horizontal: BorderSide(color: pTheme.secondaryAccent, width: 1.5),
            ),
          ),
          child: Text(
            '▣ $dayLabel · $streakLabel${metricLabel != null ? ' · $metricLabel' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pTheme.secondaryAccent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ),
      ),
    };
  }
}

class _StylePill extends StatelessWidget {
  const _StylePill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pTheme = OurneyPersonaTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: OurneyLayout.minTouchTarget,
            minWidth: OurneyLayout.minTouchTarget,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? pTheme.primaryAccent
                    : Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? pTheme.primaryAccent : Colors.white30,
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
