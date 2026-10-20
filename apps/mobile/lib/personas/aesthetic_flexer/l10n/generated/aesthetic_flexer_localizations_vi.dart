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
}
