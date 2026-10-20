// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'accountability_squad_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AccountabilitySquadL10nVi extends AccountabilitySquadL10n {
  AccountabilitySquadL10nVi([String locale = 'vi']) : super(locale);

  @override
  String accountability_squad_daysDuration(int days) {
    return '$days NGÀY';
  }

  @override
  String get accountability_squad_openDuration => 'HẰNG NGÀY';

  @override
  String accountability_squad_dayGoalTrophy(int day) {
    return 'MỤC TIÊU NGÀY $day';
  }

  @override
  String accountability_squad_dayStartLabel(String day) {
    return 'NGÀY $day · BẮT ĐẦU';
  }

  @override
  String accountability_squad_dayTodayLabel(String day) {
    return 'NGÀY $day · HÔM NAY';
  }

  @override
  String accountability_squad_dayWeekMilestone(String day, int week) {
    return 'NGÀY $day ★ TUẦN $week';
  }

  @override
  String accountability_squad_dayRegularLabel(String day) {
    return 'NGÀY $day';
  }

  @override
  String get accountability_squad_missedSlot => 'Chưa chụp';

  @override
  String accountability_squad_studyMetricBadge(String value, String unit) {
    return '$value $unit HỌC';
  }

  @override
  String accountability_squad_streakBadge(int streak) {
    return '$streak CHUỖI NGÀY';
  }

  @override
  String accountability_squad_checkedInProgress(int done, int total) {
    return '$done/$total ĐÃ CHECK-IN HÔM NAY';
  }

  @override
  String accountability_squad_memberWaiting(String name) {
    return '$name · ĐANG CHỜ';
  }

  @override
  String get accountability_squad_waitingHint => 'Chưa check-in hôm nay';

  @override
  String get accountability_squad_emptySquad =>
      'Chưa có thành viên nào trong nhóm này.';

  @override
  String get accountability_squad_addReaction => 'Thả cảm xúc';

  @override
  String accountability_squad_nudge(String name) {
    return 'Nhắc $name';
  }
}
