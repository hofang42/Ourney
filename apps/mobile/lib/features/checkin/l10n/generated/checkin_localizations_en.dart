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
  String get checkin_postMemory => 'Stick in the book';

  @override
  String get checkin_postMinimal => 'Post now';

  @override
  String get checkin_captionLabelMemory => 'Write one line';

  @override
  String get checkin_captionLabelFlexer => 'How was today\'s run?';

  @override
  String get checkin_posting => 'Posting…';

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
  String checkin_photoAdded(int n) {
    return 'Photo $n added';
  }

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
  String get checkin_shareSkinMemory => 'Share trip poster';

  @override
  String get checkin_shareSkinCouple => 'Share your story';

  @override
  String get checkin_shareSkinFlexer => 'Share to Story';

  @override
  String get checkin_shareSkinMinimal => 'Export card';

  @override
  String get checkin_shareSkinQuiet => 'Make a card';

  @override
  String get checkin_done_saved => 'Saved to your journey.';

  @override
  String get checkin_done_savedPrivate => 'Saved. Only you can see it.';

  @override
  String get checkin_done_futureMembers =>
      'Saved. People who join can see this photo.';

  @override
  String get checkin_done_sharedSquad => 'Shared with your squad.';

  @override
  String get checkin_done_sharedLink => 'Visible on your shared journey.';

  @override
  String get checkin_chooseAnother => 'Choose another';

  @override
  String get checkin_done_stampChecked => 'CHECKED IN';

  @override
  String get checkin_done_stampWeek1 => 'WEEK 1 DONE';

  @override
  String get checkin_done_stampCup => 'CUP WON';

  @override
  String checkin_done_memoryStamp(int day) {
    return 'PASTED · JOURNEY DAY $day';
  }

  @override
  String checkin_done_coupleDay(int day) {
    return 'Day $day';
  }

  @override
  String get checkin_done_coupleSent => 'Your half is sent.';

  @override
  String get checkin_done_coupleWeek => 'First week together';

  @override
  String get checkin_done_coupleFull30 => 'A full 30 days';

  @override
  String checkin_done_flexerDay(int day, int streak) {
    String _temp0 = intl.Intl.pluralLogic(
      streak,
      locale: localeName,
      other: 'DAY $day. $streak DAYS STRAIGHT.',
      one: 'DAY $day. 1 DAY STRAIGHT.',
    );
    return '$_temp0';
  }

  @override
  String get checkin_done_flexerWeek => 'WEEK ONE DONE';

  @override
  String get checkin_done_flexerFinish => 'FINISHED';

  @override
  String get checkin_done_minimalDone => 'DONE.';

  @override
  String get checkin_done_minimalWeek => '7 DAYS STRAIGHT';

  @override
  String get checkin_done_minimalFull => 'ALL 30 DAYS';

  @override
  String get checkin_done => 'Done';

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

  @override
  String get checkin_retake => 'Retake';

  @override
  String get checkin_privacyPrivate => 'Only you';

  @override
  String get checkin_privacyPending => 'For this journey';

  @override
  String get checkin_privacyFutureMembers => 'Visible to people who join';

  @override
  String get checkin_privacyShared => 'Shared';

  @override
  String get checkin_privacyCouple => 'Couple';

  @override
  String get checkin_privacySquad => 'Squad';

  @override
  String checkin_dayStamp(int day) {
    return 'DAY $day';
  }

  @override
  String checkin_calendarSemantics(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Calendar of the last $days days, today has a photo',
      one: 'Calendar of the last 1 day, today has a photo',
    );
    return '$_temp0';
  }

  @override
  String get checkin_extraMoodLabel => 'How are you feeling today?';

  @override
  String get checkin_extraMoodLight => 'Light';

  @override
  String get checkin_extraMoodNormal => 'Okay';

  @override
  String get checkin_extraMoodTired => 'A bit tired';

  @override
  String get checkin_extraMinutesLabel => 'How long did you study today?';

  @override
  String checkin_extraMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get checkin_extraMinutesOther => 'Other';

  @override
  String get checkin_extraMinutesLess => 'Five minutes less';

  @override
  String get checkin_extraMinutesMore => 'Five minutes more';

  @override
  String get checkin_extraPlaceLabel => 'Where are you?';

  @override
  String get checkin_extraPlaceHint => 'Search for a place...';

  @override
  String get checkin_extraDishLabel => 'Today\'s dish';

  @override
  String get checkin_extraDishHint => 'Leave empty if you like';

  @override
  String get checkin_extraMomentLabel => 'Today\'s moment';

  @override
  String get checkin_extraMomentHint => 'Leave empty if you like';

  @override
  String get checkin_extraCookLabel => 'Who cooked?';

  @override
  String get checkin_extraYou => 'You';

  @override
  String get checkin_extraPartner => 'Partner';

  @override
  String get checkin_extraHeartsLabel => 'How many hearts for this meal?';

  @override
  String get checkin_extraHeartsMomentLabel => 'How many hearts for today?';

  @override
  String checkin_extraHeartsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hearts',
      one: '1 heart',
    );
    return '$_temp0';
  }

  @override
  String get checkin_coupleInvite => 'Invite your partner to join';

  @override
  String get checkin_coupleWaiting => 'Waiting for your partner’s photo';

  @override
  String get checkin_extraPaceLabel => 'Pace (min/km)';

  @override
  String get checkin_extraPaceInvalid =>
      'Invalid pace, seconds must be under 60';

  @override
  String get checkin_extraKmLabel => 'Distance (km)';

  @override
  String get checkin_extraKmHint => 'e.g. 5.3';

  @override
  String get checkin_extraKmInvalid =>
      'Distance must be 0.1 to 500 km, one decimal';

  @override
  String get checkin_extraBackspace => 'Delete one digit';

  @override
  String checkin_extraCountdown(int seconds) {
    return 'Posting in $seconds s';
  }

  @override
  String get checkin_extraCountdownStop => 'Tap anywhere to stop';

  @override
  String get checkin_details => 'Details';

  @override
  String checkin_captionLimitReached(int max) {
    return 'Limit reached: $max characters';
  }

  @override
  String checkin_metricLast(String value) {
    return 'Last time: $value';
  }
}
