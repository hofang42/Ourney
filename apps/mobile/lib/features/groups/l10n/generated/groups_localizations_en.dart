// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'groups_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class GroupsL10nEn extends GroupsL10n {
  GroupsL10nEn([String locale = 'en']) : super(locale);

  @override
  String get groups_title => 'Groups';

  @override
  String get groups_emptyTitle => 'No groups yet';

  @override
  String get groups_emptyMessage =>
      'Enter a friend\'s invite code, or start a group journey from the Journeys tab.';

  @override
  String get groups_joinWithCode => 'Join with code';

  @override
  String get groups_createGroup => 'New group journey';

  @override
  String get groups_activeSection => 'Running';

  @override
  String get groups_finishedSection => 'Finished';

  @override
  String get groups_loadError => 'Couldn\'t load your groups.';

  @override
  String get groups_statusEnded => 'Ended';

  @override
  String get groups_statusArchived => 'Archived';

  @override
  String groups_dayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String groups_dayOpen(int day) {
    return 'Day $day';
  }

  @override
  String get groups_joinTitle => 'Join a group';

  @override
  String get groups_joinCodeLabel => 'Invite code';

  @override
  String get groups_joinCodeHint => '8 letters or digits';

  @override
  String get groups_joinInvalidCode =>
      'Invite codes have exactly 8 letters or digits.';

  @override
  String get groups_joinPreviewTitle => 'You\'re invited to a group journey';

  @override
  String get groups_joinRules =>
      'Groups have up to 10 members. Your progress counts from the day you join, and you can still see the group\'s history.';

  @override
  String get groups_joinButton => 'Join group';

  @override
  String get groups_errorNotFound =>
      'No group uses this code. The owner may have changed it, so ask for a new one.';

  @override
  String get groups_errorFull => 'This group is full (10 members).';

  @override
  String get groups_errorBlocked => 'You can\'t join this group.';

  @override
  String get groups_errorLimit =>
      'You already have 3 journeys running. End one, then join this group.';

  @override
  String get groups_errorEnded => 'This journey has ended.';

  @override
  String get groups_errorForbidden => 'You\'re not allowed to do that.';

  @override
  String get groups_errorNotAlone =>
      'Other members are still in the group. End the journey instead of deleting it.';

  @override
  String get groups_errorInvalid => 'This action isn\'t possible here.';

  @override
  String groups_todayHeader(int done, int total) {
    return '$done of $total checked in today';
  }

  @override
  String get groups_doneSection => 'Checked in today';

  @override
  String get groups_pendingSection => 'Not yet today';

  @override
  String get groups_statusDone => 'Done today';

  @override
  String get groups_statusPending => 'Not yet';

  @override
  String get groups_you => 'You';

  @override
  String get groups_ownerBadge => 'Owner';

  @override
  String groups_latestPhoto(String date) {
    return 'Latest: $date';
  }

  @override
  String get groups_noPhotoYet => 'No check-ins yet';

  @override
  String get groups_endedBanner =>
      'This journey has ended. Photos and streaks are read-only.';

  @override
  String get groups_notFoundTitle => 'Group not found';

  @override
  String get groups_notMember => 'You\'re no longer a member of this group.';

  @override
  String get groups_todayLoadError => 'Couldn\'t load today\'s check-ins.';

  @override
  String get groups_openTimeline => 'My timeline';

  @override
  String get groups_invite => 'Invite';

  @override
  String get groups_moreActions => 'More actions';

  @override
  String groups_memberActions(String name) {
    return 'Actions for $name';
  }

  @override
  String groups_reactSemantics(String emoji, int count) {
    return 'React $emoji, $count so far';
  }

  @override
  String get groups_actionRotate => 'Change invite code';

  @override
  String get groups_rotateTitle => 'Change the invite code?';

  @override
  String get groups_rotateMessage =>
      'The current code and link stop working. Members already in the group stay.';

  @override
  String get groups_rotateDone => 'New invite code ready.';

  @override
  String get groups_actionEnd => 'End journey';

  @override
  String get groups_endTitle => 'End this journey for everyone?';

  @override
  String get groups_endMessage =>
      'Nobody can check in after that. Photos and streaks stay for everyone to look back on.';

  @override
  String get groups_actionDelete => 'Delete journey';

  @override
  String get groups_deleteTitle => 'Delete this group journey?';

  @override
  String get groups_deleteMessage =>
      'You\'re the only member. The journey and your photos are deleted for good.';

  @override
  String get groups_actionLeave => 'Leave group';

  @override
  String get groups_leaveTitle => 'Leave this group?';

  @override
  String get groups_leaveMessage =>
      'Your check-ins will be hidden from the group. If you rejoin with an invite code, they come back.';

  @override
  String get groups_leaveOwnerNote =>
      'You\'re the owner: ownership passes to the member who joined earliest.';

  @override
  String get groups_leaveAloneNote =>
      'You\'re the only member: the journey will be archived.';

  @override
  String get groups_leftDone => 'You left the group.';

  @override
  String get groups_actionRemove => 'Remove from group';

  @override
  String groups_removeTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get groups_removeMessage =>
      'Their check-ins will be hidden from the group. They can rejoin with the invite code unless you change it.';

  @override
  String groups_removedDone(String name) {
    return '$name was removed.';
  }

  @override
  String get groups_actionReport => 'Report';

  @override
  String get groups_actionBlock => 'Block';

  @override
  String get groups_inviteTitle => 'Invite friends';

  @override
  String get groups_inviteMessage =>
      'Send the code or link to friends. Up to 10 members.';

  @override
  String get groups_copyCode => 'Copy code';

  @override
  String get groups_copied => 'Invite code copied.';

  @override
  String get groups_shareLink => 'Share link';

  @override
  String groups_shareText(String title, String link, String code) {
    return 'Join my journey \"$title\" on Ourney: $link (invite code $code)';
  }

  @override
  String get groups_qrSemantics => 'QR code of the invite link';

  @override
  String get groups_noInviteCode => 'This group has no invite code yet.';

  @override
  String get groups_inviteClosed =>
      'The journey has ended, so no one else can join.';

  @override
  String get groups_eyebrow => 'Your people';
}
