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
      'Pick something you want to do regularly, then take your first photo.';

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
  String camera_streakChip(int days) {
    return '$days day streak';
  }

  @override
  String get camera_ghostOn => 'Day 1 ghost · On';

  @override
  String get camera_ghostOff => 'Day 1 ghost · Off';

  @override
  String get camera_pickerTitle => 'All journeys';

  @override
  String get camera_pickerSearch => 'Search journeys';

  @override
  String get camera_pickerEmpty => 'No journey matches your search.';

  @override
  String get camera_pickerNotShot => 'Not shot today';

  @override
  String get camera_pickerShot => 'Shot today';

  @override
  String get camera_pickerEnded => 'Ended';

  @override
  String get camera_pickerPinned => 'Pinned';

  @override
  String camera_allJourneysCount(int count) {
    return 'All journeys ($count)';
  }

  @override
  String camera_chipDay(String title, int day) {
    return '$title · Day $day';
  }

  @override
  String get camera_partnerPhoto => 'Partner\'s photo';

  @override
  String get camera_partnerPhotoEnlargeHint => 'Tap to enlarge';

  @override
  String get camera_partnerPhotoShrinkHint => 'Tap to shrink';
}
