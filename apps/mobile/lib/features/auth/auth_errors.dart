import 'package:ourney_core/ourney_core.dart';

import 'l10n/generated/auth_localizations.dart';

/// Which auth call failed (the same code reads differently per step).
enum AuthStep {
  sendOtp,
  verifyOtp,
  sendPhone,
  verifyPhone,
  passwordSignIn,
  resetSend,
  resetConfirm,
}

/// Maps an error thrown by an `AuthRepository` call to a localized message.
/// Codes come from [OurneyErrorCode] (the data layer maps Supabase Auth errors
/// onto them; anything else is generic).
String authErrorMessage(AuthL10n l10n, Object error, AuthStep step) {
  final code = error is OurneyException ? error.error : OurneyErrorCode.unknown;
  final detail = error is OurneyException ? (error.detail ?? '') : '';
  if (code == OurneyErrorCode.rateLimited) return l10n.auth_errorRateLimited;
  if (code == OurneyErrorCode.offline) return l10n.auth_errorOffline;
  if (step == AuthStep.resetConfirm) {
    if (detail.contains('weak_password')) return l10n.auth_passwordShort;
    if (detail.contains('same_password')) return l10n.auth_errorSamePassword;
  }
  final badInput =
      code == OurneyErrorCode.invalid ||
      code == OurneyErrorCode.notFound ||
      code == OurneyErrorCode.unauthenticated;
  return switch (step) {
    AuthStep.sendOtp || AuthStep.resetSend =>
      code == OurneyErrorCode.invalid
          ? l10n.auth_emailInvalid
          : l10n.auth_errorSendFailed,
    AuthStep.sendPhone => switch (code) {
      OurneyErrorCode.unavailable => l10n.auth_errorPhoneUnavailable,
      OurneyErrorCode.internal => l10n.auth_errorSmsFailed,
      OurneyErrorCode.invalid => l10n.auth_phoneInvalid,
      _ => l10n.auth_errorSendFailed,
    },
    AuthStep.verifyOtp || AuthStep.verifyPhone || AuthStep.resetConfirm =>
      badInput ? l10n.auth_errorWrongCode : l10n.auth_errorGeneric,
    AuthStep.passwordSignIn =>
      badInput ? l10n.auth_errorWrongPassword : l10n.auth_errorGeneric,
  };
}
