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
  String get onboarding_skip => 'Skip';

  @override
  String get onboarding_cameraTitle => 'let ourney use the camera.';

  @override
  String get onboarding_cameraBody =>
      'To take the first photo of your journey. Photos only show to people in that journey.';

  @override
  String get onboarding_cameraAllow => 'Allow';

  @override
  String get onboarding_nudgeTitle =>
      'let us nudge you before the streak breaks.';

  @override
  String get onboarding_nudgeAllow => 'Allow';

  @override
  String get onboarding_notNow => 'maybe later.';

  @override
  String onboarding_quizStep(int n) {
    return 'Question $n/3';
  }

  @override
  String get onboarding_quizBack => 'Previous question';

  @override
  String get onboarding_quizQ1 => 'what do you want to stick with?';

  @override
  String get onboarding_quizQ2 => 'on your own or with company?';

  @override
  String get onboarding_quizQ3 => 'when do you usually forget?';

  @override
  String get onboarding_goalWeight => 'Lose weight';

  @override
  String get onboarding_goalEnglish => 'Learn English';

  @override
  String get onboarding_goalWorkout => 'Work out';

  @override
  String get onboarding_goalTrip => 'A trip';

  @override
  String get onboarding_goalCouple => 'A ritual for two';

  @override
  String get onboarding_goalHabit => 'A small habit';

  @override
  String get onboarding_whoSolo => 'On my own';

  @override
  String get onboarding_whoSoloHint => 'only you see it';

  @override
  String get onboarding_whoGroup => 'With friends';

  @override
  String get onboarding_whoGroupHint => 'up to 10 people';

  @override
  String get onboarding_whoCouple => 'Just the two of us';

  @override
  String get onboarding_whoCoupleHint => 'paired, two people only';

  @override
  String get onboarding_coupleStyleHint => 'we will use the Two of us style';

  @override
  String get onboarding_remMorning => 'Early morning';

  @override
  String get onboarding_remNoon => 'Midday';

  @override
  String get onboarding_remNight => 'Late evening';

  @override
  String onboarding_remHint(String time) {
    return 'suggested reminder at $time';
  }

  @override
  String get onboarding_quizResultTitle => 'your first journey.';

  @override
  String onboarding_quizRemind(String time) {
    return 'Remind $time';
  }

  @override
  String get onboarding_quizContinue => 'Continue';

  @override
  String get onboarding_quizStart => 'Let us start';

  @override
  String get onboarding_splashTagline1 => 'snap one.';

  @override
  String get onboarding_splashTagline2 => 'keep a streak.';

  @override
  String get onboarding_splashTagline3 => 'go together.';

  @override
  String get onboarding_splashStart => 'Start';

  @override
  String get onboarding_splashOpening => 'Opening';

  @override
  String get onboarding_resultCouple => 'the two of us.';

  @override
  String get onboarding_permissionClose => 'Close';

  @override
  String onboarding_nudgeBody(String time) {
    return 'Turn on reminders and we will nudge you at $time. It may run late on some phones.';
  }
}
