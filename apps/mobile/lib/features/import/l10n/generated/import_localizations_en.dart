// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'import_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ImportL10nEn extends ImportL10n {
  ImportL10nEn([String locale = 'en']) : super(locale);

  @override
  String get import_headerTitle => 'Retell a past journey';

  @override
  String get import_back => 'Back';

  @override
  String import_stepOf(int n) {
    return 'Step $n of 3';
  }

  @override
  String get import_photosTitle => 'Choose your photos.';

  @override
  String get import_photosIntro =>
      'Pick the photos of the journey you want to retell. Ourney reads the date each photo was taken to place it on the timeline.';

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
  String import_selectedCount(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get import_selectAll => 'Select all';

  @override
  String get import_selectNone => 'Select none';

  @override
  String import_selectPhoto(String date) {
    return 'Select photo $date';
  }

  @override
  String import_deselectPhoto(String date) {
    return 'Deselect photo $date';
  }

  @override
  String import_nextTimeline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return 'Next · $_temp0';
  }

  @override
  String import_pickLimit(int max) {
    return 'A journey takes up to $max photos. The extra photos were left out.';
  }

  @override
  String import_duplicatesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicate photos were skipped',
      one: '1 duplicate photo was skipped',
    );
    return '$_temp0';
  }

  @override
  String get import_pickFailed => 'Could not open the photo library.';

  @override
  String import_maxReached(int max) {
    return 'You have reached $max photos.';
  }

  @override
  String get import_timelineTitle => 'Check the timeline.';

  @override
  String get import_timelineIntro =>
      'Dates come from your photos. Tap the calendar to change a date, or the photo to add a caption.';

  @override
  String import_rangeLine(String range, String days) {
    return '$range · $days';
  }

  @override
  String import_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String import_dayLabel(int day) {
    return 'Day $day';
  }

  @override
  String import_dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String import_gapRow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days with no photos',
      one: '1 day with no photos',
    );
    return '$_temp0';
  }

  @override
  String get import_undatedTitle => 'No date yet';

  @override
  String get import_undatedBody =>
      'Give these photos a date, or remove them, to go on.';

  @override
  String get import_setDateAllUndated => 'Set a date for all';

  @override
  String import_editDate(String date) {
    return 'Change the date of this photo, now $date';
  }

  @override
  String get import_noDate => 'No date';

  @override
  String get import_selectMode => 'Select';

  @override
  String get import_selectDone => 'Done';

  @override
  String import_bulkSetDate(int count) {
    return 'Set date · $count';
  }

  @override
  String import_bulkRemove(int count) {
    return 'Remove · $count';
  }

  @override
  String get import_removePhoto => 'Remove photo';

  @override
  String import_photoRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count photos.',
      one: 'Removed 1 photo.',
    );
    return '$_temp0';
  }

  @override
  String get import_undo => 'Undo';

  @override
  String get import_sourceExif => 'Date taken';

  @override
  String get import_sourceFile => 'File date';

  @override
  String get import_sourceManual => 'Set by you';

  @override
  String get import_errorRange =>
      'A journey can last at most 366 days. Change some dates or remove photos.';

  @override
  String get import_next => 'Next';

  @override
  String get import_detailsTitle => 'Name your journey.';

  @override
  String get import_nameLabel => 'Name or place';

  @override
  String get import_nameHint => 'A past journey';

  @override
  String get import_errorTitle => 'Enter a name for the journey.';

  @override
  String get import_typeHeading => 'Type';

  @override
  String get import_type_weight => 'Weight loss';

  @override
  String get import_type_study => 'English';

  @override
  String get import_type_trip => 'Trip';

  @override
  String get import_type_workout => 'Workout';

  @override
  String get import_type_custom => 'Custom';

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
      'Some layouts need more data, so they only show for the type that uses them.';

  @override
  String get import_previewLabel => 'PREVIEW';

  @override
  String get import_previewHud => 'Daily check-in';

  @override
  String get import_continueTitle => 'Still going?';

  @override
  String get import_continueBody =>
      'Keep the journey open so you can keep checking in. Only new check-ins count toward a streak, not retold photos.';

  @override
  String get import_privacyNote =>
      'Only you can see this journey until you share it. Hiding weight and blurring photos on share follow your Settings.';

  @override
  String get import_save => 'Save journey';

  @override
  String import_summaryLine(int count, String range) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0 · $range';
  }

  @override
  String get import_savingTitle => 'Saving your journey.';

  @override
  String import_preparing(int done, int total) {
    return 'Preparing your photos… $done/$total';
  }

  @override
  String get import_creating => 'Creating the journey…';

  @override
  String import_saving(int done, int total) {
    return 'Saving $done/$total photos…';
  }

  @override
  String get import_pause => 'Pause';

  @override
  String get import_pauseHint =>
      'You can pause. The photos left stay on this device until you continue.';

  @override
  String get import_pausedTitle => 'Paused.';

  @override
  String get import_pausedBody =>
      'Saving is paused. The photos left stay on this device until you continue.';

  @override
  String get import_resume => 'Continue saving';

  @override
  String get import_partialTitle => 'Some photos are not saved.';

  @override
  String get import_dateSheetTitle => 'Pick a date';

  @override
  String get import_dateDay => 'Day';

  @override
  String get import_dateMonth => 'Month';

  @override
  String get import_dateYear => 'Year';

  @override
  String get import_dateCancel => 'Cancel';

  @override
  String get import_createMaybeLanded =>
      'The journey may already have been created. Try again to finish it, or leave: your photos stay on this device and saving continues later.';

  @override
  String get import_abandon => 'Discard this journey';

  @override
  String get import_abandonTitle => 'Discard this journey?';

  @override
  String get import_abandonBody =>
      'Nothing more will be saved and the photos kept on this device are deleted. The journey may still appear in your list, empty.';

  @override
  String get import_abandonConfirm => 'Discard';

  @override
  String get import_signedOutTitle => 'Signed out.';

  @override
  String get import_signedOutBody =>
      'Sign in again to keep saving. Your photos stay on this device.';

  @override
  String get import_dateConfirm => 'Use this date';

  @override
  String get import_cancelling => 'Stopping…';

  @override
  String get import_photoPending => 'Waiting';

  @override
  String get import_photoSaved => 'Saved';

  @override
  String get import_photoFailed => 'Not saved';

  @override
  String get import_reason_unreadable => 'The file cannot be read any more';

  @override
  String get import_reason_offline => 'No connection';

  @override
  String get import_reason_badDate => 'The date does not fit the journey';

  @override
  String get import_reason_unknown => 'Something went wrong';

  @override
  String get import_doneTitle => 'Done.';

  @override
  String import_savedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos saved',
      one: '1 photo saved',
    );
    return '$_temp0';
  }

  @override
  String import_notSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos not saved',
      one: '1 photo not saved',
    );
    return '$_temp0';
  }

  @override
  String get import_openJourney => 'Open journey';

  @override
  String get import_retryFailed => 'Retry failed photos';

  @override
  String get import_leaveRest => 'Leave the rest out';

  @override
  String get import_tryAgain => 'Try again';

  @override
  String get import_editDetails => 'Edit details';

  @override
  String get import_errorInvalid =>
      'The journey details were refused. Check the name and the dates.';

  @override
  String get import_discardTitle => 'Leave without saving?';

  @override
  String get import_discardBody =>
      'The copies Ourney keeps on this device will be deleted (photos in your library stay).';

  @override
  String get import_discardConfirm => 'Leave';

  @override
  String get import_discardKeep => 'Keep going';

  @override
  String get import_captionAddHint => 'Add a caption…';

  @override
  String import_captionSheetEyebrow(int day, String date) {
    return 'Day $day · $date';
  }

  @override
  String get import_captionHint => 'What do you remember about this photo?';

  @override
  String get import_captionHelper => 'Optional. You can edit it after saving.';

  @override
  String get import_captionPrev => 'Previous photo';

  @override
  String get import_captionNext => 'Next photo';

  @override
  String get import_captionDone => 'Done';

  @override
  String get import_captionEditDate => 'Change date';

  @override
  String import_captionOpen(String date) {
    return 'Write a caption for the photo on $date';
  }

  @override
  String get import_discardCaptions => 'Captions you wrote will be lost too.';

  @override
  String get import_captionHideKeyboard => 'Close the keyboard';

  @override
  String import_captionEdit(Object caption, Object date) {
    return 'Edit caption for the photo on $date: $caption';
  }
}
