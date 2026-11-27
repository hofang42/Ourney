import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_dock.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/app_shell.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/data/group_daily_checkins_provider.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/day_viewer_screen.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_intro.dart';
import 'package:ourney/features/journeys/ui/journey_photo.dart';
import 'package:ourney/features/journeys/ui/widgets/timeline_common.dart';
import 'package:ourney/l10n/generated/app_localizations.dart';
import 'package:ourney/ui/ui.dart' show OurneyTheme, UiCamera;
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
    testWidgets('a partner-only day opens with two authored viewer slots', (
      tester,
    ) async {
      final j = testJourney(kind: JourneyKind.group, maxMembers: 2);
      const date = LocalDate(2026, 10, 12);
      final partner = testCheckIn(j.id, date, userId: 'u2', metricValue: 88);
      await pumpJourneys(
        tester,
        config: testBackendConfig,
        userId: 'u1',
        locale: const Locale('en'),
        location: AppRoutes.journey(j.id),
        journeys: FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: testMembership(j)},
        ),
        checkIns: FakeCheckInRepository([partner]),
        extraOverrides: [
          groupMembersTodaySafeProvider(j.id).overrideWith(
            (ref) => Stream.value(const [
              MemberToday(userId: 'u1', displayName: 'An', role: MemberRole.owner),
              MemberToday(userId: 'u2', displayName: 'Binh', role: MemberRole.member),
            ]),
          ),
        ],
      );
      await _tap(tester, _day(date));
      final viewer = find.byType(DayViewerScreen);
      expect(viewer, findsOneWidget);
      expect(find.descendant(of: viewer, matching: find.text('An')), findsOneWidget);
      expect(find.descendant(of: viewer, matching: find.text('Binh')), findsOneWidget);
      expect(find.text('No photo for this day'), findsOneWidget);
      final photos = find.descendant(of: viewer, matching: find.byType(JourneyPhoto));
      expect(tester.widget<JourneyPhoto>(photos).checkIn, same(partner));
      expect(_key('journey-day-metric'), findsNothing);
    });

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

    testWidgets('squad home tracks pending uploads for the signed-in member', (
      tester,
    ) async {
      final j = testJourney(
        templateId: TemplateId.englishDaily,
        kind: JourneyKind.group,
        maxMembers: 5,
      );
      final connectivity = StreamController<bool>.broadcast();
      addTearDown(connectivity.close);
      final other = testCheckIn(
        j.id,
        testToday,
        userId: 'u2',
        uploaded: false,
        hour: 4,
      );
      final checkIns = FakeCheckInRepository([other]);
      await pumpJourneys(
        tester,
        location: AppRoutes.journey(j.id),
        config: testBackendConfig,
        userId: 'u1',
        journeys: FakeJourneyRepository(
          journeys: [j],
          memberships: {j.id: testMembership(j)},
        ),
        checkIns: checkIns,
        extraOverrides: [
          journeyHomeOfflineProvider.overrideWith((ref) async* {
            yield true;
            yield* connectivity.stream;
          }),
        ],
      );

      const pending = 'Đã lưu ảnh của bạn, có mạng sẽ gửi lên nhóm';
      expect(find.text('Chưa có kết nối mạng'), findsOneWidget);
      expect(find.text(pending), findsNothing);

      checkIns.replaceAll([
        other,
        testCheckIn(j.id, testToday, uploaded: false),
      ]);
      await tester.pumpAndSettle();
      expect(find.text(pending), findsOneWidget);
      connectivity.add(false);
      await tester.pumpAndSettle();
      expect(find.text(pending), findsOneWidget);

      checkIns.replaceAll([other, testCheckIn(j.id, testToday)]);
      await tester.pumpAndSettle();
      expect(find.text(pending), findsNothing);
      expect(_key('journey-home-offline'), findsNothing);
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
        find.bySemanticsLabel(RegExp(r'^Day 3, .*: no photo$')),
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

    testWidgets(
      'tapping a day opens the photo viewer and always shows own metric (UX-25)',
      (tester) async {
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
        expect(find.text('71.5 kg'), findsOneWidget);
        expect(find.text('Hidden'), findsNothing);
        expect(_key('journey-day-reveal'), findsNothing);
      },
    );

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
      expect(h.location, '/groups/j1');
    });

    testWidgets('share with a server offers the card or the journey screen (DE-24, UX-35)', (
      tester,
    ) async {
      final h = await _pumpDetail(tester, backend: true, userId: 'u1');
      await _tap(tester, _key('journey-share'));
      expect(_key('journey-share-sheet'), findsOneWidget);
      expect(find.text('Create a share card'), findsOneWidget);
      expect(find.textContaining('video'), findsNothing);
      await _tap(tester, _key('journey-share-card'));
      expect(h.location, AppRoutes.share('j1'));

      await h.go(tester, AppRoutes.journey('j1'));
      await _tap(tester, _key('journey-share'));
      await _tap(tester, _key('journey-share-friends'));
      expect(h.location, AppRoutes.shareJourney('j1'));
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

        // 4. Profile tab: the last section (badges) sits above the dock.
        await h.go(tester, AppRoutes.profile);
        await scrollToEnd(_key('profile-screen'));
        expect(
          tester.getRect(_key('profile-stats')).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(AppDock)).top),
        );
      },
    );

    testWidgets(
      'F-38: DayViewerScreen lands on page 0 (authored pair) even when myCheckInsProvider emits before journeyByIdProvider',
      (tester) async {
        final j = testJourney(kind: JourneyKind.group, maxMembers: 2);
        const date = LocalDate(2026, 10, 12);
        final firstTake = testCheckIn(
          j.id,
          date,
          userId: 'u1',
          hour: 8,
        );
        final secondTake = testCheckIn(
          j.id,
          date,
          userId: 'u1',
          hour: 9,
        );
        final partnerTake = testCheckIn(
          j.id,
          date,
          userId: 'u2',
          hour: 10,
        );
        final journeyController = StreamController<Journey?>();
        addTearDown(journeyController.close);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              currentUserIdProvider.overrideWithValue('u1'),
              mediaStoreProvider.overrideWithValue(FakeMediaStore()),
              checkInRepositoryProvider.overrideWithValue(
                FakeCheckInRepository([firstTake, secondTake, partnerTake]),
              ),
              journeyByIdProvider(j.id).overrideWith(
                (_) => journeyController.stream,
              ),
              myCheckInsProvider(j.id).overrideWith(
                (_) => Stream.value([firstTake, secondTake]),
              ),
              groupMembersTodaySafeProvider(j.id).overrideWith(
                (_) => Stream.value(const [
                  MemberToday(
                    userId: 'u1',
                    displayName: 'An',
                    role: MemberRole.owner,
                  ),
                  MemberToday(
                    userId: 'u2',
                    displayName: 'Binh',
                    role: MemberRole.member,
                  ),
                ]),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                ...JourneysL10n.localizationsDelegates,
                ...AppLocalizations.localizationsDelegates,
              ],
              supportedLocales: JourneysL10n.supportedLocales,
              theme: OurneyTheme.build(Brightness.light),
              home: DayViewerScreen(journeyId: j.id, date: date),
            ),
          ),
        );
        // Check-ins have already emitted while journeyByIdProvider is loading.
        await tester.pump();
        journeyController.add(j);
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<(String, int, String?)>(('day-viewer-slot', 0, 'u1')),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey<(String, int, String?)>(('day-viewer-slot', 1, 'u2')),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'F-39: Couple timeline grid cell renders Today ring and readable day number when only right-side partner posted today',
      (tester) async {
        final j = testJourney(
          kind: JourneyKind.group,
          maxMembers: 2,
          templateId: TemplateId.custom,
        );
        final partnerToday = testCheckIn(j.id, testToday, userId: 'u2');
        final day = TimelineDay(
          date: testToday,
          dayNumber: 7,
          state: DayState.today,
          isToday: true,
          coupleSlots: [
            const CouplePhotoSlot(
              userId: 'u1',
              displayName: 'An',
              isMine: true,
            ),
            CouplePhotoSlot(
              userId: 'u2',
              displayName: 'Binh',
              checkIn: partnerToday,
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: JourneysL10n.localizationsDelegates,
              supportedLocales: JourneysL10n.supportedLocales,
              theme: OurneyTheme.build(Brightness.light),
              home: Scaffold(
                body: TimelineGridCell(
                  day: day,
                  size: 44,
                  hit: 48,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        );
        final todayCell = _day(testToday);
        expect(todayCell, findsOneWidget);
        expect(
          find.descendant(
            of: todayCell,
            matching: _key('journey-today-ring'),
          ),
          findsOneWidget,
        );
        final numeral = tester.widget<Text>(
          find.descendant(of: todayCell, matching: find.text('${testToday.day}')),
        );
        expect(numeral.style?.color, isNot(equals(UiCamera.onPhoto)));
      },
    );

    testWidgets(
      'F-40: DayViewerScreen renders journey-day-error with retry instead of noCheckIn when checkIns errors',
      (tester) async {
        final j = testJourney();
        var shouldError = true;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              journeyByIdProvider(j.id).overrideWith((_) => Stream.value(j)),
              myCheckInsProvider(j.id).overrideWith(
                (_) => shouldError
                    ? Stream<List<CheckIn>>.error(StateError('db error'))
                    : Stream.value([testCheckIn(j.id, testToday)]),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                ...JourneysL10n.localizationsDelegates,
                ...AppLocalizations.localizationsDelegates,
              ],
              supportedLocales: JourneysL10n.supportedLocales,
              theme: OurneyTheme.build(Brightness.light),
              home: DayViewerScreen(journeyId: j.id, date: testToday),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_key('journey-day-error'), findsOneWidget);
        expect(_key('journey-day-retry'), findsOneWidget);

        shouldError = false;
        await tester.tap(_key('journey-day-retry'));
        await tester.pumpAndSettle();
        expect(_key('journey-day-error'), findsNothing);
        expect(_key('journey-day-photo'), findsOneWidget);
      },
    );
  });
}
