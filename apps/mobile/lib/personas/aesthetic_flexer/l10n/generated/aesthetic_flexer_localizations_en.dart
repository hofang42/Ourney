// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'aesthetic_flexer_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AestheticFlexerL10nEn extends AestheticFlexerL10n {
  AestheticFlexerL10nEn([String locale = 'en']) : super(locale);

  @override
  String get aesthetic_flexer_name => 'Aesthetic Flexer';

  @override
  String aesthetic_flexer_dayLabel(int day) {
    return 'Day $day';
  }

  @override
  String aesthetic_flexer_streakLabel(int streak) {
    return '$streak-day streak';
  }

  @override
  String aesthetic_flexer_checkInsLabel(int count) {
    return '$count check-ins';
  }
}
