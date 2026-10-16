// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'safety_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SafetyL10nEn extends SafetyL10n {
  SafetyL10nEn([String locale = 'en']) : super(locale);

  @override
  String get safety_title => 'Safety & support';

  @override
  String get safety_hubIntro =>
      'Ourney is a place to keep habits together. Here you can report bad content, block people and read our terms.';

  @override
  String get safety_hubEula => 'Terms of use';

  @override
  String get safety_hubPrivacy => 'Privacy policy';

  @override
  String get safety_hubContact => 'Contact';

  @override
  String get safety_hubBlocked => 'Blocked people';

  @override
  String get safety_hubHowToReport => 'How to report';

  @override
  String get safety_hubHowToReportBody =>
      'In a group, open the menu of a check-in or a member and choose \"Report\" or \"Block\". Content you report is hidden on your device right away.';

  @override
  String get safety_reportCheckInTitle => 'Report check-in';

  @override
  String get safety_reportUserTitle => 'Report user';

  @override
  String get safety_reportPrompt =>
      'What\'s wrong? Reports are confidential: the person won\'t know it was you.';

  @override
  String get safety_reasonSpam => 'Spam or scam';

  @override
  String get safety_reasonNudity => 'Nudity or sexual content';

  @override
  String get safety_reasonHarassment => 'Harassment or bullying';

  @override
  String get safety_reasonSelfHarm => 'Self-harm';

  @override
  String get safety_reasonOther => 'Something else';

  @override
  String get safety_noteLabel => 'Note (optional)';

  @override
  String get safety_noteHint => 'Extra details help us act faster';

  @override
  String get safety_reportSubmit => 'Send report';

  @override
  String get safety_reportCancel => 'Cancel';

  @override
  String get safety_reportSent =>
      'Report sent. Thank you! This content is now hidden on your device.';

  @override
  String get safety_reportDone => 'Done';

  @override
  String get safety_reportAlsoBlock => 'Also block this person';

  @override
  String get safety_selfHarmTitle => 'You\'re not alone';

  @override
  String get safety_selfHarmBody =>
      'If you or someone else is in immediate danger, call your local emergency services now. Talking to someone you trust, a family member or a mental health professional can also really help.';

  @override
  String get safety_errorRateLimited =>
      'You\'ve sent a lot of reports in the last 24 hours. Please try again later.';

  @override
  String get safety_errorNotFound =>
      'This content no longer exists or you can no longer see it.';

  @override
  String get safety_errorInvalid => 'You can\'t do that to yourself.';

  @override
  String get safety_errorOffline =>
      'No connection. Try again when you\'re back online.';

  @override
  String get safety_errorGeneric =>
      'Something went wrong. Please try again later.';

  @override
  String get safety_needsAccount =>
      'Reporting and blocking need the Ourney server. In on-device mode nobody else can see your content.';

  @override
  String safety_blockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get safety_blockBody =>
      'You won\'t see each other\'s check-ins or reactions any more, and they can\'t join groups you\'re in. They won\'t be told. You can unblock at any time.';

  @override
  String get safety_blockConfirm => 'Block';

  @override
  String get safety_blockCancel => 'Cancel';

  @override
  String safety_blocked(String name) {
    return '$name is blocked.';
  }

  @override
  String safety_unblockTitle(String name) {
    return 'Unblock $name?';
  }

  @override
  String get safety_unblockBody =>
      'You\'ll see each other\'s content again in groups you share.';

  @override
  String get safety_unblockConfirm => 'Unblock';

  @override
  String safety_unblocked(String name) {
    return '$name is unblocked.';
  }

  @override
  String get safety_unknownUser => 'User';

  @override
  String get safety_blockedEmptyTitle => 'You haven\'t blocked anyone';

  @override
  String get safety_blockedEmptyMessage =>
      'People you block show up here so you can unblock them later.';

  @override
  String get safety_loadError =>
      'Couldn\'t load the list. Please try again later.';

  @override
  String get safety_retry => 'Try again';

  @override
  String get safety_contactIntro =>
      'Need help, have feedback or want to flag an urgent safety issue? Write to us. Content reports are reviewed within 24 hours.';

  @override
  String get safety_contactEmailLabel => 'Support email';

  @override
  String get safety_contactSend => 'Send email';

  @override
  String get safety_contactCopy => 'Copy address';

  @override
  String get safety_contactCopied => 'Email address copied.';

  @override
  String get safety_contactSubject => 'Ourney - support';

  @override
  String get safety_contactNoMailApp =>
      'Couldn\'t open a mail app. Copy the address and write from the app you use.';

  @override
  String get safety_eulaAcceptTitle => 'Before you start';

  @override
  String get safety_eulaAcceptIntro =>
      'Ourney has zero tolerance for objectionable content or abusive users. Please read and accept the terms of use to continue.';

  @override
  String get safety_eulaAcceptCheckbox =>
      'I have read and agree to the Terms of use and the Privacy policy.';

  @override
  String get safety_eulaAcceptButton => 'Agree and continue';

  @override
  String safety_lastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get safety_eula1Title => '1. Accepting these terms';

  @override
  String get safety_eula1Body =>
      'By creating an account or using Ourney you agree to these terms. If you don\'t agree, please don\'t use the app.';

  @override
  String get safety_eula2Title => '2. Zero tolerance for objectionable content';

  @override
  String get safety_eula2Body =>
      'Ourney does not tolerate objectionable content or abusive users of any kind. You may not post or send: nudity or sexual content; harassment, bullying or threats; hate speech or discrimination; violence; content that encourages self-harm; spam or scams; anything illegal or that infringes the rights of others.';

  @override
  String get safety_eula3Title => '3. Your content';

  @override
  String get safety_eula3Body =>
      'Photos, captions and numbers you post stay yours. You allow Ourney to store them and show them to the people you choose to share with (group members, people with your public link). You are responsible for what you post.';

  @override
  String get safety_eula4Title => '4. Reporting, blocking and moderation';

  @override
  String get safety_eula4Body =>
      'You can report check-ins or users and block anyone. We review reports within 24 hours, remove content that breaks these terms and remove the accounts of users who post it.';

  @override
  String get safety_eula5Title => '5. Termination';

  @override
  String get safety_eula5Body =>
      'We may suspend or delete accounts that break these terms without notice. You can delete your account at any time from your Profile.';

  @override
  String get safety_eula6Title => '6. Disclaimer and changes';

  @override
  String get safety_eula6Body =>
      'Ourney is provided \"as is\" and is not a substitute for professional medical, nutrition or fitness advice. When these terms change we\'ll let you know in the app.';

  @override
  String get safety_privacy1Title => 'What we store';

  @override
  String get safety_privacy1Body =>
      'Your email (to sign in); display name, username and avatar; the journeys you create; check-ins with their photo, caption, numbers (for example weight) and time taken; reactions; your reports and block list.';

  @override
  String get safety_privacy2Title => 'Who can see it';

  @override
  String get safety_privacy2Body =>
      'Private journeys are visible only to you. Group journeys are visible only to group members. A public link shows only what you turn on, and you can hide numbers or blur photos. In on-device mode your data never leaves your phone.';

  @override
  String get safety_privacy3Title => 'What we don\'t do';

  @override
  String get safety_privacy3Body =>
      'We don\'t sell your data. No ads. Your photos are not used for anything other than showing them in Ourney.';

  @override
  String get safety_privacy4Title => 'Notifications';

  @override
  String get safety_privacy4Body =>
      'Check-in reminders are local notifications, scheduled on your device.';

  @override
  String get safety_privacy5Title => 'Deleting your data';

  @override
  String get safety_privacy5Body =>
      'Go to Profile > Delete account to permanently delete your account and all your check-ins and photos from our servers. If you own a group, ownership passes to the earliest-joined member.';

  @override
  String get safety_privacy6Title => 'Contact';

  @override
  String get safety_privacy6Body =>
      'Questions about privacy? See the Contact page under Safety & support.';
}
