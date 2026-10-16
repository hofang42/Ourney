// /capture inside the real router and tab shell (A3).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/camera/camera_session.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart';

void main() {
  testWidgets('camera is released on another tab and reopened on return', (
    tester,
  ) async {
    final camera = FakeCameraSession();
    await pumpOurneyApp(
      tester,
      overrides: [
        journeyRepositoryProvider.overrideWithValue(FakeJourneyRepository()),
        cameraSessionFactoryProvider.overrideWithValue(() => camera),
      ],
    );
    // First launch: the in-context pre-prompt comes before the OS prompt.
    await tester.tap(find.text('Cho phép camera'));
    await tester.pumpAndSettle();
    expect(camera.starts, 1);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);

    await tester.tap(find.text('Journeys'));
    await tester.pumpAndSettle();
    expect(camera.stops, greaterThanOrEqualTo(1));
    expect(camera.isReady, isFalse);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pumpAndSettle();
    expect(camera.starts, 2);
    expect(camera.isReady, isTrue);
  });
}
