// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'couple_rituals_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CoupleRitualsL10nEn extends CoupleRitualsL10n {
  CoupleRitualsL10nEn([String locale = 'en']) : super(locale);

  @override
  String get couple_rituals_name => 'Couple Rituals';

  @override
  String couple_rituals_dayLabel(int day) {
    return 'Day $day';
  }

  @override
  String couple_rituals_streakLabel(int streak) {
    return '$streak-day streak';
  }

  @override
  String couple_rituals_checkInsLabel(int count) {
    return '$count check-ins';
  }

  @override
  String get couple_rituals_meDefault => 'You';

  @override
  String get couple_rituals_partnerDefault => 'Partner';

  @override
  String couple_rituals_waitingPartner(String name) {
    return 'Waiting for $name';
  }

  @override
  String get couple_rituals_completePairHint =>
      'Snap your half · Complete pair';

  @override
  String couple_rituals_partnerDoneBadge(String name) {
    return '$name · Snapped';
  }

  @override
  String couple_rituals_mosaicTitle(int days, int moments) {
    return '$days DAYS · $moments MOMENTS';
  }

  @override
  String get couple_rituals_shareStoryButton => 'Share Our Story';

  @override
  String couple_rituals_dayHeader(String day) {
    return 'DAY $day';
  }

  @override
  String couple_rituals_todayHeader(String day) {
    return 'DAY $day · TODAY';
  }
}
