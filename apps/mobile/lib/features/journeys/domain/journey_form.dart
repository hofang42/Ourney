import 'package:ourney_core/ourney_core.dart';

/// Emoji offered in the create form (journey emoji is user content).
const List<String> journeyEmojiChoices = [
  '⚖️',
  '📚',
  '💪',
  '✈️',
  '✨',
  '💞',
  '🏃',
  '🧘',
  '🥗',
  '🎨',
  '🎸',
  '🌱',
  '💧',
];

/// Quick-pick durations in days (all inside [durationMin]..[durationMax]).
const List<int> journeyDurationChoices = [7, 14, 21, 30, 60, 90];

/// Field-level validation result for the create form.
class JourneyFormErrors {
  const JourneyFormErrors({
    this.title,
    this.duration,
    this.metricName,
    this.visibility,
  });

  final JourneyTitleError? title;
  final DurationError? duration;

  /// Metric enabled but without a name.
  final bool? metricName;
  final VisibilityError? visibility;

  bool get isValid =>
      title == null &&
      duration == null &&
      metricName != true &&
      visibility == null;
}

/// Mutable state of the create form, seeded from a template (FR-B1/B2/B7).
class JourneyForm {
  JourneyForm.fromTemplate(
    this.template, {
    required String languageCode,
    required this.timezone,
  }) : title = template.id == TemplateId.custom
           ? ''
           : (languageCode == 'en' ? template.titleEn : template.titleVi),
       emoji = template.emoji,
       durationDays = template.defaultDurationDays,
       trackMetric = template.metricName != null,
       metricName = template.metricName ?? '',
       metricUnit = template.metricUnit ?? '',
       hideMetric = template.hideMetricDefault,
       // FR-B7: weight loss blurs photos on outside shares by default.
       blurOnShare = template.id == TemplateId.weightLoss;

  final JourneyTemplate template;
  String title;
  String emoji;
  JourneyKind kind = JourneyKind.solo;

  /// Null = open-ended (only when [JourneyTemplate.allowOpenEnded]).
  int? durationDays;
  bool trackMetric;
  String metricName;
  String metricUnit;
  bool hideMetric;
  bool blurOnShare;
  JourneyVisibility soloVisibility = JourneyVisibility.private;
  String timezone;

  bool get allowOpenEnded => template.allowOpenEnded;

  /// Visibility sent to `create_journey`: groups are always `group`.
  JourneyVisibility get visibility => kind == JourneyKind.group
      ? defaultVisibilityFor(JourneyKind.group)
      : soloVisibility;

  JourneyFormErrors validate() {
    final metricMissing = trackMetric && metricName.trim().isEmpty;
    return JourneyFormErrors(
      title: validateJourneyTitle(title),
      duration: validateDurationDays(durationDays),
      metricName: metricMissing ? true : null,
      visibility: validateJourneyVisibility(kind, visibility),
    );
  }

  /// [id]: client id generated once per form (idempotent create retries).
  JourneyDraft toDraft({required LocalDate startDate, String? id}) {
    final unit = metricUnit.trim();
    return JourneyDraft(
      kind: kind,
      templateId: template.id,
      title: title.trim(),
      emoji: emoji,
      startDate: startDate,
      timezone: timezone,
      durationDays: durationDays,
      metricName: trackMetric ? metricName.trim() : null,
      metricUnit: trackMetric && unit.isNotEmpty ? unit : null,
      hideMetricDefault: trackMetric && hideMetric,
      visibility: visibility,
      id: id,
    );
  }
}
