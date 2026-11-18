import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../l10n/generated/journeys_localizations.dart';
import 'create_widgets.dart';

/// Top bar of the create flow: back, "Step n/5" with segments, close.
class CreateFlowHeader extends StatelessWidget {
  const CreateFlowHeader({
    required this.step,
    required this.steps,
    required this.onBack,
    required this.onClose,
    super.key,
  });

  final int step;
  final int steps;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final stepLabel = l10n.journeys_createStepOf(step + 1, steps);
    return Row(
      children: [
        UiIconButton(
          key: const ValueKey('create-back'),
          glyph: OurneyIcon(name: 'back', size: 22),
          iconSize: 22,
          color: ui.ink,
          label: l10n.journeys_back,
          onPressed: onBack,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                stepLabel,
                key: const ValueKey('create-step-label'),
                style: UiText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  height: 1.35,
                  color: ui.ink,
                ),
              ),
              const SizedBox(height: 4),
              CreateStepSegments(count: steps, current: step, label: stepLabel),
            ],
          ),
        ),
        UiIconButton(
          key: const ValueKey('create-close'),
          glyph: OurneyIcon(name: 'close', size: 22),
          iconSize: 22,
          color: ui.ink,
          label: l10n.journeys_createExit,
          onPressed: onClose,
        ),
      ],
    );
  }
}
