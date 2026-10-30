import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../data/journeys_providers.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_photo.dart';

/// `/journey/:id/day/:date`: full photo of the caller's check-in for that
/// day with caption and metric, on the camera black. The metric starts
/// hidden when the journey or the caller hides it (FR-B7) and can be
/// revealed on this device.
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

  static const _muted = Color(0xFFA1A1AA);

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
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
    final dateText = date == null
        ? ''
        : MaterialLocalizations.of(context).formatFullDate(displayDate(date));

    return UiScaffold(
      key: const ValueKey('journey-day-viewer'),
      background: UiCamera.bg,
      padTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              UiIconButton(
                icon: Icons.arrow_back_rounded,
                label: l10n.journeys_back,
                color: UiCamera.ink,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.journey(widget.journeyId)),
              ),
              Expanded(
                child: Text(
                  dateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: UiText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    height: 1.4,
                    color: UiCamera.ink,
                  ),
                ),
              ),
              const SizedBox(width: UiSize.tap),
            ],
          ),
          const SizedBox(height: UiSpace.sm),
          if (checkIn == null)
            Padding(
              padding: const EdgeInsets.only(top: 120),
              child: Center(
                child: checkIns.isLoading
                    ? CircularProgressIndicator(
                        semanticsLabel: app.common_loading,
                      )
                    : Text(
                        l10n.journeys_noCheckIn,
                        textAlign: TextAlign.center,
                        style: UiText.body(
                          size: 16,
                          height: 1.5,
                          color: UiCamera.ink,
                        ),
                      ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(UiRadius.card),
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
                        style: UiText.body(size: 14, color: _muted),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: UiSpace.lg),
            if (checkIn.fromLibrary)
              Row(
                children: [
                  const Icon(
                    Icons.photo_library_rounded,
                    size: 18,
                    color: _muted,
                  ),
                  const SizedBox(width: UiSpace.xs),
                  Flexible(
                    child: Text(
                      l10n.journeys_fromLibrary,
                      style: UiText.body(size: 12, color: _muted),
                    ),
                  ),
                ],
              ),
            if (checkIn.caption != null && checkIn.caption!.isNotEmpty) ...[
              const SizedBox(height: UiSpace.sm),
              Text(
                checkIn.caption!,
                key: const ValueKey('journey-day-caption'),
                style: UiText.body(size: 16, height: 1.5, color: UiCamera.ink),
              ),
            ],
            if (checkIn.metricValue != null) ...[
              const SizedBox(height: UiSpace.md),
              _MetricRow(
                name: journey?.metricName,
                unit: journey?.metricUnit,
                value: checkIn.metricValue!,
                hidden: hidden,
                onReveal: () => setState(() => _revealMetric = true),
              ),
            ],
          ],
        ],
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
    final number = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    final shown = [number, ?unit].join(' ');
    final strong = UiText.body(
      size: 16,
      weight: FontWeight.w700,
      height: 1.4,
      color: UiCamera.ink,
    );
    return Wrap(
      key: const ValueKey('journey-day-metric'),
      spacing: UiSpace.sm,
      runSpacing: UiSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (name != null)
          Text(
            '$name:',
            style: UiText.body(
              size: 14,
              height: 1.4,
              color: const Color(0xFFA1A1AA),
            ),
          ),
        if (hidden) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_off_rounded,
                size: 18,
                color: UiCamera.ink,
              ),
              const SizedBox(width: UiSpace.xs),
              Text(l10n.journeys_metricHidden, style: strong),
            ],
          ),
          UiTextAction(
            key: const ValueKey('journey-day-reveal'),
            label: l10n.journeys_showMetric,
            color: UiCamera.ink,
            underline: true,
            onPressed: onReveal,
          ),
        ] else
          Text(shown, style: strong),
      ],
    );
  }
}
