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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count check-ins',
      one: '1 check-in',
    );
    return '$_temp0';
  }

  @override
  String aesthetic_flexer_telemetryHeader(String total, String latest) {
    return '$total TOTAL · $latest LATEST';
  }

  @override
  String aesthetic_flexer_activeDaysHeader(int active, int total, int streak) {
    return '$active/$total DAYS ACTIVE · 🔥 $streak STREAK';
  }

  @override
  String get aesthetic_flexer_milestoneStart => 'DAY 01 · START';

  @override
  String aesthetic_flexer_milestoneStar(String day) {
    return 'DAY $day ★ MILESTONE';
  }

  @override
  String aesthetic_flexer_milestoneToday(String day) {
    return 'DAY $day · TODAY';
  }

  @override
  String aesthetic_flexer_milestoneDay(String day) {
    return 'DAY $day';
  }

  @override
  String get aesthetic_flexer_styleBoldHud => 'Bold HUD';

  @override
  String get aesthetic_flexer_styleMinimalStamp => 'Minimal Stamp';

  @override
  String get aesthetic_flexer_styleFilmStrip => 'Film Strip';

  @override
  String aesthetic_flexer_daysActiveBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count DAYS ACTIVE',
      one: '1 DAY ACTIVE',
    );
    return '$_temp0';
  }

  @override
  String get aesthetic_flexer_shareStoryButton => 'Share to Story';

  @override
  String get aesthetic_flexer_waitingPhoto => 'No workout photo';
}
