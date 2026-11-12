import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Language picked in-app (onboarding language chip). `null` follows the
/// device locale (Vietnamese by default, see `ourneySupportedLocales`).
final localeOverrideProvider = NotifierProvider<LocaleOverride, Locale?>(
  LocaleOverride.new,
);

class LocaleOverride extends Notifier<Locale?> {
  static const prefsKey = 'app.localeOverride';

  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider).getString(prefsKey);
    return code == null ? null : Locale(code);
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await ref
        .read(sharedPreferencesProvider)
        .setString(prefsKey, locale.languageCode);
  }
}
