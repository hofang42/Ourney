// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'reminders_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class RemindersL10nEn extends RemindersL10n {
  RemindersL10nEn([String locale = 'en']) : super(locale);

  @override
  String get reminders_title => 'Reminders';

  @override
  String get reminders_intro =>
      'Pick a reminder time for each journey. Ourney only reminds you on days you haven\'t checked in yet.';

  @override
  String get reminders_journeysHeader => 'Journeys';

  @override
  String reminders_toggleLabel(String journey) {
    return 'Reminder for $journey';
  }

  @override
  String reminders_timeOn(String time) {
    return 'Every day at $time';
  }

  @override
  String get reminders_timeOff => 'Off';

  @override
  String reminders_changeTime(String time) {
    return 'Change reminder time ($time)';
  }

  @override
  String get reminders_pickTimeHelp => 'Check-in reminder time';

  @override
  String get reminders_streakAlertTitle => 'Streak alert at 21:00';

  @override
  String get reminders_streakAlertSubtitle =>
      'When it\'s 21:00, you have a streak going and haven\'t checked in yet.';

  @override
  String get reminders_emptyTitle => 'No journeys yet';

  @override
  String get reminders_emptyMessage =>
      'Create a journey, then come back here to set a reminder.';

  @override
  String get reminders_loadError =>
      'Couldn\'t load your journeys. Please try again later.';

  @override
  String get reminders_retry => 'Try again';

  @override
  String get reminders_deniedTitle => 'Notifications are off';

  @override
  String get reminders_deniedMessage =>
      'Your reminder times are saved, but notifications for Ourney need to be on in Settings for them to show up.';

  @override
  String get reminders_openSettings => 'Open Settings';

  @override
  String get reminders_permissionTitle => 'Turn on notifications?';

  @override
  String get reminders_permissionMessage =>
      'Ourney only sends the reminders you set, plus a heads-up at 21:00 when your streak is about to break. No ads.';

  @override
  String get reminders_permissionContinue => 'Continue';

  @override
  String get reminders_permissionNotNow => 'Not now';

  @override
  String get reminders_notifTitle => 'Time to check in';

  @override
  String reminders_notifBody(String journey) {
    return '$journey: snap today\'s photo.';
  }

  @override
  String get reminders_alertTitle => 'Your streak is about to break';

  @override
  String reminders_alertBody(String journey, int count) {
    return '$journey: your $count-day streak ends at midnight. One photo keeps it going.';
  }

  @override
  String get reminders_channelName => 'Check-in reminders';

  @override
  String get reminders_channelDescription =>
      'Daily check-in reminders and streak alerts.';
}
