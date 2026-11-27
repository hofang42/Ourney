import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/domain/journey_layouts.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney/features/journeys/ui/edit/time_wheel.dart';
import 'package:ourney/features/profile/settings_providers.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney/features/reminders/data/reminder_settings.dart';
import 'package:ourney/features/reminders/domain/reminder_plan.dart';
import 'package:ourney/ui/ui.dart' show UiSwitchRow;
import 'package:ourney_core/ourney_core.dart';

import '../reminders/reminders_fakes.dart' show FakeNotificationGateway;
import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<JourneysHarness> _open(
  WidgetTester tester, {
  Journey? journey,
  String userId = 'u1',
  Size size = const Size(420, 1800),
  FakeNotificationGateway? gateway,
}) async {
  final j = journey ?? testJourney();
  final h = await pumpJourneys(
    tester,
    locale: const Locale('en'),
    location: JourneysPaths.edit(j.id),
    userId: userId,
    journeys: FakeJourneyRepository(
      journeys: [j],
      memberships: {j.id: testMembership(j, userId: userId)},
    ),
    extraOverrides: [
      if (gateway != null) ...[
        notificationGatewayProvider.overrideWithValue(gateway),
        reminderDeviceTimezoneProvider.overrideWith((ref) async => testTz),
        remindersClockProvider.overrideWithValue(Clock.fixed(testNow)),
      ],
    ],
  );
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
  return h;
}

void main() {
  group('availableLayoutsFor', () {
    test('hides layouts that need data the journey lacks', () {
      final solo = testJourney(templateId: TemplateId.custom);
      final layouts = availableLayoutsFor(
        solo,
        current: PersonaSkinId.minimalistHabit,
      );
      expect(layouts, [
        PersonaSkinId.memoryCollectors,
        PersonaSkinId.minimalistHabit,
      ]);
      final group = testJourney(
        kind: JourneyKind.group,
        templateId: TemplateId.workout30,
      );
      expect(
        availableLayoutsFor(group, current: PersonaSkinId.aestheticFlexer),
        containsAll([
          PersonaSkinId.accountabilitySquad,
          PersonaSkinId.aestheticFlexer,
        ]),
      );
      // A 10-member squad with a heart emoji is not a couple journey (UX-04).
      final heartSquad = testJourney(
        kind: JourneyKind.group,
        templateId: TemplateId.custom,
        emoji: '💞',
      );
      expect(
        availableLayoutsFor(
          heartSquad,
          current: PersonaSkinId.accountabilitySquad,
        ),
        isNot(contains(PersonaSkinId.coupleRituals)),
      );
    });
  });

  group('Edit journey screen', () {
    testWidgets('renames, picks colour, saves through update (UX-08)', (
      tester,
    ) async {
      final h = await _open(tester);
      expect(_key('journey-edit'), findsOneWidget);
      expect(find.text('update journey.'), findsOneWidget);
      // Dead cover and HUD pickers are gone (UX-08).
      expect(_key('edit-cover-0'), findsNothing);
      expect(_key('edit-hud-bold'), findsNothing);
      // Each colour chip carries a 14px colour dot (B6).
      for (var i = 0; i < 3; i++) {
        expect(_key('edit-color-dot-$i'), findsOneWidget);
      }
      await tester.enterText(_key('edit-name'), 'Renamed run');
      await tester.tap(_key('edit-color-1'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('edit-save-bottom'));
      await tester.tap(_key('edit-save-bottom'));
      await tester.pumpAndSettle();
      final u = h.journeys.updates.single;
      expect(u.title, 'Renamed run');
      expect(u.color, 1);
      expect(u.reminderTime, isNull);
    });

    testWidgets('saving an edit reconciles a unitless Quiet Transformer log', (
      tester,
    ) async {
      final journey = testJourney(
        templateId: TemplateId.custom,
        metricName: 'Reading',
      ).copyWith(layout: PersonaSkinId.quietTransformer);
      final h = await _open(tester, journey: journey);
      await tester.runAsync(
        () => h.container.read(hideWeightOnShareProvider.notifier).set(true),
      );
      await tester.enterText(_key('edit-name'), 'Updated log');
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('edit-save-bottom'));
      await tester.tap(_key('edit-save-bottom'));
      await tester.pumpAndSettle();
      expect(h.journeys.updates, hasLength(1));
      expect(h.journeys.prefUpdates, [
        (id: journey.id, hideMetric: true, blurMedia: null),
      ]);
    });

    testWidgets(
      'switching layout stages locally until Save, and discarding drops it (UX-18)',
      (tester) async {
        final h = await _open(tester);
        await tester.ensureVisible(_key('edit-layout-memory'));
        await tester.tap(_key('edit-layout-memory'));
        await tester.pumpAndSettle();
        expect(_key('layout-full-preview'), findsOneWidget);
        await tester.tap(_key('layout-use'));
        await tester.pumpAndSettle();
        // Staged locally: not persisted before Save.
        expect(h.journeys.updates, isEmpty);
        // Back -> Discard drops the staged layout without saving.
        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();
        await tester.tap(_key('edit-discard-confirm'));
        await tester.pumpAndSettle();
        expect(_key('journey-edit'), findsNothing);
        expect(h.journeys.updates, isEmpty);
        expect(h.journeys.journeys.single.layout, isNull);

        // Re-open, stage layout again, and Save to persist.
        h.container.read(routerProvider).go(JourneysPaths.edit('j1'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(_key('edit-layout-memory'));
        await tester.tap(_key('edit-layout-memory'));
        await tester.pumpAndSettle();
        await tester.tap(_key('layout-use'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(_key('edit-save-bottom'));
        await tester.tap(_key('edit-save-bottom'));
        await tester.pumpAndSettle();
        expect(
          h.journeys.updates.single.layout,
          PersonaSkinId.memoryCollectors,
        );
        expect(
          h.journeys.journeys.single.layout,
          PersonaSkinId.memoryCollectors,
        );
      },
    );

    testWidgets('cancel in the preview changes nothing', (tester) async {
      final h = await _open(tester);
      await tester.ensureVisible(_key('edit-layout-memory'));
      await tester.tap(_key('edit-layout-memory'));
      await tester.pumpAndSettle();
      await tester.tap(_key('layout-cancel'));
      await tester.pumpAndSettle();
      expect(h.journeys.updates, isEmpty);
    });

    testWidgets('a non-owner cannot edit', (tester) async {
      final j = testJourney(ownerId: 'someone-else');
      await _open(tester, journey: j);
      expect(_key('edit-save'), findsNothing);
      expect(_key('edit-save-bottom'), findsNothing);
      expect(find.text('Only the journey owner can edit.'), findsOneWidget);
    });

    testWidgets('picking a reminder time turns the reminder on (B-B9)', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway(granted: true);
      final h = await _open(tester, gateway: gateway);
      tester.widget<UiTimeWheel>(find.byType(UiTimeWheel)).onChanged(21, 30);
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('edit-save-bottom'));
      await tester.tap(_key('edit-save-bottom'));
      await tester.pumpAndSettle();
      expect(h.journeys.updates.single.reminderTime, '21:30');
      final setting = h.container.read(reminderSettingsProvider)['j1'];
      expect(setting?.enabled, isTrue);
      expect(setting?.time, const ReminderTime(21, 30));
      await h.container.read(reminderSchedulerProvider).reschedule();
      expect(gateway.scheduled, isNotEmpty);
    });

    testWidgets('a picked time offers the notification permission (B-B9)', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway();
      final h = await _open(tester, gateway: gateway);
      tester.widget<UiTimeWheel>(find.byType(UiTimeWheel)).onChanged(21, 30);
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('edit-save-bottom'));
      await tester.tap(_key('edit-save-bottom'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // The saved journey already carries 21:30, yet the pick still counts.
      expect(h.journeys.updates.single.reminderTime, '21:30');
      expect(_key('notification-sheet'), findsOneWidget);
      expect(h.container.read(reminderSettingsProvider)['j1']?.enabled, isTrue);
      await tester.tap(_key('notification-turn-on'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(gateway.requests, 1);
      expect(_key('journey-edit'), findsNothing);
    });

    testWidgets('ending the journey drops its pending reminders (B-B8)', (
      tester,
    ) async {
      final gateway = FakeNotificationGateway(granted: true);
      final h = await _open(tester, gateway: gateway);
      await h.container
          .read(reminderSettingsProvider.notifier)
          .save(
            'j1',
            const ReminderSetting(enabled: true, time: ReminderTime(20, 0)),
          );
      await h.container.read(reminderSchedulerProvider).reschedule();
      expect(gateway.scheduled, isNotEmpty);
      await tester.ensureVisible(_key('edit-end'));
      await tester.tap(_key('edit-end'));
      await tester.pumpAndSettle();
      await tester.tap(_key('edit-end-confirm'));
      await tester.pumpAndSettle();
      expect(h.journeys.calls, contains('end:j1'));
      expect(gateway.scheduled, isEmpty);
    });

    testWidgets('clearing the trophy removes it from the DNA (B-B13)', (
      tester,
    ) async {
      final j = testJourney(templateId: TemplateId.englishDaily)
          .copyWith(dna: {'trophy': 'IELTS 7.0'});
      final h = await _open(tester, journey: j);
      await tester.enterText(_key('edit-trophy'), '');
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('edit-save-bottom'));
      await tester.tap(_key('edit-save-bottom'));
      await tester.pumpAndSettle();
      final u = h.journeys.updates.single;
      expect(u.dna?['trophy'], isNull);
      expect(u.clear, contains('dna'));
    });

    testWidgets('an empty name says why Save is off (U19)', (tester) async {
      await _open(tester);
      expect(find.text('Give your journey a name.'), findsNothing);
      await tester.enterText(_key('edit-name'), '  ');
      await tester.pumpAndSettle();
      expect(find.text('Give your journey a name.'), findsOneWidget);
    });

    testWidgets('a couple journey keeps both names (U19)', (tester) async {
      final base = testJourney(kind: JourneyKind.group);
      final j = Journey(
        id: base.id,
        ownerId: base.ownerId,
        kind: base.kind,
        templateId: base.templateId,
        title: base.title,
        emoji: base.emoji,
        startDate: base.startDate,
        durationDays: base.durationDays,
        timezone: base.timezone,
        visibility: base.visibility,
        status: base.status,
        coupleSelfName: 'An',
        couplePartnerName: 'Binh',
        layout: PersonaSkinId.coupleRituals,
      );
      final h = await _open(tester, journey: j);
      await tester.ensureVisible(_key('edit-self'));
      await tester.enterText(_key('edit-self'), '');
      await tester.enterText(_key('edit-partner'), '');
      await tester.pumpAndSettle();
      expect(find.text('Enter both names.'), findsNWidgets(2));
      await tester.ensureVisible(_key('edit-save-bottom'));
      await tester.tap(_key('edit-save-bottom'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(h.journeys.updates, isEmpty);
    });

    testWidgets('back with unsaved edits asks before leaving (U19)', (
      tester,
    ) async {
      final h = await _open(tester);
      await tester.enterText(_key('edit-name'), 'Renamed run');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      expect(_key('journey-edit'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(_key('journey-edit'), findsOneWidget);
      expect(h.journeys.updates, isEmpty);
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      await tester.tap(_key('edit-discard-confirm'));
      await tester.pumpAndSettle();
      expect(_key('journey-edit'), findsNothing);
      expect(h.journeys.updates, isEmpty);
    });

    testWidgets(
      'unknown journey shows loading then not-found with way back to /journeys (DE-13)',
      (tester) async {
        final pending = StreamController<Journey?>();
        addTearDown(pending.close);
        final h = await pumpJourneys(
          tester,
          locale: const Locale('en'),
          extraOverrides: [
            journeyByIdProvider('missing').overrideWith(
              (ref) => pending.stream,
            ),
          ],
        );
        h.container.read(routerProvider).go(JourneysPaths.edit('missing'));
        await tester.pump();
        await tester.pump();
        expect(_key('journey-edit-loading'), findsOneWidget);
        pending.add(null);
        await tester.pumpAndSettle();
        expect(_key('journey-edit-not-found'), findsOneWidget);
        expect(find.text('Journey not found.'), findsOneWidget);
        await tester.tap(find.text('Journeys'));
        await tester.pumpAndSettle();
        expect(h.location, AppRoutes.journeys);
      },
    );

    testWidgets(
      'stream error shows error state with retry (DE-13)',
      (tester) async {
        var fail = true;
        final j = testJourney(id: 'j-err');
        await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: JourneysPaths.edit('j-err'),
          extraOverrides: [
            journeyByIdProvider('j-err').overrideWith(
              (ref) => fail
                  ? Stream<Journey?>.error(
                      const OurneyException(OurneyErrorCode.offline),
                    )
                  : Stream<Journey?>.value(j),
            ),
          ],
        );
        expect(_key('journey-edit-error'), findsOneWidget);
        fail = false;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(_key('journey-edit'), findsOneWidget);
      },
    );

    for (final dark in [false, true]) {
      testWidgets('fits 320dp at 1.35x text (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        tester.platformDispatcher.textScaleFactorTestValue = 1.35;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _open(
          tester,
          journey: testJourney(
            templateId: TemplateId.workout30,
            title: 'Một hành trình có tên rất dài để thử tràn chữ',
          ),
          size: const Size(320, 640),
        );
        expect(tester.takeException(), isNull);
        expect(_key('reminder-wheel'), findsOneWidget);
        await tester.scrollUntilVisible(
          _key('edit-save-bottom'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'reminder switch reflects RemindersScreen and turning it off clears reminderTime (UX-18)',
      (tester) async {
        final j = testJourney().copyWith(reminderTime: '07:30');
        final h = await _open(tester, journey: j);
        expect(
          tester.widget<UiSwitchRow>(_key('edit-reminder-toggle')).value,
          isTrue,
        );
        await tester.ensureVisible(_key('edit-reminder-toggle'));
        await tester.tap(_key('edit-reminder-toggle'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(_key('edit-save-bottom'));
        await tester.tap(_key('edit-save-bottom'));
        await tester.pumpAndSettle();
        final u = h.journeys.updates.single;
        expect(u.reminderTime, isNull);
        expect(u.clear, contains('reminder_time'));
        expect(
          h.container.read(reminderSettingsProvider)['j1']?.enabled,
          isFalse,
        );
      },
    );

    testWidgets(
      'squad journey visibility note explains member consent after journey ends (UX-36)',
      (tester) async {
        final j = testJourney(kind: JourneyKind.group);
        await _open(tester, journey: j);
        expect(
          find.textContaining(
            'a public link can be created with member consent once the journey ends',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'F-07: edit-vis-link is disabled on live active journey (S9)',
      (tester) async {
        await _open(tester);
        await tester.ensureVisible(_key('edit-vis-link'));
        await tester.tap(_key('edit-vis-link'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(_key('share-sensitive-warning'), findsNothing);
        expect(
          tester.widget<Semantics>(
            find.descendant(
              of: _key('edit-vis-link'),
              matching: find.byType(Semantics),
            ).first,
          ).properties.selected,
          isFalse,
        );
      },
    );

    testWidgets(
      'F-07: edit-vis-link enforces sensitive warning and passes hideWeight on imported journey',
      (tester) async {
        final base = testJourney(templateId: TemplateId.weightLoss);
        final importedWeight = Journey(
          id: base.id,
          ownerId: base.ownerId,
          kind: base.kind,
          templateId: base.templateId,
          title: base.title,
          emoji: base.emoji,
          startDate: base.startDate,
          durationDays: base.durationDays,
          timezone: base.timezone,
          visibility: JourneyVisibility.private,
          status: JourneyStatus.active,
          origin: JourneyOrigin.imported,
        );
        final h = await _open(tester, journey: importedWeight);
        await tester.runAsync(
          () => h.container.read(hideWeightOnShareProvider.notifier).set(true),
        );
        await tester.ensureVisible(_key('edit-vis-link'));
        await tester.tap(_key('edit-vis-link'));
        await tester.pumpAndSettle();
        expect(_key('share-sensitive-warning'), findsOneWidget);

        await tester.tap(_key('share-warning-confirm'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(_key('edit-save-bottom'));
        await tester.tap(_key('edit-save-bottom'));
        await tester.pumpAndSettle();

        expect(h.journeys.publicLinkCalls, [
          (id: importedWeight.id, enabled: true, hideWeight: true),
        ]);
      },
    );
  });
}
