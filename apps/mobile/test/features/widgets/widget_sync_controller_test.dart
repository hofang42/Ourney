import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/account_reset.dart';
import 'package:ourney/app/locale_override.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/groups/data/groups_providers.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney/features/widgets/data/widget_bridge_gateway.dart';
import 'package:ourney/features/widgets/data/widget_sync_controller.dart';
import 'package:ourney/features/widgets/data/widget_thumb_preparer.dart';
import 'package:ourney/features/widgets/domain/widget_privacy.dart';
import 'package:ourney/features/widgets/domain/widget_snapshot.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:path/path.dart' as p;

import '../../app/test_helpers.dart';
import '../reminders/reminders_fakes.dart';

class _NoOpThumbPreparer implements WidgetThumbPreparer {
  int clearCacheCount = 0;

  @override
  Future<List<WidgetThumbPayload>> prepare(
    List<WidgetThumbRequest> requests,
  ) async => [
    for (final r in requests)
      WidgetThumbPayload(
        id: r.id,
        sourcePath: '/tmp/${r.id}',
        maxSide: r.maxSide,
        blur: r.blur,
      ),
  ];

  @override
  Future<void> clearCache() async {
    clearCacheCount++;
  }
}

class _SignedInUser extends CurrentUserId {
  @override
  String? build() => 'user-a';

  void signOut() => state = null;
}

void main() {
  const journeyId = '6f8c9a10-0000-4000-8000-000000000001';
  // 2026-11-24 14:05 UTC == 21:05 ICT (inside evening window).
  final fixedNow = DateTime.utc(2026, 11, 24, 14, 5);

  test(
    'coalesces rapid scheduleSync calls, suppresses duplicate SHA-256 syncs, '
    'consumes native state.json, and calls clearAll() on resetAccountLocalState (§4.5, §8.3)',
    () async {
      final prefs = await testPrefs({
        WidgetPrefs.photoMode: 'smart',
        WidgetPrefs.liveActivityEnabled: true,
      });
      final fakeBridge = FakeWidgetBridgeGateway();
      final thumbPreparer = _NoOpThumbPreparer();
      final journey = Journey(
        id: journeyId,
        ownerId: 'user-a',
        kind: JourneyKind.solo,
        templateId: TemplateId.englishDaily,
        title: 'Tự học IELTS 30 ngày',
        emoji: '',
        startDate: const LocalDate(2026, 11, 10),
        durationDays: 30,
        timezone: 'Asia/Ho_Chi_Minh',
        visibility: JourneyVisibility.private,
        status: JourneyStatus.active,
      );
      final checkInRepo = FakeReminderCheckInRepository()
        ..byJourney[journeyId] = [
          CheckIn(
            id: 'c-yesterday',
            journeyId: journeyId,
            userId: 'user-a',
            localDate: const LocalDate(2026, 11, 23),
            capturedAt: DateTime.utc(2026, 11, 23, 10),
            photoPath: 'checkins/j1/u1/c1.jpg',
            thumbPath: 'checkins/j1/u1/c1_t.jpg',
          ),
        ];

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testBackendConfig),
          sharedPreferencesProvider.overrideWithValue(prefs),
          supabaseClientProvider.overrideWithValue(null),
          currentUserIdProvider.overrideWith(_SignedInUser.new),
          widgetBridgeGatewayProvider.overrideWithValue(fakeBridge),
          widgetThumbPreparerProvider.overrideWithValue(thumbPreparer),
          journeyRepositoryProvider.overrideWithValue(
            FakeReminderJourneyRepository([journey]),
          ),
          checkInRepositoryProvider.overrideWithValue(checkInRepo),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(granted: true),
          ),
          reminderDeviceTimezoneProvider.overrideWith(
            (ref) async => 'Asia/Ho_Chi_Minh',
          ),
          journeysClockProvider.overrideWithValue(Clock.fixed(fixedNow)),
          remindersClockProvider.overrideWithValue(Clock.fixed(fixedNow)),
          widgetsClockProvider.overrideWithValue(Clock.fixed(fixedNow)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(accountSessionResetProvider, (_, _) {});

      final controller = container.read(widgetSyncControllerProvider);

      // 1. Rapidly schedule 5 syncs inside the 250ms window -> coalesced to 1!
      for (var i = 0; i < 5; i++) {
        controller.scheduleSync();
      }
      expect(fakeBridge.snapshotSyncs, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 320));
      await pumpEventQueue();
      expect(fakeBridge.snapshotSyncs, hasLength(1));
      expect(fakeBridge.liveActivitySyncs, hasLength(1));
      expect(fakeBridge.liveActivitySyncs.single, isNotNull);

      final firstJson =
          jsonDecode(fakeBridge.snapshotSyncs.single.snapshotJson)
              as Map<String, Object?>;
      expect(firstJson['schemaVersion'], 1);
      expect(firstJson['authState'], 'ready');

      // 2. Calling syncNow() again when nothing changed -> 0 platform channel calls!
      await controller.syncNow();
      expect(
        fakeBridge.snapshotSyncs,
        hasLength(1),
        reason: 'SHA-256 digest deduplication must suppress identical snapshot',
      );
      expect(
        fakeBridge.liveActivitySyncs,
        hasLength(1),
        reason: 'SHA-256 digest deduplication must suppress identical live activity',
      );

      // 3. Changing photoMode -> produces a new digest and triggers sync #2.
      await container
          .read(widgetPhotoModeProvider.notifier)
          .set(WidgetPhotoMode.blurred);
      await controller.syncNow();
      expect(fakeBridge.snapshotSyncs, hasLength(2));

      // 4. Native state.json reports dismissedWindowKey -> suppresses Live Activity.
      fakeBridge.pendingWidgetState = {
        'dismissedWindowKey': '2026-11-24:$journeyId',
      };
      await controller.syncNow(consumeNativeState: true);
      expect(
        container.read(dismissedLiveWindowKeyProvider),
        '2026-11-24:$journeyId',
      );
      expect(fakeBridge.liveActivitySyncs.last, isNull);

      // 5. Sign-out triggers resetAccountLocalState -> wipes prefs & calls clearAll().
      (container.read(currentUserIdProvider.notifier) as _SignedInUser)
          .signOut();
      await pumpEventQueue();

      expect(fakeBridge.clearAllCount, greaterThanOrEqualTo(1));
      expect(thumbPreparer.clearCacheCount, greaterThanOrEqualTo(1));
      expect(container.read(widgetPhotoModeProvider), WidgetPhotoMode.smart);
      expect(container.read(dismissedLiveWindowKeyProvider), isNull);
    },
  );

  test(
    'resolves device English locale when localeOverrideProvider is null and '
    'awaits reminderDeviceTimezoneProvider on cold start (P1-2)',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final binding = TestWidgetsFlutterBinding.instance;
      binding.platformDispatcher.localeTestValue = const Locale('en', 'US');
      addTearDown(binding.platformDispatcher.clearLocaleTestValue);

      final prefs = await testPrefs();
      final fakeBridge = FakeWidgetBridgeGateway();
      final thumbPreparer = _NoOpThumbPreparer();
      final journey = Journey(
        id: journeyId,
        ownerId: 'user-a',
        kind: JourneyKind.solo,
        templateId: TemplateId.englishDaily,
        title: 'Daily English',
        emoji: '',
        startDate: const LocalDate(2026, 11, 10),
        durationDays: 30,
        timezone: 'Asia/Ho_Chi_Minh',
        visibility: JourneyVisibility.private,
        status: JourneyStatus.active,
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testBackendConfig),
          sharedPreferencesProvider.overrideWithValue(prefs),
          supabaseClientProvider.overrideWithValue(null),
          currentUserIdProvider.overrideWith(_SignedInUser.new),
          widgetBridgeGatewayProvider.overrideWithValue(fakeBridge),
          widgetThumbPreparerProvider.overrideWithValue(thumbPreparer),
          journeyRepositoryProvider.overrideWithValue(
            FakeReminderJourneyRepository([journey]),
          ),
          checkInRepositoryProvider.overrideWithValue(
            FakeReminderCheckInRepository(),
          ),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(granted: true),
          ),
          reminderDeviceTimezoneProvider.overrideWith((ref) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 'America/New_York';
          }),
          journeysClockProvider.overrideWithValue(Clock.fixed(fixedNow)),
          remindersClockProvider.overrideWithValue(Clock.fixed(fixedNow)),
          widgetsClockProvider.overrideWithValue(Clock.fixed(fixedNow)),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(widgetSyncControllerProvider);
      await controller.syncNow();

      expect(fakeBridge.snapshotSyncs, hasLength(1));
      final snapJson =
          jsonDecode(fakeBridge.snapshotSyncs.single.snapshotJson)
              as Map<String, Object?>;
      expect(snapJson['locale'], 'en');

      // Explicit Vietnamese override wins over English device locale.
      await container
          .read(localeOverrideProvider.notifier)
          .set(const Locale('vi'));
      await controller.syncNow();
      expect(fakeBridge.snapshotSyncs, hasLength(2));
      final viJson =
          jsonDecode(fakeBridge.snapshotSyncs.last.snapshotJson)
              as Map<String, Object?>;
      expect(viJson['locale'], 'vi');
    },
  );

  testWidgets(
    'WidgetLifecycleHook triggers sync on block/unblock, membership.blurMedia toggle, and check-in delete/import (P1-5)',
    (tester) async {
      final prefs = await testPrefs();
      final fakeBridge = FakeWidgetBridgeGateway();
      final thumbPreparer = _NoOpThumbPreparer();

      final blockedController = StreamController<Set<String>>.broadcast();
      final membershipController = StreamController<Membership?>.broadcast();
      final checkInsController = StreamController<List<CheckIn>>.broadcast();
      addTearDown(() async {
        await blockedController.close();
        await membershipController.close();
        await checkInsController.close();
      });

      final groupJourney = Journey(
        id: journeyId,
        ownerId: 'user-a',
        kind: JourneyKind.group,
        templateId: TemplateId.englishDaily,
        title: 'Squad IELTS',
        emoji: '',
        startDate: const LocalDate(2026, 11, 10),
        durationDays: 30,
        timezone: 'Asia/Ho_Chi_Minh',
        visibility: JourneyVisibility.group,
        status: JourneyStatus.active,
      );

      final checkIn1 = CheckIn(
        id: 'c-1',
        journeyId: journeyId,
        userId: 'user-a',
        localDate: const LocalDate(2026, 11, 24),
        capturedAt: DateTime.utc(2026, 11, 24, 9),
        photoPath: 'checkins/j1/u1/c1.jpg',
        thumbPath: 'checkins/j1/u1/c1_t.jpg',
      );
      final friendMember = MemberToday(
        userId: 'user-friend',
        displayName: 'Minh',
        role: MemberRole.member,
        currentStreak: 3,
        todayCheckIn: CheckIn(
          id: 'c-friend',
          journeyId: journeyId,
          userId: 'user-friend',
          localDate: const LocalDate(2026, 11, 24),
          capturedAt: DateTime.utc(2026, 11, 24, 8),
          photoPath: 'checkins/j1/uf/cf.jpg',
          thumbPath: 'checkins/j1/uf/cf_t.jpg',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(testBackendConfig),
          sharedPreferencesProvider.overrideWithValue(prefs),
          supabaseClientProvider.overrideWithValue(null),
          currentUserIdProvider.overrideWith(_SignedInUser.new),
          widgetBridgeGatewayProvider.overrideWithValue(fakeBridge),
          widgetThumbPreparerProvider.overrideWithValue(thumbPreparer),
          journeyRepositoryProvider.overrideWithValue(
            FakeReminderJourneyRepository([groupJourney]),
          ),
          checkInRepositoryProvider.overrideWithValue(
            FakeReminderCheckInRepository(),
          ),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(granted: true),
          ),
          reminderDeviceTimezoneProvider.overrideWith(
            (ref) async => 'Asia/Ho_Chi_Minh',
          ),
          journeysClockProvider.overrideWithValue(Clock.fixed(fixedNow)),
          remindersClockProvider.overrideWithValue(Clock.fixed(fixedNow)),
          widgetsClockProvider.overrideWithValue(Clock.fixed(fixedNow)),
          groupBlockedIdsProvider.overrideWith((ref) => blockedController.stream),
          myMembershipProvider(journeyId).overrideWith(
            (ref) => membershipController.stream,
          ),
          myCheckInsProvider(journeyId).overrideWith(
            (ref) => checkInsController.stream,
          ),
          groupTodayProvider(journeyId).overrideWith(
            (ref) => Stream.value([friendMember]),
          ),
          groupCheckInsProvider(journeyId).overrideWith(
            (ref) => Stream.value(const <CheckIn>[]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: WidgetLifecycleHook(child: SizedBox.shrink()),
          ),
        ),
      );
      // Pump once so journeysListProvider resolves and WidgetLifecycleHook
      // attaches listeners to per-journey membership and check-ins providers.
      await tester.pump();
      await tester.pump();

      blockedController.add(const <String>{});
      membershipController.add(
        Membership(
          journeyId: journeyId,
          userId: 'user-a',
          role: MemberRole.owner,
          status: MemberStatus.active,
          joinedAt: DateTime.utc(2026, 11, 10),
        ),
      );
      checkInsController.add([checkIn1]);
      await tester.pump();
      await tester.pump();

      final initialCount = fakeBridge.snapshotSyncs.length;
      expect(initialCount, greaterThanOrEqualTo(1));

      // 1. Toggle membership.blurMedia -> triggers sync with heroThumbBlurred: true.
      membershipController.add(
        Membership(
          journeyId: journeyId,
          userId: 'user-a',
          role: MemberRole.owner,
          status: MemberStatus.active,
          joinedAt: DateTime.utc(2026, 11, 10),
          blurMedia: true,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(fakeBridge.snapshotSyncs.length, greaterThan(initialCount));
      expect(
        container
            .read(widgetSyncControllerProvider)
            .lastSnapshot!
            .journeys
            .single
            .heroThumbBlurred,
        isTrue,
      );

      // 2. Block user-friend -> triggers sync stripping user-friend from squad.
      final beforeBlockCount = fakeBridge.snapshotSyncs.length;
      blockedController.add(const {'user-friend'});
      await tester.pump();
      await tester.pump();
      expect(fakeBridge.snapshotSyncs.length, greaterThan(beforeBlockCount));
      expect(
        container
            .read(widgetSyncControllerProvider)
            .lastSnapshot!
            .squads
            .single
            .members,
        isEmpty,
      );

      // 3. Delete check-in -> triggers sync flipping checkedInToday to false.
      final beforeDeleteCount = fakeBridge.snapshotSyncs.length;
      checkInsController.add(const []);
      await tester.pump();
      await tester.pump();
      expect(fakeBridge.snapshotSyncs.length, greaterThan(beforeDeleteCount));
      expect(
        container
            .read(widgetSyncControllerProvider)
            .lastSnapshot!
            .journeys
            .single
            .checkedInToday,
        isFalse,
      );
    },
  );

  group('MethodChannelWidgetBridgeGateway (P2-2)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const gateway = MethodChannelWidgetBridgeGateway();

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannelWidgetBridgeGateway.channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'returns false / null / WidgetCapabilities.unsupported on MissingPluginException',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              MethodChannelWidgetBridgeGateway.channel,
              (call) async => throw MissingPluginException('no handler'),
            );

        expect(
          await gateway.syncSnapshot(snapshotJson: '{}', thumbs: const []),
          isFalse,
        );
        expect(await gateway.syncLiveActivity(const {'a': 1}), isFalse);
        expect(await gateway.clearAll(), isFalse);
        expect(await gateway.consumeWidgetState(), isNull);
        expect(
          await gateway.getCapabilities(),
          WidgetCapabilities.unsupported,
        );
      },
    );

    test('invokes channel methods and parses responses on Android/iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannelWidgetBridgeGateway.channel,
            (call) async {
              calls.add(call);
              return switch (call.method) {
                'syncSnapshot' => true,
                'syncLiveActivity' => true,
                'clearAll' => true,
                'consumeWidgetState' => <Object?, Object?>{
                  'dismissedWindowKey': '2026-11-24:j1',
                  42: 'ignored-non-string-key',
                },
                'getCapabilities' => <Object?, Object?>{
                  'widgets': true,
                  'liveActivity': true,
                  'promotedLiveUpdates': false,
                  'appGroup': false,
                },
                _ => null,
              };
            },
          );

      const thumb = WidgetThumbPayload(
        id: 'abc.jpg',
        sourcePath: '/tmp/abc.jpg',
        maxSide: 320,
        blur: false,
      );
      expect(
        await gateway.syncSnapshot(snapshotJson: '{"ok":true}', thumbs: [thumb]),
        isTrue,
      );
      expect(await gateway.syncLiveActivity(null), isTrue);
      expect(await gateway.clearAll(), isTrue);
      expect(await gateway.consumeWidgetState(), {
        'dismissedWindowKey': '2026-11-24:j1',
      });
      expect(
        await gateway.getCapabilities(),
        const WidgetCapabilities(
          widgets: true,
          liveActivity: true,
          promotedLiveUpdates: false,
          appGroup: false,
        ),
      );
      expect(calls.map((c) => c.method).toList(), [
        'syncSnapshot',
        'syncLiveActivity',
        'clearAll',
        'consumeWidgetState',
        'getCapabilities',
      ]);
    });

    test('short-circuits on unsupported desktop platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
        await gateway.syncSnapshot(snapshotJson: '{}', thumbs: const []),
        isFalse,
      );
      expect(await gateway.getCapabilities(), WidgetCapabilities.unsupported);
    });
  });

  group('LocalWidgetThumbPreparer (P1-4, P2-2)', () {
    late Directory tempRoot;
    late ProviderContainer container;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('ourney_widget_thumb_test_');
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test(
      'fails closed when blur fails (never leaks raw unblurred sourcePath) and sets blur: false on pre-blurred payload',
      () async {
        final rawFile = File(p.join(tempRoot.path, 'raw_secret.jpg'))
          ..writeAsBytesSync([1, 2, 3, 4]);

        final blurReq = WidgetThumbRequest(
          id: 'blurred_1234.jpg',
          storagePath: rawFile.path,
          localFilePath: rawFile.path,
          maxSide: 320,
          blur: true,
        );

        // 1. When blurRenderer returns null (failure), prepare() MUST fail closed (empty list).
        final failingPreparer = LocalWidgetThumbPreparer(
          container.read( Provider((ref) => ref) ),
          tempDirProvider: () async => tempRoot,
          blurRenderer: ({
            required sourcePath,
            required targetPath,
            required maxSide,
          }) async => null,
        );
        final failedResult = await failingPreparer.prepare([blurReq]);
        expect(failedResult, isEmpty);

        // 2. When enableNativeTransforms is false and no blurRenderer is given, also fails closed.
        final disabledPreparer = LocalWidgetThumbPreparer(
          container.read(Provider((ref) => ref)),
          tempDirProvider: () async => tempRoot,
          enableNativeTransforms: false,
        );
        expect(await disabledPreparer.prepare([blurReq]), isEmpty);

        // 3. When blurRenderer succeeds, emits blurred targetPath with blur: false (no double-blur)
        // and reuses cached file on subsequent call + prunes orphans.
        var blurCalls = 0;
        final orphanFile = File(
          p.join(tempRoot.path, kWidgetThumbsTempDirName, 'stale_orphan.jpg'),
        )..createSync(recursive: true)..writeAsBytesSync([9, 9]);

        final workingPreparer = LocalWidgetThumbPreparer(
          container.read(Provider((ref) => ref)),
          tempDirProvider: () async => tempRoot,
          blurRenderer: ({
            required sourcePath,
            required targetPath,
            required maxSide,
          }) async {
            blurCalls++;
            final f = File(targetPath)..writeAsBytesSync([7, 8, 9]);
            return f.path;
          },
        );

        final firstPass = await workingPreparer.prepare([blurReq]);
        expect(firstPass, hasLength(1));
        expect(firstPass.single.id, 'blurred_1234.jpg');
        expect(firstPass.single.sourcePath, isNot(rawFile.path));
        expect(firstPass.single.blur, isFalse);
        expect(blurCalls, 1);
        expect(orphanFile.existsSync(), isFalse);

        // Second pass hits the cached file in <temp>/widget_thumbs/ without calling blurRenderer.
        final secondPass = await workingPreparer.prepare([blurReq]);
        expect(secondPass, hasLength(1));
        expect(blurCalls, 1);

        // clearCache() removes <temp>/widget_thumbs/.
        await workingPreparer.clearCache();
        expect(
          Directory(p.join(tempRoot.path, kWidgetThumbsTempDirName)).existsSync(),
          isFalse,
        );
      },
    );
  });
}
