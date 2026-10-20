// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'couple_rituals_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class CoupleRitualsL10nVi extends CoupleRitualsL10n {
  CoupleRitualsL10nVi([String locale = 'vi']) : super(locale);

  @override
  String get couple_rituals_name => 'Nghi thức đôi';

  @override
  String couple_rituals_dayLabel(int day) {
    return 'Ngày $day';
  }

  @override
  String couple_rituals_streakLabel(int streak) {
    return 'Chuỗi $streak ngày';
  }

  @override
  String couple_rituals_checkInsLabel(int count) {
    return '$count lần check-in';
  }
}
