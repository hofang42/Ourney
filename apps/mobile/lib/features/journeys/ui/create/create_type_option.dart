import 'package:ourney_core/ourney_core.dart';

/// Who the journey is with (V2 create step 3).
enum CreateWho { solo, group, couple }

/// One journey type of step 1 (V2 `createTypes`).
class CreateTypeOption {
  const CreateTypeOption({
    required this.keyName,
    required this.templateId,
    required this.skinId,
    required this.badge,
    this.isCouple = false,
  });

  final String keyName;
  final TemplateId templateId;
  final PersonaSkinId skinId;

  /// `UiTypeBadge` id.
  final String badge;
  final bool isCouple;

  bool get isCustom => templateId == TemplateId.custom && !isCouple;

  /// The six V2 types, in the Figma order's data-model terms.
  static List<CreateTypeOption> all() => [
    for (final t in allTemplates.where((t) => t.id != TemplateId.custom))
      CreateTypeOption(
        keyName: t.id.wireName,
        templateId: t.id,
        skinId: t.personaSkinId,
        badge: switch (t.id) {
          TemplateId.weightLoss => 'weight',
          TemplateId.englishDaily => 'study',
          TemplateId.workout30 => 'workout',
          TemplateId.travel => 'trip',
          TemplateId.custom => 'custom',
        },
      ),
    const CreateTypeOption(
      keyName: 'couple',
      templateId: TemplateId.custom,
      skinId: PersonaSkinId.coupleRituals,
      badge: 'couple',
      isCouple: true,
    ),
    CreateTypeOption(
      keyName: TemplateId.custom.wireName,
      templateId: TemplateId.custom,
      skinId: PersonaSkinId.minimalistHabit,
      badge: 'custom',
    ),
  ];
}
