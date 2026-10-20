import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/minimalist_habit_localizations.dart';

/// Temporary `ZeroText3SecHud` (task F1). The owner of this persona replaces
/// the body; keep the constructor and keep drawing [PersonaCameraData.viewfinder].
class ZeroText3SecHud extends StatelessWidget {
  const ZeroText3SecHud({required this.data, super.key});

  final PersonaCameraData data;

  @override
  Widget build(BuildContext context) {
    final l10n = MinimalistHabitL10n.of(context);
    return PlaceholderHud(
      data: data,
      label:
          '${l10n.minimalist_habit_name} · ${l10n.minimalist_habit_streakLabel(data.currentStreak)}',
    );
  }
}
