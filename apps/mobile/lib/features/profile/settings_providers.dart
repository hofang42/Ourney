import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// One of the 8 Ourney V2 app launcher icons (`default` + 7 alternates).
@immutable
class AppIconVariant {
  const AppIconVariant({
    required this.id,
    required this.iosIconName,
    required this.androidAlias,
    required this.previewAsset,
  });

  final String id;

  /// Name passed to `UIApplication.shared.setAlternateIconName` on iOS
  /// (`null` resets to the primary `AppIcon`).
  final String? iosIconName;

  /// `<activity-alias android:name="...">` suffix in `AndroidManifest.xml`.
  final String androidAlias;

  /// Bundled `180x180` preview PNG under `assets/app_icons/`.
  final String previewAsset;
}

/// Switches the OS home-screen launcher icon on iOS and Android via the
/// native `ourney/app_icon` [MethodChannel].
abstract interface class AppIconSwitcher {
  /// Whether runtime launcher icon switching is available on this platform.
  bool get supported;

  /// Applies [variant] on the host OS. Returns `true` when applied.
  Future<bool> setIcon(AppIconVariant variant);
}

class PlatformAppIconSwitcher implements AppIconSwitcher {
  const PlatformAppIconSwitcher();

  static const MethodChannel channel = MethodChannel('ourney/app_icon');

  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<bool> setIcon(AppIconVariant variant) async {
    if (!supported) return false;
    try {
      return await channel.invokeMethod<bool>(
            'setAlternateIcon',
            <String, Object?>{
              'id': variant.id,
              'iosIconName': variant.iosIconName,
              'androidAlias': variant.androidAlias,
            },
          ) ??
          false;
    } on Object {
      return false;
    }
  }
}

final appIconSwitcherProvider = Provider<AppIconSwitcher>(
  (ref) => const PlatformAppIconSwitcher(),
);

/// Selected app icon id (persisted in `SharedPreferences` under
/// [AppIconController.prefsKey] and applied via [appIconSwitcherProvider]).
final appIconProvider = NotifierProvider<AppIconController, String>(
  AppIconController.new,
);

class AppIconController extends Notifier<String> {
  static const prefsKey = 'app.appIcon';

  static const List<AppIconVariant> variants = [
    AppIconVariant(
      id: 'default',
      iosIconName: null,
      androidAlias: '.IconDefault',
      previewAsset: 'assets/app_icons/default.png',
    ),
    AppIconVariant(
      id: 'yellow',
      iosIconName: 'AppIcon-Yellow',
      androidAlias: '.IconYellow',
      previewAsset: 'assets/app_icons/yellow.png',
    ),
    AppIconVariant(
      id: 'green',
      iosIconName: 'AppIcon-Green',
      androidAlias: '.IconGreen',
      previewAsset: 'assets/app_icons/green.png',
    ),
    AppIconVariant(
      id: 'coral',
      iosIconName: 'AppIcon-Coral',
      androidAlias: '.IconCoral',
      previewAsset: 'assets/app_icons/coral.png',
    ),
    AppIconVariant(
      id: 'violet',
      iosIconName: 'AppIcon-Violet',
      androidAlias: '.IconViolet',
      previewAsset: 'assets/app_icons/violet.png',
    ),
    AppIconVariant(
      id: 'sky',
      iosIconName: 'AppIcon-Sky',
      androidAlias: '.IconSky',
      previewAsset: 'assets/app_icons/sky.png',
    ),
    AppIconVariant(
      id: 'dark',
      iosIconName: 'AppIcon-Dark',
      androidAlias: '.IconDark',
      previewAsset: 'assets/app_icons/dark.png',
    ),
    AppIconVariant(
      id: 'minimal',
      iosIconName: 'AppIcon-Minimal',
      androidAlias: '.IconMinimal',
      previewAsset: 'assets/app_icons/minimal.png',
    ),
  ];

  static const List<String> ids = [
    'default',
    'yellow',
    'green',
    'coral',
    'violet',
    'sky',
    'dark',
    'minimal',
  ];

  static AppIconVariant? variantById(String id) {
    for (final v in variants) {
      if (v.id == id) return v;
    }
    return null;
  }

  @override
  String build() {
    final v = ref.watch(sharedPreferencesProvider).getString(prefsKey);
    return ids.contains(v) ? v! : 'default';
  }

  Future<bool> set(String id) async {
    final variant = variantById(id);
    if (variant == null) return false;
    state = id;
    await ref.read(sharedPreferencesProvider).setString(prefsKey, id);
    return ref.read(appIconSwitcherProvider).setIcon(variant);
  }
}
