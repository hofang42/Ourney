import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_dock.dart';
import 'package:ourney/app/overlays/reminder_banner.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/checkin/checkin_clock.dart';
import 'package:ourney/features/checkin/checkin_drafts.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney/features/update/data/update_manifest_source.dart';
import 'package:ourney/features/update/data/update_providers.dart';
import 'package:ourney/features/update/ui/hub_update_banner.dart';
import 'package:ourney/features/update/ui/soft_update_sheet.dart';
import 'package:ourney/features/update/ui/update_gate_screen.dart';
import 'package:ourney/features/update/ui/whats_new_sheet.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart' as checkin;
import '../journeys/journeys_fakes.dart'
    show FakeCheckInRepository, FakeJourneyRepository;
import '../profile/fakes.dart';

class FakeManifestSource implements UpdateManifestSource {
  FakeManifestSource(this.onFetch);

  Future<AppUpdateManifest> Function(UpdatePlatform platform) onFetch;
  int calls = 0;

  @override
  Future<AppUpdateManifest> fetch(UpdatePlatform platform) {
    calls++;
    return onFetch(platform);
  }
}

AppUpdateManifest buildTestManifest({
  UpdatePlatform platform = UpdatePlatform.android,
  String latest = '1.1.0',
  int latestBuild = 2,
  String? recommended,
  String minSupported = '1.0.0',
  bool forceOnMajor = true,
  bool killSwitch = false,
  String? downloadUrl = 'https://ourney.tech/Ourney.apk',
  List<String> notesVi = const [
    'Tiện ích màn hình chính và khung giờ chụp buổi tối nhẹ nhàng hơn',
    'Đặt hoặc đổi mật khẩu ngay trong phần Cài đặt',
  ],
  List<String> notesEn = const [
    'Calmer Home Screen widgets and evening check-in window',
    'Set or change your password right inside Settings',
  ],
}) => AppUpdateManifest.tryFromJson({
  'platform': platform.name,
  'latest': latest,
  'latest_build': latestBuild,
  'recommended': recommended ?? latest,
  'min_supported': minSupported,
  'force_on_major': forceOnMajor,
  'kill_switch': killSwitch,
  'download_url': downloadUrl,
  'notes': {'vi': notesVi, 'en': notesEn},
  'updated_at': '2026-11-25T00:00:00Z',
})!;

void main() {
  final fixedNow = DateTime.utc(2026, 11, 25, 12);

  Future<ProviderContainer> pumpUpdateApp(
    WidgetTester tester, {
    required FakeManifestSource source,
    String installedVersion = '1.0.0',
    String installedBuild = '1',
    UpdatePlatform platform = UpdatePlatform.android,
    Locale locale = const Locale('vi'),
    Map<String, Object> initialPrefs = const {},
    FakeAuthRepository? auth,
    Future<bool> Function(Uri)? onLaunchUpdate,
    Future<bool> Function(Uri)? onLaunchSupport,
    PersonaSkinId? activeSkin,
    Clock? updateClock,
    JourneyRepository? journeys,
    CheckInRepository? checkIns,
    List<Override> overrides = const [],
  }) async {
    final userAuth = auth ?? FakeAuthRepository(userId: 'u1');
    final container = await pumpOurneyApp(
      tester,
      config: testBackendConfig,
      auth: userAuth,
      locale: locale,
      initialPrefs: {
        'update.firstSeenAtMs': fixedNow
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch,
        'update.lastSeenInstalledVersion': installedVersion,
        ...initialPrefs,
      },
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          FakeProfileRepository(aliceProfile),
        ),
        journeyRepositoryProvider.overrideWithValue(
          journeys ?? FakeJourneyRepository(),
        ),
        checkInRepositoryProvider.overrideWithValue(
          checkIns ?? FakeCheckInRepository(),
        ),
        mediaStoreProvider.overrideWithValue(FakeMediaStore()),
        appUpdateEnabledProvider.overrideWithValue(true),
        updatePlatformProvider.overrideWithValue(platform),
        appUpdateClockProvider.overrideWithValue(
          updateClock ?? Clock(() => fixedNow),
        ),
        appUpdateConnectivityChangesProvider.overrideWithValue(
          () => const Stream<bool>.empty(),
        ),
        packageInfoProvider.overrideWithValue(
          PackageInfo(
            appName: 'Ourney',
            packageName: 'com.hofang42.ourney',
            version: installedVersion,
            buildNumber: installedBuild,
          ),
        ),
        updateManifestSourceProvider.overrideWithValue(source),
        if (onLaunchUpdate != null)
          appUpdateLauncherProvider.overrideWithValue(onLaunchUpdate),
        if (onLaunchSupport != null)
          safetyUrlLauncherProvider.overrideWithValue(onLaunchSupport),
        if (activeSkin != null)
          activePersonaSkinProvider.overrideWithValue(activeSkin),
        ...overrides,
      ],
    );
    addTearDown(() => container.invalidate(appUpdateControllerProvider));
    return container;
  }

  group('CLAUDE.md §1.3 anti-slop guard', () {
    test('zero default Icons, CupertinoIcons, or emojis in update feature', () {
      final defaultIconPattern = RegExp(r'\b(Icons|CupertinoIcons)\.');
      final emojiPattern = RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
        unicode: true,
      );

      final files = [
        ...Directory('lib/features/update')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) => f.path.endsWith('.dart') || f.path.endsWith('.arb'),
            ),
      ];
      expect(files, isNotEmpty);
      for (final file in files) {
        final content = file.readAsStringSync();
        expect(
          defaultIconPattern.hasMatch(content),
          isFalse,
          reason: '${file.path} uses default Icons/CupertinoIcons',
        );
        expect(
          emojiPattern.hasMatch(content),
          isFalse,
          reason: '${file.path} contains a raw Unicode emoji',
        );
      }
    });
  });

  group('Camera-first non-interruption & sheet priority', () {
    testWidgets(
      'starting on /capture shows zero sheets over camera; switching to /journeys opens SoftUpdateSheet',
      (tester) async {
        final source = FakeManifestSource(
          (_) async => buildTestManifest(latest: '1.1.0'),
        );
        final c = await pumpUpdateApp(tester, source: source);
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.softSheet,
        );

        // On /capture (AppShell.captureIndex == 2): zero update sheets appear.
        expect(
          c.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
          AppRoutes.capture,
        );
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);
        expect(
          find.byKey(const ValueKey('update-whats-new-sheet')),
          findsNothing,
        );

        // Switching to /journeys (browse tab) opens SoftUpdateSheet automatically.
        await tester.tap(find.text('Hành trình'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('update-soft-sheet')),
            matching: find.text('Có bản Ourney 1.1.0 mới'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'starting on /capture with tracked upgrade suppresses WhatsNewSheet until switching to a browse tab',
      (tester) async {
        final source = FakeManifestSource(
          (_) async => buildTestManifest(latest: '1.1.0'),
        );
        final c = await pumpUpdateApp(
          tester,
          source: source,
          installedVersion: '1.1.0',
          installedBuild: '2',
          initialPrefs: const {
            'update.lastSeenInstalledVersion': '1.0.0',
          },
        );
        expect(c.read(appUpdateControllerProvider).canShowWhatsNew, isTrue);
        expect(
          find.byKey(const ValueKey('update-whats-new-sheet')),
          findsNothing,
        );

        // Switching to /journeys opens WhatsNewSheet once.
        await tester.tap(find.text('Hành trình'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('update-whats-new-sheet')),
          findsOneWidget,
        );
        expect(find.text('Có gì mới ở Ourney 1.1.0'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('update-whats-new-done')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('update-whats-new-sheet')),
          findsNothing,
        );
        expect(c.read(appUpdateControllerProvider).canShowWhatsNew, isFalse);
      },
    );

    testWidgets(
      'TermsUpdateSheet takes priority over SoftUpdateSheet and never stacks two sheets',
      (tester) async {
        final source = FakeManifestSource(
          (_) async => buildTestManifest(latest: '1.1.0'),
        );
        // termsVersion = 1 on server while required termsVersionProvider is 2 -> needsTermsUpdate is true.
        final auth = FakeAuthRepository(userId: 'u1', termsVersion: 1);
        final c = await pumpOurneyApp(
          tester,
          config: testBackendConfig,
          auth: auth,
          initialPrefs: {
            SafetyPrefs.termsVersionFor('u1'): 1,
            'update.firstSeenAtMs': fixedNow
                .subtract(const Duration(days: 3))
                .millisecondsSinceEpoch,
            'update.lastSeenInstalledVersion': '1.0.0',
          },
          overrides: [
            termsVersionProvider.overrideWithValue(2),
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(aliceProfile),
            ),
            journeyRepositoryProvider.overrideWithValue(FakeJourneyRepository()),
            checkInRepositoryProvider.overrideWithValue(FakeCheckInRepository()),
            mediaStoreProvider.overrideWithValue(FakeMediaStore()),
            appUpdateEnabledProvider.overrideWithValue(true),
            updatePlatformProvider.overrideWithValue(UpdatePlatform.android),
            appUpdateClockProvider.overrideWithValue(Clock(() => fixedNow)),
            packageInfoProvider.overrideWithValue(
              PackageInfo(
                appName: 'Ourney',
                packageName: 'com.hofang42.ourney',
                version: '1.0.0',
                buildNumber: '1',
              ),
            ),
            updateManifestSourceProvider.overrideWithValue(source),
          ],
        );

        expect(c.read(needsTermsUpdateProvider), isTrue);
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.softSheet,
        );

        // Only TermsUpdateSheet is shown, even after navigating to /journeys.
        expect(
          find.byKey(const ValueKey('safety-terms-update-sheet')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);

        c.read(routerProvider).go(AppRoutes.journeys);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);

        // Once TermsUpdateSheet clears, UpdateShellCoordinator retries and shows SoftUpdateSheet.
        await tester.tap(
          find.byKey(const ValueKey('safety-terms-update-later')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('safety-terms-update-sheet')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);
      },
    );

    testWidgets(
      'active ReminderBanner defers SoftUpdateSheet and WhatsNewSheet until banner clears',
      (tester) async {
        final source = FakeManifestSource(
          (_) async => buildTestManifest(latest: '1.1.0'),
        );
        final c = await pumpUpdateApp(tester, source: source);
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.softSheet,
        );

        // Show a ReminderBanner before switching to /journeys.
        c.read(reminderBannerProvider.notifier).show(
          const ReminderBannerData(
            journeyId: 'j1',
            journeyName: 'Chạy bộ',
            skinId: 'flexer',
            kind: ReminderBannerKind.daily,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ReminderBanner), findsOneWidget);

        // Switch to /journeys while ReminderBanner is active: SoftUpdateSheet must not stack.
        await tester.tap(find.text('Hành trình'));
        await tester.pumpAndSettle();
        expect(find.byType(ReminderBanner), findsOneWidget);
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);

        // Dismiss ReminderBanner -> SoftUpdateSheet opens automatically.
        c.read(reminderBannerProvider.notifier).dismiss();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);
      },
    );

    testWidgets(
      'active ReminderBanner defers WhatsNewSheet until banner clears, and subsequent release in same session still prompts SoftUpdateSheet',
      (tester) async {
        final source = FakeManifestSource(
          (_) async => buildTestManifest(latest: '1.1.0'),
        );
        final c = await pumpUpdateApp(
          tester,
          source: source,
          installedVersion: '1.1.0',
          installedBuild: '2',
          initialPrefs: const {
            'update.lastSeenInstalledVersion': '1.0.0',
          },
        );
        expect(c.read(appUpdateControllerProvider).canShowWhatsNew, isTrue);

        c.read(reminderBannerProvider.notifier).show(
          const ReminderBannerData(
            journeyId: 'j1',
            journeyName: 'Chạy bộ',
            skinId: 'flexer',
            kind: ReminderBannerKind.daily,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hành trình'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('update-whats-new-sheet')),
          findsNothing,
        );

        // Clearing ReminderBanner triggers WhatsNewSheet.
        c.read(reminderBannerProvider.notifier).dismiss();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('update-whats-new-sheet')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('update-whats-new-done')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('update-whats-new-sheet')),
          findsNothing,
        );

        // Later in the same long-lived session, 1.2.0 is released -> SoftUpdateSheet opens.
        source.onFetch = (_) async => buildTestManifest(latest: '1.2.0');
        await c
            .read(appUpdateControllerProvider.notifier)
            .refresh(manual: true);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('update-soft-sheet')),
            matching: find.text('Có bản Ourney 1.2.0 mới'),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Patch vs. Minor differentiation & HubUpdateBanner', () {
    testWidgets(
      'patch update (1.1.0 -> 1.1.1) shows HubUpdateBanner without SoftUpdateSheet; dismiss hides banner and keeps Settings badge',
      (tester) async {
        final source = FakeManifestSource(
          (_) async => buildTestManifest(latest: '1.1.1'),
        );
        final c = await pumpUpdateApp(
          tester,
          source: source,
          installedVersion: '1.1.0',
          installedBuild: '2',
        );
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.softBanner,
        );
        expect(c.read(appUpdateControllerProvider).showHubBanner, isTrue);
        expect(c.read(appUpdateControllerProvider).showSettingsBadge, isTrue);

        // Navigate to /journeys: HubUpdateBanner is visible, SoftUpdateSheet does NOT auto-open.
        await tester.tap(find.text('Hành trình'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);
        expect(find.byKey(const ValueKey('hub-update-banner')), findsOneWidget);
        expect(find.text('Có bản Ourney 1.1.1 mới'), findsOneWidget);

        // Verify touch targets >= 48x48dp on banner buttons.
        final viewSize = tester.getSize(
          find.byKey(const ValueKey('hub-update-banner-view')),
        );
        final dismissSize = tester.getSize(
          find.byKey(const ValueKey('hub-update-banner-dismiss')),
        );
        expect(viewSize.height, greaterThanOrEqualTo(48));
        expect(dismissSize.width, greaterThanOrEqualTo(48));
        expect(dismissSize.height, greaterThanOrEqualTo(48));

        // Tapping "Xem" opens SoftUpdateSheet manually.
        await tester.tap(find.byKey(const ValueKey('hub-update-banner-view')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);
        Navigator.of(
          tester.element(find.byKey(const ValueKey('update-soft-sheet'))),
        ).pop();
        await tester.pumpAndSettle();

        // Tapping dismiss (x) hides HubUpdateBanner while keeping Settings badge active.
        await tester.tap(
          find.byKey(const ValueKey('hub-update-banner-dismiss')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('hub-update-banner')), findsNothing);
        expect(c.read(appUpdateControllerProvider).showHubBanner, isFalse);
        expect(c.read(appUpdateControllerProvider).showSettingsBadge, isTrue);

        c.read(routerProvider).go('/profile/settings');
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('settings-version')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Phiên bản 1.1.0'), findsOneWidget);
        expect(find.text('Có bản mới 1.1.1'), findsOneWidget);
        c.invalidate(appUpdateControllerProvider);
      },
    );
  });

  group('SoftUpdateSheet actions & platform rules', () {
    testWidgets(
      'tapping "Cập nhật ngay" calls launchUpdate and shows Android sideload hint; tapping "Để sau" calls snoozeSheet',
      (tester) async {
        final launched = <Uri>[];
        final source = FakeManifestSource(
          (_) async => buildTestManifest(latest: '1.1.0'),
        );
        final c = await pumpUpdateApp(
          tester,
          source: source,
          onLaunchUpdate: (uri) async {
            launched.add(uri);
            return true;
          },
        );

        await tester.tap(find.text('Hành trình'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('update-android-install-hint')),
          findsNothing,
        );

        // Tap "Cập nhật ngay" -> launches URL and reveals Android sideload hint in-place.
        await tester.tap(find.byKey(const ValueKey('update-soft-install')));
        await tester.pumpAndSettle();
        expect(launched, [Uri.parse('https://ourney.tech/Ourney.apk')]);
        expect(
          find.byKey(const ValueKey('update-android-install-hint')),
          findsOneWidget,
        );

        // Tap "Để sau" -> snoozes sheet and closes.
        await tester.tap(find.byKey(const ValueKey('update-soft-later')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.softBanner,
        );
        c.invalidate(appUpdateControllerProvider);
      },
    );

    testWidgets(
      'tapping "Bỏ qua bản 1.1.0" calls skipVersion and closes sheet',
      (tester) async {
        final source = FakeManifestSource(
          (_) async => buildTestManifest(latest: '1.1.0'),
        );
        final c = await pumpUpdateApp(tester, source: source);

        await tester.tap(find.text('Hành trình'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);
        expect(find.text('Bỏ qua bản 1.1.0'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('update-soft-skip')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.passive,
        );
      },
    );

    testWidgets(
      'iOS with null downloadUrl hides install CTA on SoftUpdateSheet',
      (tester) async {
        final source = FakeManifestSource(
          (_) async => buildTestManifest(
            platform: UpdatePlatform.ios,
            latest: '1.1.0',
            downloadUrl: null,
          ),
        );
        final c = await pumpUpdateApp(
          tester,
          source: source,
          platform: UpdatePlatform.ios,
        );
        // Policy suppresses automatic soft prompts on iOS when downloadUrl is null.
        expect(c.read(appUpdateControllerProvider).urgency, UpdateUrgency.none);

        // Even if SoftUpdateSheet is rendered directly on iOS with null downloadUrl,
        // the install CTA button is hidden.
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: testApp(
              SoftUpdateSheet(version: SemVer.tryParse('1.1.0')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-install')), findsNothing);
        expect(
          find.byKey(const ValueKey('update-soft-later')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'dismissing SoftUpdateSheet by swipe, scrim tap, or system Back calls snoozeSheet (3d -> 7d -> stop) and re-evaluates in a long-lived session',
      (tester) async {
        var now = fixedNow;
        final source = FakeManifestSource(
          (_) async => buildTestManifest(latest: '1.1.0'),
        );
        final c = await pumpUpdateApp(
          tester,
          source: source,
          updateClock: Clock(() => now),
        );

        // 1. Switch to /journeys -> automatic SoftUpdateSheet opens (prompt #1).
        await tester.tap(find.text('Hành trình'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);

        // Dismiss #1 by swiping the sheet down -> snoozed for 3 days (urgency drops to softBanner).
        await tester.fling(
          find.byKey(const ValueKey('update-soft-sheet')),
          const Offset(0, 400),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.softBanner,
        );

        // 2. Advance past the 3-day snooze window in the same session -> re-opens (prompt #2).
        now = now.add(const Duration(days: 3, hours: 1));
        await c
            .read(appUpdateControllerProvider.notifier)
            .refresh(manual: true);
        await tester.pumpAndSettle();
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.softSheet,
        );
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);

        // Dismiss #2 by tapping the scrim barrier -> snoozed for 7 days.
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.softBanner,
        );

        // 3. Advance past the 7-day snooze window in the same session -> re-opens (prompt #3).
        now = now.add(const Duration(days: 7, hours: 1));
        await c
            .read(appUpdateControllerProvider.notifier)
            .refresh(manual: true);
        await tester.pumpAndSettle();
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.softSheet,
        );
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);

        // Dismiss #3 via Android system Back -> 3rd snooze permanently stops automatic sheets for 1.1.0.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);
        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.passive,
        );

        // 4. Advancing 30 more days never re-opens SoftUpdateSheet for 1.1.0.
        now = now.add(const Duration(days: 30));
        await c
            .read(appUpdateControllerProvider.notifier)
            .refresh(manual: true);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsNothing);

        // 5. When a new minor release 1.2.0 arrives in the same session, SoftUpdateSheet prompts for 1.2.0.
        source.onFetch = (_) async => buildTestManifest(latest: '1.2.0');
        await c
            .read(appUpdateControllerProvider.notifier)
            .refresh(manual: true);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('update-soft-sheet')),
            matching: find.text('Có bản Ourney 1.2.0 mới'),
          ),
          findsOneWidget,
        );
        c.invalidate(appUpdateControllerProvider);
      },
    );

    testWidgets(
      'Android sideload hint shows only for ourney.tech or .apk URLs, not Play Store URLs',
      (tester) async {
        expect(
          shouldShowAndroidSideloadHint(
            Uri.parse('https://ourney.tech/Ourney.apk'),
          ),
          isTrue,
        );
        expect(
          shouldShowAndroidSideloadHint(
            Uri.parse('https://www.ourney.tech/download'),
          ),
          isTrue,
        );
        expect(
          shouldShowAndroidSideloadHint(
            Uri.parse(
              'https://github.com/hofang42/ourney-releases/releases/download/v1.1.0/Ourney.apk',
            ),
          ),
          isTrue,
        );
        expect(
          shouldShowAndroidSideloadHint(
            Uri.parse(
              'https://play.google.com/store/apps/details?id=com.hofang42.ourney',
            ),
          ),
          isFalse,
        );
        expect(shouldShowAndroidSideloadHint(null), isFalse);

        final launched = <Uri>[];
        final playStoreUrl =
            'https://play.google.com/store/apps/details?id=com.hofang42.ourney';
        final source = FakeManifestSource(
          (_) async => buildTestManifest(
            latest: '1.1.0',
            downloadUrl: playStoreUrl,
          ),
        );
        final c = await pumpUpdateApp(
          tester,
          source: source,
          onLaunchUpdate: (uri) async {
            launched.add(uri);
            return true;
          },
        );

        await tester.tap(find.text('Hành trình'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('update-soft-sheet')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('update-soft-install')));
        await tester.pumpAndSettle();
        expect(launched, [Uri.parse(playStoreUrl)]);
        expect(
          find.byKey(const ValueKey('update-android-install-hint')),
          findsNothing,
        );
        c.invalidate(appUpdateControllerProvider);
      },
    );
  });

  group('Forced UpdateGateScreen', () {
    for (final post in [true, false]) {
      testWidgets(
        post
            ? 'live gate preserves the Post draft until the check-in is saved'
            : 'live gate on the camera waits for Post to be discarded',
        (tester) async {
          final source = FakeManifestSource(
            (_) async => buildTestManifest(latest: '1.0.0', latestBuild: 1),
          );
          final camera = checkin.FakeCameraSession();
          final drafts = checkin.FakeDraftFiles();
          final compressor = checkin.FakePhotoCompressor();
          final checkIns = checkin.FakeCheckInRepository();
          final c = await pumpUpdateApp(
            tester,
            source: source,
            journeys: checkin.FakeJourneyRepository(
              journeys: [
                checkin.testJourney(
                  durationDays: null,
                  templateId: TemplateId.weightLoss,
                ),
              ],
            ),
            checkIns: checkIns,
            overrides: [
              cameraSessionFactoryProvider.overrideWithValue(() => camera),
              checkinClockProvider.overrideWithValue(
                checkin.FakeCheckinClock(fixedNow),
              ),
              draftFilesProvider.overrideWithValue(drafts),
              photoCompressorProvider.overrideWithValue(compressor),
            ],
          );

          final allowCamera = find.text('Cho phép camera');
          await tester.ensureVisible(allowCamera);
          await tester.tap(allowCamera);
          await tester.pumpAndSettle();

          Future<void> forceUpdate() async {
            source.onFetch = (_) async =>
                buildTestManifest(latest: '2.0.0', minSupported: '2.0.0');
            await c
                .read(appUpdateControllerProvider.notifier)
                .refresh(manual: true);
            await tester.pumpAndSettle();
            expect(c.read(appUpdateWorkPausedProvider), isTrue);
            expect(find.byType(UpdateGateScreen), findsNothing);
          }

          if (!post) await forceUpdate();
          await tester.tap(find.byKey(const ValueKey('capture-shutter')));
          await tester.pumpAndSettle();

          final caption = find.byKey(const ValueKey('checkin-caption'));
          await tester.enterText(caption, 'A draft caption');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          if (post) await forceUpdate();

          expect(find.text('A draft caption'), findsOneWidget);
          expect(drafts.discarded, isEmpty);

          if (post) {
            await tester.tap(find.byKey(const ValueKey('checkin-post')));
            await tester.pumpAndSettle();
            expect(compressor.sources, ['/tmp/shot1.jpg']);
            expect(checkIns.submitted.single.caption, 'A draft caption');
            await tester.tap(find.byKey(const ValueKey('checkin-done')));
          } else {
            await tester.tap(find.byKey(const ValueKey('checkin-close')));
          }
          await tester.pumpAndSettle();

          expect(drafts.discarded, contains('/tmp/shot1.jpg'));
          expect(c.read(checkinDraftsProvider).photoFor('j1'), isNull);
          expect(find.byType(UpdateGateScreen), findsOneWidget);
          c.invalidate(appUpdateControllerProvider);
        },
      );
    }

    testWidgets(
      'system back on Post during a forced update discards the draft and opens UpdateGateScreen',
      (tester) async {
        final source = FakeManifestSource(
          (_) async => buildTestManifest(latest: '1.0.0', latestBuild: 1),
        );
        final camera = checkin.FakeCameraSession();
        final drafts = checkin.FakeDraftFiles();
        final c = await pumpUpdateApp(
          tester,
          source: source,
          journeys: checkin.FakeJourneyRepository(
            journeys: [
              checkin.testJourney(
                durationDays: null,
                templateId: TemplateId.weightLoss,
              ),
            ],
          ),
          checkIns: checkin.FakeCheckInRepository(),
          overrides: [
            cameraSessionFactoryProvider.overrideWithValue(() => camera),
            checkinClockProvider.overrideWithValue(
              checkin.FakeCheckinClock(fixedNow),
            ),
            draftFilesProvider.overrideWithValue(drafts),
            photoCompressorProvider.overrideWithValue(
              checkin.FakePhotoCompressor(),
            ),
          ],
        );

        final allowCamera = find.text('Cho phép camera');
        await tester.ensureVisible(allowCamera);
        await tester.tap(allowCamera);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('capture-shutter')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('checkin-caption')),
          'Draft before gate',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        source.onFetch = (_) async =>
            buildTestManifest(latest: '2.0.0', minSupported: '2.0.0');
        await c
            .read(appUpdateControllerProvider.notifier)
            .refresh(manual: true);
        await tester.pumpAndSettle();
        expect(c.read(appUpdateWorkPausedProvider), isTrue);
        expect(find.byType(UpdateGateScreen), findsNothing);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(drafts.discarded, contains('/tmp/shot1.jpg'));
        expect(c.read(checkinDraftsProvider).photoFor('j1'), isNull);
        expect(find.byType(UpdateGateScreen), findsOneWidget);
        c.invalidate(appUpdateControllerProvider);
      },
    );

    testWidgets(
      'blocks Android system back, hides AppDock and ReminderBanner, expands release notes, and unmounts when policy clears',
      (tester) async {
        var currentManifest = buildTestManifest(
          latest: '2.0.0',
          minSupported: '2.0.0',
        );
        final source = FakeManifestSource((_) async => currentManifest);
        final launched = <Uri>[];
        final supportLaunched = <Uri>[];
        final c = await pumpUpdateApp(
          tester,
          source: source,
          onLaunchUpdate: (uri) async {
            launched.add(uri);
            return true;
          },
          onLaunchSupport: (uri) async {
            supportLaunched.add(uri);
            return true;
          },
        );

        // Trigger a reminder banner while gated to verify it stays suppressed.
        c.read(reminderBannerProvider.notifier).show(
          const ReminderBannerData(
            journeyId: 'j1',
            journeyName: 'Chạy bộ',
            skinId: 'flexer',
            kind: ReminderBannerKind.daily,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          c.read(appUpdateControllerProvider).urgency,
          UpdateUrgency.forced,
        );
        expect(
          find.byKey(const ValueKey('update-gate-screen')),
          findsOneWidget,
        );
        expect(find.text('Cập nhật Ourney để tiếp tục'), findsOneWidget);
        expect(
          find.textContaining('Mọi hành trình và ảnh đã chụp của bạn vẫn được giữ nguyên'),
          findsOneWidget,
        );
        // AppDock and ReminderBanner are completely hidden.
        expect(find.byType(AppDock), findsNothing);
        expect(find.byType(ReminderBanner), findsNothing);

        // System back does NOT pop UpdateGateScreen.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('update-gate-screen')),
          findsOneWidget,
        );

        // Toggle "Xem có gì mới ở bản 2.0.0" reveals release notes.
        expect(
          find.text(
            'Tiện ích màn hình chính và khung giờ chụp buổi tối nhẹ nhàng hơn',
          ),
          findsNothing,
        );
        await tester.tap(
          find.byKey(const ValueKey('update-gate-whats-new-toggle')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Tiện ích màn hình chính và khung giờ chụp buổi tối nhẹ nhàng hơn',
          ),
          findsOneWidget,
        );

        // Tapping "Cập nhật ngay" launches URL and shows Android install hint.
        await tester.tap(find.byKey(const ValueKey('update-gate-install')));
        await tester.pumpAndSettle();
        expect(launched, [Uri.parse('https://ourney.tech/Ourney.apk')]);
        expect(
          find.byKey(const ValueKey('update-android-install-hint')),
          findsOneWidget,
        );

        // Tapping "Cần hỗ trợ cài đặt?" opens support mailto.
        await tester.ensureVisible(
          find.byKey(const ValueKey('update-gate-support')),
        );
        await tester.tap(find.byKey(const ValueKey('update-gate-support')));
        await tester.pumpAndSettle();
        expect(supportLaunched, hasLength(1));
        expect(supportLaunched.single.scheme, 'mailto');

        // When server lowers min_supported or enables kill_switch, tapping
        // "Kiểm tra lại" unmounts UpdateGateScreen automatically.
        currentManifest = buildTestManifest(
          latest: '2.0.0',
          minSupported: '1.0.0',
          forceOnMajor: false,
          killSwitch: true,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('update-gate-retry')),
        );
        await tester.tap(find.byKey(const ValueKey('update-gate-retry')));
        await tester.pumpAndSettle();

        expect(c.read(appUpdateControllerProvider).urgency, UpdateUrgency.none);
        expect(find.byKey(const ValueKey('update-gate-screen')), findsNothing);
      },
    );

    testWidgets(
      'cached forced gate while offline shows offline banner and checking state on retry; iOS hides install CTA when downloadUrl is null',
      (tester) async {
        final forcedIosManifest = buildTestManifest(
          platform: UpdatePlatform.ios,
          latest: '2.0.0',
          minSupported: '2.0.0',
          downloadUrl: null,
        );
        final pendingRetry = Completer<AppUpdateManifest>();
        var firstCall = true;
        final source = FakeManifestSource((_) {
          if (firstCall) {
            firstCall = false;
            return Future<AppUpdateManifest>.error(
              TimeoutException('offline on cold start'),
            );
          }
          return pendingRetry.future;
        });

        final c = await pumpUpdateApp(
          tester,
          source: source,
          platform: UpdatePlatform.ios,
          locale: const Locale('en'),
          initialPrefs: {
            'update.cachedPolicy': jsonEncode({
              'manifest': forcedIosManifest.toJson(),
              'checkedAt': fixedNow.millisecondsSinceEpoch,
            }),
          },
        );

        expect(
          find.byKey(const ValueKey('update-gate-screen')),
          findsOneWidget,
        );
        expect(find.text('Update Ourney to continue'), findsOneWidget);
        // Offline notice is shown because cold-start refresh failed while cached gate held.
        expect(
          find.byKey(const ValueKey('update-gate-offline-banner')),
          findsOneWidget,
        );
        // iOS with null downloadUrl hides install CTA and shows manual hint instead.
        expect(find.byKey(const ValueKey('update-gate-install')), findsNothing);
        expect(
          find.byKey(const ValueKey('update-gate-ios-manual-hint')),
          findsOneWidget,
        );

        // Tapping "Check again" enters checking state (spinner inside button).
        await tester.ensureVisible(
          find.byKey(const ValueKey('update-gate-retry')),
        );
        await tester.tap(find.byKey(const ValueKey('update-gate-retry')));
        await tester.pump();
        expect(
          tester
              .widget<UiButton>(find.byKey(const ValueKey('update-gate-retry')))
              .loading,
          isTrue,
        );

        pendingRetry.complete(forcedIosManifest);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<UiButton>(find.byKey(const ValueKey('update-gate-retry')))
              .loading,
          isFalse,
        );
        c.invalidate(appUpdateControllerProvider);
      },
    );
  });

  group('320x568 @ 1.35x text scale & Light/Dark skin matrix', () {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        for (final skin in [
          PersonaSkinId.quietTransformer,
          PersonaSkinId.aestheticFlexer,
        ]) {
          testWidgets(
            'all update surfaces fit 320x568 @ 1.35x without overflow (${brightness.name}, ${locale.languageCode}, ${skin.name})',
            (tester) async {
              tester.platformDispatcher.platformBrightnessTestValue =
                  brightness;
              addTearDown(
                tester.platformDispatcher.clearPlatformBrightnessTestValue,
              );
              tester.platformDispatcher.textScaleFactorTestValue = 1.35;
              addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue,
              );
              tester.view.physicalSize = const Size(320 * 2, 568 * 2);
              tester.view.devicePixelRatio = 2;
              addTearDown(tester.view.reset);

              final source = FakeManifestSource(
                (_) async => buildTestManifest(latest: '1.1.0'),
              );
              final c = await pumpUpdateApp(
                tester,
                source: source,
                locale: locale,
                activeSkin: skin,
              );
              expect(tester.takeException(), isNull);

              // 1. Switch to /journeys -> SoftUpdateSheet opens + HubUpdateBanner behind it.
              c.read(routerProvider).go(AppRoutes.journeys);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(
                find.byKey(const ValueKey('update-soft-sheet')),
                findsOneWidget,
              );

              // Close SoftUpdateSheet via snooze -> HubUpdateBanner is visible on /journeys.
              await tester.ensureVisible(
                find.byKey(const ValueKey('update-soft-later')),
              );
              await tester.tap(find.byKey(const ValueKey('update-soft-later')));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(
                find.byKey(const ValueKey('hub-update-banner')),
                findsOneWidget,
              );

              // 2. Render WhatsNewSheet at 320x568 @ 1.35x.
              unawaited(
                showWhatsNewSheet(
                  tester.element(find.byType(HubUpdateBanner)),
                  version: SemVer.tryParse('1.1.0'),
                  notes: buildTestManifest().notes.forLanguage(
                    locale.languageCode,
                  ),
                  markSeen: false,
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(
                find.byKey(const ValueKey('update-whats-new-sheet')),
                findsOneWidget,
              );
              await tester.ensureVisible(
                find.byKey(const ValueKey('update-whats-new-done')),
              );
              await tester.tap(
                find.byKey(const ValueKey('update-whats-new-done')),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);

              // 3. Transition to forced UpdateGateScreen at 320x568 @ 1.35x.
              source.onFetch = (_) async => buildTestManifest(
                latest: '2.0.0',
                minSupported: '2.0.0',
              );
              await c
                  .read(appUpdateControllerProvider.notifier)
                  .refresh(manual: true);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(
                find.byKey(const ValueKey('update-gate-screen')),
                findsOneWidget,
              );
              expect(find.byType(UpdateGateScreen), findsOneWidget);
              expect(find.byType(SoftUpdateSheet), findsNothing);
              expect(find.byType(WhatsNewSheet), findsNothing);
              c.invalidate(appUpdateControllerProvider);
            },
          );
        }
      }
    }
  });

  final shotsDir = Platform.environment['OURNEY_SHOTS_DIR'];
  if (shotsDir != null && shotsDir.isNotEmpty) {
    Future<void> loadBundledFonts() async {
      const families = <String, List<String>>{
        'BeVietnamPro': [
          'assets/fonts/BeVietnamPro-Regular.ttf',
          'assets/fonts/BeVietnamPro-Medium.ttf',
          'assets/fonts/BeVietnamPro-SemiBold.ttf',
          'assets/fonts/BeVietnamPro-Bold.ttf',
        ],
        'BricolageGrotesque': [
          'assets/fonts/BricolageGrotesque-Variable.ttf',
        ],
        'SpaceGrotesk': [
          'assets/fonts/SpaceGrotesk-Variable.ttf',
        ],
      };
      for (final entry in families.entries) {
        final loader = FontLoader(entry.key);
        for (final path in entry.value) {
          final bytes = File(path).readAsBytesSync();
          loader.addFont(
            Future.value(ByteData.sublistView(bytes)),
          );
        }
        await loader.load();
      }
    }

    Future<void> capturePng(WidgetTester tester, String fileName) async {
      final renderView = tester.binding.renderViews.first;
      final layer = renderView.debugLayer as OffsetLayer?;
      if (layer == null) return;
      final bounds = Offset.zero & tester.view.physicalSize;
      await tester.runAsync(() async {
        final image = await layer.toImage(bounds, pixelRatio: 1.0);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (bytes != null) {
          final out = File('$shotsDir/$fileName');
          out.parent.createSync(recursive: true);
          out.writeAsBytesSync(bytes.buffer.asUint8List());
        }
      });
    }

    for (final brightness in [Brightness.light, Brightness.dark]) {
      final mode = brightness.name;
      testWidgets('capture update surface screenshots ($mode)', (tester) async {
        await loadBundledFonts();
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(
          tester.platformDispatcher.clearPlatformBrightnessTestValue,
        );
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        var currentManifest = buildTestManifest(latest: '1.1.0');
        final source = FakeManifestSource((_) async => currentManifest);
        final c = await pumpUpdateApp(tester, source: source);

        // 1. SoftUpdateSheet on /journeys
        c.read(routerProvider).go(AppRoutes.journeys);
        await tester.pumpAndSettle();
        await capturePng(tester, 'soft-update-sheet-$mode.png');

        // 2. HubUpdateBanner on /journeys
        await tester.tap(find.byKey(const ValueKey('update-soft-later')));
        await tester.pumpAndSettle();
        await capturePng(tester, 'hub-update-banner-$mode.png');

        // 3. Settings version row with update badge
        c.read(routerProvider).go('/profile/settings');
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('settings-version')),
        );
        await tester.pumpAndSettle();
        await capturePng(tester, 'settings-version-row-$mode.png');

        // 4. WhatsNewSheet
        unawaited(
          showWhatsNewSheet(
            tester.element(find.byKey(const ValueKey('settings-version'))),
            version: SemVer.tryParse('1.1.0'),
            notes: currentManifest.notes.vi,
            markSeen: false,
          ),
        );
        await tester.pumpAndSettle();
        await capturePng(tester, 'whats-new-sheet-$mode.png');
        await tester.tap(find.byKey(const ValueKey('update-whats-new-done')));
        await tester.pumpAndSettle();

        // 5. UpdateGateScreen (forced)
        currentManifest = buildTestManifest(
          latest: '2.0.0',
          minSupported: '2.0.0',
        );
        await c
            .read(appUpdateControllerProvider.notifier)
            .refresh(manual: true);
        await tester.pumpAndSettle();
        await capturePng(tester, 'update-gate-$mode.png');
        c.invalidate(appUpdateControllerProvider);
      });
    }
  }
}
