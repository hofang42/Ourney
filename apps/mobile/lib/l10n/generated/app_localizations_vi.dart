// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get app_name => 'Ourney';

  @override
  String get journeyStyle_quietTransformer => 'Lặng lẽ đổi thay';

  @override
  String get journeyStyle_accountabilitySquad => 'Đội cùng cam kết';

  @override
  String get journeyStyle_memoryCollectors => 'Người lưu giữ ký ức';

  @override
  String get journeyStyle_coupleRituals => 'Nghi thức đôi lứa';

  @override
  String get journeyStyle_aestheticFlexer => 'Khoe nét thẩm mỹ';

  @override
  String get journeyStyle_minimalistHabit => 'Thói quen tối giản';

  @override
  String get journeyStyle_glowRitual => 'Nghi thức tỏa sáng';

  @override
  String get journeyStyle_littleMilestones => 'Cột mốc nhỏ';

  @override
  String get journeyStyle_pawGrowth => 'Lớn lên cùng thú cưng';

  @override
  String get journeyStyle_blueprintMakeover => 'Lột xác theo bản vẽ';

  @override
  String get nav_journeys => 'Hành trình';

  @override
  String get nav_capture => 'Chụp';

  @override
  String get nav_groups => 'Nhóm';

  @override
  String get nav_activity => 'Hoạt động';

  @override
  String get nav_profileTab => 'Hồ sơ';

  @override
  String get nav_profile => 'Hồ sơ và cài đặt';

  @override
  String get common_retry => 'Thử lại';

  @override
  String get common_cancel => 'Hủy';

  @override
  String get common_ok => 'OK';

  @override
  String get common_close => 'Đóng';

  @override
  String get common_save => 'Lưu';

  @override
  String get common_loading => 'Đang tải…';

  @override
  String get common_errorGeneric => 'Có lỗi xảy ra. Thử lại nhé.';

  @override
  String get common_offline =>
      'Bạn đang offline. Ourney sẽ tự đồng bộ khi có mạng.';

  @override
  String get empty_default_title => 'Chưa có gì ở đây';

  @override
  String streak_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return '$_temp0';
  }

  @override
  String streak_semantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return 'Chuỗi $_temp0';
  }

  @override
  String get streak_atRisk => 'Sắp mất chuỗi';

  @override
  String get needsServer_title => 'Cần kết nối máy chủ';

  @override
  String get needsServer_message =>
      'Bản này đang chạy chế độ chỉ trên máy. Hành trình một mình vẫn dùng bình thường, còn nhóm thì cần máy chủ.';

  @override
  String get placeholder_comingSoon => 'Sắp ra mắt';

  @override
  String get reminderBanner_now => 'bây giờ';

  @override
  String get reminderBanner_close => 'Đóng';

  @override
  String get reminderBanner_appName => 'Ourney';

  @override
  String get reminderBanner_daily_quiet =>
      'Đến giờ của bạn rồi. Một tấm là đủ.';

  @override
  String get reminderBanner_daily_squad =>
      'Tới giờ điểm danh! Cả nhóm đang chờ.';

  @override
  String get reminderBanner_daily_memory =>
      'Thêm một khung hình cho cuộn phim?';

  @override
  String get reminderBanner_daily_couple => 'Hai đứa ơi, đến giờ rồi.';

  @override
  String get reminderBanner_daily_flexer => 'ĐẾN GIỜ. CHẠY ĐI.';

  @override
  String reminderBanner_daily_minimal(int day) {
    return 'NGÀY $day.';
  }

  @override
  String reminderBanner_streak_quiet(int streak, String time) {
    return 'Chuỗi $streak ngày còn đến $time. Vẫn kịp.';
  }

  @override
  String reminderBanner_streak_squad(int streak, String time) {
    return 'Chuỗi $streak sắp đứt lúc $time. Chụp ngay nào!';
  }

  @override
  String reminderBanner_streak_memory(String time) {
    return 'Cuộn phim còn mở đến $time.';
  }

  @override
  String reminderBanner_streak_couple(int streak, String time) {
    return 'Chuỗi $streak ngày sắp đứt lúc $time.';
  }

  @override
  String reminderBanner_streak_flexer(int streak, String time) {
    return 'CHUỖI $streak. CÒN ĐẾN $time.';
  }

  @override
  String reminderBanner_streak_minimal(int streak, String time) {
    return 'CHUỖI $streak. $time.';
  }

  @override
  String missedDay_chipSquad(int day) {
    return 'NGÀY $day · LỠ';
  }

  @override
  String missedDay_chipQuiet(int day) {
    return 'NGÀY $day · NGHỈ';
  }

  @override
  String get missedDay_titleSquad => 'ngày lỡ.';

  @override
  String get missedDay_titleQuiet => 'ngày nghỉ.';

  @override
  String get missedDay_bodySquad => 'Lỡ một hôm thôi. Mai về lại đường nào!';

  @override
  String get missedDay_bodyQuiet => 'Một ngày nghỉ không xóa hành trình.';

  @override
  String get missedDay_dismiss => 'Đã hiểu';
}
