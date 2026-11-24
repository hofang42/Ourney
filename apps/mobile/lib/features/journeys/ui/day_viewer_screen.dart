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
import 'journey_extras.dart';
import 'journey_photo.dart';

/// `/journey/:id/day/:date`: the caller's photos of that day (swipe through
/// several, B-B6) with caption and metric, on the camera black. The metric starts
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
  // Created once the day's photos are known: it opens on the latest one.
  PageController? _pages;
  int _page = 0;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  static const _muted = UiCamera.muted;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    final journey = ref.watch(journeyByIdProvider(widget.journeyId)).value;
    final membership = ref.watch(myMembershipProvider(widget.journeyId)).value;
    final checkIns = ref.watch(myCheckInsProvider(widget.journeyId));
    final date = widget.date;
    // Every photo of the day, oldest first (several a day since `0014`).
    final dayCheckIns = date == null
        ? const <CheckIn>[]
        : ([
            for (final c in checkIns.value ?? const <CheckIn>[])
              if (c.localDate == date) c,
          ]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt)));
    final count = dayCheckIns.length;
    if (count > 0 && _pages == null) {
      _page = count - 1;
      _pages = PageController(initialPage: count - 1);
    }
    final index = count == 0 ? 0 : _page.clamp(0, count - 1);
    final checkIn = count == 0 ? null : dayCheckIns[index];

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
                glyph: const OurneyIcon(
                  name: 'back',
                  size: 21,
                  flat: true,
                  color: UiCamera.ink,
                ),
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
                    ? UiSpinner(
                        color: UiCamera.ink,
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      key: const ValueKey('journey-day-pages'),
                      controller: _pages,
                      itemCount: count,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) {
                        final c = dayCheckIns[i];
                        return Semantics(
                          image: true,
                          label: c.caption ?? dateText,
                          child: JourneyPhoto(
                            key: i == index
                                ? const ValueKey('journey-day-photo')
                                : null,
                            checkIn: c,
                            thumbnail: false,
                            fallback: Center(
                              child: Text(
                                l10n.journeys_photoUnavailable,
                                style: UiText.body(size: 14, color: _muted),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (count > 1)
                      Positioned(
                        right: UiSpace.sm,
                        bottom: UiSpace.sm,
                        child: Semantics(
                          label: l10n.journeys_dayPhotoCountSemantics(
                            index + 1,
                            count,
                          ),
                          excludeSemantics: true,
                          child: Container(
                            key: const ValueKey('journey-day-counter'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: UiSpace.sm,
                              vertical: UiSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: UiCamera.bg.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(
                                UiRadius.capsule,
                              ),
                            ),
                            child: Text(
                              l10n.journeys_dayPhotoCount(index + 1, count),
                              style: UiText.body(
                                size: 12,
                                weight: FontWeight.w700,
                                height: 1.3,
                                color: UiCamera.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: UiSpace.lg),
            if (checkIn.fromLibrary)
              Row(
                children: [
                  OurneyIcon(
                    name: 'gallery',
                    size: 18,
                    flat: true,
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
            if (journeyExtrasParts(context, checkIn.extras) case final parts
                when parts.isNotEmpty) ...[
              const SizedBox(height: UiSpace.sm),
              Text(
                parts.join(' · '),
                key: const ValueKey('journey-day-extras'),
                style: UiText.body(size: 14, height: 1.45, color: _muted),
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
            style: UiText.body(size: 14, height: 1.4, color: UiCamera.muted),
          ),
        if (hidden) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OurneyIcon(
                name: 'eye-off',
                size: 18,
                flat: true,
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
