// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'aesthetic_flexer_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AestheticFlexerL10nVi extends AestheticFlexerL10n {
  AestheticFlexerL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get aesthetic_flexer_name => 'Khoe nhịp tập';

  @override
  String aesthetic_flexer_dayLabel(int day) {
    return 'Ngày $day';
  }

  @override
  String aesthetic_flexer_streakLabel(int streak) {
    return 'Chuỗi $streak ngày';
  }

  @override
  String aesthetic_flexer_checkInsLabel(int count) {
    return '$count lần check-in';
  }

  @override
  String aesthetic_flexer_telemetryHeader(String total, String latest) {
    return '$total TỔNG · $latest GẦN NHẤT';
  }

  @override
  String aesthetic_flexer_activeDaysHeader(int active, int total, int streak) {
    return '$active/$total NGÀY TẬP · 🔥 $streak CHUỖI';
  }

  @override
  String get aesthetic_flexer_milestoneStart => 'NGÀY 01 · KHỞI ĐỘNG';

  @override
  String aesthetic_flexer_milestoneStar(String day) {
    return 'NGÀY $day ★ CỘT MỐC';
  }

  @override
  String aesthetic_flexer_milestoneToday(String day) {
    return 'NGÀY $day · HÔM NAY';
  }

  @override
  String aesthetic_flexer_milestoneDay(String day) {
    return 'NGÀY $day';
  }

  @override
  String get aesthetic_flexer_styleBoldHud => 'Bold HUD';

  @override
  String get aesthetic_flexer_styleMinimalStamp => 'Minimal Stamp';

  @override
  String get aesthetic_flexer_styleFilmStrip => 'Film Strip';

  @override
  String aesthetic_flexer_daysActiveBadge(int count) {
    return '$count NGÀY ĐÃ TẬP';
  }

  @override
  String get aesthetic_flexer_shareStoryButton => 'Chia sẻ lên Story';

  @override
  String get aesthetic_flexer_waitingPhoto => 'Chưa có ảnh tập';
}
