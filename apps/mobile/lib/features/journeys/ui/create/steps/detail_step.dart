import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../../ui/ui.dart';
import '../../../domain/journey_form.dart';
import '../../../l10n/generated/journeys_localizations.dart';
import 'step_parts.dart';

/// Step 2 (part B): journey title, icon, metric tracking and share blur.
class CreateDetailStep extends StatelessWidget {
  const CreateDetailStep({
    required this.form,
    required this.titleController,
    required this.metricNameController,
    required this.metricUnitController,
    required this.showErrors,
    required this.onUpdate,
    super.key,
  });

  final JourneyForm form;
  final TextEditingController titleController;
  final TextEditingController metricNameController;
  final TextEditingController metricUnitController;
  final bool showErrors;
  final void Function(void Function(JourneyForm f) change) onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final errors = form.validate();
    final titleError = switch (showErrors ? errors.title : null) {
      JourneyTitleError.empty => l10n.journeys_errorTitleEmpty,
      JourneyTitleError.tooLong => l10n.journeys_errorTitleTooLong(
        journeyTitleMax,
      ),
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeading(l10n.journeys_createDetailTitle),
        UiTextField(
          fieldKey: const ValueKey('journey-title'),
          label: l10n.journeys_fieldTitle,
          hint: l10n.journeys_fieldTitle,
          controller: titleController,
          error: titleError,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (v) => onUpdate((f) => f.title = v),
        ),
        StepLabel(l10n.journeys_fieldEmoji),
        Wrap(
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
          children: [
            for (final e in {form.template.emoji, ...journeyEmojiChoices})
              EmojiChoice(
                emoji: e,
                template: form.template.id,
                selected: form.emoji == e,
                onTap: () => onUpdate((f) => f.emoji = e),
              ),
          ],
        ),
        StepLabel(l10n.journeys_fieldMetric),
        UiSwitchRow(
          key: const ValueKey('journey-metric'),
          label: l10n.journeys_fieldMetric,
          subtitle: l10n.journeys_fieldMetricHint,
          value: form.trackMetric,
          onChanged: (v) => onUpdate((f) => f.trackMetric = v),
        ),
        if (form.trackMetric) ...[
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('journey-metric-name'),
            label: l10n.journeys_metricName,
            controller: metricNameController,
            error: showErrors && errors.metricName == true
                ? l10n.journeys_errorMetricName
                : null,
            onChanged: (v) => onUpdate((f) => f.metricName = v),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('journey-metric-unit'),
            label: l10n.journeys_metricUnit,
            controller: metricUnitController,
            onChanged: (v) => onUpdate((f) => f.metricUnit = v),
          ),
          UiSwitchRow(
            key: const ValueKey('journey-hide-metric'),
            label: l10n.journeys_hideMetric,
            value: form.hideMetric,
            onChanged: (v) => onUpdate((f) => f.hideMetric = v),
          ),
        ],
        UiSwitchRow(
          key: const ValueKey('journey-blur'),
          label: l10n.journeys_blurOnShare,
          value: form.blurOnShare,
          onChanged: (v) => onUpdate((f) => f.blurOnShare = v),
        ),
      ],
    );
  }
}
