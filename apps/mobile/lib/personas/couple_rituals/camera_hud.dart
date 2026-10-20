import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/couple_rituals_localizations.dart';

/// Temporary `HalfFrameDuoHud` (task F1). The owner of this persona replaces
/// the body; keep the constructor and keep drawing [PersonaCameraData.viewfinder].
class HalfFrameDuoHud extends StatelessWidget {
  const HalfFrameDuoHud({required this.data, super.key});

  final PersonaCameraData data;

  @override
  Widget build(BuildContext context) {
    final l10n = CoupleRitualsL10n.of(context);
    return PlaceholderHud(
      data: data,
      label:
          '${l10n.couple_rituals_name} · ${l10n.couple_rituals_streakLabel(data.currentStreak)}',
    );
  }
}
