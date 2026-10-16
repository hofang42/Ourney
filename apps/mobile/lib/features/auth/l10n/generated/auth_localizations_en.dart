// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AuthL10nEn extends AuthL10n {
  AuthL10nEn([String locale = 'en']) : super(locale);

  @override
  String get auth_title => 'Sign in';

  @override
  String get auth_subtitle =>
      'Enter your email and Ourney sends you a 6-digit code. No password needed.';

  @override
  String get auth_emailLabel => 'Email';

  @override
  String get auth_emailHint => 'you@example.com';

  @override
  String get auth_emailInvalid => 'That email doesn\'t look right.';

  @override
  String get auth_sendCode => 'Send code';

  @override
  String get auth_sending => 'Sending…';

  @override
  String get auth_codeTitle => 'Enter the code';

  @override
  String auth_codeSentTo(String email) {
    return 'We sent a 6-digit code to $email.';
  }

  @override
  String get auth_codeLabel => '6-digit code';

  @override
  String get auth_codeInvalidFormat => 'The code is exactly 6 digits.';

  @override
  String get auth_verify => 'Confirm';

  @override
  String get auth_verifying => 'Checking…';

  @override
  String get auth_resend => 'Resend code';

  @override
  String auth_resendIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get auth_codeResent => 'New code sent. Check your inbox.';

  @override
  String get auth_changeEmail => 'Change email';

  @override
  String get auth_termsNote =>
      'By continuing you agree to Ourney\'s terms of use and privacy policy.';

  @override
  String get auth_termsLink => 'Read the terms';

  @override
  String get auth_errorWrongCode =>
      'That code is wrong or expired. Check it or ask for a new one.';

  @override
  String get auth_errorRateLimited =>
      'Too many tries. Wait a moment and try again.';

  @override
  String get auth_errorOffline => 'You\'re offline. Reconnect and try again.';

  @override
  String get auth_errorGeneric => 'Something went wrong. Please try again.';
}
