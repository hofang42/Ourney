import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/data/group_daily_checkins_provider.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/personas/couple_rituals/camera_hud.dart';
import 'package:ourney/personas/couple_rituals/l10n/generated/couple_rituals_localizations.dart';
import 'package:ourney/personas/couple_rituals/share_card.dart';
import 'package:ourney/personas/couple_rituals/timeline.dart';
import 'package:ourney/personas/persona_contract.dart';
import 'package:ourney_core/ourney_core.dart';

const _testTz = 'Asia/Ho_Chi_Minh';

Journey _coupleJourney({JourneyKind kind = JourneyKind.group}) => Journey(
  id: 'j-couple',
  ownerId: 'u-1',
  kind: kind,
  templateId: TemplateId.custom,
  title: 'Mỗi ngày của tụi mình',
  emoji: '💞',
  startDate: const LocalDate(2026, 10, 1),
  durationDays: 30,
  maxMembers: 2,
  timezone: _testTz,
  visibility: defaultVisibilityFor(kind),
  status: JourneyStatus.active,
);

List<TimelineDay> _buildCoupleDays({int total = 18}) {
  return [
    for (var i = 1; i <= total; i++)
      TimelineDay(
        date: const LocalDate(2026, 10, 1).addDays(i - 1),
        dayNumber: i,
        isToday: i == total,
        state: i < total ? DayState.checkedIn : DayState.today,
        checkIn: CheckIn(
          id: 'my-c-$i',
          journeyId: 'j-couple',
          userId: 'u-1',
          localDate: const LocalDate(2026, 10, 1).addDays(i - 1),
          capturedAt: DateTime.utc(
            2026,
            10,
            1,
            7,
            15,
          ).add(Duration(days: i - 1)),
          photoPath: 'checkins/j-couple/u-1/my-c-$i.jpg',
          thumbPath: 'checkins/j-couple/u-1/my-c-${i}_t.jpg',
          uploaded: true,
        ),
      ),
  ];
}

Map<LocalDate, CheckIn> _buildPartnerByDate({int total = 17}) {
  return {
    for (var i = 1; i <= total; i++)
      const LocalDate(2026, 10, 1).addDays(i - 1): CheckIn(
        id: 'p-c-$i',
        journeyId: 'j-couple',
        userId: 'u-2',
        localDate: const LocalDate(2026, 10, 1).addDays(i - 1),
        capturedAt: DateTime.utc(2026, 10, 1, 7, 30).add(Duration(days: i - 1)),
        photoPath: 'checkins/j-couple/u-2/p-c-$i.jpg',
        thumbPath: 'checkins/j-couple/u-2/p-c-${i}_t.jpg',
        uploaded: true,
      ),
  };
}

Future<void> _pumpCoupleWidget(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  double width = 390,
  double height = 844,
  double textScale = 1.0,
  AppConfig config = const AppConfig(
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon',
  ),
  List<Override> overrides = const [],
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);

  final pTheme = OurneyPersonaTheme.forSkin(
    PersonaSkinId.coupleRituals,
    brightness,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        currentUserIdProvider.overrideWithValue('u-1'),
        ...overrides,
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          ...ourneyLocalizationsDelegates,
          CoupleRitualsL10n.delegate,
        ],
        supportedLocales: ourneySupportedLocales,
        theme: pTheme.toThemeData(brightness),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('D1 — GroupDailySnapshot & groupDailySnapshotProvider', () {
    test('returns empty snapshot in local-only mode', () {
      final journey = _coupleJourney();
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
        ],
      );
      addTearDown(container.dispose);

      final snap = container.read(groupDailySnapshotProvider(journey));
      expect(snap.partnerCheckInsByDate, isEmpty);
      expect(snap.partnerCheckIns, isEmpty);
    });

    test('pairs current user and primary partner across 2 and 10 members', () {
      final journey = _coupleJourney();
      final partnerToday = CheckIn(
        id: 'p-today',
        journeyId: 'j-couple',
        userId: 'u-2',
        localDate: const LocalDate(2026, 10, 18),
        capturedAt: DateTime.utc(2026, 10, 18, 7, 30),
        photoPath: 'checkins/j-couple/u-2/p-today.jpg',
        thumbPath: 'checkins/j-couple/u-2/p-today_t.jpg',
        uploaded: true,
      );

      for (final memberCount in [2, 10]) {
        final members = [
          const MemberToday(
            userId: 'u-1',
            displayName: 'Minh',
            role: MemberRole.owner,
            todayCheckIn: null,
            currentStreak: 18,
          ),
          MemberToday(
            userId: 'u-2',
            displayName: 'Lan',
            role: MemberRole.member,
            todayCheckIn: partnerToday,
            currentStreak: 18,
          ),
          for (var i = 3; i <= memberCount; i++)
            MemberToday(
              userId: 'u-$i',
              displayName: 'Friend $i',
              role: MemberRole.member,
              todayCheckIn: null,
              currentStreak: 3,
            ),
        ];

        final snap = GroupDailySnapshot.build(
          journey: journey,
          allCheckIns: [partnerToday],
          members: members,
          myUserId: 'u-1',
        );
        expect(snap.myName, 'Minh');
        expect(snap.partnerName, 'Lan');
        expect(snap.partnerTodayCheckIn?.id, 'p-today');
        expect(
          snap.partnerCheckInsByDate[const LocalDate(2026, 10, 18)]?.id,
          'p-today',
        );
      }
    });
  });

  group('D2 — DuoSplitTimeline', () {
    testWidgets(
      'renders paired diptych rows, heart center nodes, and waiting dashed slot when one partner has not checked in',
      (tester) async {
        final journey = _coupleJourney();
        final days = _buildCoupleDays(total: 18);
        final partnerByDate = _buildPartnerByDate(total: 17); // Day 18 waiting!

        for (final brightness in [Brightness.light, Brightness.dark]) {
          for (final width in [320.0, 390.0, 430.0]) {
            await _pumpCoupleWidget(
              tester,
              DuoSplitTimeline(
                key: ValueKey('d2-$brightness-$width'),
                data: PersonaTimelineData(
                  journey: journey,
                  days: days,
                  currentStreak: 18,
                  myName: 'Minh',
                  partnerName: 'Lan',
                  partnerCheckInsByDate: partnerByDate,
                  photoBuilder: (_, d) => ColoredBox(
                    color: Colors.pink.shade200,
                    child: Center(child: Text('M${d.dayNumber}')),
                  ),
                  partnerPhotoBuilder: (_, c) => ColoredBox(
                    color: Colors.purple.shade200,
                    child: Center(child: Text(c.id)),
                  ),
                ),
              ),
              brightness: brightness,
              width: width,
              textScale: 1.35,
            );

            expect(
              find.byKey(const ValueKey('d2-duo-split-timeline')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('d2-day-card-18')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('d2-center-node-18')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('d2-partner-waiting-18')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  });

  group('D3 — HalfFrameDuoHud', () {
    testWidgets(
      'shows partner half-frame photo when partner checked in, or waiting state when not',
      (tester) async {
        final journey = _coupleJourney();
        final partnerCheckIn = _buildPartnerByDate(total: 1).values.single;

        await _pumpCoupleWidget(
          tester,
          SizedBox(
            height: 440,
            child: HalfFrameDuoHud(
              data: PersonaCameraData(
                journey: journey,
                capturedAt: DateTime.utc(2026, 10, 18, 7, 30),
                currentStreak: 18,
                checkInCount: 17,
                partnerName: 'Lan',
                partnerTodayCheckIn: partnerCheckIn,
                partnerPhotoBuilder: (_, _) =>
                    const ColoredBox(color: Colors.pinkAccent),
                viewfinder: const ColoredBox(color: Colors.black87),
              ),
            ),
          ),
          width: 320,
          textScale: 1.35,
        );

        expect(find.byKey(const ValueKey('d3-top-pill')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('d3-partner-snapped')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('d3-my-viewfinder-half')),
          findsOneWidget,
        );

        // When partner has NOT checked in today:
        await _pumpCoupleWidget(
          tester,
          SizedBox(
            height: 440,
            child: HalfFrameDuoHud(
              data: PersonaCameraData(
                journey: journey,
                capturedAt: DateTime.utc(2026, 10, 18, 7, 30),
                currentStreak: 18,
                checkInCount: 17,
                partnerName: 'Lan',
                partnerTodayCheckIn: null,
                viewfinder: const ColoredBox(color: Colors.black87),
              ),
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey('d3-partner-waiting')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('D4 — CoupleMosaicPosterShareCard', () {
    testWidgets(
      'weaves both partners check-ins into mosaic poster and never renders public link for group journeys (FR-E3)',
      (tester) async {
        final journey = _coupleJourney(kind: JourneyKind.group);
        final myDays = _buildCoupleDays(total: 18);
        final myCheckIns = [for (final d in myDays) d.checkIn!];
        final partnerCheckIns = _buildPartnerByDate(total: 18).values.toList();
        var shared = false;

        await _pumpCoupleWidget(
          tester,
          CoupleMosaicPosterShareCard(
            data: PersonaShareData(
              journey: journey,
              checkIns: myCheckIns,
              partnerCheckIns: partnerCheckIns,
              dayNumber: 18,
              currentStreak: 18,
              onShare: () => shared = true,
              publicLinkSection: const Text('GROUP_PUBLIC_LINK_FORBIDDEN'),
              photoBuilder: (_, c) => ColoredBox(
                color: Colors.pink.shade300,
                child: Center(child: Text(c.id)),
              ),
            ),
          ),
          width: 320,
          textScale: 1.35,
        );

        expect(
          find.byKey(const ValueKey('d4-couple-mosaic-card')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('d4-mosaic-grid')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('d4-mosaic-headline')),
          findsOneWidget,
        );
        // FR-E3: Group journey never shows public link section.
        expect(find.text('GROUP_PUBLIC_LINK_FORBIDDEN'), findsNothing);

        await tester.ensureVisible(
          find.byKey(const ValueKey('d4-share-story-btn')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('d4-share-story-btn')));
        await tester.pumpAndSettle();
        expect(shared, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
