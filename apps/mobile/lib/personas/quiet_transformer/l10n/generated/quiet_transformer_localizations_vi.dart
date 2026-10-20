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
}
