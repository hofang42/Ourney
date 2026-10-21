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

  @override
  String get couple_rituals_meDefault => 'Bạn';

  @override
  String get couple_rituals_partnerDefault => 'Người đồng hành';

  @override
  String couple_rituals_waitingPartner(String name) {
    return 'Đang chờ $name';
  }

  @override
  String get couple_rituals_completePairHint =>
      'Chụp nửa của bạn · Ghép trọn đôi';

  @override
  String couple_rituals_partnerDoneBadge(String name) {
    return '$name · Đã chụp';
  }

  @override
  String couple_rituals_mosaicTitle(int days, int moments) {
    return '$days NGÀY · $moments KHOẢNH KHẮC';
  }

  @override
  String get couple_rituals_shareStoryButton =>
      'Chia sẻ câu chuyện của hai đứa';

  @override
  String couple_rituals_dayHeader(String day) {
    return 'NGÀY $day';
  }

  @override
  String couple_rituals_todayHeader(String day) {
    return 'NGÀY $day · HÔM NAY';
  }
}
