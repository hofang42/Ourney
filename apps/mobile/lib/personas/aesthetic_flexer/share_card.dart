import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/aesthetic_flexer_localizations.dart';

/// Temporary `TransparentStoryStickerShareCard` (task F1). The owner of this persona replaces
/// the body; keep the constructor so the registry and the screens keep working.
class TransparentStoryStickerShareCard extends StatelessWidget {
  const TransparentStoryStickerShareCard({required this.data, super.key});

  final PersonaShareData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AestheticFlexerL10n.of(context);
    return PlaceholderShareBoard(
      data: data,
      styleName: l10n.aesthetic_flexer_name,
      facts: [
        l10n.aesthetic_flexer_dayLabel(data.dayNumber),
        l10n.aesthetic_flexer_streakLabel(data.currentStreak),
        l10n.aesthetic_flexer_checkInsLabel(data.checkIns.length),
      ],
    );
  }
}
