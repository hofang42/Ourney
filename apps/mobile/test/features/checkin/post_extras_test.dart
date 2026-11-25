import 'dart:ui' show Tristate;

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

  Future<void> pump(
    WidgetTester tester,
    Journey journey, {
    List<Journey> previousTrips = const [],
  }) async {
    final prefs = await testPrefs(const {});
    checkIns = FakeCheckInRepository();
    compressor = FakePhotoCompressor();
    final container = ProviderContainer(
      overrides: [
        ...baseOverrides(
          prefs: prefs,
          journeys: FakeJourneyRepository(
            journeys: [journey, ...previousTrips],
          ),
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

  testWidgets(
    'memory skin suggests the trip destination before recent places',
    (tester) async {
      await pump(
        tester,
        testJourney(templateId: TemplateId.travel)
            .copyWith(dna: {'place': 'Hanoi'}),
        previousTrips: [
          testJourney(
            id: 'previous',
            templateId: TemplateId.travel,
            start: const LocalDate(2026, 9, 1),
          ).copyWith(dna: {'place': 'Phu Quoc'}),
        ],
      );
      final field = find.byKey(const ValueKey('checkin-place'));
      final semantics = tester.getSemantics(field);
      expect(semantics.flagsCollection.isTextField, isTrue);
      expect(semantics.label, startsWith('Bạn đang ở đâu?'));
      expect(semantics.flagsCollection.isExpanded, Tristate.isFalse);
      await tapKey(tester, 'checkin-place');
      expect(
        tester.getSemantics(field).flagsCollection.isExpanded,
        Tristate.isTrue,
      );
      final current = find.byKey(const ValueKey('vn-province-ha-noi'));
      final recent = find.byKey(const ValueKey('vn-destination-phu-quoc'));
      expect(
        tester.getTopLeft(current).dy,
        lessThan(tester.getTopLeft(recent).dy),
      );
      expect(find.bySemanticsLabel('Hanoi, Việt Nam'), findsOneWidget);
      expect(find.text('Phu Quoc'), findsOneWidget);
      await tapKey(tester, 'vn-province-ha-noi');
      await tester.pumpAndSettle();
      final selected = tester.getSemantics(field);
      expect(selected.flagsCollection.isTextField, isTrue);
      expect(selected.label, 'Bạn đang ở đâu?');
      expect(selected.value, 'Hanoi');
      expect(selected.flagsCollection.isExpanded, Tristate.isFalse);
      expect(find.bySemanticsLabel('Hanoi, Việt Nam'), findsNothing);
      await post(tester);
      expect(
        checkIns.submitted.single.extras,
        const CheckInExtras(place: 'Hanoi'),
      );
    },
  );

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

  testWidgets('flexer posts the typed distance with the pace', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.workout30));
    await tester.enterText(find.byKey(const ValueKey('checkin-km')), '5,3');
    await tapKey(tester, 'checkin-pace-key-5');
    await post(tester);
    expect(
      checkIns.submitted.single.extras,
      const CheckInExtras(km: 5.3, pace: '0:05'),
    );
  });

  testWidgets('flexer distance over 500 km blocks Post', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.workout30));
    await tester.enterText(find.byKey(const ValueKey('checkin-km')), '501');
    await tester.pump();
    await post(tester);
    expect(checkIns.submitted, isEmpty);
    expect(find.textContaining('500'), findsWidgets);
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

  testWidgets(
    'non-cooking couple ritual hides Who cooked (UX-24)',
    (tester) async {
      final coupleLdr = Journey(
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
        dna: const {'ritual': 'ldr'},
      );
      await pump(tester, coupleLdr);
      expect(find.byKey(const ValueKey('checkin-cook-An')), findsNothing);
      expect(find.byKey(const ValueKey('checkin-cook-Bình')), findsNothing);
      expect(find.byKey(const ValueKey('checkin-dish')), findsOneWidget);
    },
  );

  testWidgets(
    'non-running workout shows duration minutes instead of km (UX-24)',
    (tester) async {
      final gymJourney = testJourney(
        templateId: TemplateId.workout30,
      ).copyWith(dna: const {'sport': 'gym', 'measure': 'min'});
      await pump(tester, gymJourney);
      expect(find.byKey(const ValueKey('checkin-km')), findsNothing);
      expect(find.byKey(const ValueKey('checkin-minutes-45')), findsOneWidget);
    },
  );
}
