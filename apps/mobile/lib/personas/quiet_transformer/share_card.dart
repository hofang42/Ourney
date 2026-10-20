import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/quiet_transformer_localizations.dart';

/// Temporary `SideBySideArchiveShareCard` (task F1). The owner of this persona replaces
/// the body; keep the constructor so the registry and the screens keep working.
class SideBySideArchiveShareCard extends StatelessWidget {
  const SideBySideArchiveShareCard({required this.data, super.key});

  final PersonaShareData data;

  @override
  Widget build(BuildContext context) {
    final l10n = QuietTransformerL10n.of(context);
    return PlaceholderShareBoard(
      data: data,
      styleName: l10n.quiet_transformer_name,
      facts: [
        l10n.quiet_transformer_dayLabel(data.dayNumber),
        l10n.quiet_transformer_streakLabel(data.currentStreak),
        l10n.quiet_transformer_checkInsLabel(data.checkIns.length),
      ],
    );
  }
}
