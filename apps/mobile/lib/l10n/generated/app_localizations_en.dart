// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'Ourney';

  @override
  String get nav_journeys => 'Journeys';

  @override
  String get nav_capture => 'Capture';

  @override
  String get nav_groups => 'Groups';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_ok => 'OK';

  @override
  String get common_loading => 'Loading…';

  @override
  String get empty_default_title => 'Nothing here yet';

  @override
  String streak_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String streak_semantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return 'Streak of $_temp0';
  }

  @override
  String get streak_atRisk => 'Streak at risk';

  @override
  String get placeholder_comingSoon => 'Coming soon';
}
