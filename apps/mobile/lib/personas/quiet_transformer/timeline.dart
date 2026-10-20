import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/quiet_transformer_localizations.dart';

/// Temporary `ConnectedWeightCurveTimeline` (task F1). The owner of this persona replaces
/// the body; keep the constructor so the registry and the screens keep working.
class ConnectedWeightCurveTimeline extends StatelessWidget {
  const ConnectedWeightCurveTimeline({required this.data, super.key});

  final PersonaTimelineData data;

  @override
  Widget build(BuildContext context) {
    final l10n = QuietTransformerL10n.of(context);
    return PlaceholderTimeline(
      data: data,
      styleName: l10n.quiet_transformer_name,
      dayLabel: l10n.quiet_transformer_dayLabel(data.dayNumber),
    );
  }
}
