import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../../../ui/ui.dart';
import '../../../l10n/generated/journeys_localizations.dart';
import '../create_widgets.dart';

/// Primary step title with an optional muted subtitle below it.
class StepHeading extends StatelessWidget {
  const StepHeading(this.text, {this.subtitle, super.key});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(text, style: UiText.h1(color: ui.ink)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: UiSpace.xs),
          Text(subtitle!, style: UiText.muted(color: ui.inkMuted)),
        ],
        const SizedBox(height: UiSpace.lg),
      ],
    );
  }
}

/// Section header label inside a create-flow step.
class StepLabel extends StatelessWidget {
  const StepLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 7),
    child: Semantics(
      header: true,
      child: Text(text, style: UiText.fieldLabel(color: context.ui.inkMuted)),
    ),
  );
}

/// Small icon + helper note row (e.g. local-only or group visibility notes).
class StepNote extends StatelessWidget {
  const StepNote({required this.icon, required this.text, super.key});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OurneyIcon(name: icon, size: 16),
          const SizedBox(width: UiSpace.xs),
          Expanded(
            child: Text(
              text,
              style: UiText.body(size: 12, height: 1.45, color: ui.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable journey badge tile in the step-2 detail form.
class EmojiChoice extends StatelessWidget {
  const EmojiChoice({
    required this.emoji,
    required this.template,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String emoji;
  final TemplateId template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      key: ValueKey('journey-emoji-$emoji'),
      onPressed: onTap,
      selected: selected,
      semanticLabel: JourneysL10n.of(context).journeys_emojiSemantics(emoji),
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(UiRadius.input),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? createSelectedFill(ui) : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: Border.all(
            color: selected ? ui.outline : ui.border,
            width: selected ? 3 : 1,
          ),
        ),
        child: uiJourneyGlyph(emoji, template, size: 26),
      ),
    );
  }
}
