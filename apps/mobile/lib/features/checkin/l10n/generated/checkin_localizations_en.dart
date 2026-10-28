// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'checkin_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CheckinL10nEn extends CheckinL10n {
  CheckinL10nEn([String locale = 'en']) : super(locale);

  @override
  String get checkin_title => 'Check-in';

  @override
  String get checkin_photoSemantics => 'Check-in photo you just took';

  @override
  String get checkin_fromLibrary => 'From library';

  @override
  String get checkin_captionLabel => 'Caption';

  @override
  String get checkin_captionHint => 'Write a few words (optional)';

  @override
  String checkin_captionCounter(int count, int max) {
    return '$count/$max';
  }

  @override
  String checkin_captionCounterSemantics(int count, int max) {
    return '$count of $max characters used';
  }

  @override
  String get checkin_metricInvalid => 'Enter a valid number';

  @override
  String get checkin_metricPrivate => 'Only you can see this number';

  @override
  String get checkin_post => 'Post';

  @override
  String get checkin_posting => 'Posting…';

  @override
  String get checkin_replaceTitle => 'Replace today\'s photo?';

  @override
  String get checkin_replaceMessage =>
      'You already checked in to this journey today. The new photo will replace the old one.';

  @override
  String get checkin_replaceConfirm => 'Replace';

  @override
  String get checkin_errorPhoto =>
      'Couldn\'t process this photo. Try another one.';

  @override
  String get checkin_errorEnded =>
      'This journey has ended, so no more check-ins.';

  @override
  String get checkin_missingPhoto =>
      'Photo not found. Go back and take it again.';

  @override
  String get checkin_missingJourney => 'This journey wasn\'t found.';

  @override
  String get checkin_stamp => 'Checked in!';

  @override
  String get checkin_streakPlusOne => '+1 day';

  @override
  String get checkin_replaced => 'Today\'s photo replaced';

  @override
  String get checkin_milestone7 => '7 days in a row!';

  @override
  String get checkin_milestone30 => '30 days in a row!';

  @override
  String get checkin_milestoneFinish => 'You made it!';

  @override
  String get checkin_milestoneMessage => 'Show your friends what you did.';

  @override
  String get checkin_share => 'Share';

  @override
  String get checkin_done => 'Done';

  @override
  String get checkin_posted => 'Moment posted';

  @override
  String get checkin_chainKept => 'Chain kept.';

  @override
  String checkin_daysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }
}
