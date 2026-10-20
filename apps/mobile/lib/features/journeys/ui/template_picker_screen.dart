import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/theme/tokens.dart';
import '../../../shared/ourney_card.dart';
import '../../../shared/template_icons.dart';
import '../journeys_paths.dart';
import '../l10n/generated/journeys_localizations.dart';

/// Step 1 of the create flow (`/journeys/new`): one of the 4 templates or
/// Custom (FR-B1).
class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = JourneysL10n.of(context);
    final text = Theme.of(context).textTheme;
    final c = OurneyColors.of(context);
    final en = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      key: const ValueKey('journeys-template-picker'),
      appBar: AppBar(title: Text(l10n.journeys_pickTemplateTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(OurneySpacing.screenMargin),
          children: [
            for (final t in allTemplates)
              Padding(
                padding: const EdgeInsets.only(bottom: OurneySpacing.md),
                child: OurneyCard(
                  key: ValueKey('template-${t.id.wireName}'),
                  onTap: () =>
                      context.push(JourneysPaths.newFromTemplate(t.id)),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          templateIcon(t.id),
                          size: 32,
                          color: OurneyColors.of(context).ink,
                        ),
                      ),
                      const SizedBox(width: OurneySpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              en ? t.titleEn : t.titleVi,
                              style: text.titleMedium,
                            ),
                            const SizedBox(height: OurneySpacing.xs),
                            Text(
                              t.id == TemplateId.custom
                                  ? l10n.journeys_templateCustomHint
                                  : l10n.journeys_templateDays(
                                      t.defaultDurationDays,
                                    ),
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: c.inkMuted),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
