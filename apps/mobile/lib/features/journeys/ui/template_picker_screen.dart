import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../ui/ui.dart';
import '../journeys_paths.dart';
import '../l10n/generated/journeys_localizations.dart';
import 'journey_style.dart';

/// One style card of the template picker.
class _TemplateOption {
  const _TemplateOption({
    required this.keyName,
    required this.templateId,
    required this.skinId,
    required this.routePath,
    this.isCouple = false,
  });

  final String keyName;
  final TemplateId templateId;
  final PersonaSkinId skinId;
  final String routePath;
  final bool isCouple;

  bool get isCustom => templateId == TemplateId.custom && !isCouple;
}

/// **Template picker** (step 1 of `/journeys/new`, V1.0 `TemplateGrid`): a
/// two-column grid of style cards, each painted in its journey style (paper,
/// ink, accent) with the style's reference photo, tagline and who can join,
/// plus a dashed **Custom** card.
///
/// The 6th style, Couple Rituals, is `TemplateId.custom` with the heart
/// preset. Tapping a card opens its quick setup.
class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({super.key});

  static List<_TemplateOption> _options() => [
    for (final t in allTemplates.where((t) => t.id != TemplateId.custom))
      _TemplateOption(
        keyName: t.id.wireName,
        templateId: t.id,
        skinId: t.personaSkinId,
        routePath: JourneysPaths.newFromTemplate(t.id),
      ),
    _TemplateOption(
      keyName: 'couple',
      templateId: TemplateId.custom,
      skinId: PersonaSkinId.coupleRituals,
      routePath: JourneysPaths.newCoupleRitual,
      isCouple: true,
    ),
    _TemplateOption(
      keyName: TemplateId.custom.wireName,
      templateId: TemplateId.custom,
      skinId: PersonaSkinId.minimalistHabit,
      routePath: JourneysPaths.newFromTemplate(TemplateId.custom),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final options = _options();
    const gap = 10.0;
    return UiScaffold(
      key: const ValueKey('journeys-template-picker'),
      padTop: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiBackHeader(
            onBack: () => context.pop(),
            backLabel: l10n.journeys_back,
          ),
          const SizedBox(height: UiSpace.sm),
          Semantics(
            header: true,
            child: Text(
              l10n.journeys_pickTemplateTitle,
              style: UiText.h1(color: ui.ink),
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < options.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _TemplateCard(option: options[i])),
                    const SizedBox(width: gap),
                    Expanded(
                      child: i + 1 < options.length
                          ? _TemplateCard(option: options[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.option});

  final _TemplateOption option;

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final ui = context.ui;
    final en = Localizations.localeOf(context).languageCode == 'en';
    final style = journeyStyleFor(option.skinId);
    final pal = JourneyPalette.of(context, style);
    final tpl = templateFor(option.templateId);
    final title = option.isCouple
        ? l10n.journeys_templateCoupleTitle
        : (en ? tpl.titleEn : tpl.titleVi);
    final tagline = switch (option.templateId) {
      _ when option.isCouple => l10n.journeys_tagCouple,
      TemplateId.weightLoss => l10n.journeys_tagWeightLoss,
      TemplateId.englishDaily => l10n.journeys_tagEnglish,
      TemplateId.travel => l10n.journeys_tagTravel,
      TemplateId.workout30 => l10n.journeys_tagWorkout,
      TemplateId.custom => l10n.journeys_tagCustom,
    };
    final mode = switch (option.templateId) {
      _ when option.isCouple => l10n.journeys_modeCoupleOnly,
      TemplateId.weightLoss => l10n.journeys_modeSoloOnly,
      _ => l10n.journeys_modeSoloGroup,
    };
    final days = option.isCustom
        ? null
        : l10n.journeys_templateDays(tpl.defaultDurationDays);

    // Dark mode: every style card shares one surface (V1.0 override).
    final bg = option.isCustom || ui.isDark ? ui.surface : pal.paper;
    final ink = option.isCustom || ui.isDark ? ui.ink : pal.ink;

    final Widget content;
    if (option.isCustom) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: ui.fill),
            child: Icon(Icons.add_rounded, color: ink),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: UiText.display(size: 15, color: ink),
          ),
          const SizedBox(height: 3),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: UiText.body(size: 11, height: 1.4, color: ui.inkMuted),
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 104,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: style.accent, width: 5)),
            ),
            child: Image.asset(
              designAssetForPersona(option.skinId),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => ColoredBox(color: ui.fill),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UiText.display(size: 15, color: ink),
          ),
          const SizedBox(height: 3),
          Text(
            tagline,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: UiText.body(
              size: 11,
              height: 1.4,
              color: ink.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 8),
          const Spacer(),
          Text(
            [mode, ?days].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UiText.body(
              size: 10,
              weight: FontWeight.w700,
              height: 1.35,
              color: ink,
            ),
          ),
        ],
      );
    }

    return UiPressable(
      key: ValueKey('template-${option.keyName}'),
      onPressed: () => context.push(option.routePath),
      semanticLabel: [title, tagline, mode, ?days].join(', '),
      excludeChildSemantics: true,
      borderRadius: BorderRadius.zero,
      minSize: const Size(UiSize.tap, 220),
      child: AnimatedContainer(
        duration: UiMotion.of(context, UiMotion.theme),
        constraints: const BoxConstraints(minHeight: 220),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: option.isCustom ? ui.border : ink),
        ),
        child: content,
      ),
    );
  }
}
