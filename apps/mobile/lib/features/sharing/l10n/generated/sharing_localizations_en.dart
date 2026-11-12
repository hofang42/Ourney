// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'sharing_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SharingL10nEn extends SharingL10n {
  SharingL10nEn([String locale = 'en']) : super(locale);

  @override
  String get sharing_title => 'Sharing';

  @override
  String get sharing_shareThisJourney => 'Share this journey';

  @override
  String get sharing_editStory => 'Edit story';

  @override
  String get sharing_friends => 'Friends';

  @override
  String get sharing_selectAll => 'Select all';

  @override
  String get sharing_clear => 'Clear';

  @override
  String get sharing_searchFriends => 'Search friends';

  @override
  String get sharing_canSee => 'Can see';

  @override
  String get sharing_remove => 'Remove';

  @override
  String get sharing_sensitiveHelper =>
      'Sensitive journey: pick people one by one';

  @override
  String get sharing_runningHelper => 'They\'ll see new photos as you post';

  @override
  String sharing_shareWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Share with $count friends',
      one: 'Share with 1 friend',
    );
    return '$_temp0';
  }

  @override
  String get sharing_pickFriends => 'Pick friends to share';

  @override
  String get sharing_noFriends => 'Add friends to share with them';

  @override
  String sharing_sharedSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared with $count friends',
      one: 'Shared with 1 friend',
    );
    return '$_temp0';
  }

  @override
  String sharing_removeFriendShare(String name) {
    return 'Remove $name from viewers';
  }

  @override
  String get sharing_publicLink => 'Public link';

  @override
  String get sharing_linkLockedTitle =>
      'Links open when this journey is finished';

  @override
  String get sharing_linkLockedSub => 'Public access is not available yet';

  @override
  String get sharing_linkOwnerOnly => 'Managed by the journey owner';

  @override
  String get sharing_linkOn => 'Link on';

  @override
  String get sharing_linkOff => 'Off';

  @override
  String get sharing_under18 => 'Public links are for 18+';

  @override
  String get sharing_blurredPreview => 'Photos blurred in previews';

  @override
  String get sharing_copyLink => 'Copy link';

  @override
  String get sharing_linkCopied => 'Link copied';

  @override
  String get sharing_resetLink => 'Reset link';

  @override
  String get sharing_resetConfirmTitle => 'Reset the link?';

  @override
  String get sharing_resetConfirmBody =>
      'The old link stops working. Counts so far are kept.';

  @override
  String get sharing_linkHelper =>
      'Anyone with the link can view it and do this journey too';

  @override
  String get sharing_showCounts => 'Show counts';

  @override
  String get sharing_showCountsHint =>
      'Show likes and follow-alongs to viewers';

  @override
  String get sharing_letAnyoneReact => 'Let anyone react';

  @override
  String get sharing_letAnyoneReactHint =>
      'People with an Ourney account can like it';

  @override
  String get sharing_allowRequests => 'Allow friend requests from viewers';

  @override
  String get sharing_allowRequestsHint =>
      'Viewers can send you a friend request';

  @override
  String sharing_statsLine(String views, String likes, String started) {
    return '$views views · $likes ❤️ · $started started';
  }

  @override
  String get sharing_stopSharing => 'Stop sharing';

  @override
  String get sharing_stopConfirm =>
      'Everyone loses access. People who started this journey keep theirs.';

  @override
  String get sharing_stopMineConfirm =>
      'Friends you shared with lose access. Other members\' shares stay.';

  @override
  String get sharing_removeMyPhotos => 'Remove my photos from sharing';

  @override
  String get sharing_removeMyPhotosConfirm =>
      'Your photos won\'t show to anyone outside the group.';

  @override
  String get sharing_warnTitle => 'Anyone with the link can see this journey';

  @override
  String get sharing_warnAnyone => 'Anyone who receives the link can view it.';

  @override
  String get sharing_warnSelected =>
      'Only selected photos show; previews are blurred.';

  @override
  String get sharing_warnUndo => 'You can turn the link off at any time.';

  @override
  String get sharing_warnTurnOn => 'Turn on link';

  @override
  String get sharing_warnSwitchTitle => 'This is a personal journey';

  @override
  String get sharing_warnSwitchBody =>
      'People outside your friends will see or do more. You can turn this off at any time.';

  @override
  String get sharing_warnSwitchConfirm => 'Turn on';

  @override
  String get sharing_consentTitle => 'Squad consent';

  @override
  String get sharing_consentHelper =>
      'Only photos of people who agreed are shared';

  @override
  String get sharing_consentAgreed => 'Agreed';

  @override
  String get sharing_consentWaiting => 'Waiting';

  @override
  String get sharing_consentDeclined => 'Declined';

  @override
  String get sharing_consentWithdrawn => 'Withdrawn';

  @override
  String get sharing_askGroup => 'Ask the group first';

  @override
  String get sharing_askGroupHint =>
      'A group journey asks everyone before it is shared outside.';

  @override
  String get sharing_askedSnack => 'Request sent to the group';

  @override
  String get sharing_errorNotFriend => 'You can only share with friends';

  @override
  String get sharing_errorRateLimited => 'Slow down a little and try again';

  @override
  String get sharing_storyHeader => 'Your story';

  @override
  String get sharing_storyTitleField => 'Story title';

  @override
  String get sharing_introField => 'Intro';

  @override
  String get sharing_introHint => 'Why I started…';

  @override
  String get sharing_lessonsField => 'What I learned';

  @override
  String get sharing_optional => 'Optional';

  @override
  String get sharing_pickCover => 'Pick cover photo';

  @override
  String get sharing_coverTitle => 'Cover photo';

  @override
  String get sharing_noPhotosYet => 'No photos yet';

  @override
  String get sharing_hidePhotos => 'Hide photos';

  @override
  String get sharing_hidePhotosHint =>
      'Tap a photo to hide it from every share';

  @override
  String sharing_photoHidden(String date) {
    return 'Photo of $date, hidden in shares';
  }

  @override
  String sharing_photoShown(String date) {
    return 'Photo of $date, shown in shares';
  }

  @override
  String get sharing_storySaved => 'Story saved';

  @override
  String get sharing_fromFriends => 'From friends';

  @override
  String get sharing_saved => 'Saved';

  @override
  String sharing_byName(String name) {
    return 'by $name';
  }

  @override
  String get sharing_imported => 'Imported';

  @override
  String get sharing_newBadge => 'New';

  @override
  String get sharing_savedFromLink => 'Liked from a public link';

  @override
  String get sharing_live => 'Live';

  @override
  String get sharing_finished => 'Finished';

  @override
  String get sharing_emptyTitle => 'Nothing shared with you yet';

  @override
  String get sharing_emptyMessage =>
      'When a friend shares a journey, it shows up here.';

  @override
  String sharing_removeSavedSemantics(String title) {
    return 'Remove $title from saved';
  }

  @override
  String get sharing_privateNow => 'This journey is private now';

  @override
  String get sharing_goBack => 'Go back';

  @override
  String get sharing_addFriend => 'Add friend';

  @override
  String get sharing_requested => 'Requested';

  @override
  String sharing_liveDay(int day) {
    return 'Live · Day $day';
  }

  @override
  String sharing_importedRange(String range) {
    return 'Imported · $range · by photo date';
  }

  @override
  String sharing_moments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moments',
      one: '1 moment',
    );
    return '$_temp0';
  }

  @override
  String get sharing_more => 'more';

  @override
  String get sharing_less => 'less';

  @override
  String sharing_counts(int likes, int follows) {
    return '❤️ $likes · $follows people did this journey';
  }

  @override
  String sharing_dayN(int day) {
    return 'Day $day';
  }

  @override
  String get sharing_like => 'Like';

  @override
  String get sharing_unlike => 'Unlike';

  @override
  String get sharing_reply => 'Reply';

  @override
  String sharing_replyHint(String name) {
    return 'Only $name sees your reply';
  }

  @override
  String get sharing_doThisJourney => 'Do this journey';

  @override
  String sharing_sharedBy(String name) {
    return 'Shared by $name';
  }

  @override
  String get sharing_savedSnack => 'Saved to Shared with me';

  @override
  String get sharing_requestSentSnack => 'Friend request sent';

  @override
  String get sharing_photoBlurred => 'Photo blurred';

  @override
  String get sharing_preview => 'Preview as a friend';

  @override
  String get sharing_followTitle => 'Do this journey';

  @override
  String sharing_startYourOwn(String style) {
    return 'Start your own $style journey';
  }

  @override
  String sharing_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get sharing_openEnded => 'No end date';

  @override
  String get sharing_daily => 'Daily';

  @override
  String get sharing_noMetrics => 'No metrics';

  @override
  String get sharing_whatYouGet => 'What you\'ll get';

  @override
  String get sharing_sameStyle => 'Same style';

  @override
  String get sharing_sameRhythm => 'Same rhythm';

  @override
  String get sharing_sameMetrics => 'Same metrics';

  @override
  String get sharing_startFresh => 'Your photos and numbers start fresh.';

  @override
  String get sharing_squadNote =>
      'A squad journey — you\'ll invite your own people';

  @override
  String get sharing_startThis => 'Start this journey';

  @override
  String get sharing_changeSomething => 'Change something';

  @override
  String sharing_basedOn(String name) {
    return 'Based on $name\'s journey';
  }

  @override
  String get sharing_removeBasedOn => 'Remove source journey';

  @override
  String get sharing_insightsTitle => 'Insights';

  @override
  String get sharing_views => 'Views';

  @override
  String get sharing_likes => 'Likes';

  @override
  String get sharing_started => 'Started this journey';

  @override
  String sharing_newViewersWeek(int count) {
    return '+$count new viewers this week';
  }

  @override
  String sharing_thisWeek(int count) {
    return '+$count this week';
  }

  @override
  String get sharing_viewsPerDay => 'People who viewed each day';

  @override
  String get sharing_last30Days => 'Last 30 days';

  @override
  String sharing_chartSemantics(int max) {
    return 'Views over the last 30 days, at most $max people a day';
  }

  @override
  String sharing_likesFriends(int count) {
    return 'Friends $count';
  }

  @override
  String sharing_likesOthers(int count) {
    return 'Others $count';
  }

  @override
  String get sharing_likersTitle => 'Who liked your photos';

  @override
  String get sharing_noLikers => 'No likes yet';

  @override
  String get sharing_privacyNote =>
      'Views are counted, not listed. Nobody knows you saw their journey either.';

  @override
  String get sharing_linkOffNote => 'Link off · counts paused';

  @override
  String get sharing_retellTitle => 'Retell a past journey';

  @override
  String get sharing_retellIntro =>
      'Already did it? Turn old photos into a story';

  @override
  String get sharing_pickPhotos => 'Pick photos';

  @override
  String get sharing_addPhotos => 'Add photos';

  @override
  String sharing_photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get sharing_photosHint =>
      'Photos line up by date. Tap a date to change it.';

  @override
  String get sharing_journeyName => 'Journey name';

  @override
  String get sharing_style => 'Style';

  @override
  String get sharing_metricOptional => 'Metric (optional)';

  @override
  String get sharing_metricName => 'Metric name';

  @override
  String get sharing_metricUnit => 'Unit';

  @override
  String sharing_changeDate(String date) {
    return 'Change photo date, now $date';
  }

  @override
  String get sharing_removePhoto => 'Remove photo';

  @override
  String get sharing_sameDay =>
      'Same day: the later photo replaces the earlier one';

  @override
  String sharing_rangeLine(String range, String days) {
    return '$range · $days';
  }

  @override
  String get sharing_saveToShelf => 'Save to shelf';

  @override
  String sharing_saving(int done, int total) {
    return 'Saving $done/$total photos…';
  }

  @override
  String get sharing_errorTitleEmpty => 'Give it a name';

  @override
  String get sharing_errorRange =>
      'Keep it within 366 days from first to last photo';

  @override
  String get sharing_errorFuture => 'Photo dates can\'t be in the future';

  @override
  String get sharing_errorNoPhotos => 'Pick at least one photo';

  @override
  String sharing_retellFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos could not be saved',
      one: '1 photo could not be saved',
    );
    return '$_temp0';
  }

  @override
  String get sharing_retry => 'Try again';

  @override
  String get sharing_openJourney => 'Open journey';
}
