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
}
