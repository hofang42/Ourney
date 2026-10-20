import 'package:flutter/material.dart';

import '../persona_contract.dart';
import '../persona_placeholder.dart';
import 'l10n/generated/aesthetic_flexer_localizations.dart';

/// Temporary `AthleticTelemetryTimeline` (task F1). The owner of this persona replaces
/// the body; keep the constructor so the registry and the screens keep working.
class AthleticTelemetryTimeline extends StatelessWidget {
  const AthleticTelemetryTimeline({required this.data, super.key});

  final PersonaTimelineData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AestheticFlexerL10n.of(context);
    return PlaceholderTimeline(
      data: data,
      styleName: l10n.aesthetic_flexer_name,
      dayLabel: l10n.aesthetic_flexer_dayLabel(data.dayNumber),
    );
  }
}
