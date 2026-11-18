// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'Ourney';

  @override
  String get journeyStyle_quietTransformer => 'Quiet Transformer';

  @override
  String get journeyStyle_accountabilitySquad => 'Accountability Squad';

  @override
  String get journeyStyle_memoryCollectors => 'Memory Collectors';

  @override
  String get journeyStyle_coupleRituals => 'Couple Rituals';

  @override
  String get journeyStyle_aestheticFlexer => 'Aesthetic Flexer';

  @override
  String get journeyStyle_minimalistHabit => 'Minimalist Habit';

  @override
  String get journeyStyle_glowRitual => 'Glow Ritual';

  @override
  String get journeyStyle_littleMilestones => 'Little Milestones';

  @override
  String get journeyStyle_pawGrowth => 'Paw Growth';

  @override
  String get journeyStyle_blueprintMakeover => 'Blueprint Makeover';

  @override
  String get nav_journeys => 'Journeys';

  @override
  String get nav_capture => 'Capture';

  @override
  String get nav_groups => 'Squad';

  @override
  String get nav_activity => 'Activity';

  @override
  String get nav_profileTab => 'Profile';

  @override
  String get nav_profile => 'Profile and settings';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_ok => 'OK';

  @override
  String get common_close => 'Close';

  @override
  String get common_save => 'Save';

  @override
  String get common_loading => 'Loading…';

  @override
  String get common_errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get common_offline =>
      'You\'re offline. Ourney will sync when you\'re back online.';

  @override
  String get empty_default_title => 'Nothing here yet';

  @override
  String streak_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String streak_semantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return 'Streak of $_temp0';
  }

  @override
  String get streak_atRisk => 'Streak at risk';

  @override
  String get needsServer_title => 'Server needed';

  @override
  String get needsServer_message =>
      'This build runs in on-device mode. Solo journeys work as usual; groups need a server.';

  @override
  String get placeholder_comingSoon => 'Coming soon';

  @override
  String get reminderBanner_now => 'now';

  @override
  String get reminderBanner_close => 'Close';

  @override
  String get reminderBanner_appName => 'Ourney';

  @override
  String get reminderBanner_daily_quiet =>
      'It\'s your time. One photo is enough.';

  @override
  String get reminderBanner_daily_squad =>
      'Check-in time! The whole squad is waiting.';

  @override
  String get reminderBanner_daily_memory => 'Add one more frame to the roll?';

  @override
  String get reminderBanner_daily_couple => 'You two, it\'s time.';

  @override
  String get reminderBanner_daily_flexer => 'TIME. GO RUN.';

  @override
  String reminderBanner_daily_minimal(int day) {
    return 'DAY $day.';
  }

  @override
  String reminderBanner_streak_quiet(int streak, String time) {
    return 'Your $streak-day streak is open until $time. Still time.';
  }

  @override
  String reminderBanner_streak_squad(int streak, String time) {
    return 'Streak $streak breaks at $time. Snap now!';
  }

  @override
  String reminderBanner_streak_memory(String time) {
    return 'The film roll stays open until $time.';
  }

  @override
  String reminderBanner_streak_couple(int streak, String time) {
    return 'Your $streak-day streak breaks at $time.';
  }

  @override
  String reminderBanner_streak_flexer(int streak, String time) {
    return 'STREAK $streak. OPEN UNTIL $time.';
  }

  @override
  String reminderBanner_streak_minimal(int streak, String time) {
    return 'STREAK $streak. $time.';
  }

  @override
  String missedDay_chipSquad(int day) {
    return 'DAY $day · MISSED';
  }

  @override
  String missedDay_chipQuiet(int day) {
    return 'DAY $day · REST';
  }

  @override
  String get missedDay_titleSquad => 'missed day.';

  @override
  String get missedDay_titleQuiet => 'rest day.';

  @override
  String get missedDay_bodySquad =>
      'Just one day missed. Back on track tomorrow!';

  @override
  String get missedDay_bodyQuiet => 'A rest day does not erase the journey.';

  @override
  String get missedDay_dismiss => 'Got it';
}
