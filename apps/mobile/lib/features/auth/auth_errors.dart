import 'package:ourney_core/ourney_core.dart';

import 'l10n/generated/auth_localizations.dart';

/// Which auth call failed (the same code reads differently per step).
enum AuthStep { sendOtp, verifyOtp }

/// Maps an error thrown by `AuthRepository.sendOtp` / `verifyOtp` to a
/// localized message. Codes come from [OurneyErrorCode] (the data layer maps
/// Supabase Auth errors onto them; anything else is generic).
String authErrorMessage(AuthL10n l10n, Object error, AuthStep step) {
  final code = error is OurneyException ? error.error : OurneyErrorCode.unknown;
  return switch (code) {
    OurneyErrorCode.rateLimited => l10n.auth_errorRateLimited,
    OurneyErrorCode.offline => l10n.auth_errorOffline,
    OurneyErrorCode.invalid when step == AuthStep.sendOtp =>
      l10n.auth_emailInvalid,
    OurneyErrorCode.invalid ||
    OurneyErrorCode.notFound ||
    OurneyErrorCode.forbidden ||
    OurneyErrorCode.unauthenticated when step == AuthStep.verifyOtp =>
      l10n.auth_errorWrongCode,
    _ => l10n.auth_errorGeneric,
  };
}
