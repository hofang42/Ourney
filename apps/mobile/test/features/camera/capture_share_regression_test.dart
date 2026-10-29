// Regression (review finding: shutter stuck after Share). The capture
// screen used to await `context.push('/checkin')` and keep `_busy` until it
// completed; the check-in success "Share" used `pushReplacement`, which in
// go_router 18 never completes that future, so the shutter stayed disabled.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/checkin/checkin_clock.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart';
import '../reminders/reminders_fakes.dart' show FakeNotificationGateway;

void main() {
  testWidgets('shutter works again after Share from the check-in success', (
    tester,
  ) async {
    // The capture screen stamps photos with the global `clock`; pin it to the
    // fixtures' day so the 7-day milestone (and its Share button) does not
    // depend on the date the test runs.
    await withClock(Clock.fixed(testNowUtc), () async {
      final camera = FakeCameraSession();
      // Six earlier days: today's check-in is a 7-day milestone (share offer).
      final checkIns = FakeCheckInRepository(
        existing: [
          for (var i = 1; i <= 6; i++) testCheckIn(testToday.addDays(-i)),
        ],
      );
      final drafts = FakeDraftFiles();
      final c = await pumpOurneyApp(
        tester,
        overrides: [
          journeyRepositoryProvider.overrideWithValue(FakeJourneyRepository()),
          checkInRepositoryProvider.overrideWithValue(checkIns),
          cameraSessionFactoryProvider.overrideWithValue(() => camera),
          photoCompressorProvider.overrideWithValue(FakePhotoCompressor()),
          checkinClockProvider.overrideWithValue(FakeCheckinClock()),
          draftFilesProvider.overrideWithValue(drafts),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
        ],
      );
      final router = c.read(routerProvider);
      await tester.tap(find.text('Cho phép camera'));
      await tester.pumpAndSettle();

      Future<void> shoot() async {
        await tester.tap(find.byKey(const ValueKey('capture-shutter')));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, AppRoutes.checkin);
      }

      await shoot();
      await tester.tap(find.byKey(const ValueKey('checkin-post')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('checkin-success')), findsOneWidget);
      // Compressed drafts and the raw camera file are cleaned up after submit.
      expect(drafts.discarded, [
        '/tmp/shot1.jpg.1080.jpg',
        '/tmp/shot1.jpg.thumb.jpg',
        '/tmp/shot1.jpg',
      ]);

      await tester.ensureVisible(find.byKey(const ValueKey('checkin-share')));
      await tester.tap(find.byKey(const ValueKey('checkin-share')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.share('j1'));

      // Back from the share card: straight to the camera (check-in was popped).
      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.capture);
      expect(camera.isReady, isTrue);

      await shoot();
      expect(camera.pictures, 2);
    });
  });

  testWidgets('closing the check-in without posting discards the photo', (
    tester,
  ) async {
    final drafts = FakeDraftFiles();
    final c = await pumpOurneyApp(
      tester,
      overrides: [
        journeyRepositoryProvider.overrideWithValue(FakeJourneyRepository()),
        checkInRepositoryProvider.overrideWithValue(FakeCheckInRepository()),
        cameraSessionFactoryProvider.overrideWithValue(FakeCameraSession.new),
        checkinClockProvider.overrideWithValue(FakeCheckinClock()),
        draftFilesProvider.overrideWithValue(drafts),
        notificationGatewayProvider.overrideWithValue(
          FakeNotificationGateway(),
        ),
      ],
    );
    await tester.tap(find.text('Cho phép camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('capture-shutter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.uri.path, AppRoutes.capture);
    expect(drafts.discarded, ['/tmp/shot1.jpg']);
    // And the shutter is enabled again.
    await tester.tap(find.byKey(const ValueKey('capture-shutter')));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.uri.path, AppRoutes.checkin);
  });
}
