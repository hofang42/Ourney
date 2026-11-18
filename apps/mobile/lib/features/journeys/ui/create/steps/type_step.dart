import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../../app/app_routes.dart';
import '../../../../../ui/ui.dart';
import '../../../l10n/generated/journeys_localizations.dart';
import '../create_deck.dart';
import '../create_type_option.dart';
import 'step_parts.dart';

/// Step 1 of the create flow: journey type deck and import-by-link action.
class CreateTypeStep extends StatelessWidget {
  const CreateTypeStep({
    required this.options,
    required this.deckFocus,
    required this.onFocus,
    required this.onChoose,
    super.key,
  });

  final List<CreateTypeOption> options;
  final int deckFocus;
  final ValueChanged<int> onFocus;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final en = Localizations.localeOf(context).languageCode == 'en';
    return KeyedSubtree(
      key: const ValueKey('journeys-template-picker'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepHeading(
            l10n.journeys_pickTemplateTitle,
            subtitle: l10n.journeys_createPickSubtitle,
          ),
          CreateTypeDeck(
            items: [
              for (final o in options)
                () {
                  final tpl = templateFor(o.templateId);
                  final skinId = o.isCouple
                      ? 'couple'
                      : uiSkinIdFor(personaSkinForTemplate(o.templateId));
                  final title = o.isCouple
                      ? l10n.journeys_templateCoupleTitle
                      : (en ? tpl.titleEn : tpl.titleVi);
                  final tagline = switch (o.templateId) {
                    _ when o.isCouple => l10n.journeys_tagCouple,
                    TemplateId.weightLoss => l10n.journeys_tagWeightLoss,
                    TemplateId.englishDaily => l10n.journeys_tagEnglish,
                    TemplateId.travel => l10n.journeys_tagTravel,
                    TemplateId.workout30 => l10n.journeys_tagWorkout,
                    TemplateId.custom => l10n.journeys_tagCustom,
                  };
                  final mode = switch (o.templateId) {
                    _ when o.isCouple => l10n.journeys_modeCoupleOnly,
                    TemplateId.weightLoss => l10n.journeys_modeSoloOnly,
                    _ => l10n.journeys_modeSoloGroup,
                  };
                  final days = o.isCustom
                      ? null
                      : l10n.journeys_templateDays(tpl.defaultDurationDays);
                  return CreateDeckItem(
                    keyName: o.keyName,
                    skinId: skinId,
                    title: title,
                    tagline: tagline,
                    meta: [mode, ?days].join(' · '),
                    badge: o.badge,
                  );
                }(),
            ],
            initial: deckFocus,
            onFocus: onFocus,
            onChoose: onChoose,
          ),
          UiButton.ghost(
            key: const ValueKey('create-import-link'),
            label: l10n.journeys_dna_import_link,
            onPressed: () => context.push(AppRoutes.importJourney),
          ),
        ],
      ),
    );
  }
}
