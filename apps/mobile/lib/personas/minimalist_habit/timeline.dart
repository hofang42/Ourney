import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/minimalist_habit_localizations.dart';

/// Temporary `ChainCalendarGridTimeline` (task F1). The owner of this persona replaces
/// the body; keep the constructor so the registry and the screens keep working.
class ChainCalendarGridTimeline extends StatelessWidget {
  const ChainCalendarGridTimeline({required this.data, super.key});

  final PersonaTimelineData data;

  @override
  Widget build(BuildContext context) {
    final l10n = MinimalistHabitL10n.of(context);
    return PlaceholderTimeline(
      data: data,
      styleName: l10n.minimalist_habit_name,
      dayLabel: l10n.minimalist_habit_dayLabel(data.dayNumber),
    );
  }
}
