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
  String get profile_deleteItemGroups => 'Your membership in squads';

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
  String get profile_usernameUnavailable => 'That username isn\'t available';

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
  String get profile_saveContentPolicy =>
      'Try a different username or display name.';

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
      'Your data stays on this device. Solo journeys work fully; sign-in and squads need a server.';

  @override
  String get profile_signOut => 'Sign out';

  @override
  String get profile_signOutTitle => 'Sign out of Ourney?';

  @override
  String get profile_signOutMessage =>
      'Photos and data saved on this phone are removed when you sign out, including check-ins that have not been sent yet. Everything already synced comes back when you sign in again with this account.';

  @override
  String get profile_deleteTitle => 'Delete your account forever?';

  @override
  String get profile_deleteMessage =>
      'Your profile, journeys, check-ins and every photo are deleted from the server and this device. Squads you are in pass to the earliest member. This can\'t be undone.';

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
      'If you own a squad, ownership passes to the earliest member.';

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
  String get profile_deletePasswordTitle => 'confirm with password.';

  @override
  String get profile_deletePasswordLead =>
      'Enter your account password to confirm permanent deletion.';

  @override
  String get profile_deletePasswordLabel => 'Password';

  @override
  String get profile_deletePasswordWrong =>
      'That password is not right. Try again.';

  @override
  String get profile_deleteUsePassword => 'Confirm with password instead';

  @override
  String get profile_deleteUseCode => 'Use a 6-digit code instead';

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
  String get profile_settings_title => 'settings.';

  @override
  String get profile_settings_back => 'Back';

  @override
  String get profile_settings_secAccount => 'account';

  @override
  String get profile_settings_editProfile => 'Edit profile';

  @override
  String get profile_settings_secReminders => 'reminders';

  @override
  String get profile_settings_remindersRow => 'Daily reminders';

  @override
  String get profile_settings_remindersSub =>
      'Per-journey times and the 21:00 evening reminder';

  @override
  String get profile_settings_widgetsRow => 'Widgets & Live Activities';

  @override
  String get profile_settings_widgetsSub =>
      'Home Screen widgets, Lock Screen widgets, and evening check-in window';

  @override
  String get profile_settings_themeLight => 'Light';

  @override
  String get profile_settings_themeDark => 'Dark';

  @override
  String get profile_settings_themeSystem => 'System';

  @override
  String get profile_settings_themeLabel => 'Theme';

  @override
  String get profile_settings_langVi => 'Việt';

  @override
  String get profile_settings_langEn => 'English';

  @override
  String get profile_settings_appIcon => 'App icon';

  @override
  String get profile_settings_appIconNote =>
      'Changes your home-screen icon. On some Android launchers, the app may briefly close or refresh when switching.';

  @override
  String get profile_settings_iconDefault => 'Default';

  @override
  String get profile_settings_iconYellow => 'Yellow';

  @override
  String get profile_settings_iconGreen => 'Green';

  @override
  String get profile_settings_iconCoral => 'Coral';

  @override
  String get profile_settings_iconViolet => 'Violet';

  @override
  String get profile_settings_iconSky => 'Sky';

  @override
  String get profile_settings_iconDark => 'Dark';

  @override
  String get profile_settings_iconMinimal => 'Minimal';

  @override
  String profile_settings_iconSemantic(String name) {
    return 'App icon $name';
  }

  @override
  String get profile_settings_secPrivacy => 'privacy & safety';

  @override
  String get profile_settings_hideKg => 'Hide kg when sharing';

  @override
  String get profile_settings_blurPhotos => 'Blur photos when sharing';

  @override
  String get profile_settings_blocked => 'Blocked people';

  @override
  String get profile_settings_blockedSub => 'View and unblock';

  @override
  String get profile_settings_secInfo => 'about';

  @override
  String get profile_settings_featureRequests => 'Feedback & feature requests';

  @override
  String get profile_settings_featureRequestsSub =>
      'Vote on ideas or suggest something new';

  @override
  String get profile_settings_eula => 'Terms of use (EULA)';

  @override
  String get profile_settings_privacyPolicy => 'Privacy policy';

  @override
  String get profile_settings_contact => 'Contact';

  @override
  String get profile_settings_version => 'Version';

  @override
  String profile_settings_versionValue(String version) {
    return 'Version $version';
  }

  @override
  String profile_settings_versionUpdateBadge(String latest) {
    return 'Version $latest available';
  }

  @override
  String get profile_settings_versionUpToDate =>
      'You\'re on the latest version';

  @override
  String get profile_settings_versionCheckFailed =>
      'Couldn\'t check for updates right now. Please try again later.';

  @override
  String get profile_settings_signOut => 'Sign out';

  @override
  String get profile_settings_delete => 'Delete account';

  @override
  String get profile_settingsEntry => 'Settings';

  @override
  String profile_signOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count photos have not been uploaded yet. Ourney tries to send them before signing out; any that can\'t be sent are lost.',
      one: '1 photo has not been uploaded yet. Ourney tries to send it before signing out; if it can\'t, it is lost.',
    );
    return '$_temp0';
  }

  @override
  String get profile_settings_secAppearance => 'appearance & language';

  @override
  String get profile_settings_signedInWith => 'Signed in with';

  @override
  String get profile_settings_haptics => 'Haptic feedback';

  @override
  String get profile_settings_shareNote => 'Applies to shared cards and squads';

  @override
  String get profile_settings_themeEyebrow => 'THEME';

  @override
  String get profile_settings_languageEyebrow => 'LANGUAGE';

  @override
  String get profile_settings_secSecurity => 'security';

  @override
  String get profile_settings_setPassword => 'Set password';

  @override
  String get profile_settings_setPasswordSub =>
      'Optional — you can always sign in with a 6-digit code';

  @override
  String get profile_settings_changePassword => 'Change password';

  @override
  String get profile_settings_changePasswordSub =>
      'Active alongside 6-digit sign-in codes';

  @override
  String get profile_settings_passwordPhoneOnly => 'Password';

  @override
  String get profile_settings_passwordPhoneOnlySub =>
      'Phone accounts sign in with SMS codes';

  @override
  String get profile_password_setTitle => 'set password.';

  @override
  String profile_password_setLead(String email) {
    return 'You can sign in with this password or a 6-digit code sent to $email.';
  }

  @override
  String get profile_password_changeTitle => 'change password.';

  @override
  String get profile_password_newLabel => 'New password';

  @override
  String get profile_password_shortError => 'Use at least 8 characters.';

  @override
  String get profile_password_sameError =>
      'New password must be different from your current password.';

  @override
  String get profile_password_signOutOthers => 'Sign out of other devices';

  @override
  String get profile_password_signOutOthersSub =>
      'Keeps you signed in on this device';

  @override
  String get profile_password_continue => 'Continue';

  @override
  String get profile_password_sending => 'Sending code…';

  @override
  String get profile_password_save => 'Save password';

  @override
  String get profile_password_saving => 'Saving…';

  @override
  String get profile_password_codeTitle => 'confirm with a code.';

  @override
  String profile_password_codeLead(String email) {
    return 'Enter the 6-digit code sent to $email to save your password.';
  }

  @override
  String get profile_password_codeLabel => '6-digit verification code';

  @override
  String get profile_password_codeWrong =>
      'That code is wrong or expired. Check it and try again.';

  @override
  String get profile_password_resend => 'Resend code';

  @override
  String profile_password_resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get profile_password_codeResent => 'New code sent.';

  @override
  String get profile_password_rateLimited =>
      'Too many tries. Wait a moment and try again.';

  @override
  String get profile_password_sendError =>
      'Couldn\'t send the verification code. Please try again.';

  @override
  String get profile_password_saveError =>
      'Couldn\'t save your password. Please try again.';

  @override
  String get profile_password_savedSet => 'Password set.';

  @override
  String get profile_password_savedChanged => 'Password updated.';

  @override
  String get profile_password_show => 'Show password';

  @override
  String get profile_password_hide => 'Hide password';
}
