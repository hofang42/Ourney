import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_photo.dart';

/// `/journey/:id/day/:date`: full photo of the caller's check-in for that
/// day with caption and metric. The metric starts hidden when the journey or
/// the caller hides it (FR-B7) and can be revealed on this device.
class DayViewerScreen extends ConsumerStatefulWidget {
  const DayViewerScreen({
    required this.journeyId,
    required this.date,
    super.key,
  });

  final String journeyId;
  final LocalDate? date;

  static LocalDate? parseDate(String? raw) {
    if (raw == null) return null;
    try {
      return LocalDate.parse(raw);
    } on FormatException {
      return null;
    }
  }

  @override
  ConsumerState<DayViewerScreen> createState() => _DayViewerScreenState();
}

class _DayViewerScreenState extends ConsumerState<DayViewerScreen> {
  bool _revealMetric = false;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final dark = OurneyColors.dark;
    final journey = ref.watch(journeyByIdProvider(widget.journeyId)).value;
    final membership = ref.watch(myMembershipProvider(widget.journeyId)).value;
    final checkIns = ref.watch(myCheckInsProvider(widget.journeyId));
    final date = widget.date;
    CheckIn? checkIn;
    if (date != null) {
      for (final c in checkIns.value ?? const <CheckIn>[]) {
        if (c.localDate == date &&
            (checkIn == null || c.capturedAt.isAfter(checkIn.capturedAt))) {
          checkIn = c;
        }
      }
    }

    final hidden =
        (membership?.hideMetric ?? journey?.hideMetricDefault ?? false) &&
        !_revealMetric;
    final text = Theme.of(context).textTheme;
    final dateText = date == null
        ? ''
        : MaterialLocalizations.of(context).formatFullDate(displayDate(date));

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: OurneyColors.cameraBg,
        appBarTheme: Theme.of(context).appBarTheme.copyWith(
          backgroundColor: OurneyColors.cameraBg,
          foregroundColor: dark.ink,
        ),
      ),
      child: Scaffold(
        key: const ValueKey('journey-day-viewer'),
        appBar: AppBar(
          title: Text(dateText, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: SafeArea(
          child: checkIn == null
              ? Center(
                  child: checkIns.isLoading
                      ? CircularProgressIndicator(
                          semanticsLabel: app.common_loading,
                        )
                      : Text(
                          l10n.journeys_noCheckIn,
                          style: text.bodyLarge?.copyWith(color: dark.ink),
                        ),
                )
              : ListView(
                  padding: const EdgeInsets.all(OurneySpacing.lg),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(OurneyRadii.media),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Semantics(
                          image: true,
                          label: checkIn.caption ?? dateText,
                          child: JourneyPhoto(
                            key: const ValueKey('journey-day-photo'),
                            checkIn: checkIn,
                            thumbnail: false,
                            fallback: Center(
                              child: Text(
                                l10n.journeys_photoUnavailable,
                                style: text.bodyMedium?.copyWith(
                                  color: dark.inkMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: OurneySpacing.lg),
                    if (checkIn.fromLibrary)
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library_rounded,
                            size: 18,
                            color: dark.inkMuted,
                          ),
                          const SizedBox(width: OurneySpacing.xs),
                          Text(
                            l10n.journeys_fromLibrary,
                            style: text.bodySmall?.copyWith(
                              color: dark.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    if (checkIn.caption != null &&
                        checkIn.caption!.isNotEmpty) ...[
                      const SizedBox(height: OurneySpacing.sm),
                      Text(
                        checkIn.caption!,
                        key: const ValueKey('journey-day-caption'),
                        style: text.bodyLarge?.copyWith(color: dark.ink),
                      ),
                    ],
                    if (checkIn.metricValue != null) ...[
                      const SizedBox(height: OurneySpacing.md),
                      _MetricRow(
                        name: journey?.metricName,
                        unit: journey?.metricUnit,
                        value: checkIn.metricValue!,
                        hidden: hidden,
                        onReveal: () => setState(() => _revealMetric = true),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.name,
    required this.unit,
    required this.value,
    required this.hidden,
    required this.onReveal,
  });

  final String? name;
  final String? unit;
  final double value;
  final bool hidden;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final dark = OurneyColors.dark;
    final text = Theme.of(context).textTheme;
    final number = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    final shown = [number, if (unit != null) unit].join(' ');
    return Wrap(
      key: const ValueKey('journey-day-metric'),
      spacing: OurneySpacing.sm,
      runSpacing: OurneySpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (name != null)
          Text(
            '$name:',
            style: text.bodyMedium?.copyWith(color: dark.inkMuted),
          ),
        if (hidden) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_off_rounded, size: 18, color: dark.ink),
              const SizedBox(width: OurneySpacing.xs),
              Text(
                l10n.journeys_metricHidden,
                style: text.titleMedium?.copyWith(color: dark.ink),
              ),
            ],
          ),
          TextButton(
            key: const ValueKey('journey-day-reveal'),
            onPressed: onReveal,
            child: Text(l10n.journeys_showMetric),
          ),
        ] else
          Text(shown, style: text.titleMedium?.copyWith(color: dark.ink)),
      ],
    );
  }
}
