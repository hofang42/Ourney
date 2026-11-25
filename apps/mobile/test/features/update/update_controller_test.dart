import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/update/data/update_manifest_source.dart';
import 'package:ourney/features/update/data/update_prefs.dart';
import 'package:ourney/features/update/data/update_providers.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/test_helpers.dart';

class FakeUpdateManifestSource implements UpdateManifestSource {
  late Future<AppUpdateManifest> Function() response;
  int calls = 0;

  @override
  Future<AppUpdateManifest> fetch(UpdatePlatform platform) {
    expect(platform, UpdatePlatform.android);
    calls++;
    return response();
  }
}

AppUpdateManifest manifest({
  String latest = '1.1.0',
  String min = '1.0.0',
  bool killed = false,
}) => AppUpdateManifest.tryFromJson({
  'platform': 'android',
  'latest': latest,
  'latest_build': 2,
  'recommended': latest,
  'min_supported': min,
  'force_on_major': true,
  'kill_switch': killed,
  'download_url': 'https://ourney.tech/Ourney.apk',
  'notes': {
    'vi': ['Cập nhật mới'],
    'en': ['New features'],
  },
  'updated_at': '2026-11-25T00:00:00Z',
})!;

void main() {
  late DateTime now;
  late FakeUpdateManifestSource source;
  late List<Uri> launched;

  setUp(() {
    now = DateTime.utc(2026, 11, 25);
    source = FakeUpdateManifestSource()..response = () async => manifest();
    launched = [];
  });

  ProviderContainer createContainer(
    SharedPreferencesWithCache prefs, {
    String installed = '1.0.0',
    bool enableChecks = true,
    Stream<bool>? connectivity,
  }) => ProviderContainer.test(
    overrides: [
      appConfigProvider.overrideWithValue(testBackendConfig),
      sharedPreferencesProvider.overrideWithValue(prefs),
      packageInfoProvider.overrideWithValue(
        PackageInfo(
          appName: 'Ourney',
          packageName: 'com.hofang42.ourney',
          version: installed,
          buildNumber: '1',
        ),
      ),
      if (enableChecks) appUpdateEnabledProvider.overrideWithValue(true),
      updatePlatformProvider.overrideWithValue(UpdatePlatform.android),
      appUpdateClockProvider.overrideWithValue(Clock(() => now)),
      updateManifestSourceProvider.overrideWithValue(source),
      if (connectivity != null)
        appUpdateConnectivityChangesProvider.overrideWithValue(
          () => connectivity,
        ),
      appUpdateLauncherProvider.overrideWithValue((url) async {
        launched.add(url);
        return true;
      }),
    ],
  );

  AppUpdateState read(ProviderContainer container) =>
      container.read(appUpdateControllerProvider);

  AppUpdateController controller(ProviderContainer container) =>
      container.read(appUpdateControllerProvider.notifier);

  test('timeout without a cached policy fails open', () async {
    final container = createContainer(await testPrefs());
    source.response = () async => throw TimeoutException('test timeout');
    await controller(container).refresh();
    expect(read(container).urgency, UpdateUrgency.none);
    expect(read(container).checkFailed, isTrue);
    expect(read(container).isChecking, isFalse);
    expect(await controller(container).launchUpdate(), isFalse);
  });

  test('cached soft policy stays hidden while offline', () async {
    final prefs = await testPrefs();
    await UpdatePrefs(prefs).savePolicy((manifest: manifest(), checkedAt: now));
    source.response = () async => throw const FormatException('bad manifest');
    final container = createContainer(prefs);
    expect(read(container).urgency, UpdateUrgency.none);
    await controller(container).refresh();
    expect(read(container).urgency, UpdateUrgency.none);
  });

  test(
    'a cached gate is synchronous and a fresh lower minimum removes it',
    () async {
      final prefs = await testPrefs();
      await UpdatePrefs(prefs)
          .savePolicy((manifest: manifest(min: '1.1.0'), checkedAt: now));
      final container = createContainer(prefs);
      expect(read(container).urgency, UpdateUrgency.forced);
      expect(read(container).usingCachedPolicy, isTrue);

      source.response = () async => throw TimeoutException('offline');
      await controller(container).refresh();
      expect(read(container).urgency, UpdateUrgency.forced);
      expect(read(container).checkFailed, isTrue);

      source.response = () async => manifest();
      await controller(container).refresh(manual: true);
      expect(read(container).urgency, UpdateUrgency.softBanner);
      expect(read(container).usingCachedPolicy, isFalse);
      expect(read(container).checkFailed, isFalse);

      final restarted = createContainer(prefs);
      expect(read(restarted).urgency, UpdateUrgency.none);
    },
  );

  test('a seven-day-old gate expires and debug ignores a recent one', () async {
    final prefs = await testPrefs();
    final updates = UpdatePrefs(prefs);
    final forced = manifest(min: '1.1.0');
    await updates.savePolicy((
      manifest: forced,
      checkedAt: now.subtract(updateForcedCacheTtl),
    ));
    expect(read(createContainer(prefs)).urgency, UpdateUrgency.none);

    await updates.savePolicy((manifest: forced, checkedAt: now));
    final debug = createContainer(prefs, enableChecks: false);
    expect(read(debug).urgency, UpdateUrgency.none);
    await controller(debug).refresh(manual: true);
    expect(source.calls, 0);
  });

  testWidgets(
    'cold start checks after frame one and reconnect clears a cached gate',
    (tester) async {
      final prefs = await testPrefs();
      await UpdatePrefs(prefs)
          .savePolicy((manifest: manifest(min: '1.1.0'), checkedAt: now));
      final connectivity = StreamController<bool>.broadcast();
      addTearDown(connectivity.close);
      final pending = Completer<AppUpdateManifest>();
      source.response = () => pending.future;
      final container = createContainer(
        prefs,
        connectivity: connectivity.stream,
      );
      expect(read(container).urgency, UpdateUrgency.forced);
      expect(source.calls, 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (_, ref, _) {
              ref.watch(appUpdateLifecycleProvider);
              expect(source.calls, 0);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      expect(source.calls, 1);
      expect(read(container).isChecking, isTrue);

      connectivity.add(true);
      await tester.pump();
      expect(source.calls, 1);
      source.response = () async => manifest(min: '1.1.0', killed: true);
      pending.completeError(TimeoutException('offline'));
      await tester.pump();
      expect(source.calls, 2);
      expect(read(container).urgency, UpdateUrgency.none);
      expect(UpdatePrefs(prefs).cachedPolicy?.manifest.killSwitch, isTrue);
    },
  );

  testWidgets('a cached gate expires while the app stays open', (tester) async {
    final prefs = await testPrefs();
    const remaining = Duration(milliseconds: 100);
    await UpdatePrefs(prefs).savePolicy((
      manifest: manifest(min: '1.1.0'),
      checkedAt: now.subtract(updateForcedCacheTtl).add(remaining),
    ));
    final container = createContainer(prefs);
    expect(read(container).urgency, UpdateUrgency.forced);
    now = now.add(remaining);
    await tester.pump(remaining);
    expect(read(container).urgency, UpdateUrgency.none);
  });

  test(
    'refresh coalesces concurrent checks and throttles automatic checks',
    () async {
      final container = createContainer(await testPrefs());
      final update = controller(container);
      final pending = Completer<AppUpdateManifest>();
      source.response = () => pending.future;
      final first = update.refresh();
      final second = update.refresh(manual: true);
      expect(identical(first, second), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(read(container).isChecking, isTrue);
      pending.complete(manifest());
      await first;
      await update.refresh();
      expect(source.calls, 1);
      now = now.add(const Duration(hours: 6));
      await update.refresh();
      expect(source.calls, 2);
    },
  );

  test(
    'snooze, skip and dismiss change only the relevant release prompts',
    () async {
      final prefs = await testPrefs();
      await UpdatePrefs(prefs)
          .recordFirstSeen(now.subtract(updateInstallGrace));
      final container = createContainer(prefs);
      final update = controller(container);
      await update.refresh();
      expect(read(container).urgency, UpdateUrgency.softSheet);
      await update.snoozeSheet();
      expect(read(container).urgency, UpdateUrgency.softBanner);
      await update.dismissHubBanner();
      expect(read(container).urgency, UpdateUrgency.passive);
      expect(read(container).showSettingsBadge, isTrue);
      expect(await update.launchUpdate(), isTrue);
      expect(launched.single, Uri.parse('https://ourney.tech/Ourney.apk'));
      await update.skipVersion();
      expect(read(container).urgency, UpdateUrgency.passive);
      source.response = () async => manifest(latest: '1.2.0');
      await update.refresh(manual: true);
      await update.skipVersion(version: SemVer.tryParse('1.1.0'));
      expect(read(container).urgency, UpdateUrgency.softSheet);
    },
  );

  test(
    'only a tracked upgrade shows Whats New, and recording it survives restart',
    () async {
      final prefs = await testPrefs();
      final firstInstall = createContainer(prefs, installed: '1.1.0');
      await controller(firstInstall).refresh();
      expect(read(firstInstall).canShowWhatsNew, isFalse);

      source.response = () async => manifest(latest: '1.2.0');
      final upgraded = createContainer(prefs, installed: '1.2.0');
      await controller(upgraded).refresh();
      expect(read(upgraded).canShowWhatsNew, isTrue);
      expect(read(upgraded).installedReleaseNotes?.en, ['New features']);
      await controller(upgraded).markWhatsNewSeen();
      expect(read(upgraded).canShowWhatsNew, isFalse);
      final restarted = createContainer(prefs, installed: '1.2.0');
      expect(read(restarted).canShowWhatsNew, isFalse);
    },
  );
}
