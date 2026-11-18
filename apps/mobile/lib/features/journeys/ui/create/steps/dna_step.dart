import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../ui/ui.dart';
import '../../../l10n/generated/journeys_localizations.dart';
import '../dna_pages.dart';
import '../dna_questions.dart';
import '../dna_text.dart';
import 'step_parts.dart';

/// Step 2 (part A): template-specific "DNA" question pages before the form.
class CreateDnaStep extends StatelessWidget {
  const CreateDnaStep({
    required this.question,
    required this.dnaPage,
    required this.totalQuestions,
    required this.dna,
    required this.hideWeight,
    required this.trophyController,
    required this.placeController,
    required this.nameLeftController,
    required this.nameRightController,
    required this.habitController,
    required this.reasonController,
    required this.onSetDna,
    required this.onHideWeightChanged,
    required this.onAdvanceDna,
    required this.onApplyDates,
    super.key,
  });

  final DnaQuestion question;
  final int dnaPage;
  final int totalQuestions;
  final Map<String, Object> dna;
  final bool hideWeight;
  final TextEditingController trophyController;
  final TextEditingController placeController;
  final TextEditingController nameLeftController;
  final TextEditingController nameRightController;
  final TextEditingController habitController;
  final TextEditingController reasonController;
  final void Function(String key, Object value) onSetDna;
  final ValueChanged<bool> onHideWeightChanged;
  final VoidCallback onAdvanceDna;
  final ValueChanged<DnaDates> onApplyDates;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final l10n = JourneysL10n.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final Widget body = switch (question.kind) {
      DnaKind.choice => DnaChoiceList(
        question: question,
        value: dna[question.key] as String?,
        onChanged: (v) => onSetDna(question.key, v),
      ),
      DnaKind.weight => DnaWeightPicker(
        weight: (dna['weight'] as int?) ?? dnaWeightDefault,
        hide: hideWeight,
        onWeight: (v) => onSetDna('weight', v),
        onHide: onHideWeightChanged,
        onSkip: onAdvanceDna,
      ),
      DnaKind.ghost => DnaGhostPage(onLater: onAdvanceDna),
      DnaKind.trophy => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: OurneyIcon(name: 'trophy', size: 76)),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('dna-trophy'),
            label: l10n.journeys_dna_trophy_label,
            hint: l10n.journeys_dna_trophy_hint,
            controller: trophyController,
            inputFormatters: [LengthLimitingTextInputFormatter(dnaTrophyMax)],
            helper: '${trophyController.text.length}/$dnaTrophyMax',
            onChanged: (v) => onSetDna('trophy', v),
          ),
        ],
      ),
      DnaKind.place => DnaPlacePicker(
        controller: placeController,
        place: (dna['place'] as String?) ?? '',
        onChanged: (v) => onSetDna('place', v),
      ),
      DnaKind.dates => DnaDateRange(
        today: DateTime.now(),
        value: dna['dates'] as DnaDates?,
        locale: locale,
        onChanged: onApplyDates,
      ),
      DnaKind.names => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiTextField(
            fieldKey: const ValueKey('dna-name-left'),
            label: l10n.journeys_dna_name_left,
            hint: l10n.journeys_dna_name_left,
            controller: nameLeftController,
            inputFormatters: [LengthLimitingTextInputFormatter(dnaNameMax)],
            onChanged: (v) => onSetDna('nameLeft', v),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('dna-name-right'),
            label: l10n.journeys_dna_name_right,
            hint: l10n.journeys_dna_name_right,
            controller: nameRightController,
            inputFormatters: [LengthLimitingTextInputFormatter(dnaNameMax)],
            onChanged: (v) => onSetDna('nameRight', v),
          ),
        ],
      ),
      DnaKind.habit => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiTextField(
            fieldKey: const ValueKey('dna-habit'),
            label: l10n.journeys_dna_habit_label,
            hint: l10n.journeys_dna_habit_hint,
            controller: habitController,
            inputFormatters: [LengthLimitingTextInputFormatter(dnaHabitMax)],
            helper: '${habitController.text.length}/$dnaHabitMax',
            onChanged: (v) => onSetDna('habit', v),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('dna-reason'),
            label: l10n.journeys_dna_reason_label,
            hint: l10n.journeys_dna_reason_hint,
            controller: reasonController,
            inputFormatters: [LengthLimitingTextInputFormatter(dnaReasonMax)],
            helper: '${reasonController.text.length}/$dnaReasonMax',
            onChanged: (v) => onSetDna('reason', v),
          ),
        ],
      ),
    };
    return Column(
      key: ValueKey('dna-page-${question.key}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (totalQuestions > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.xs),
            child: Text(
              l10n.journeys_dna_step_of_q(dnaPage + 1, totalQuestions),
              key: const ValueKey('dna-question-count'),
              style: UiText.fieldLabel(color: ui.inkMuted),
            ),
          ),
        StepHeading(dnaText(l10n, question.titleId)),
        body,
      ],
    );
  }
}
