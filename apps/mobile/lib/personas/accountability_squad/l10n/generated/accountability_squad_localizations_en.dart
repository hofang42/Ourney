// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'accountability_squad_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AccountabilitySquadL10nEn extends AccountabilitySquadL10n {
  AccountabilitySquadL10nEn([String locale = 'en']) : super(locale);

  @override
  String accountability_squad_daysDuration(int days) {
    return '$days DAYS';
  }

  @override
  String get accountability_squad_openDuration => 'DAILY';

  @override
  String accountability_squad_dayGoalTrophy(int day) {
    return 'DAY $day GOAL';
  }

  @override
  String accountability_squad_dayStartLabel(String day) {
    return 'DAY $day · START';
  }

  @override
  String accountability_squad_dayTodayLabel(String day) {
    return 'DAY $day · TODAY';
  }

  @override
  String accountability_squad_dayWeekMilestone(String day, int week) {
    return 'DAY $day ★ WEEK $week';
  }

  @override
  String accountability_squad_dayRegularLabel(String day) {
    return 'DAY $day';
  }

  @override
  String get accountability_squad_missedSlot => 'Not snapped yet';

  @override
  String accountability_squad_studyMetricBadge(String value, String unit) {
    return '$value $unit STUDY';
  }

  @override
  String accountability_squad_streakBadge(int streak) {
    return '$streak STREAK';
  }

  @override
  String accountability_squad_checkedInProgress(int done, int total) {
    return '$done/$total CHECKED IN TODAY';
  }

  @override
  String accountability_squad_memberWaiting(String name) {
    return '$name · WAITING';
  }

  @override
  String get accountability_squad_waitingHint => 'Hasn\'t checked in today';

  @override
  String get accountability_squad_emptySquad => 'No members in this squad yet.';

  @override
  String get accountability_squad_addReaction => 'Add a reaction';

  @override
  String accountability_squad_nudge(String name) {
    return 'Nudge $name';
  }
}
