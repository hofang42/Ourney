import 'models.dart';

/// Static description of a journey template (docs/02 §3, §10 & docs/06).
class JourneyTemplate {
  const JourneyTemplate({
    required this.id,
    required this.personaSkinId,
    required this.designAssetPath,
    required this.titleVi,
    required this.titleEn,
    required this.emoji,
    required this.defaultDurationDays,
    required this.captionPromptVi,
    required this.captionPromptEn,
    this.metricName,
    this.metricUnit,
    this.hideMetricDefault = false,
    this.allowOpenEnded = false,
  });

  final TemplateId id;
  final PersonaSkinId personaSkinId;
  final String designAssetPath;
  final String titleVi;
  final String titleEn;
  final String emoji;

  /// Suggested duration shown in the create form.
  final int defaultDurationDays;
  final String? metricName;
  final String? metricUnit;

  /// Metric is hidden from others by default (weight loss).
  final bool hideMetricDefault;

  /// The user may choose "no end date" instead of a fixed duration.
  final bool allowOpenEnded;
  final String captionPromptVi;
  final String captionPromptEn;
}

const List<JourneyTemplate> allTemplates = [
  JourneyTemplate(
    id: TemplateId.weightLoss,
    personaSkinId: PersonaSkinId.quietTransformer,
    designAssetPath: 'assets/design_personas/persona_1_quiet_transformer.jpg',
    titleVi: 'Giảm cân',
    titleEn: 'Weight loss',
    emoji: '⚖️',
    defaultDurationDays: 30,
    metricName: 'Cân nặng',
    metricUnit: 'kg',
    hideMetricDefault: true,
    captionPromptVi: 'Hôm nay bạn cảm thấy thế nào?',
    captionPromptEn: 'How do you feel today?',
  ),
  JourneyTemplate(
    id: TemplateId.englishDaily,
    personaSkinId: PersonaSkinId.accountabilitySquad,
    designAssetPath: 'assets/design_personas/persona_2_accountability_squad.jpg',
    titleVi: 'Học tiếng Anh mỗi ngày',
    titleEn: 'Daily English',
    emoji: '📚',
    defaultDurationDays: 30,
    metricName: 'Thời gian học',
    metricUnit: 'phút',
    captionPromptVi: 'Hôm nay bạn học được gì?',
    captionPromptEn: 'What did you learn today?',
  ),
  JourneyTemplate(
    id: TemplateId.workout30,
    personaSkinId: PersonaSkinId.aestheticFlexer,
    designAssetPath: 'assets/design_personas/persona_5_aesthetic_flexers.jpg',
    titleVi: '30 ngày tập luyện',
    titleEn: '30-day workout',
    emoji: '💪',
    defaultDurationDays: 30,
    captionPromptVi: 'Hôm nay bạn tập gì?',
    captionPromptEn: 'What did you train today?',
  ),
  JourneyTemplate(
    id: TemplateId.travel,
    personaSkinId: PersonaSkinId.memoryCollectors,
    designAssetPath: 'assets/design_personas/persona_3_memory_collectors.jpg',
    titleVi: 'Chuyến đi',
    titleEn: 'Trip',
    emoji: '✈️',
    defaultDurationDays: 7,
    allowOpenEnded: true,
    captionPromptVi: 'Hôm nay bạn đã đi đâu?',
    captionPromptEn: 'Where did you go today?',
  ),
  JourneyTemplate(
    id: TemplateId.custom,
    personaSkinId: PersonaSkinId.minimalistHabit,
    designAssetPath: 'assets/design_personas/persona_6_minimalist_habit.jpg',
    titleVi: 'Tuỳ chỉnh',
    titleEn: 'Custom',
    emoji: '✨',
    defaultDurationDays: 30,
    allowOpenEnded: true,
    captionPromptVi: 'Hôm nay có gì mới?',
    captionPromptEn: "What's new today?",
  ),
];

JourneyTemplate templateFor(TemplateId id) => allTemplates.firstWhere((t) => t.id == id);

/// Resolves the [PersonaSkinId] for a [TemplateId] (and promotes 2-member
/// couple/custom rituals to [PersonaSkinId.coupleRituals] when applicable).
PersonaSkinId personaSkinForTemplate(
  TemplateId id, {
  JourneyKind kind = JourneyKind.solo,
  int maxMembers = 10,
  String? emoji,
}) {
  if (id == TemplateId.custom &&
      (emoji == '💞' || emoji == '❤️' || (kind == JourneyKind.group && maxMembers == 2))) {
    return PersonaSkinId.coupleRituals;
  }
  return templateFor(id).personaSkinId;
}

/// Design reference board asset path for each of the 6 [PersonaSkinId]s.
String designAssetForPersona(PersonaSkinId skin) {
  switch (skin) {
    case PersonaSkinId.quietTransformer:
      return 'assets/design_personas/persona_1_quiet_transformer.jpg';
    case PersonaSkinId.accountabilitySquad:
      return 'assets/design_personas/persona_2_accountability_squad.jpg';
    case PersonaSkinId.memoryCollectors:
      return 'assets/design_personas/persona_3_memory_collectors.jpg';
    case PersonaSkinId.coupleRituals:
      return 'assets/design_personas/persona_4_couple_rituals.jpg';
    case PersonaSkinId.aestheticFlexer:
      return 'assets/design_personas/persona_5_aesthetic_flexers.jpg';
    case PersonaSkinId.minimalistHabit:
      return 'assets/design_personas/persona_6_minimalist_habit.jpg';
  }
}

