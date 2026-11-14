// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AuthL10nEn extends AuthL10n {
  AuthL10nEn([String locale = 'en']) : super(locale);

  @override
  String get auth_codeTitle => 'enter the code.';

  @override
  String get auth_otpHelper =>
      'Can\'t find the email? Check spam or promotions.';

  @override
  String get auth_title => 'sign in.';

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
  String get auth_errorWrongCode =>
      'That code is wrong or expired. Check it or ask for a new one.';

  @override
  String get auth_errorRateLimited =>
      'Too many tries. Wait a moment and try again.';

  @override
  String get auth_errorOffline => 'You\'re offline. Reconnect and try again.';

  @override
  String get auth_errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get auth_eyebrow => 'OURNEY';

  @override
  String get auth_eyebrowCheck => 'CHECK YOUR EMAIL';

  @override
  String get auth_terms => 'Terms';

  @override
  String get auth_privacy => 'Privacy';

  @override
  String auth_digitSemantics(int n) {
    return 'Digit $n of 6';
  }

  @override
  String get auth_tabEmail => 'Email';

  @override
  String get auth_tabPhone => 'Phone';

  @override
  String get auth_phoneLabel => 'Phone number';

  @override
  String get auth_phoneHint => '912 345 678';

  @override
  String get auth_phonePrefix => '+84';

  @override
  String get auth_phoneInvalid =>
      'A Vietnamese number has 9–10 digits after 0 or +84.';

  @override
  String get auth_phoneSubtitle =>
      'Enter your phone number and Ourney texts you a 6-digit code.';

  @override
  String get auth_sendSms => 'Text me a code';

  @override
  String auth_smsSentTo(String phone) {
    return 'We texted a 6-digit code to $phone.';
  }

  @override
  String get auth_changePhone => 'Change phone number';

  @override
  String get auth_passwordLabel => 'Password';

  @override
  String get auth_newPasswordLabel => 'New password';

  @override
  String get auth_passwordShort => 'Use at least 8 characters.';

  @override
  String get auth_showPassword => 'Show password';

  @override
  String get auth_hidePassword => 'Hide password';

  @override
  String get auth_signIn => 'Sign in';

  @override
  String get auth_usePassword => 'Use a password';

  @override
  String get auth_useCode => 'Use a sign-in code';

  @override
  String get auth_forgot => 'Forgot password?';

  @override
  String get auth_createAccount => 'Create an account with a password';

  @override
  String get auth_haveAccount => 'Have an account? Sign in';

  @override
  String get auth_signUpTitle => 'create account.';

  @override
  String get auth_signUpSubtitle =>
      'Use your email and a password. We may email you a code to confirm.';

  @override
  String get auth_signUpButton => 'Create account';

  @override
  String get auth_resetTitle => 'reset password.';

  @override
  String get auth_resetSubtitle =>
      'Enter your email and Ourney sends a 6-digit code to set a new password.';

  @override
  String get auth_resetConfirm => 'Set password';

  @override
  String get auth_backToSignIn => 'Back to sign in';

  @override
  String get auth_errorWrongPassword => 'Wrong email or password.';

  @override
  String get auth_errorEmailTaken =>
      'That email already has an account. Sign in instead.';
}
