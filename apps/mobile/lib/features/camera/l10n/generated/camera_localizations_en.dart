// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'camera_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CameraL10nEn extends CameraL10n {
  CameraL10nEn([String locale = 'en']) : super(locale);

  @override
  String get camera_title => 'Check-in camera';

  @override
  String get camera_shutter => 'Take check-in photo';

  @override
  String camera_shutterFor(String journey) {
    return 'Take check-in photo for $journey';
  }

  @override
  String get camera_flashOff => 'Flash: off';

  @override
  String get camera_flashAuto => 'Flash: auto';

  @override
  String get camera_flashOn => 'Flash: on';

  @override
  String get camera_flashUnavailable => 'This camera has no flash';

  @override
  String get camera_switchLens => 'Switch front/back camera';

  @override
  String get camera_gallery => 'Choose photo from library';

  @override
  String get camera_journeyPicker => 'Choose journey';

  @override
  String get camera_journeysError => 'Couldn\'t load your journeys';

  @override
  String get camera_noJourneyTitle => 'Start your first journey';

  @override
  String get camera_noJourneyMessage =>
      'Create a journey, then snap one photo a day to keep your streak.';

  @override
  String get camera_noJourneyAction => 'Create journey';

  @override
  String get camera_prePromptTitle => 'One photo a day';

  @override
  String get camera_prePromptMessage =>
      'Ourney needs the camera for your check-in photos. Nothing is posted until you tap Post.';

  @override
  String get camera_prePromptAction => 'Allow camera';

  @override
  String get camera_deniedTitle => 'No camera access';

  @override
  String get camera_deniedMessage =>
      'Turn on camera access to take check-ins. You can still choose a photo from your library.';

  @override
  String get camera_deniedSettingsPath =>
      'Go to Settings › Apps › Ourney › Permissions › Camera, turn it on and come back.';

  @override
  String get camera_openSettings => 'Open Settings';

  @override
  String get camera_restrictedMessage =>
      'The camera is restricted on this device. You can still choose a photo from your library.';

  @override
  String get camera_unavailableTitle => 'No camera found';

  @override
  String get camera_unavailableMessage =>
      'This device has no usable camera. Choose a photo from your library instead.';

  @override
  String get camera_failedTitle => 'Couldn\'t open the camera';

  @override
  String get camera_starting => 'Opening camera…';

  @override
  String get camera_captureFailed =>
      'Couldn\'t take the photo. Please try again.';

  @override
  String get camera_grid => 'Framing grid';

  @override
  String camera_dayHud(int day) {
    return 'Day $day';
  }

  @override
  String camera_streakChip(int days) {
    return '$days day streak';
  }

  @override
  String get camera_ghostOn => 'Day 1 ghost · On';

  @override
  String get camera_ghostOff => 'Day 1 ghost · Off';

  @override
  String get camera_privateVault => 'Private vault';

  @override
  String get camera_filmRoll => 'FILM ROLL';

  @override
  String get camera_partnerWaiting =>
      'Your partner hasn\'t shot yet. You go first.';

  @override
  String get camera_hudBold => 'Bold HUD';

  @override
  String get camera_hudStamp => 'Minimal stamp';

  @override
  String get camera_hudStrip => 'Film strip';

  @override
  String camera_dayStreakBold(int day, int streak) {
    return 'DAY $day · $streak IN A ROW';
  }

  @override
  String get camera_allJourneys => 'All journeys';

  @override
  String get camera_pickerTitle => 'All journeys';

  @override
  String get camera_pickerSearch => 'Search journeys';

  @override
  String get camera_pickerEmpty => 'No journey matches your search.';

  @override
  String get camera_pickerClose => 'Close';

  @override
  String get camera_pickerNotShot => 'Not shot today';

  @override
  String get camera_pickerShot => 'Shot today';

  @override
  String get camera_pickerEnded => 'Ended';

  @override
  String camera_lastPace(String pace) {
    return 'LAST PACE $pace';
  }

  @override
  String camera_lastWeight(String value) {
    return 'Last weigh-in $value';
  }

  @override
  String get camera_weightSliderLabel => 'Weight (kg)';

  @override
  String camera_lastPaceKm(String pace, String km) {
    return 'LAST PACE $pace · km $km';
  }

  @override
  String get camera_pickerPinned => 'Pinned';

  @override
  String camera_dayOfTotal(int day, int total) {
    return 'Day $day/$total';
  }

  @override
  String get camera_notShotToday => 'not shot today';

  @override
  String camera_shotTodayCount(int count) {
    return '$count photos today';
  }

  @override
  String camera_photoCount(int count) {
    return '$count photos';
  }

  @override
  String camera_openToday(int count) {
    return 'Open journey, $count photos today';
  }

  @override
  String camera_allJourneysCount(int count) {
    return 'All journeys ($count)';
  }

  @override
  String camera_squadLastStudy(int minutes, int days) {
    return 'LAST TIME $minutes MIN · $days STREAK';
  }

  @override
  String camera_squadStreak(int days) {
    return '$days DAY STREAK';
  }
}
