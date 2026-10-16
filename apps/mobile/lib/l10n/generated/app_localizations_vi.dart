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
  String get nav_journeys => 'Journeys';

  @override
  String get nav_capture => 'Chụp';

  @override
  String get nav_groups => 'Nhóm';

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
}
