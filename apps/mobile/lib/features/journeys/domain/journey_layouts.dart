import 'package:ourney_core/ourney_core.dart';

/// Layouts the owner may switch a journey to (Figma
/// `availableLayoutsForJourney`): a layout that needs data the journey does
/// not have is hidden. The journey's current skin is always offered.
List<PersonaSkinId> availableLayoutsFor(
  Journey journey, {
  required PersonaSkinId current,
}) {
  final metric = (journey.metricName ?? '').toLowerCase();
  final unit = (journey.metricUnit ?? '').toLowerCase();
  bool ok(PersonaSkinId skin) => switch (skin) {
    PersonaSkinId.quietTransformer =>
      journey.templateId == TemplateId.weightLoss ||
          unit == 'kg' ||
          metric.contains('weight'),
    PersonaSkinId.coupleRituals =>
      journey.coupleSelfName != null ||
      (journey.kind == JourneyKind.group && journey.maxMembers == 2) ||
      journey.layout == PersonaSkinId.coupleRituals,
    PersonaSkinId.accountabilitySquad => journey.kind == JourneyKind.group,
    PersonaSkinId.aestheticFlexer =>
      journey.templateId == TemplateId.workout30 ||
          unit == 'km' ||
          unit == 'min',
    PersonaSkinId.memoryCollectors || PersonaSkinId.minimalistHabit => true,
  };
  return [
    for (final s in PersonaSkinId.values)
      if (s == current || ok(s)) s,
  ];
}
