// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'journeys_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class JourneysL10nEn extends JourneysL10n {
  JourneysL10nEn([String locale = 'en']) : super(locale);

  @override
  String get journeys_title => 'Journeys';

  @override
  String get journeys_activeSection => 'Active';

  @override
  String get journeys_finishedSection => 'Shelf';

  @override
  String get journeys_emptyTitle => 'No journeys yet';

  @override
  String get journeys_emptyMessage =>
      'Start your first journey: one photo a day.';

  @override
  String get journeys_newJourney => 'New journey';

  @override
  String get journeys_limitTitle => 'You have 3 journeys running';

  @override
  String get journeys_limitMessage =>
      'You can run up to 3 journeys at once so posting stays light. End one to start a new one.';

  @override
  String journeys_dayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String journeys_dayOpen(int day) {
    return 'Day $day';
  }

  @override
  String get journeys_checkedToday => 'Checked in today';

  @override
  String get journeys_notCheckedToday => 'Not checked in today';

  @override
  String get journeys_statusEnded => 'Ended';

  @override
  String get journeys_statusArchived => 'Archived';

  @override
  String get journeys_kindSolo => 'Solo';

  @override
  String get journeys_kindGroup => 'Group';

  @override
  String get journeys_loadError => 'Couldn\'t load journeys.';

  @override
  String get journeys_pickTemplateTitle => 'Pick a journey type';

  @override
  String journeys_templateDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get journeys_templateCustomHint => 'Set everything yourself';

  @override
  String get journeys_templateCoupleTitle => 'Couple ritual';

  @override
  String get journeys_templateCoupleHint =>
      'Two people sharing a daily moment together';

  @override
  String get journeys_personaPreviewLabel => 'Live UI preview';

  @override
  String get journeys_continueTemplateButton => 'Continue with this style';

  @override
  String get journeys_createTitle => 'Create journey';

  @override
  String get journeys_fieldTitle => 'Journey name';

  @override
  String get journeys_fieldEmoji => 'Icon';

  @override
  String journeys_emojiSemantics(String emoji) {
    return 'Icon $emoji';
  }

  @override
  String get journeys_fieldKind => 'Solo or with a group?';

  @override
  String get journeys_groupNeedsServer =>
      'Group journeys need a server. This build runs on this device only.';

  @override
  String get journeys_fieldDuration => 'Duration';

  @override
  String get journeys_durationCustom => 'Number of days';

  @override
  String get journeys_openEnded => 'No end date';

  @override
  String get journeys_fieldMetric => 'Track a number';

  @override
  String get journeys_fieldMetricHint =>
      'For example weight or minutes studied';

  @override
  String get journeys_metricName => 'Metric name';

  @override
  String get journeys_metricUnit => 'Unit';

  @override
  String get journeys_hideMetric => 'Hide the number from others';

  @override
  String get journeys_blurOnShare => 'Blur photos when sharing outside';

  @override
  String get journeys_fieldVisibility => 'Who can see it?';

  @override
  String get journeys_visibilityPrivate => 'Only me';

  @override
  String get journeys_visibilityLink => 'Anyone with the link';

  @override
  String get journeys_visibilityGroup => 'Group members';

  @override
  String get journeys_linkNeedsServer => 'Share links need a server.';

  @override
  String get journeys_fieldTimezone => 'Time zone';

  @override
  String get journeys_createButton => 'Start journey';

  @override
  String get journeys_errorTitleEmpty => 'Give your journey a name.';

  @override
  String journeys_errorTitleTooLong(int max) {
    return 'Names can be up to $max characters.';
  }

  @override
  String journeys_errorDuration(int min, int max) {
    return 'Duration must be $min to $max days.';
  }

  @override
  String get journeys_errorMetricName => 'Enter a metric name.';

  @override
  String get journeys_errorVisibility =>
      'This visibility isn\'t available for this journey.';

  @override
  String get journeys_errorNotAlone =>
      'Other members are still in the group, so it can\'t be deleted. You can end the journey instead.';

  @override
  String get journeys_errorForbidden => 'Only the journey owner can do this.';

  @override
  String get journeys_errorEnded => 'This journey has ended.';

  @override
  String get journeys_errorNotFound => 'Journey not found.';

  @override
  String get journeys_statCurrent => 'Current streak';

  @override
  String get journeys_statBest => 'Longest';

  @override
  String get journeys_statComplete => 'Complete';

  @override
  String get journeys_statDay => 'Progress';

  @override
  String journeys_percent(int value) {
    return '$value%';
  }

  @override
  String get journeys_checkInNow => 'Check in';

  @override
  String get journeys_share => 'Share';

  @override
  String get journeys_openGroup => 'Open group';

  @override
  String get journeys_endJourney => 'End journey';

  @override
  String get journeys_endConfirmTitle => 'End this journey?';

  @override
  String get journeys_endConfirmMessage =>
      'Once ended, the journey is read-only and no more check-ins can be added.';

  @override
  String get journeys_archive => 'Archive';

  @override
  String get journeys_delete => 'Delete journey';

  @override
  String get journeys_deleteConfirmTitle => 'Delete this journey?';

  @override
  String get journeys_deleteConfirmMessage =>
      'All your photos in this journey will be deleted. This can\'t be undone.';

  @override
  String get journeys_readOnlyBanner => 'This journey has ended. Read-only.';

  @override
  String get journeys_moreActions => 'More actions';

  @override
  String get journeys_timelineTitle => 'Timeline';

  @override
  String get journeys_privacyTitle => 'Privacy';

  @override
  String journeys_cellChecked(int day, String date) {
    return 'Day $day, $date: checked in';
  }

  @override
  String journeys_cellMissed(int day, String date) {
    return 'Day $day, $date: missed';
  }

  @override
  String journeys_cellToday(int day, String date) {
    return 'Day $day, $date: today, not checked in yet';
  }

  @override
  String journeys_cellFuture(int day, String date) {
    return 'Day $day, $date: upcoming';
  }

  @override
  String journeys_cellNotCounted(int day, String date) {
    return 'Day $day, $date: before you joined';
  }

  @override
  String get journeys_today => 'Today';

  @override
  String get journeys_fromLibrary => 'From library';

  @override
  String get journeys_metricHidden => 'Hidden';

  @override
  String get journeys_showMetric => 'Show number';

  @override
  String get journeys_photoUnavailable => 'Photo not available yet';

  @override
  String get journeys_noCheckIn => 'No photo for this day';

  @override
  String get journeys_greetingMorning => 'Good morning';

  @override
  String get journeys_greetingAfternoon => 'Good afternoon';

  @override
  String get journeys_greetingEvening => 'Good evening';

  @override
  String journeys_greetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String journeys_remainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count journeys still need today\'s photo.',
      one: '1 journey still needs today\'s photo.',
    );
    return '$_temp0';
  }

  @override
  String get journeys_allDonePrompt =>
      'Nothing left for today. See you tomorrow.';

  @override
  String get journeys_allDoneTitle => 'All done for today';

  @override
  String get journeys_todayLabel => 'Today';

  @override
  String journeys_dayShort(int day, int total) {
    return 'Day $day/$total';
  }

  @override
  String get journeys_streakWord => 'streak';

  @override
  String journeys_endsInHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Ends in ${hours}h',
      one: 'Ends in 1h',
    );
    return '$_temp0';
  }

  @override
  String get journeys_endsSoon => 'Ends in under an hour';

  @override
  String get journeys_startsToday => 'Starts today';

  @override
  String get journeys_lastSevenDays => 'Last seven days';

  @override
  String get journeys_snapToday => 'Snap today';

  @override
  String get journeys_yourJourneys => 'Your journeys';

  @override
  String get journeys_rowDone => 'Done';

  @override
  String get journeys_rowNotYet => 'Not yet';

  @override
  String get journeys_privacyPrivate => 'Private';

  @override
  String get journeys_privacyLink => 'Link on';

  @override
  String get journeys_privacyGroup => 'Squad';

  @override
  String get journeys_addJourney => 'Add journey';

  @override
  String get journeys_shelfEmpty =>
      'Finished journeys rest here, ready to look back on.';

  @override
  String get journeys_activeEmpty => 'Nothing running right now.';

  @override
  String get journeys_tagWeightLoss => 'See small changes add up.';

  @override
  String get journeys_tagEnglish => 'Keep the group moving.';

  @override
  String get journeys_tagTravel => 'Save each day away.';

  @override
  String get journeys_tagCouple => 'A shared table, remembered.';

  @override
  String get journeys_tagWorkout => 'Show up, one run at a time.';

  @override
  String get journeys_tagCustom => 'Build it your way.';

  @override
  String get journeys_modeSoloOnly => 'Solo only';

  @override
  String get journeys_modeSoloGroup => 'Solo · Group';

  @override
  String get journeys_modeCoupleOnly => 'Couple only';

  @override
  String get journeys_styleLocked => 'Style can\'t be changed later';

  @override
  String get journeys_moreOptions => 'More options';

  @override
  String get journeys_statMoments => 'Moments';

  @override
  String get journeys_daysUnit => 'days';

  @override
  String journeys_dateRange(String start, String end) {
    return '$start — $end';
  }

  @override
  String journeys_sinceDate(String start) {
    return 'Since $start';
  }

  @override
  String get journeys_addMore => 'Add more';

  @override
  String get journeys_statCurrentShort => 'Current';

  @override
  String get journeys_sharedSection => 'Shared with me';

  @override
  String get journeys_retell => 'Retell a past journey';

  @override
  String get journeys_imported => 'Imported';

  @override
  String get journeys_shareCard => 'Share card';
}
