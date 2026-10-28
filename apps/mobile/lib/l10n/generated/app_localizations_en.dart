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
  String get nav_groups => 'Squad';

  @override
  String get nav_profile => 'Profile and settings';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_ok => 'OK';

  @override
  String get common_close => 'Close';

  @override
  String get common_save => 'Save';

  @override
  String get common_loading => 'Loading…';

  @override
  String get common_errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get common_offline =>
      'You\'re offline. Ourney will sync when you\'re back online.';

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
  String get needsServer_title => 'Server needed';

  @override
  String get needsServer_message =>
      'This build runs in on-device mode. Solo journeys work as usual; groups need a server.';

  @override
  String get placeholder_comingSoon => 'Coming soon';
}
