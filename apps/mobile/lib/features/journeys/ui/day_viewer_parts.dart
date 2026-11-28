import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../data/group_daily_checkins_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../domain/day_neighbors.dart';
import '../domain/journey_time.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_extras.dart';
import 'journey_photo.dart';

class DayViewerHeader extends StatelessWidget {
  const DayViewerHeader({
    required this.journey,
    required this.date,
    required this.checkIn,
    required this.now,
    required this.onBack,
    super.key,
  });
  final Journey? journey;
  final LocalDate? date;
  final CheckIn? checkIn;
  final DateTime now;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final material = MaterialLocalizations.of(context);
    var dateText = date == null
        ? ''
        : material.formatFullDate(displayDate(date!));
    if (date?.year == now.year) {
      dateText = dateText
          .replaceFirst(RegExp(r',?\s*' + date!.year.toString() + r'\s*'), '')
          .trim();
    }
    final ordinal = journey == null || date == null
        ? null
        : journeyDayOrdinal(journey!, date!);
    final total = journey?.durationDays;
    final subtitle = <String>[
      if (ordinal != null)
        total != null && ordinal <= total
            ? l10n.journeys_dayOf(ordinal, total)
            : l10n.journeys_dayOpen(ordinal),
      if (checkIn != null && !checkIn!.fromLibrary && journey != null)
        material.formatTimeOfDay(
          TimeOfDay.fromDateTime(
            checkIn!.capturedAt.toUtc().add(
              utcOffsetIn(journey!.timezone, checkIn!.capturedAt),
            ),
          ),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        ),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            UiIconButton(
              glyph: OurneyIcon(
                name: 'back',
                size: 21,
                flat: true,
                color: ui.ink,
              ),
              label: l10n.journeys_back,
              onPressed: onBack,
            ),
            if (journey != null) ...[
              uiJourneyGlyph(
                journey!.emoji,
                journey!.templateId,
                size: 22,
                color: ui.ink,
              ),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Semantics(
                  label: journey!.title,
                  excludeSemantics: true,
                  child: Text(
                    journey!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(size: 14, height: 1.3, color: ui.ink),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (dateText.isNotEmpty)
          Semantics(
            header: true,
            child: Text(
              dateText,
              style: UiText.heading(
                font:
                    UiSkinScope.maybeOf(context)?.headingFont ??
                    'Space Grotesk',
                size: 23,
                height: 1.3,
                color: ui.ink,
              ),
            ),
          ),
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: UiText.body(size: 14, height: 1.3, color: ui.inkMuted),
            ),
          ),
        const SizedBox(height: UiSpace.md),
      ],
    );
  }
}

/// Run/weight plan owns the content of this widget.
class DayFacts extends StatelessWidget {
  const DayFacts({required this.checkIn, required this.journey, super.key});
  final CheckIn checkIn;
  final Journey? journey;
  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final parts = journeyExtrasParts(context, checkIn.extras);
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.md),
      child: Column(
        key: const ValueKey('journey-day-chrome'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: UiSpace.md,
            runSpacing: UiSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (checkIn.fromLibrary)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OurneyIcon(
                      name: 'gallery',
                      size: 18,
                      flat: true,
                      color: context.ui.inkMuted,
                    ),
                    const SizedBox(width: UiSpace.xs),
                    Flexible(
                      child: Text(
                        l10n.journeys_fromLibrary,
                        style: UiText.body(
                          size: 12,
                          height: 1.3,
                          color: context.ui.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              if (parts.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OurneyIcon(
                      name: 'timer',
                      size: 18,
                      flat: true,
                      color: context.ui.inkMuted,
                    ),
                    const SizedBox(width: UiSpace.xs),
                    Flexible(
                      child: Text(
                        parts.join(' · '),
                        key: const ValueKey('journey-day-extras'),
                        style: UiText.body(
                          size: 14,
                          height: 1.45,
                          color: context.ui.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              if (checkIn.metricValue != null)
                _MetricRow(
                  name: journey?.metricName,
                  unit: journey?.metricUnit,
                  value: checkIn.metricValue!,
                ),
            ],
          ),
          if (checkIn.partnerPhotoPath != null &&
              (checkIn.uploaded || journey?.kind == JourneyKind.solo)) ...[
            const SizedBox(height: UiSpace.lg),
            Text(
              l10n.journeys_uploaderAttachment,
              style: UiText.body(
                size: 14,
                height: 1.4,
                color: context.ui.inkMuted,
              ),
            ),
            const SizedBox(height: UiSpace.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UiRadius.input),
                child: SizedBox.square(
                  dimension: 96,
                  child: JourneyPhoto(checkIn: checkIn, attachment: true),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DayCaptionSlot extends StatelessWidget {
  const DayCaptionSlot({required this.caption, super.key});
  final String? caption;
  @override
  Widget build(BuildContext context) {
    // Retell PR 2: add/edit caption control goes here (canEditCheckInCaption).
    if (caption == null || caption!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.sm),
      child: Text(
        caption!,
        key: const ValueKey('journey-day-caption'),
        style: UiText.body(size: 16, height: 1.45, color: context.ui.ink),
      ),
    );
  }
}

class DayPeopleSwitch extends StatelessWidget {
  const DayPeopleSwitch({
    required this.slots,
    required this.selectedId,
    required this.onSelect,
    super.key,
  });
  final List<CouplePhotoSlot> slots;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    String name(CouplePhotoSlot s) => s.isMine
        ? l10n.journeys_coupleYou
        : s.displayName ?? l10n.journeys_ticketPartner;
    String missing(CouplePhotoSlot s) => s.photoUnavailable
        ? l10n.journeys_photoUnavailable
        : l10n.journeys_dayPartnerNoPhoto(name(s));
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final (i, s) in slots.indexed) ...[
                if (i > 0) const SizedBox(width: UiSpace.sm),
                Expanded(
                  child: UiPressable(
                    key: ValueKey(('day-person-chip', i, s.userId)),
                    semanticLabel: s.checkIn == null ? missing(s) : name(s),
                    excludeChildSemantics: true,
                    selected: s.checkIn != null && s.checkIn!.id == selectedId,
                    onPressed: s.checkIn == null
                        ? null
                        : () => onSelect(s.checkIn!.id),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ui.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              s.checkIn != null && s.checkIn!.id == selectedId
                              ? ui.accent
                              : ui.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (s.checkIn != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                width: 24,
                                height: 32,
                                child: JourneyPhoto(checkIn: s.checkIn!),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              name(s),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.body(
                                size: 14,
                                height: 1.3,
                                color: s.checkIn == null ? ui.inkMuted : ui.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          for (final s in slots.where((s) => !s.isMine && s.checkIn == null))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                missing(s),
                style: UiText.body(size: 12, height: 1.3, color: ui.inkMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class DayNeighborNav extends StatelessWidget {
  const DayNeighborNav({
    required this.previous,
    required this.next,
    required this.onSelect,
    super.key,
  });
  final CheckIn? previous;
  final CheckIn? next;
  final ValueChanged<LocalDate> onSelect;
  @override
  Widget build(BuildContext context) {
    if (previous == null && next == null) return const SizedBox.shrink();
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget button(CheckIn photo, bool before) {
          final date = DateFormat.MMMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(displayDate(photo.localDate));
          return UiPressable(
            key: ValueKey(before ? 'day-previous' : 'day-next'),
            semanticLabel: before
                ? l10n.journeys_dayPreviousSemantics(date)
                : l10n.journeys_dayNextSemantics(date),
            excludeChildSemantics: true,
            onPressed: () => onSelect(photo.localDate),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: ui.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ui.border, width: 1.5),
              ),
              child: Row(
                children: [
                  if (before)
                    OurneyIcon(
                      name: 'back',
                      size: 16,
                      color: ui.ink,
                      flat: true,
                    ),
                  if (constraints.maxWidth >= 340) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 30,
                        height: 40,
                        child: JourneyPhoto(checkIn: photo),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          before
                              ? l10n.journeys_dayPrevious
                              : l10n.journeys_dayNext,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.body(
                            size: 11,
                            height: 1.3,
                            color: ui.inkMuted,
                          ),
                        ),
                        Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.body(
                            size: 13,
                            height: 1.3,
                            color: ui.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!before)
                    OurneyIcon(
                      name: 'chevron-right',
                      size: 16,
                      color: ui.ink,
                      flat: true,
                    ),
                ],
              ),
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: previous == null
                  ? const SizedBox.shrink()
                  : button(previous!, true),
            ),
            const SizedBox(width: UiSpace.sm),
            Expanded(
              child: next == null
                  ? const SizedBox.shrink()
                  : button(next!, false),
            ),
          ],
        );
      },
    );
  }
}

class DayEmptyState extends StatelessWidget {
  const DayEmptyState({
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpenJourney,
    this.onCheckIn,
    super.key,
  });
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onOpenJourney;
  final VoidCallback? onCheckIn;
  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final app = AppLocalizations.of(context);
    return UiCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              UiSpinner(
                color: context.ui.ink,
                semanticsLabel: app.common_loading,
              )
            else ...[
              OurneyIcon(
                name: 'image',
                size: 36,
                color: context.ui.inkMuted,
                flat: true,
              ),
              const SizedBox(height: UiSpace.md),
              Text(
                error ?? l10n.journeys_noCheckIn,
                key: error == null ? null : const ValueKey('journey-day-error'),
                textAlign: TextAlign.center,
                style: UiText.body(
                  size: 16,
                  height: 1.45,
                  color: context.ui.ink,
                ),
              ),
              const SizedBox(height: UiSpace.lg),
              if (error != null)
                UiButton.secondary(
                  key: const ValueKey('journey-day-retry'),
                  label: app.common_retry,
                  onPressed: onRetry,
                ),
              if (error == null && onCheckIn != null) ...[
                UiButton(label: l10n.journeys_checkInNow, onPressed: onCheckIn),
                const SizedBox(height: UiSpace.sm),
              ],
            ],
            if (loading || error != null) const SizedBox(height: UiSpace.sm),
            UiButton.secondary(
              label: l10n.journeys_dayOpenJourney,
              onPressed: onOpenJourney,
            ),
          ],
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
  });

  final String? name;
  final String? unit;
  final double value;

  @override
  Widget build(BuildContext context) {
    final number = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    final shown = [number, ?unit].join(' ');
    final strong = UiText.body(
      size: 16,
      weight: FontWeight.w700,
      height: 1.4,
      color: context.ui.ink,
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
              color: context.ui.inkMuted,
            ),
          ),
        Text(
          shown,
          key: const ValueKey('journey-day-metric-shown'),
          style: strong,
        ),
      ],
    );
  }
}
