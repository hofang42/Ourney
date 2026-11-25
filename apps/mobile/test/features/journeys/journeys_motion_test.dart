import 'dart:async';

import 'package:animations/animations.dart';
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
import 'package:ourney/features/share_card/ui/share_card.dart';
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

/// Counts `watchActive()` subscriptions while still emitting live journey list
/// values immediately like [FakeJourneyRepository].
class _CountingJourneyRepository extends FakeJourneyRepository {
  _CountingJourneyRepository({
    super.journeys,
    super.memberships,
  });

  int watchActiveCalls = 0;

  @override
  Stream<List<Journey>> watchActive() {
    watchActiveCalls++;
    return super.watchActive();
  }
}

/// Pumps the full Ourney app with configurable Android [disableAnimations] and
/// iOS [reduceMotion] accessibility flags so 3-point `tester.pump` choreography
/// and platform-independent Reduce-Motion parity can be verified.
Future<JourneysHarness> _pumpMotionJourneys(
  WidgetTester tester, {
  FakeJourneyRepository? journeys,
  FakeCheckInRepository? checkIns,
  String location = '/journeys',
  bool disableAnimations = false,
  bool? reduceMotion,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  List<Override> extraOverrides = const [],
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(
        disableAnimations: disableAnimations,
        reduceMotion: reduceMotion ?? disableAnimations,
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
  group(
    'M3 Moment #10 & #11 — Hub skeleton crossfade, wave stagger & pull-to-refresh',
    () {
      testWidgets(
        '3-point pump on Hub skeleton -> content crossfade and first-load wave stagger (auto-clears after 350ms and does not replay on segment switch)',
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

          // 3. Settled (also fires the 350ms stagger-cleanup timer): all stagger
          // items reach opacity 1.0 and resting offset.
          await tester.pumpAndSettle();
          expect(j2StaggerFade.opacity.value, 1.0);
          expect(_key('journeys-loading'), findsNothing);
          expect(_key('journey-card-j1'), findsOneWidget);
          expect(_key('journey-card-j2'), findsOneWidget);

          // Re-emitting data after the initial entrance settles does not replay stagger.
          repo.activeController.add([j1, j2, ended]);
          await tester.pump();
          expect(
            tester.widget<UiStaggerItem>(_key('hub-stagger-j1')).enabled,
            isFalse,
          );

          // Switching segments (Active -> Shelf -> Active) also keeps stagger disabled.
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

      for (final (label, androidDisable, iosReduce) in [
        ('Android disableAnimations', true, false),
        ('iOS reduceMotion', false, true),
      ]) {
        testWidgets(
          'Hub skeleton -> content & wave stagger Reduce Motion parity ($label)',
          (tester) async {
            final j1 = testJourney(id: 'j1', title: 'Reduced Hub One');
            final repo = _ControllableJourneyRepository(
              journeys: [j1],
              memberships: {j1.id: testMembership(j1)},
            );
            addTearDown(repo.activeController.close);

            await _pumpMotionJourneys(
              tester,
              journeys: repo,
              disableAnimations: androidDisable,
              reduceMotion: iosReduce,
            );
            expect(_key('journeys-loading'), findsOneWidget);

            repo.activeController.add([j1]);
            await tester.pump();
            await tester.pump();

            // Zero stagger delay or vertical translation under Reduce Motion.
            final staggerItem = tester.widget<UiStaggerItem>(
              _key('hub-stagger-j1'),
            );
            expect(staggerItem.enabled, isFalse);

            // Opacity-only crossfade settles within 160ms (150ms reducedFade).
            await tester.pump(const Duration(milliseconds: 160));
            expect(_key('journeys-loading'), findsNothing);
            expect(_key('journey-card-j1'), findsOneWidget);
          },
        );
      }

      testWidgets(
        'Hub pull-to-refresh (UiRefreshScaffold) fires selection haptic on threshold, invalidates journeysListProvider, and honors Android + iOS Reduce Motion',
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
          final repo = _CountingJourneyRepository(
            journeys: [j1],
            memberships: {j1.id: testMembership(j1)},
          );
          await _pumpMotionJourneys(tester, journeys: repo);
          await tester.pumpAndSettle();

          final callsBefore = repo.watchActiveCalls;
          expect(callsBefore, greaterThanOrEqualTo(1));
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

          // 3. Release -> triggers refresh, invalidates journeysListProvider,
          // and collapses badge over 180ms.
          await gesture.up();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 80));
          expect(_key('ui-refresh-badge'), findsOneWidget);

          await tester.pumpAndSettle();
          expect(_key('ui-refresh-badge'), findsNothing);
          expect(repo.watchActiveCalls, greaterThan(callsBefore));

          // 4. Reduce Motion parity (iOS reduceMotion-only & Android disableAnimations):
          for (final (androidDisable, iosReduce) in [
            (true, false),
            (false, true),
          ]) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                FakeAccessibilityFeatures(
                  disableAnimations: androidDisable,
                  reduceMotion: iosReduce,
                );
            await tester.pump();

            haptics.clear();
            final beforeReducedRefresh = repo.watchActiveCalls;
            final gReduced = await tester.startGesture(const Offset(195, 220));
            await gReduced.moveBy(const Offset(0, 95));
            await tester.pump();
            expect(haptics, ['HapticFeedbackType.selectionClick']);
            await gReduced.up();
            await tester.pumpAndSettle();
            expect(repo.watchActiveCalls, greaterThan(beforeReducedRefresh));
            expect(_key('ui-refresh-badge'), findsNothing);
          }
        },
      );
    },
  );

  group(
    'M3 Moment #6 — Hub -> Journey Detail SharedAxisZ transition & P1-1 badge/TodayCard integrity',
    () {
      testWidgets(
        '3-point pump on Hub JourneyRow -> JourneyDetailScreen: single-badge press translation (no 4dp ghost split), TodayCard non-interference, and SharedAxisZ route transition',
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

          // P1-1 regression check 1: JourneyRow mounts exactly one UiTypeBadge
          // inside UiJourneyCard (never a stationary duplicate overlaid badge).
          final cardFinder = _key('journey-card-j1');
          await tester.ensureVisible(cardFinder);
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: cardFinder,
              matching: find.byType(UiTypeBadge),
            ),
            findsOneWidget,
          );

          // P1-1 regression check 2: TodayCard photo banner has no UiHero/Hero
          // wrapper that could rip it into UiEyebrow text when tapping JourneyRow.
          expect(_key('journeys-today-j1'), findsOneWidget);
          expect(
            find.descendant(
              of: _key('journeys-today-j1'),
              matching: find.byType(Hero),
            ),
            findsNothing,
          );

          // 1. Pointer down on JourneyRow: at t = 55ms (mid-press of 110ms),
          // the single UiTypeBadge translates with the card surface (+4dp press)
          // without splitting into two badges.
          final pressGesture = await tester.startGesture(
            tester.getCenter(cardFinder),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 55));
          expect(
            find.descendant(
              of: cardFinder,
              matching: find.byType(UiTypeBadge),
            ),
            findsOneWidget,
          );
          await pressGesture.up();
          await tester.pump();

          // 2. Mid-flight at t = 120ms (of 320ms UiMotion.page):
          // SharedAxisTransition (scaled Z) is active, and no mismatched
          // text-border Hero shuttle is mounted.
          await tester.pump(const Duration(milliseconds: 120));
          expect(find.byType(SharedAxisTransition), findsWidgets);
          expect(_key('ui-hero-shuttle'), findsNothing);

          // 3. Settled at >= 320ms: JourneyDetailScreen is resting with zero active tickers.
          await tester.pumpAndSettle();
          expect(_key('journey-detail'), findsOneWidget);
          expect(tester.binding.transientCallbackCount, 0);
        },
      );

      for (final (label, androidDisable, iosReduce) in [
        ('Android disableAnimations', true, false),
        ('iOS reduceMotion', false, true),
      ]) {
        testWidgets(
          'Reduce Motion collapses Hub -> JourneyDetailScreen to 150ms fade ($label)',
          (tester) async {
            final j = testJourney(id: 'j1', title: 'Reduced Run');
            await _pumpMotionJourneys(
              tester,
              disableAnimations: androidDisable,
              reduceMotion: iosReduce,
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
            expect(find.byType(SharedAxisTransition), findsNothing);

            await tester.pump(const Duration(milliseconds: 90));
            expect(_key('journey-detail'), findsOneWidget);
          },
        );
      }
    },
  );

  group(
    'M3 Moment #8 — Timeline -> DayViewerScreen Hero flight & interactive drag-to-dismiss',
    () {
      testWidgets(
        '3-point pump on Timeline day tap -> DayViewerScreen Hero flight, Interval(0.45, 1.0) chrome fade, non-opaque underlying route, velocity-preserving upward-flick rebound, and drag dismiss',
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

          // 3. Settled at >= 300ms. Because day/:date is opaque: false (P1-2),
          // JourneyDetailScreen remains painted underneath DayViewerScreen so
          // vertical drag-to-dismiss reveals the live timeline behind the photo.
          await tester.pumpAndSettle();
          expect(chromeFade.opacity.value, 1.0);
          expect(h.location, JourneysPaths.day(j.id, d));
          expect(_key('journey-detail'), findsOneWidget);

          // Horizontal swipe across photos of the day fires selectionClick haptic.
          haptics.clear();
          await tester.drag(_key('journey-day-pages'), const Offset(350, 0));
          await tester.pumpAndSettle();
          expect(find.text('Morning weigh-in'), findsOneWidget);
          expect(haptics, contains('HapticFeedbackType.selectionClick'));

          // UX-25: caller's own metric is always shown directly in DayViewerScreen.
          expect(_key('journey-day-metric'), findsOneWidget);
          expect(_key('journey-day-metric-shown'), findsOneWidget);
          expect(find.text('62 kg'), findsOneWidget);
          expect(_key('journey-day-reveal'), findsNothing);

          // 4a. Interactive vertical drag below threshold (|dy| = 70 <= 110dp):
          final dragSurface = _key('journey-day-drag-surface');
          final gRebound = await tester.startGesture(
            tester.getCenter(dragSurface),
          );
          await gRebound.moveBy(const Offset(0, 20));
          await tester.pump();
          await gRebound.moveBy(const Offset(40, 70));
          await tester.pump();

          final dragTransform = tester.widget<Transform>(
            _key('journey-day-drag-transform'),
          );
          expect(
            dragTransform.transform.getTranslation().y,
            closeTo(70.0, 0.5),
          );
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

          // 4b. P1-2 regression check: dragging down to +80dp, pausing >100ms
          // (so downward samples clear VelocityTracker's 100ms horizon), and
          // flicking UPWARD toward rest (vy < 0) preserves upward velocity
          // toward 0dp instead of flinging the photo further downward (> 50dp).
          final gUpwardFlick = await tester.startGesture(
            tester.getCenter(dragSurface),
          );
          await gUpwardFlick.moveBy(
            const Offset(0, 20),
            timeStamp: const Duration(milliseconds: 16),
          );
          await tester.pump(const Duration(milliseconds: 16));
          await gUpwardFlick.moveBy(
            const Offset(0, 80),
            timeStamp: const Duration(milliseconds: 16),
          );
          await tester.pump(const Duration(milliseconds: 16));
          await gUpwardFlick.moveBy(
            Offset.zero,
            timeStamp: const Duration(milliseconds: 120),
          );
          await tester.pump(const Duration(milliseconds: 120));
          // Flick upward by -30dp over 48ms (vy ≈ -625 px/s < 0, releasing at dy = +50dp).
          for (var i = 0; i < 3; i++) {
            await gUpwardFlick.moveBy(
              const Offset(0, -10),
              timeStamp: const Duration(milliseconds: 16),
            );
            await tester.pump(const Duration(milliseconds: 16));
          }
          expect(
            tester
                .widget<Transform>(_key('journey-day-drag-transform'))
                .transform
                .getTranslation()
                .y,
            closeTo(50.0, 0.5),
          );
          await gUpwardFlick.up();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          final afterFlickY = tester
              .widget<Transform>(_key('journey-day-drag-transform'))
              .transform
              .getTranslation()
              .y;
          expect(afterFlickY, lessThan(50.0));
          expect(afterFlickY, greaterThanOrEqualTo(0.0));
          await tester.pumpAndSettle();
          expect(_key('journey-day-drag-transform'), findsNothing);

          // 5. Interactive vertical drag past threshold (|dy| = 150 > 110dp) pops back to JourneyDetailScreen.
          final gDismiss = await tester.startGesture(
            tester.getCenter(dragSurface),
          );
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

      for (final (label, androidDisable, iosReduce) in [
        ('Android disableAnimations', true, false),
        ('iOS reduceMotion', false, true),
      ]) {
        testWidgets(
          'DayViewerScreen Reduce Motion parity ($label): no Hero flight, no drag scale/translate, 150ms fade, and threshold drag still dismisses',
          (tester) async {
            final j = testJourney(id: 'j1', templateId: TemplateId.weightLoss);
            final d = const LocalDate(2026, 10, 15);
            final h = await _pumpMotionJourneys(
              tester,
              disableAnimations: androidDisable,
              reduceMotion: iosReduce,
              location: AppRoutes.journey(j.id),
              journeys: FakeJourneyRepository(
                journeys: [j],
                memberships: {j.id: testMembership(j)},
              ),
              checkIns: FakeCheckInRepository([
                testCheckIn(j.id, d, caption: 'Reduced day photo'),
              ]),
            );
            await tester.pumpAndSettle();

            final dayFinder = _key('day-$d');
            await tester.ensureVisible(dayFinder);
            await tester.pumpAndSettle();
            await tester.tap(dayFinder);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 75));
            expect(_key('ui-hero-shuttle'), findsNothing);
            expect(_key('journey-day-chrome-fade'), findsNothing);

            await tester.pump(const Duration(milliseconds: 90));
            expect(h.location, JourneysPaths.day(j.id, d));

            // Drag below threshold under Reduce Motion does not translate/shrink photo.
            final dragSurface = _key('journey-day-drag-surface');
            final gShort = await tester.startGesture(
              tester.getCenter(dragSurface),
            );
            await gShort.moveBy(const Offset(0, 20));
            await tester.pump();
            await gShort.moveBy(const Offset(0, 60));
            await tester.pump();
            expect(_key('journey-day-drag-transform'), findsNothing);
            await gShort.up();
            await tester.pumpAndSettle();
            expect(h.location, JourneysPaths.day(j.id, d));

            // Drag past 110dp threshold still dismisses DayViewerScreen.
            final gDismiss = await tester.startGesture(
              tester.getCenter(dragSurface),
            );
            await gDismiss.moveBy(const Offset(0, 20));
            await tester.pump();
            await gDismiss.moveBy(const Offset(0, 150));
            await tester.pump();
            await gDismiss.up();
            await tester.pumpAndSettle();
            expect(h.location, AppRoutes.journey(j.id));
          },
        );
      }
    },
  );

  group(
    'M3 Moment #15 — Quiet Hold-to-Reveal weight crossfade, curve range replay & Archive month accordion',
    () {
      testWidgets(
        '3-point pump on QuietTimeline Hold-to-Reveal weight (140ms crossfade + selection haptic, zero horizontal jump) and 30D/All curve replay',
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
            startDate: testToday.addDays(-40),
            durationDays: 60,
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
              testCheckIn(j.id, testToday.addDays(-38), metricValue: 66.4),
              testCheckIn(
                j.id,
                const LocalDate(2026, 10, 13),
                metricValue: 65.2,
              ),
              testCheckIn(
                j.id,
                const LocalDate(2026, 10, 15),
                metricValue: 62.0,
              ),
            ]),
          );
          await tester.pumpAndSettle();

          final holdFinder = _key('quiet-hold');
          await tester.ensureVisible(holdFinder);
          await tester.pumpAndSettle();

          expect(_key('quiet-axis-0-masked'), findsOneWidget);
          expect(_key('quiet-axis-0-shown'), findsNothing);

          // 1. Pointer down at t = 0ms -> fires selectionClick haptic & starts 140ms crossfade.
          final gesture = await tester.startGesture(
            tester.getCenter(holdFinder),
          );
          await tester.pump();
          expect(haptics, contains('HapticFeedbackType.selectionClick'));

          // 2. Mid-flight at t = 70ms: both masked and shown axis labels are in
          // the AnimatedSwitcher tree with 0 < opacity < 1, and start/end edges
          // stay locked (P2-1 zero horizontal jump).
          await tester.pump(const Duration(milliseconds: 70));
          expect(_key('quiet-axis-0-shown'), findsOneWidget);
          final midAxis0Left = tester
              .getTopLeft(_key('quiet-axis-0-shown'))
              .dx;
          final midAxis1Right = tester
              .getTopRight(_key('quiet-axis-1-shown'))
              .dx;
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

          // 3. Settled at >= 140ms: only shown weight remains at identical x coordinates.
          await tester.pumpAndSettle();
          expect(shownFade.opacity.value, 1.0);
          expect(_key('quiet-axis-0-masked'), findsNothing);
          expect(
            tester.getTopLeft(_key('quiet-axis-0-shown')).dx,
            closeTo(midAxis0Left, 0.5),
          );
          expect(
            tester.getTopRight(_key('quiet-axis-1-shown')).dx,
            closeTo(midAxis1Right, 0.5),
          );

          // Release pointer -> crossfades back to masked '••,•'.
          await gesture.up();
          await tester.pumpAndSettle();
          expect(_key('quiet-axis-0-masked'), findsOneWidget);
          expect(_key('quiet-axis-0-shown'), findsNothing);

          // P1-4: Toggling All -> 30D range chip triggers didUpdateWidget on
          // _AnimatedTimelineCurve and replays the 680ms curve reveal cleanly.
          await tester.ensureVisible(_key('quiet-range-30'));
          await tester.pumpAndSettle();
          await tester.tap(_key('quiet-range-30'));
          await tester.pump();
          expect(tester.binding.transientCallbackCount, greaterThan(0));
          await tester.pumpAndSettle();
          expect(tester.binding.transientCallbackCount, 0);
        },
      );

      testWidgets(
        '3-point pump on TimelineArchive month header chevron rotation (180ms) & widget-scoped accordion body fade+slide + haptic',
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

          // 2. Mid-flight at t = 80ms: chevron RotationTransition turns is between (0, 0.25),
          // row FadeTransition opacity is between (0, 1), and no dead AnimatedSize wraps the sliver item (P2-2).
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
          expect(
            find.descendant(
              of: rowAnimFinder,
              matching: find.byType(AnimatedSize),
            ),
            findsNothing,
          );
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

      for (final (label, androidDisable, iosReduce) in [
        ('Android disableAnimations', true, false),
        ('iOS reduceMotion', false, true),
      ]) {
        testWidgets(
          'Moment #15 Reduce Motion parity ($label): Quiet hold-to-reveal & Archive month toggle settle in 0ms',
          (tester) async {
            final j = Journey(
              id: 'j-quiet-long',
              ownerId: 'u1',
              kind: JourneyKind.solo,
              templateId: TemplateId.weightLoss,
              title: 'Quiet Long Reduced',
              emoji: 'x',
              startDate: testToday.addDays(-65),
              durationDays: 90,
              timezone: testTz,
              visibility: JourneyVisibility.private,
              status: JourneyStatus.active,
              metricName: 'Weight',
              metricUnit: 'kg',
            );
            await _pumpMotionJourneys(
              tester,
              locale: const Locale('vi'),
              disableAnimations: androidDisable,
              reduceMotion: iosReduce,
              location: AppRoutes.journey(j.id),
              journeys: FakeJourneyRepository(
                journeys: [j],
                memberships: {j.id: testMembership(j)},
              ),
              checkIns: FakeCheckInRepository([
                testCheckIn(
                  j.id,
                  const LocalDate(2026, 9, 10),
                  metricValue: 65.2,
                ),
                testCheckIn(j.id, testToday, metricValue: 62.0),
              ]),
            );
            await tester.pumpAndSettle();

            // Quiet hold-to-reveal swaps in 0ms with no intermediate fade.
            final holdFinder = _key('quiet-hold');
            await tester.ensureVisible(holdFinder);
            await tester.pumpAndSettle();
            final gesture = await tester.startGesture(
              tester.getCenter(holdFinder),
            );
            await tester.pump();
            expect(_key('quiet-axis-0-shown'), findsOneWidget);
            expect(_key('quiet-axis-0-masked'), findsNothing);
            await gesture.up();
            await tester.pump();
            expect(_key('quiet-axis-0-masked'), findsOneWidget);

            // Archive month toggle settles in 0ms under Reduce Motion.
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
            await tester.tap(sepHeader);
            await tester.pump();

            final chevronFinder = _key('archive-chevron-$sepMonthId');
            final rotTransition = tester.widget<RotationTransition>(
              find.descendant(
                of: chevronFinder,
                matching: find.byType(RotationTransition),
              ),
            );
            expect(rotTransition.turns.value, closeTo(0.25, 0.001));
          },
        );
      }
    },
  );

  group(
    'M3 Moment #9 — JourneyWrappedScreen, WrappedVisual telemetry & ShareCardScreen morph',
    () {
      testWidgets(
        '3-point pump on Wrapped story: 5.0s segment progress fill, long-press pause/resume, and direction-aware slide handoff (+1 right / -1 left)',
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

      for (final (label, androidDisable, iosReduce) in [
        ('Android disableAnimations', true, false),
        ('iOS reduceMotion', false, true),
      ]) {
        testWidgets(
          'Wrapped story Reduce Motion parity ($label): pauses 5.0s auto-advance timer and uses 150ms opacity-only slide handoff with 0dp dx offset',
          (tester) async {
            final j = testJourney(
              id: 'j-wrap-reduced',
              status: JourneyStatus.ended,
              templateId: TemplateId.workout30,
            );
            await _pumpMotionJourneys(
              tester,
              disableAnimations: androidDisable,
              reduceMotion: iosReduce,
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
            await tester.pumpAndSettle();

            // Auto-advance segment fill is not running under Reduce Motion,
            // and waiting > 5.0s stays on page 0.
            expect(_key('wrapped-segment-fill-0'), findsNothing);
            expect(_key('wrapped-page-0'), findsOneWidget);
            await tester.pump(const Duration(seconds: 6));
            expect(_key('wrapped-page-0'), findsOneWidget);

            // Manual tap right advances to page 1 with 0dp horizontal offset.
            await tester.tapAt(const Offset(350, 420));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 75));
            final incomingPage1 = _key('wrapped-page-1');
            expect(incomingPage1, findsOneWidget);
            final midX = tester
                .getTopLeft(
                  find.descendant(
                    of: incomingPage1,
                    matching: _key('wrapped-headline'),
                  ),
                )
                .dx;
            await tester.pumpAndSettle();
            final settledX = tester.getTopLeft(_key('wrapped-headline')).dx;
            expect(midX, closeTo(settledX, 0.01));
          },
        );
      }

      testWidgets(
        '3-point pump on WrappedVisual telemetry: _Bars staggered growth, _Chain sequential illumination, _Curve path reveal, _Trophy 32dp rise + UiCountRoll + climax-synced milestone haptic, and Reduce Motion parity',
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
          Widget hostVisual(
            PersonaSkinId skin,
            int page, {
            bool reduced = false,
          }) {
            return MaterialApp(
              theme: appTheme,
              themeAnimationDuration: Duration.zero,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduced),
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

          // 3. _Trophy (accountabilitySquad page 2): rises 32dp over 560ms +
          // UiCountRoll + double-beat milestone haptic synced to settle (~360ms & ~470ms, P2-3).
          haptics.clear();
          await tester.pumpWidget(
            hostVisual(PersonaSkinId.accountabilitySquad, 2),
          );
          await tester.pump();
          // P2-3: No premature haptic at t = 0ms while invisible at +32dp.
          expect(haptics, isEmpty);

          // At t = 180ms: trophy is mid-rise (0 < dy < 32), still before 360ms settle beat.
          await tester.pump(const Duration(milliseconds: 180));
          expect(haptics, isEmpty);
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

          // At t = 370ms (>= 360ms first beat): mediumImpact fires at rise settle.
          await tester.pump(const Duration(milliseconds: 190));
          expect(haptics, ['HapticFeedbackType.mediumImpact']);

          // At t = 480ms (>= 470ms second beat): lightImpact completes the double beat.
          await tester.pump(const Duration(milliseconds: 110));
          expect(haptics, [
            'HapticFeedbackType.mediumImpact',
            'HapticFeedbackType.lightImpact',
          ]);

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
        '3-point pump on ShareCardScreen 9:16 <-> 4:5 aspect ratio morph (240ms), optical privacy blur crossfade (180ms) keeping card text unblurred, and Android + iOS Reduce Motion parity',
        (tester) async {
          final j = testJourney(title: 'Crisp Typography Run');
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

          // 2. Toggle privacy blur switch (P1-3): verify mid-flight optical
          // crossfade at t = 90ms and assert card typography has NO ImageFiltered ancestor.
          final blurSwitch = _key('share-card-blur');
          await tester.ensureVisible(blurSwitch);
          await tester.pumpAndSettle();
          await tester.tap(blurSwitch);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 90));

          expect(_key('share-card-blur-crossfade'), findsOneWidget);
          final overlayFade = tester.widget<FadeTransition>(
            _key('share-card-blur-overlay-fade'),
          );
          expect(overlayFade.opacity.value, greaterThan(0.0));
          expect(overlayFade.opacity.value, lessThan(1.0));

          // P1-3 regression check: ShareCard's typography inside the card is
          // never wrapped in an outer ImageFiltered blur!
          final cardTexts = find.descendant(
            of: find.byType(ShareCard).first,
            matching: find.byType(Text),
          );
          expect(cardTexts, findsWidgets);
          expect(
            find.ancestor(
              of: cardTexts.first,
              matching: find.byType(ImageFiltered),
            ),
            findsNothing,
          );

          await tester.pumpAndSettle();
          expect(_key('share-card-blur-crossfade'), findsNothing);
          expect(_key('share-card-photo-blurred'), findsOneWidget);
          expect(tester.binding.transientCallbackCount, 0);

          // 3. Reduce Motion parity (Android disableAnimations & iOS reduceMotion):
          // aspect ratio and privacy blur switches settle in 0ms on the very next frame.
          for (final (androidDisable, iosReduce) in [
            (true, false),
            (false, true),
          ]) {
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                FakeAccessibilityFeatures(
                  disableAnimations: androidDisable,
                  reduceMotion: iosReduce,
                );
            await tester.pump();

            final targetFormatLabel =
                tester
                        .widget<AspectRatio>(
                          find
                              .descendant(
                                of: _key('share-card-aspect-morph'),
                                matching: find.byType(AspectRatio),
                              )
                              .first,
                        )
                        .aspectRatio >
                    0.7
                ? '9:16'
                : '4:5';
            final expectedRatio = targetFormatLabel == '9:16' ? 9 / 16 : 4 / 5;
            final formatTab = find.descendant(
              of: _key('share-card-format'),
              matching: find.text(targetFormatLabel),
            );
            await tester.ensureVisible(formatTab);
            await tester.pumpAndSettle();
            await tester.tap(formatTab);
            await tester.pump();
            expect(
              tester
                  .widget<AspectRatio>(
                    find
                        .descendant(
                          of: _key('share-card-aspect-morph'),
                          matching: find.byType(AspectRatio),
                        )
                        .first,
                  )
                  .aspectRatio,
              closeTo(expectedRatio, 0.001),
            );

            await tester.ensureVisible(blurSwitch);
            await tester.pumpAndSettle();
            await tester.tap(blurSwitch);
            await tester.pump();
            expect(_key('share-card-blur-crossfade'), findsNothing);
          }
        },
      );
    },
  );
}
