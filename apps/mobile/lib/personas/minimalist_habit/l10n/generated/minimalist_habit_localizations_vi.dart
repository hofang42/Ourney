// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'minimalist_habit_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class MinimalistHabitL10nVi extends MinimalistHabitL10n {
  MinimalistHabitL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get minimalist_habit_name => 'Thói quen tối giản';

  @override
  String minimalist_habit_dayLabel(int day) {
    return 'Ngày $day';
  }

  @override
  String minimalist_habit_streakLabel(int streak) {
    return 'Chuỗi $streak ngày';
  }

  @override
  String minimalist_habit_checkInsLabel(int count) {
    return '$count lần check-in';
  }
}
