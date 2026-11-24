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
    final hidden =
        allTemplates.where((t) => t.hideMetricDefault).map((t) => t.id);
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

  test('caption prompts are unique per language (U21)', () {
    final vi = allTemplates.map((t) => t.captionPromptVi).toSet();
    final en = allTemplates.map((t) => t.captionPromptEn).toSet();
    expect(vi.length, allTemplates.length);
    expect(en.length, allTemplates.length);
    // The weight-loss prompt must not repeat the Check-in mood question.
    final wl = allTemplates.firstWhere((t) => t.id == TemplateId.weightLoss);
    expect(wl.captionPromptVi, isNot('Hôm nay bạn cảm thấy thế nào?'));
    expect(wl.captionPromptEn, isNot('How are you feeling today?'));
  });

  test('defaults pass journey validation', () {
    for (final t in allTemplates) {
      expect(validateJourneyTitle(t.titleVi), isNull, reason: t.id.name);
      expect(validateDurationDays(t.defaultDurationDays), isNull,
          reason: t.id.name);
    }
  });

  test('every template maps to a PersonaSkinId', () {
    for (final t in allTemplates) {
      expect(personaSkinForTemplate(t.id), t.personaSkinId);
    }
    expect(
      personaSkinForTemplate(
        TemplateId.custom,
        kind: JourneyKind.group,
        maxMembers: 2,
      ),
      PersonaSkinId.coupleRituals,
    );
  });
}
