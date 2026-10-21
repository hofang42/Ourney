// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'quiet_transformer_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class QuietTransformerL10nVi extends QuietTransformerL10n {
  QuietTransformerL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get quiet_transformer_name => 'Thay đổi thầm lặng';

  @override
  String quiet_transformer_dayLabel(int day) {
    return 'Ngày $day';
  }

  @override
  String quiet_transformer_streakLabel(int streak) {
    return 'Chuỗi $streak ngày';
  }

  @override
  String quiet_transformer_checkInsLabel(int count) {
    return '$count lần check-in';
  }

  @override
  String quiet_transformer_vaultPill(int day) {
    return 'Kho riêng tư · Ngày $day';
  }

  @override
  String get quiet_transformer_ghostOn => 'Bóng mờ căn dáng: BẬT (30%)';

  @override
  String get quiet_transformer_ghostOff => 'Bóng mờ căn dáng: TẮT';

  @override
  String quiet_transformer_metricSliderLabel(String name) {
    return '$name hôm nay';
  }

  @override
  String quiet_transformer_trendTitle(String name) {
    return 'Xu hướng $name';
  }

  @override
  String get quiet_transformer_trendEmpty =>
      'Ghi chỉ số khi check-in để vẽ đường biến đổi';

  @override
  String get quiet_transformer_trendSingle =>
      'Đã ghi mốc đầu tiên · Thêm ngày tiếp theo để nối đường cong';

  @override
  String get quiet_transformer_metricHiddenBadge => 'Đã ẩn số liệu riêng tư';

  @override
  String get quiet_transformer_milestoneStart => 'NGÀY 01 · KHỞI ĐẦU';

  @override
  String quiet_transformer_milestoneWeek(String day) {
    return 'NGÀY $day · CỘT MỐC';
  }

  @override
  String quiet_transformer_milestoneToday(String day) {
    return 'NGÀY $day · HÔM NAY';
  }

  @override
  String quiet_transformer_milestoneDay(String day) {
    return 'NGÀY $day';
  }

  @override
  String get quiet_transformer_compareDayStart => 'NGÀY 01';

  @override
  String quiet_transformer_compareDayNow(String day) {
    return 'NGÀY $day';
  }

  @override
  String get quiet_transformer_hideExactWeight => 'Ẩn số cân chính xác';

  @override
  String get quiet_transformer_hideExactWeightSub =>
      'Chỉ hiện độ chênh lệch hoặc chuỗi ngày khi chia sẻ';

  @override
  String quiet_transformer_transformationBadge(String delta) {
    return 'Chuyển đổi $delta';
  }

  @override
  String get quiet_transformer_exportCard => 'Xuất thiệp tiến độ';

  @override
  String get quiet_transformer_waitingPhoto => 'Chưa có ảnh';
}
