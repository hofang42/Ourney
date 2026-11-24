import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../../ui/ui.dart';
import '../../../domain/journey_form.dart';
import '../../../l10n/generated/journeys_localizations.dart';
import '../../widgets/departure_ticket.dart';
import '../create_type_option.dart';
import 'step_parts.dart';

/// Step 5: departure ticket preview and edit action.
class CreateReviewStep extends StatelessWidget {
  const CreateReviewStep({
    required this.form,
    required this.who,
    required this.optionIsCouple,
    required this.skinId,
    required this.title,
    required this.variant,
    required this.today,
    required this.start,
    required this.nameLeftController,
    required this.nameRightController,
    required this.onChangeVariant,
    required this.onEdit,
    super.key,
  });

  final JourneyForm form;
  final CreateWho who;
  final bool optionIsCouple;
  final String skinId;
  final String title;
  final int variant;
  final LocalDate today;
  final LocalDate? start;
  final TextEditingController nameLeftController;
  final TextEditingController nameRightController;
  final VoidCallback onChangeVariant;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final locale = Localizations.localeOf(context).toString();
    final days = form.durationDays;
    final hasDays = days != null && days > 0;
    final metric = form.trackMetric ? form.metricName.trim() : '';
    final goalLine = metric.isNotEmpty
        ? (form.metricUnit.trim().isEmpty
              ? metric
              : '$metric (${form.metricUnit.trim()})')
        : switch (form.template.id) {
            _ when optionIsCouple || who == CreateWho.couple =>
              l10n.journeys_tagCouple,
            TemplateId.weightLoss => l10n.journeys_tagWeightLoss,
            TemplateId.englishDaily => l10n.journeys_tagEnglish,
            TemplateId.travel => l10n.journeys_tagTravel,
            TemplateId.workout30 => l10n.journeys_tagWorkout,
            _ => l10n.journeys_tagCustom,
          };
    final s = start;
    final effectiveStart = s != null && !s.isBefore(today) ? s : today;
    final fmt = DateFormat.MMMd(locale);
    String d(LocalDate x) => fmt.format(DateTime(x.year, x.month, x.day));
    final datesLabel = hasDays
        ? l10n.journeys_ticketDates(
            d(effectiveStart),
            d(effectiveStart.addDays(days - 1)),
          )
        : l10n.journeys_ticketDatesOpen(d(effectiveStart));
    final milestones = !hasDays || days < 3
        ? const <String>[]
        : {
            for (final n in [7, days ~/ 2, days])
              if (n >= 1 && n <= days) l10n.journeys_ticketMilestone('$n'),
          }.toList();
    final couple = who == CreateWho.couple;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeading(l10n.journeys_createReviewTitle),
        KeyedSubtree(
          key: const ValueKey('journey-create-design-preview'),
          child: Semantics(
            container: true,
            label: l10n.journeys_ticketPreview,
            child: UiFadeThroughSwitcher(
              duration: UiMotion.sheetEnter,
              animateSize: true,
              alignment: Alignment.topCenter,
              child: DepartureTicket(
                key: ValueKey('ticket-$skinId'),
                skinId: skinId,
                variant: variant,
                title: title,
                goalLine: goalLine,
                durationLabel: hasDays
                    ? l10n.journeys_templateDays(days)
                    : l10n.journeys_ticketOpenEnded,
                datesLabel: datesLabel,
                milestones: milestones,
                leftName: couple && nameLeftController.text.trim().isNotEmpty
                    ? nameLeftController.text.trim()
                    : l10n.journeys_ticketYou,
                rightName:
                    couple && nameRightController.text.trim().isNotEmpty
                    ? nameRightController.text.trim()
                    : l10n.journeys_ticketPartner,
                privateLabel: l10n.journeys_ticketPrivate,
                memoryLabel: l10n.journeys_ticketMemory,
                tagline: switch (skinId) {
                  'quiet' => l10n.journeys_ticketTagQuiet,
                  'squad' => l10n.journeys_ticketTagSquad,
                  'memory' => l10n.journeys_ticketTagMemory,
                  'couple' => l10n.journeys_ticketTagCouple,
                  'flexer' => l10n.journeys_ticketTagFlexer,
                  _ => '',
                },
                changeVariantLabel: l10n.journeys_ticketChangeColor,
                onChangeVariant: onChangeVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: UiSpace.md),
        UiButton.secondary(
          key: const ValueKey('create-review-edit'),
          label: l10n.journeys_createReviewEdit,
          onPressed: onEdit,
        ),
      ],
    );
  }
}
