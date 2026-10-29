import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/personas/aesthetic_flexer/l10n/generated/aesthetic_flexer_localizations.dart';
import 'package:ourney/personas/aesthetic_flexer/share_card.dart';
import 'package:ourney/personas/aesthetic_flexer/timeline.dart';
import 'package:ourney/personas/persona_contract.dart';
import 'package:ourney_core/ourney_core.dart';

const _testTz = 'Asia/Ho_Chi_Minh';

Journey _workoutJourney({
  String? metricName = 'Distance',
  String? metricUnit = 'KM',
}) => Journey(
  id: 'j-run',
  ownerId: 'u-1',
  kind: JourneyKind.solo,
  templateId: TemplateId.workout30,
  title: '30-Day Run Club',
  emoji: '💪',
  startDate: const LocalDate(2026, 10, 1),
  durationDays: 30,
  timezone: _testTz,
  visibility: JourneyVisibility.private,
  status: JourneyStatus.active,
  metricName: metricName,
  metricUnit: metricUnit,
);

List<TimelineDay> _buildRunDays({int total = 21, bool withMetrics = true}) {
  return [
    for (var i = 1; i <= total; i++)
      TimelineDay(
        date: const LocalDate(2026, 10, 1).addDays(i - 1),
        dayNumber: i,
        isToday: i == total,
        state: i < total ? DayState.checkedIn : DayState.today,
        checkIn: CheckIn(
          id: 'run-c-$i',
          journeyId: 'j-run',
          userId: 'u-1',
          localDate: const LocalDate(2026, 10, 1).addDays(i - 1),
          capturedAt: DateTime.utc(2026, 10, 1, 6).add(Duration(days: i - 1)),
          photoPath: 'checkins/j-run/u-1/run-c-$i.jpg',
          thumbPath: 'checkins/j-run/u-1/run-c-${i}_t.jpg',
          metricValue: withMetrics ? 4.4 : null,
          uploaded: true,
        ),
      ),
  ];
}

Future<void> _pumpFlexerWidget(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
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
    PersonaSkinId.aestheticFlexer,
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
          AestheticFlexerL10n.delegate,
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
  group('R1 — AthleticTelemetryTimeline', () {
    testWidgets(
      'renders real total/latest sparkline when metric exists and falls back to streak count without fake pace',
      (tester) async {
        final journey = _workoutJourney();
        final days = _buildRunDays(total: 21, withMetrics: true);

        for (final brightness in [Brightness.dark, Brightness.light]) {
          for (final width in [320.0, 390.0, 430.0]) {
            await _pumpFlexerWidget(
              tester,
              AthleticTelemetryTimeline(
                key: ValueKey('r1-$brightness-$width'),
                data: PersonaTimelineData(
                  journey: journey,
                  days: days,
                  currentStreak: 21,
                  photoBuilder: (_, d) => ColoredBox(
                    color: Colors.deepOrange,
                    child: Center(child: Text('D${d.dayNumber}')),
                  ),
                ),
              ),
              brightness: brightness,
              width: width,
              textScale: 1.35,
            );

            expect(
              find.byKey(const ValueKey('r1-sparkline-card')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('r1-sparkline-canvas')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('r1-telemetry-header')),
              findsOneWidget,
            );
            // Must NOT fabricate pace like "5:04 /KM".
            expect(find.textContaining('5:04'), findsNothing);
            expect(tester.takeException(), isNull);
          }
        }

        // Without metrics: hides sparkline card and shows active days pill.
        final noMetricJourney = _workoutJourney(
          metricName: null,
          metricUnit: null,
        );
        final tenDays = _buildRunDays(total: 10, withMetrics: false);
        await _pumpFlexerWidget(
          tester,
          AthleticTelemetryTimeline(
            data: PersonaTimelineData(
              journey: noMetricJourney,
              days: tenDays,
              currentStreak: 10,
              photoBuilder: (_, d) => const ColoredBox(color: Colors.black54),
            ),
          ),
        );
        expect(find.byKey(const ValueKey('r1-sparkline-card')), findsNothing);
        expect(find.byKey(const ValueKey('r1-active-pill')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('R3 — TransparentStoryStickerShareCard', () {
    testWidgets(
      'renders 9:16 story preview, 21-bar active streak heatmap, and triggers share action',
      (tester) async {
        final journey = _workoutJourney();
        final days = _buildRunDays(total: 21);
        final checkIns = [for (final d in days) d.checkIn!];
        var shared = false;

        await _pumpFlexerWidget(
          tester,
          TransparentStoryStickerShareCard(
            data: PersonaShareData(
              journey: journey,
              checkIns: checkIns,
              dayNumber: 21,
              currentStreak: 21,
              onShare: () => shared = true,
              photoBuilder: (_, c) => const ColoredBox(color: Colors.indigo),
            ),
          ),
          width: 320,
          textScale: 1.35,
        );

        expect(
          find.byKey(const ValueKey('r3-transparent-story-sticker')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('r3-heatmap-strip')), findsOneWidget);
        expect(find.byKey(const ValueKey('r3-heatmap-bar-0')), findsOneWidget);
        expect(find.byKey(const ValueKey('r3-heatmap-bar-20')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('r3-active-days-pill')),
          findsOneWidget,
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('r3-share-story-button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('r3-share-story-button')));
        await tester.pumpAndSettle();
        expect(shared, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
