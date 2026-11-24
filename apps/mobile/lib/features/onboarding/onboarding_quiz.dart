import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/theme/motion.dart';
import '../../ui/ui.dart';
import 'l10n/generated/onboarding_localizations.dart';

/// The 3-question onboarding quiz (V2 `OnboardingFlow`): goal, company,
/// reminder time. A question needs an answer before "Continue" enables;
/// "Skip" leaves at any time. [onDone] gets the answers (null when skipped).
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

UiFlowGoal _flowGoal(QuizGoal goal) => switch (goal) {
  QuizGoal.weightLoss => UiFlowGoal.weight,
  QuizGoal.english => UiFlowGoal.english,
  QuizGoal.workout => UiFlowGoal.workout,
  QuizGoal.trip => UiFlowGoal.trip,
  QuizGoal.couple => UiFlowGoal.couple,
  QuizGoal.habit => UiFlowGoal.habit,
};

String _goalSampleAsset(QuizGoal goal) => switch (goal) {
  QuizGoal.weightLoss => 'assets/samples/weight_loss/02.webp',
  QuizGoal.english => 'assets/samples/ielts_study/01.webp',
  QuizGoal.workout => 'assets/samples/workout_30/01.webp',
  QuizGoal.trip => 'assets/samples/travel_dalat/02.webp',
  QuizGoal.couple => 'assets/samples/couple_rituals/02.webp',
  QuizGoal.habit => 'assets/samples/reading_10_pages/01.webp',
};

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
      OurneyHaptics.selection();
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
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // `app-screen-in`: each question fades in and slides 10dp from the right
    // over 210ms (a 150ms plain fade with reduced motion).
    return TweenAnimationBuilder<double>(
      key: ValueKey('onboarding-quiz-$_step'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: reduce ? 150 : 210),
      curve: reduce ? Curves.linear : Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(reduce ? 0 : (1 - t) * 10, 0),
          child: child,
        ),
      ),
      child: Column(
        children: [
          _TopBar(
            step: _step,
            gutter: widget.gutter,
            onBack: () => setState(() => _step--),
            onSkip: () => widget.onDone(null),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                widget.gutter,
                UiSpace.md,
                widget.gutter,
                UiSpace.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: UiText.heading(
                        font: 'SpaceGrotesk',
                        size: 32,
                        weight: 700,
                        height: 1.3,
                        tracking: -0.045,
                        color: ui.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: UiSpace.xxl),
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
            padding: EdgeInsets.fromLTRB(
              widget.gutter,
              UiSpace.md,
              widget.gutter,
              UiSpace.xl,
            ),
            child: UiFlowButton(
              key: const ValueKey('onboarding-quiz-next'),
              label: _isLast && _answered
                  ? l10n.onboarding_quizStart
                  : l10n.onboarding_quizContinue,
              onPressed: _answered ? _next : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Two-column grid of goal cards (`.choice-grid`, 12dp gaps).
  List<Widget> _goalOptions(OnboardingL10n l10n) {
    final items = <(QuizGoal, String)>[
      (QuizGoal.weightLoss, l10n.onboarding_goalWeight),
      (QuizGoal.english, l10n.onboarding_goalEnglish),
      (QuizGoal.workout, l10n.onboarding_goalWorkout),
      (QuizGoal.trip, l10n.onboarding_goalTrip),
      (QuizGoal.couple, l10n.onboarding_goalCouple),
      (QuizGoal.habit, l10n.onboarding_goalHabit),
    ];
    final cards = [
      for (final (goal, label) in items)
        _GoalCard(
          key: ValueKey('onboarding-goal-${goal.wireName}'),
          goal: _flowGoal(goal),
          label: label,
          selected: _goal == goal,
          onTap: () => setState(() => _goal = goal),
        ),
    ];
    return [
      for (var i = 0; i < cards.length; i += 2)
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < cards.length ? 12 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: 12),
                Expanded(child: cards[i + 1]),
              ],
            ),
          ),
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
        _RowCard(
          key: ValueKey('onboarding-who-${c.wireName}'),
          color: c == QuizCompany.couple
              ? UiFlowColors.couple
              : UiFlowColors.english,
          label: label,
          hint: hint,
          minHeight: 88,
          selected: _company == c,
          onTap: () => setState(() => _company = c),
        ),
      if (_company == QuizCompany.couple)
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: UiFlowColors.couple, width: 3),
            ),
          ),
          child: Text(
            l10n.onboarding_coupleStyleHint,
            style: UiText.muted(color: context.ui.inkMuted, size: 12),
          ),
        ),
    ];
  }

  List<Widget> _reminderOptions(OnboardingL10n l10n) {
    final items = <(String, String)>[
      ('07:00', l10n.onboarding_remMorning),
      ('12:00', l10n.onboarding_remNoon),
      ('21:30', l10n.onboarding_remNight),
    ];
    return [
      for (final (time, label) in items)
        _RowCard(
          key: ValueKey('onboarding-reminder-$time'),
          color: UiFlowColors.habit,
          label: label,
          hint: l10n.onboarding_remHint(time),
          minHeight: 72,
          selected: _reminder == time,
          onTap: () => setState(() => _reminder = time),
        ),
      if (_reminder != null) _resultCard(l10n),
    ];
  }

  /// `.onboarding-result`: the first journey, previewed from the answers.
  Widget _resultCard(OnboardingL10n l10n) {
    final ui = context.ui;
    final quizGoal = _goal ?? QuizGoal.english;
    final goal = _flowGoal(quizGoal);
    final couple = _company == QuizCompany.couple;
    final goalLabel = switch (quizGoal) {
      QuizGoal.weightLoss => l10n.onboarding_goalWeight,
      QuizGoal.english => l10n.onboarding_goalEnglish,
      QuizGoal.workout => l10n.onboarding_goalWorkout,
      QuizGoal.trip => l10n.onboarding_goalTrip,
      QuizGoal.couple => l10n.onboarding_goalCouple,
      QuizGoal.habit => l10n.onboarding_goalHabit,
    };
    final who = switch (_company) {
      QuizCompany.group => l10n.onboarding_whoGroup,
      QuizCompany.couple => l10n.onboarding_whoCouple,
      _ => l10n.onboarding_whoSolo,
    };
    final chipStyle = UiText.body(
      size: 12,
      weight: FontWeight.w700,
      height: 1.3,
      color: UiFlowColors.onPastel,
    );
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboarding_quizResultTitle,
            style: UiText.heading(
              font: 'SpaceGrotesk',
              size: 18,
              weight: 700,
              height: 1.3,
              color: ui.ink,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('onboarding-quiz-result'),
            constraints: const BoxConstraints(minHeight: 128),
            decoration: BoxDecoration(
              color: couple ? UiFlowColors.couple : goal.color,
              borderRadius: BorderRadius.circular(UiChoiceCard.radius),
              border: ui.stickerBorder(),
              boxShadow: ui.hardShadow(),
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Positioned(
                  left: 14,
                  top: 18,
                  child: Transform.rotate(
                    angle: 2 * math.pi / 180,
                    child: Container(
                      width: 62,
                      height: 72,
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: UiFlowColors.paper,
                        border: Border.fromBorderSide(
                          BorderSide(
                            color: UiFlowColors.onPastel,
                            width: UiBorder.standard,
                          ),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            _goalSampleAsset(quizGoal),
                            key: ValueKey(
                              'onboarding-quiz-result-photo-${quizGoal.wireName}',
                            ),
                            fit: BoxFit.cover,
                            cacheWidth: 186,
                            excludeFromSemantics: true,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(child: UiGoalGlyph(goal: goal, size: 28)),
                          ),
                          if (ui.isDark)
                            const IgnorePointer(
                              child: ColoredBox(color: Color(0x22000000)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(92, 18, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        couple
                            ? l10n.onboarding_resultCouple
                            : '${goalLabel.toLowerCase()}.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.heading(
                          font: 'SpaceGrotesk',
                          size: 19,
                          weight: 700,
                          height: 1.3,
                          color: UiFlowColors.onPastel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Chip(label: who, style: chipStyle),
                          _Chip(
                            label: l10n.onboarding_quizRemind(_reminder!),
                            style: chipStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.mini-result-card` chip: white, 1.5dp ink outline, 9dp radius.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.style});

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 30),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: UiFlowColors.paper,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: UiFlowColors.onPastel, width: UiBorder.thin),
    ),
    child: Text(label, style: style),
  );
}

/// `.onboarding-top`: back (from question 2), "Câu n/3" over the three
/// segments, and "Bỏ qua".
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.step,
    required this.gutter,
    required this.onBack,
    required this.onSkip,
  });

  final int step;
  final double gutter;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = OnboardingL10n.of(context);
    final ui = context.ui;
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter - 8, UiSpace.xs, gutter - 8, 10),
      child: Row(
        children: [
          if (step > 0)
            UiIconButton(
              key: const ValueKey('onboarding-quiz-back'),
              glyph: const OurneyIcon(name: 'back', flat: true, size: 22),
              label: l10n.onboarding_quizBack,
              onPressed: onBack,
            )
          else
            const SizedBox(width: UiSize.tap, height: UiSize.tap),
          const SizedBox(width: UiSpace.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.onboarding_quizStep(step + 1),
                  style: UiText.body(
                    size: 14,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: ui.ink,
                  ),
                ),
                const SizedBox(height: 7),
                UiStepSegments(
                  count: OnboardingQuizStage.questionCount,
                  current: step,
                  itemKey: (i) => ValueKey('onboarding-step-$i'),
                ),
              ],
            ),
          ),
          const SizedBox(width: UiSpace.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: UiTextAction(
              key: const ValueKey('onboarding-skip'),
              label: l10n.onboarding_skip,
              size: 14,
              color: ui.ink,
              onPressed: onSkip,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.type-choice`: coloured icon disc over a bold label.
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final UiFlowGoal goal;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => UiChoiceCard(
    color: goal.color,
    selected: selected,
    onPressed: onTap,
    minHeight: 132,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: goal.color,
            shape: BoxShape.circle,
            border: const Border.fromBorderSide(
              BorderSide(
                color: UiFlowColors.onPastel,
                width: UiBorder.standard,
              ),
            ),
          ),
          child: UiGoalGlyph(goal: goal),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: UiText.body(size: 14, weight: FontWeight.w700, height: 1.3),
        ),
      ],
    ),
  );
}

/// `.row-choice`: label with a muted hint, 48dp right gutter for the badge.
class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.color,
    required this.label,
    required this.hint,
    required this.minHeight,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final String label;
  final String hint;
  final double minHeight;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: UiChoiceCard(
        color: color,
        selected: selected,
        onPressed: onTap,
        minHeight: minHeight,
        padding: const EdgeInsets.fromLTRB(18, 14, 48, 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: UiText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                hint,
                style: UiText.body(
                  size: 12,
                  height: 1.3,
                  color: selected ? UiFlowColors.onPastel : ui.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
