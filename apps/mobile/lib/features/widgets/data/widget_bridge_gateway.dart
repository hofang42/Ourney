import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One thumbnail entry sent across `MethodChannel('ourney/widgets')` in
/// `syncSnapshot` (§4.4).
@immutable
class WidgetThumbPayload {
  const WidgetThumbPayload({
    required this.id,
    required this.sourcePath,
    required this.maxSide,
    required this.blur,
  });

  /// `<sha256_16>.jpg`.
  final String id;

  /// Absolute local file path on disk for native downsampling/copying.
  final String sourcePath;

  /// Maximum short side in pixels (`320` for hero, `160` for grid/avatar).
  final int maxSide;

  /// Whether the image is blurred (`true` when privacy policy requires blur).
  final bool blur;

  Map<String, Object?> toJson() => {
    'id': id,
    'sourcePath': sourcePath,
    'maxSide': maxSide,
    'blur': blur,
  };

  @override
  bool operator ==(Object other) =>
      other is WidgetThumbPayload &&
      other.id == id &&
      other.sourcePath == sourcePath &&
      other.maxSide == maxSide &&
      other.blur == blur;

  @override
  int get hashCode => Object.hash(id, sourcePath, maxSide, blur);
}

/// Platform capabilities returned by `getCapabilities` on
/// `MethodChannel('ourney/widgets')` (§4.4).
@immutable
class WidgetCapabilities {
  const WidgetCapabilities({
    required this.widgets,
    required this.liveActivity,
    required this.promotedLiveUpdates,
    required this.appGroup,
  });

  static const unsupported = WidgetCapabilities(
    widgets: false,
    liveActivity: false,
    promotedLiveUpdates: false,
    appGroup: false,
  );

  factory WidgetCapabilities.fromMap(Map<Object?, Object?>? raw) {
    if (raw == null) return unsupported;
    return WidgetCapabilities(
      widgets: raw['widgets'] == true,
      liveActivity: raw['liveActivity'] == true,
      promotedLiveUpdates: raw['promotedLiveUpdates'] == true,
      appGroup: (raw['appGroupAvailable'] ?? raw['appGroup']) == true,
    );
  }

  final bool widgets;
  final bool liveActivity;
  final bool promotedLiveUpdates;
  final bool appGroup;

  @override
  bool operator ==(Object other) =>
      other is WidgetCapabilities &&
      other.widgets == widgets &&
      other.liveActivity == liveActivity &&
      other.promotedLiveUpdates == promotedLiveUpdates &&
      other.appGroup == appGroup;

  @override
  int get hashCode =>
      Object.hash(widgets, liveActivity, promotedLiveUpdates, appGroup);
}

/// Injectable port for the native `MethodChannel('ourney/widgets')` bridge (§4.4).
abstract interface class WidgetBridgeGateway {
  /// Atomically writes `snapshot_v1.json`, syncs missing content-addressed
  /// [thumbs], prunes orphan files, and reloads WidgetKit / Glance timelines.
  Future<bool> syncSnapshot({
    required String snapshotJson,
    required List<WidgetThumbPayload> thumbs,
  });

  /// Starts, updates, or ends (`payload == null`) the Check-In Window Live
  /// Activity (iOS 16.2+ `ActivityKit`) / Ongoing Live Update (Android 26+).
  Future<bool> syncLiveActivity(Map<String, Object?>? payload);

  /// Deletes `snapshot_v1.json`, `state.json`, and all `thumbs/*`, ends all
  /// Live Activities / notification `42000`, and reloads widgets to empty state.
  Future<bool> clearAll();

  /// Reads any `state.json` mutations written by interactive widget intents or
  /// notification receivers while backgrounded (e.g. `dismissedWindowKey`).
  Future<Map<String, Object?>?> consumeWidgetState();

  /// Queries OS widget, App Group, ActivityKit, and Android 16 promoted Live
  /// Update support.
  Future<WidgetCapabilities> getCapabilities();

  /// Reads recent extension diagnostics from the iOS App Group.
  Future<List<String>> getWidgetDiagnostics();
}

/// Production [WidgetBridgeGateway] backed by `MethodChannel('ourney/widgets')`.
///
/// Degrades gracefully with zero crashes when the native channel is absent or
/// when an iOS Free Apple ID sideload lacks an App Group container (O2, §4.2).
class MethodChannelWidgetBridgeGateway implements WidgetBridgeGateway {
  const MethodChannelWidgetBridgeGateway();

  static const MethodChannel channel = MethodChannel('ourney/widgets');

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<bool> syncSnapshot({
    required String snapshotJson,
    required List<WidgetThumbPayload> thumbs,
  }) async {
    if (!_supported) return false;
    try {
      final result = await channel.invokeMethod<bool>(
        'syncSnapshot',
        <String, Object?>{
          'snapshotJson': snapshotJson,
          'thumbs': [for (final t in thumbs) t.toJson()],
        },
      );
      return result ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> syncLiveActivity(Map<String, Object?>? payload) async {
    if (!_supported) return false;
    try {
      final result = await channel.invokeMethod<bool>(
        'syncLiveActivity',
        payload,
      );
      return result ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> clearAll() async {
    if (!_supported) return false;
    try {
      final result = await channel.invokeMethod<bool>('clearAll');
      return result ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<Map<String, Object?>?> consumeWidgetState() async {
    if (!_supported) return null;
    try {
      final raw = await channel.invokeMethod<Map<Object?, Object?>>(
        'consumeWidgetState',
      );
      if (raw == null) return null;
      return {
        for (final entry in raw.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
    } on Object {
      return null;
    }
  }

  @override
  Future<WidgetCapabilities> getCapabilities() async {
    if (!_supported) return WidgetCapabilities.unsupported;
    try {
      final raw = await channel.invokeMethod<Map<Object?, Object?>>(
        'getCapabilities',
      );
      return WidgetCapabilities.fromMap(raw);
    } on Object {
      return WidgetCapabilities.unsupported;
    }
  }

  @override
  Future<List<String>> getWidgetDiagnostics() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return const [];
    try {
      return await channel.invokeListMethod<String>('getWidgetDiagnostics') ??
          const [];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }
}

/// Recorded `syncSnapshot` call on [FakeWidgetBridgeGateway].
class RecordedSnapshotSync {
  const RecordedSnapshotSync({
    required this.snapshotJson,
    required this.thumbs,
  });

  final String snapshotJson;
  final List<WidgetThumbPayload> thumbs;
}

/// In-memory [WidgetBridgeGateway] double for unit and widget tests (§4.1, §8.3).
class FakeWidgetBridgeGateway implements WidgetBridgeGateway {
  FakeWidgetBridgeGateway({
    this.capabilities = const WidgetCapabilities(
      widgets: true,
      liveActivity: true,
      promotedLiveUpdates: true,
      appGroup: true,
    ),
    this.pendingWidgetState,
  });

  WidgetCapabilities capabilities;
  List<String> widgetDiagnostics = const [];
  Map<String, Object?>? pendingWidgetState;
  bool nextSyncSnapshotResult = true;
  bool nextSyncLiveActivityResult = true;

  final List<RecordedSnapshotSync> snapshotSyncs = [];
  final List<Map<String, Object?>?> liveActivitySyncs = [];
  int clearAllCount = 0;
  int consumeStateCount = 0;

  @override
  Future<bool> syncSnapshot({
    required String snapshotJson,
    required List<WidgetThumbPayload> thumbs,
  }) async {
    snapshotSyncs.add(
      RecordedSnapshotSync(
        snapshotJson: snapshotJson,
        thumbs: List.unmodifiable(thumbs),
      ),
    );
    return nextSyncSnapshotResult;
  }

  @override
  Future<bool> syncLiveActivity(Map<String, Object?>? payload) async {
    liveActivitySyncs.add(
      payload == null ? null : Map<String, Object?>.unmodifiable(payload),
    );
    return nextSyncLiveActivityResult;
  }

  @override
  Future<bool> clearAll() async {
    clearAllCount++;
    return true;
  }

  @override
  Future<Map<String, Object?>?> consumeWidgetState() async {
    consumeStateCount++;
    final state = pendingWidgetState;
    pendingWidgetState = null;
    return state;
  }

  @override
  Future<WidgetCapabilities> getCapabilities() async => capabilities;

  @override
  Future<List<String>> getWidgetDiagnostics() async => widgetDiagnostics;
}

final widgetBridgeGatewayProvider = Provider<WidgetBridgeGateway>(
  (ref) => const MethodChannelWidgetBridgeGateway(),
);
