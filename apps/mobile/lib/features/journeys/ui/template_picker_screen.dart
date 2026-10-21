import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/motion.dart';
import '../../../app/theme/persona_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/ourney_card.dart';
import '../../../shared/persona_pill.dart';
import '../../../shared/template_icons.dart';
import '../journeys_paths.dart';
import '../l10n/generated/journeys_localizations.dart';

/// Descriptor of one of the 6 persona style options on `TemplatePickerScreen` (J2).
class _PersonaTemplateOption {
  const _PersonaTemplateOption({
    required this.keyName,
    required this.templateId,
    required this.skinId,
    required this.emoji,
    required this.routePath,
    this.isCouple = false,
  });

  final String keyName;
  final TemplateId templateId;
  final PersonaSkinId skinId;
  final String emoji;
  final String routePath;
  final bool isCouple;
}

/// **Task J2** (`TemplatePickerScreen` — Step 1 of `/journeys/new`):
/// - Lists all **6 persona style cards**: the 5 `JourneyTemplate`s plus the
///   6th `Couple Rituals` option (`TemplateId.custom` with `💞`, `PersonaSkinId.coupleRituals`).
/// - **Live Chameleon Preview**: selecting or previewing any card morphs the
///   screen's theme (`AnimatedTheme`, `320ms`) and displays that persona's
///   reference design board (`designAssetForPersona(skinId)`).
/// - Tapping a card navigates directly to its create form (`template-<wireName>`
///   or `template-couple`).
class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key});

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  PersonaSkinId _previewSkin = PersonaSkinId.quietTransformer;

  List<_PersonaTemplateOption> _buildOptions() => [
    for (final t in allTemplates.where((t) => t.id != TemplateId.custom))
      _PersonaTemplateOption(
        keyName: t.id.wireName,
        templateId: t.id,
        skinId: t.personaSkinId,
        emoji: t.emoji,
        routePath: JourneysPaths.newFromTemplate(t.id),
      ),
    _PersonaTemplateOption(
      keyName: 'couple',
      templateId: TemplateId.custom,
      skinId: PersonaSkinId.coupleRituals,
      emoji: '💞',
      routePath: JourneysPaths.newCoupleRitual,
      isCouple: true,
    ),
    _PersonaTemplateOption(
      keyName: TemplateId.custom.wireName,
      templateId: TemplateId.custom,
      skinId: PersonaSkinId.minimalistHabit,
      emoji: '✨',
      routePath: JourneysPaths.newFromTemplate(TemplateId.custom),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final brightness = Theme.of(context).brightness;
    final en = Localizations.localeOf(context).languageCode == 'en';
    final options = _buildOptions();
    final previewPersona = OurneyPersonaTheme.forSkin(_previewSkin, brightness);
    final previewAsset = designAssetForPersona(_previewSkin);

    return AnimatedTheme(
      data: buildAppTheme(brightness, _previewSkin).copyWith(
        scaffoldBackgroundColor: previewPersona.background,
      ),
      duration: OurneyMotion.duration(context, OurneyDurations.personaTheme),
      curve: Curves.easeOutCubic,
      child: Builder(
        builder: (context) {
          final pTheme = OurneyPersonaTheme.of(context);
          final text = Theme.of(context).textTheme;
          return Scaffold(
            key: const ValueKey('journeys-template-picker'),
            backgroundColor: pTheme.background,
            appBar: AppBar(
              backgroundColor: pTheme.background,
              foregroundColor: pTheme.ink,
              title: Text(l10n.journeys_pickTemplateTitle),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(OurneySpacing.screenMargin),
                children: [
                  for (final opt in options)
                    Builder(
                      builder: (context) {
                        final tpl = templateFor(opt.templateId);
                        final cardPersona = OurneyPersonaTheme.forSkin(
                          opt.skinId,
                          brightness,
                        );
                        final isPreviewed = _previewSkin == opt.skinId;
                        final title = opt.isCouple
                            ? l10n.journeys_templateCoupleTitle
                            : (en ? tpl.titleEn : tpl.titleVi);
                        final subtitle = opt.isCouple
                            ? l10n.journeys_templateCoupleHint
                            : (opt.templateId == TemplateId.custom
                                  ? l10n.journeys_templateCustomHint
                                  : l10n.journeys_templateDays(
                                      tpl.defaultDurationDays,
                                    ));

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: OurneySpacing.md,
                          ),
                          child: OurneyCard(
                            key: ValueKey('template-${opt.keyName}'),
                            onTap: () {
                              setState(() => _previewSkin = opt.skinId);
                              context.push(opt.routePath);
                            },
                            child: Row(
                              children: [
                                ExcludeSemantics(
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: cardPersona.primaryAccent
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(
                                        OurneyRadii.chip,
                                      ),
                                      border: Border.all(
                                        color: isPreviewed
                                            ? cardPersona.primaryAccent
                                            : cardPersona.primaryAccent
                                                  .withValues(alpha: 0.35),
                                        width: isPreviewed ? 2 : 1,
                                      ),
                                    ),
                                    child: Icon(
                                      journeyIcon(opt.emoji, opt.templateId),
                                      size: 26,
                                      color: cardPersona.primaryAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: OurneySpacing.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.titleMedium?.copyWith(
                                          color: pTheme.ink,
                                        ),
                                      ),
                                      const SizedBox(height: OurneySpacing.xs),
                                      Text(
                                        subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.bodySmall?.copyWith(
                                          color: pTheme.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey(
                                    'template-preview-${opt.keyName}',
                                  ),
                                  tooltip: l10n.journeys_personaPreviewLabel,
                                  onPressed: () =>
                                      setState(() => _previewSkin = opt.skinId),
                                  icon: Icon(
                                    isPreviewed
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_outlined,
                                    color: isPreviewed
                                        ? cardPersona.primaryAccent
                                        : pTheme.inkMuted,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: pTheme.inkMuted,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: OurneySpacing.sm),
                  // Live Chameleon Design Reference Board Preview
                  Container(
                    key: const ValueKey('template-design-preview-card'),
                    padding: const EdgeInsets.all(OurneySpacing.md),
                    decoration: BoxDecoration(
                      color: pTheme.surface,
                      borderRadius: BorderRadius.circular(pTheme.cardRadius),
                      border: Border.all(
                        color: pTheme.border,
                        width: pTheme.borderWidth,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: PersonaPill(
                            icon: Icons.palette_rounded,
                            emphasized: true,
                            label: l10n.journeys_personaPreviewLabel,
                          ),
                        ),
                        const SizedBox(height: OurneySpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: Image.asset(
                              previewAsset,
                              key: ValueKey('template-asset-$previewAsset'),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: pTheme.surfaceElevated,
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: pTheme.inkMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
