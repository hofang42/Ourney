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
  String get share_card_numberDay => 'Day N';

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
  String share_card_photoOfDay(String date) {
    return 'Photo from $date';
  }

  @override
  String get share_card_blurPhoto => 'Blur photo';

  @override
  String get share_card_blurPhotoHint =>
      'On because of this journey\'s privacy settings';

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
  String get share_card_linkActive =>
      'The link is on. Anyone with it can view this journey.';

  @override
  String get share_card_linkCreate => 'Create & copy link';

  @override
  String get share_card_linkCopy => 'Copy link';

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
}
