import 'dart:async';

import 'package:ourney_core/ourney_core.dart';

import 'l10n/generated/profile_localizations.dart';

enum UsernameAvailability { unconfirmed, available, unavailable, taken }

class UsernameAvailabilityCheck {
  UsernameAvailability status = UsernameAvailability.unconfirmed;
  Timer? _debounce;
  int _revision = 0;

  bool get rejected =>
      status == UsernameAvailability.unavailable ||
      status == UsernameAvailability.taken;

  void onChanged(
    String value, {
    required String? currentUsername,
    required Future<bool> Function(String) lookup,
    required void Function() onResult,
  }) {
    cancel();
    status = UsernameAvailability.unconfirmed;
    if (value == currentUsername || validateUsername(value) != null) return;
    final revision = _revision;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final bool available;
      try {
        available = await lookup(value);
      } on Object {
        // Failed checks leave the username unconfirmed so save can still try.
        return;
      }
      if (revision != _revision) return;
      status = available
          ? UsernameAvailability.available
          : UsernameAvailability.unavailable;
      onResult();
    });
  }

  void cancel() {
    _debounce?.cancel();
    _debounce = null;
    _revision++;
  }

  String? errorFor(ProfileL10n l10n, String value, {required bool submitted}) {
    switch (status) {
      case UsernameAvailability.taken:
        return l10n.profile_usernameTaken;
      case UsernameAvailability.unavailable:
        return l10n.profile_usernameUnavailable;
      default:
        break;
    }
    if (!submitted && value.isEmpty) return null;
    return switch (validateUsername(value)) {
      UsernameError.tooShort => l10n.profile_usernameTooShort(usernameMin),
      UsernameError.tooLong => l10n.profile_usernameTooLong(usernameMax),
      UsernameError.invalidChars => l10n.profile_usernameInvalidChars,
      null => null,
    };
  }

  bool isAvailable(String value, {required String? currentUsername}) =>
      !rejected &&
      (value == currentUsername || status == UsernameAvailability.available);
}
