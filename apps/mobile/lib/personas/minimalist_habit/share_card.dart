import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/minimalist_habit_localizations.dart';

/// Temporary `ZenSummaryCardShareCard` (task F1). The owner of this persona replaces
/// the body; keep the constructor so the registry and the screens keep working.
class ZenSummaryCardShareCard extends StatelessWidget {
  const ZenSummaryCardShareCard({required this.data, super.key});

  final PersonaShareData data;

  @override
  Widget build(BuildContext context) {
    final l10n = MinimalistHabitL10n.of(context);
    return PlaceholderShareBoard(
      data: data,
      styleName: l10n.minimalist_habit_name,
      facts: [
        l10n.minimalist_habit_dayLabel(data.dayNumber),
        l10n.minimalist_habit_streakLabel(data.currentStreak),
        l10n.minimalist_habit_checkInsLabel(data.checkIns.length),
      ],
    );
  }
}
