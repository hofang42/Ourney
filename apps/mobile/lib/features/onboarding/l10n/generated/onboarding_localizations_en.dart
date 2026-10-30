// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onboarding_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class OnboardingL10nEn extends OnboardingL10n {
  OnboardingL10nEn([String locale = 'en']) : super(locale);

  @override
  String get onboarding_title => 'Welcome to Ourney';

  @override
  String get onboarding_next => 'Continue';

  @override
  String get onboarding_skip => 'Skip';

  @override
  String get onboarding_languageSwitch => 'Tiếng Việt';

  @override
  String get onboarding_languageSwitchHint => 'Change language';

  @override
  String get onboarding_page1Title => 'One photo at a time. A whole story.';

  @override
  String get onboarding_page1Body =>
      'Keep today, then watch the bigger story take shape.';

  @override
  String get onboarding_page2Title =>
      'Any journey. Alone, with others, or with your person.';

  @override
  String get onboarding_page2Body =>
      'Choose the kind of company that fits your journey.';

  @override
  String get onboarding_page3Title => 'Turn it into something worth sharing.';

  @override
  String get onboarding_page3Body =>
      'Make recaps you will want to keep and share.';

  @override
  String get onboarding_recapTitle => '30 quiet days';

  @override
  String get onboarding_recapSubtitle => 'Daily Reading · October';

  @override
  String get onboarding_recapShare => 'Worth sharing';

  @override
  String onboarding_pageSemantics(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get onboarding_cameraTitle => 'Camera access';

  @override
  String get onboarding_cameraBody =>
      'Ourney needs your camera to take today\'s photo.';

  @override
  String get onboarding_cameraAllow => 'Allow camera';

  @override
  String onboarding_nudgeTitle(String time) {
    return 'Want a nudge tomorrow at $time?';
  }

  @override
  String get onboarding_nudgeAllow => 'Turn on';

  @override
  String get onboarding_notNow => 'Not now';
}
