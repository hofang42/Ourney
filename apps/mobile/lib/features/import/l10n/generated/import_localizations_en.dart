// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'import_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ImportL10nEn extends ImportL10n {
  ImportL10nEn([String locale = 'en']) : super(locale);

  @override
  String get import_headerTitle => 'import a past journey.';

  @override
  String get import_back => 'Back';

  @override
  String get import_setupTitle => 'Pick a type and layout.';

  @override
  String get import_type_weight => 'Weight loss';

  @override
  String get import_type_study => 'English';

  @override
  String get import_type_trip => 'Trip';

  @override
  String get import_type_couple => 'Couple';

  @override
  String get import_type_workout => 'Workout';

  @override
  String get import_type_custom => 'Custom';

  @override
  String get import_placeLabel => 'Name or place';

  @override
  String get import_placeHint => 'A past journey';

  @override
  String get import_layoutHeading => 'Layout';

  @override
  String get import_layout_quiet => 'Quiet';

  @override
  String get import_layout_memory => 'Memory';

  @override
  String get import_layout_flexer => 'Flexer';

  @override
  String get import_layout_minimal => 'Minimalist';

  @override
  String get import_layoutNote =>
      'Some layouts need more data, so they are hidden.';

  @override
  String get import_previewLabel => 'PREVIEW';

  @override
  String get import_previewHud => 'Camera HUD';

  @override
  String get import_pickOld => 'Choose old photos';

  @override
  String get import_libraryTitle => 'Choose old photos.';

  @override
  String get import_libraryIntro =>
      'Pick several photos. Ourney reads the date taken to place them in the journey.';

  @override
  String get import_openLibrary => 'Open photo library';

  @override
  String get import_addMore => 'Add photos';

  @override
  String get import_libraryEmptyTitle => 'No photos yet';

  @override
  String get import_libraryEmptyBody =>
      'Pick old photos from your library to rebuild the journey.';

  @override
  String get import_noDate => 'No date';

  @override
  String import_selectPhoto(String date) {
    return 'Select photo $date';
  }

  @override
  String import_deselectPhoto(String date) {
    return 'Deselect photo $date';
  }

  @override
  String import_reviewButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return 'Review $_temp0';
  }

  @override
  String get import_reviewTitle => 'Review on the timeline.';

  @override
  String import_dayLabel(int day) {
    return 'Day $day';
  }

  @override
  String get import_noPhotos => 'No photo yet';

  @override
  String import_fromLibrary(String date) {
    return '$date · from library';
  }

  @override
  String get import_extraInDay => 'extra photo that day';

  @override
  String get import_undatedTitle => 'No date yet';

  @override
  String get import_assignDate => 'Set date';

  @override
  String get import_drop => 'Remove';

  @override
  String get import_startLabel => 'Start';

  @override
  String get import_endLabel => 'End';

  @override
  String get import_continueTitle => 'Keep shooting';

  @override
  String get import_continueBody =>
      'The streak starts from the first real photo; imported photos do not count.';

  @override
  String get import_privateNote =>
      'Weight stays hidden and photos stay blurred when shared.';

  @override
  String get import_save => 'Save journey';

  @override
  String import_saving(int done, int total) {
    return 'Saving $done/$total photos…';
  }

  @override
  String import_failed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos could not be saved',
      one: '1 photo could not be saved',
    );
    return '$_temp0';
  }

  @override
  String get import_retry => 'Try again';

  @override
  String get import_openJourney => 'Open journey';

  @override
  String get import_errorNoPhotos => 'Pick at least one photo with a date.';

  @override
  String get import_errorUndated =>
      'Set a date for, or remove, the undated photos.';

  @override
  String get import_errorTitle => 'Enter a name or place.';

  @override
  String get import_errorOutside =>
      'Some photos fall outside the chosen dates.';

  @override
  String get import_errorFuture => 'The end date cannot be in the future.';

  @override
  String get import_errorRange => 'A journey can last at most 366 days.';

  @override
  String get import_errorGeneric => 'Could not save the journey. Try again.';

  @override
  String get import_pickFailed => 'Could not open the photo library.';

  @override
  String import_failedWithReason(int count, String reason) {
    return '$count photos could not be saved ($reason)';
  }
}
