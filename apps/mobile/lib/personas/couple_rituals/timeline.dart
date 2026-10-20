import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/couple_rituals_localizations.dart';

/// Temporary `DuoSplitTimeline` (task F1). The owner of this persona replaces
/// the body; keep the constructor so the registry and the screens keep working.
class DuoSplitTimeline extends StatelessWidget {
  const DuoSplitTimeline({required this.data, super.key});

  final PersonaTimelineData data;

  @override
  Widget build(BuildContext context) {
    final l10n = CoupleRitualsL10n.of(context);
    return PlaceholderTimeline(
      data: data,
      styleName: l10n.couple_rituals_name,
      dayLabel: l10n.couple_rituals_dayLabel(data.dayNumber),
    );
  }
}
