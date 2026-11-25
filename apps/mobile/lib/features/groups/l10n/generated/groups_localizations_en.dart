// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'groups_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class GroupsL10nEn extends GroupsL10n {
  GroupsL10nEn([String locale = 'en']) : super(locale);

  @override
  String get groups_title => 'Squad';

  @override
  String get groups_joinWithCode => 'Join with code';

  @override
  String get groups_activeSection => 'Running';

  @override
  String get groups_finishedSection => 'Finished';

  @override
  String get groups_loadError => 'Couldn\'t load your squads.';

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
  String get groups_joinTitle => 'Join a squad';

  @override
  String get groups_joinCodeLabel => 'Invite code';

  @override
  String get groups_joinCodeHint => '8 letters or digits';

  @override
  String get groups_joinInvalidCode =>
      'Invite codes have exactly 8 letters or digits.';

  @override
  String get groups_joinPreviewTitle => 'You\'re invited to a squad journey';

  @override
  String get groups_joinRules =>
      'Squads have up to 10 members. Your progress counts from the day you join, and you can still see the squad\'s history.';

  @override
  String get groups_joinButton => 'Join squad';

  @override
  String get groups_joinLater => 'Later';

  @override
  String get groups_errorNotFound =>
      'No squad uses this code. The owner may have changed it, so ask for a new one.';

  @override
  String get groups_errorFull => 'This squad is full (10 members).';

  @override
  String get groups_errorBlocked => 'You can\'t join this squad.';

  @override
  String get groups_errorEnded => 'This journey has ended.';

  @override
  String get groups_errorSyncPending =>
      'Photos are still uploading. Try again in a moment.';

  @override
  String get groups_errorForbidden => 'You\'re not allowed to do that.';

  @override
  String get groups_errorNotAlone =>
      'Other members are still in the squad. End the journey instead of deleting it.';

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
  String get groups_notFoundTitle => 'Squad not found';

  @override
  String get groups_notMember => 'You\'re no longer a member of this squad.';

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
      'The current code and link stop working. Members already in the squad stay.';

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
  String get groups_deleteTitle => 'Delete this squad journey?';

  @override
  String get groups_deleteMessage =>
      'You\'re the only member. The journey and your photos are deleted for good.';

  @override
  String get groups_actionLeave => 'Leave squad';

  @override
  String get groups_leaveTitle => 'Leave this squad?';

  @override
  String get groups_leaveMessage =>
      'Your check-ins will be hidden from the squad. If you rejoin with an invite code, they come back.';

  @override
  String get groups_leaveOwnerNote =>
      'You\'re the owner: ownership passes to the member who joined earliest.';

  @override
  String get groups_leaveAloneNote =>
      'You\'re the only member: the journey will be archived.';

  @override
  String get groups_leftDone => 'You left the squad.';

  @override
  String get groups_actionRemove => 'Remove from squad';

  @override
  String groups_removeTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get groups_removeMessage =>
      'Their check-ins will be hidden from the squad. They can rejoin with the invite code unless you change it.';

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
  String get groups_noInviteCode => 'This squad has no invite code yet.';

  @override
  String get groups_inviteClosed =>
      'The journey has ended, so no one else can join.';

  @override
  String groups_joinCodeBoxesSemantics(int count) {
    return 'Invite code, $count of 8 characters entered';
  }

  @override
  String groups_previewOwner(String name) {
    return 'Owner: $name';
  }

  @override
  String get groups_previewMembers => 'Members';

  @override
  String groups_previewMembersValue(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$count of $max people',
      one: '$count of 1 person',
    );
    return '$_temp0';
  }

  @override
  String get groups_previewDuration => 'Length';

  @override
  String groups_previewDurationValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get groups_previewDurationOpen => 'No end date';

  @override
  String get groups_previewProgress => 'Progress';

  @override
  String groups_previewProgressValue(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String groups_previewProgressOpen(int day) {
    return 'Day $day';
  }

  @override
  String get groups_previewPrivate =>
      'This squad has no public link. Only people with the code can join.';

  @override
  String get groups_previewAlreadyMember => 'You are already in this squad.';

  @override
  String get groups_previewOpenGroup => 'Open squad';

  @override
  String get groups_previewLoading => 'Looking up the code…';

  @override
  String get groups_errorRateLimited =>
      'Too many tries. Wait a little, then try again.';

  @override
  String get groups_inviteSheetTitle => 'Invite by username';

  @override
  String get groups_inviteHandleLabel => 'Username';

  @override
  String get groups_inviteSend => 'Send invite';

  @override
  String get groups_inviteSent => 'Invitation sent';

  @override
  String get groups_invitePendingTitle => 'Pending invitations';

  @override
  String get groups_invitePendingEmpty => 'No pending invitations.';

  @override
  String get groups_inviteRevoke => 'Revoke';

  @override
  String get groups_inviteRevoked => 'Invitation revoked';

  @override
  String get groups_inviteShareCode => 'Share the code instead';

  @override
  String get groups_inviteNeedsHandle => 'Enter a username first.';

  @override
  String get groups_codeLabel => 'Invite code';

  @override
  String get groups_codeHint => '8-character code';

  @override
  String get groups_pasteCode => 'Paste';

  @override
  String get groups_pasteNoCode => 'No invite code in your clipboard';

  @override
  String get groups_joinAction => 'Join';

  @override
  String get groups_todayHeading => 'Today';

  @override
  String groups_checkedInCount(int done, int total) {
    return '$done/$total checked in';
  }

  @override
  String get groups_memberWaiting => 'not yet';

  @override
  String groups_openTodayOf(String name) {
    return 'Open today for $name';
  }

  @override
  String get groups_pendingInvitesHeading => 'Pending invites';

  @override
  String groups_inviteLine(String inviter, String title) {
    return '$inviter invited you to $title';
  }

  @override
  String get groups_inviteAccept => 'Join';

  @override
  String get groups_inviteSkip => 'Skip';

  @override
  String get groups_memberReport => 'Report user';

  @override
  String get groups_memberBlock => 'Block';

  @override
  String groups_memberHandle(String username) {
    return '@$username';
  }

  @override
  String groups_memberCheckedAt(String time) {
    return 'Checked in at $time';
  }

  @override
  String get groups_memberNotYetToday => 'Not checked in yet today';

  @override
  String groups_memberStreak(int count) {
    return '$count-day streak';
  }

  @override
  String get groups_memberCheckInNow => 'Check in now';

  @override
  String get groups_memberAddPhoto => 'Add a photo';

  @override
  String groups_overflowMore(int count) {
    return '+$count';
  }

  @override
  String get groups_emptyCardTitle => 'no squads yet.';

  @override
  String get groups_emptyCardBody =>
      'Enter an invite code to join a squad or start a squad journey.';

  @override
  String groups_wallUpdated(String time) {
    return 'Updated at $time';
  }

  @override
  String groups_wallWaiting(String name) {
    return '$name · NOT YET';
  }

  @override
  String get groups_quietTitle => 'Squad today.';

  @override
  String get groups_quietIntro => 'Sorted by name, not by results.';

  @override
  String groups_quietDone(String time) {
    return 'Snapped $time';
  }

  @override
  String get groups_quietNotYet => 'Not snapped yet';

  @override
  String groups_quietSteady(int count) {
    return 'steady $count/7';
  }

  @override
  String get groups_quietShow => 'Show photo';

  @override
  String get groups_quietHide => 'Hide photo';

  @override
  String get groups_quietFooter =>
      'Nobody gets compared. We only count steadiness.';

  @override
  String groups_memoryTitle(int done, int total) {
    return 'TODAY · $done/$total HAVE A FRAME';
  }

  @override
  String groups_memoryFrame(String name, String time) {
    return '$name · $time';
  }

  @override
  String groups_memoryMissing(String name) {
    return '$name · NO FRAME YET';
  }

  @override
  String get groups_coupleTitle => 'Today, the two of you';

  @override
  String groups_coupleDone(String name, String time) {
    return '$name · snapped $time';
  }

  @override
  String groups_coupleCheckedIn(String name) {
    return '$name · checked in';
  }

  @override
  String groups_coupleWaiting(String name) {
    return '$name · waiting';
  }

  @override
  String groups_flexerTitle(int done, int total) {
    return '$done/$total DONE';
  }

  @override
  String groups_flexerDone(String time) {
    return 'Done · $time';
  }

  @override
  String get groups_flexerPending => 'NOT YET';

  @override
  String groups_flexerTrainedTitle(int done, int total) {
    return '$done/$total DONE';
  }

  @override
  String groups_flexerTrainedDone(String time) {
    return 'Done · $time';
  }

  @override
  String get groups_flexerTrainedPending => 'NOT YET';

  @override
  String groups_minimalTitle(int done, int total) {
    return '$done/$total DONE';
  }

  @override
  String get groups_minimalPending => 'NOT YET';

  @override
  String get groups_inviteRevokeTitle => 'Revoke this invite?';

  @override
  String get groups_inviteRevokeMessage =>
      'The invited person will no longer be able to use it.';

  @override
  String groups_flexerKm(String km) {
    return '$km KM';
  }

  @override
  String groups_flexerKmPace(String km, String pace) {
    return '$km KM · $pace /KM';
  }
}
