// Review finding: the camera stayed running when the screen was left while
// the controller was still initialising (fast tab switch / app hidden).
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart';
import '../reminders/reminders_fakes.dart' show FakeNotificationGateway;

const _back = CameraDescription(
  name: 'back',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

class _FakeController extends Fake implements CameraController {
  _FakeController(this.init);

  final Completer<void> init;
  bool initialized = false;
  bool disposed = false;

  @override
  CameraDescription get description => _back;

  @override
  CameraValue get value =>
      CameraValue.uninitialized(_back).copyWith(isInitialized: initialized);

  @override
  Future<void> initialize() async {
    await init.future;
    initialized = true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    initialized = false;
  }
}

/// Fake session whose start completes only when the test says so.
class _SlowCameraSession extends FakeCameraSession {
  final gates = <Completer<void>>[];

  @override
  Future<void> start({bool front = false}) async {
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    await super.start(front: front);
  }
}

void main() {
  group('PluginCameraSession serialises start/stop', () {
    late List<_FakeController> controllers;
    late PluginCameraSession session;

    setUp(() {
      controllers = [];
      session = PluginCameraSession(
        cameras: () async => const [_back],
        createController: (_) {
          final c = _FakeController(Completer<void>());
          controllers.add(c);
          return c;
        },
      );
    });

    test('stop during initialize disposes the new controller', () async {
      final starting = session.start();
      await pumpEventQueue();
      expect(controllers, hasLength(1));
      final stopped = session.stop(); // arrives mid-initialize
      controllers.single.init.complete();
      await starting;
      await stopped;
      expect(controllers.single.disposed, isTrue);
      expect(session.isReady, isFalse);
    });

    test('start, stop, start: only the last start keeps a camera', () async {
      final first = session.start();
      final stop = session.stop();
      final second = session.start();
      await pumpEventQueue();
      // The first start was superseded before it created a controller.
      expect(controllers, hasLength(1));
      controllers.single.init.complete();
      await Future.wait([first, stop, second]);
      expect(session.isReady, isTrue);
      await session.stop();
      expect(controllers.single.disposed, isTrue);
      expect(session.isReady, isFalse);
    });
  });

  testWidgets('leaving the tab while the camera starts releases it', (
    tester,
  ) async {
    final camera = _SlowCameraSession();
    await pumpOurneyApp(
      tester,
      overrides: [
        journeyRepositoryProvider.overrideWithValue(FakeJourneyRepository()),
        cameraSessionFactoryProvider.overrideWithValue(() => camera),
        notificationGatewayProvider.overrideWithValue(
          FakeNotificationGateway(),
        ),
      ],
    );
    await tester.tap(find.text('Cho phép camera'));
    await tester.pump();
    expect(camera.gates, hasLength(1), reason: 'start is in flight');

    // Leave before the camera finished opening.
    await tester.tap(find.text('Journeys'));
    await tester.pump();
    camera.gates.single.complete();
    await tester.pumpAndSettle();
    expect(camera.isReady, isFalse, reason: 'stale start must not keep it');
    expect(camera.stops, greaterThanOrEqualTo(1));

    // Coming back opens it again.
    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pump();
    camera.gates.last.complete();
    await tester.pumpAndSettle();
    expect(camera.isReady, isTrue);
  });
}
