// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'minimalist_habit_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class MinimalistHabitL10nEn extends MinimalistHabitL10n {
  MinimalistHabitL10nEn([String locale = 'en']) : super(locale);

  @override
  String get minimalist_habit_name => 'Minimalist Habit';

  @override
  String minimalist_habit_dayLabel(int day) {
    return 'Day $day';
  }

  @override
  String minimalist_habit_streakLabel(int streak) {
    return '$streak-day streak';
  }

  @override
  String minimalist_habit_checkInsLabel(int count) {
    return '$count check-ins';
  }

  @override
  String minimalist_habit_monthStreakHeader(int month, int streak) {
    return 'MONTH $month · $streak DAY STREAK';
  }

  @override
  String minimalist_habit_cameraPill(String title, int day) {
    return '$title · DAY $day';
  }

  @override
  String get minimalist_habit_quickSnapHint => '1-tap · Zero text';

  @override
  String minimalist_habit_summaryCompleted(int done, int total) {
    return '$done / $total DAYS COMPLETED';
  }

  @override
  String minimalist_habit_summaryOpen(int done) {
    return '$done DAYS COMPLETED';
  }

  @override
  String minimalist_habit_summaryConsistency(int percent) {
    return '$percent% CONSISTENCY';
  }

  @override
  String get minimalist_habit_exportCardButton => 'Export Minimal Card';

  @override
  String get minimalist_habit_noPhotoYet => 'No photo yet';
}
