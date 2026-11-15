// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'profile_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ProfileL10nEn extends ProfileL10n {
  ProfileL10nEn([String locale = 'en']) : super(locale);

  @override
  String get profile_deleteItemProfile => 'Your profile';

  @override
  String get profile_deleteItemJourneys => 'All journeys and photos';

  @override
  String get profile_deleteItemGroups => 'Your membership in groups';

  @override
  String get profile_editScreenTitle => 'edit profile.';

  @override
  String get profile_title => 'profile.';

  @override
  String get profile_setupTitle => 'your profile.';

  @override
  String get profile_setupSubtitle =>
      'Friends see this name and photo on shared journeys.';

  @override
  String get profile_editTitle => 'Edit profile';

  @override
  String get profile_usernameLabel => 'Username';

  @override
  String get profile_usernameHelper => '3–20 characters: a–z, 0–9, _ .';

  @override
  String profile_usernameTooShort(int min) {
    return 'At least $min characters.';
  }

  @override
  String profile_usernameTooLong(int max) {
    return 'At most $max characters.';
  }

  @override
  String get profile_usernameInvalidChars => 'Use only a–z, 0–9, _ .';

  @override
  String get profile_usernameTaken => 'That username is already taken';

  @override
  String get profile_displayNameLabel => 'Display name';

  @override
  String get profile_displayNameEmpty => 'Enter a display name.';

  @override
  String profile_displayNameTooLong(int max) {
    return 'At most $max characters.';
  }

  @override
  String get profile_avatarAdd => 'Add a profile photo';

  @override
  String get profile_avatarOptional => 'Optional';

  @override
  String get profile_avatarChange => 'Change profile photo';

  @override
  String get profile_avatarFromGallery => 'Choose from library';

  @override
  String get profile_avatarFromCamera => 'Take a new photo';

  @override
  String get profile_avatarError =>
      'Couldn\'t upload your profile photo. Please try again.';

  @override
  String profile_avatarSemantics(String name) {
    return 'Profile photo of $name';
  }

  @override
  String get profile_save => 'Save';

  @override
  String get profile_continue => 'Done';

  @override
  String get profile_saving => 'Saving…';

  @override
  String get profile_saveError =>
      'Couldn\'t save your profile. Please try again.';

  @override
  String get profile_offlineError =>
      'You\'re offline. Reconnect and try again.';

  @override
  String get profile_loadError => 'Couldn\'t load your profile.';

  @override
  String get profile_completeTitle => 'Finish your profile';

  @override
  String get profile_completeMessage =>
      'Pick a username so friends can recognise you.';

  @override
  String get profile_guestName => 'Guest';

  @override
  String get profile_guestTitle => 'On-device only';

  @override
  String get profile_guestMessage =>
      'Your data stays on this device. Solo journeys work fully; sign-in and groups need a server.';

  @override
  String get profile_sectionSettings => 'settings';

  @override
  String get profile_reminders => 'Reminders';

  @override
  String get profile_remindersSubtitle => 'Daily check-in reminder time';

  @override
  String get profile_haptics => 'Haptic feedback';

  @override
  String get profile_language => 'Language';

  @override
  String get profile_languageNote =>
      'Follows your device language. Vietnamese by default.';

  @override
  String get profile_safety => 'Terms, privacy & contact';

  @override
  String get profile_sectionAccount => 'account';

  @override
  String get profile_signOut => 'Sign out';

  @override
  String get profile_signOutTitle => 'Sign out of Ourney?';

  @override
  String get profile_signOutMessage =>
      'Photos and data saved on this phone are removed when you sign out, including check-ins that have not been sent yet. Everything already synced comes back when you sign in again with your email.';

  @override
  String get profile_deleteAccount => 'Delete account';

  @override
  String get profile_deleteTitle => 'Delete your account forever?';

  @override
  String get profile_deleteMessage =>
      'Your profile, journeys, check-ins and every photo are deleted from the server and this device. Groups you are in pass to the earliest member. This can\'t be undone.';

  @override
  String profile_deleteTypeToConfirm(String phrase) {
    return 'Type $phrase to confirm';
  }

  @override
  String get profile_deleteConfirmWord => 'DELETE';

  @override
  String get profile_deleteConfirmButton => 'Delete forever';

  @override
  String get profile_deleting => 'Deleting…';

  @override
  String get profile_deleteErrorRetry =>
      'Not fully deleted yet. Try again to remove the rest.';

  @override
  String get profile_deleteErrorReauth =>
      'Your session expired. Sign in again, then delete.';

  @override
  String get profile_back => 'Back';

  @override
  String get profile_statSnaps => 'total check-ins';

  @override
  String get profile_statLongest => 'longest streak';

  @override
  String get profile_statDone => 'journeys finished';

  @override
  String get profile_badgesTitle => 'steady-habit badges.';

  @override
  String get profile_badge7 => 'Steady 7 days';

  @override
  String get profile_badge30 => 'Steady 30 days';

  @override
  String get profile_badgeFinish => 'First finish';

  @override
  String get profile_badge100 => '100 days in';

  @override
  String get profile_badge7Rule => 'Show up 7 days in a row.';

  @override
  String get profile_badge30Rule => 'Show up 30 days in a row.';

  @override
  String get profile_badgeFinishRule => 'Finish your first journey.';

  @override
  String get profile_badge100Rule => 'Check in on 100 days.';

  @override
  String get profile_badgeUnlocked => 'unlocked';

  @override
  String get profile_badgeLocked => 'locked';

  @override
  String get profile_deleteUnderstand => 'I understand this cannot be undone.';

  @override
  String get profile_deleteOwnerNote =>
      'If you own a group, ownership passes to the earliest member.';

  @override
  String get profile_deleteKeep => 'Keep my account';

  @override
  String get profile_deleteContinue => 'Continue';

  @override
  String get profile_deleteOtpTitle => 'confirm with a code.';

  @override
  String get profile_deleteOtpLead =>
      'We sent a 6-digit code to the email or phone number of this account.';

  @override
  String get profile_deleteOtpLabel => '6-digit code to delete the account';

  @override
  String get profile_deleteOtpWrong =>
      'That code is not right. Check it and try again.';

  @override
  String get profile_deleteResend => 'Resend code';

  @override
  String profile_deleteResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get profile_deleteCodeSent => 'New code sent.';

  @override
  String get profile_deleteDoneTitle => 'Account deleted.';

  @override
  String get profile_deleteDoneBody => 'Thanks for using Ourney.';

  @override
  String get profile_deleteDoneButton => 'Back to start';

  @override
  String get profile_deleteBackToSettings => 'Back to settings';

  @override
  String profile_deleteStepSemantics(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get profile_usernameAvailable => 'Available';

  @override
  String profile_avatarColorN(int n) {
    return 'Avatar color $n';
  }

  @override
  String get profile_avatarColors => 'Choose an avatar color';
}
