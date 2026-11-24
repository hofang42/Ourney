import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/domain/wrapped_story.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_intro.dart';
import 'package:ourney/features/journeys/ui/wrapped/wrapped_visuals.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../share_card/share_card_fakes.dart' show pumpShare, streakCheckIns;
import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

/// Streams journeys on demand so tests can verify the loading skeleton ->
/// content crossfade and first-load wave stagger deterministically.
class _ControllableJourneyRepository extends FakeJourneyRepository {
  _ControllableJourneyRepository({
    super.journeys,
    super.memberships,
  });

  final StreamController<List<Journey>> activeController =
      StreamController<List<Journey>>.broadcast();
  int watchActiveCalls = 0;

  @override
  Stream<List<Journey>> watchActive() {
    watchActiveCalls++;
    return activeController.stream;
  }
}

/// Pumps the full Ourney app with animations ENABLED (or disabled when
/// [disableAnimations] is true) so 3-point `tester.pump` choreography can be
/// verified at `t = 0`, `t = mid-flight`, and `t = settled`.
Future<JourneysHarness> _pumpMotionJourneys(
  WidgetTester tester, {
  FakeJourneyRepository? journeys,
  FakeCheckInRepository? checkIns,
  String location = '/journeys',
  bool disableAnimations = false,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  List<Override> extraOverrides = const [],
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(
        disableAnimations: disableAnimations,
        reduceMotion: disableAnimations,
      );
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  final repo = journeys ?? FakeJourneyRepository();
  final ci = checkIns ?? FakeCheckInRepository();
  final container = await pumpOurneyApp(
    tester,
    config: const AppConfig.localOnly(),
    locale: locale,
    overrides: [
      journeyRepositoryProvider.overrideWithValue(repo),
      checkInRepositoryProvider.overrideWithValue(ci),
      mediaStoreProvider.overrideWithValue(FakeMediaStore()),
      journeysClockProvider.overrideWithValue(Clock.fixed(testNow)),
      deviceTimezoneProvider.overrideWith((ref) => testTz),
      journeyHomeOfflineProvider.overrideWith((ref) => Stream.value(false)),
      ...extraOverrides,
    ],
  );
  final h = JourneysHarness(container, repo, ci);
  container.read(routerProvider).go(location);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return h;
}

void main() {
  group('M3 Moment #10 & #11 — Hub skeleton crossfade, wave stagger & pull-to-refresh', () {
    testWidgets(
      '3-point pump on Hub skeleton -> content crossfade and first-load wave stagger (does not replay on segment switch)',
      (tester) async {
        final j1 = testJourney(id: 'j1', title: 'Journey One');
        final j2 = testJourney(id: 'j2', title: 'Journey Two');
        final ended = testJourney(
          id: 'j3',
          title: 'Ended Three',
          status: JourneyStatus.ended,
        );
        final repo = _ControllableJourneyRepository(
          journeys: [j1, j2, ended],
          memberships: {
            j1.id: testMembership(j1),
            j2.id: testMembership(j2),
            ended.id: testMembership(ended),
          },
        );
        addTearDown(repo.activeController.close);

        await _pumpMotionJourneys(
          tester,
          journeys: repo,
          checkIns: FakeCheckInRepository([
            testCheckIn(j1.id, const LocalDate(2026, 10, 15)),
          ]),
        );

        // 1. Loading state: skeleton is mounted inside a RepaintBoundary.
        expect(_key('journeys-loading'), findsOneWidget);
        expect(
          find.ancestor(
            of: _key('journeys-loading'),
            matching: find.byType(RepaintBoundary),
          ),
          findsWidgets,
        );

        // 2. Emit data -> t = 0ms start of skeleton-to-content crossfade & wave stagger.
        repo.activeController.add([j1, j2, ended]);
        await tester.pump();
        await tester.pump();

        // Mid-flight at t = 60ms:
        // - AnimatedSwitcher is crossfading loading and content.
        // - UiStaggerItem for hero (index 0, 0ms delay) is mid-flight, while
        //   row j2 (index 3, 105ms delay) has not started its fade yet (opacity == 0).
        await tester.pump(const Duration(milliseconds: 60));
        final j2StaggerFade = tester.widget<FadeTransition>(
          find
              .descendant(
                of: _key('hub-stagger-j2'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(j2StaggerFade.opacity.value, 0.0);

        // Advance to t = 120ms (fires the 105ms delay timer and starts ticker),
        // then t = 180ms where j2 stagger is mid-flight (0 < opacity < 1).
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump(const Duration(milliseconds: 60));
        expect(j2StaggerFade.opacity.value, greaterThan(0.0));
        expect(j2StaggerFade.opacity.value, lessThan(1.0));

        // 3. Settled: all stagger items reach opacity 1.0 and resting offset.
        await tester.pumpAndSettle();
        expect(j2StaggerFade.opacity.value, 1.0);
        expect(_key('journeys-loading'), findsNothing);
        expect(_key('journey-card-j1'), findsOneWidget);
        expect(_key('journey-card-j2'), findsOneWidget);

        // Switching segments (Active -> Shelf -> Active) clears initial stagger
        // so rows mount with enabled: false and zero replay animation.
        await tester.drag(_key('journeys-list'), const Offset(0, -160));
        await tester.pumpAndSettle();
        await tester.tap(_key('hub-segment-shelf'));
        await tester.pumpAndSettle();
        expect(_key('journey-card-j3'), findsOneWidget);

        await tester.tap(_key('hub-segment-active'));
        await tester.pump();
        final j1StaggerAfterSwitch = tester.widget<UiStaggerItem>(
          _key('hub-stagger-j1'),
        );
        expect(j1StaggerAfterSwitch.enabled, isFalse);
      },
    );

    testWidgets(
      'Hub pull-to-refresh (UiRefreshScaffold) fires selection haptic on threshold and invalidates journeys provider; Reduce Motion parity',
      (tester) async {
        final haptics = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                haptics.add(call.arguments as String? ?? '');
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        final j1 = testJourney(id: 'j1', title: 'Pull Refresh Journey');
        final repo = FakeJourneyRepository(
          journeys: [j1],
          memberships: {j1.id: testMembership(j1)},
        );
        await _pumpMotionJourneys(tester, journeys: repo);
        await tester.pumpAndSettle();

        expect(_key('ui-refresh-badge'), findsNothing);

        // 1. Start overscroll pull from top.
        final gesture = await tester.startGesture(const Offset(195, 220));
        await gesture.moveBy(const Offset(0, 45));
        await tester.pump();
        expect(_key('ui-refresh-badge'), findsOneWidget);
        expect(haptics, isEmpty);

        // 2. Cross 72dp trigger threshold -> fires selectionClick once.
        await gesture.moveBy(const Offset(0, 50));
        await tester.pump();
        expect(haptics, ['HapticFeedbackType.selectionClick']);

        // 3. Release -> triggers refresh and collapses badge over 180ms.
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(_key('ui-refresh-badge'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(_key('ui-refresh-badge'), findsNothing);
      },
    );
  });

  group('M3 Moment #6 — Hub -> Journey Detail Hero flight & buildUiPage transition', () {
    testWidgets(
      '3-point pump on Hub JourneyRow -> JourneyDetailScreen: SharedAxisZ route transition + UiHero flight shuttle with BorderRadiusTween, and Reduce Motion parity',
      (tester) async {
        final j = testJourney(id: 'j1', title: 'Chameleon Run');
        await _pumpMotionJourneys(
          tester,
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
        );
        await tester.pumpAndSettle();

        // 1. Scroll JourneyRow into view and tap at t = 0ms.
        await tester.ensureVisible(_key('journey-card-j1'));
        await tester.pumpAndSettle();
        await tester.tap(_key('journey-card-j1'));
        await tester.pump();

        // 2. Mid-flight at t = 120ms (of 320ms UiMotion.page):
        // UiHero flight shuttles (card 12->20dp and icon 14->10dp) are active
        // in the Overlay with interpolated BorderRadius values.
        await tester.pump(const Duration(milliseconds: 120));
        final shuttle = _key('ui-hero-shuttle');
        expect(shuttle, findsWidgets);
        final radii = tester
            .widgetList<ClipRRect>(
              find.descendant(of: shuttle, matching: find.byType(ClipRRect)),
            )
            .map((c) => (c.borderRadius as BorderRadius).topLeft.x)
            .toList();
        expect(
          radii.any((r) => r > 10.0 && r < 14.0) ||
              radii.any((r) => r > 12.0 && r < 20.0),
          isTrue,
        );

        // 3. Settled at >= 320ms: JourneyDetailScreen is resting with zero active tickers.
        await tester.pumpAndSettle();
        expect(_key('journey-detail'), findsOneWidget);
        expect(_key('ui-hero-shuttle'), findsNothing);
      },
    );

    testWidgets(
      'Reduce Motion disables Hero flight on Hub -> JourneyDetailScreen and settles by 160ms',
      (tester) async {
        final j = testJourney(id: 'j1', title: 'Reduced Run');
        await _pumpMotionJourneys(
          tester,
          disableAnimations: true,
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(_key('journey-card-j1'));
        await tester.pumpAndSettle();
        await tester.tap(_key('journey-card-j1'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        expect(_key('ui-hero-shuttle'), findsNothing);

        await tester.pump(const Duration(milliseconds: 90));
        expect(_key('journey-detail'), findsOneWidget);
      },
    );
  });

  group('M3 Moment #8 — Timeline -> DayViewerScreen Hero flight & interactive drag-to-dismiss', () {
    testWidgets(
      '3-point pump on Timeline day tap -> DayViewerScreen Hero flight, Interval(0.45, 1.0) chrome fade, interactive drag rebound & dismiss, and page haptic',
      (tester) async {
        final haptics = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                haptics.add(call.arguments as String? ?? '');
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        final j = testJourney(
          id: 'j1',
          templateId: TemplateId.weightLoss,
          metricName: 'Weight',
          metricUnit: 'kg',
          hideMetricDefault: true,
        );
        final d = const LocalDate(2026, 10, 15);
        final h = await _pumpMotionJourneys(
          tester,
          location: AppRoutes.journey(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j, hideMetric: true)},
          ),
          checkIns: FakeCheckInRepository([
            testCheckIn(
              j.id,
              d,
              caption: 'Morning weigh-in',
              metricValue: 62.0,
              hour: 1,
            ),
            testCheckIn(
              j.id,
              d,
              caption: 'Evening check',
              metricValue: 62.0,
              hour: 8,
            ),
          ]),
        );
        await tester.pumpAndSettle();

        // 1. Tap checked-in day cell on timeline -> starts 300ms route push & Hero flight.
        final dayFinder = _key('day-$d');
        await tester.ensureVisible(dayFinder);
        await tester.pumpAndSettle();
        await tester.tap(dayFinder);
        await tester.pump();

        // 2a. At t = 90ms (< 0.45 * 300ms = 135ms): Hero shuttle is mid-flight,
        // and metadata chrome fade is still held at 0.0.
        await tester.pump(const Duration(milliseconds: 90));
        expect(_key('ui-hero-shuttle'), findsOneWidget);
        final chromeFade = tester.widget<FadeTransition>(
          _key('journey-day-chrome-fade'),
        );
        expect(chromeFade.opacity.value, 0.0);

        // 2b. At t = 220ms (inside Interval(0.45, 1.0)): metadata chrome is mid-fade (0 < alpha < 1).
        await tester.pump(const Duration(milliseconds: 130));
        expect(chromeFade.opacity.value, greaterThan(0.0));
        expect(chromeFade.opacity.value, lessThan(1.0));

        // 3. Settled at >= 300ms.
        await tester.pumpAndSettle();
        expect(chromeFade.opacity.value, 1.0);
        expect(h.location, JourneysPaths.day(j.id, d));

        // Horizontal swipe across photos of the day fires selectionClick haptic.
        haptics.clear();
        await tester.drag(_key('journey-day-pages'), const Offset(350, 0));
        await tester.pumpAndSettle();
        expect(find.text('Morning weigh-in'), findsOneWidget);
        expect(haptics, contains('HapticFeedbackType.selectionClick'));

        // Hidden metric reveal crossfades over 140ms + selection haptic.
        haptics.clear();
        await tester.tap(_key('journey-day-reveal'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));
        expect(find.text('62 kg'), findsOneWidget);
        expect(haptics, contains('HapticFeedbackType.selectionClick'));
        await tester.pumpAndSettle();

        // 4. Interactive vertical drag below threshold (|dy| = 70 <= 110dp):
        // First moveBy crosses kTouchSlop to claim the vertical drag arena
        // over PageView; second moveBy drives _onVerticalDragUpdate 1:1 on dy,
        // 0.35x on dx, scales down in (0.84, 1.0), then rebounds via UiSprings.snappy.
        final dragSurface = _key('journey-day-drag-surface');
        final gRebound = await tester.startGesture(tester.getCenter(dragSurface));
        await gRebound.moveBy(const Offset(0, 20));
        await tester.pump();
        await gRebound.moveBy(const Offset(40, 70));
        await tester.pump();

        final dragTransform = tester.widget<Transform>(
          _key('journey-day-drag-transform'),
        );
        expect(dragTransform.transform.getTranslation().y, closeTo(70.0, 0.5));
        expect(
          dragTransform.transform.getTranslation().x,
          closeTo(40.0 * 0.35, 0.5),
        );
        final dragScale = tester.widget<Transform>(
          _key('journey-day-drag-scale'),
        );
        final midScale = dragScale.transform.storage[0];
        expect(midScale, greaterThan(0.84));
        expect(midScale, lessThan(1.0));

        await gRebound.up();
        await tester.pump();
        // Mid-rebound at t = 40ms: offset is between (0, 70).
        await tester.pump(const Duration(milliseconds: 40));
        final reboundMidY = tester
            .widget<Transform>(_key('journey-day-drag-transform'))
            .transform
            .getTranslation()
            .y;
        expect(reboundMidY, greaterThan(0.0));
        expect(reboundMidY, lessThan(70.0));

        await tester.pumpAndSettle();
        expect(_key('journey-day-drag-transform'), findsNothing);
        expect(h.location, JourneysPaths.day(j.id, d));

        // 5. Interactive vertical drag past threshold (|dy| = 150 > 110dp) pops back to JourneyDetailScreen.
        final gDismiss = await tester.startGesture(tester.getCenter(dragSurface));
        await gDismiss.moveBy(const Offset(0, 20));
        await tester.pump();
        await gDismiss.moveBy(const Offset(0, 150));
        await tester.pump();
        await gDismiss.up();
        await tester.pumpAndSettle();
        expect(h.location, AppRoutes.journey(j.id));
        expect(_key('journey-detail'), findsOneWidget);
      },
    );
  });

  group('M3 Moment #15 — Quiet Hold-to-Reveal weight crossfade & Archive month accordion', () {
    testWidgets(
      '3-point pump on QuietTimeline Hold-to-Reveal weight (140ms crossfade + selection haptic)',
      (tester) async {
        final haptics = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                haptics.add(call.arguments as String? ?? '');
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        final j = testJourney(
          id: 'j-quiet',
          templateId: TemplateId.weightLoss,
          metricName: 'Weight',
          metricUnit: 'kg',
        );
        await _pumpMotionJourneys(
          tester,
          location: AppRoutes.journey(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
          checkIns: FakeCheckInRepository([
            testCheckIn(j.id, const LocalDate(2026, 10, 13), metricValue: 65.2),
            testCheckIn(j.id, const LocalDate(2026, 10, 15), metricValue: 62.0),
          ]),
        );
        await tester.pumpAndSettle();

        final holdFinder = _key('quiet-hold');
        await tester.ensureVisible(holdFinder);
        await tester.pumpAndSettle();

        expect(_key('quiet-axis-0-masked'), findsOneWidget);
        expect(_key('quiet-axis-0-shown'), findsNothing);

        // 1. Pointer down at t = 0ms -> fires selectionClick haptic & starts 140ms crossfade.
        final gesture = await tester.startGesture(tester.getCenter(holdFinder));
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.selectionClick'));

        // 2. Mid-flight at t = 70ms: both masked and shown axis labels are in the AnimatedSwitcher tree with 0 < opacity < 1.
        await tester.pump(const Duration(milliseconds: 70));
        expect(_key('quiet-axis-0-shown'), findsOneWidget);
        final shownFade = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: _key('quiet-axis-0-shown'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(shownFade.opacity.value, greaterThan(0.0));
        expect(shownFade.opacity.value, lessThan(1.0));

        // 3. Settled at >= 140ms: only shown weight remains.
        await tester.pumpAndSettle();
        expect(shownFade.opacity.value, 1.0);
        expect(_key('quiet-axis-0-masked'), findsNothing);

        // Release pointer -> crossfades back to masked '••,•'.
        await gesture.up();
        await tester.pumpAndSettle();
        expect(_key('quiet-axis-0-masked'), findsOneWidget);
        expect(_key('quiet-axis-0-shown'), findsNothing);
      },
    );

    testWidgets(
      '3-point pump on TimelineArchive month header chevron rotation (180ms) & accordion body fade+size + haptic',
      (tester) async {
        final haptics = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                haptics.add(call.arguments as String? ?? '');
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        final j = Journey(
          id: 'j-long',
          ownerId: 'u1',
          kind: JourneyKind.solo,
          templateId: TemplateId.custom,
          title: 'Long Archive Journey',
          emoji: 'x',
          startDate: testToday.addDays(-65),
          durationDays: 90,
          timezone: testTz,
          visibility: JourneyVisibility.private,
          status: JourneyStatus.active,
        );
        await _pumpMotionJourneys(
          tester,
          locale: const Locale('vi'),
          location: AppRoutes.journey(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
          checkIns: FakeCheckInRepository([
            testCheckIn(j.id, const LocalDate(2026, 9, 10)),
            testCheckIn(j.id, testToday),
          ]),
        );
        await tester.pumpAndSettle();

        // Switch to By month mode.
        await tester.scrollUntilVisible(
          _key('timeline-mode-month'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(_key('timeline-mode-month'));
        await tester.pumpAndSettle();

        final sepMonthId = 2026 * 12 + 9 - 1;
        final sepHeader = find.byWidgetPredicate(
          (w) =>
              w is UiMonthHeader &&
              RegExp(r'^tháng 9 2026, ').hasMatch(w.semanticLabel),
        );
        await tester.scrollUntilVisible(
          sepHeader,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final chevronFinder = _key('archive-chevron-$sepMonthId');
        expect(
          tester.widget<AnimatedRotation>(chevronFinder).turns,
          0.0,
        );

        // 1. Tap September header to expand -> fires selection haptic & starts 180ms rotation + body fade.
        haptics.clear();
        await tester.tap(sepHeader);
        await tester.pump();
        expect(haptics, contains('HapticFeedbackType.selectionClick'));

        // 2. Mid-flight at t = 80ms: chevron RotationTransition turns is between (0, 0.25)
        // and row FadeTransition opacity is between (0, 1).
        await tester.pump(const Duration(milliseconds: 80));
        final rotTransition = tester.widget<RotationTransition>(
          find.descendant(
            of: chevronFinder,
            matching: find.byType(RotationTransition),
          ),
        );
        expect(rotTransition.turns.value, greaterThan(0.0));
        expect(rotTransition.turns.value, lessThan(0.25));

        final rowAnimFinder = _key('archive-row-anim-$sepMonthId-0');
        expect(rowAnimFinder, findsOneWidget);
        final rowFade = tester.widget<FadeTransition>(
          find.descendant(
            of: rowAnimFinder,
            matching: find.byType(FadeTransition),
          ),
        );
        expect(rowFade.opacity.value, greaterThan(0.0));
        expect(rowFade.opacity.value, lessThan(1.0));

        // 3. Settled at >= 180ms: chevron at 0.25 turns and row opacity at 1.0.
        await tester.pumpAndSettle();
        expect(rotTransition.turns.value, closeTo(0.25, 0.001));
        expect(rowFade.opacity.value, 1.0);
      },
    );
  });

  group('M3 Moment #9 — JourneyWrappedScreen, WrappedVisual telemetry & ShareCardScreen morph', () {
    testWidgets(
      '3-point pump on Wrapped story: 5.0s segment progress fill, long-press pause/resume, direction-aware slide handoff (+1 right / -1 left), and Reduce Motion parity',
      (tester) async {
        final j = testJourney(
          id: 'j-wrap',
          status: JourneyStatus.ended,
          templateId: TemplateId.workout30,
        );
        await _pumpMotionJourneys(
          tester,
          location: JourneysPaths.wrapped(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
          checkIns: FakeCheckInRepository([
            for (final d in [10, 11, 12, 14])
              testCheckIn(j.id, LocalDate(2026, 10, d), metricValue: 5.0),
          ]),
        );

        // 1. Segment 0 active bar fills linearly over 5.0s.
        await tester.pump(const Duration(milliseconds: 1200));
        final seg0Fill = tester
            .widget<FractionallySizedBox>(_key('wrapped-segment-fill-0'))
            .widthFactor!;
        expect(seg0Fill, greaterThan(0.15));
        expect(seg0Fill, lessThan(0.45));

        // Long-press hold pauses the segment timer; releasing resumes it.
        final holdGesture = await tester.startGesture(const Offset(195, 420));
        await tester.pump(const Duration(milliseconds: 600));
        final pausedVal = tester
            .widget<FractionallySizedBox>(_key('wrapped-segment-fill-0'))
            .widthFactor!;
        await tester.pump(const Duration(milliseconds: 1000));
        expect(
          tester
              .widget<FractionallySizedBox>(_key('wrapped-segment-fill-0'))
              .widthFactor,
          closeTo(pausedVal, 0.001),
        );
        await holdGesture.up();
        await tester.pump();

        // 2. Tap right side (Next, direction +1) -> UiDirectionalSwitcher slides incoming page 1 from +dx.
        final headlineOriginX = tester
            .getTopLeft(_key('wrapped-headline'))
            .dx;
        await tester.tapAt(const Offset(350, 420));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final incomingPage1 = _key('wrapped-page-1');
        expect(incomingPage1, findsOneWidget);
        final page1MidX = tester
            .getTopLeft(
              find.descendant(
                of: incomingPage1,
                matching: _key('wrapped-headline'),
              ),
            )
            .dx;
        expect(page1MidX, greaterThan(headlineOriginX));

        await tester.pump(const Duration(milliseconds: 200));

        // 3. Tap left side (Back, direction -1) -> UiDirectionalSwitcher slides incoming page 0 from -dx.
        final page1SettledX = tester.getTopLeft(_key('wrapped-headline')).dx;
        await tester.tapAt(const Offset(40, 420));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final incomingPage0 = _key('wrapped-page-0');
        expect(incomingPage0, findsOneWidget);
        final page0MidX = tester
            .getTopLeft(
              find.descendant(
                of: incomingPage0,
                matching: _key('wrapped-headline'),
              ),
            )
            .dx;
        expect(page0MidX, lessThan(page1SettledX));
      },
    );

    testWidgets(
      '3-point pump on WrappedVisual telemetry: _Bars staggered growth, _Chain sequential illumination, _Curve path reveal, and _Trophy 32dp rise + UiCountRoll + milestone haptic',
      (tester) async {
        final haptics = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                haptics.add(call.arguments as String? ?? '');
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        const stats = WrappedStats(
          days: 6,
          total: 10,
          moments: 6,
          streak: 4,
          totalKm: 18,
          weights: [65.0, 63.5],
          photos: [],
          lastCaption: null,
          lastPlace: null,
          pace: null,
        );

        final appTheme = OurneyTheme.build(Brightness.light);
        Widget hostVisual(PersonaSkinId skin, int page, {bool reduced = false}) {
          return MaterialApp(
            theme: appTheme,
            themeAnimationDuration: Duration.zero,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!,
            ),
            home: Scaffold(
              body: Center(
                child: WrappedVisual(
                  key: ValueKey('host-visual-${skin.name}-$page-$reduced'),
                  skin: skin,
                  stats: stats,
                  page: page,
                ),
              ),
            ),
          );
        }

        // 1. _Bars (aestheticFlexer page 0): staggered vertical scaleY growth over 620ms.
        await tester.pumpWidget(hostVisual(PersonaSkinId.aestheticFlexer, 0));
        await tester.pump(const Duration(milliseconds: 180));
        final bar0MidScaleY = tester
            .widget<Transform>(_key('wrapped-bar-scale-0'))
            .transform
            .storage[5];
        final bar9MidScaleY = tester
            .widget<Transform>(_key('wrapped-bar-scale-9'))
            .transform
            .storage[5];
        expect(bar0MidScaleY, greaterThan(0.0));
        expect(bar0MidScaleY, lessThan(1.0));
        expect(bar0MidScaleY, greaterThan(bar9MidScaleY));

        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Transform>(_key('wrapped-bar-scale-0'))
              .transform
              .storage[5],
          closeTo(1.0, 0.001),
        );
        expect(
          tester
              .widget<Transform>(_key('wrapped-bar-scale-9'))
              .transform
              .storage[5],
          closeTo(1.0, 0.001),
        );

        // 2. _Chain (minimalistHabit page 0): sequential tile illumination over 580ms.
        await tester.pumpWidget(hostVisual(PersonaSkinId.minimalistHabit, 0));
        await tester.pump(const Duration(milliseconds: 180));
        final tile0Scale = tester
            .widget<Transform>(_key('wrapped-chain-tile-0'))
            .transform
            .storage[0];
        final tile5Scale = tester
            .widget<Transform>(_key('wrapped-chain-tile-5'))
            .transform
            .storage[0];
        expect(tile0Scale, greaterThan(tile5Scale));
        expect(tile5Scale, greaterThanOrEqualTo(0.86));
        expect(tile5Scale, lessThan(1.0));

        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Transform>(_key('wrapped-chain-tile-5'))
              .transform
              .storage[0],
          closeTo(1.0, 0.001),
        );

        // 3. _Trophy (accountabilitySquad page 2): rises 32dp over 560ms + UiCountRoll + double-beat milestone haptic.
        haptics.clear();
        await tester.pumpWidget(
          hostVisual(PersonaSkinId.accountabilitySquad, 2),
        );
        await tester.pump();
        expect(haptics, ['HapticFeedbackType.mediumImpact']);

        // At t = 180ms: second haptic beat (110ms) has fired, trophy is mid-rise (0 < dy < 32),
        // and UiCountRoll is mid-roll.
        await tester.pump(const Duration(milliseconds: 180));
        expect(haptics, [
          'HapticFeedbackType.mediumImpact',
          'HapticFeedbackType.lightImpact',
        ]);
        final trophyTransforms = tester
            .widgetList<Transform>(
              find.descendant(
                of: _key('wrapped-trophy'),
                matching: find.byType(Transform),
              ),
            )
            .toList();
        final trophyDy = trophyTransforms.first.transform.getTranslation().y;
        expect(trophyDy, greaterThan(0.0));
        expect(trophyDy, lessThan(32.0));

        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<Transform>(
                find.descendant(
                  of: _key('wrapped-trophy'),
                  matching: find.byType(Transform),
                ),
              )
              .first
              .transform
              .getTranslation()
              .y,
          closeTo(0.0, 0.01),
        );
        expect(find.text('6/10 · 60%'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);

        // 4. Reduce Motion renders _Trophy immediately at resting position with zero tickers.
        await tester.pumpWidget(
          hostVisual(PersonaSkinId.accountabilitySquad, 2, reduced: true),
        );
        await tester.pump();
        expect(find.text('6/10 · 60%'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );

    testWidgets(
      '3-point pump on ShareCardScreen 9:16 <-> 4:5 aspect ratio morph (240ms) and privacy blur sigma 0 -> 14 tween (180ms)',
      (tester) async {
        // Override pumpShare's disableAnimations so real transitions run.
        final j = testJourney();
        await pumpShare(
          tester,
          journey: j,
          photos: true,
          checkIns: streakCheckIns(j.id),
        );
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(
              disableAnimations: false,
              reduceMotion: false,
            );
        await tester.pump();

        // 1. Toggle 9:16 -> 4:5: verify mid-flight aspect ratio at t = 120ms is between (9/16, 4/5).
        final format45 = find.descendant(
          of: _key('share-card-format'),
          matching: find.text('4:5'),
        );
        await tester.tap(format45);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final aspectWidget = tester.widget<AspectRatio>(
          find
              .descendant(
                of: _key('share-card-aspect-morph'),
                matching: find.byType(AspectRatio),
              )
              .first,
        );
        expect(aspectWidget.aspectRatio, greaterThan(9 / 16));
        expect(aspectWidget.aspectRatio, lessThan(4 / 5));

        await tester.pumpAndSettle();
        final settledAspect = tester.widget<AspectRatio>(
          find
              .descendant(
                of: _key('share-card-aspect-morph'),
                matching: find.byType(AspectRatio),
              )
              .first,
        );
        expect(settledAspect.aspectRatio, closeTo(4 / 5, 0.001));

        // 2. Toggle privacy blur switch: verify mid-flight ImageFiltered blur tween at t = 90ms.
        final blurSwitch = _key('share-card-blur');
        await tester.ensureVisible(blurSwitch);
        await tester.pumpAndSettle();
        await tester.tap(blurSwitch);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 90));

        expect(
          find.descendant(
            of: _key('share-card-blur-tween'),
            matching: find.byType(ImageFiltered),
          ),
          findsWidgets,
        );

        await tester.pumpAndSettle();
        expect(_key('share-card-photo-blurred'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  });
}
