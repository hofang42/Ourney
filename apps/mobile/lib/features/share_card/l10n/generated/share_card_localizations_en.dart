// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'share_card_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ShareCardL10nEn extends ShareCardL10n {
  ShareCardL10nEn([String locale = 'en']) : super(locale);

  @override
  String get share_card_title => 'Share';

  @override
  String get share_card_sizeLabel => 'Card size';

  @override
  String get share_card_sizeStory => 'Story';

  @override
  String get share_card_sizeFeed => 'Post';

  @override
  String get share_card_numberLabel => 'Big number';

  @override
  String get share_card_numberStreak => 'Streak';

  @override
  String share_card_numberDay(int day) {
    return 'Day $day';
  }

  @override
  String share_card_captionStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'day streak',
    );
    return '$_temp0';
  }

  @override
  String share_card_captionCheckedIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days checked in',
      one: 'day checked in',
    );
    return '$_temp0';
  }

  @override
  String get share_card_kickerFinished => 'Finished';

  @override
  String share_card_captionFinished(int done, int total) {
    return '$done/$total days';
  }

  @override
  String get share_card_kickerDay => 'Day';

  @override
  String share_card_captionDayOf(int total) {
    return 'of $total';
  }

  @override
  String get share_card_milestone7 => '7-day milestone!';

  @override
  String get share_card_milestone30 => '30-day milestone!';

  @override
  String get share_card_milestoneCompleted => 'Made it!';

  @override
  String get share_card_photoLabel => 'Photo';

  @override
  String get share_card_photoNone =>
      'No check-in photos yet. The card uses an illustration.';

  @override
  String get share_card_coupleOwnPhotos => 'This card shows only your photos.';

  @override
  String get share_card_stateError =>
      'Couldn\'t check which photos are hidden from sharing, so the card has no photo for now. You can still share it with the illustration, or try again.';

  @override
  String share_card_photoOfDay(String date) {
    return 'Photo from $date';
  }

  @override
  String get share_card_blurPhoto => 'Blur photo';

  @override
  String get share_card_blurPhotoHint => 'On because of your privacy settings';

  @override
  String get share_card_blurPhotoLocked => 'Always on for this card style';

  @override
  String get share_card_metricHidden => 'Your metric is not shown on the card.';

  @override
  String get share_card_shareButton => 'Share card';

  @override
  String get share_card_preparing => 'Creating image…';

  @override
  String get share_card_shareError =>
      'Couldn\'t create the image. Please try again.';

  @override
  String share_card_shareText(String emoji, String title) {
    return '$emoji $title on Ourney';
  }

  @override
  String share_card_previewLabel(
    String headline,
    String caption,
    String title,
  ) {
    return 'Card preview: $headline $caption, $title';
  }

  @override
  String get share_card_notFound => 'This journey could not be found.';

  @override
  String get share_card_linkTitle => 'Public view link';

  @override
  String get share_card_linkDescription =>
      'Anyone with the link can view this journey (read-only). You can revoke it at any time.';

  @override
  String get share_card_linkNotYet =>
      'A public link becomes available once this journey is finished.';

  @override
  String get share_card_linkActive =>
      'The link is on. Anyone with it can view this journey.';

  @override
  String get share_card_linkCreate => 'Create & copy link';

  @override
  String get share_card_linkCopy => 'Copy link';

  @override
  String get share_card_linkAlreadyActive => 'A link is already active';

  @override
  String get share_card_linkConflict =>
      'The current link includes a journey title. Resetting it will break the old link.';

  @override
  String get share_card_linkResetAndCopy => 'Reset and copy';

  @override
  String get share_card_linkCopied => 'Link copied';

  @override
  String get share_card_linkRevoke => 'Revoke link';

  @override
  String get share_card_linkRevokeTitle => 'Revoke the link?';

  @override
  String get share_card_linkRevokeMessage =>
      'The current link stops working right away. You can create a new one later.';

  @override
  String get share_card_linkRevoked => 'Link revoked';

  @override
  String get share_card_linkErrorEnded =>
      'This journey is archived, so it can\'t get a link.';

  @override
  String get share_card_linkErrorForbidden =>
      'Only the journey owner can manage the link.';

  @override
  String get share_card_quietTitle => 'Make a card.';

  @override
  String get share_card_squadTitle => 'make a card.';

  @override
  String get share_card_quietPrivate => 'Private';

  @override
  String share_card_dayLabel(int n) {
    return 'DAY $n';
  }

  @override
  String share_card_steadyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n steady days',
      one: '1 steady day',
    );
    return '$_temp0';
  }

  @override
  String share_card_attended(int done, int total, int day) {
    return '$done/$total CHECKED IN · DAY $day';
  }

  @override
  String share_card_cup(int n) {
    return 'CUP $n';
  }

  @override
  String share_card_tripPosterTitle(int days, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days DAYS · $name',
      one: '1 DAY · $name',
    );
    return '$_temp0';
  }

  @override
  String share_card_coupleTitle(int days, int moments) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days DAYS TOGETHER',
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
  String share_card_activeDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ACTIVE DAYS',
      one: '1 ACTIVE DAY',
    );
    return '$_temp0';
  }

  @override
  String share_card_minimalDays(int done, int total) {
    return '$done/$total DAYS';
  }

  @override
  String share_card_minimalDaysOpen(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: '$done DAYS',
      one: '1 DAY',
    );
    return '$_temp0';
  }

  @override
  String share_card_minimalRate(int pct) {
    return '$pct% CONSISTENT';
  }

  @override
  String get share_card_noteBoth =>
      'Cover photo is blurred · weight is always hidden';

  @override
  String get share_card_noteBlur => 'Cover photo is blurred';

  @override
  String get share_card_noteMetric => 'Weight is always hidden';

  @override
  String get share_card_hideBrand => 'Hide the ourney wordmark';

  @override
  String get share_card_brandOn => 'On';

  @override
  String get share_card_brandOff => 'Off';

  @override
  String get share_card_export => 'Export card';

  @override
  String get share_card_exportSaved => 'Card saved.';

  @override
  String get share_card_squadShare => 'Share';

  @override
  String get share_card_memoryShare => 'Share trip poster';

  @override
  String get share_card_coupleShare => 'Share our story';

  @override
  String get share_card_flexerShare => 'Share to Story';

  @override
  String get share_card_minimalExport => 'Export minimal card';

  @override
  String get share_card_squadSheetTitle => 'share the card.';

  @override
  String get share_card_memorySheetTitle => 'share the trip poster.';

  @override
  String get share_card_coupleSheetTitle => 'share the story.';

  @override
  String get share_card_flexerSheetTitle => 'share the achievement.';

  @override
  String get share_card_minimalSheetTitle => 'export the minimal card.';

  @override
  String get share_card_sheetMessages => 'Messages';

  @override
  String get share_card_sheetOther => 'Other apps';

  @override
  String get share_card_sheetSave => 'Save image';

  @override
  String get share_card_privacyTitle => 'Show weight on the card?';

  @override
  String get share_card_privacyBody =>
      'Anyone who sees the card will see this number.';

  @override
  String get share_card_privacyKeep => 'Keep hidden';

  @override
  String get share_card_privacyShow => 'Show anyway';

  @override
  String get share_card_moreOptions => 'Card options';
}
