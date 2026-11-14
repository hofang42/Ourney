import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../ui/ui.dart';
import 'l10n/generated/onboarding_localizations.dart';

/// The 3-question onboarding quiz (Figma `OnboardingFlow`): goal, company,
/// reminder time. Every answer is optional overall (the user can skip), but a
/// question needs an answer before "Continue" enables. [onDone] gets the
/// answers (null when skipped).
class OnboardingQuizStage extends StatefulWidget {
  const OnboardingQuizStage({
    required this.onDone,
    required this.gutter,
    super.key,
  });

  final ValueChanged<OnboardingQuiz?> onDone;
  final double gutter;

  static const questionCount = 3;

  @override
  State<OnboardingQuizStage> createState() => _OnboardingQuizStageState();
}

class _OnboardingQuizStageState extends State<OnboardingQuizStage> {
  int _step = 0;
  QuizGoal? _goal;
  QuizCompany? _company;
  String? _reminder;

  bool get _answered => switch (_step) {
    0 => _goal != null,
    1 => _company != null,
    _ => _reminder != null,
  };

  bool get _isLast => _step == OnboardingQuizStage.questionCount - 1;

  void _next() {
    if (!_answered) return;
    if (_isLast) {
      widget.onDone(
        OnboardingQuiz(goal: _goal, company: _company, reminder: _reminder),
      );
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = OnboardingL10n.of(context);
    final ui = context.ui;
    final title = [
      l10n.onboarding_quizQ1,
      l10n.onboarding_quizQ2,
      l10n.onboarding_quizQ3,
    ][_step];
    return Column(
      key: ValueKey('onboarding-quiz-$_step'),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.gutter),
          child: Row(
            children: [
              if (_step > 0)
                UiIconButton(
                  key: const ValueKey('onboarding-quiz-back'),
                  glyph: const OurneyIcon(name: 'chevron-left', flat: true),
                  label: l10n.onboarding_quizBack,
                  onPressed: () => setState(() => _step--),
                )
              else
                const SizedBox(width: UiSize.tap, height: UiSize.tap),
              Expanded(
                child: Center(
                  child: Text(
                    l10n.onboarding_quizStep(_step + 1),
                    style: UiText.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: ui.ink,
                    ),
                  ),
                ),
              ),
              UiTextAction(
                key: const ValueKey('onboarding-quiz-skip'),
                label: l10n.onboarding_skip,
                onPressed: () => widget.onDone(null),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              widget.gutter,
              UiSpace.lg,
              widget.gutter,
              UiSpace.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: UiText.h1(color: ui.ink)),
                ),
                const SizedBox(height: UiSpace.xl),
                ...switch (_step) {
                  0 => _goalOptions(l10n),
                  1 => _companyOptions(l10n),
                  _ => _reminderOptions(l10n),
                },
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(widget.gutter, 6, widget.gutter, 28),
          child: UiButton(
            key: const ValueKey('onboarding-quiz-next'),
            label: _isLast && _answered
                ? l10n.onboarding_quizStart
                : l10n.onboarding_quizContinue,
            onPressed: _answered ? _next : null,
          ),
        ),
      ],
    );
  }

  Widget _option({
    required Key key,
    required String label,
    String? hint,
    String? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.md),
      child: Semantics(
        selected: selected,
        child: UiCard(
          key: key,
          radius: UiRadius.card,
          padding: const EdgeInsets.all(UiSpace.lg),
          borderColor: selected ? ui.brand : null,
          onPressed: onTap,
          child: Row(
            children: [
              if (icon != null) ...[
                OurneyIcon(name: icon, flat: true, color: ui.ink, size: 26),
                const SizedBox(width: UiSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: UiText.body(
                        size: 16,
                        weight: FontWeight.w700,
                        height: 1.35,
                        color: ui.ink,
                      ),
                    ),
                    if (hint != null)
                      Text(
                        hint,
                        style: UiText.muted(color: ui.inkMuted, size: 13),
                      ),
                  ],
                ),
              ),
              if (selected)
                OurneyIcon(name: 'check', flat: true, color: ui.ink, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _goalOptions(OnboardingL10n l10n) {
    final items = <(QuizGoal, String, String)>[
      (QuizGoal.weightLoss, l10n.onboarding_goalWeight, 'type-weight'),
      (QuizGoal.english, l10n.onboarding_goalEnglish, 'type-study'),
      (QuizGoal.workout, l10n.onboarding_goalWorkout, 'type-workout'),
      (QuizGoal.trip, l10n.onboarding_goalTrip, 'type-trip'),
      (QuizGoal.couple, l10n.onboarding_goalCouple, 'type-couple'),
      (QuizGoal.habit, l10n.onboarding_goalHabit, 'type-custom'),
    ];
    return [
      for (final (goal, label, icon) in items)
        _option(
          key: ValueKey('onboarding-goal-${goal.wireName}'),
          label: label,
          icon: icon,
          selected: _goal == goal,
          onTap: () => setState(() => _goal = goal),
        ),
    ];
  }

  List<Widget> _companyOptions(OnboardingL10n l10n) {
    final items = <(QuizCompany, String, String)>[
      (QuizCompany.solo, l10n.onboarding_whoSolo, l10n.onboarding_whoSoloHint),
      (
        QuizCompany.group,
        l10n.onboarding_whoGroup,
        l10n.onboarding_whoGroupHint,
      ),
      (
        QuizCompany.couple,
        l10n.onboarding_whoCouple,
        l10n.onboarding_whoCoupleHint,
      ),
    ];
    return [
      for (final (c, label, hint) in items)
        _option(
          key: ValueKey('onboarding-who-${c.wireName}'),
          label: label,
          hint: hint,
          selected: _company == c,
          onTap: () => setState(() => _company = c),
        ),
      if (_company == QuizCompany.couple)
        Text(
          l10n.onboarding_coupleStyleHint,
          style: UiText.muted(color: context.ui.inkMuted, size: 13),
        ),
    ];
  }

  List<Widget> _reminderOptions(OnboardingL10n l10n) {
    final items = <(String, String)>[
      ('07:00', l10n.onboarding_remMorning),
      ('12:00', l10n.onboarding_remNoon),
      ('21:30', l10n.onboarding_remNight),
    ];
    final suggestion = OnboardingQuiz(
      goal: _goal,
      company: _company,
      reminder: _reminder,
    ).suggestion;
    final lang = Localizations.localeOf(context).languageCode;
    return [
      for (final (time, label) in items)
        _option(
          key: ValueKey('onboarding-reminder-$time'),
          label: label,
          hint: l10n.onboarding_remHint(time),
          selected: _reminder == time,
          onTap: () => setState(() => _reminder = time),
        ),
      if (_reminder != null && suggestion != null) ...[
        const SizedBox(height: UiSpace.md),
        Text(
          l10n.onboarding_quizResultTitle,
          style: UiText.h2(color: context.ui.ink),
        ),
        const SizedBox(height: UiSpace.sm),
        UiCard(
          key: const ValueKey('onboarding-quiz-result'),
          radius: UiRadius.card,
          padding: const EdgeInsets.all(UiSpace.lg),
          child: Row(
            children: [
              // Template emoji badge (allowed: journey template badge).
              Text(
                suggestion.coupleRitual
                    ? '💞'
                    : templateFor(suggestion.templateId).emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Text(
                  suggestion.coupleRitual
                      ? l10n.onboarding_goalCouple
                      : (lang == 'vi'
                            ? templateFor(suggestion.templateId).titleVi
                            : templateFor(suggestion.templateId).titleEn),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 16,
                    weight: FontWeight.w700,
                    height: 1.35,
                    color: context.ui.ink,
                  ),
                ),
              ),
              Text(
                l10n.onboarding_quizRemind(_reminder!),
                style: UiText.muted(color: context.ui.inkMuted, size: 13),
              ),
            ],
          ),
        ),
      ],
    ];
  }
}
