// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'memory_collectors_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class MemoryCollectorsL10nVi extends MemoryCollectorsL10n {
  MemoryCollectorsL10nVi([String locale = 'vi']) : super(locale);

  @override
  String memory_collectors_daysHeader(String title, int days) {
    return '$title · $days NGÀY';
  }

  @override
  String memory_collectors_openHeader(String title) {
    return '$title · NHẬT KÝ HÀNH TRÌNH';
  }

  @override
  String memory_collectors_dayCaption(String day, String caption) {
    return 'NGÀY $day · $caption';
  }

  @override
  String memory_collectors_dayToday(String day) {
    return 'NGÀY $day · HÔM NAY';
  }

  @override
  String memory_collectors_dayNumber(String day) {
    return 'NGÀY $day';
  }

  @override
  String memory_collectors_filmRollBounded(int used, int total) {
    return 'CUỘN PHIM $used/$total';
  }

  @override
  String memory_collectors_filmRollOpen(int used) {
    return 'CUỘN PHIM #$used';
  }

  @override
  String memory_collectors_contactSheetSubtitle(int count) {
    return '$count KHOẢNH KHẮC · PHIM 35MM';
  }

  @override
  String get memory_collectors_sharePosterCta => 'Chia sẻ áp phích chuyến đi';

  @override
  String get memory_collectors_emptyFilmStrip =>
      'Chưa có khung hình nào trong cuộn phim này.';
}
