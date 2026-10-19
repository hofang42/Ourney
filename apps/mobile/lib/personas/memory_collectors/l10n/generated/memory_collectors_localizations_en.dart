// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'memory_collectors_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class MemoryCollectorsL10nEn extends MemoryCollectorsL10n {
  MemoryCollectorsL10nEn([String locale = 'en']) : super(locale);

  @override
  String memory_collectors_daysHeader(String title, int days) {
    return '$title · $days DAYS';
  }

  @override
  String memory_collectors_openHeader(String title) {
    return '$title · TRIP JOURNAL';
  }

  @override
  String memory_collectors_dayCaption(String day, String caption) {
    return 'DAY $day · $caption';
  }

  @override
  String memory_collectors_dayToday(String day) {
    return 'DAY $day · TODAY';
  }

  @override
  String memory_collectors_dayNumber(String day) {
    return 'DAY $day';
  }

  @override
  String memory_collectors_filmRollBounded(int used, int total) {
    return 'FILM ROLL $used/$total';
  }

  @override
  String memory_collectors_filmRollOpen(int used) {
    return 'FILM ROLL #$used';
  }

  @override
  String memory_collectors_contactSheetSubtitle(int count) {
    return '$count MOMENTS · 35MM FILM';
  }

  @override
  String get memory_collectors_sharePosterCta => 'Share Trip Poster';

  @override
  String get memory_collectors_emptyFilmStrip =>
      'No frames captured on this film roll yet.';
}
