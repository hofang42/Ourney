// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'profile_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ProfileL10nEn extends ProfileL10n {
  ProfileL10nEn([String locale = 'en']) : super(locale);

  @override
  String get profile_title => 'Profile';

  @override
  String get profile_setupTitle => 'Create your profile';

  @override
  String get profile_setupSubtitle =>
      'Friends see this name and photo on shared journeys.';

  @override
  String get profile_editTitle => 'Edit profile';

  @override
  String get profile_usernameLabel => 'Username';

  @override
  String get profile_usernameHelper =>
      '3–20 characters: lowercase letters, digits, _ and .';

  @override
  String profile_usernameTooShort(int min) {
    return 'At least $min characters.';
  }

  @override
  String profile_usernameTooLong(int max) {
    return 'At most $max characters.';
  }

  @override
  String get profile_usernameInvalidChars =>
      'Use only lowercase a–z, digits, _ and dots.';

  @override
  String get profile_usernameTaken =>
      'That username is taken. Try another one.';

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
  String get profile_continue => 'Continue';

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
  String get profile_sectionSettings => 'Settings';

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
  String get profile_sectionAccount => 'Account';

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
}
