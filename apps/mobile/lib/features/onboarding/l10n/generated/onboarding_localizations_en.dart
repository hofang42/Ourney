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
  String get onboarding_start => 'Get started';

  @override
  String get onboarding_next => 'Next';

  @override
  String get onboarding_skip => 'Skip';

  @override
  String get onboarding_valueTitle =>
      'One photo a day. See how far you\'ve come.';

  @override
  String get onboarding_valueBody =>
      'Ourney turns small habits into a journey: losing weight, learning English, working out or a trip.';

  @override
  String get onboarding_howTitle => 'Checking in takes 5 seconds';

  @override
  String get onboarding_howStep1 => 'Open the app and shoot right away';

  @override
  String get onboarding_howStep2 =>
      'Add it to a journey, with a note or a measurement';

  @override
  String get onboarding_howStep3 => 'Keep your streak and bring friends along';

  @override
  String get onboarding_readyTitle => 'Ready?';

  @override
  String get onboarding_readyBody =>
      'Ourney only asks for camera and notification access when it needs them, not right now.';

  @override
  String onboarding_pageSemantics(int current, int total) {
    return 'Page $current of $total';
  }
}
