import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/personas/persona_contract.dart';
import 'package:ourney/personas/quiet_transformer/camera_hud.dart';
import 'package:ourney/personas/quiet_transformer/l10n/generated/quiet_transformer_localizations.dart';
import 'package:ourney/personas/quiet_transformer/metric_curve_painter.dart';
import 'package:ourney/personas/quiet_transformer/share_card.dart';
import 'package:ourney/personas/quiet_transformer/timeline.dart';
import 'package:ourney_core/ourney_core.dart';

const _testTz = 'Asia/Ho_Chi_Minh';

Journey _weightJourney({
  String? metricName = 'Weight',
  String? metricUnit = 'kg',
  bool hideMetricDefault = true,
}) => Journey(
  id: 'j-weight',
  ownerId: 'u-1',
  kind: JourneyKind.solo,
  templateId: TemplateId.weightLoss,
  title: 'Quiet Transformation',
  emoji: '⚖️',
  startDate: const LocalDate(2026, 10, 1),
  durationDays: 30,
  timezone: _testTz,
  visibility: JourneyVisibility.private,
  status: JourneyStatus.active,
  metricName: metricName,
  metricUnit: metricUnit,
  hideMetricDefault: hideMetricDefault,
);

List<TimelineDay> _buildWeightDays({
  int total = 21,
  List<double?>? metrics,
}) {
  return [
    for (var i = 1; i <= total; i++)
      TimelineDay(
        date: const LocalDate(2026, 10, 1).addDays(i - 1),
        dayNumber: i,
        isToday: i == total,
        state: i < total ? DayState.checkedIn : DayState.today,
        checkIn: CheckIn(
          id: 'w-c-$i',
          journeyId: 'j-weight',
          userId: 'u-1',
          localDate: const LocalDate(2026, 10, 1).addDays(i - 1),
          capturedAt: DateTime.utc(2026, 10, 1, 7).add(Duration(days: i - 1)),
          photoPath: 'checkins/j-weight/u-1/w-c-$i.jpg',
          thumbPath: 'checkins/j-weight/u-1/w-c-${i}_t.jpg',
          metricValue: metrics != null
              ? metrics[i - 1]
              : 65.2 - ((i - 1) * 0.16),
          uploaded: true,
        ),
      ),
  ];
}

Future<void> _pumpQuietWidget(
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
    PersonaSkinId.quietTransformer,
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
          QuietTransformerL10n.delegate,
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
  group('Q1 — ConnectedWeightCurveTimeline & MetricSeries', () {
    test('MetricSeries.fromDays handles 0, 1, 2, and 30 points cleanly', () {
      expect(MetricSeries.fromDays(const []).isEmpty, isTrue);

      final oneDay = _buildWeightDays(total: 1, metrics: [65.2]);
      final oneSeries = MetricSeries.fromDays(oneDay);
      expect(oneSeries.isSingle, isTrue);
      expect(oneSeries.latestValue, 65.2);

      final twoDays = _buildWeightDays(total: 2, metrics: [65.2, 64.8]);
      final twoSeries = MetricSeries.fromDays(twoDays);
      expect(twoSeries.hasCurve, isTrue);
      expect(twoSeries.points, hasLength(2));

      final thirtyDays = _buildWeightDays(total: 30);
      expect(MetricSeries.fromDays(thirtyDays).points, hasLength(30));
    });

    testWidgets(
      'renders curve header and vertical milestone spine across 320/390/430dp at 1.35x',
      (tester) async {
        final journey = _weightJourney(hideMetricDefault: false);
        final days = _buildWeightDays(total: 21);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          for (final width in [320.0, 390.0, 430.0]) {
            await _pumpQuietWidget(
              tester,
              ConnectedWeightCurveTimeline(
                key: ValueKey('q1-$brightness-$width'),
                data: PersonaTimelineData(
                  journey: journey,
                  days: days,
                  currentStreak: 21,
                  hideMetric: false,
                  photoBuilder: (_, d) => ColoredBox(
                    color: Colors.teal,
                    child: Center(child: Text('D${d.dayNumber}')),
                  ),
                ),
              ),
              brightness: brightness,
              width: width,
              textScale: 1.35,
            );

            expect(find.byKey(const ValueKey('q1-curve-card')), findsOneWidget);
            expect(
              find.byKey(const ValueKey('q1-curve-canvas')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('q1-spine-day-21')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  });

  group('Q2 — GhostAlignVaultHud', () {
    testWidgets(
      'toggles Day 1 ghost silhouette and renders weight slider when metric is active',
      (tester) async {
        final journey = _weightJourney(hideMetricDefault: false);
        double? updatedMetric;

        await _pumpQuietWidget(
          tester,
          SizedBox(
            height: 440,
            child: GhostAlignVaultHud(
              data: PersonaCameraData(
                journey: journey,
                capturedAt: DateTime.utc(2026, 10, 21, 7),
                currentStreak: 21,
                checkInCount: 20,
                metricValue: 62.0,
                hideMetric: false,
                viewfinder: const ColoredBox(color: Colors.black87),
              ),
              onMetricChanged: (v) => updatedMetric = v,
            ),
          ),
          width: 320,
          textScale: 1.35,
        );

        expect(find.byKey(const ValueKey('q2-vault-pill')), findsOneWidget);
        expect(find.byKey(const ValueKey('q2-ghost-overlay')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('q2-metric-slider-card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('q2-metric-value-text')),
          findsOneWidget,
        );

        final opacityBefore = tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('q2-ghost-overlay')),
            )
            .opacity;
        expect(opacityBefore, closeTo(0.30, 0.01));

        await tester.tap(find.byKey(const ValueKey('q2-ghost-toggle')));
        await tester.pumpAndSettle();

        final opacityAfter = tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('q2-ghost-overlay')),
            )
            .opacity;
        expect(opacityAfter, 0.0);

        final slider = tester.widget<Slider>(
          find.byKey(const ValueKey('q2-metric-slider')),
        );
        slider.onChanged?.call(61.5);
        await tester.pump();
        expect(updatedMetric, 61.5);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Q3 — SideBySideArchiveShareCard', () {
    testWidgets(
      'renders DAY 01 vs latest comparison, defaults Hide Exact Weight to ON, and updates frame metrics',
      (tester) async {
        final journey = _weightJourney(hideMetricDefault: true);
        final days = _buildWeightDays(total: 21);
        final checkIns = [for (final d in days) d.checkIn!];
        var exported = false;

        await _pumpQuietWidget(
          tester,
          SideBySideArchiveShareCard(
            data: PersonaShareData(
              journey: journey,
              checkIns: checkIns,
              dayNumber: 21,
              currentStreak: 21,
              hideMetric: true,
              onShare: () => exported = true,
              photoBuilder: (_, c) => ColoredBox(
                color: Colors.blueGrey,
                child: Center(child: Text(c.id)),
              ),
            ),
          ),
          width: 320,
          textScale: 1.35,
        );

        expect(find.byKey(const ValueKey('q3-frame-start')), findsOneWidget);
        expect(find.byKey(const ValueKey('q3-frame-latest')), findsOneWidget);
        // When hidden, neither frame metrics nor delta pill leak exact weight.
        expect(find.byKey(const ValueKey('q3-delta-pill')), findsNothing);
        expect(find.text('•••'), findsNWidgets(2));

        // Toggle Hide Exact Weight OFF -> exact start, latest & delta appear.
        await tester.ensureVisible(
          find.byKey(const ValueKey('q3-hide-metric-switch')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('q3-hide-metric-switch')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('q3-delta-pill')), findsOneWidget);
        expect(find.text('65.2 kg'), findsOneWidget);
        expect(find.text('62.0 kg'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const ValueKey('q3-export-button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('q3-export-button')));
        await tester.pumpAndSettle();
        expect(exported, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
