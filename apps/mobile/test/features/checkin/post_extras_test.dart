import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/camera/capture_services.dart';
import 'package:ourney/features/checkin/captured_photo.dart';
import 'package:ourney/features/checkin/checkin_clock.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/checkin/post_extras.dart';
import 'package:ourney/features/checkin/routes.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'fakes.dart';

class _FakeGallery implements GalleryPicker {
  @override
  Future<String?> pickPhoto() async => '/tmp/partner.jpg';
}

void main() {
  late FakeCheckInRepository checkIns;
  late FakePhotoCompressor compressor;

  final photo = CapturedPhoto(
    journeyId: 'j1',
    path: '/tmp/shot.jpg',
    capturedAt: testNowUtc,
  );

  Future<void> pump(WidgetTester tester, Journey journey) async {
    final prefs = await testPrefs(const {});
    checkIns = FakeCheckInRepository();
    compressor = FakePhotoCompressor();
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(journeys: [journey]),
          checkIns: checkIns,
        ),
        photoCompressorProvider.overrideWithValue(compressor),
        checkinClockProvider.overrideWithValue(FakeCheckinClock()),
        galleryPickerProvider.overrideWithValue(_FakeGallery()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      routedTestApp(
        container: container,
        routes: checkinRoutes,
        initialLocation: '/checkin',
        initialExtra: photo,
        log: RouteLog(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> post(WidgetTester tester) async {
    await tapKey(tester, 'checkin-post');
    await tester.pump();
  }

  test('paceFromDigits fills m:ss from the right', () {
    expect(paceFromDigits(''), '');
    expect(paceFromDigits('5'), '0:05');
    expect(paceFromDigits('504'), '5:04');
    expect(paceFromDigits('1230'), '12:30');
  });

  testWidgets('study skin posts the picked minutes', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.englishDaily));
    await tapKey(tester, 'checkin-minutes-45');
    await post(tester);
    expect(checkIns.submitted.single.extras, const CheckInExtras(minutes: 45));
  });

  testWidgets('quiet skin posts the mood code', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.weightLoss));
    await tapKey(tester, 'checkin-mood-tired');
    await post(tester);
    expect(
      checkIns.submitted.single.extras,
      const CheckInExtras(mood: 'tired'),
    );
  });

  testWidgets('memory skin posts the place', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.travel));
    await tester.enterText(
      find.byKey(const ValueKey('checkin-place')),
      ' Đà Lạt ',
    );
    await post(tester);
    expect(
      checkIns.submitted.single.extras,
      const CheckInExtras(place: 'Đà Lạt'),
    );
  });

  testWidgets('flexer keypad posts the typed pace', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.workout30));
    for (final d in ['5', '0', '4']) {
      await tapKey(tester, 'checkin-pace-key-$d');
    }
    expect(find.text('5:04'), findsOneWidget);
    await post(tester);
    expect(checkIns.submitted.single.extras, const CheckInExtras(pace: '5:04'));
  });

  testWidgets('flexer pace with seconds over 59 blocks Post', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.workout30));
    await tapKey(tester, 'checkin-pace-key-9');
    await tapKey(tester, 'checkin-pace-key-9');
    expect(find.byKey(const ValueKey('checkin-pace-error')), findsOneWidget);
    await post(tester);
    expect(checkIns.submitted, isEmpty);
    await tapKey(tester, 'checkin-pace-backspace');
    expect(find.byKey(const ValueKey('checkin-pace-error')), findsNothing);
  });

  testWidgets('couple skin posts dish, cook, hearts and the partner photo', (
    tester,
  ) async {
    final journey = Journey(
      id: 'j1',
      ownerId: 'me',
      kind: JourneyKind.solo,
      templateId: TemplateId.custom,
      title: 'Hai đứa',
      emoji: '💞',
      startDate: const LocalDate(2026, 10, 1),
      durationDays: 30,
      timezone: 'Asia/Ho_Chi_Minh',
      visibility: JourneyVisibility.private,
      status: JourneyStatus.active,
      coupleSelfName: 'An',
      couplePartnerName: 'Bình',
    );
    await pump(tester, journey);
    await tester.enterText(find.byKey(const ValueKey('checkin-dish')), 'Phở');
    await tapKey(tester, 'checkin-cook-Bình');
    await tapKey(tester, 'checkin-heart-4');
    await tapKey(tester, 'checkin-partner-photo-add');
    await tester.pumpAndSettle();
    await post(tester);

    final draft = checkIns.submitted.single;
    expect(
      draft.extras,
      const CheckInExtras(dish: 'Phở', cook: 'Bình', hearts: 4),
    );
    expect(draft.partnerPhotoFile, '/tmp/partner.jpg.1080.jpg');
  });
}
