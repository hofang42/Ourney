import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Theme preference (Figma `themePreference`: light / dark / system).
/// Persisted; `app.dart` reads it for `MaterialApp.themeMode`.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  static const prefsKey = 'app.themeMode';

  @override
  ThemeMode build() {
    final v = ref.watch(sharedPreferencesProvider).getString(prefsKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == v,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(prefsKey, mode.name);
  }
}

/// Global share-privacy switch persisted in prefs (Figma `hideWeightOnShare`,
/// `blurPhotosOnShare`).
class PrefSwitch extends Notifier<bool> {
  PrefSwitch(this.key);

  final String key;

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(key) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(key, value);
  }
}

/// Per-account (dropped on sign-out, see `accountPrefsKeys`).
abstract final class SharePrivacyPrefs {
  static const hideWeight = 'privacy.hideWeightOnShare';
  static const blurPhotos = 'privacy.blurPhotosOnShare';

  /// Failed membership pushes to heal (see share_privacy_sync.dart).
  static const pendingHeal = 'privacy.pendingHeal';
}

final hideWeightOnShareProvider = NotifierProvider<PrefSwitch, bool>(
  () => PrefSwitch(SharePrivacyPrefs.hideWeight),
);
final blurPhotosOnShareProvider = NotifierProvider<PrefSwitch, bool>(
  () => PrefSwitch(SharePrivacyPrefs.blurPhotos),
);

/// Selected app icon id (Figma `appIcon`). No platform plugin switches the
/// launcher icon yet (docs/figma-parity.md D); the choice is only stored.
final appIconProvider = NotifierProvider<AppIconController, String>(
  AppIconController.new,
);

class AppIconController extends Notifier<String> {
  static const prefsKey = 'app.appIcon';
  static const ids = [
    'default',
    'quiet',
    'squad',
    'memory',
    'couple',
    'flexer',
    'minimal',
  ];

  @override
  String build() {
    final v = ref.watch(sharedPreferencesProvider).getString(prefsKey);
    return ids.contains(v) ? v! : 'default';
  }

  Future<void> set(String id) async {
    state = id;
    await ref.read(sharedPreferencesProvider).setString(prefsKey, id);
  }
}
