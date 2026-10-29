import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/motion.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/dashed_border_painter.dart';
import '../../../shared/layout.dart';
import '../journeys_paths.dart';
import '../l10n/generated/journeys_localizations.dart';

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

/// **Template picker** (Step 1 of `/journeys/new`, V1.0 `TemplateGrid`):
/// a two-column grid of style cards, each painted in its journey style
/// (paper, ink, accent) with the persona's reference photo, tagline and
/// who can join, plus a dashed **Custom** card.
///
/// The 6th style, Couple Rituals, is `TemplateId.custom` with the `💞`
/// preset. Tapping a card opens its create form.
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
    final options = _options();
    final c = OurneyColors.of(context);
    return Scaffold(
      key: const ValueKey('journeys-template-picker'),
      backgroundColor: c.bg,
      appBar: AppBar(backgroundColor: c.bg),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final pad = OurneyLayout.horizontalPadding(width);
            final maxW = OurneyLayout.contentMaxWidth(width);
            const gap = 10.0;
            final rows = <Widget>[];
            for (var i = 0; i < options.length; i += 2) {
              rows.add(
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
              );
            }
            return Center(
              child: SizedBox(
                width: maxW,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(pad, 4, pad, 32),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.journeys_pickTemplateTitle,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...rows,
                  ],
                ),
              ),
            );
          },
        ),
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
    final brightness = Theme.of(context).brightness;
    final en = Localizations.localeOf(context).languageCode == 'en';
    final style = OurneyPersonaTheme.forSkin(option.skinId, brightness);
    final c = OurneyColors.of(context);
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

    final bg = option.isCustom ? c.surface : style.background;
    final ink = option.isCustom ? c.ink : style.ink;

    final Widget content;
    if (option.isCustom) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surfaceSunken,
            ),
            child: Icon(Icons.add_rounded, color: ink),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: displayStyle(size: 15, weight: 700, height: 1.3, color: ink),
          ),
          const SizedBox(height: 3),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 11,
              height: 1.4,
              color: ink.withValues(alpha: 0.72),
            ),
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
              border: Border(
                bottom: BorderSide(color: style.primaryAccent, width: 5),
              ),
            ),
            child: Image.asset(
              designAssetForPersona(option.skinId),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) =>
                  ColoredBox(color: style.surfaceElevated),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: displayStyle(size: 15, weight: 700, height: 1.3, color: ink),
          ),
          const SizedBox(height: 3),
          Text(
            tagline,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 11,
              height: 1.4,
              color: ink.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 8),
          const Spacer(),
          Text(
            [mode, ?days].join(' · ').toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              height: 1.35,
              color: ink,
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: [title, tagline, mode, ?days].join(', '),
      excludeSemantics: true,
      child: Material(
        color: bg,
        child: InkWell(
          key: ValueKey('template-${option.keyName}'),
          onTap: () => context.push(option.routePath),
          child: AnimatedContainer(
            duration: OurneyMotion.duration(
              context,
              OurneyDurations.personaTheme,
            ),
            constraints: const BoxConstraints(minHeight: 220),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: option.isCustom
                  ? null
                  : Border.all(
                      color: brightness == Brightness.dark ? c.border : ink,
                    ),
            ),
            foregroundDecoration: option.isCustom
                ? _DashedDecoration(color: c.border)
                : null,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Dashed outline for the Custom card (V1.0 `border-style: dashed`).
class _DashedDecoration extends Decoration {
  const _DashedDecoration({required this.color});

  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DashedBoxPainter(color);
}

class _DashedBoxPainter extends BoxPainter {
  _DashedBoxPainter(Color color) : _painter = DashedBorderPainter(color: color);

  final DashedBorderPainter _painter;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    _painter.paint(canvas, size);
    canvas.restore();
  }
}
