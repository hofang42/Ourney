import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

/// Which page widget a question uses.
enum DnaKind { choice, weight, ghost, trophy, place, dates, names, habit }

/// One page of the V2 step 2 ("DNA") questions for a journey type
/// (`CreateStepTwo` / `questionSets` in create.tsx). Text is looked up by id
/// through [dnaText]; answers are kept in the create flow (no backend field).
@immutable
class DnaQuestion {
  const DnaQuestion({
    required this.key,
    required this.titleId,
    this.kind = DnaKind.choice,
    this.set = '',
    this.choiceIds = const [],
    this.compact = false,
    this.hints = true,
  });

  final String key;
  final String titleId;
  final DnaKind kind;

  /// Choice set prefix: text ids are `c_<set>_<id>` and `c_<set>_<id>_hint`.
  final String set;
  final List<String> choiceIds;
  final bool compact;
  final bool hints;

  String labelId(String id) => 'c_${set}_$id';
  String hintId(String id) => 'c_${set}_${id}_hint';
}

/// A trip's chosen days; [end] null = "return date not set".
@immutable
class DnaDates {
  const DnaDates(this.start, [this.end]);
  final DateTime start;
  final DateTime? end;
}

/// Days of a trip from [start] to [end], both included, counted on the
/// calendar (UTC dates), so a DST change in between cannot drop a day.
int dnaTripDays(DateTime start, DateTime end) =>
    DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
    1;

/// The end of a [start]..[end] trip clamped into the journey length limits
/// (`durationMin`..`durationMax` days): a shorter pick is lengthened to the
/// shortest journey, so the calendar shows what will be saved.
DateTime dnaClampTripEnd(DateTime start, DateTime end) {
  final n = dnaTripDays(start, end).clamp(durationMin, durationMax);
  return DateTime(start.year, start.month, start.day + n - 1);
}

const int dnaWeightMin = 40;
const int dnaWeightMax = 120;
const int dnaWeightDefault = 70;
const int dnaTrophyMax = 24;
const int dnaNameMax = 18;
const int dnaHabitMax = 40;
const int dnaReasonMax = 80;

/// Questions of [template], in order (couples use [dnaCoupleQuestions]).
List<DnaQuestion> dnaQuestionsFor(TemplateId template) => switch (template) {
  TemplateId.weightLoss => const [
    DnaQuestion(
      key: 'goal',
      titleId: 'goal_title_weight',
      set: 'goal_weight',
      choiceIds: ['lose', 'keep', 'shape'],
    ),
    DnaQuestion(key: 'weight', titleId: 'weight_title', kind: DnaKind.weight),
    DnaQuestion(key: 'ghost', titleId: 'ghost_title', kind: DnaKind.ghost),
  ],
  TemplateId.englishDaily => const [
    DnaQuestion(
      key: 'goal',
      titleId: 'goal_title_english',
      set: 'goal_english',
      choiceIds: ['ielts', 'talk', 'read'],
    ),
    DnaQuestion(
      key: 'minutes',
      titleId: 'minutes_title',
      set: 'minutes',
      choiceIds: ['15', '30', '45', '60'],
      compact: true,
    ),
    DnaQuestion(key: 'trophy', titleId: 'trophy_title', kind: DnaKind.trophy),
  ],
  TemplateId.workout30 => const [
    DnaQuestion(
      key: 'sport',
      titleId: 'sport_title',
      set: 'sport',
      choiceIds: ['run', 'gym', 'pilates', 'yoga', 'other'],
      compact: true,
    ),
    DnaQuestion(
      key: 'measure',
      titleId: 'measure_title',
      set: 'measure',
      choiceIds: ['km', 'min', 'session'],
    ),
  ],
  TemplateId.travel => const [
    DnaQuestion(key: 'place', titleId: 'place_title', kind: DnaKind.place),
    DnaQuestion(key: 'dates', titleId: 'dates_title', kind: DnaKind.dates),
    DnaQuestion(
      key: 'film',
      titleId: 'film_title',
      set: 'film',
      choiceIds: ['24', '36'],
    ),
  ],
  TemplateId.custom => const [
    DnaQuestion(key: 'habit', titleId: 'habit_title', kind: DnaKind.habit),
  ],
};

/// Couple journeys (template `custom`): ritual, two names, who shoots which half.
const List<DnaQuestion> dnaCoupleQuestions = [
  DnaQuestion(
    key: 'ritual',
    titleId: 'ritual_title',
    set: 'ritual',
    choiceIds: ['cook', 'save', 'ldr', 'custom'],
  ),
  DnaQuestion(key: 'names', titleId: 'names_title', kind: DnaKind.names),
  DnaQuestion(
    key: 'side',
    titleId: 'side_title',
    set: 'side',
    choiceIds: ['left', 'right'],
    hints: false,
  ),
];

/// Whether [q] is answered. Weight and the ghost photo are always allowed.
bool dnaAnswered(DnaQuestion q, Map<String, Object> answers) {
  bool filled(String k) => (answers[k] as String?)?.trim().isNotEmpty ?? false;
  return switch (q.kind) {
    DnaKind.weight || DnaKind.ghost => true,
    DnaKind.trophy => filled('trophy'),
    DnaKind.place => filled('place'),
    DnaKind.dates => answers['dates'] is DnaDates,
    DnaKind.names => filled('nameLeft') && filled('nameRight'),
    DnaKind.habit => filled('habit') && filled('reason'),
    DnaKind.choice => answers[q.key] != null,
  };
}
