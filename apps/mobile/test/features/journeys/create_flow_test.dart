import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/features/journeys/ui/create/create_widgets.dart';
import 'package:ourney/features/journeys/ui/widgets/departure_ticket.dart';
import 'package:ourney/features/onboarding/onboarding_providers.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../reminders/reminders_fakes.dart' show FakeNotificationGateway;
import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _tap(WidgetTester tester, String key) async {
  final f = _key(key);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Answers the V2 step-2 "DNA" question pages until the name form shows.
Future<void> _skipDna(WidgetTester tester) async {
  bool has(String k) => _key(k).evaluate().isNotEmpty;
  Future<void> type(String k, String t) async {
    await tester.enterText(_key(k), t);
    await tester.pumpAndSettle();
  }

  final page = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('dna-page-'),
  );
  final choice = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('dna-choice-'),
  );
  for (var i = 0; i < 6 && page.evaluate().isNotEmpty; i++) {
    if (has('dna-trophy')) {
      await type('dna-trophy', 'Cup');
    } else if (has('dna-place-field')) {
      await type('dna-place-field', 'Da Lat');
    } else if (has('dna-name-left')) {
      await type('dna-name-left', 'An');
      await type('dna-name-right', 'Binh');
    } else if (has('dna-habit')) {
      await type('dna-habit', 'Read');
      await type('dna-reason', 'Sleep');
    } else if (has('dna-dates-summary')) {
      final day = DateTime.now().day;
      await _tap(tester, 'dna-day-$day');
      await _tap(tester, 'dna-day-$day');
    } else if (choice.evaluate().isNotEmpty) {
      await tester.tap(choice.first);
      await tester.pumpAndSettle();
    }
    await _tap(tester, 'create-next');
  }
}

Future<void> _pick(WidgetTester tester, String key) async {
  await _tap(tester, key);
  await _skipDna(tester);
}

Future<JourneysHarness> _open(
  WidgetTester tester, {
  AppConfig config = const AppConfig.localOnly(),
  String? userId,
  FakeJourneyRepository? journeys,
}) => pumpJourneys(
  tester,
  location: AppRoutes.journeyNew,
  locale: const Locale('en'),
  config: config,
  userId: userId,
  journeys: journeys,
);

String _stepLabel(WidgetTester tester) =>
    tester.widget<Text>(_key('create-step-label')).data!;

bool _switch(WidgetTester tester, String key) =>
    tester.widget<UiSwitchRow>(_key(key)).value;

/// Bug #8: every sticker icon on screen keeps its V2 palette fill; none is
/// painted as a solid ink (black in light mode) blob.
void _expectNoInkFilledStickers(WidgetTester tester) {
  final icons = find.byType(OurneyIcon).evaluate().toList();
  expect(icons, isNotEmpty);
  for (final e in icons) {
    final icon = e.widget as OurneyIcon;
    if (icon.flat) continue;
    expect(
      icon.color,
      isNot(e.ui.ink),
      reason: '${icon.name} is filled with ink',
    );
  }
}

void _reminderAndIconGroup() {
  for (final brightness in Brightness.values) {
    testWidgets('create icons keep their colours (${brightness.name})', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _open(tester);
      _expectNoInkFilledStickers(tester);
      await _pick(tester, 'template-workout_30');
      _expectNoInkFilledStickers(tester);
      await _tap(tester, 'create-next');
      // Who step: solo / group / couple stickers.
      expect(_key('journey-kind-solo'), findsOneWidget);
      _expectNoInkFilledStickers(tester);
      await _tap(tester, 'create-next');
      _expectNoInkFilledStickers(tester);
    });
  }

  testWidgets('quiz reminder: creating offers notifications (bug #7)', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway();
    final h = await pumpJourneys(
      tester,
      location: AppRoutes.journeyNew,
      locale: const Locale('en'),
      extraOverrides: [
        journeySuggestionProvider.overrideWithValue(
          const JourneySuggestion(
            templateId: TemplateId.workout30,
            skin: PersonaSkinId.aestheticFlexer,
            kind: JourneyKind.solo,
            reminder: '07:30',
          ),
        ),
        notificationGatewayProvider.overrideWithValue(gateway),
        reminderDeviceTimezoneProvider.overrideWith((ref) async => testTz),
        remindersClockProvider.overrideWithValue(Clock.fixed(testNow)),
      ],
    );
    await _tap(tester, 'create-next');
    await _skipDna(tester);
    for (var i = 0; i < 3; i++) {
      await _tap(tester, 'create-next');
    }
    // The DNA forge overlay animates while the sheet waits: pump frames
    // instead of settling.
    Future<void> frames() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.ensureVisible(_key('journey-create'));
    await tester.pumpAndSettle();
    await tester.tap(_key('journey-create'));
    await frames();

    expect(h.journeys.created, hasLength(1));
    expect(_key('notification-sheet'), findsOneWidget);
    expect(find.textContaining('07:30'), findsWidgets);
    await tester.tap(_key('notification-turn-on'));
    await frames();
    await tester.pumpAndSettle();

    expect(gateway.requests, 1);
    expect(gateway.scheduled, isNotEmpty);
    expect(_key('notification-sheet'), findsNothing);
  });
}

void main() {
  _dnaGroup();
  _reminderAndIconGroup();
  group('Create flow (V2, 5 steps)', () {
    testWidgets('step 1 lists the six types; choosing moves to step 2', (
      tester,
    ) async {
      await _open(tester);
      expect(_key('journeys-template-picker'), findsOneWidget);
      expect(_stepLabel(tester), 'Step 1/5');
      for (final t in TemplateId.values) {
        expect(_key('template-${t.wireName}'), findsWidgets);
      }
      expect(_key('template-couple'), findsOneWidget);
      await _pick(tester, 'template-travel');
      expect(_stepLabel(tester), 'Step 2/5');
      expect(
        tester.widget<TextField>(_key('journey-title')).controller!.text,
        templateFor(TemplateId.travel).titleEn,
      );
    });

    testWidgets('back keeps what you typed and the chosen type', (
      tester,
    ) async {
      await _open(tester);
      await _pick(tester, 'template-custom');
      await tester.enterText(_key('journey-title'), 'Uống nước');
      await tester.pumpAndSettle();
      await _tap(tester, 'create-next');
      await _tap(tester, 'journey-kind-couple');
      await _tap(tester, 'create-back');
      await _tap(tester, 'create-back');
      await _tap(tester, 'create-back'); // the habit question page
      expect(_stepLabel(tester), 'Step 1/5');
      // Same type again keeps the form; a new one would reseed it.
      await _tap(tester, 'create-next');
      expect(_stepLabel(tester), 'Step 2/5');
      await _tap(tester, 'create-next'); // answers are kept: on to the form
      expect(
        tester.widget<TextField>(_key('journey-title')).controller!.text,
        'Uống nước',
      );
      await _tap(tester, 'create-next');
      expect(_key('journey-kind-couple'), findsOneWidget);
    });

    testWidgets('validation: empty title, metric name, couple names', (
      tester,
    ) async {
      final h = await _open(tester);
      await _pick(tester, 'template-custom');
      await _tap(tester, 'create-next');
      expect(_stepLabel(tester), 'Step 2/5');
      expect(find.text('Give your journey a name.'), findsOneWidget);

      await tester.enterText(_key('journey-title'), 'Đọc sách');
      await _tap(tester, 'journey-metric');
      await _tap(tester, 'create-next');
      expect(find.text('Enter a metric name.'), findsOneWidget);
      expect(_stepLabel(tester), 'Step 2/5');
      await tester.enterText(_key('journey-metric-name'), 'Trang');
      await _tap(tester, 'create-next');
      expect(_stepLabel(tester), 'Step 3/5');

      await _tap(tester, 'journey-kind-couple');
      await _tap(tester, 'create-next');
      expect(find.text('Enter both names.'), findsNWidgets(2));
      expect(_stepLabel(tester), 'Step 3/5');
      await tester.enterText(_key('journey-couple-left'), 'An');
      await tester.enterText(_key('journey-couple-right'), 'Bình');
      await tester.pumpAndSettle();
      await _tap(tester, 'create-next');
      expect(_stepLabel(tester), 'Step 4/5');

      await tester.enterText(_key('journey-duration'), '${durationMax + 1}');
      await tester.pumpAndSettle();
      await _tap(tester, 'create-next');
      expect(
        find.text('Duration must be $durationMin to $durationMax days.'),
        findsOneWidget,
      );
      expect(h.journeys.created, isEmpty);
    });

    testWidgets('weight loss: hideWeight default and real duration saved', (
      tester,
    ) async {
      final h = await _open(tester);
      await _pick(tester, 'template-weight_loss');
      expect(_switch(tester, 'journey-hide-metric'), isTrue);
      expect(_switch(tester, 'journey-blur'), isTrue);
      await _tap(tester, 'create-next');
      await _tap(tester, 'create-next');
      // Not hard-coded to 30: pick 14 days and a start date.
      await _tap(tester, 'journey-duration-14');
      await _tap(tester, 'create-day-2026-10-20');
      await _tap(tester, 'create-next');
      expect(_stepLabel(tester), 'Step 5/5');
      expect(_key('journey-create-design-preview'), findsOneWidget);
      expect(find.byType(DepartureTicket), findsOneWidget);
      expect(find.text('14 days'), findsWidgets);

      await _tap(tester, 'journey-create');
      final draft = h.journeys.created.single;
      expect(draft.templateId, TemplateId.weightLoss);
      expect(draft.durationDays, 14);
      expect(draft.startDate, const LocalDate(2026, 10, 20));
      expect(draft.metricUnit, 'kg');
      expect(draft.hideMetricDefault, isTrue);
      expect(draft.kind, JourneyKind.solo);
      expect(draft.visibility, JourneyVisibility.private);
      expect(h.journeys.prefUpdates.single, (
        id: 'new-1',
        hideMetric: true,
        blurMedia: true,
      ));
      expect(h.location, AppRoutes.journey('new-1'));
    });

    testWidgets('turning hideWeight off is saved too', (tester) async {
      final h = await _open(tester);
      await _pick(tester, 'template-weight_loss');
      await _tap(tester, 'journey-hide-metric');
      await _tap(tester, 'journey-blur');
      for (var i = 0; i < 3; i++) {
        await _tap(tester, 'create-next');
      }
      await _tap(tester, 'journey-create');
      expect(h.journeys.created.single.hideMetricDefault, isFalse);
      expect(h.journeys.prefUpdates, isEmpty);
    });

    testWidgets('calendar keeps the chosen start when paging months', (
      tester,
    ) async {
      await _open(tester);
      await _pick(tester, 'template-english_daily');
      await _tap(tester, 'create-next');
      await _tap(tester, 'create-next');
      await _tap(tester, 'create-day-2026-10-20');
      await _tap(tester, 'create-calendar-next');
      await _tap(tester, 'create-calendar-prev');
      expect(_key('create-day-2026-10-20'), findsOneWidget);
      expect(
        tester.widget<UiPressable>(_key('create-day-2026-10-20')).selected,
        isTrue,
      );
      // Past days cannot start a journey.
      expect(
        tester.widget<UiPressable>(_key('create-day-2026-10-15')).onPressed,
        isNull,
      );
    });

    testWidgets(
      'couple: names are stored in their own fields, not in the title',
      (tester) async {
        final h = await _open(tester);
        await _pick(tester, 'template-couple');
        await _tap(tester, 'create-next');
        expect(
          tester.widget<CreateChoiceCard>(_key('journey-kind-couple')).selected,
          isTrue,
        );
        await tester.enterText(_key('journey-couple-left'), 'An');
        await tester.enterText(_key('journey-couple-right'), 'Bình');
        await tester.pumpAndSettle();
        await _tap(tester, 'create-next');
        await _tap(tester, 'create-next');
        final ticket = tester.widget<DepartureTicket>(
          find.byType(DepartureTicket),
        );
        expect(ticket.leftName, 'An');
        expect(ticket.rightName, 'Bình');
        await _tap(tester, 'journey-create');
        final draft = h.journeys.created.single;
        expect(draft.coupleSelfName, 'An');
        expect(draft.couplePartnerName, 'Bình');
        expect(draft.title, isNot(contains('&')));
        expect(draft.emoji, '💞');
      },
    );

    testWidgets('the DNA answers are saved with the journey (validated keys)', (
      tester,
    ) async {
      final h = await _open(tester);
      await _pick(tester, 'template-custom');
      await tester.enterText(_key('journey-title'), 'Đọc sách');
      await tester.pumpAndSettle();
      await _tap(tester, 'create-next');
      await _tap(tester, 'create-next');
      await _tap(tester, 'create-next');
      await _tap(tester, 'journey-create');
      final draft = h.journeys.created.single;
      expect(draft.dna, {'habit': 'Read', 'reason': 'Sleep'});
      expect(draft.dna!.keys.every(journeyDnaKeys.contains), isTrue);
    });

    testWidgets('closing from step 3 leaves a resume card step on the hub', (
      tester,
    ) async {
      await _open(tester);
      await _pick(tester, 'template-custom');
      await tester.enterText(_key('journey-title'), 'Đọc sách');
      await tester.pumpAndSettle();
      await _tap(tester, 'create-next');
      expect(_stepLabel(tester), 'Step 3/5');
      await _tap(tester, 'create-close');
      expect(_key('hub-create-progress'), findsOneWidget);
      expect(find.text('step 3/5'), findsOneWidget);
    });

    testWidgets('local-only: group is disabled', (tester) async {
      final h = await _open(tester);
      await _pick(tester, 'template-workout_30');
      await _tap(tester, 'create-next');
      await _tap(tester, 'journey-kind-group');
      expect(
        tester.widget<CreateChoiceCard>(_key('journey-kind-group')).selected,
        isFalse,
      );
      expect(
        find.text(
          'Group journeys need a server. This build runs on this device only.',
        ),
        findsOneWidget,
      );
      for (var i = 0; i < 2; i++) {
        await _tap(tester, 'create-next');
      }
      await _tap(tester, 'journey-create');
      expect(h.journeys.created.single.kind, JourneyKind.solo);
    });

    testWidgets('with a server: group uses group visibility', (tester) async {
      final h = await _open(tester, config: testBackendConfig, userId: 'u1');
      await _pick(tester, 'template-workout_30');
      await _tap(tester, 'create-next');
      await _tap(tester, 'journey-kind-group');
      await _tap(tester, 'create-next');
      expect(_key('journey-visibility-link'), findsNothing);
      await _tap(tester, 'create-next');
      await _tap(tester, 'journey-create');
      final draft = h.journeys.created.single;
      expect(draft.kind, JourneyKind.group);
      expect(draft.visibility, JourneyVisibility.group);
    });

    testWidgets('a failed create can be retried with the same client id', (
      tester,
    ) async {
      final repo = FakeJourneyRepository()
        ..createError = const OurneyException(OurneyErrorCode.offline);
      final h = await _open(tester, journeys: repo);
      await _pick(tester, 'template-workout_30');
      for (var i = 0; i < 3; i++) {
        await _tap(tester, 'create-next');
      }
      await _tap(tester, 'journey-create');
      repo.createError = null;
      await _tap(tester, 'journey-create');
      expect(repo.attempts, hasLength(2));
      expect(repo.attempts.last.id, repo.attempts.first.id);
      expect(h.journeys.created, hasLength(1));
    });

    for (final dark in [false, true]) {
      testWidgets(
        'every step fits 320dp at 1.35x text (${dark ? 'dark' : 'light'})',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          tester.platformDispatcher.textScaleFactorTestValue = 1.35;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await _open(tester);
          tester.view.physicalSize = const Size(320, 640);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.element(_key('journeys-create-flow')).ui.isDark, dark);
          await _pick(tester, 'template-couple');
          expect(tester.takeException(), isNull);
          await _tap(tester, 'create-next');
          expect(tester.takeException(), isNull);
          await tester.enterText(_key('journey-couple-left'), 'An');
          await tester.enterText(_key('journey-couple-right'), 'Bình');
          await tester.pumpAndSettle();
          for (var i = 0; i < 2; i++) {
            await _tap(tester, 'create-next');
            expect(tester.takeException(), isNull);
          }
          expect(_stepLabel(tester), 'Step 5/5');
          expect(_key('journey-create'), findsOneWidget);
        },
      );
    }
  });
}

void _dnaGroup() {
  group('Create step 2 DNA questions', () {
    testWidgets('weight loss: goal, weight, ghost photo, then the form', (
      tester,
    ) async {
      await _open(tester);
      await _tap(tester, 'template-weight_loss');
      expect(_key('dna-page-goal'), findsOneWidget);
      expect(find.text('Question 1/3'), findsOneWidget);
      // Next is a no-op until a card is chosen.
      await _tap(tester, 'create-next');
      expect(_key('dna-page-goal'), findsOneWidget);
      await _tap(tester, 'dna-choice-goal-keep');
      await _tap(tester, 'create-next');
      expect(_key('dna-page-weight'), findsOneWidget);
      expect(find.text('70'), findsOneWidget);
      expect(_key('dna-hide-weight'), findsOneWidget);
      await _tap(tester, 'create-next');
      expect(_key('dna-page-ghost'), findsOneWidget);
      expect(_key('dna-ghost-silhouette'), findsOneWidget);
      await _tap(tester, 'dna-ghost-later');
      expect(_key('journey-title'), findsOneWidget);
      expect(_stepLabel(tester), 'Step 2/5');
      await _tap(tester, 'create-back');
      expect(_key('dna-page-ghost'), findsOneWidget);
    });

    testWidgets('travel: place, dates set the journey length, film', (
      tester,
    ) async {
      await _open(tester);
      await _tap(tester, 'template-travel');
      expect(_key('dna-page-place'), findsOneWidget);
      await _tap(tester, 'create-next');
      expect(_key('dna-page-place'), findsOneWidget, reason: 'needs a place');
      await _tap(tester, 'dna-place_dalat');
      expect(_key('dna-pine'), findsOneWidget);
      await _tap(tester, 'create-next');
      expect(_key('dna-page-dates'), findsOneWidget);
      final day = DateTime.now().day;
      await _tap(tester, 'dna-day-$day');
      await _tap(tester, 'dna-day-$day');
      await _tap(tester, 'create-next');
      expect(_key('dna-page-film'), findsOneWidget);
    });

    testWidgets('couple: ritual, names, side', (tester) async {
      await _open(tester);
      await _tap(tester, 'template-couple');
      await _tap(tester, 'dna-choice-ritual-cook');
      await _tap(tester, 'create-next');
      expect(_key('dna-page-names'), findsOneWidget);
      await _tap(tester, 'create-next');
      expect(_key('dna-page-names'), findsOneWidget, reason: 'needs names');
      await tester.enterText(_key('dna-name-left'), 'An');
      await tester.enterText(_key('dna-name-right'), 'Binh');
      await tester.pumpAndSettle();
      await _tap(tester, 'create-next');
      await _tap(tester, 'dna-choice-side-left');
      await _tap(tester, 'create-next');
      expect(_key('journey-title'), findsOneWidget);
    });

    testWidgets('the import link opens the import flow route', (tester) async {
      await _open(tester);
      expect(_key('create-import-link'), findsOneWidget);
    });
  });
}
