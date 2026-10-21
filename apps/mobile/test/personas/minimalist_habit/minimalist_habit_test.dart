import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/personas/minimalist_habit/camera_hud.dart';
import 'package:ourney/personas/minimalist_habit/l10n/generated/minimalist_habit_localizations.dart';
import 'package:ourney/personas/minimalist_habit/share_card.dart';
import 'package:ourney/personas/minimalist_habit/timeline.dart';
import 'package:ourney/personas/persona_contract.dart';
import 'package:ourney_core/ourney_core.dart';

const _testTz = 'Asia/Ho_Chi_Minh';

Journey _habitJourney({int? durationDays = 30}) => Journey(
  id: 'j-habit',
  ownerId: 'u-1',
  kind: JourneyKind.solo,
  templateId: TemplateId.custom,
  title: 'Daily Reading',
  emoji: '✨',
  startDate: const LocalDate(2026, 10, 1),
  durationDays: durationDays,
  timezone: _testTz,
  visibility: JourneyVisibility.private,
  status: JourneyStatus.active,
);

List<TimelineDay> _buildHabitDays({
  int total = 30,
  int todayNumber = 24,
}) {
  return [
    for (var i = 1; i <= total; i++)
      TimelineDay(
        date: const LocalDate(2026, 10, 1).addDays(i - 1),
        dayNumber: i,
        isToday: i == todayNumber,
        state: i < todayNumber
            ? (i == 5 ? DayState.missed : DayState.checkedIn)
            : (i == todayNumber ? DayState.today : DayState.future),
        checkIn: (i <= todayNumber && i != 5)
            ? CheckIn(
                id: 'hab-c-$i',
                journeyId: 'j-habit',
                userId: 'u-1',
                localDate: const LocalDate(2026, 10, 1).addDays(i - 1),
                capturedAt: DateTime.utc(
                  2026,
                  10,
                  1,
                  21,
                ).add(Duration(days: i - 1)),
                photoPath: 'checkins/j-habit/u-1/hab-c-$i.jpg',
                thumbPath: 'checkins/j-habit/u-1/hab-c-${i}_t.jpg',
                uploaded: true,
              )
            : null,
      ),
  ];
}

Future<void> _pumpMinimalWidget(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  double width = 390,
  double height = 844,
  double textScale = 1.0,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);

  final pTheme = OurneyPersonaTheme.forSkin(
    PersonaSkinId.minimalistHabit,
    brightness,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          ...ourneyLocalizationsDelegates,
          MinimalistHabitL10n.delegate,
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
  group('Z1 — ChainCalendarGridTimeline', () {
    testWidgets(
      'renders 7-column calendar grid with horizontal chain lines and dashed missed/future squares across 320/390/430dp',
      (tester) async {
        final journey = _habitJourney(durationDays: 30);
        final days = _buildHabitDays(total: 30, todayNumber: 24);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          for (final width in [320.0, 390.0, 430.0]) {
            await _pumpMinimalWidget(
              tester,
              ChainCalendarGridTimeline(
                key: ValueKey('z1-$brightness-$width'),
                data: PersonaTimelineData(
                  journey: journey,
                  days: days,
                  currentStreak: 19,
                  photoBuilder: (_, d) => ColoredBox(
                    color: Colors.deepOrange,
                    child: Center(child: Text('${d.dayNumber}')),
                  ),
                ),
              ),
              brightness: brightness,
              width: width,
              textScale: 1.35,
            );

            expect(
              find.byKey(const ValueKey('z1-chain-calendar-grid')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('z1-month-streak-header')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('z1-chain-line-row-0')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  });

  group('Z2 — ZeroText3SecHud', () {
    testWidgets(
      'renders single top pill, zero TextFields, and 1-tap quick snap badge',
      (tester) async {
        final journey = _habitJourney();
        await _pumpMinimalWidget(
          tester,
          SizedBox(
            height: 440,
            child: ZeroText3SecHud(
              data: PersonaCameraData(
                journey: journey,
                capturedAt: DateTime.utc(2026, 10, 24, 21),
                currentStreak: 24,
                checkInCount: 23,
                viewfinder: const ColoredBox(color: Colors.black87),
              ),
            ),
          ),
          width: 320,
          textScale: 1.35,
        );

        expect(find.byKey(const ValueKey('z2-zero-text-hud')), findsOneWidget);
        expect(find.byKey(const ValueKey('z2-top-pill')), findsOneWidget);
        expect(find.textContaining('DAILY READING · DAY 24'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('z2-quick-snap-badge')),
          findsOneWidget,
        );
        // Strictly zero text input fields on the HUD (Task Z2).
        expect(find.byType(TextField), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Z3 — ZenSummaryCardShareCard', () {
    testWidgets(
      'renders consistency percentage, featured 1:1 square photo, and matte charcoal export button',
      (tester) async {
        final journey = _habitJourney(durationDays: 30);
        final days = _buildHabitDays(total: 30, todayNumber: 25);
        final checkIns = [
          for (final d in days)
            if (d.checkIn != null) d.checkIn!,
        ];
        var exported = false;

        await _pumpMinimalWidget(
          tester,
          ZenSummaryCardShareCard(
            data: PersonaShareData(
              journey: journey,
              checkIns: checkIns,
              dayNumber: 25,
              currentStreak: 20,
              onShare: () => exported = true,
              photoBuilder: (_, c) => ColoredBox(
                color: Colors.orange.shade300,
                child: Center(child: Text(c.id)),
              ),
            ),
          ),
          width: 320,
          textScale: 1.35,
        );

        expect(
          find.byKey(const ValueKey('z3-zen-summary-card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('z3-consistency-pill')),
          findsOneWidget,
        );
        expect(find.textContaining('96% CONSISTENCY'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('z3-featured-square')),
          findsOneWidget,
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('z3-export-minimal-btn')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('z3-export-minimal-btn')));
        await tester.pumpAndSettle();
        expect(exported, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
