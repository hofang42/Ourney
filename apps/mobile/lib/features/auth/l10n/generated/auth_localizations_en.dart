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
  String get auth_otpHelperEmail => 'No email? Check Spam or Promotions.';

  @override
  String get auth_title => 'get into ourney.';

  @override
  String get auth_subtitle =>
      'Enter your email and we\'ll send a 6-digit code. New here? We\'ll set up your account.';

  @override
  String get auth_emailLabel => 'Email';

  @override
  String get auth_emailHint => 'name@email.com';

  @override
  String get auth_emailInvalid =>
      'That email doesn\'t look right. Example: name@gmail.com';

  @override
  String get auth_sendCode => 'Send code';

  @override
  String get auth_sending => 'Sending…';

  @override
  String get auth_codeLabel => '6-digit code';

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
  String get auth_codeResent => 'New code sent. The old code no longer works.';

  @override
  String get auth_changeEmail => 'Change email';

  @override
  String get auth_errorWrongCode =>
      'That code is wrong or expired. Check it and try again.';

  @override
  String get auth_errorRateLimited =>
      'Too many tries. Wait a moment and try again.';

  @override
  String get auth_errorOffline => 'You\'re offline. Reconnect and try again.';

  @override
  String get auth_errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get auth_terms => 'Terms of Use';

  @override
  String get auth_privacy => 'Privacy Policy.';

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
      'Enter your number and we\'ll text a 6-digit code. New here? We\'ll set up your account.';

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
  String get auth_usePassword => 'Sign in with password';

  @override
  String get auth_useCode => 'Use a code instead';

  @override
  String get auth_forgot => 'Forgot password?';

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
  String get auth_errorWrongPassword =>
      'Wrong password. Try again or sign in with a code.';

  @override
  String get auth_errorSendFailed =>
      'Couldn\'t send the code. Try again in a few minutes.';

  @override
  String get auth_codeSentPrefix => 'We sent a 6-digit code to';

  @override
  String get auth_offlineBanner =>
      'You\'re offline, so the code wasn\'t sent. Turn on your connection and try again.';

  @override
  String get auth_retry => 'Try again';

  @override
  String get auth_success => 'All done. Welcome.';

  @override
  String get auth_legalIntro => 'By continuing, you agree to Ourney\'s';

  @override
  String get auth_legalAnd => '(zero tolerance for objectionable content) and';

  @override
  String get auth_back => 'Back';

  @override
  String get auth_methodLabel => 'How to get your code';

  @override
  String get auth_passwordTitle => 'sign in with password.';

  @override
  String get auth_otpHelperSms =>
      'No text yet? Wait a moment, then tap Resend code.';

  @override
  String get auth_errorPhoneUnavailable =>
      'SMS sign-in isn\'t available right now. Please use email.';

  @override
  String get auth_errorSmsFailed =>
      'Couldn\'t send the SMS. Check the number and try again in a few minutes.';

  @override
  String get auth_errorSamePassword =>
      'New password must be different from your current password.';
}
