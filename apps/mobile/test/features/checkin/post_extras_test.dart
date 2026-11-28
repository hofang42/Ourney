import 'dart:ui' show Tristate;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/checkin/captured_photo.dart';
import 'package:ourney/features/checkin/checkin_clock.dart';
import 'package:ourney/features/checkin/l10n/generated/checkin_localizations.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney/features/checkin/post_extras.dart';
import 'package:ourney/features/checkin/routes.dart';
import 'package:ourney/features/groups/data/groups_providers.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../groups/groups_fakes.dart' show FakeGroupRepository, memberToday;
import '../sharing/sharing_fakes.dart' show FakeSharingRepository;
import 'fakes.dart';

class _SignedInUser extends CurrentUserId {
  @override
  String build() => 'me';
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
    FakeGroupRepository? group,
    Map<String, Object> initialPrefs = const {},
  }) async {
    final prefs = await testPrefs(initialPrefs);
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
          config: group == null
              ? const AppConfig.localOnly()
              : testBackendConfig,
        ),
        photoCompressorProvider.overrideWithValue(compressor),
        checkinClockProvider.overrideWithValue(FakeCheckinClock()),
        if (group != null) ...[
          currentUserIdProvider.overrideWith(_SignedInUser.new),
          groupRepositoryProvider.overrideWithValue(group),
          sharingRepositoryProvider.overrideWithValue(FakeSharingRepository()),
          sentGroupInvitationsProvider(journey.id)
              .overrideWith((_) async => []),
        ],
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
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
    await tapKey(tester, 'checkin-minutes-other');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('checkin-minutes-less')),
        matching: find.byWidgetPredicate(
          (w) => w is OurneyIcon && w.name == 'minus',
        ),
      ),
      findsOneWidget,
    );
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
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

  Future<void> pace(WidgetTester tester, String minutes, String seconds) async {
    final m = find.byKey(const ValueKey('checkin-pace-minutes'));
    await tester.ensureVisible(m);
    await tester.enterText(m, minutes);
    final sec = find.byKey(const ValueKey('checkin-pace-seconds'));
    await tester.ensureVisible(sec);
    await tester.enterText(sec, seconds);
    await tester.pump();
  }

  testWidgets('typing 5, 4, 2 in one sequence posts 5:42', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.workout30));
    final minutes = find.byKey(const ValueKey('checkin-pace-minutes'));
    await tester.ensureVisible(minutes);
    await tester.showKeyboard(minutes);
    for (final digit in ['5', '4', '2']) {
      final focusedField = tester.widget<EditableText>(
        find.byWidgetPredicate(
          (w) => w is EditableText && w.focusNode.hasFocus,
        ),
      );
      tester.testTextInput.enterText('${focusedField.controller.text}$digit');
      await tester.pump();
    }
    await post(tester);
    expect(checkIns.submitted.single.extras, const CheckInExtras(pace: '5:42'));
  }, timeout: const Timeout(Duration(seconds: 30)));

  for (final minutes in ['0', '']) {
    final description = minutes.isEmpty ? 'empty' : 'zero';
    testWidgets('Pace with $description minutes blocks Post', (tester) async {
      await pump(tester, testJourney(templateId: TemplateId.workout30));
      await pace(tester, minutes, '42');
      await post(tester);
      expect(checkIns.submitted, isEmpty);
      final error = find.byKey(const ValueKey('checkin-pace-error'));
      expect(error, findsOneWidget);
      expect(
        tester.widget<Text>(error).data,
        CheckinL10n.of(tester.element(error)).checkin_paceMinutesInvalid,
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  }

  testWidgets('seconds above 59 are rejected and blur pads one digit', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.workout30));
    await pace(tester, '12', '05');
    final sec = find.byKey(const ValueKey('checkin-pace-seconds'));
    await tester.enterText(sec, '99');
    expect(tester.widget<TextField>(sec).controller!.text, '05');
    await tester.enterText(sec, '5');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(tester.widget<TextField>(sec).controller!.text, '05');
    await post(tester);
    expect(checkIns.submitted.single.extras.pace, '12:05');
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('comma distance and pasted pace are stored unchanged', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.workout30));
    final km = find.byKey(const ValueKey('checkin-km'));
    await tester.ensureVisible(km);
    await tester.enterText(km, '5,2');
    final m = find.byKey(const ValueKey('checkin-pace-minutes'));
    await tester.ensureVisible(m);
    await tester.enterText(m, '12:05');
    await tester.pump();
    await post(tester);
    expect(
      checkIns.submitted.single.extras,
      const CheckInExtras(km: 5.2, pace: '12:05'),
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('empty pace stays null and zero km fails validation', () {
    final c = PostExtrasController();
    addTearDown(c.dispose);
    c.setPaceParts('', '');
    expect(c.extrasFor(PersonaSkinId.aestheticFlexer).pace, isNull);
    c.km.text = '0';
    expect(c.kmInvalid, isTrue);
  }, timeout: const Timeout(Duration(seconds: 15)));

  for (final (width, scale) in [(340.0, 1.0), (390.0, 1.35)]) {
    testWidgets('run inputs stack at $width dp and $scale text scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await pump(tester, testJourney(templateId: TemplateId.workout30));
      expect(
        find.byKey(const ValueKey('checkin-run-inputs-stacked')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }, timeout: const Timeout(Duration(seconds: 30)));
  }

  testWidgets('last weight stays private and is hidden again on background', (
    tester,
  ) async {
    await pump(
      tester,
      testJourney(
        templateId: TemplateId.weightLoss,
        metricName: 'Weight',
        metricUnit: 'kg',
        hideMetricDefault: false,
      ),
      initialPrefs: {'journeys.startingWeight.j1': 72.4},
    );
    final metric = find.byKey(const ValueKey('checkin-metric'));
    await tester.ensureVisible(metric);
    final l10n = CheckinL10n.of(tester.element(metric));
    final show = find.text(l10n.checkin_show);
    String? hint() => tester.widget<TextField>(metric).decoration!.hintText;

    for (final transitions in const [
      [AppLifecycleState.inactive],
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
      ],
    ]) {
      expect(hint(), '\u2022\u2022,\u2022 kg');
      await tester.tap(show);
      await tester.pump();
      expect(hint(), l10n.checkin_metricLast('72,4'));
      expect(show, findsNothing);

      for (final state in transitions) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(hint(), '\u2022\u2022,\u2022 kg');
      expect(show, findsOneWidget);
    }
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('a missing last weight has no mask or reveal action', (
    tester,
  ) async {
    await pump(
      tester,
      testJourney(
        templateId: TemplateId.weightLoss,
        metricName: 'Weight',
        metricUnit: 'kg',
      ),
    );
    final metric = find.byKey(const ValueKey('checkin-metric'));
    final l10n = CheckinL10n.of(tester.element(metric));
    expect(tester.widget<TextField>(metric).decoration!.hintText, isNull);
    expect(find.text(l10n.checkin_show), findsNothing);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('a hidden custom metric uses its own unit in the mask', (
    tester,
  ) async {
    await pump(
      tester,
      testJourney(
        metricName: 'Weight',
        metricUnit: 'lb',
        hideMetricDefault: true,
      ),
      initialPrefs: {'journeys.startingWeight.j1': 160.5},
    );
    final metric = find.byKey(const ValueKey('checkin-metric'));
    expect(
      tester.widget<TextField>(metric).decoration!.hintText,
      '\u2022\u2022,\u2022 lb',
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('flexer distance over 500 km blocks Post', (tester) async {
    await pump(tester, testJourney(templateId: TemplateId.workout30));
    await tester.enterText(find.byKey(const ValueKey('checkin-km')), '501');
    await tester.pump();
    await post(tester);
    expect(checkIns.submitted, isEmpty);
    expect(find.textContaining('500'), findsWidgets);
  });

  testWidgets('couple skin posts the ritual with the author’s photo', (
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
    expect(
      find.byKey(const ValueKey('checkin-partner-photo-add')),
      findsNothing,
    );
    await post(tester);

    final draft = checkIns.submitted.single;
    expect(
      draft.extras,
      const CheckInExtras(dish: 'Phở', cook: 'Bình', hearts: 4),
    );
    expect(compressor.sources, [photo.path]);
  });

  testWidgets('open Couple slot opens the existing invite sheet', (
    tester,
  ) async {
    final journey = testJourney(
      kind: JourneyKind.group,
      maxMembers: 2,
      templateId: TemplateId.englishDaily,
    ).copyWith(layout: PersonaSkinId.accountabilitySquad);
    final group = FakeGroupRepository(
      today: {
        journey.id: [memberToday('me', 'An', role: MemberRole.owner)],
      },
    );
    await pump(tester, journey, group: group);

    expect(find.text('Mời người ấy tham gia'), findsOneWidget);
    await tapKey(tester, 'checkin-couple-invite');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('group-invite-sheet')), findsOneWidget);
  });

  testWidgets('a member can post while waiting for their partner', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNowUtc), () async {
      final journey = testJourney(kind: JourneyKind.group, maxMembers: 2);
      final self = memberToday('me', 'An', role: MemberRole.owner);
      final partner = memberToday('partner', 'Bình');
      final group = FakeGroupRepository(
        today: {
          journey.id: [self, partner],
        },
      );
      await pump(tester, journey, group: group);

      expect(find.text('Chờ người ấy đăng ảnh'), findsOneWidget);
      expect(find.text('Mời người ấy tham gia'), findsNothing);

      group.setToday(journey.id, [
        self,
        memberToday(
          'partner',
          'Bình',
          today: CheckIn(
            id: 'partner-photo',
            journeyId: journey.id,
            userId: 'partner',
            localDate: testToday,
            capturedAt: testNowUtc,
            photoPath: 'partner.jpg',
            thumbPath: 'partner_t.jpg',
            uploaded: true,
          ),
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Chờ người ấy đăng ảnh'), findsNothing);

      group.setToday(journey.id, [self, partner]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Chờ người ấy đăng ảnh'), findsOneWidget);
      await post(tester);

      expect(checkIns.submitted.single.photoFile, '${photo.path}.1080.jpg');
      expect(compressor.sources, [photo.path]);
    });
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
