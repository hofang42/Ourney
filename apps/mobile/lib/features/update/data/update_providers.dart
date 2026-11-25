import 'dart:async';

import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import 'update_manifest_source.dart';
import 'update_prefs.dart';

part 'update_providers.g.dart';

Future<PackageInfo?> readUpdatePackageInfo() async {
  try {
    return await PackageInfo.fromPlatform();
  } on Object {
    return null;
  }
}

/// Seeded before runApp so a cached gate can be evaluated synchronously.
@Riverpod(keepAlive: true)
PackageInfo? packageInfo(Ref ref) => null;

@Riverpod(keepAlive: true)
UpdatePlatform? updatePlatform(Ref ref) => kIsWeb
    ? null
    : switch (defaultTargetPlatform) {
        TargetPlatform.android => UpdatePlatform.android,
        TargetPlatform.iOS => UpdatePlatform.ios,
        _ => null,
      };

@Riverpod(keepAlive: true)
bool appUpdateEnabled(Ref ref) =>
    !kDebugMode && ref.watch(appConfigProvider).hasBackend;

@Riverpod(keepAlive: true)
UpdateManifestSource? updateManifestSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseUpdateManifestSource(client);
}

@Riverpod(keepAlive: true)
Clock appUpdateClock(Ref ref) => clock;

@Riverpod(keepAlive: true)
Stream<bool> Function() appUpdateConnectivityChanges(Ref ref) =>
    () => Connectivity().onConnectivityChanged
        .map(
          (results) =>
              results.any((result) => result != ConnectivityResult.none),
        )
        .distinct();

@Riverpod(keepAlive: true)
Future<bool> Function(Uri) appUpdateLauncher(Ref ref) =>
    (url) => launchUrl(url, mode: LaunchMode.externalApplication);

/// Bound at the app root to start checking after the first frame and recheck
/// when the app resumes or regains connectivity.
@Riverpod(keepAlive: true)
void appUpdateLifecycle(Ref ref) {
  if (!ref.watch(appUpdateEnabledProvider) ||
      ref.watch(updatePlatformProvider) == null ||
      SemVer.tryParse(ref.watch(packageInfoProvider)?.version) == null) {
    return;
  }
  final controller = ref.read(appUpdateControllerProvider.notifier);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!ref.mounted) return;
    unawaited(controller.refresh());
    final lifecycle = AppLifecycleListener(onResume: controller._onResume);
    final connectivity = ref
        .read(appUpdateConnectivityChangesProvider)()
        .listen(controller._onConnectivityChanged, onError: (Object _) {});
    ref.onDispose(lifecycle.dispose);
    ref.onDispose(() => unawaited(connectivity.cancel()));
  });
}

final class AppUpdateState {
  const AppUpdateState({
    this.installedVersion,
    this.installedBuild,
    this.platform,
    this.manifest,
    this.decision = const UpdateDecision(),
    this.isChecking = false,
    this.checkFailed = false,
    this.usingCachedPolicy = false,
  });

  final SemVer? installedVersion;
  final String? installedBuild;
  final UpdatePlatform? platform;
  final AppUpdateManifest? manifest;
  final UpdateDecision decision;
  final bool isChecking;
  final bool checkFailed;
  final bool usingCachedPolicy;

  UpdateUrgency get urgency => decision.urgency;
  bool get showHubBanner => decision.showHubBanner;
  bool get showSettingsBadge => decision.showSettingsBadge;
  bool get canShowWhatsNew => decision.canShowWhatsNew;
  UpdateReleaseNotes? get installedReleaseNotes =>
      manifest?.latest == installedVersion ? manifest?.notes : null;
}

@Riverpod(keepAlive: true)
class AppUpdateController extends _$AppUpdateController {
  static const _refreshInterval = Duration(hours: 6);

  UpdatePrefs? _prefs;
  CachedUpdatePolicy? _policy;
  DateTime? _lastCheckedAt;
  Timer? _reevaluateTimer;
  Future<void>? _inFlight;
  bool _fresh = false;
  bool _checkFailed = false;
  bool? _online;
  bool _checkOnReconnect = false;

  DateTime get _now => ref.read(appUpdateClockProvider).now();

  @override
  AppUpdateState build() {
    ref.onDispose(() => _reevaluateTimer?.cancel());
    final platform = ref.read(updatePlatformProvider);
    final info = ref.read(packageInfoProvider);
    final installed = SemVer.tryParse(info?.version);
    if (ref.read(appUpdateEnabledProvider) &&
        platform != null &&
        installed != null) {
      _prefs = UpdatePrefs(ref.read(sharedPreferencesProvider));
      final cached = _prefs!.cachedPolicy;
      if (cached?.manifest.platform == platform) _policy = cached;
    }
    return _evaluate(
      platform: platform,
      installed: installed,
      build: info?.buildNumber,
    );
  }

  Future<void> refresh({bool manual = false}) {
    if (_prefs == null) return Future.value();
    if (_inFlight case final active?) return active;
    final lastCheckedAt = _lastCheckedAt;
    if (!manual && lastCheckedAt != null) {
      final age = _now.difference(lastCheckedAt);
      if (!age.isNegative && age < _refreshInterval) return Future.value();
    }
    _lastCheckedAt = _now;
    // Defer execution until the active Future is recorded, including for
    // synchronous listeners reacting to the checking state.
    final refresh = Future<void>.microtask(_fetch);
    return _inFlight = refresh.whenComplete(() {
      _inFlight = null;
      if (ref.mounted && _checkOnReconnect) {
        _checkOnReconnect = false;
        if (_checkFailed) unawaited(this.refresh(manual: true));
      }
    });
  }

  Future<void> _fetch() async {
    if (!ref.mounted) return;
    final prefs = _prefs!;
    final installed = state.installedVersion!;
    final platform = state.platform!;
    if (prefs.firstSeenAt == null) {
      unawaited(_save(() => prefs.recordFirstSeen(_now)));
    }
    if (prefs.lastSeenInstalledVersion == null) {
      unawaited(_save(() => prefs.recordInstalledVersion(installed)));
    }
    _emit(checking: true);
    try {
      final source = ref.read(updateManifestSourceProvider);
      final manifest = await source?.fetch(platform);
      if (!ref.mounted) return;
      if (manifest == null || manifest.platform != platform) {
        throw const FormatException('App version policy is unavailable');
      }
      final policy = (manifest: manifest, checkedAt: _now);
      _policy = policy;
      _fresh = true;
      _checkFailed = false;
      unawaited(_save(() => prefs.savePolicy(policy)));
    } on Object {
      if (!ref.mounted) return;
      _fresh = false;
      _checkFailed = true;
    }
    _emit(checking: false);
  }

  void _onResume() {
    _emit();
    // A forced gate or failed check needs a fresh answer on resume even
    // inside the normal six-hour interval.
    unawaited(
      refresh(manual: state.urgency == UpdateUrgency.forced || _checkFailed),
    );
  }

  void _onConnectivityChanged(bool online) {
    final previous = _online;
    _online = online;
    if (!online || previous == true) return;
    if (_inFlight != null) {
      _checkOnReconnect = true;
    } else if (previous == false || _checkFailed) {
      unawaited(refresh(manual: true));
    }
  }

  void _emit({bool? checking}) {
    state = _evaluate(
      platform: state.platform,
      installed: state.installedVersion,
      build: state.installedBuild,
      checking: checking ?? state.isChecking,
    );
  }

  AppUpdateState _evaluate({
    UpdatePlatform? platform,
    SemVer? installed,
    String? build,
    bool checking = false,
  }) {
    final policy = _policy;
    final prefs = _prefs;
    final now = _now;
    final firstSeenAt = prefs?.firstSeenAt;
    final snooze = prefs?.snooze;
    final age = policy == null ? null : now.difference(policy.checkedAt);
    final isCached =
        !_fresh || age == null || age.isNegative || age >= updateForcedCacheTtl;
    final decision = evaluateAppUpdatePolicy(
      installed: installed,
      manifest: policy?.manifest,
      now: now,
      isCached: isCached,
      checkedAt: policy?.checkedAt,
      firstSeenAt: firstSeenAt,
      snooze: snooze,
      skippedVersion: prefs?.skippedVersion,
      hubDismissedVersion: prefs?.hubDismissedVersion,
      lastSeenInstalledVersion: prefs?.lastSeenInstalledVersion,
    );
    _reevaluateTimer?.cancel();
    final reconsiderAt = switch (decision.urgency) {
      UpdateUrgency.forced => policy?.checkedAt.add(updateForcedCacheTtl),
      UpdateUrgency.softBanner || UpdateUrgency.passive => _nextSheetCheck(
        policy,
        firstSeenAt,
        snooze,
        now,
      ),
      _ => null,
    };
    if (reconsiderAt != null && reconsiderAt.isAfter(now)) {
      _reevaluateTimer = Timer(reconsiderAt.difference(now), _emit);
    }
    return AppUpdateState(
      installedVersion: installed,
      installedBuild: build,
      platform: platform,
      manifest: policy?.manifest,
      decision: decision,
      isChecking: checking,
      checkFailed: _checkFailed,
      usingCachedPolicy: isCached && decision.urgency == UpdateUrgency.forced,
    );
  }

  DateTime? _nextSheetCheck(
    CachedUpdatePolicy? policy,
    DateTime? firstSeenAt,
    UpdateSnooze? snooze,
    DateTime now,
  ) {
    if (!_fresh || policy == null) return null;
    final until = snooze?.version == policy.manifest.latest
        ? snooze?.until
        : null;
    final graceEnd = firstSeenAt != null && !firstSeenAt.isAfter(now)
        ? firstSeenAt.add(updateInstallGrace)
        : null;
    if (graceEnd != null && (until == null || graceEnd.isAfter(until))) {
      return graceEnd;
    }
    return until;
  }

  Future<void> snoozeSheet({SemVer? version}) async {
    final prefs = _prefs;
    final target = version ?? state.manifest?.latest;
    if (prefs == null || target == null || target != state.manifest?.latest) {
      return;
    }
    final snooze = prefs.snooze ?? UpdateSnooze(version: target, count: 0);
    await _apply(() => prefs.saveSnooze(snooze.next(target, _now)));
  }

  Future<void> skipVersion({SemVer? version}) async {
    final prefs = _prefs;
    final target = version ?? state.manifest?.latest;
    if (prefs == null || target == null || target != state.manifest?.latest) {
      return;
    }
    await _apply(() => prefs.skipVersion(target));
  }

  Future<void> dismissHubBanner({SemVer? version}) async {
    final prefs = _prefs;
    final target = version ?? state.manifest?.latest;
    if (prefs == null || target == null || target != state.manifest?.latest) {
      return;
    }
    await _apply(() => prefs.dismissHubBanner(target));
  }

  Future<void> markWhatsNewSeen() async {
    final prefs = _prefs;
    final installed = state.installedVersion;
    if (prefs == null || installed == null || !state.canShowWhatsNew) return;
    await _apply(() => prefs.recordInstalledVersion(installed));
  }

  Future<bool> launchUpdate() async {
    final url = state.manifest?.downloadUrl;
    if (state.urgency == UpdateUrgency.none ||
        url == null ||
        !isAllowedUpdateUrl(url)) {
      return false;
    }
    try {
      return await ref.read(appUpdateLauncherProvider)(url);
    } on Object {
      return false;
    }
  }

  Future<void> _apply(Future<void> Function() write) async {
    final saved = _save(write);
    _emit();
    await saved;
  }

  Future<void> _save(Future<void> Function() write) async {
    try {
      await write();
    } on Object {
      // SharedPreferencesWithCache already updated its in-memory values.
    }
  }
}
