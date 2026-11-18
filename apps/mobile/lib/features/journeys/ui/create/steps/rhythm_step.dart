import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../../ui/ui.dart';
import '../../../domain/journey_form.dart';
import '../../../l10n/generated/journeys_localizations.dart';
import '../create_type_option.dart';
import '../create_widgets.dart';
import 'step_parts.dart';

/// Step 4: duration, start date calendar, and visibility.
class CreateRhythmStep extends StatelessWidget {
  const CreateRhythmStep({
    required this.form,
    required this.who,
    required this.localOnly,
    required this.showErrors,
    required this.today,
    required this.start,
    required this.durationController,
    required this.onUpdate,
    required this.onPickStart,
    super.key,
  });

  final JourneyForm form;
  final CreateWho who;
  final bool localOnly;
  final bool showErrors;
  final LocalDate today;
  final LocalDate? start;
  final TextEditingController durationController;
  final void Function(void Function(JourneyForm f) change) onUpdate;
  final ValueChanged<LocalDate> onPickStart;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final errors = form.validate();
    final durationError = showErrors && errors.duration != null
        ? l10n.journeys_errorDuration(durationMin, durationMax)
        : null;
    final s = start;
    final effectiveStart = s != null && !s.isBefore(today) ? s : today;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeading(l10n.journeys_createRhythmTitle),
        Text(
          l10n.journeys_fieldDuration,
          style: UiText.fieldLabel(color: context.ui.inkMuted),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
          children: [
            for (final d in journeyDurationChoices)
              CreateDurationChip(
                key: ValueKey('journey-duration-$d'),
                label: l10n.journeys_templateDays(d),
                selected: form.durationDays == d,
                onPressed: () => onUpdate((f) {
                  f.durationDays = d;
                  durationController.text = '$d';
                }),
              ),
            if (form.allowOpenEnded)
              CreateDurationChip(
                key: const ValueKey('journey-duration-open'),
                label: l10n.journeys_openEnded,
                selected: form.durationDays == null,
                onPressed: () => onUpdate((f) {
                  f.durationDays = null;
                  durationController.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: UiSpace.md),
        UiTextField(
          fieldKey: const ValueKey('journey-duration'),
          label: l10n.journeys_durationCustom,
          controller: durationController,
          error: durationError,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => onUpdate((f) {
            final n = int.tryParse(v);
            f.durationDays = n ?? (f.allowOpenEnded ? null : 0);
          }),
        ),
        StepLabel(l10n.journeys_fieldStartDate),
        CreateCalendar(
          today: today,
          start: effectiveStart,
          days: form.durationDays != null && form.durationDays! > 0
              ? form.durationDays
              : null,
          locale: locale,
          prevLabel: l10n.journeys_calendarPrev,
          nextLabel: l10n.journeys_calendarNext,
          onPick: (d) => onPickStart(d),
        ),
        StepLabel(l10n.journeys_fieldVisibility),
        if (who == CreateWho.solo) ...[
          Wrap(
            spacing: UiSpace.sm,
            runSpacing: UiSpace.sm,
            children: [
              UiChip(
                key: const ValueKey('journey-visibility-private'),
                label: l10n.journeys_visibilityPrivate,
                glyph: const OurneyIcon(name: 'lock', size: 16),
                selected: form.soloVisibility == JourneyVisibility.private,
                onPressed: () => onUpdate(
                  (f) => f.soloVisibility = JourneyVisibility.private,
                ),
              ),
              UiChip(
                key: const ValueKey('journey-visibility-link'),
                label: l10n.journeys_visibilityLink,
                glyph: const OurneyIcon(name: 'share', size: 16),
                selected: form.soloVisibility == JourneyVisibility.link,
                onPressed: localOnly
                    ? null
                    : () => onUpdate(
                        (f) => f.soloVisibility = JourneyVisibility.link,
                      ),
              ),
            ],
          ),
          if (localOnly)
            StepNote(icon: 'cloud-off', text: l10n.journeys_linkNeedsServer),
        ] else
          StepNote(
            icon: 'lock',
            text: who == CreateWho.group
                ? l10n.journeys_visibilityGroup
                : l10n.journeys_kindCouple,
          ),
      ],
    );
  }
}
