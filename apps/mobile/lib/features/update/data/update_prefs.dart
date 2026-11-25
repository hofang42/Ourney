import 'dart:convert';

import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef CachedUpdatePolicy = ({AppUpdateManifest manifest, DateTime checkedAt});

/// Update history belongs to this installation across account switches.
final class UpdatePrefs {
  const UpdatePrefs(this._prefs);

  static const _cachedPolicy = 'update.cachedPolicy';
  static const _firstSeen = 'update.firstSeenAtMs';
  static const _snooze = 'update.snooze';
  static const _skippedVersion = 'update.skippedVersion';
  static const _hubDismissedVersion = 'update.hubDismissedVersion';
  static const _lastSeenVersion = 'update.lastSeenInstalledVersion';

  final SharedPreferencesWithCache _prefs;

  CachedUpdatePolicy? get cachedPolicy {
    if (_readJson(_cachedPolicy) case {
      'manifest': final json,
      'checkedAt': final int ms,
    }) {
      final manifest = AppUpdateManifest.tryFromJson(json);
      final checkedAt = _timestamp(ms);
      if (manifest != null && checkedAt != null) {
        return (manifest: manifest, checkedAt: checkedAt);
      }
    }
    return null;
  }

  Future<void> savePolicy(CachedUpdatePolicy policy) => _prefs.setString(
    _cachedPolicy,
    jsonEncode({
      'manifest': policy.manifest.toJson(),
      'checkedAt': policy.checkedAt.millisecondsSinceEpoch,
    }),
  );

  DateTime? get firstSeenAt => _timestamp(_prefs.get(_firstSeen));

  Future<void> recordFirstSeen(DateTime now) =>
      _prefs.setInt(_firstSeen, now.millisecondsSinceEpoch);

  UpdateSnooze? get snooze {
    if (_readJson(_snooze) case {
      'version': final String raw,
      'count': final int count,
      'until': final until,
    }) {
      final version = SemVer.tryParse(raw);
      if (version != null && count >= 1 && count <= 3) {
        return UpdateSnooze(
          version: version,
          count: count,
          until: _timestamp(until),
        );
      }
    }
    return null;
  }

  Future<void> saveSnooze(UpdateSnooze snooze) => _prefs.setString(
    _snooze,
    jsonEncode({
      'version': snooze.version.precedence,
      'count': snooze.count,
      'until': snooze.until?.millisecondsSinceEpoch,
    }),
  );

  SemVer? get skippedVersion => _version(_skippedVersion);
  SemVer? get hubDismissedVersion => _version(_hubDismissedVersion);
  SemVer? get lastSeenInstalledVersion => _version(_lastSeenVersion);

  Future<void> skipVersion(SemVer version) =>
      _prefs.setString(_skippedVersion, version.precedence);

  Future<void> dismissHubBanner(SemVer version) =>
      _prefs.setString(_hubDismissedVersion, version.precedence);

  Future<void> recordInstalledVersion(SemVer version) =>
      _prefs.setString(_lastSeenVersion, version.precedence);

  SemVer? _version(String key) {
    final value = _prefs.get(key);
    return value is String ? SemVer.tryParse(value) : null;
  }

  Object? _readJson(String key) {
    final raw = _prefs.get(key);
    if (raw is! String) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static DateTime? _timestamp(Object? value) {
    if (value is! int || value < 0 || value > 8640000000000000) return null;
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
}
