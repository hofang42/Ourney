import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/data/group_daily_checkins_provider.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

MemberToday _m(String id, String name, {bool shot = false, String j = 'j1'}) =>
    MemberToday(
      userId: id,
      displayName: name,
      role: MemberRole.member,
      todayCheckIn: shot ? testCheckIn(j, testToday, userId: id) : null,
    );

Future<void> _open(
  WidgetTester tester,
  Journey j, {
  List<MemberToday> members = const [],
  Size size = const Size(420, 1800),
}) async {
  final days = [10, 11, 13, 14, 15].map((d) => LocalDate(2026, 10, d));
  await pumpJourneys(
    tester,
    locale: const Locale('en'),
    location: AppRoutes.journey(j.id),
    journeys: FakeJourneyRepository(
      journeys: [j],
      memberships: {j.id: testMembership(j)},
    ),
    checkIns: FakeCheckInRepository([
      for (final d in days) testCheckIn(j.id, d, caption: 'cap $d'),
    ]),
    extraOverrides: [
      groupMembersTodaySafeProvider(j.id)
          .overrideWith((ref) => Stream.value(members)),
    ],
  );
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('squad title with length does not repeat the duration', (
    tester,
  ) async {
    final j = testJourney(
      templateId: TemplateId.englishDaily,
      title: 'Đà Lạt 7 ngày',
      durationDays: 7,
    );
    await _open(tester, j);
    expect(find.text('ĐÀ LẠT 7\u00A0NGÀY'), findsOneWidget);
    expect(find.textContaining('7 DAYS'), findsNothing);
  });

  group('Journey home: six distinct skin headers', () {
    testWidgets('squad: progress chip, avatar stack, trophy name', (
      tester,
    ) async {
      final j = testJourney(
        kind: JourneyKind.group,
        templateId: TemplateId.englishDaily,
        durationDays: 30,
      ).copyWith(dna: {'trophy': 'Cup 7.5'});
      await _open(
        tester,
        j,
        members: [
          _m('a', 'An', shot: true),
          _m('b', 'Binh', shot: true),
          _m('c', 'Chi'),
        ],
      );
      expect(_key('journey-squad-chip'), findsOneWidget);
      expect(_key('journey-avatar-stack'), findsOneWidget);
      expect(find.text('2/3 TODAY'), findsOneWidget);
      expect(find.text('CUP 7.5'), findsOneWidget);
      expect(find.textContaining('DAY 30'), findsWidgets);
    });

    testWidgets('memory: film roll chip counts frames', (tester) async {
      final j = testJourney(templateId: TemplateId.travel);
      await _open(tester, j);
      expect(_key('journey-film-chip'), findsOneWidget);
      expect(find.text('FILM ROLL 5/24'), findsOneWidget);
      expect(_key('journey-film-note'), findsNothing);
    });

    testWidgets('couple: pair header with both names and the ritual', (
      tester,
    ) async {
      final j = Journey(
        id: 'j1',
        ownerId: 'u1',
        kind: JourneyKind.group,
        templateId: TemplateId.custom,
        title: 'Us',
        emoji: '💞',
        startDate: const LocalDate(2026, 10, 10),
        durationDays: 30,
        timezone: testTz,
        visibility: JourneyVisibility.group,
        status: JourneyStatus.active,
        maxMembers: 2,
        coupleSelfName: 'An',
        couplePartnerName: 'Binh',
        dna: const {'ritual': 'cook'},
      );
      await _open(
        tester,
        j,
        members: [_m('a', 'An', shot: true), _m('b', 'Binh')],
      );
      expect(_key('journey-couple-pair'), findsOneWidget);
      expect(find.text('An'), findsWidgets);
      expect(find.text('Binh'), findsWidgets);
      expect(find.text('30 DAYS COOKING FOR EACH OTHER'), findsOneWidget);
      expect(find.text('waiting for Binh'), findsOneWidget);
    });

    testWidgets('quiet keeps its intro and chart as the header', (
      tester,
    ) async {
      await _open(tester, testJourney(templateId: TemplateId.weightLoss));
      expect(_key('journey-home-squad-header'), findsNothing);
      expect(_key('journey-home-film-header'), findsNothing);
      expect(_key('journey-home-headline'), findsOneWidget);
    });

    testWidgets('flexer header', (tester) async {
      await _open(tester, testJourney());
      expect(_key('journey-home-flexer-header'), findsOneWidget);
    });

    testWidgets('minimal header', (tester) async {
      await _open(tester, testJourney(templateId: TemplateId.custom));
      expect(_key('journey-home-minimal-header'), findsOneWidget);
    });

    testWidgets('layout override changes the home skin', (tester) async {
      final j = testJourney(templateId: TemplateId.custom)
          .copyWith(layout: PersonaSkinId.memoryCollectors);
      await _open(tester, j);
      expect(_key('journey-home-film-header'), findsOneWidget);
      expect(_key('journey-home-minimal-header'), findsNothing);
    });

    testWidgets(
      'retake hero says take another photo; ended offers the wrap-up',
      (tester) async {
        final j = testJourney();
        await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: AppRoutes.journey(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
          checkIns: FakeCheckInRepository([testCheckIn(j.id, testToday)]),
        );
        expect(find.text('Take another photo today'), findsOneWidget);
      },
    );

    testWidgets('an ended journey offers the wrap-up', (tester) async {
      await _open(tester, testJourney(status: JourneyStatus.ended));
      expect(_key('journey-home-wrapped'), findsOneWidget);
      expect(find.text('See the wrap-up'), findsOneWidget);
    });

    for (final t in [
      TemplateId.weightLoss,
      TemplateId.englishDaily,
      TemplateId.travel,
      TemplateId.workout30,
      TemplateId.custom,
    ]) {
      for (final dark in [false, true]) {
        testWidgets(
          '${t.wireName} home fits 320dp at 1.35x (${dark ? 'dark' : 'light'})',
          (tester) async {
            tester.platformDispatcher.platformBrightnessTestValue = dark
                ? Brightness.dark
                : Brightness.light;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            tester.platformDispatcher.textScaleFactorTestValue = 1.35;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final group = t == TemplateId.englishDaily;
            await _open(
              tester,
              testJourney(
                templateId: t,
                kind: group ? JourneyKind.group : JourneyKind.solo,
                title: 'Một hành trình có tên rất dài để thử tràn chữ',
              ).copyWith(dna: {'trophy': 'Chiếc cúp có tên dài dài dài'}),
              members: group
                  ? [
                      for (var i = 0; i < 7; i++)
                        _m('u$i', 'Người $i', shot: i.isEven),
                    ]
                  : const [],
              size: const Size(320, 640),
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('couple home fits 320dp at 1.35x', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.35;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final j = Journey(
        id: 'j1',
        ownerId: 'u1',
        kind: JourneyKind.group,
        templateId: TemplateId.custom,
        title: 'Us',
        emoji: '💞',
        startDate: const LocalDate(2026, 10, 10),
        durationDays: 30,
        timezone: testTz,
        visibility: JourneyVisibility.group,
        status: JourneyStatus.active,
        maxMembers: 2,
        coupleSelfName: 'Một cái tên khá dài',
        couplePartnerName: 'Another long name',
      );
      await _open(tester, j, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'open-ended squad header shows OPEN-ENDED instead of 1 DAYS / DAY 1 (UX-20)',
      (tester) async {
        final j = Journey(
          id: 'j1',
          ownerId: 'u1',
          kind: JourneyKind.group,
          templateId: TemplateId.englishDaily,
          title: 'English',
          emoji: '📚',
          startDate: testToday,
          durationDays: null,
          timezone: testTz,
          visibility: JourneyVisibility.group,
          status: JourneyStatus.active,
        );
        await _open(tester, j, members: [_m('a', 'An', shot: true)]);
        expect(find.text('ENGLISH · OPEN-ENDED'), findsOneWidget);
        expect(find.text('OPEN-ENDED'), findsOneWidget);
        expect(find.textContaining('1 DAYS'), findsNothing);
      },
    );

    testWidgets(
      'couple ritual save shows ritual-specific intro and fallback names (UX-04, UX-24)',
      (tester) async {
        final coupleSave = Journey(
          id: 'j1',
          ownerId: 'u1',
          kind: JourneyKind.group,
          templateId: TemplateId.custom,
          title: 'Us',
          emoji: '💞',
          startDate: const LocalDate(2026, 10, 10),
          durationDays: 30,
          timezone: testTz,
          visibility: JourneyVisibility.group,
          status: JourneyStatus.active,
          maxMembers: 2,
          dna: const {'ritual': 'save'},
        );
        await _open(tester, coupleSave);
        expect(
          find.text('What are you two saving for today?'),
          findsOneWidget,
        );
        // Unnamed couple journey falls back to You / Partner and offers Rename Couple (UX-04).
        expect(find.text('You'), findsWidgets);
        expect(find.text('Partner'), findsWidgets);
      },
    );

    testWidgets(
      'flexer gym shows TRAINED instead of RAN (UX-24)',
      (tester) async {
        final gymSquad = testJourney(
          kind: JourneyKind.group,
          templateId: TemplateId.workout30,
        ).copyWith(dna: const {'sport': 'gym', 'measure': 'session'});
        await _open(
          tester,
          gymSquad,
          members: [_m('a', 'An', shot: true), _m('b', 'Binh')],
        );
        expect(find.text('1/2 TRAINED'), findsOneWidget);
      },
    );
  });
}
