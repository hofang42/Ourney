// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'social_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SocialL10nEn extends SocialL10n {
  SocialL10nEn([String locale = 'en']) : super(locale);

  @override
  String get social_friendsTitle => 'Friends';

  @override
  String social_friendsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends',
      one: '1 friend',
    );
    return '$_temp0 · only you see this';
  }

  @override
  String get social_add => 'Add';

  @override
  String get social_requests => 'Requests';

  @override
  String get social_noRequests => 'No new requests';

  @override
  String get social_accept => 'Accept';

  @override
  String get social_decline => 'Decline';

  @override
  String get social_requested => 'Requested';

  @override
  String get social_cancelRequest => 'Cancel';

  @override
  String get social_searchFriends => 'Search friends';

  @override
  String get social_emptyFriendsTitle =>
      'Share journeys with the people who were there';

  @override
  String get social_addFriends => 'Add friends';

  @override
  String get social_message => 'Message';

  @override
  String get social_removeFriend => 'Remove friend';

  @override
  String social_removeFriendTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get social_removeFriendBody =>
      'You\'ll stop seeing each other\'s shared journeys.';

  @override
  String social_removed(String name) {
    return 'Removed $name from friends';
  }

  @override
  String get social_block => 'Block';

  @override
  String get social_report => 'Report';

  @override
  String social_sawJourney(String title) {
    return 'Saw $title';
  }

  @override
  String get social_inviteLinkTitle => 'Share my invite link';

  @override
  String get social_inviteLinkHint => 'Anyone who opens it becomes your friend';

  @override
  String get social_share => 'Share';

  @override
  String get social_copy => 'Copy';

  @override
  String get social_linkCopied => 'Link copied';

  @override
  String get social_copied => 'Copied';

  @override
  String social_inviteShareText(String link) {
    return 'Be my friend on Ourney: $link';
  }

  @override
  String get social_qrTitle => 'My QR code';

  @override
  String get social_qrShow => 'Tap to show';

  @override
  String get social_qrEnlarge => 'Tap to enlarge';

  @override
  String get social_qrSemantics => 'Invite link QR code';

  @override
  String get social_findByUsername => 'Find by username';

  @override
  String get social_usernameHint => '@username';

  @override
  String get social_search => 'Search';

  @override
  String get social_exactMatchHint => 'Only an exact username match shows up';

  @override
  String get social_noOne => 'No one with that username';

  @override
  String get social_addFriend => 'Add friend';

  @override
  String get social_alreadyFriends => 'Friends';

  @override
  String get social_thatsYou => 'That\'s you';

  @override
  String get social_rateLimited => 'That\'s a lot of tries. Please wait a bit.';

  @override
  String get social_errorForbidden => 'You can\'t do that';

  @override
  String get social_errorNotFound => 'Not found';

  @override
  String get social_errorBlocked => 'You can\'t add this person';

  @override
  String get social_inviteTitle => 'Friend invite';

  @override
  String get social_inviteAccepting => 'Adding friend…';

  @override
  String social_inviteDone(String name) {
    return 'You and $name are friends now';
  }

  @override
  String get social_inviteNotFound =>
      'This invite link expired or doesn\'t exist';

  @override
  String get social_inviteOwn => 'This is your own invite link';

  @override
  String get social_inviteOwnHint => 'Send it to a friend to connect.';

  @override
  String get social_seeFriends => 'See friends';

  @override
  String get social_inboxTitle => 'Inbox';

  @override
  String get social_inboxNew => 'Inbox, new items';

  @override
  String get social_filterAll => 'All';

  @override
  String get social_filterReplies => 'Replies';

  @override
  String get social_filterInvites => 'Invites';

  @override
  String get social_sectionFriendRequests => 'Friend requests';

  @override
  String social_friendRequestFrom(String name) {
    return 'Friend request from $name';
  }

  @override
  String get social_sectionConsents => 'Share requests';

  @override
  String social_consentRequest(String name, String title) {
    return '$name wants to share $title outside the squad';
  }

  @override
  String get social_agree => 'Agree';

  @override
  String get social_sectionConversations => 'Conversations';

  @override
  String get social_photoMessage => 'Sent a photo';

  @override
  String get social_sectionNewShares => 'Shared with you';

  @override
  String social_newShares(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new journeys shared with you',
      one: '1 new journey shared with you',
    );
    return '$_temp0';
  }

  @override
  String get social_view => 'View';

  @override
  String get social_sectionPublic => 'From your public journeys';

  @override
  String social_publicSummary(int count, String title) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests from people who saw $title',
      one: '1 request from someone who saw $title',
    );
    return '$_temp0';
  }

  @override
  String get social_publicJourneyFallback => 'your public journey';

  @override
  String get social_declineAll => 'Decline all';

  @override
  String get social_inboxEmpty => 'Replies and invites from friends land here';

  @override
  String social_unread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
    );
    return '$_temp0';
  }

  @override
  String get social_messageHint => 'Message';

  @override
  String get social_send => 'Send';

  @override
  String get social_camera => 'Take a photo';

  @override
  String get social_library => 'Photo library';

  @override
  String get social_more => 'More options';

  @override
  String get social_deleteConversation => 'Delete conversation';

  @override
  String social_deleteConversationBody(String name) {
    return 'This only deletes it for you. $name keeps their history.';
  }

  @override
  String get social_delete => 'Delete';

  @override
  String get social_deleteForMe => 'Delete for me';

  @override
  String get social_readOnly => 'You can\'t reply to this conversation';

  @override
  String get social_replyingTo => 'Replying to this photo';

  @override
  String get social_chatEmpty => 'No messages yet';

  @override
  String get social_conversationGone => 'This conversation is gone';

  @override
  String get social_photoFailed => 'Couldn\'t use this photo';

  @override
  String get social_photoSemantics => 'Photo message';

  @override
  String get social_sent => 'Sent';

  @override
  String social_profileFriends(int count) {
    return 'Friends · $count';
  }

  @override
  String social_profileRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests waiting',
      one: '1 request waiting',
    );
    return '$_temp0';
  }
}
