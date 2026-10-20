import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/couple_rituals_localizations.dart';

/// Temporary `CoupleMosaicPosterShareCard` (task F1). The owner of this persona replaces
/// the body; keep the constructor so the registry and the screens keep working.
class CoupleMosaicPosterShareCard extends StatelessWidget {
  const CoupleMosaicPosterShareCard({required this.data, super.key});

  final PersonaShareData data;

  @override
  Widget build(BuildContext context) {
    final l10n = CoupleRitualsL10n.of(context);
    return PlaceholderShareBoard(
      data: data,
      styleName: l10n.couple_rituals_name,
      facts: [
        l10n.couple_rituals_dayLabel(data.dayNumber),
        l10n.couple_rituals_streakLabel(data.currentStreak),
        l10n.couple_rituals_checkInsLabel(data.checkIns.length),
      ],
    );
  }
}
