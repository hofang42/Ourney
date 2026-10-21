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

  @override
  String minimalist_habit_monthStreakHeader(int month, int streak) {
    return 'THÁNG $month · CHUỖI $streak NGÀY';
  }

  @override
  String minimalist_habit_cameraPill(String title, int day) {
    return '$title · NGÀY $day';
  }

  @override
  String get minimalist_habit_quickSnapHint => '1 chạm · Không cần gõ chữ';

  @override
  String minimalist_habit_summaryCompleted(int done, int total) {
    return '$done / $total NGÀY HOÀN THÀNH';
  }

  @override
  String minimalist_habit_summaryOpen(int done) {
    return '$done NGÀY HOÀN THÀNH';
  }

  @override
  String minimalist_habit_summaryConsistency(int percent) {
    return '$percent% ĐỀU ĐẶN';
  }

  @override
  String get minimalist_habit_exportCardButton => 'Xuất thiệp tối giản';

  @override
  String get minimalist_habit_noPhotoYet => 'Chưa có ảnh';
}
