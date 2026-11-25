import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/domain/timeline_window.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/journey_style.dart';
import 'package:ourney/features/journeys/ui/widgets/journey_timeline.dart';
import 'package:ourney/features/journeys/ui/widgets/timeline_common.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

const _skins = ['quiet', 'squad', 'memory', 'couple', 'flexer', 'minimal'];

List<TimelineDay> _days() {
  final j = testJourney();
  return [
    for (var i = 0; i < 14; i++)
      TimelineDay(
        date: LocalDate(2026, 10, 10 + i),
        dayNumber: i + 1,
        isToday: i == 6,
        state: i == 6
            ? DayState.today
            : i > 6
            ? DayState.future
            : i == 2
            ? DayState.missed
            : DayState.checkedIn,
        checkIn: i < 6 && i != 2
            ? testCheckIn(j.id, LocalDate(2026, 10, 10 + i))
            : null,
      ),
  ];
}

Widget _host(
  String skin, {
  required Brightness brightness,
  required double scale,
  required ValueChanged<TimelineDay> onTap,
  List<TimelineDay>? days,
  TimelineSummary? summary,
  bool? rangeShort,
  double? startingWeight,
  bool isOpenEnded = false,
  String? selfName,
  String? partnerName,
  bool showOfflineStamps = false,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: JourneysL10n.localizationsDelegates,
      supportedLocales: JourneysL10n.supportedLocales,
      theme: OurneyTheme.build(brightness),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 800),
          textScaler: TextScaler.linear(scale),
        ),
        child: UiSkinScope(
          skinId: skin,
          child: Builder(
            builder: (context) => Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: JourneyTimeline(
                  skinId: skin,
                  days: days ?? _days(),
                  summary: summary,
                  rangeShort: rangeShort,
                  startingWeight: startingWeight,
                  isOpenEnded: isOpenEnded,
                  selfName: selfName,
                  partnerName: partnerName,
                  showOfflineStamps: showOfflineStamps,
                  pal: JourneyPalette.of(
                    context,
                    styleOfJourney(testJourney()),
                  ),
                  onTapDay: onTap,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('chainRuns joins consecutive checked-in days across week breaks', () {
    TimelineDay d(int i, DayState s) => TimelineDay(
      date: LocalDate(2026, 10, 1 + i),
      dayNumber: i + 1,
      isToday: false,
      state: s,
    );
    const c = DayState.checkedIn;
    final cells = <TimelineDay?>[
      null,
      d(0, c),
      d(1, c),
      d(2, DayState.missed),
      d(3, c),
      d(4, c),
      d(5, c),
      d(6, c),
      d(7, c),
      d(8, DayState.future),
    ];
    expect(chainRuns(cells), [
      [1, 2],
      [4, 5, 6, 7, 8],
    ]);
  });

  testWidgets('couple shows a waiting partner slot per day', (tester) async {
    await tester.pumpWidget(
      _host('couple', brightness: Brightness.light, scale: 1, onTap: (_) {}),
    );
    expect(
      find.byKey(const ValueKey('couple-partner-slot')),
      findsNWidgets(14),
    );
    expect(find.text('You'), findsNWidgets(14));
    expect(find.text('Partner'), findsNWidgets(14));
  });

  testWidgets('couple shows persisted names and the partner photo', (
    tester,
  ) async {
    final j = testJourney();
    final base = testCheckIn(j.id, const LocalDate(2026, 10, 10));
    final withPartner = CheckIn(
      id: base.id,
      journeyId: base.journeyId,
      userId: base.userId,
      localDate: base.localDate,
      capturedAt: base.capturedAt,
      photoPath: base.photoPath,
      thumbPath: base.thumbPath,
      partnerPhotoPath: 'checkins/j/u/c_p.jpg',
    );
    final days = [
      TimelineDay(
        date: const LocalDate(2026, 10, 10),
        dayNumber: 1,
        isToday: false,
        state: DayState.checkedIn,
        checkIn: withPartner,
      ),
      TimelineDay(
        date: const LocalDate(2026, 10, 11),
        dayNumber: 2,
        isToday: false,
        state: DayState.checkedIn,
        checkIn: testCheckIn(j.id, const LocalDate(2026, 10, 11)),
      ),
    ];
    await tester.pumpWidget(
      _host(
        'couple',
        brightness: Brightness.light,
        scale: 1,
        onTap: (_) {},
        days: days,
        selfName: 'An',
        partnerName: 'Bình',
      ),
    );
    expect(find.text('An'), findsNWidgets(2));
    expect(find.text('Bình'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('couple-partner-photo')), findsOneWidget);
    // the day without a partner photo keeps its waiting slot
    expect(find.byKey(const ValueKey('couple-partner-slot')), findsOneWidget);
  });

  testWidgets('minimal draws the chain line', (tester) async {
    await tester.pumpWidget(
      _host('minimal', brightness: Brightness.light, scale: 1, onTap: (_) {}),
    );
    expect(find.byKey(const ValueKey('timeline-chain-line')), findsOneWidget);
  });

  testWidgets('minimal calendar days are 48dp tap boxes at 320dp (U5)', (
    tester,
  ) async {
    final tapped = <TimelineDay>[];
    await tester.pumpWidget(
      _host(
        'minimal',
        brightness: Brightness.light,
        scale: 1,
        onTap: tapped.add,
      ),
    );
    await tester.pump();
    for (final d in _days()) {
      final box = find.byKey(ValueKey('day-${d.date}'));
      final size = tester.getSize(box);
      expect(size.width, greaterThanOrEqualTo(48), reason: '${d.date}');
      expect(size.height, greaterThanOrEqualTo(48), reason: '${d.date}');
    }
    // The far edge of a checked-in day's box still hits that day.
    final first = _days().firstWhere((d) => d.state == DayState.checkedIn);
    final rect = tester.getRect(find.byKey(ValueKey('day-${first.date}')));
    await tester.tapAt(rect.center + Offset(0, rect.height / 2 - 2));
    expect(tapped.map((d) => d.date), [first.date]);
  });

  testWidgets('quiet hides numbers until the hold button is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host('quiet', brightness: Brightness.dark, scale: 1.35, onTap: (_) {}),
    );
    expect(find.text('Hold to view'), findsOneWidget);
    expect(find.byKey(const ValueKey('quiet-milestones')), findsOneWidget);
    final hold = find.byKey(const ValueKey('quiet-hold'));
    await tester.ensureVisible(hold);
    final g = await tester.startGesture(tester.getCenter(hold));
    await tester.pumpAndSettle();
    expect(find.text('Viewing'), findsOneWidget);
    expect(find.text('••,•'), findsNothing);
    await g.up();
    await tester.pumpAndSettle();
    expect(find.text('Hold to view'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'quiet open-ended Day 1 is not badged Finish and 30D pace fallback does not show baseline kg (UX-20, UX-05)',
    (tester) async {
      final j = testJourney();
      final day1 = [
        TimelineDay(
          date: const LocalDate(2026, 10, 10),
          dayNumber: 1,
          isToday: false,
          state: DayState.checkedIn,
          checkIn: testCheckIn(j.id, const LocalDate(2026, 10, 10)),
        ),
      ];
      await tester.pumpWidget(
        _host(
          'quiet',
          brightness: Brightness.light,
          scale: 1,
          onTap: (_) {},
          days: day1,
          isOpenEnded: true,
        ),
      );
      expect(find.text('Finish'), findsNothing);

      const summary = TimelineSummary(
        curve: [70.0, 69.0],
        curve30: [3.0, 5.0],
        metricCount: 2,
        metric30Count: 0,
        metricFirst: 70.0,
        metricLast: 69.0,
        pace: [1.0, 5.0],
        done: 5,
        frames: 5,
        totalDays: 40,
        currentDay: 40,
        isOpenEnded: true,
      );
      await tester.pumpWidget(
        _host(
          'quiet',
          brightness: Brightness.light,
          scale: 1,
          onTap: (_) {},
          days: day1,
          summary: summary,
          rangeShort: true,
          startingWeight: 71.5,
          isOpenEnded: true,
        ),
      );
      expect(find.byKey(const ValueKey('quiet-range-fallback')), findsOneWidget);
      final hold = find.byKey(const ValueKey('quiet-hold'));
      await tester.ensureVisible(hold);
      final g = await tester.startGesture(tester.getCenter(hold));
      await tester.pumpAndSettle();
      expect(find.text('71.5 kg'), findsNothing);
      expect(find.text('70.0 kg'), findsNothing);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      await g.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('memory ties knots on the thread and labels the today slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host('memory', brightness: Brightness.light, scale: 1, onTap: (_) {}),
    );
    expect(find.byKey(const ValueKey('timeline-knot-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('timeline-knot-4')), findsOneWidget);
    expect(find.textContaining('tap to snap'), findsOneWidget);
  });

  testWidgets('memory shows the film roll chip and offline stamps', (
    tester,
  ) async {
    final j = testJourney();
    final days = _days();
    days[0] = TimelineDay(
      date: days[0].date,
      dayNumber: 1,
      isToday: false,
      state: DayState.checkedIn,
      checkIn: testCheckIn(j.id, days[0].date, uploaded: false),
    );
    await tester.pumpWidget(
      _host(
        'memory',
        brightness: Brightness.dark,
        scale: 1.35,
        onTap: (_) {},
        days: days,
        showOfflineStamps: true,
      ),
    );
    expect(find.byKey(const ValueKey('timeline-film-roll')), findsOneWidget);
    expect(find.textContaining('FILM ROLL'), findsOneWidget);
    expect(find.byKey(const ValueKey('timeline-offline-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('timeline-offline-2')), findsNothing);
  });

  testWidgets('memory: local-only shows no offline stamp', (tester) async {
    final j = testJourney();
    final d = LocalDate(2026, 10, 10);
    await tester.pumpWidget(
      _host(
        'memory',
        brightness: Brightness.light,
        scale: 1,
        onTap: (_) {},
        days: [
          TimelineDay(
            date: d,
            dayNumber: 1,
            isToday: false,
            state: DayState.checkedIn,
            checkIn: testCheckIn(j.id, d, uploaded: false),
          ),
        ],
      ),
    );
    expect(find.byKey(const ValueKey('timeline-offline-1')), findsNothing);
  });

  for (final skin in _skins) {
    for (final dark in [false, true]) {
      testWidgets('$skin timeline ${dark ? 'dark' : 'light'} 320dp 1.35x', (
        tester,
      ) async {
        TimelineDay? tapped;
        await tester.pumpWidget(
          _host(
            skin,
            brightness: dark ? Brightness.dark : Brightness.light,
            scale: 1.35,
            onTap: (d) => tapped = d,
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('journey-timeline')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('journey-today-ring')),
          findsOneWidget,
        );
        final all = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('day-'),
        );
        expect(all, findsNWidgets(14));

        final day = find.byKey(const ValueKey('day-2026-10-11'));
        await tester.ensureVisible(day);
        await tester.pump();
        await tester.tap(day);
        expect(tapped?.dayNumber, 2);

        tapped = null;
        final missed = find.byKey(const ValueKey('day-2026-10-12'));
        await tester.ensureVisible(missed);
        await tester.pump();
        await tester.tap(missed);
        expect(tapped, isNull);
      });
    }
  }
}
