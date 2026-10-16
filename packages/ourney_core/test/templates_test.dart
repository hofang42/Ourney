import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

void main() {
  test('catalog covers every TemplateId exactly once', () {
    expect(allTemplates.map((t) => t.id).toSet(), TemplateId.values.toSet());
    expect(allTemplates.length, TemplateId.values.length);
  });

  test('weight loss: 30 days, kg, metric hidden by default', () {
    final t = templateFor(TemplateId.weightLoss);
    expect(t.defaultDurationDays, 30);
    expect(t.metricUnit, 'kg');
    expect(t.hideMetricDefault, isTrue);
    expect(t.titleVi, 'Giảm cân');
  });

  test('english daily: 30 days, minutes', () {
    final t = templateFor(TemplateId.englishDaily);
    expect(t.defaultDurationDays, 30);
    expect(t.metricUnit, 'phút');
    expect(t.hideMetricDefault, isFalse);
    expect(t.titleVi, 'Học tiếng Anh mỗi ngày');
  });

  test('workout 30 has no metric', () {
    final t = templateFor(TemplateId.workout30);
    expect(t.defaultDurationDays, 30);
    expect(t.metricName, isNull);
  });

  test('travel defaults to 7 days and may be open-ended', () {
    final t = templateFor(TemplateId.travel);
    expect(t.defaultDurationDays, 7);
    expect(t.allowOpenEnded, isTrue);
  });

  test('only weight loss hides metric by default', () {
    final hidden = allTemplates.where((t) => t.hideMetricDefault).map((t) => t.id);
    expect(hidden, [TemplateId.weightLoss]);
  });

  test('every template has titles, emoji and caption prompts', () {
    for (final t in allTemplates) {
      expect(t.titleVi, isNotEmpty);
      expect(t.titleEn, isNotEmpty);
      expect(t.emoji, isNotEmpty);
      expect(t.captionPromptVi, isNotEmpty);
    }
  });

  test('defaults pass journey validation', () {
    for (final t in allTemplates) {
      expect(validateJourneyTitle(t.titleVi), isNull, reason: t.id.name);
      expect(validateDurationDays(t.defaultDurationDays), isNull, reason: t.id.name);
    }
  });
}
