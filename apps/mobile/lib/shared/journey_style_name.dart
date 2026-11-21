import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';
import '../ui/journey_styles.dart';

/// Localized display name of [style] (bug U20): `UiJourneyStyle.name` is an
/// internal English identifier and must not reach the screen.
String journeyStyleName(BuildContext context, UiJourneyStyle style) {
  final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
  if (l10n == null) return style.name;
  final names = [
    l10n.journeyStyle_quietTransformer,
    l10n.journeyStyle_accountabilitySquad,
    l10n.journeyStyle_memoryCollectors,
    l10n.journeyStyle_coupleRituals,
    l10n.journeyStyle_aestheticFlexer,
    l10n.journeyStyle_minimalistHabit,
    l10n.journeyStyle_glowRitual,
    l10n.journeyStyle_littleMilestones,
    l10n.journeyStyle_pawGrowth,
    l10n.journeyStyle_blueprintMakeover,
  ];
  final i = uiJourneyStyles.indexOf(style);
  return i < 0 ? style.name : names[i];
}
