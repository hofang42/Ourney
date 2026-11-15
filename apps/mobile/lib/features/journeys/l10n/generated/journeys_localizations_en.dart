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
  String get journeys_todayAtRisk => 'At risk';

  @override
  String get journeys_todayRest => 'Everything else';

  @override
  String get journeys_openJourneys => 'Open my journeys';

  @override
  String journeys_doneOf(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get journeys_shareMakeCard => 'Make a card or video';

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
    return '$count moments';
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
  String get journeys_ticketTagFlexer => 'Get out of bed. Keep running.';

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
  String get journeys_partnerPhotoSemantics => 'Your partner\'s photo';

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
    return 'FILM ROLL · $count FRAMES';
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
      'This private photo becomes your alignment frame on the following days.';

  @override
  String get journeys_dna_ghost_now => 'Take it now';

  @override
  String get journeys_dna_ghost_later => 'Maybe later.';

  @override
  String get journeys_dna_trophy_label => 'Trophy name';

  @override
  String get journeys_dna_trophy_hint => 'Trophy 7.5';

  @override
  String get journeys_dna_place_search => 'Search for a place...';

  @override
  String get journeys_dna_place_country => 'Vietnam';

  @override
  String get journeys_dna_place_dalat => 'Da Lat';

  @override
  String get journeys_dna_place_hoian => 'Hoi An';

  @override
  String get journeys_dna_place_phuquoc => 'Phu Quoc';

  @override
  String get journeys_dna_place_pine => 'Pine forest and mist';

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
  String get journeys_dna_forge_title => 'forging your DNA…';

  @override
  String get journeys_dna_forge_a11y => 'Creating your journey';

  @override
  String get journeys_dna_import_link => 'Import a past journey';

  @override
  String get journeys_home_introQuiet => 'Look back, a little at a time.';

  @override
  String get journeys_home_introSquad => 'how long did you study today.';

  @override
  String get journeys_home_introMemory => 'Where did the crew get lost today?';

  @override
  String get journeys_home_introCouple => 'What are you two cooking today?';

  @override
  String get journeys_home_offlineQuiet =>
      'Saved on this phone · will sync later';

  @override
  String get journeys_home_offlineSquad =>
      'WAITING TO SYNC · SAVED ON THIS PHONE';

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
}
