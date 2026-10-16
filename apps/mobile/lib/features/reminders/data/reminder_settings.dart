import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/reminder_plan.dart';

/// Default time proposed when a reminder is first turned on.
const ReminderTime kDefaultReminderTime = ReminderTime(20, 0);

/// Shared-preferences keys of the reminders feature.
abstract final class ReminderPrefs {
  /// `reminders.<journeyId>` -> JSON `{"on": bool, "time": "HH:mm"}`.
  static const journeyPrefix = 'reminders.';

  static String journey(String journeyId) => '$journeyPrefix$journeyId';

  /// Global switch for the 21:00 "streak about to break" alert (FR-G2).
  /// Not a journey id: journey ids are UUIDs, never this literal.
  static const streakAlerts = 'reminders.streakAlerts';

  /// Set once the OS permission prompt has been shown (FR-A3: we ask only
  /// when the user turns on the first reminder).
  static const permissionAsked = 'reminders.permissionAsked';

  static const _reserved = {streakAlerts, permissionAsked};

  /// Journey id encoded in [key], or null if [key] is not a journey setting.
  static String? journeyIdOf(String key) {
    if (!key.startsWith(journeyPrefix) || _reserved.contains(key)) return null;
    final id = key.substring(journeyPrefix.length);
    return id.isEmpty ? null : id;
  }
}

/// One journey's reminder: on/off plus the time (kept while off so turning
/// it back on restores the previous choice).
class ReminderSetting {
  const ReminderSetting({required this.enabled, required this.time});

  static const off = ReminderSetting(
    enabled: false,
    time: kDefaultReminderTime,
  );

  /// Lenient decode: anything malformed reads as [off].
  static ReminderSetting decode(String? raw) {
    if (raw == null) return off;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, Object?>) return off;
      final on = map['on'];
      final time = ReminderTime.tryParse(map['time'] as String?);
      return ReminderSetting(
        enabled: on is bool && on,
        time: time ?? kDefaultReminderTime,
      );
    } on Object {
      return off;
    }
  }

  final bool enabled;
  final ReminderTime time;

  /// The time to schedule, or null when off.
  ReminderTime? get activeTime => enabled ? time : null;

  String encode() => jsonEncode({'on': enabled, 'time': time.toString()});

  ReminderSetting copyWith({bool? enabled, ReminderTime? time}) =>
      ReminderSetting(
        enabled: enabled ?? this.enabled,
        time: time ?? this.time,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSetting &&
      other.enabled == enabled &&
      other.time == time;

  @override
  int get hashCode => Object.hash(enabled, time);
}

/// Every stored per-journey reminder, keyed by journey id.
class ReminderSettingsController
    extends Notifier<Map<String, ReminderSetting>> {
  @override
  Map<String, ReminderSetting> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return {
      for (final key in prefs.keys)
        ?ReminderPrefs.journeyIdOf(key): ReminderSetting.decode(
          prefs.getString(key),
        ),
    };
  }

  ReminderSetting of(String journeyId) =>
      state[journeyId] ?? ReminderSetting.off;

  Future<void> save(String journeyId, ReminderSetting setting) async {
    state = {...state, journeyId: setting};
    await ref
        .read(sharedPreferencesProvider)
        .setString(ReminderPrefs.journey(journeyId), setting.encode());
  }

  /// Drops settings of journeys that no longer exist.
  Future<void> forget(String journeyId) async {
    if (!state.containsKey(journeyId)) return;
    state = {...state}..remove(journeyId);
    await ref
        .read(sharedPreferencesProvider)
        .remove(ReminderPrefs.journey(journeyId));
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsController, Map<String, ReminderSetting>>(
      ReminderSettingsController.new,
    );

/// FR-G2 switch (default on).
class StreakAlertsController extends Notifier<bool> {
  @override
  bool build() =>
      ref
          .watch(sharedPreferencesProvider)
          .getBool(ReminderPrefs.streakAlerts) ??
      true;

  Future<void> set({required bool enabled}) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(ReminderPrefs.streakAlerts, enabled);
  }
}

final streakAlertsEnabledProvider =
    NotifierProvider<StreakAlertsController, bool>(StreakAlertsController.new);
