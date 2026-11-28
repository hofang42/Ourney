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
  String get journeys_kindGroup => 'Squad';

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
  String get journeys_fieldKind => 'Solo or with a squad?';

  @override
  String get journeys_groupNeedsServer =>
      'Squad journeys need a server. This build runs on this device only.';

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
  String get journeys_hideExtras =>
      'Hide my mood, minutes and details from others';

  @override
  String get journeys_pin => 'Pin to top';

  @override
  String get journeys_unpin => 'Unpin';

  @override
  String get journeys_blurOnShare => 'Blur photos when sharing outside';

  @override
  String get journeys_fieldVisibility => 'Who can see it?';

  @override
  String get journeys_visibilityPrivate => 'Only me';

  @override
  String get journeys_visibilityLink => 'Anyone with the link';

  @override
  String get journeys_visibilityGroup => 'Squad members';

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
  String get journeys_errorInvalid =>
      'Some of this data isn\'t valid. Check it and try again.';

  @override
  String get journeys_errorLimit =>
      'You have too many running journeys. End one and try again.';

  @override
  String get journeys_errorNotAlone =>
      'Other members are still in the squad, so it can\'t be deleted. You can end the journey instead.';

  @override
  String get journeys_errorForbidden => 'Only the journey owner can do this.';

  @override
  String get journeys_errorEnded => 'This journey has ended.';

  @override
  String get journeys_errorSyncPending =>
      'Photos are still uploading. Try again in a moment.';

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
  String get journeys_openGroup => 'Open squad';

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
  String get journeys_archiveConfirmTitle => 'Archive this journey?';

  @override
  String get journeys_archiveConfirmMessage =>
      'The journey is hidden from your list. You can undo right after archiving.';

  @override
  String get journeys_archived => 'Journey archived';

  @override
  String get journeys_archiveUndo => 'Undo';

  @override
  String get journeys_archivedSection => 'Archived';

  @override
  String get journeys_unarchive => 'Unarchive';

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
    return 'Day $day, $date: no photo';
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
  String journeys_dayPhotoCount(int index, int count) {
    return '$index/$count';
  }

  @override
  String journeys_dayPhotoCountSemantics(int index, int count) {
    return 'Photo $index of $count for this day. Swipe to see the others.';
  }

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
  String get journeys_openToday => 'Open today';

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
  String get journeys_tagEnglish => 'Keep the squad moving.';

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
  String get journeys_modeSoloGroup => 'Solo · Squad';

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
  String get journeys_addMore => 'Take another photo today';

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

  @override
  String get journeys_back => 'Back';

  @override
  String get journeys_shelfIntro => 'Completed journeys, kept like albums.';

  @override
  String get journeys_dayZeroBody =>
      'One photo a day keeps your journey. Start with something you care about.';

  @override
  String get journeys_dayZeroStart => 'Start your first journey';

  @override
  String journeys_greetingHi(String name) {
    return 'Hi, $name';
  }

  @override
  String journeys_todayLeft(int count) {
    return '$count left';
  }

  @override
  String get journeys_todayAtRisk => 'Active streaks';

  @override
  String get journeys_todayRest => 'Everything else';

  @override
  String get journeys_openJourneys => 'Open my journeys';

  @override
  String journeys_doneOf(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get journeys_shareMakeCard => 'Create a share card';

  @override
  String get journeys_shareMakeCardHint => 'Share a moment from this journey';

  @override
  String get journeys_shareJourney => 'Share this journey';

  @override
  String get journeys_shareJourneyHint => 'Choose friends who can follow along';

  @override
  String journeys_albumDays(int done, int total) {
    return '$done/$total days';
  }

  @override
  String journeys_albumMoments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moments',
      one: '1 moment',
    );
    return '$_temp0';
  }

  @override
  String get journeys_streakDaysLabel => 'streak';

  @override
  String get journeys_ticketPrivate => 'PRIVATE PROFILE';

  @override
  String get journeys_ticketMemory => 'MEMORY TICKET';

  @override
  String get journeys_ticketChangeColor => 'Change color';

  @override
  String get journeys_ticketYou => 'You';

  @override
  String get journeys_ticketPartner => 'Partner';

  @override
  String get journeys_ticketOpenEnded => 'no return date';

  @override
  String journeys_ticketMilestone(String day) {
    return 'Day $day';
  }

  @override
  String journeys_ticketDates(String start, String end) {
    return '$start – $end';
  }

  @override
  String journeys_ticketDatesOpen(String start) {
    return 'From $start';
  }

  @override
  String get journeys_ticketTagQuiet => 'Only you see it. A little at a time.';

  @override
  String get journeys_ticketTagSquad =>
      'Check in every day, the whole crew levels up!';

  @override
  String get journeys_ticketTagMemory => 'Bring home plenty of frames.';

  @override
  String get journeys_ticketTagCouple => 'One half each day, together a whole.';

  @override
  String get journeys_ticketTagFlexer => 'Every run counts. Keep moving.';

  @override
  String get journeys_ticketTagFlexerTrain =>
      'Every session counts. Keep moving.';

  @override
  String get journeys_ticketPreview => 'Departure ticket preview';

  @override
  String get journeys_coupleYou => 'You';

  @override
  String get journeys_coupleWaiting => 'Waiting for your partner';

  @override
  String journeys_createStepOf(int step, int total) {
    return 'Step $step/$total';
  }

  @override
  String get journeys_createNext => 'Continue';

  @override
  String get journeys_createExit => 'Leave journey setup';

  @override
  String get journeys_createPickSubtitle => 'Tap a type to begin.';

  @override
  String get journeys_createChosen => 'Selected';

  @override
  String get journeys_createDetailTitle => 'Name it and set the goal.';

  @override
  String get journeys_createWhoTitle => 'Who is coming along?';

  @override
  String get journeys_kindCouple => 'Just the two of us';

  @override
  String get journeys_kindSoloBody => 'Just you and the camera.';

  @override
  String get journeys_kindGroupBody => 'Up to 10 people, invite by code.';

  @override
  String get journeys_kindCoupleBody => 'One pair, one rhythm.';

  @override
  String get journeys_coupleNameYou => 'Your name';

  @override
  String get journeys_coupleNameOther => 'Their name';

  @override
  String get journeys_errorCoupleNames => 'Enter both names.';

  @override
  String get journeys_createRhythmTitle => 'Set the rhythm.';

  @override
  String get journeys_fieldStartDate => 'Start date';

  @override
  String get journeys_calendarPrev => 'Previous month';

  @override
  String get journeys_calendarNext => 'Next month';

  @override
  String journeys_calendarRange(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String get journeys_createReviewTitle => 'Your departure ticket.';

  @override
  String get journeys_createReviewEdit => 'Edit';

  @override
  String journeys_extraMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String journeys_extraHearts(int count) {
    return '$count/5 hearts';
  }

  @override
  String journeys_extraKm(String km) {
    return '$km km';
  }

  @override
  String journeys_extraPace(String pace) {
    return '$pace /km';
  }

  @override
  String journeys_extraCook(String name) {
    return '$name cooked';
  }

  @override
  String get journeys_extraMoodLight => 'Light';

  @override
  String get journeys_extraMoodNormal => 'Okay';

  @override
  String get journeys_extraMoodTired => 'A bit tired';

  @override
  String get journeys_uploaderAttachment =>
      'Photo you attached to this check-in';

  @override
  String get journeys_coupleNoPhoto => 'No photo for this day';

  @override
  String get journeys_inviteAction => 'Invite';

  @override
  String get journeys_renameCouple => 'Edit names';

  @override
  String get journeys_renameCoupleTitle => 'Edit couple names';

  @override
  String get journeys_quietHold => 'Hold to view';

  @override
  String get journeys_quietHolding => 'Viewing';

  @override
  String get journeys_quietHoldHint => 'Press and hold to reveal your numbers';

  @override
  String get journeys_quietHidden => 'Hidden';

  @override
  String journeys_quietAxis(String value) {
    return '$value kg';
  }

  @override
  String journeys_quietDayTag(int day) {
    return 'DAY $day';
  }

  @override
  String get journeys_quietToday => 'TODAY';

  @override
  String get journeys_quietWeek => 'FIRST WEEK';

  @override
  String get journeys_quietHalf => 'HALFWAY';

  @override
  String get journeys_quietFinish => 'FINISH';

  @override
  String get journeys_quietMissed => 'A rest day doesn\'t erase the journey.';

  @override
  String get journeys_quietMilestones => 'Milestones';

  @override
  String get journeys_memoryToday => 'TODAY · tap to snap';

  @override
  String get journeys_memoryEmpty => 'EMPTY FRAME';

  @override
  String journeys_memoryFilmRoll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'FILM ROLL · $count FRAMES',
      one: 'FILM ROLL · 1 FRAME',
    );
    return '$_temp0';
  }

  @override
  String get journeys_memoryOffline => 'OFFLINE · waiting to sync';

  @override
  String get journeys_dna_goal_title_weight => 'your goal.';

  @override
  String get journeys_dna_weight_title => 'current weight.';

  @override
  String get journeys_dna_ghost_title =>
      'take a day-1 photo as your alignment frame.';

  @override
  String get journeys_dna_goal_title_english => 'goal.';

  @override
  String get journeys_dna_minutes_title => 'minutes per day.';

  @override
  String get journeys_dna_trophy_title => 'name the trophy at the finish.';

  @override
  String get journeys_dna_sport_title => 'which sport.';

  @override
  String get journeys_dna_measure_title => 'measured in.';

  @override
  String get journeys_dna_hud_title => 'HUD style.';

  @override
  String get journeys_dna_place_title => 'where to.';

  @override
  String get journeys_dna_dates_title => 'depart – return.';

  @override
  String get journeys_dna_film_title => 'how many frames on the roll.';

  @override
  String get journeys_dna_ritual_title => 'your ritual together.';

  @override
  String get journeys_dna_names_title => 'your two names.';

  @override
  String get journeys_dna_side_title => 'who shoots which half.';

  @override
  String get journeys_dna_habit_title => 'your habit.';

  @override
  String get journeys_dna_c_goal_weight_lose => 'Lose weight';

  @override
  String get journeys_dna_c_goal_weight_lose_hint =>
      'lighter and healthier every day';

  @override
  String get journeys_dna_c_goal_weight_keep => 'Stay in shape';

  @override
  String get journeys_dna_c_goal_weight_keep_hint => 'keep your current rhythm';

  @override
  String get journeys_dna_c_goal_weight_shape => 'Reshape';

  @override
  String get journeys_dna_c_goal_weight_shape_hint =>
      'track a new version of you';

  @override
  String get journeys_dna_c_goal_english_ielts => 'IELTS';

  @override
  String get journeys_dna_c_goal_english_ielts_hint => 'reach your target band';

  @override
  String get journeys_dna_c_goal_english_talk => 'Conversation';

  @override
  String get journeys_dna_c_goal_english_talk_hint =>
      'speak more naturally every day';

  @override
  String get journeys_dna_c_goal_english_read => 'Reading';

  @override
  String get journeys_dna_c_goal_english_read_hint =>
      'finish your first whole book';

  @override
  String get journeys_dna_c_minutes_15 => '15';

  @override
  String get journeys_dna_c_minutes_15_hint => '15 minutes a day';

  @override
  String get journeys_dna_c_minutes_30 => '30';

  @override
  String get journeys_dna_c_minutes_30_hint => '30 minutes a day';

  @override
  String get journeys_dna_c_minutes_45 => '45';

  @override
  String get journeys_dna_c_minutes_45_hint => '45 minutes a day';

  @override
  String get journeys_dna_c_minutes_60 => '60';

  @override
  String get journeys_dna_c_minutes_60_hint => '60 minutes a day';

  @override
  String get journeys_dna_c_sport_run => 'Run';

  @override
  String get journeys_dna_c_sport_run_hint => '30 days of running';

  @override
  String get journeys_dna_c_sport_gym => 'Gym';

  @override
  String get journeys_dna_c_sport_gym_hint => '30 days of gym';

  @override
  String get journeys_dna_c_sport_pilates => 'Pilates';

  @override
  String get journeys_dna_c_sport_pilates_hint => '30 days of pilates';

  @override
  String get journeys_dna_c_sport_yoga => 'Yoga';

  @override
  String get journeys_dna_c_sport_yoga_hint => '30 days of yoga';

  @override
  String get journeys_dna_c_sport_other => 'Other';

  @override
  String get journeys_dna_c_sport_other_hint => '30 days of something else';

  @override
  String get journeys_dna_c_measure_km => 'km';

  @override
  String get journeys_dna_c_measure_km_hint => 'log it in km';

  @override
  String get journeys_dna_c_measure_min => 'minutes';

  @override
  String get journeys_dna_c_measure_min_hint => 'log it in minutes';

  @override
  String get journeys_dna_c_measure_session => 'sessions';

  @override
  String get journeys_dna_c_measure_session_hint => 'log it per session';

  @override
  String get journeys_dna_c_hud_bold => 'Bold HUD';

  @override
  String get journeys_dna_c_hud_bold_hint => 'big numbers, high contrast';

  @override
  String get journeys_dna_c_hud_stamp => 'Minimal stamp';

  @override
  String get journeys_dna_c_hud_stamp_hint => 'neat as a postage stamp';

  @override
  String get journeys_dna_c_hud_strip => 'Film strip';

  @override
  String get journeys_dna_c_hud_strip_hint => 'moments one after another';

  @override
  String get journeys_dna_c_film_24 => '24 frames';

  @override
  String get journeys_dna_c_film_24_hint => 'every frame is considered';

  @override
  String get journeys_dna_c_film_36 => '36 frames';

  @override
  String get journeys_dna_c_film_36_hint => 'room for surprises';

  @override
  String get journeys_dna_c_ritual_cook => 'Cooking';

  @override
  String get journeys_dna_c_ritual_cook_hint => 'cook together';

  @override
  String get journeys_dna_c_ritual_save => 'Saving';

  @override
  String get journeys_dna_c_ritual_save_hint => 'save together';

  @override
  String get journeys_dna_c_ritual_ldr => 'Long distance';

  @override
  String get journeys_dna_c_ritual_ldr_hint => 'do long distance together';

  @override
  String get journeys_dna_c_ritual_custom => 'Your own';

  @override
  String get journeys_dna_c_ritual_custom_hint => 'make your own ritual';

  @override
  String get journeys_dna_c_side_left => 'Me on the left';

  @override
  String get journeys_dna_c_side_right => 'Me on the right';

  @override
  String journeys_dna_step_of_q(int n, int total) {
    return 'Question $n/$total';
  }

  @override
  String get journeys_dna_weight_unit => 'kg';

  @override
  String get journeys_dna_weight_a11y => 'Current weight';

  @override
  String get journeys_dna_weight_private => 'Only you can see this';

  @override
  String get journeys_dna_weight_hide => 'Hide kg when sharing';

  @override
  String get journeys_dna_weight_skip => 'Skip';

  @override
  String get journeys_dna_ghost_body =>
      'Show a translucent silhouette guide in the camera so every photo lines up.';

  @override
  String get journeys_dna_ghost_now => 'Turn on ghost guide';

  @override
  String get journeys_dna_ghost_later => 'Keep it off for now.';

  @override
  String get journeys_dna_trophy_label => 'Trophy name';

  @override
  String get journeys_dna_trophy_hint => 'Trophy 7.5';

  @override
  String get journeys_dna_place_search => 'Search destinations';

  @override
  String journeys_dna_place_limit(int max) {
    return 'Use up to $max characters.';
  }

  @override
  String get journeys_dna_dates_open => 'return date not set';

  @override
  String get journeys_dna_dates_prompt => 'Pick your departure and return days';

  @override
  String journeys_dna_dates_open_summary(String start) {
    return '$start · return date not set';
  }

  @override
  String journeys_dna_dates_range_summary(String start, String end) {
    return '$start – $end';
  }

  @override
  String journeys_dna_dates_min_note(int days) {
    return 'A journey lasts at least $days days, so the return date moved.';
  }

  @override
  String journeys_dna_dates_max_note(int days) {
    return 'A journey lasts at most $days days, so the return date moved.';
  }

  @override
  String get journeys_dna_prev_month => 'Previous month';

  @override
  String get journeys_dna_next_month => 'Next month';

  @override
  String get journeys_dna_name_left => 'Your name';

  @override
  String get journeys_dna_name_right => 'Their name';

  @override
  String get journeys_dna_habit_label => 'Habit';

  @override
  String get journeys_dna_habit_hint => 'Read 10 pages';

  @override
  String get journeys_dna_reason_label => 'why.';

  @override
  String get journeys_dna_reason_hint => 'to sleep better';

  @override
  String get journeys_dna_forge_title => 'Creating your journey…';

  @override
  String get journeys_dna_forge_a11y => 'Creating your journey';

  @override
  String get journeys_dna_import_link => 'Retell a past journey';

  @override
  String get journeys_home_introQuiet => 'Look back, a little at a time.';

  @override
  String get journeys_home_introSquad => 'how long did you study today.';

  @override
  String get journeys_home_introMemory => 'Where did the crew get lost today?';

  @override
  String get journeys_home_introCouple => 'What are you two cooking today?';

  @override
  String get journeys_home_introCoupleSave =>
      'What are you two saving for today?';

  @override
  String get journeys_home_introCoupleLdr =>
      'How did you two bridge the distance today?';

  @override
  String get journeys_home_introCoupleCustom =>
      'What moment did you two share today?';

  @override
  String get journeys_home_offlineQuiet =>
      'Saved on this phone · will sync later';

  @override
  String get journeys_home_offlineSquad =>
      'Your photo is saved on this device. We’ll send it to your squad when you’re back online.';

  @override
  String get journeys_home_offlineCouple =>
      'Your half is saved on this device. We’ll send it to your partner when you’re back online.';

  @override
  String get journeys_home_offline => 'You’re offline';

  @override
  String get journeys_home_offlineMemory =>
      'Saved on this phone. It sends itself once you are online.';

  @override
  String get journeys_home_readOnlyQuiet => 'Journey ended · view only';

  @override
  String get journeys_home_readOnlyFlexer => 'FINISHED · READ ONLY';

  @override
  String get journeys_home_readOnlyMinimal => 'ENDED · READ ONLY';

  @override
  String journeys_home_dayStreak(int day, int total, int streak) {
    return 'Day $day/$total · streak $streak';
  }

  @override
  String journeys_home_dayStreakOpen(int day, int streak) {
    return 'Day $day · streak $streak';
  }

  @override
  String journeys_home_monthStreak(int streak, String month) {
    return '$month · $streak-DAY STREAK';
  }

  @override
  String get journeys_home_holdReveal => 'Hold to reveal';

  @override
  String get journeys_home_viewing => 'Viewing';

  @override
  String get journeys_home_chartA11y => 'Progress line';

  @override
  String get journeys_home_msWeek => 'First week';

  @override
  String get journeys_home_msHalf => 'Halfway';

  @override
  String get journeys_home_msFinish => 'Finish line';

  @override
  String journeys_home_msDay(int day) {
    return 'DAY $day';
  }

  @override
  String get journeys_home_actionSquad => 'Squad today';

  @override
  String get journeys_home_actionCard => 'Make a card';

  @override
  String journeys_home_attendance(int done, int total) {
    return '$done/$total DAYS SHOT';
  }

  @override
  String get journeys_home_retake => 'Take another photo today';

  @override
  String get journeys_home_timelineLabel => 'Timeline';

  @override
  String get journeys_edit_title => 'update journey.';

  @override
  String get journeys_edit_save => 'Save';

  @override
  String get journeys_edit_name => 'Name';

  @override
  String get journeys_edit_cover => 'Cover';

  @override
  String journeys_edit_coverOption(int n) {
    return 'Cover $n';
  }

  @override
  String get journeys_edit_layout => 'Layout';

  @override
  String get journeys_edit_layoutNote =>
      'Some layouts need more data, so they are hidden.';

  @override
  String get journeys_edit_layoutInUse => 'In use';

  @override
  String journeys_edit_layoutPreviewLabel(String name) {
    return 'Preview the $name layout';
  }

  @override
  String get journeys_edit_previewTag => 'PREVIEW';

  @override
  String get journeys_edit_hudPreview => 'Daily check-in';

  @override
  String journeys_edit_dayOf(int day, int total) {
    return 'DAY $day/$total';
  }

  @override
  String journeys_edit_dayOpen(int day) {
    return 'DAY $day';
  }

  @override
  String get journeys_edit_useLayout => 'Use this layout';

  @override
  String get journeys_edit_cancel => 'Not now';

  @override
  String get journeys_edit_discardTitle => 'Discard your changes?';

  @override
  String get journeys_edit_discardBody =>
      'You changed this journey but haven\'t saved. Leaving now drops those changes.';

  @override
  String get journeys_edit_discardConfirm => 'Discard changes';

  @override
  String get journeys_edit_discardKeep => 'Keep editing';

  @override
  String get journeys_edit_layoutApplied => 'Layout changed for this journey.';

  @override
  String get journeys_edit_layoutOwnerOnly =>
      'The squad owner picks the layout for everyone.';

  @override
  String get journeys_edit_color => 'Colour';

  @override
  String get journeys_edit_skinShort_quiet => 'Quiet';

  @override
  String get journeys_edit_skinColor_quiet_0 => 'Jade';

  @override
  String get journeys_edit_skinColor_quiet_1 => 'Sage green';

  @override
  String get journeys_edit_skinColor_quiet_2 => 'Mist';

  @override
  String get journeys_edit_skinShort_squad => 'Squad';

  @override
  String get journeys_edit_skinColor_squad_0 => 'Flame';

  @override
  String get journeys_edit_skinColor_squad_1 => 'Purple';

  @override
  String get journeys_edit_skinColor_squad_2 => 'Chalk';

  @override
  String get journeys_edit_skinShort_memory => 'Memory';

  @override
  String get journeys_edit_skinColor_memory_0 => 'Pine mist';

  @override
  String get journeys_edit_skinColor_memory_1 => 'Salt sea';

  @override
  String get journeys_edit_skinColor_memory_2 => 'Night city';

  @override
  String get journeys_edit_skinShort_couple => 'Couple';

  @override
  String get journeys_edit_skinColor_couple_0 => 'Pink';

  @override
  String get journeys_edit_skinColor_couple_1 => 'Raspberry';

  @override
  String get journeys_edit_skinColor_couple_2 => 'Peach';

  @override
  String get journeys_edit_skinShort_flexer => 'Flexer';

  @override
  String get journeys_edit_skinColor_flexer_0 => 'Neon lime';

  @override
  String get journeys_edit_skinColor_flexer_1 => 'Electric coral';

  @override
  String get journeys_edit_skinColor_flexer_2 => 'Ice';

  @override
  String get journeys_edit_skinShort_minimal => 'Minimalist';

  @override
  String get journeys_edit_skinColor_minimal_0 => 'Orange';

  @override
  String get journeys_edit_skinColor_minimal_1 => 'Charcoal';

  @override
  String get journeys_edit_skinColor_minimal_2 => 'Sky';

  @override
  String get journeys_edit_trophy => 'Trophy name';

  @override
  String get journeys_edit_film => 'Film roll';

  @override
  String journeys_edit_filmReadonly(int n) {
    return '$n · view only';
  }

  @override
  String get journeys_edit_couple => 'The two of us';

  @override
  String get journeys_edit_hud => 'HUD style';

  @override
  String get journeys_edit_hudBold => 'Bold';

  @override
  String get journeys_edit_hudStamp => 'Minimal stamp';

  @override
  String get journeys_edit_hudStrip => 'Film strip';

  @override
  String get journeys_edit_reminder => 'Reminder time';

  @override
  String get journeys_edit_reminderHour => 'Hour';

  @override
  String get journeys_edit_reminderMinute => 'Minute';

  @override
  String get journeys_edit_visibility => 'Who can view';

  @override
  String get journeys_edit_visPrivate => 'Only me';

  @override
  String get journeys_edit_visLink => 'View link (revocable)';

  @override
  String get journeys_edit_visQuietNote =>
      'The view page always hides kg and blurs photos by default.';

  @override
  String get journeys_edit_membersOnly => 'Members only';

  @override
  String get journeys_edit_membersOnlyHint =>
      'a public link can be created with member consent once the journey ends';

  @override
  String get journeys_edit_quietLock => 'Private';

  @override
  String get journeys_edit_endTitle => 'End this journey?';

  @override
  String get journeys_edit_endBody =>
      'You can still look back, but not add photos.';

  @override
  String get journeys_edit_endConfirm => 'End';

  @override
  String get journeys_edit_saved => 'Saved.';

  @override
  String get journeys_edit_ownerOnly => 'Only the journey owner can edit.';

  @override
  String get journeys_edit_menu => 'Edit journey';

  @override
  String get journeys_wrapped_title => 'Journey complete';

  @override
  String get journeys_wrapped_close => 'Close';

  @override
  String journeys_wrapped_step(int n) {
    return 'Step $n';
  }

  @override
  String journeys_wrapped_moments(int moments, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      moments,
      locale: localeName,
      other: '$moments moments',
      one: '1 moment',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 over $_temp1';
  }

  @override
  String journeys_wrapped_streak(int n) {
    return '$n-day streak';
  }

  @override
  String get journeys_wrapped_quietEnd => 'You made it.';

  @override
  String journeys_wrapped_checkIns(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n check-ins',
      one: '1 check-in',
    );
    return '$_temp0';
  }

  @override
  String get journeys_wrapped_squadEnd => 'Finished, everyone!';

  @override
  String journeys_wrapped_frames(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n frames',
      one: '1 frame',
    );
    return '$_temp0';
  }

  @override
  String journeys_wrapped_daysTogether(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days together',
      one: '1 day together',
    );
    return '$_temp0';
  }

  @override
  String get journeys_wrapped_coupleFallback => 'The moment we will remember';

  @override
  String journeys_wrapped_km(String km) {
    return '$km KM';
  }

  @override
  String journeys_wrapped_pace(String pace) {
    return 'PACE $pace';
  }

  @override
  String journeys_wrapped_flexStreak(int n) {
    return 'STREAK $n.';
  }

  @override
  String journeys_wrapped_minimalLine(int done, int total, String name) {
    return '$done/$total DAYS · $name';
  }

  @override
  String get journeys_wrapped_memoryEnd =>
      'The roll is finished. Time to print it.';

  @override
  String journeys_wrapped_sumQuiet(int total) {
    return 'DAY 01 vs DAY $total';
  }

  @override
  String journeys_wrapped_sumSquad(int done, int total) {
    return '$done/$total FINISHED';
  }

  @override
  String journeys_wrapped_sumMemory(int total, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total DAYS · $name',
      one: '1 DAY · $name',
    );
    return '$_temp0';
  }

  @override
  String journeys_wrapped_sumCouple(int total, int moments) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total DAYS TOGETHER',
      one: '1 DAY TOGETHER',
    );
    String _temp1 = intl.Intl.pluralLogic(
      moments,
      locale: localeName,
      other: '$moments MOMENTS',
      one: '1 MOMENT',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String journeys_wrapped_sumFlexer(int total, String km) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total DAYS · $km KM',
      one: '1 DAY · $km KM',
    );
    return '$_temp0';
  }

  @override
  String journeys_wrapped_sumMinimal(int done, int total, int pct) {
    return '$done/$total DAYS · $pct% CONSISTENT';
  }

  @override
  String get journeys_wrapped_hideKg => 'Hide kg';

  @override
  String get journeys_wrapped_blur => 'Blur photos';

  @override
  String get journeys_wrapped_blurLocked => 'Always on for this card style';

  @override
  String get journeys_wrapped_on => 'On';

  @override
  String get journeys_wrapped_off => 'Off';

  @override
  String get journeys_wrapped_ctaPoster => 'Share the trip poster';

  @override
  String get journeys_wrapped_ctaStory => 'Share our story';

  @override
  String get journeys_wrapped_ctaFlexer => 'Share to Story';

  @override
  String get journeys_wrapped_ctaMinimal => 'Export card';

  @override
  String get journeys_wrapped_ctaCard => 'Make a card';

  @override
  String get journeys_wrapped_share => 'Share';

  @override
  String get journeys_wrapped_editCard => 'Edit card';

  @override
  String get journeys_wrapped_sheetTitle => 'share the card.';

  @override
  String get journeys_wrapped_hideBrand => 'Hide the ourney wordmark';

  @override
  String get journeys_wrapped_messages => 'Messages';

  @override
  String get journeys_wrapped_otherApps => 'Other apps';

  @override
  String get journeys_wrapped_saveCard => 'Save image';

  @override
  String get journeys_wrapped_cardSaved => 'Card saved.';

  @override
  String journeys_create_invitingFriend(String handle) {
    return 'Will invite @$handle';
  }

  @override
  String get journeys_wrapped_open => 'See the finished journey';

  @override
  String get journeys_wrapped_menu => 'Finish story';

  @override
  String journeys_home_squadChip(String title, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$title · $days DAYS',
      one: '$title · 1 DAY',
    );
    return '$_temp0';
  }

  @override
  String journeys_home_squadChipOpen(String title) {
    return '$title · OPEN-ENDED';
  }

  @override
  String journeys_home_squadToday(int done, int total) {
    return '$done/$total TODAY';
  }

  @override
  String get journeys_home_trophyDefault => 'TROPHY';

  @override
  String journeys_home_trophyDay(int day) {
    return 'DAY $day';
  }

  @override
  String get journeys_home_trophyOpen => 'OPEN-ENDED';

  @override
  String journeys_home_filmRoll(int frames, int total) {
    return 'FILM ROLL $frames/$total';
  }

  @override
  String journeys_home_rollNote(int total) {
    return 'Roll of $total used · open a new roll';
  }

  @override
  String journeys_home_coupleLine(int total, String ritual) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total DAYS $ritual',
      one: '1 DAY $ritual',
    );
    return '$_temp0';
  }

  @override
  String get journeys_home_ritualCook => 'COOKING FOR EACH OTHER';

  @override
  String get journeys_home_ritualSave => 'SAVING TOGETHER';

  @override
  String get journeys_home_ritualLdr => 'CLOSE FROM FAR';

  @override
  String get journeys_home_ritualOther => 'TOGETHER';

  @override
  String journeys_home_pairWaiting(String name) {
    return 'waiting for $name';
  }

  @override
  String get journeys_home_pairBoth => 'both shot today';

  @override
  String get journeys_home_pairNeither => 'nobody has shot today yet';

  @override
  String journeys_home_flexSummary(String km, String pace) {
    return '$km KM TOTAL · $pace /KM AVG PACE';
  }

  @override
  String journeys_home_flexKmOnly(String km) {
    return '$km KM TOTAL';
  }

  @override
  String journeys_home_flexRan(int done, int total) {
    return '$done/$total RAN';
  }

  @override
  String journeys_home_flexTrained(int done, int total) {
    return '$done/$total TRAINED';
  }

  @override
  String journeys_home_minimalMonth(String month, int streak) {
    String _temp0 = intl.Intl.pluralLogic(
      streak,
      locale: localeName,
      other: '$month · STREAK $streak DAYS',
      one: '$month · STREAK 1 DAY',
    );
    return '$_temp0';
  }

  @override
  String journeys_home_minimalDone(int done, int total) {
    return '$done/$total DONE';
  }

  @override
  String get journeys_home_viewWrapped => 'See the wrap-up';

  @override
  String get journeys_addMoreTag => 'Add more';

  @override
  String get journeys_hubTitle => 'Ourney';

  @override
  String journeys_hubGreeting(String name) {
    return 'hi $name.';
  }

  @override
  String get journeys_hubGreetingNoName => 'hi there.';

  @override
  String get journeys_hubOffline =>
      'saved on this phone, will send when you are online';

  @override
  String get journeys_hubResumeTitle => 'Continue creating a journey';

  @override
  String journeys_hubResumeStep(int n) {
    return 'step $n/5';
  }

  @override
  String get journeys_hubSection => 'your journeys.';

  @override
  String journeys_hubRunning(int n) {
    return '$n running';
  }

  @override
  String get journeys_hubNewTitle => 'new journey.';

  @override
  String get journeys_hubNewHint => 'pick a world to start';

  @override
  String get journeys_hubEmptyTitle => 'no journeys yet.';

  @override
  String get journeys_hubEmptyBody => 'one photo a day keeps the whole road.';

  @override
  String get journeys_hubErrorTitle => 'could not load. try again?';

  @override
  String get journeys_hubLoading => 'Loading';

  @override
  String journeys_createDeckCard(int n, int total, String name) {
    return 'Card $n of $total, $name';
  }

  @override
  String get journeys_createDeckChosen => 'Chosen';

  @override
  String get journeys_deckPrivate => 'Private';

  @override
  String get journeys_deckHudStudy => '45 MIN';

  @override
  String get journeys_deckHudFlexer => '5.2 KM · 5:48';

  @override
  String get journeys_deckHudMemory => 'FILM ROLL 12/24';

  @override
  String get journeys_deckHudCouple => 'two halves · one day';

  @override
  String get journeys_createDeckPrev => 'Previous card';

  @override
  String get journeys_createDeckNext => 'Next card';

  @override
  String journeys_createDeckCounter(int n, int total) {
    return '$n/$total';
  }

  @override
  String get journeys_createDeckChoose => 'Choose this type';

  @override
  String journeys_cardStreak(int days) {
    return '$days-day streak';
  }

  @override
  String journeys_heroSemantics(int streak, String title) {
    return '$title, $streak-day streak';
  }

  @override
  String journeys_hubDaysLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days logged',
      one: '1 day logged',
    );
    return '$_temp0';
  }

  @override
  String journeys_deadUploads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos couldn\'t be sent',
      one: '1 photo couldn\'t be sent',
    );
    return '$_temp0';
  }

  @override
  String get journeys_deadRetry => 'Retry';

  @override
  String get journeys_deadDiscard => 'Discard';

  @override
  String get journeys_createSettingsNotSaved =>
      'Some settings couldn\'t be saved';

  @override
  String get journeys_deadDiscardTitle => 'Discard unsent photos?';

  @override
  String journeys_deadDiscardBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count photos will be deleted from this phone and never uploaded. This can\'t be undone.',
      one: '1 photo will be deleted from this phone and never uploaded. This can\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String get journeys_timelineRecent => 'Recent';

  @override
  String get journeys_timelineByMonth => 'By month';

  @override
  String journeys_monthSummary(int checked, int days, int photos) {
    String _temp0 = intl.Intl.pluralLogic(
      photos,
      locale: localeName,
      other: '$photos photos',
      one: '1 photo',
    );
    return '$checked/$days days · $_temp0';
  }

  @override
  String journeys_monthA11y(String month, int checked, int days, int photos) {
    String _temp0 = intl.Intl.pluralLogic(
      photos,
      locale: localeName,
      other: '$photos photos',
      one: '1 photo',
    );
    return '$month, $checked of $days days checked in, $_temp0';
  }

  @override
  String get journeys_monthExpandHint => 'Expand';

  @override
  String get journeys_monthCollapseHint => 'Collapse';

  @override
  String journeys_jumpToMonth(String month) {
    return 'Go to $month';
  }

  @override
  String journeys_jumpToYear(int year) {
    return 'Show $year';
  }

  @override
  String journeys_jumpAnnounce(String month) {
    return 'Showing $month';
  }

  @override
  String journeys_earlierLink(int to, int checked) {
    return 'Earlier: days 1–$to, $checked checked in';
  }

  @override
  String get journeys_earlierView => 'View';

  @override
  String journeys_daysToGo(int days, int finish) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 to go · Finish on day $finish';
  }

  @override
  String get journeys_range30 => '30D';

  @override
  String get journeys_rangeAll => 'All';

  @override
  String journeys_clearYear(int year) {
    return 'Clear $year filter';
  }

  @override
  String get journeys_range30Pace => 'Few values in 30 days, showing check-ins';

  @override
  String journeys_startsIn(int days, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    String _temp1 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total days',
      one: '1 day',
    );
    return 'Starts in $_temp0 · $_temp1';
  }

  @override
  String get journeys_dayPrevious => 'Earlier';

  @override
  String get journeys_dayNext => 'Later';

  @override
  String journeys_dayPreviousSemantics(String date) {
    return 'Previous check-in, $date';
  }

  @override
  String journeys_dayNextSemantics(String date) {
    return 'Next check-in, $date';
  }

  @override
  String get journeys_dayViewFull => 'View full photo';

  @override
  String get journeys_dayOpenJourney => 'Open journey';

  @override
  String journeys_dayPartnerNoPhoto(String name) {
    return '$name has no photo for this day';
  }
}
