import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../ui/ui.dart';
import '../../../l10n/generated/journeys_localizations.dart';
import '../create_type_option.dart';
import '../create_widgets.dart';
import 'step_parts.dart';

/// Step 3: solo, group, or couple (with partner display names).
class CreateWhoStep extends StatelessWidget {
  const CreateWhoStep({
    required this.who,
    required this.localOnly,
    required this.showErrors,
    required this.nameLeftController,
    required this.nameRightController,
    required this.onPick,
    required this.onNamesChanged,
    this.inviteHandle,
    super.key,
  });

  final CreateWho who;
  final bool localOnly;
  final bool showErrors;
  final TextEditingController nameLeftController;
  final TextEditingController nameRightController;
  final ValueChanged<CreateWho> onPick;
  final VoidCallback onNamesChanged;
  final String? inviteHandle;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final invite = inviteHandle?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeading(l10n.journeys_createWhoTitle),
        if (invite != null && invite.isNotEmpty && who != CreateWho.solo) ...[
          KeyedSubtree(
            key: const ValueKey('create-inviting-friend'),
            child: StepNote(
              icon: 'squad',
              text: l10n.journeys_create_invitingFriend(invite),
            ),
          ),
          const SizedBox(height: UiSpace.sm),
        ],
        CreateChoiceCard(
          key: const ValueKey('journey-kind-solo'),
          title: l10n.journeys_kindSolo,
          body: l10n.journeys_kindSoloBody,
          glyph: OurneyIcon(name: 'profile', size: 30),
          selected: who == CreateWho.solo,
          onPressed: () => onPick(CreateWho.solo),
        ),
        const SizedBox(height: UiSpace.sm),
        CreateChoiceCard(
          key: const ValueKey('journey-kind-group'),
          title: l10n.journeys_kindGroup,
          body: l10n.journeys_kindGroupBody,
          glyph: OurneyIcon(name: 'squad', size: 30),
          selected: who == CreateWho.group,
          onPressed: localOnly ? null : () => onPick(CreateWho.group),
        ),
        if (localOnly)
          StepNote(icon: 'cloud-off', text: l10n.journeys_groupNeedsServer),
        const SizedBox(height: UiSpace.sm),
        CreateChoiceCard(
          key: const ValueKey('journey-kind-couple'),
          title: l10n.journeys_kindCouple,
          body: l10n.journeys_kindCoupleBody,
          glyph: OurneyIcon(name: 'heart', size: 30),
          selected: who == CreateWho.couple,
          onPressed: () => onPick(CreateWho.couple),
        ),
        if (who == CreateWho.couple) ...[
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('journey-couple-left'),
            label: l10n.journeys_coupleNameYou,
            controller: nameLeftController,
            error: showErrors && nameLeftController.text.trim().isEmpty
                ? l10n.journeys_errorCoupleNames
                : null,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(18)],
            onChanged: (_) => onNamesChanged(),
          ),
          const SizedBox(height: UiSpace.md),
          UiTextField(
            fieldKey: const ValueKey('journey-couple-right'),
            label: l10n.journeys_coupleNameOther,
            controller: nameRightController,
            error: showErrors && nameRightController.text.trim().isEmpty
                ? l10n.journeys_errorCoupleNames
                : null,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(18)],
            onChanged: (_) => onNamesChanged(),
          ),
        ],
      ],
    );
  }
}
