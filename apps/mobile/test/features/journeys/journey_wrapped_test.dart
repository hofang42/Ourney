import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney/features/profile/settings_providers.dart';
import 'package:ourney/features/social/data/social_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<JourneysHarness> _open(
  WidgetTester tester, {
  Journey? journey,
  Size size = const Size(420, 1000),
}) async {
  final j =
      journey ??
      testJourney(status: JourneyStatus.ended, templateId: TemplateId.custom);
  final days = [10, 11, 12, 14].map((d) => LocalDate(2026, 10, d));
  final h = await pumpJourneys(
    tester,
    locale: const Locale('en'),
    location: JourneysPaths.wrapped(j.id),
    journeys: FakeJourneyRepository(
      journeys: [j],
      memberships: {j.id: testMembership(j)},
    ),
    checkIns: FakeCheckInRepository([
      for (final d in days)
        testCheckIn(j.id, d, caption: 'cap $d', metricValue: 70.0 - d.day),
    ]),
  );
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
  return h;
}

void main() {
  group('Wrapped story', () {
    testWidgets('pages advance by tap, segments jump, then the summary', (
      tester,
    ) async {
      await _open(tester);
      expect(_key('journey-wrapped'), findsOneWidget);
      expect(find.text('Journey complete'), findsOneWidget);
      // Minimal skin has two pages.
      expect(find.text('4 MOMENTS OVER 4 DAYS'), findsOneWidget);
      expect(_key('wrapped-segment-0'), findsOneWidget);
      expect(_key('wrapped-segment-1'), findsOneWidget);
      // U4: the last segment is the summary page.
      expect(_key('wrapped-segment-2'), findsOneWidget);
      expect(_key('wrapped-segment-3'), findsNothing);
      await tester.tapAt(const Offset(380, 500));
      await tester.pumpAndSettle();
      expect(find.textContaining('4/14 DAYS'), findsOneWidget);
      await tester.tapAt(const Offset(380, 500));
      await tester.pumpAndSettle();
      expect(_key('wrapped-summary'), findsOneWidget);
      expect(_key('wrapped-card-story'), findsOneWidget);
      await tester.tap(find.text('4:5'));
      await tester.pumpAndSettle();
      expect(_key('wrapped-card-feed'), findsOneWidget);
      expect(find.text('Export card'), findsOneWidget);
    });

    testWidgets('U4: back arrow steps a page; story exposes scroll actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester);
      final story = tester.getSemantics(_key('wrapped-headline'));
      expect(
        story.getSemanticsData().hasAction(SemanticsAction.scrollLeft),
        isTrue,
      );
      expect(story.label, isNotEmpty);
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        story.id,
        SemanticsAction.scrollLeft,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('4/14 DAYS'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(find.text('4 MOMENTS OVER 4 DAYS'), findsOneWidget);
      expect(_key('journey-wrapped'), findsOneWidget);
      await tester.tap(_key('wrapped-segment-2'));
      await tester.pumpAndSettle();
      expect(_key('wrapped-summary'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('left tap goes back, segment jumps to a page', (tester) async {
      await _open(tester);
      await tester.tap(_key('wrapped-segment-1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('4/14 DAYS'), findsOneWidget);
      await tester.tapAt(const Offset(40, 500));
      await tester.pumpAndSettle();
      expect(find.text('4 MOMENTS OVER 4 DAYS'), findsOneWidget);
    });

    testWidgets('quiet summary has privacy toggles and hides the wordmark', (
      tester,
    ) async {
      await _open(
        tester,
        journey: testJourney(
          status: JourneyStatus.ended,
          templateId: TemplateId.weightLoss,
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.tapAt(const Offset(380, 500));
        await tester.pumpAndSettle();
      }
      expect(_key('wrapped-hide-kg'), findsOneWidget);
      expect(_key('wrapped-blur'), findsOneWidget);
      expect(_key('wrapped-brand'), findsNothing);
      await tester.tap(_key('wrapped-hide-kg'));
      await tester.pumpAndSettle();
      expect(_key('wrapped-weights'), findsOneWidget);
    });

    testWidgets('U4: hide-kg and format are handed to the share card', (
      tester,
    ) async {
      final j = testJourney(
        status: JourneyStatus.ended,
        templateId: TemplateId.weightLoss,
      );
      final h = await _open(tester, journey: j);
      for (var i = 0; i < 4; i++) {
        await tester.tapAt(const Offset(380, 500));
        await tester.pumpAndSettle();
      }
      await tester.tap(_key('wrapped-cta'));
      await tester.pumpAndSettle();
      final uri = Uri.parse(h.location);
      expect(uri.path, '/share/${j.id}');
      expect(uri.queryParameters['hideMetric'], 'true');
      expect(uri.queryParameters['format'], 'story');
      expect(uri.queryParameters.containsKey('blur'), isFalse);
      expect(find.text('Save image'), findsNothing);
    });

    testWidgets('U4: turning hide-kg off is handed over as false', (
      tester,
    ) async {
      final j = testJourney(
        status: JourneyStatus.ended,
        templateId: TemplateId.weightLoss,
      );
      final h = await _open(tester, journey: j);
      for (var i = 0; i < 4; i++) {
        await tester.tapAt(const Offset(380, 500));
        await tester.pumpAndSettle();
      }
      await tester.tap(_key('wrapped-hide-kg'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('wrapped-edit-card'));
      await tester.tap(_key('wrapped-edit-card'));
      await tester.pumpAndSettle();
      expect(Uri.parse(h.location).queryParameters['hideMetric'], 'false');
    });

    testWidgets(
      'loading, unknown journey, and stream error states render cleanly (DE-13)',
      (tester) async {
        final pending = StreamController<Journey?>();
        addTearDown(pending.close);
        final h = await pumpJourneys(
          tester,
          locale: const Locale('en'),
          extraOverrides: [
            journeyByIdProvider('pending-id').overrideWith(
              (ref) => pending.stream,
            ),
          ],
        );
        h.container.read(routerProvider).go(JourneysPaths.wrapped('pending-id'));
        await tester.pump();
        await tester.pump();
        expect(_key('journey-wrapped-loading'), findsOneWidget);
        pending.add(null);
        await tester.pumpAndSettle();
        expect(_key('journey-wrapped-not-found'), findsOneWidget);
      },
    );

    testWidgets(
      'unknown journey shows not-found with way back to /journeys (DE-13)',
      (tester) async {
        final h = await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: JourneysPaths.wrapped('missing'),
        );
        expect(_key('journey-wrapped-not-found'), findsOneWidget);
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
        final j = testJourney(
          id: 'j-err',
          status: JourneyStatus.ended,
          templateId: TemplateId.custom,
        );
        await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: JourneysPaths.wrapped('j-err'),
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
        expect(_key('journey-wrapped-error'), findsOneWidget);
        fail = false;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(_key('journey-wrapped'), findsOneWidget);
      },
    );

    testWidgets(
      'Messages and Other apps in share sheet honor hide-brand toggle, iPad origin, and surface share errors (DE-17)',
      (tester) async {
        expect(defaultSharePositionOrigin().isEmpty, isFalse);
        final shared = <String>[];
        var shouldThrow = false;
        final token = 'pub${'0' * 37}';
        final base = testJourney(
          status: JourneyStatus.ended,
          templateId: TemplateId.custom,
        );
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
          visibility: JourneyVisibility.link,
          status: base.status,
          publicToken: token,
        );
        final h = await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: JourneysPaths.wrapped(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
          checkIns: FakeCheckInRepository([
            testCheckIn(j.id, const LocalDate(2026, 10, 10)),
          ]),
          extraOverrides: [
            socialShareLauncherProvider.overrideWithValue((text) async {
              if (shouldThrow) {
                throw const OurneyException(OurneyErrorCode.unknown);
              }
              shared.add(text);
            }),
          ],
        );
        await tester.tap(_key('wrapped-segment-2'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(_key('wrapped-share'));
        await tester.tap(_key('wrapped-share'));
        await tester.pumpAndSettle();
        expect(_key('wrapped-share-sheet'), findsOneWidget);

        await tester.tap(_key('wrapped-share-messages'));
        await tester.pumpAndSettle();
        expect(shared, hasLength(1));
        expect(shared.single, contains(j.title));
        expect(shared.single, contains('ourney · https://ourney.tech/p/$token'));
        expect(h.location, JourneysPaths.wrapped(j.id));

        // Toggling "Hide the ourney wordmark" in the sheet hides the brand
        // on the card AND removes the `ourney · ` wordmark from the shared text.
        await tester.tap(_key('wrapped-share'));
        await tester.pumpAndSettle();
        await tester.tap(_key('wrapped-hide-brand'));
        await tester.pumpAndSettle();
        await tester.tap(_key('wrapped-share-other'));
        await tester.pumpAndSettle();
        expect(shared, hasLength(2));
        expect(shared.last, isNot(contains('ourney · ')));
        expect(shared.last, contains('https://ourney.tech/p/$token'));
        expect(_key('wrapped-brand'), findsNothing);
        expect(h.location, JourneysPaths.wrapped(j.id));

        // A failing share launcher shows a toast instead of an unhandled async error.
        shouldThrow = true;
        await tester.tap(_key('wrapped-share'));
        await tester.pumpAndSettle();
        await tester.tap(_key('wrapped-share-messages'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      },
    );

    for (final (globalHide, membershipHide) in [
      (false, false),
      (false, true),
      (true, false),
      (true, true),
    ]) {
      testWidgets('Wrapped caption with global hide $globalHide and '
          'membership hide $membershipHide', (tester) async {
        final j = testJourney(
          status: JourneyStatus.ended,
          templateId: TemplateId.custom,
          metricName: 'Reading',
          metricUnit: 'kg',
        ).copyWith(layout: PersonaSkinId.quietTransformer);
        final shared = <String>[];
        final h = await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: JourneysPaths.wrapped(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j, hideMetric: membershipHide)},
          ),
          checkIns: FakeCheckInRepository([
            testCheckIn(j.id, const LocalDate(2026, 10, 10), metricValue: 81.2),
            testCheckIn(j.id, const LocalDate(2026, 10, 11), metricValue: 78.4),
          ]),
          extraOverrides: [
            socialShareLauncherProvider.overrideWithValue((text) async {
              shared.add(text);
            }),
          ],
        );
        await tester.runAsync(
          () => h.container
              .read(hideWeightOnShareProvider.notifier)
              .set(globalHide),
        );
        await tester.tap(_key('wrapped-segment-4'));
        await tester.pumpAndSettle();
        await tester.tap(_key('wrapped-hide-kg'));
        await tester.pumpAndSettle();
        expect(_key('wrapped-weights'), findsOneWidget);
        await tester.ensureVisible(_key('wrapped-share'));
        await tester.tap(_key('wrapped-share'));
        await tester.pumpAndSettle();
        await tester.tap(_key('wrapped-share-messages'));
        await tester.pumpAndSettle();
        for (final value in ['81.2', '78.4']) {
          expect(
            shared.single.contains(value),
            !(globalHide || membershipHide),
          );
        }
      });
    }

    for (final skin in [
      TemplateId.weightLoss,
      TemplateId.englishDaily,
      TemplateId.travel,
      TemplateId.workout30,
      TemplateId.custom,
    ]) {
      for (final dark in [false, true]) {
        testWidgets(
          '${skin.wireName} story + summary fit 320dp at 1.35x (${dark ? 'dark' : 'light'})',
          (tester) async {
            tester.platformDispatcher.platformBrightnessTestValue = dark
                ? Brightness.dark
                : Brightness.light;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
            tester.platformDispatcher.textScaleFactorTestValue = 1.35;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await _open(
              tester,
              journey: testJourney(
                status: JourneyStatus.ended,
                templateId: skin,
                title: 'Một hành trình có tên rất dài để thử tràn chữ',
              ),
              size: const Size(320, 640),
            );
            for (var i = 0; i < 6; i++) {
              expect(tester.takeException(), isNull);
              await tester.tapAt(const Offset(300, 400));
              await tester.pumpAndSettle();
            }
            expect(_key('wrapped-summary'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.tap(find.text('4:5'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets(
      'open-ended journey computes consistency against elapsed span, not 100% (UX-20)',
      (tester) async {
        // Started Oct 1, checked in on Oct 1, 5, 10 (3 out of 10 elapsed days).
        final j = Journey(
          id: 'j-open',
          ownerId: 'u1',
          kind: JourneyKind.solo,
          templateId: TemplateId.custom,
          title: 'Daily read',
          emoji: '✨',
          startDate: const LocalDate(2026, 10, 1),
          durationDays: null,
          timezone: testTz,
          visibility: JourneyVisibility.private,
          status: JourneyStatus.ended,
        );
        await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: JourneysPaths.wrapped(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
          checkIns: FakeCheckInRepository([
            testCheckIn(j.id, const LocalDate(2026, 10, 1)),
            testCheckIn(j.id, const LocalDate(2026, 10, 5)),
            testCheckIn(j.id, const LocalDate(2026, 10, 10)),
          ]),
        );
        await tester.tap(_key('wrapped-segment-2'));
        await tester.pumpAndSettle();
        expect(find.text('3/10 DAYS · 30% CONSISTENT'), findsOneWidget);
      },
    );

    testWidgets(
      'non-running workout wrapped summary shows completed days instead of 0 KM (UX-24)',
      (tester) async {
        final j = testJourney(
          status: JourneyStatus.ended,
          templateId: TemplateId.workout30,
        ).copyWith(dna: const {'sport': 'gym', 'measure': 'session'});
        await _open(tester, journey: j);
        await tester.tap(_key('wrapped-segment-4'));
        await tester.pumpAndSettle();
        expect(find.text('4/14 FINISHED'), findsOneWidget);
        expect(find.textContaining('0 KM'), findsNothing);
      },
    );
  });
}
