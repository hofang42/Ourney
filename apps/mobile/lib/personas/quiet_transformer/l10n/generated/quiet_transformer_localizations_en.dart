// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'quiet_transformer_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class QuietTransformerL10nEn extends QuietTransformerL10n {
  QuietTransformerL10nEn([String locale = 'en']) : super(locale);

  @override
  String get quiet_transformer_name => 'Quiet Transformer';

  @override
  String quiet_transformer_dayLabel(int day) {
    return 'Day $day';
  }

  @override
  String quiet_transformer_streakLabel(int streak) {
    return '$streak-day streak';
  }

  @override
  String quiet_transformer_checkInsLabel(int count) {
    return '$count check-ins';
  }
}
