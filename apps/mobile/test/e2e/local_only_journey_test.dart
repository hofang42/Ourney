// End-to-end (Wave D): the real app, router and data layer in local-only
// mode (in-memory drift database, media on a temp dir). Only the platform
// edges are faked: camera, photo compressor, notifications, device zone.
//
// fresh install -> onboarding -> capture (no journey: CTA) -> create journey
// -> capture -> check-in -> journeys timeline shows the day -> share card.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/data/data_providers.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney/shared/time_zones.dart';
import 'package:ourney_core/ourney_core.dart';

import '../app/test_helpers.dart';
import '../data/data_test_helpers.dart' show memoryDb, tempDir;
import '../features/checkin/fakes.dart' show FakeCameraSession, FakeDraftFiles;
import '../features/reminders/reminders_fakes.dart'
    show FakeNotificationGateway;

const _zone = 'Asia/Ho_Chi_Minh';

/// 1x1 PNG: a decodable image for the timeline and share card.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// Writes real files (the repository copies them into the media store).
class _DiskCompressor implements PhotoCompressor {
  _DiskCompressor(this.dir);

  final Directory dir;
  int n = 0;

  @override
  Future<CompressedPhoto> compress(String sourcePath) async {
    n++;
    final photo = File('${dir.path}/draft$n.jpg')..writeAsBytesSync(_png);
    final thumb = File('${dir.path}/draft${n}_t.jpg')..writeAsBytesSync(_png);
    return CompressedPhoto(photoFile: photo.path, thumbFile: thumb.path);
  }
}

void main() {
  testWidgets('local-only: first journey, first check-in, share card', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(420, 1800);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final camera = FakeCameraSession();
    final notifications = FakeNotificationGateway(granted: true);
    final drafts = tempDir();
    final c = await pumpOurneyApp(
      tester,
      onboarded: false,
      overrides: [
        ...dataOverrides(
          DataEnvironment(
            db: memoryDb(),
            mediaRoot: Directory('${tempDir().path}/media'),
            listenLifecycle: false,
            autoSync: false,
          ),
        ),
        cameraSessionFactoryProvider.overrideWithValue(() => camera),
        photoCompressorProvider.overrideWithValue(_DiskCompressor(drafts)),
        draftFilesProvider.overrideWithValue(FakeDraftFiles()),
        notificationGatewayProvider.overrideWithValue(notifications),
        deviceTimezoneProvider.overrideWith((ref) async => _zone),
        reminderDeviceTimezoneProvider.overrideWith((ref) async => _zone),
      ],
    );
    final router = c.read(routerProvider);
    String path() => router.state.uri.path;
    Finder key(String k) => find.byKey(ValueKey(k));

    // Drift queries and file copies complete on the real event loop, so
    // alternate real waits with frames (bounded: a spinner never settles).
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> tap(String k) async {
      await tester.ensureVisible(key(k));
      await tester.pump();
      await tester.tap(key(k));
      await settle();
    }

    // Fresh install: onboarding first.
    expect(path(), AppRoutes.onboarding);
    await tap('onboarding-skip');
    expect(path(), AppRoutes.capture);
    await settle();

    // No journey yet: the camera stays off and offers to create one.
    expect(key('capture-no-journeys'), findsOneWidget);
    expect(camera.starts, 0);
    await tester.tap(find.text('Tạo hành trình'));
    await settle();
    expect(key('journeys-template-picker'), findsOneWidget);

    await tap('template-${TemplateId.workout30.wireName}');
    expect(key('journeys-create'), findsOneWidget);
    await tap('journey-create');
    expect(path(), startsWith('/journey/'));
    final journeyId = path().split('/').last;
    final journeys = await tester.runAsync(
      () => c.read(journeyRepositoryProvider).watchActive().first,
    );
    expect(journeys!.single.id, journeyId);
    expect(journeys.single.timezone, _zone);
    expect(notifications.scheduled, isEmpty, reason: 'no streak to protect');

    // "Check in now" -> capture: the camera opens after the pre-prompt.
    await tap('journey-checkin');
    expect(path(), AppRoutes.capture);
    await tester.tap(find.text('Cho phép camera'));
    await settle();
    expect(camera.isReady, isTrue);
    expect(key('journey-chip-$journeyId'), findsOneWidget);

    await tap('capture-shutter');
    expect(path(), AppRoutes.checkin);
    await tester.tap(key('checkin-post'));
    await waitFor(key('checkin-success'));
    expect(key('checkin-success'), findsOneWidget);
    await tap('checkin-done');
    expect(path(), AppRoutes.capture);

    final now = DateTime.now();
    final today = localDateOf(now, timeZoneOffsetAt(_zone, now));
    final saved = await tester.runAsync(
      () => c.read(checkInRepositoryProvider).watchForJourney(journeyId).first,
    );
    expect(saved!.single.localDate, today);
    expect(File(saved.single.localPhotoFile!).existsSync(), isTrue);

    // Reminders were rescheduled after the check-in: the 21:00 alert now
    // protects tomorrow, nothing is left for today.
    await settle();
    expect(notifications.scheduled, isNotEmpty);
    expect(
      notifications.scheduled.values.map(
        (n) => localDateOf(n.fireAt, timeZoneOffsetAt(_zone, n.fireAt)),
      ),
      everyElement(isNot(today)),
    );

    // Journeys tab: the timeline shows the day as checked in.
    await tester.tap(find.text('Journeys'));
    await settle();
    expect(path(), AppRoutes.journey(journeyId));
    expect(key('journey-timeline'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(
      tester.getSemantics(key('day-$today')),
      isSemantics(isButton: true),
      reason: 'only checked-in days are tappable',
    );
    semantics.dispose();

    // Share card renders for the journey.
    await tap('journey-share');
    expect(path(), AppRoutes.share(journeyId));
    expect(key('share-card-screen'), findsOneWidget);
    expect(key('share-card-preview-story'), findsOneWidget);
  });
}
