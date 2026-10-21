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

  @override
  String quiet_transformer_vaultPill(int day) {
    return 'Private Vault · Day $day';
  }

  @override
  String get quiet_transformer_ghostOn => 'Ghost Align: ON (30%)';

  @override
  String get quiet_transformer_ghostOff => 'Ghost Align: OFF';

  @override
  String quiet_transformer_metricSliderLabel(String name) {
    return 'Today\'s $name';
  }

  @override
  String quiet_transformer_trendTitle(String name) {
    return '$name Trend';
  }

  @override
  String get quiet_transformer_trendEmpty =>
      'Log a metric on check-in to plot your curve';

  @override
  String get quiet_transformer_trendSingle =>
      'First point logged · Add another day to connect the curve';

  @override
  String get quiet_transformer_metricHiddenBadge => 'Metric hidden for privacy';

  @override
  String get quiet_transformer_milestoneStart => 'DAY 01 · START';

  @override
  String quiet_transformer_milestoneWeek(String day) {
    return 'DAY $day · MILESTONE';
  }

  @override
  String quiet_transformer_milestoneToday(String day) {
    return 'DAY $day · TODAY';
  }

  @override
  String quiet_transformer_milestoneDay(String day) {
    return 'DAY $day';
  }

  @override
  String get quiet_transformer_compareDayStart => 'DAY 01';

  @override
  String quiet_transformer_compareDayNow(String day) {
    return 'DAY $day';
  }

  @override
  String get quiet_transformer_hideExactWeight => 'Hide Exact Weight';

  @override
  String get quiet_transformer_hideExactWeightSub =>
      'Only show transformation delta or streak when sharing';

  @override
  String quiet_transformer_transformationBadge(String delta) {
    return '$delta Transformation';
  }

  @override
  String get quiet_transformer_exportCard => 'Export Progress Card';

  @override
  String get quiet_transformer_waitingPhoto => 'No photo yet';
}
