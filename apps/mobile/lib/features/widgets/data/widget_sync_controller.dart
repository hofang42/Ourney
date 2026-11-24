import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/locale_override.dart';
import '../../../app/providers.dart';
import '../../../app/redirect.dart' show AuthStatus;
import '../../../data/data_providers.dart' show dataLayerProvider;
import '../../groups/data/groups_providers.dart' show groupBlockedIdsProvider;
import '../../journeys/data/journeys_providers.dart';
import '../../profile/settings_providers.dart'
    show
        blurPhotosOnShareProvider,
        hideWeightOnShareProvider,
        themeModeProvider;
import '../../reminders/data/reminder_scheduler.dart'
    show reminderDeviceTimezoneProvider;
import '../../reminders/data/reminder_settings.dart';
import '../../safety/data/safety_providers.dart' show hiddenCheckInIdsProvider;
import '../domain/live_activity_planner.dart';
import '../domain/widget_snapshot.dart';
import 'widget_bridge_gateway.dart';
import 'widget_settings.dart';
import 'widget_thumb_preparer.dart';

export 'widget_settings.dart';

/// Trailing debounce window used by [WidgetSyncController] to coalesce rapid
/// repository and settings emissions into a single native write (§4.5).
const Duration kWidgetSyncDebounceDuration = Duration(milliseconds: 250);

/// Clock used for widget snapshot timestamps and check-in window evaluation.
/// Defaults to `journeysClockProvider`; override in tests if needed.
final widgetsClockProvider = Provider<Clock>(
  (ref) => ref.watch(journeysClockProvider),
);

/// Coordinates building `snapshot_v1.json`, preparing content-addressed
/// privacy-filtered thumbnails, deduplicating via SHA-256 digests, and
/// driving the Check-In Window Live Activity / Live Update (§4.5).
class WidgetSyncController {
  WidgetSyncController(
    this._ref, {
    this.debounceDuration = kWidgetSyncDebounceDuration,
  });

  final Ref _ref;
  final Duration debounceDuration;

  Timer? _debounceTimer;
  bool _microtaskScheduled = false;
  Future<void> _serial = Future.value();
  bool _pendingConsumeNativeState = false;
  bool _disposed = false;

  String? _lastSnapshotDigest;
  String? _lastLiveActivityDigest;
  WidgetLiveWindow? _lastActiveWindow;

  /// Latest built [WidgetSnapshot], exposed for diagnostics and tests.
  WidgetSnapshot? get lastSnapshot => _lastSnapshot;
  WidgetSnapshot? _lastSnapshot;

  WidgetBridgeGateway get _gateway => _ref.read(widgetBridgeGatewayProvider);
  WidgetThumbPreparer get _thumbPreparer =>
      _ref.read(widgetThumbPreparerProvider);

  /// Schedules a coalesced sync after [debounceDuration] (`250ms` by default).
  void scheduleSync({bool consumeNativeState = false}) {
    if (_disposed) return;
    if (consumeNativeState) _pendingConsumeNativeState = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      _debounceTimer = null;
      unawaited(syncNow());
    });
  }

  /// Coalesces synchronous provider-change bursts within the current event-loop
  /// turn using a microtask (zero `Timer`s created, safe in `FakeAsync` widget
  /// tests that exit without pumping 250ms of idle timer time).
  void scheduleCoalescedMicrotaskSync({bool consumeNativeState = false}) {
    if (_disposed) return;
    if (consumeNativeState) _pendingConsumeNativeState = true;
    if (_microtaskScheduled) return;
    _microtaskScheduled = true;
    Future.microtask(() {
      _microtaskScheduled = false;
      if (!_disposed) {
        unawaited(syncNow());
      }
    });
  }

  /// Immediately executes a snapshot + Live Activity sync, cancelling any
  /// pending debounce timer. Serialized so concurrent callers never race.
  Future<void> syncNow({
    bool consumeNativeState = false,
    bool force = false,
  }) {
    if (_disposed) return Future.value();
    if (consumeNativeState) _pendingConsumeNativeState = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final next = _serial.then((_) => _runSync(force: force));
    _serial = next.catchError((Object _) {});
    return _serial;
  }

  /// Unconditionally deletes `snapshot_v1.json`, `state.json`, all cached
  /// widget thumbnails, and ends all active Live Activities / Live Updates
  /// (called on sign-out / account switch / account deletion, §4.5, §7.1).
  Future<void> clearAll() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingConsumeNativeState = false;
    _lastSnapshotDigest = null;
    _lastLiveActivityDigest = null;
    _lastActiveWindow = null;
    _lastSnapshot = null;
    final next = _serial.then((_) async {
      await _thumbPreparer.clearCache();
      await _gateway.clearAll();
    });
    _serial = next.catchError((Object _) {});
    return _serial;
  }

  Future<void> _runSync({required bool force}) async {
    if (_disposed) return;
    try {
      final authStatus = _ref.read(authStatusProvider);
      if (authStatus == AuthStatus.signedOut) {
        _lastSnapshotDigest = null;
        _lastLiveActivityDigest = null;
        _lastActiveWindow = null;
        _lastSnapshot = null;
        await _thumbPreparer.clearCache();
        await _gateway.clearAll();
        return;
      }

      if (_pendingConsumeNativeState) {
        _pendingConsumeNativeState = false;
        await _consumeNativeState();
      }

      final now = _ref.read(widgetsClockProvider).now().toUtc();
      final localeOverride = _ref.read(localeOverrideProvider);
      final locale = localeOverride?.languageCode ?? 'vi';
      final themeMode = _ref.read(themeModeProvider);
      final photoMode = _ref.read(widgetPhotoModeProvider);
      final explicitRedact = _ref.read(redactLockScreenTitlesPrefProvider);
      final liveEnabled = _ref.read(liveActivityEnabledProvider);
      final defaultJourneyId = _ref.read(defaultWidgetJourneyIdProvider);
      final dismissedWindowKey = _ref.read(dismissedLiveWindowKeyProvider);
      final reminderSettings = _ref.read(reminderSettingsProvider);
      final streakAlerts = _ref.read(streakAlertsEnabledProvider);
      final blurPhotosOnShare = _ref.read(blurPhotosOnShareProvider);
      final hiddenCheckInIds = _ref.read(hiddenCheckInIdsProvider);
      final currentUserId = _ref.read(currentUserIdProvider);
      final deviceTimezone = _ref
          .read(reminderDeviceTimezoneProvider)
          .asData
          ?.value;

      final pinnedIds = await _readPinnedIds();
      final blockedIds = await _readBlockedIds();
      final journeyInputs = await _readJourneyInputs(currentUserId);

      final snapshot = WidgetSnapshotBuilder.build(
        now: now,
        authStatus: authStatus,
        journeyInputs: journeyInputs,
        locale: locale,
        themeMode: themeMode,
        deviceTimezone: deviceTimezone,
        pinnedJourneyIds: pinnedIds,
        reminderSettings: reminderSettings,
        streakAlertsEnabled: streakAlerts,
        photoMode: photoMode,
        explicitRedactLockScreenTitles: explicitRedact,
        liveActivityEnabled: liveEnabled,
        preferredDefaultJourneyId: defaultJourneyId,
        globalBlurPhotosOnShare: blurPhotosOnShare,
        blockedUserIds: blockedIds,
        hiddenCheckInIds: hiddenCheckInIds,
        currentUserId: currentUserId,
        dismissedWindowKey: dismissedWindowKey,
      );
      _lastSnapshot = snapshot;

      final preparedThumbs = await _thumbPreparer.prepare(
        snapshot.thumbRequests,
      );
      final thumbPathsSignature = [
        for (final t in preparedThumbs)
          '${t.id}:${t.sourcePath}:${t.maxSide}:${t.blur}',
      ]..sort();
      final fullSnapshotDigest = sha256
          .convert(
            utf8.encode(
              '${snapshot.computeContentDigest()}|${thumbPathsSignature.join(',')}',
            ),
          )
          .toString();

      if (force || fullSnapshotDigest != _lastSnapshotDigest) {
        await _gateway.syncSnapshot(
          snapshotJson: snapshot.toJsonString(),
          thumbs: preparedThumbs,
        );
        _lastSnapshotDigest = fullSnapshotDigest;
      }

      final livePlan = LiveActivityWindowPlanner.plan(
        now: now,
        authStatus: authStatus,
        liveActivityEnabled: liveEnabled,
        streakAlertsEnabled: streakAlerts,
        redactTitleOnLockScreen: snapshot.privacy.redactLockScreenTitles,
        locale: snapshot.locale,
        journeys: snapshot.journeys,
        dismissedWindowKey: dismissedWindowKey,
        previousActiveWindow: _lastActiveWindow,
      );

      final liveDigest = _computeLiveDigest(livePlan);
      if (force || liveDigest != _lastLiveActivityDigest) {
        await _gateway.syncLiveActivity(livePlan.channelPayload);
        _lastLiveActivityDigest = liveDigest;
      }
      _lastActiveWindow = livePlan.window;
    } on Object catch (e) {
      debugPrint('widgets: sync skipped: $e');
    }
  }

  String _computeLiveDigest(LiveActivityPlan plan) {
    final payload = plan.channelPayload;
    if (payload == null) return 'null';
    // Exclude volatile minute-by-minute `shortCriticalText` from deduplication
    // when the window, streak, counts, and action have not changed.
    final canonical = Map<String, Object?>.of(payload)
      ..remove('shortCriticalText');
    return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
  }

  Future<void> _consumeNativeState() async {
    final state = await _gateway.consumeWidgetState();
    if (state == null || _disposed) return;
    final dismissedKey = state['dismissedWindowKey'];
    if (dismissedKey is String && dismissedKey.isNotEmpty) {
      await _ref
          .read(dismissedLiveWindowKeyProvider.notifier)
          .set(dismissedKey);
    }
  }

  Future<Set<String>> _readPinnedIds() async {
    final cached = _ref.read(pinnedJourneyIdsProvider);
    if (cached.hasValue) return cached.requireValue;
    try {
      return await _ref
          .read(journeyRepositoryProvider)
          .watchPinnedJourneyIds()
          .first;
    } on Object {
      return const <String>{};
    }
  }

  Future<Set<String>> _readBlockedIds() async {
    final cached = _ref.read(groupBlockedIdsProvider);
    if (cached.hasValue) return cached.requireValue;
    try {
      return await _ref
          .read(safetyRepositoryProvider)
          .watchBlockedIds()
          .first;
    } on Object {
      return const <String>{};
    }
  }

  Future<List<WidgetJourneyBuildInput>> _readJourneyInputs(
    String? currentUserId,
  ) async {
    List<Journey> journeys;
    final cachedJourneys = _ref.read(journeysListProvider);
    if (cachedJourneys.hasValue) {
      journeys = cachedJourneys.requireValue;
    } else {
      try {
        journeys = await _ref
            .read(journeyRepositoryProvider)
            .watchActive()
            .first;
      } on Object {
        return const [];
      }
    }

    final localOnly = _ref.read(appConfigProvider).localOnly;
    final inputs = <WidgetJourneyBuildInput>[];

    for (final j in journeys) {
      if (j.status != JourneyStatus.active) continue;
      Membership? membership;
      final cachedMembership = _ref.read(myMembershipProvider(j.id));
      if (cachedMembership.hasValue) {
        membership = cachedMembership.requireValue;
      } else {
        try {
          membership = await _ref
              .read(journeyRepositoryProvider)
              .watchMyMembership(j.id)
              .first;
        } on Object {
          membership = null;
        }
      }

      final effectiveUserId = currentUserId ?? membership?.userId;
      List<CheckIn> myCheckIns = const [];
      final cachedMyCheckIns = _ref.read(myCheckInsProvider(j.id));
      if (cachedMyCheckIns.hasValue) {
        myCheckIns = cachedMyCheckIns.requireValue;
      } else {
        try {
          myCheckIns = await _ref
              .read(checkInRepositoryProvider)
              .watchForJourney(j.id, userId: effectiveUserId)
              .first;
        } on Object {
          myCheckIns = const [];
        }
      }

      List<MemberToday>? groupMembers;
      List<CheckIn> groupCheckIns = const [];
      if (j.kind == JourneyKind.group && !localOnly) {
        try {
          groupMembers = await _ref
              .read(groupRepositoryProvider)
              .watchToday(j.id)
              .first;
        } on Object {
          groupMembers = null;
        }
        try {
          groupCheckIns = await _ref
              .read(checkInRepositoryProvider)
              .watchForJourney(j.id)
              .first;
        } on Object {
          groupCheckIns = const [];
        }
      }

      inputs.add(
        WidgetJourneyBuildInput(
          journey: j,
          membership: membership,
          myCheckIns: myCheckIns,
          groupMembers: groupMembers,
          groupCheckIns: groupCheckIns,
        ),
      );
    }

    return inputs;
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}

final widgetSyncControllerProvider = Provider<WidgetSyncController>((ref) {
  final controller = WidgetSyncController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

/// Triggers an immediate widget snapshot & Live Activity sync (e.g. right after
/// `CheckInPoster.post` succeeds in `checkin_screen.dart`, §4.5). Never throws.
Future<void> syncWidgetsNow(WidgetRef ref) =>
    ref.read(widgetSyncControllerProvider).syncNow();

/// Mounted in `OurneyApp.builder` right alongside `ReminderLifecycleHook`
/// (`lib/app/app.dart`) to keep Home Screen Widgets, Lock Screen Widgets, and
/// Live Activities synchronized on start, resume, quarter-hour day ticks,
/// sync pulls, and settings/privacy changes (§4.5).
class WidgetLifecycleHook extends ConsumerStatefulWidget {
  const WidgetLifecycleHook({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<WidgetLifecycleHook> createState() =>
      _WidgetLifecycleHookState();
}

class _WidgetLifecycleHookState extends ConsumerState<WidgetLifecycleHook>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _syncEngineSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindSyncEngineChanges();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(widgetSyncControllerProvider)
          .scheduleCoalescedMicrotaskSync(consumeNativeState: true);
    });
  }

  void _bindSyncEngineChanges() {
    try {
      final sync = ref.read(dataLayerProvider).ctx.sync;
      if (sync != null) {
        _syncEngineSub = sync.changes.listen((_) {
          if (mounted) {
            ref
                .read(widgetSyncControllerProvider)
                .scheduleCoalescedMicrotaskSync();
          }
        });
      }
    } on Object {
      // Data layer not wired (unit/widget tests): repository streams suffice.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref
          .read(widgetSyncControllerProvider)
          .scheduleCoalescedMicrotaskSync(consumeNativeState: true);
    }
  }

  @override
  void dispose() {
    unawaited(_syncEngineSub?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void trigger<T>(T? _, T _) => ref
        .read(widgetSyncControllerProvider)
        .scheduleCoalescedMicrotaskSync();

    ref
      ..listen(authStatusProvider, trigger)
      ..listen(journeysListProvider, trigger)
      ..listen(pinnedJourneyIdsProvider, trigger)
      ..listen(journeysNowProvider, trigger)
      ..listen(themeModeProvider, trigger)
      ..listen(localeOverrideProvider, trigger)
      ..listen(hideWeightOnShareProvider, trigger)
      ..listen(blurPhotosOnShareProvider, trigger)
      ..listen(hiddenCheckInIdsProvider, trigger)
      ..listen(reminderSettingsProvider, trigger)
      ..listen(streakAlertsEnabledProvider, trigger)
      ..listen(widgetPhotoModeProvider, trigger)
      ..listen(redactLockScreenTitlesPrefProvider, trigger)
      ..listen(liveActivityEnabledProvider, trigger)
      ..listen(defaultWidgetJourneyIdProvider, trigger)
      ..listen(dismissedLiveWindowKeyProvider, trigger);

    return widget.child;
  }
}
