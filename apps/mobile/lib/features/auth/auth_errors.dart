import 'package:ourney_core/ourney_core.dart';

import 'l10n/generated/auth_localizations.dart';

/// Which auth call failed (the same code reads differently per step).
enum AuthStep {
  sendOtp,
  verifyOtp,
  sendPhone,
  verifyPhone,
  passwordSignIn,
  signUp,
  confirmSignUp,
  resetSend,
  resetConfirm,
}

/// Maps an error thrown by an `AuthRepository` call to a localized message.
/// Codes come from [OurneyErrorCode] (the data layer maps Supabase Auth errors
/// onto them; anything else is generic).
String authErrorMessage(AuthL10n l10n, Object error, AuthStep step) {
  final code = error is OurneyException ? error.error : OurneyErrorCode.unknown;
  if (code == OurneyErrorCode.rateLimited) return l10n.auth_errorRateLimited;
  if (code == OurneyErrorCode.offline) return l10n.auth_errorOffline;
  final badInput =
      code == OurneyErrorCode.invalid ||
      code == OurneyErrorCode.notFound ||
      code == OurneyErrorCode.forbidden ||
      code == OurneyErrorCode.unauthenticated;
  return switch (step) {
    AuthStep.sendOtp || AuthStep.resetSend =>
      code == OurneyErrorCode.invalid
          ? l10n.auth_emailInvalid
          : l10n.auth_errorSendFailed,
    AuthStep.sendPhone =>
      code == OurneyErrorCode.invalid
          ? l10n.auth_phoneInvalid
          : l10n.auth_errorSendFailed,
    AuthStep.verifyOtp ||
    AuthStep.verifyPhone ||
    AuthStep.confirmSignUp ||
    AuthStep.resetConfirm =>
      badInput ? l10n.auth_errorWrongCode : l10n.auth_errorGeneric,
    AuthStep.passwordSignIn =>
      badInput ? l10n.auth_errorWrongPassword : l10n.auth_errorGeneric,
    AuthStep.signUp =>
      code == OurneyErrorCode.invalid
          ? l10n.auth_errorEmailTaken
          : l10n.auth_errorGeneric,
  };
}
