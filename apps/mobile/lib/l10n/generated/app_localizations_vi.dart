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
  String get common_retry => 'Thử lại';

  @override
  String get common_cancel => 'Hủy';

  @override
  String get common_ok => 'OK';

  @override
  String get common_loading => 'Đang tải…';

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
  String get placeholder_comingSoon => 'Sắp ra mắt';
}
