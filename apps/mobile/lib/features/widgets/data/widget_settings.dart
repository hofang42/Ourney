import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../journeys/data/journeys_providers.dart' show journeysListProvider;
import '../domain/widget_privacy.dart';
import 'widget_bridge_gateway.dart';

/// Shared-preferences keys owned by the widgets feature (§7.2).
///
/// All keys in [accountKeys] belong to the signed-in account and are wiped by
/// `resetAccountLocalState` on sign-out / account switch / account deletion.
abstract final class WidgetPrefs {
  /// `'smart'` (default) | `'blurred'` | `'off'` | `'clear'`.
  static const photoMode = 'widgets.photoMode';

  /// Explicit `bool` override for Lock Screen journey title redaction.
  /// When absent (`null`), defaults to `true` if the user has any weight-loss
  /// journey, else `false` (§7.1).
  static const redactLockScreenTitles = 'widgets.redactLockScreenTitles';

  /// Master switch for the evening Check-In Window Live Activity (iOS) /
  /// Ongoing Live Update (Android) (default `true`, §7.2).
  static const liveActivityEnabled = 'widgets.liveActivityEnabled';

  /// Optional journey id pinned as the primary default journey on widgets.
  static const defaultJourneyId = 'widgets.defaultJourneyId';

  /// Last `windowKey` (`YYYY-MM-DD:<journeyId>`) dismissed by the user so
  /// reopening the app later that evening does not re-spawn the Live Activity (§6.2).
  static const dismissedWindowKey = 'widgets.dismissedWindowKey';

  static const List<String> accountKeys = [
    photoMode,
    redactLockScreenTitles,
    liveActivityEnabled,
    defaultJourneyId,
    dismissedWindowKey,
  ];
}

class WidgetPhotoModeController extends Notifier<WidgetPhotoMode> {
  @override
  WidgetPhotoMode build() {
    final raw = ref
        .watch(sharedPreferencesProvider)
        .getString(WidgetPrefs.photoMode);
    return WidgetPhotoMode.fromWire(raw);
  }

  Future<void> set(WidgetPhotoMode mode) async {
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(WidgetPrefs.photoMode, mode.wireName);
  }
}

final widgetPhotoModeProvider =
    NotifierProvider<WidgetPhotoModeController, WidgetPhotoMode>(
      WidgetPhotoModeController.new,
    );

class RedactLockScreenTitlesPrefController extends Notifier<bool?> {
  @override
  bool? build() => ref
      .watch(sharedPreferencesProvider)
      .getBool(WidgetPrefs.redactLockScreenTitles);

  Future<void> set(bool value) async {
    state = value;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(WidgetPrefs.redactLockScreenTitles, value);
  }
}

final redactLockScreenTitlesPrefProvider =
    NotifierProvider<RedactLockScreenTitlesPrefController, bool?>(
      RedactLockScreenTitlesPrefController.new,
    );

/// Effective Lock Screen title redaction flag (§7.1): uses the user's explicit
/// toggle when set, or defaults to `true` when any active journey is a
/// weight-loss / sensitive-metric journey.
final redactLockScreenTitlesProvider = Provider<bool>((ref) {
  final explicitPref = ref.watch(redactLockScreenTitlesPrefProvider);
  if (explicitPref != null) return explicitPref;
  List<Journey> journeys = const [];
  try {
    journeys = ref.watch(journeysListProvider).asData?.value ?? const [];
  } on Object {
    journeys = const [];
  }
  final active = journeys.where((j) => j.status == JourneyStatus.active);
  return WidgetPrivacyPolicy.resolveRedactLockScreenTitles(
    explicitPreference: null,
    activeJourneys: active,
  );
});

class LiveActivityEnabledController extends Notifier<bool> {
  @override
  bool build() =>
      ref
          .watch(sharedPreferencesProvider)
          .getBool(WidgetPrefs.liveActivityEnabled) ??
      true;

  Future<void> set({required bool enabled}) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(WidgetPrefs.liveActivityEnabled, enabled);
  }
}

final liveActivityEnabledProvider =
    NotifierProvider<LiveActivityEnabledController, bool>(
      LiveActivityEnabledController.new,
    );

class DefaultWidgetJourneyIdController extends Notifier<String?> {
  @override
  String? build() {
    final raw = ref
        .watch(sharedPreferencesProvider)
        .getString(WidgetPrefs.defaultJourneyId);
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  Future<void> set(String? journeyId) async {
    final normalized = (journeyId == null || journeyId.isEmpty)
        ? null
        : journeyId;
    state = normalized;
    final prefs = ref.read(sharedPreferencesProvider);
    if (normalized == null) {
      await prefs.remove(WidgetPrefs.defaultJourneyId);
    } else {
      await prefs.setString(WidgetPrefs.defaultJourneyId, normalized);
    }
  }
}

final defaultWidgetJourneyIdProvider =
    NotifierProvider<DefaultWidgetJourneyIdController, String?>(
      DefaultWidgetJourneyIdController.new,
    );

class DismissedLiveWindowKeyController extends Notifier<String?> {
  @override
  String? build() {
    final raw = ref
        .watch(sharedPreferencesProvider)
        .getString(WidgetPrefs.dismissedWindowKey);
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  Future<void> set(String? windowKey) async {
    final normalized = (windowKey == null || windowKey.isEmpty)
        ? null
        : windowKey;
    state = normalized;
    final prefs = ref.read(sharedPreferencesProvider);
    if (normalized == null) {
      await prefs.remove(WidgetPrefs.dismissedWindowKey);
    } else {
      await prefs.setString(WidgetPrefs.dismissedWindowKey, normalized);
    }
  }
}

final dismissedLiveWindowKeyProvider =
    NotifierProvider<DismissedLiveWindowKeyController, String?>(
      DismissedLiveWindowKeyController.new,
    );

/// Platform capabilities for widgets, Live Activities, and App Group sync.
final widgetCapabilitiesProvider =
    FutureProvider.autoDispose<WidgetCapabilities>(
      (ref) => ref.watch(widgetBridgeGatewayProvider).getCapabilities(),
      retry: (_, _) => null,
    );
