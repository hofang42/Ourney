import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/features/groups/data/groups_providers.dart';
import 'package:ourney/features/groups/domain/group_today.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/personas/accountability_squad/camera_hud.dart';
import 'package:ourney/personas/accountability_squad/l10n/generated/accountability_squad_localizations.dart';
import 'package:ourney/personas/accountability_squad/share_card.dart';
import 'package:ourney/personas/accountability_squad/timeline.dart';
import 'package:ourney_core/ourney_core.dart';

const _testTz = 'Asia/Ho_Chi_Minh';

Journey _englishJourney({
  JourneyKind kind = JourneyKind.group,
  int? durationDays = 35,
  String? metricName = 'Thời gian học',
  String? metricUnit = 'phút',
}) => Journey(
  id: 'j-eng',
  ownerId: 'u-1',
  kind: kind,
  templateId: TemplateId.englishDaily,
  title: 'IELTS 7.5 Squad',
  emoji: '📚',
  startDate: const LocalDate(2026, 10, 1),
  durationDays: durationDays,
  timezone: _testTz,
  visibility: defaultVisibilityFor(kind),
  status: JourneyStatus.active,
  metricName: metricName,
  metricUnit: metricUnit,
);

List<TimelineDay> _build35Days({int todayNumber = 21}) {
  return [
    for (var i = 1; i <= 35; i++)
      TimelineDay(
        date: const LocalDate(2026, 10, 1).addDays(i - 1),
        dayNumber: i,
        isToday: i == todayNumber,
        state: i < todayNumber
            ? DayState.checkedIn
            : (i == todayNumber ? DayState.today : DayState.future),
        checkIn: i <= todayNumber
            ? CheckIn(
                id: 'c-$i',
                journeyId: 'j-eng',
                userId: 'u-1',
                localDate: const LocalDate(2026, 10, 1).addDays(i - 1),
                capturedAt: DateTime.utc(2026, 10, i, 6, 15),
                photoPath: 'checkins/j-eng/u-1/c-$i.jpg',
                thumbPath: 'checkins/j-eng/u-1/c-${i}_t.jpg',
                metricValue: 45,
                uploaded: true,
              )
            : null,
      ),
  ];
}

List<GroupMemberEntry> _buildMembers(int count, {int checkedInCount = 4}) {
  const names = [
    'Linh',
    'Nam',
    'Hà',
    'Minh',
    'Tuấn',
    'Phương',
    'Đức',
    'Vy',
    'Hùng',
    'Thảo',
  ];
  return [
    for (var i = 0; i < count; i++)
      () {
        final done = i < checkedInCount;
        final uid = 'u-${i + 1}';
        final checkIn = done
            ? CheckIn(
                id: 'ci-$uid',
                journeyId: 'j-eng',
                userId: uid,
                localDate: const LocalDate(2026, 10, 19),
                capturedAt: DateTime(2026, 10, 19, 6, 10 + i * 5),
                photoPath: 'checkins/j-eng/$uid/ci-$uid.jpg',
                thumbPath: 'checkins/j-eng/$uid/ci-${uid}_t.jpg',
                uploaded: true,
              )
            : null;
        return GroupMemberEntry(
          member: MemberToday(
            userId: uid,
            displayName: names[i % names.length],
            role: i == 0 ? MemberRole.owner : MemberRole.member,
            todayCheckIn: checkIn,
            currentStreak: done ? 21 : 5,
          ),
          isMe: i == 0,
          checkedInToday: done,
          streak: done ? 21 : 5,
          photo: checkIn,
          photoIsToday: done,
        );
      }(),
  ];
}

Future<void> _pumpSquadWidget(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('vi'),
  double width = 390,
  double height = 844,
  double textScale = 1.0,
  bool reduceMotion = false,
  AppConfig config = const AppConfig(
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon',
  ),
  List<Override> overrides = const [],
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);

  final pTheme = OurneyPersonaTheme.forSkin(
    PersonaSkinId.accountabilitySquad,
    brightness,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        currentUserIdProvider.overrideWithValue('u-1'),
        groupBlockedIdsProvider.overrideWith((ref) => Stream.value(const {})),
        for (var i = 1; i <= 10; i++)
          groupReactionsProvider('ci-u-$i').overrideWith(
            (ref) => Stream.value([
              Reaction(
                checkInId: 'ci-u-$i',
                userId: 'u-2',
                emoji: '🔥',
                createdAt: DateTime.utc(2026, 10, 19),
              ),
            ]),
          ),
        ...overrides,
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          ...ourneyLocalizationsDelegates,
          AccountabilitySquadL10n.delegate,
        ],
        supportedLocales: ourneySupportedLocales,
        theme: pTheme.toThemeData(brightness),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('S1 — SteppingStoneQuestTimeline', () {
    testWidgets(
      'renders trophy, milestones 1/7/14/today and scrolls smoothly with 35 days',
      (tester) async {
        final journey = _englishJourney(durationDays: 35);
        final days = _build35Days(todayNumber: 21);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          for (final width in [320.0, 390.0, 430.0]) {
            await _pumpSquadWidget(
              tester,
              SteppingStoneQuestTimeline(
                key: ValueKey('s1-$brightness-$width'),
                journey: journey,
                days: days,
                photoBuilder: (_, d) => ColoredBox(
                  color: Colors.amber,
                  child: Center(child: Text('P${d.dayNumber}')),
                ),
              ),
              brightness: brightness,
              width: width,
              textScale: 1.35,
            );

            expect(find.byKey(const ValueKey('s1-top-pill')), findsOneWidget);
            expect(
              find.byKey(const ValueKey('s1-goal-trophy')),
              findsOneWidget,
            );
            expect(find.textContaining('MỤC TIÊU NGÀY 35'), findsOneWidget);

            // Today (Day 21) is near top of the reverse-chronological trail.
            expect(
              find.byKey(const ValueKey('s1-node-day-21')),
              findsOneWidget,
            );
            expect(find.textContaining('NGÀY 21 · HÔM NAY'), findsOneWidget);

            // Scroll down to verify Day 14, Day 07, and Day 01 render without overflow.
            final scrollable = find.byType(Scrollable).first;
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('s1-node-day-14')),
              250,
              scrollable: scrollable,
            );
            expect(find.textContaining('NGÀY 14 ★ TUẦN 2'), findsOneWidget);

            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('s1-node-day-7')),
              250,
              scrollable: scrollable,
            );
            expect(find.textContaining('NGÀY 07 ★ TUẦN 1'), findsOneWidget);

            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('s1-node-day-1')),
              250,
              scrollable: scrollable,
            );
            expect(find.textContaining('NGÀY 01 · BẮT ĐẦU'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  });

  group('S2 — StudyTimerSnapHud', () {
    testWidgets('shows study minutes and streak when metric exists', (
      tester,
    ) async {
      final journey = _englishJourney(
        metricName: 'Thời gian học',
        metricUnit: 'phút',
      );
      await _pumpSquadWidget(
        tester,
        SizedBox(
          height: 420,
          child: StudyTimerSnapHud(
            journey: journey,
            streak: 21,
            metricValue: 45,
            capturedAt: DateTime(2026, 10, 19, 6, 15),
          ),
        ),
        locale: const Locale('en'),
        width: 320,
        textScale: 1.35,
      );

      expect(
        find.byKey(const ValueKey('s2-study-streak-pill')),
        findsOneWidget,
      );
      expect(find.text('45 PHÚT STUDY · 21 STREAK'), findsOneWidget);
      expect(find.text('06:15 AM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hides study minutes part when journey has no metric', (
      tester,
    ) async {
      final journey = _englishJourney(metricName: null, metricUnit: null);
      await _pumpSquadWidget(
        tester,
        SizedBox(
          height: 420,
          child: StudyTimerSnapHud(
            journey: journey,
            streak: 12,
            metricValue: null,
            capturedAt: DateTime(2026, 10, 19, 18, 5),
          ),
        ),
        brightness: Brightness.dark,
        locale: const Locale('vi'),
      );

      expect(find.text('12 CHUỖI NGÀY'), findsOneWidget);
      expect(find.textContaining('HỌC'), findsNothing);
      expect(find.text('06:05 PM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('S3 — SquadPolaroidWall', () {
    testWidgets('shows NeedsServerView in local-only mode', (tester) async {
      final journey = _englishJourney();
      await _pumpSquadWidget(
        tester,
        SquadPolaroidWall(journey: journey, members: _buildMembers(4)),
        config: const AppConfig.localOnly(),
      );

      expect(find.byKey(const ValueKey('s3-needs-server')), findsOneWidget);
    });

    testWidgets(
      'renders 1 to 10 members, progress bar, dashed waiting card, and NO Nudge button',
      (tester) async {
        final journey = _englishJourney();
        for (final count in [1, 5, 10]) {
          final done = (count * 0.6).ceil();
          final members = _buildMembers(count, checkedInCount: done);

          await _pumpSquadWidget(
            tester,
            SquadPolaroidWall(
              journey: journey,
              members: members,
              photoBuilder: (_, e) => ColoredBox(
                color: Colors.teal,
                child: Center(child: Text(e.member.displayName)),
              ),
            ),
            width: 320,
            textScale: 1.35,
          );

          expect(find.byKey(const ValueKey('s3-progress-bar')), findsOneWidget);
          expect(find.text('$done/$count ĐÃ CHECK-IN HÔM NAY'), findsOneWidget);
          // Explicitly verify NO Nudge button exists in v1 (FR-G3 is P2).
          expect(find.textContaining('Nudge'), findsNothing);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'shows the Nudge pill in waiting tiles only when onNudge is provided',
      (tester) async {
        final members = _buildMembers(5, checkedInCount: 4);
        GroupMemberEntry? nudged;

        await _pumpSquadWidget(
          tester,
          SquadPolaroidWall(
            journey: _englishJourney(),
            members: members,
            onNudge: (e) => nudged = e,
            photoBuilder: (_, e) => const ColoredBox(color: Colors.teal),
          ),
          width: 320,
          textScale: 1.35,
        );

        final nudge = find.byKey(const ValueKey('s3-nudge-u-5'));
        expect(nudge, findsOneWidget);
        await tester.ensureVisible(nudge);
        await tester.pumpAndSettle();
        await tester.tap(nudge);
        await tester.pumpAndSettle();
        expect(nudged?.member.userId, 'u-5');
        expect(tester.takeException(), isNull);
      },
    );
  });
}
