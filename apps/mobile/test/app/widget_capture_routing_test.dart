import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/journey_clock.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/camera/camera_providers.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/camera/capture_screen.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/ui/ui.dart';

import '../features/checkin/fakes.dart';
import '../features/reminders/reminders_fakes.dart';
import 'test_helpers.dart';

const tripLink = 'ourney://capture?journeyId=trip';

void main() {
  Future<ProviderContainer> pumpApp(WidgetTester tester) => pumpOurneyApp(
    tester,
    locale: const Locale('en'),
    initialPrefs: {
      ActiveJourneyId.prefsKey: 'other',
      CameraPrefs.permissionAsked: true,
    },
    overrides: [
      journeysClockProvider.overrideWithValue(Clock.fixed(reminderNow)),
      journeyRepositoryProvider.overrideWithValue(
        FakeReminderJourneyRepository([
          reminderJourney(id: 'other', title: 'Other Journey'),
          reminderJourney(id: 'trip', title: 'Trip', durationDays: 16),
        ]),
      ),
      checkInRepositoryProvider.overrideWithValue(
        FakeReminderCheckInRepository(),
      ),
      notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
      cameraSessionFactoryProvider.overrideWithValue(FakeCameraSession.new),
    ],
  );

  void expectTripCamera(ProviderContainer container) {
    final uri = container.read(routerProvider).state.uri;
    expect(uri.path, AppRoutes.capture);
    expect(uri.queryParameters['journeyId'], 'trip');
    expect(container.read(activeJourneyIdProvider), 'trip');
    expect(
      find.byWidgetPredicate(
        (widget) => widget is UiShutter && widget.label.contains('Trip'),
      ),
      findsOneWidget,
    );
  }

  Future<void> openPlatformLink(WidgetTester tester, String url) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.navigation.name,
      SystemChannels.navigation.codec.encodeMethodCall(
        MethodCall('pushRouteInformation', {'location': url}),
      ),
      null,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cold widget tap opens the displayed trip instead of the remembered journey',
    (tester) async {
      tester.platformDispatcher.defaultRouteNameTestValue = tripLink;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);

      final container = await pumpApp(tester);

      expectTripCamera(container);
    },
  );

  testWidgets(
    'warm widget tap reselects the trip even when its camera URL is already open',
    (tester) async {
      final container = await pumpApp(tester);
      expect(container.read(activeJourneyIdProvider), 'other');
      await openPlatformLink(tester, tripLink);
      expectTripCamera(container);

      await container.read(activeJourneyIdProvider.notifier).select('other');
      await tester.pumpAndSettle();
      expect(container.read(activeJourneyIdProvider), 'other');

      await openPlatformLink(tester, tripLink);
      expectTripCamera(container);
    },
  );

  testWidgets(
    'a stale widget link never enables capture for a different journey',
    (tester) async {
      final container = await pumpApp(tester);
      await openPlatformLink(tester, 'ourney://capture?journeyId=gone');

      expect(container.read(routerProvider).state.uri.path, AppRoutes.capture);
      expect(
        container.read(routerProvider).state.uri.queryParameters['journeyId'],
        'gone',
      );
      expect(container.read(activeJourneyIdProvider), 'gone');
      expect(
        tester
            .widget<CaptureScreen>(find.byType(CaptureScreen))
            .initialJourneyId,
        'gone',
      );
      final shutter = tester.widget<UiShutter>(
        find.byKey(const ValueKey('capture-shutter')),
      );
      expect(shutter.onPressed, isNull);
      expect(shutter.label, isNot(contains('Other Journey')));
    },
  );
}
