import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_dock.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/app_shell.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder _day(LocalDate d) => find.byKey(ValueKey('day-$d'));

/// Every calendar square of the journey chain.
Finder get _allDays => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('day-'),
);

/// Solo 14-day journey started 2026-10-10; today is 10-16 (day 7).
/// Checked in 10, 11, 13, 14, 15; missed 12; today still open.
Future<JourneysHarness> _pumpDetail(
  WidgetTester tester, {
  Journey? journey,
  Membership? membership,
  FakeJourneyRepository? repo,
  String? userId,
  bool backend = false,
}) {
  final j = journey ?? testJourney();
  final dates = [10, 11, 13, 14, 15].map((d) => LocalDate(2026, 10, d));
  return pumpJourneys(
    tester,
    locale: const Locale('en'),
    location: AppRoutes.journey(j.id),
    config: backend ? testBackendConfig : const AppConfig.localOnly(),
    userId: userId,
    journeys:
        repo ??
        FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: membership ?? testMembership(j)},
        ),
    checkIns: FakeCheckInRepository([
      for (final d in dates)
        d.day == 15
            ? testCheckIn(j.id, d, caption: 'weighed', metricValue: 71.5)
            : testCheckIn(j.id, d, caption: 'cap $d'),
    ]),
  );
}

void main() {
  group('Journey detail (FR-B4/B5)', () {
    testWidgets('home: day/streak line, milestones, actions', (tester) async {
      await _pumpDetail(tester);
      expect(_key('journey-detail'), findsOneWidget);
      expect(find.text('Day 7/14 · streak 3'), findsOneWidget);
      // Day 7 of 14: the first-week and finish cards; only week 1 reached.
      expect(_key('journey-home-milestones'), findsOneWidget);
      expect(_key('journey-milestone-7'), findsOneWidget);
      expect(_key('journey-milestone-14'), findsOneWidget);
      expect(_key('journey-home-card'), findsOneWidget);
      // Solo journeys have no squad row; the V1 stat grid is gone.
      expect(_key('journey-home-squad'), findsNothing);
      expect(_key('stat-current'), findsNothing);
    });

    testWidgets('quiet home shows the missed-day chip from the Figma overlay', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        journey: testJourney(templateId: TemplateId.weightLoss),
      );
      expect(_key('missed-day-chip'), findsOneWidget);
    });

    testWidgets('U15: at 2.0x the chip and Check-in button stack, no overlap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpDetail(
        tester,
        journey: testJourney(templateId: TemplateId.weightLoss),
      );
      expect(_key('journey-overlay-stacked'), findsOneWidget);
      final chip = tester.getRect(_key('missed-day-chip'));
      final button = tester.getRect(_key('journey-checkin'));
      expect(chip.overlaps(button), isFalse);
      // One line: the label is never split mid-word.
      final label = find.descendant(
        of: _key('journey-checkin'),
        matching: find.byType(Text),
      );
      expect(tester.getSize(label.first).height, lessThan(2 * 16 * 2.0 * 1.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('journey chain: checked, missed, today, future', (
      tester,
    ) async {
      await _pumpDetail(tester);
      expect(_key('journey-timeline'), findsOneWidget);
      expect(_allDays, findsNWidgets(14));
      expect(_day(testToday), findsOneWidget);
      expect(_day(const LocalDate(2026, 10, 23)), findsOneWidget);
      expect(_key('journey-today-ring'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r': checked in$')), findsNWidgets(5));
      expect(
        find.bySemanticsLabel(RegExp(r'^Day 3, .*: missed$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Day 7, .*: today, not checked in yet$'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('open-ended journeys show day N without a percentage', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        journey: testJourney(templateId: TemplateId.custom, durationDays: null),
      );
      // Custom = minimal skin: month + streak header, no "Day N/M".
      expect(find.textContaining('STREAK'), findsOneWidget);
      expect(find.textContaining('Day 7/'), findsNothing);
      // Start to today.
      expect(_allDays, findsNWidgets(7));
    });

    testWidgets('tapping a day opens the photo viewer; hidden metric', (
      tester,
    ) async {
      final j = testJourney(
        templateId: TemplateId.weightLoss,
        metricName: 'Weight',
        metricUnit: 'kg',
        hideMetricDefault: true,
      );
      final h = await _pumpDetail(
        tester,
        journey: j,
        membership: testMembership(j, hideMetric: true),
      );
      await _tap(tester, _day(const LocalDate(2026, 10, 15)));
      expect(
        h.location,
        JourneysPaths.day('j1', const LocalDate(2026, 10, 15)),
      );
      expect(_key('journey-day-viewer'), findsOneWidget);
      expect(find.text('weighed'), findsOneWidget);
      expect(find.text('Hidden'), findsOneWidget);
      expect(find.textContaining('71.5'), findsNothing);

      await _tap(tester, _key('journey-day-reveal'));
      expect(find.text('71.5 kg'), findsOneWidget);
    });

    testWidgets('day viewer pages through every photo of the day (B-B6)', (
      tester,
    ) async {
      final j = testJourney();
      final d = const LocalDate(2026, 10, 15);
      await pumpJourneys(
        tester,
        locale: const Locale('en'),
        location: JourneysPaths.day(j.id, d),
        config: const AppConfig.localOnly(),
        journeys: FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: testMembership(j)},
        ),
        checkIns: FakeCheckInRepository([
          testCheckIn(j.id, d, caption: 'morning coffee', hour: 1),
          testCheckIn(j.id, d, caption: 'evening walk', hour: 12),
        ]),
      );
      await tester.pumpAndSettle();
      // Opens on the latest photo.
      expect(find.text('evening walk'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);

      await tester.drag(_key('journey-day-pages'), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(find.text('morning coffee'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('missed and future days are not tappable', (tester) async {
      final h = await _pumpDetail(tester);
      await _tap(tester, _day(const LocalDate(2026, 10, 12)));
      expect(h.location, AppRoutes.journey('j1'));
    });
  });

  group('Journey actions (FR-B6)', () {
    testWidgets('check in now opens the camera for this journey', (
      tester,
    ) async {
      final h = await _pumpDetail(tester);
      await _tap(tester, _key('journey-checkin'));
      expect(h.location, '/capture?journeyId=j1');
      expect(
        h.container
            .read(sharedPreferencesProvider)
            .getString(lastJourneyPrefsKey),
        'j1',
      );
    });

    testWidgets('share opens the share card route (local only)', (
      tester,
    ) async {
      final h = await _pumpDetail(tester);
      await _tap(tester, _key('journey-share'));
      expect(h.location, AppRoutes.share('j1'));
    });

    testWidgets('end makes the journey read-only, then archive', (
      tester,
    ) async {
      final h = await _pumpDetail(tester);
      expect(_key('journey-home-readonly'), findsNothing);

      await _tap(tester, _key('journey-more'));
      expect(_key('journey-action-archive'), findsNothing);
      await _tap(tester, _key('journey-action-end'));
      expect(find.text('End this journey?'), findsOneWidget);
      await _tap(tester, _key('journeys-confirm'));

      expect(h.journeys.calls, contains('end:j1'));
      // Ending opens the finish story; closing it returns to the home.
      expect(h.location, JourneysPaths.wrapped('j1'));
      await _tap(tester, _key('wrapped-close'));
      expect(h.location, AppRoutes.journey('j1'));
      expect(_key('journey-home-readonly'), findsOneWidget);
      expect(_key('journey-checkin'), findsNothing);
      expect(_key('journey-pref-blur'), findsNothing);

      await _tap(tester, _key('journey-more'));
      expect(_key('journey-action-end'), findsNothing);
      await _tap(tester, _key('journey-action-archive'));
      // Archiving asks first (U12): cancelling keeps the journey.
      expect(find.text('Archive this journey?'), findsOneWidget);
      expect(h.journeys.calls, isNot(contains('archive:j1')));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(h.location, AppRoutes.journey('j1'));
      await _tap(tester, _key('journey-more'));
      await _tap(tester, _key('journey-action-archive'));
      await _tap(tester, _key('journeys-confirm'));
      expect(h.journeys.calls, contains('archive:j1'));
      expect(h.location, AppRoutes.journeys);
      // Toast with an undo path that restores the journey.
      expect(find.text('Journey archived'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ui-toast-action')));
      await tester.pumpAndSettle();
      expect(h.journeys.calls, contains('unarchive:j1'));
      await _tap(tester, _key('hub-segment-shelf'));
      expect(find.text('Archived'), findsNothing);
    });

    testWidgets('cancelling end does nothing', (tester) async {
      final h = await _pumpDetail(tester);
      await _tap(tester, _key('journey-more'));
      await _tap(tester, _key('journey-action-end'));
      await _tap(tester, find.text('Cancel'));
      expect(h.journeys.calls, isEmpty);
    });

    testWidgets('delete removes the journey and returns to the list', (
      tester,
    ) async {
      final h = await _pumpDetail(tester);
      await _tap(tester, _key('journey-more'));
      await _tap(tester, _key('journey-action-delete'));
      expect(find.text('Delete this journey?'), findsOneWidget);
      await _tap(tester, _key('journeys-confirm'));
      expect(h.journeys.calls, ['delete:j1']);
      expect(h.journeys.journeys, isEmpty);
      expect(h.location, AppRoutes.journeys);
      expect(_key('journeys-empty'), findsOneWidget);
    });

    testWidgets('delete with other members maps not_alone', (tester) async {
      final j = testJourney(kind: JourneyKind.group);
      final repo = FakeJourneyRepository(
        journeys: [j],
        memberships: {j.id: testMembership(j)},
      )..deleteError = const OurneyException(OurneyErrorCode.notAlone);
      final h = await _pumpDetail(
        tester,
        journey: j,
        repo: repo,
        backend: true,
        userId: 'u1',
      );
      await _tap(tester, _key('journey-more'));
      await _tap(tester, _key('journey-action-delete'));
      await _tap(tester, _key('journeys-confirm'));
      expect(
        find.text(
          'Other members are still in the squad, so it can\'t be deleted. '
          'You can end the journey instead.',
        ),
        findsOneWidget,
      );
      expect(h.location, AppRoutes.journey('j1'));
    });

    testWidgets('group member: no owner actions; open group button', (
      tester,
    ) async {
      final j = testJourney(kind: JourneyKind.group, ownerId: 'owner');
      final h = await _pumpDetail(
        tester,
        journey: j,
        membership: testMembership(j, userId: 'u1'),
        backend: true,
        userId: 'u1',
      );
      // Members never get end/archive/delete: the menu only offers invite.
      await _tap(tester, _key('journey-more'));
      expect(_key('journey-action-invite'), findsOneWidget);
      expect(_key('journey-action-end'), findsNothing);
      expect(_key('journey-action-delete'), findsNothing);
      expect(_key('journey-share'), findsOneWidget);
      expect(_key('journey-checkin'), findsOneWidget);
      expect(_key('journey-timeline'), findsOneWidget);
      // The menu floats over the page: a tap outside closes it first.
      await _tap(tester, _key('ui-menu-barrier'));
      expect(_key('journey-action-invite'), findsNothing);
      await _tap(tester, _key('journey-home-squad'));
      expect(h.location, AppRoutes.groups);
    });

    testWidgets('share with a server offers the card or the journey sheet', (
      tester,
    ) async {
      final h = await _pumpDetail(tester, backend: true, userId: 'u1');
      await _tap(tester, _key('journey-share'));
      expect(_key('journey-share-sheet'), findsOneWidget);
      await _tap(tester, _key('journey-share-card'));
      expect(h.location, AppRoutes.share('j1'));
    });

    testWidgets('privacy switches update my membership (FR-B7)', (
      tester,
    ) async {
      final j = testJourney(metricName: 'Weight', metricUnit: 'kg');
      final h = await _pumpDetail(tester, journey: j);
      await _tap(tester, _key('journey-pref-hide-metric'));
      await _tap(tester, _key('journey-pref-blur'));
      expect(h.journeys.prefUpdates, [
        (id: 'j1', hideMetric: true, blurMedia: null),
        (id: 'j1', hideMetric: null, blurMedia: true),
      ]);
    });

    testWidgets('pin action toggles my pin', (tester) async {
      final h = await _pumpDetail(tester);
      await _tap(tester, _key('journey-more'));
      expect(find.text('Pin to top'), findsOneWidget);
      await _tap(tester, _key('journey-action-pin'));
      expect(h.journeys.extraPrefUpdates, [
        (id: 'j1', hideExtras: null, pinned: true),
      ]);
    });

    testWidgets('hide-extras switch is hidden on solo journeys', (
      tester,
    ) async {
      await _pumpDetail(tester);
      expect(_key('journey-pref-hide-extras'), findsNothing);
    });

    testWidgets('hide-extras switch updates my membership', (tester) async {
      final j = testJourney(kind: JourneyKind.group);
      final h = await _pumpDetail(tester, journey: j);
      await _tap(tester, _key('journey-pref-hide-extras'));
      expect(h.journeys.extraPrefUpdates, [
        (id: 'j1', hideExtras: true, pinned: null),
      ]);
    });

    testWidgets('unknown journey shows not found', (tester) async {
      await pumpJourneys(
        tester,
        locale: const Locale('en'),
        location: AppRoutes.journey('missing'),
      );
      expect(_key('journey-detail-empty'), findsOneWidget);
      expect(find.text('Journey not found.'), findsOneWidget);
    });
  });

  group('Floating check-in, missed-day chip, and dock scroll clearance', () {
    testWidgets(
      'quiet 30-day journey with a missed day scrolls behind dock/check-in '
      'and places final item completely above check-in on 393pt',
      (tester) async {
        // Day 4 of 30 (`testToday` = 2026-10-16), Day 3 (2026-10-15) missed.
        final j = testJourney(
          templateId: TemplateId.weightLoss,
          startDate: const LocalDate(2026, 10, 13),
          durationDays: 30,
          metricName: 'Weight',
          metricUnit: 'kg',
        );
        await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: AppRoutes.journey(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
          checkIns: FakeCheckInRepository([
            testCheckIn(j.id, const LocalDate(2026, 10, 13), metricValue: 65.2),
            testCheckIn(j.id, const LocalDate(2026, 10, 14), metricValue: 64.8),
          ]),
        );
        tester.view.physicalSize = const Size(393, 852);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Shell extends body behind the glass dock so the skin background
        // reaches the very bottom of the screen.
        final shellScaffold = tester.widget<Scaffold>(
          find
              .descendant(
                of: find.byType(AppShell),
                matching: find.byType(Scaffold),
              )
              .first,
        );
        expect(shellScaffold.extendBody, isTrue);

        final detailScroll = find.descendant(
          of: _key('journey-detail'),
          matching: find.byType(SingleChildScrollView),
        );
        expect(tester.getRect(detailScroll).bottom, 852);

        final dockRect = tester.getRect(find.byType(AppDock));
        final chipRect = tester.getRect(_key('missed-day-chip'));
        final checkInRect = tester.getRect(_key('journey-checkin'));

        // Chip sits at start (left), vertically centered with Check-in at end,
        // non-overlapping, and both sit above the dock.
        expect(chipRect.overlaps(checkInRect), isFalse);
        expect(chipRect.right, lessThan(checkInRect.left));
        expect(
          (chipRect.center.dy - checkInRect.center.dy).abs(),
          lessThanOrEqualTo(2),
        );
        expect(chipRect.bottom, lessThanOrEqualTo(dockRect.top));
        expect(checkInRect.bottom, lessThanOrEqualTo(dockRect.top));

        // Scroll all the way to the bottom: final element sits completely
        // above the floating Check-in button and chip.
        final scrollableState = tester.state<ScrollableState>(
          find.descendant(of: detailScroll, matching: find.byType(Scrollable)),
        );
        scrollableState.position.jumpTo(
          scrollableState.position.maxScrollExtent,
        );
        await tester.pumpAndSettle();

        final finalItemRect = tester.getRect(_key('journey-pref-blur'));
        final checkInAfterScroll = tester.getRect(_key('journey-checkin'));
        final chipAfterScroll = tester.getRect(_key('missed-day-chip'));
        expect(finalItemRect.bottom, lessThanOrEqualTo(checkInAfterScroll.top));
        expect(finalItemRect.bottom, lessThanOrEqualTo(chipAfterScroll.top));
      },
    );

    testWidgets(
      'missed-day chip and check-in do not overlap at 360pt, and chip stays '
      'above the dock when canCheckIn is false',
      (tester) async {
        final active = testJourney(
          id: 'j-active',
          templateId: TemplateId.weightLoss,
          startDate: const LocalDate(2026, 10, 13),
          durationDays: 30,
        );
        final ended = testJourney(
          id: 'j-ended',
          templateId: TemplateId.weightLoss,
          startDate: const LocalDate(2026, 10, 13),
          durationDays: 30,
          status: JourneyStatus.ended,
        );
        // Check in on today as well so `journey-checkin` renders the longer
        // "Take another photo today" / "Chụp thêm ảnh hôm nay" label at 360pt.
        final h = await pumpJourneys(
          tester,
          locale: const Locale('vi'),
          location: AppRoutes.journey(active.id),
          journeys: FakeJourneyRepository(
            journeys: [active, ended],
            memberships: {
              active.id: testMembership(active),
              ended.id: testMembership(ended),
            },
          ),
          checkIns: FakeCheckInRepository([
            testCheckIn(active.id, const LocalDate(2026, 10, 13)),
            testCheckIn(active.id, const LocalDate(2026, 10, 14)),
            testCheckIn(active.id, testToday),
            testCheckIn(ended.id, const LocalDate(2026, 10, 13)),
            // 14 is missed: the timeline of an ended journey stops at its
            // last check-in, so the chip needs a gap before it.
            testCheckIn(ended.id, const LocalDate(2026, 10, 15)),
          ]),
        );
        tester.view.physicalSize = const Size(360, 800);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final dockRect = tester.getRect(find.byType(AppDock));
        final chipRect = tester.getRect(_key('missed-day-chip'));
        final checkInRect = tester.getRect(_key('journey-checkin'));
        expect(chipRect.overlaps(checkInRect), isFalse);
        expect(chipRect.right, lessThan(checkInRect.left));
        expect(
          (chipRect.center.dy - checkInRect.center.dy).abs(),
          lessThanOrEqualTo(2),
        );
        expect(chipRect.bottom, lessThanOrEqualTo(dockRect.top));
        expect(checkInRect.bottom, lessThanOrEqualTo(dockRect.top));

        // Ended journey (`perms.canCheckIn == false`): no check-in button
        // and no missed-day chip (nothing can be caught up any more).
        await h.go(tester, AppRoutes.journey(ended.id));
        expect(tester.takeException(), isNull);
        expect(_key('journey-checkin'), findsNothing);
        expect(_key('missed-day-chip'), findsNothing);
      },
    );

    testWidgets(
      'shell root tabs keep their final item completely above the dock',
      (tester) async {
        final journeys = [
          for (var i = 1; i <= 6; i++)
            testJourney(id: 'j$i', title: 'Journey $i'),
        ];
        final h = await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: AppRoutes.journeys,
          journeys: FakeJourneyRepository(
            journeys: journeys,
            memberships: {for (final j in journeys) j.id: testMembership(j)},
          ),
        );
        tester.view.physicalSize = const Size(393, 852);
        await tester.pumpAndSettle();

        Future<void> scrollToEnd(Finder root) async {
          final scrollables = find.descendant(
            of: root,
            matching: find.byType(Scrollable),
          );
          for (final element in scrollables.evaluate()) {
            final state = element as StatefulElement;
            final s = state.state as ScrollableState;
            if (s.position.axis == Axis.vertical &&
                s.position.maxScrollExtent > 0) {
              s.position.jumpTo(s.position.maxScrollExtent);
            }
          }
          await tester.pumpAndSettle();
        }

        // 1. Journeys tab: final `_NewJourneyCard` sits above the dock.
        await scrollToEnd(_key('journeys-list'));
        expect(
          tester.getRect(_key('journeys-new-card')).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(AppDock)).top),
        );

        // 2. Squad tab (local-only): `needs-server` state sits above the dock.
        await h.go(tester, AppRoutes.groups);
        await scrollToEnd(_key('groups-list'));
        expect(
          tester.getRect(_key('needs-server')).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(AppDock)).top),
        );

        // 3. Activity tab (local-only): `needs-server` state sits above the dock.
        await h.go(tester, AppRoutes.inbox);
        expect(
          tester.getRect(_key('needs-server')).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(AppDock)).top),
        );

        // 4. Profile tab: final `profile-safety` row sits above the dock.
        await h.go(tester, AppRoutes.profile);
        await scrollToEnd(_key('profile-screen'));
        expect(
          tester.getRect(_key('profile-safety')).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(AppDock)).top),
        );
      },
    );
  });
}
