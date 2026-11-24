import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/account_reset.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney/features/widgets/data/widget_bridge_gateway.dart';
import 'package:ourney/features/widgets/data/widget_sync_controller.dart';
import 'package:ourney/features/widgets/data/widget_thumb_preparer.dart';
import 'package:ourney/features/widgets/domain/widget_privacy.dart';
import 'package:ourney/features/widgets/domain/widget_snapshot.dart';
import 'package:ourney_core/ourney_core.dart';

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
}
