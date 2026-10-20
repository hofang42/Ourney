import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/aesthetic_flexer_localizations.dart';

/// Temporary `StravaStickerStudioHud` (task F1). The owner of this persona replaces
/// the body; keep the constructor and keep drawing [PersonaCameraData.viewfinder].
class StravaStickerStudioHud extends StatelessWidget {
  const StravaStickerStudioHud({required this.data, super.key});

  final PersonaCameraData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AestheticFlexerL10n.of(context);
    return PlaceholderHud(
      data: data,
      label:
          '${l10n.aesthetic_flexer_name} · ${l10n.aesthetic_flexer_streakLabel(data.currentStreak)}',
    );
  }
}
