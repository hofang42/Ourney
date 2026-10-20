import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/quiet_transformer_localizations.dart';

/// Temporary `GhostAlignVaultHud` (task F1). The owner of this persona replaces
/// the body; keep the constructor and keep drawing [PersonaCameraData.viewfinder].
class GhostAlignVaultHud extends StatelessWidget {
  const GhostAlignVaultHud({required this.data, super.key});

  final PersonaCameraData data;

  @override
  Widget build(BuildContext context) {
    final l10n = QuietTransformerL10n.of(context);
    return PlaceholderHud(
      data: data,
      label:
          '${l10n.quiet_transformer_name} · ${l10n.quiet_transformer_streakLabel(data.currentStreak)}',
    );
  }
}
