import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney/features/share_card/data/share_card_exporter.dart';
import 'package:ourney/features/share_card/data/share_card_providers.dart';
import 'package:ourney/features/share_card/domain/share_card_content.dart';
import 'package:ourney/features/social/data/social_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../share_card/share_card_fakes.dart' show FakeExporter, FakeSaver, FakeSharer;
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
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Edit card'), findsOneWidget);
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
      expect(_key('wrapped-blur-note'), findsOneWidget);
      expect(find.text('Always on for this card style'), findsOneWidget);
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
      await tester.ensureVisible(_key('wrapped-edit-card'));
      await tester.tap(_key('wrapped-edit-card'));
      await tester.pumpAndSettle();
      final uri = Uri.parse(h.location);
      expect(uri.path, '/share/${j.id}');
      expect(uri.queryParameters['hideMetric'], 'true');
      expect(uri.queryParameters['format'], 'story');
      expect(uri.queryParameters.containsKey('blur'), isFalse);
      expect(_key('wrapped-edit-card'), findsNothing);
      expect(_key('share-card-save'), findsOneWidget);
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
      'Share and Save image in share sheet export rendered card image, honor hide-brand toggle, and surface share errors (DE-17, UX-07)',
      (tester) async {
        expect(defaultSharePositionOrigin().isEmpty, isFalse);
        final exporter = FakeExporter();
        final sharer = FakeSharer();
        final saver = FakeSaver();
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
            shareCardExporterProvider.overrideWithValue(exporter),
            shareCardSharerProvider.overrideWithValue(sharer),
            shareCardSaverProvider.overrideWithValue(saver),
          ],
        );
        await tester.tap(_key('wrapped-segment-2'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(_key('wrapped-share'));
        await tester.tap(_key('wrapped-share'));
        await tester.pumpAndSettle();
        expect(_key('wrapped-share-sheet'), findsOneWidget);

        await tester.tap(_key('wrapped-share-now'));
        await tester.pumpAndSettle();
        expect(exporter.exports, hasLength(1));
        expect(exporter.exports.single.boundarySize, const Size(360, 640));
        expect(sharer.shared, hasLength(1));
        expect(sharer.shared.single.path, contains('ourney-${j.id}-story.png'));
        expect(sharer.shared.single.text, contains(j.title));
        expect(
          sharer.shared.single.text,
          contains('ourney · https://ourney.tech/p/$token'),
        );
        expect(h.location, JourneysPaths.wrapped(j.id));

        // Toggling "Hide the ourney wordmark" in the sheet hides the brand
        // on the card AND removes the `ourney · ` wordmark from the shared text.
        await tester.tap(_key('wrapped-share'));
        await tester.pumpAndSettle();
        await tester.tap(_key('wrapped-hide-brand'));
        await tester.pumpAndSettle();
        await tester.tap(_key('wrapped-share-now'));
        await tester.pumpAndSettle();
        expect(sharer.shared, hasLength(2));
        expect(sharer.shared.last.text, isNot(contains('ourney · ')));
        expect(sharer.shared.last.text, contains('https://ourney.tech/p/$token'));
        expect(_key('wrapped-brand'), findsNothing);
        expect(h.location, JourneysPaths.wrapped(j.id));

        // Save image exports and saves the rendered card image.
        await tester.tap(_key('wrapped-share'));
        await tester.pumpAndSettle();
        await tester.tap(_key('wrapped-share-save'));
        await tester.pumpAndSettle();
        expect(saver.saved, hasLength(1));
        expect(find.text('Card saved.'), findsOneWidget);

        // A failing export shows a toast instead of an unhandled async error.
        exporter.error = const OurneyException(OurneyErrorCode.unknown);
        await tester.tap(_key('wrapped-share'));
        await tester.pumpAndSettle();
        await tester.tap(_key('wrapped-share-now'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      },
    );

    testWidgets(
      'UX-07: Wrapped summary RepaintBoundary exports exact 1080x1920 and 1080x1350 images with real ShareCardExporter',
      (tester) async {
        final dir = await tester.runAsync(
          () => Directory.systemTemp.createTemp('wrapped_export_test'),
        );
        addTearDown(() => dir!.deleteSync(recursive: true));
        final realExporter = ShareCardExporter(tempDirectory: () async => dir!);
        await _open(tester);
        await tester.tap(_key('wrapped-segment-2'));
        await tester.pumpAndSettle();

        RenderRepaintBoundary findCardBoundary(String cardKey) {
          final boundaryFinder = find.descendant(
            of: _key(cardKey),
            matching: find.byWidgetPredicate(
              (w) => w is RepaintBoundary && w.key is GlobalKey,
            ),
          );
          return tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
        }

        // Story (9:16 -> logical 360x640 -> pixel 1080x1920).
        final storyBoundary = findCardBoundary('wrapped-card-story');
        expect(storyBoundary.size, const Size(360, 640));
        final storyFile = await tester.runAsync(
          () => realExporter.export(
            storyBoundary,
            ShareCardFormat.story,
            baseName: 'ourney-j1-story',
          ),
        );
        expect(storyFile, isNotNull);
        expect(storyFile!.image.width, 1080);
        expect(storyFile.image.height, 1920);
        expect(storyFile.path, endsWith('ourney-j1-story.png'));

        // Switch to Feed (4:5 -> logical 360x450 -> pixel 1080x1350) and verify
        // export succeeds even mid-morph while TweenAnimationBuilder is in flight.
        await tester.tap(find.text('4:5'));
        await tester.pump(const Duration(milliseconds: 80));
        final feedBoundary = findCardBoundary('wrapped-card-feed');
        expect(feedBoundary.size, const Size(360, 450));
        final feedFile = await tester.runAsync(
          () => realExporter.export(
            feedBoundary,
            ShareCardFormat.feed,
            baseName: 'ourney-j1-feed',
          ),
        );
        expect(feedFile, isNotNull);
        expect(feedFile!.image.width, 1080);
        expect(feedFile.image.height, 1350);
        expect(feedFile.path, endsWith('ourney-j1-feed.png'));
        await tester.pumpAndSettle();
      },
    );

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
