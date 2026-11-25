// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'widgets_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class WidgetsL10nEn extends WidgetsL10n {
  WidgetsL10nEn([String locale = 'en']) : super(locale);

  @override
  String get widgets_title => 'widgets.';

  @override
  String get widgets_back => 'Back';

  @override
  String get widgets_intro =>
      'Keep your streak, today\'s check-in, and your squad on your Home Screen or Lock Screen. Weight (kg) and private goals never appear on widgets.';

  @override
  String get widgets_appGroupUnavailable =>
      'This install can’t share data with widgets. Widgets will work with the TestFlight or App Store version, or when installed through AltStore or SideStore.';

  @override
  String get widgets_diagnosticsTitle => 'Widget diagnostics';

  @override
  String get widgets_diagnosticsEmpty => 'No widget events recorded yet.';

  @override
  String get widgets_diagnosticsCopy => 'Copy log';

  @override
  String get widgets_diagnosticsCopied => 'Widget log copied';

  @override
  String get widgets_secPreview => 'widget preview';

  @override
  String get widgets_tabToday => 'Today';

  @override
  String get widgets_tabStreak => 'Streak';

  @override
  String get widgets_tabSquad => 'Squad';

  @override
  String get widgets_previewSampleTitle => '30-Day IELTS Study';

  @override
  String get widgets_previewSampleBadge => 'Sample preview';

  @override
  String get widgets_previewYou => 'You';

  @override
  String widgets_previewDayOf(int day, int total) {
    return 'Day $day/$total';
  }

  @override
  String widgets_previewDayOpen(int day) {
    return 'Day $day';
  }

  @override
  String widgets_previewStreakDays(int count) {
    return '$count-day streak';
  }

  @override
  String get widgets_previewSnapCta => 'Snap now';

  @override
  String get widgets_previewDoneBadge => 'Checked in today';

  @override
  String get widgets_previewAtRiskBadge => 'Open for today · until midnight';

  @override
  String get widgets_previewPendingBadge => 'Not checked in yet';

  @override
  String widgets_previewSquadCount(int done, int total) {
    return '$done/$total checked in today';
  }

  @override
  String get widgets_previewPhotoHiddenNote => 'Photos hidden on widgets';

  @override
  String get widgets_previewPhotoBlurredNote => 'Photos blurred automatically';

  @override
  String get widgets_previewPhotoClearNote =>
      'Photos shown clear on Home Screen';

  @override
  String get widgets_secPrivacy => 'privacy & display';

  @override
  String get widgets_photoModeEyebrow => 'HOME-SCREEN WIDGET PHOTOS';

  @override
  String get widgets_photoModeSmart => 'Smart';

  @override
  String get widgets_photoModeBlurred => 'Blurred';

  @override
  String get widgets_photoModeOff => 'No photos';

  @override
  String get widgets_photoModeClear => 'Clear';

  @override
  String get widgets_photoModeSmartNote =>
      'Automatically blurs weight-loss photos and shows avatars only on squad widgets. Weight (kg) is never shown.';

  @override
  String get widgets_photoModeBlurredNote =>
      'Every check-in photo on Home Screen widgets is pre-blurred before saving. Weight (kg) is never shown.';

  @override
  String get widgets_photoModeOffNote =>
      'Never displays photos on widgets; shows vector stickers, streak counters, and initials only.';

  @override
  String get widgets_photoModeClearNote =>
      'Shows crisp check-in photos on your unlocked Home Screen. Your Lock Screen still never shows photos or weight (kg).';

  @override
  String get widgets_redactTitlesLabel => 'Hide journey titles on Lock Screen';

  @override
  String get widgets_redactTitlesSub =>
      'On the Lock Screen, widgets and Live Activities show \"Ourney\" instead of specific journey names.';

  @override
  String get widgets_redactTitlesSubAndroid =>
      'On the Lock Screen, live updates show \"Ourney\" instead of specific journey names.';

  @override
  String get widgets_secLiveActivity => 'evening check-in window';

  @override
  String get widgets_liveActivityLabel => 'Live Activity & check-in window';

  @override
  String get widgets_liveActivityLabelAndroid =>
      'Live Updates & status-bar check-in';

  @override
  String get widgets_liveActivitySub =>
      'Shows your check-in window on Dynamic Island / Lock Screen starting 30 minutes before your reminder (or 18:00 for active streaks) and clears right after you post.';

  @override
  String get widgets_liveActivitySubAndroid =>
      'Shows your check-in window on the status bar and Lock Screen starting 30 minutes before your reminder (or 18:00 for active streaks) and clears right after you post.';

  @override
  String get widgets_secDefaultJourney => 'featured widget journey';

  @override
  String get widgets_defaultJourneyAuto =>
      'Automatic (prioritize next unchecked)';

  @override
  String get widgets_defaultJourneyAutoSub =>
      'Used by widgets set to Automatic. Long-press any widget on your Home Screen to pin a specific journey.';

  @override
  String get widgets_secSetup => 'how to add to your home screen';

  @override
  String get widgets_setupStep1Title =>
      '1. Touch and hold your Home Screen or Lock Screen';

  @override
  String get widgets_setupStep1TitleAndroid =>
      '1. Touch and hold your Home Screen';

  @override
  String get widgets_setupStep1Body =>
      'Long-press an empty area until icons jiggle, then tap Edit or Widgets.';

  @override
  String get widgets_setupStep2Title =>
      '2. Search for Ourney in the widget gallery';

  @override
  String get widgets_setupStep2Body =>
      'Pick Today Check-In (2×2, 4×2, 4×4), Streak Sticker (2×2), or Squad Today (4×2, 4×4).';

  @override
  String get widgets_setupStep3Title =>
      '3. Tap \"Snap now\" to open the camera directly';

  @override
  String get widgets_setupStep3Body =>
      'Every widget opens the viewfinder for that exact journey in under a second.';
}
