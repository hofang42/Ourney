import 'models.dart';

/// Static description of a journey template (docs/02 §3, §10).
class JourneyTemplate {
  const JourneyTemplate({
    required this.id,
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
    titleVi: '30 ngày tập luyện',
    titleEn: '30-day workout',
    emoji: '💪',
    defaultDurationDays: 30,
    captionPromptVi: 'Hôm nay bạn tập gì?',
    captionPromptEn: 'What did you train today?',
  ),
  JourneyTemplate(
    id: TemplateId.travel,
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
