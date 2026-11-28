import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/data/group_daily_checkins_provider.dart';
import 'package:ourney/features/camera/capture_services.dart'
    show appSettingsOpenerProvider;
import 'package:ourney/features/journeys/data/journey_reaction_count_provider.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/domain/wrapped_story.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/journey_photo.dart';
import 'package:ourney/features/journeys/ui/wrapped/journey_wrapped_screen.dart';
import 'package:ourney/features/journeys/ui/wrapped/wrapped_visuals.dart';
import 'package:ourney/features/profile/settings_providers.dart';
import 'package:ourney/features/share_card/data/share_card_exporter.dart';
import 'package:ourney/features/share_card/data/share_card_providers.dart';
import 'package:ourney/features/share_card/domain/share_card_content.dart';
import 'package:ourney/features/sharing/data/sharing_providers.dart'
    show shareStateProvider;
import 'package:ourney/features/social/data/social_providers.dart'
    show defaultSharePositionOrigin;
import 'package:ourney/ui/ui.dart' show OurneyTheme, UiButton;
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart' show testBackendConfig;
import '../checkin/fakes.dart' show FakeSettingsOpener;
import '../share_card/share_card_fakes.dart'
    show FakeExporter, FakeSaver, FakeSharer;
import 'journeys_fakes.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

final _progressSegmentPattern = RegExp(r'^wrapped-segment-\d+$');

Finder _progressSegments() => find.descendant(
  of: _key('wrapped-progress'),
  matching: find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        _progressSegmentPattern.hasMatch(key.value);
  }),
);

Future<void> _pumpTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _jumpToSummary(WidgetTester tester) async {
  await tester.tap(_progressSegments().last);
  await _pumpTransition(tester);
  expect(_key('wrapped-summary'), findsOneWidget);
}

Future<JourneysHarness> _open(
  WidgetTester tester, {
  Journey? journey,
  Size size = const Size(420, 1000),
  Locale locale = const Locale('en'),
  double? textScale,
}) async {
  final j =
      journey ??
      testJourney(status: JourneyStatus.ended, templateId: TemplateId.custom);
  final days = [10, 11, 12, 14].map((d) => LocalDate(2026, 10, d));
  final h = await pumpJourneys(
    tester,
    locale: locale,
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
  if (textScale != null) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await _pumpTransition(tester);
  return h;
}

void main() {
  testWidgets(
    'Vietnamese wrapped header has no clipped title on a small phone',
    (tester) async {
      await _open(
        tester,
        size: const Size(360, 640),
        locale: const Locale('vi'),
        textScale: 1.35,
      );
      final header = _key('wrapped-header');
      expect(header, findsOneWidget);
      final routeSemantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((widget) => widget.properties.label == 'Hành trình đã về đích')
          .single;
      expect(routeSemantics.properties.namesRoute, isTrue);
      expect(routeSemantics.properties.scopesRoute, isTrue);
      expect(
        find.descendant(
          of: header,
          matching: find.text(routeSemantics.properties.label!),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('memory summary title with length does not repeat duration', (
    tester,
  ) async {
    final j = testJourney(
      templateId: TemplateId.travel,
      title: 'Đà Lạt 7 ngày',
      durationDays: 7,
      status: JourneyStatus.ended,
    );
    await _open(tester, journey: j);
    await _jumpToSummary(tester);
    expect(find.text('ĐÀ LẠT 7\u00A0NGÀY'), findsOneWidget);
    final caption = wrappedShareText(
      lookupJourneysL10n(const Locale('en')),
      j,
      PersonaSkinId.memoryCollectors,
      const WrappedStats(
        days: 4,
        moments: 4,
        total: 7,
        streak: 4,
        totalKm: 0,
        photos: [],
        lastCaption: null,
        lastPlace: null,
        pace: null,
      ),
    );
    expect(caption, contains('ĐÀ LẠT 7 NGÀY'));
    expect(caption, isNot(contains('\u00A0')));
  });

  group('Wrapped story', () {
    testWidgets('pages advance by tap, segments jump, then the summary', (
      tester,
    ) async {
      await _open(tester);
      expect(_key('journey-wrapped'), findsOneWidget);
      expect(find.text('Journey complete'), findsNothing);
      expect(find.bySemanticsLabel('Journey complete'), findsOneWidget);
      expect(_key('wrapped-beat-open'), findsOneWidget);
      expect(_progressSegments(), findsNWidgets(7));
      await tester.tapAt(const Offset(380, 500));
      await _pumpTransition(tester);
      expect(_key('wrapped-beat-first'), findsOneWidget);
      await tester.tap(_progressSegments().at(5));
      await _pumpTransition(tester);
      expect(_key('wrapped-beat-finish'), findsOneWidget);
      await tester.tapAt(const Offset(380, 500));
      await _pumpTransition(tester);
      expect(_key('wrapped-summary'), findsOneWidget);
      expect(_key('wrapped-card-story'), findsOneWidget);
      await tester.tap(find.text('4:5'));
      await _pumpTransition(tester);
      expect(_key('wrapped-card-feed'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Edit card'), findsOneWidget);
    });

    testWidgets('U4: back arrow steps a page; story exposes scroll actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester);
      final storyFinder = find.ancestor(
        of: _key('wrapped-beat-open'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.onScrollLeft != null,
        ),
      );
      final story = tester.getSemantics(storyFinder);
      expect(
        story.getSemanticsData().hasAction(SemanticsAction.scrollLeft),
        isTrue,
      );
      expect(
        story.getSemanticsData().hasAction(SemanticsAction.scrollRight),
        isTrue,
      );
      expect(_key('wrapped-headline'), findsOneWidget);
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        story.id,
        SemanticsAction.scrollLeft,
      );
      await _pumpTransition(tester);
      expect(_key('wrapped-beat-first'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back').first);
      await _pumpTransition(tester);
      expect(_key('wrapped-beat-open'), findsOneWidget);
      expect(_key('journey-wrapped'), findsOneWidget);
      await _jumpToSummary(tester);
      expect(_key('wrapped-summary'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('left tap goes back, segment jumps to a page', (tester) async {
      await _open(tester);
      await tester.tap(_progressSegments().at(1));
      await _pumpTransition(tester);
      expect(_key('wrapped-beat-first'), findsOneWidget);
      await tester.tapAt(const Offset(40, 500));
      await _pumpTransition(tester);
      expect(_key('wrapped-beat-open'), findsOneWidget);
    });

    testWidgets(
      'a late reaction count adds the stat and preserves the summary',
      (tester) async {
        final j = testJourney(
          status: JourneyStatus.ended,
          kind: JourneyKind.group,
          templateId: TemplateId.englishDaily,
        );
        final count = Completer<int?>();
        await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: JourneysPaths.wrapped(j.id),
          journeys: FakeJourneyRepository(journeys: [j]),
          extraOverrides: [
            journeyReactionCountProvider(j.id)
                .overrideWith((_) => count.future),
          ],
        );
        expect(_progressSegments(), findsNWidgets(3));
        await _jumpToSummary(tester);

        count.complete(7);
        await _pumpTransition(tester);
        expect(_key('wrapped-summary'), findsOneWidget);
        expect(_progressSegments(), findsNWidgets(4));
        await tester.tap(_progressSegments().at(1));
        await _pumpTransition(tester);
        expect(_key('wrapped-beat-signature'), findsOneWidget);
        expect(find.text('7 reactions'), findsOneWidget);
      },
    );

    testWidgets('quiet summary has privacy toggles and hides the wordmark', (
      tester,
    ) async {
      await _open(
        tester,
        journey: testJourney(
          status: JourneyStatus.ended,
          templateId: TemplateId.custom,
          metricName: 'Weight',
          metricUnit: 'kg',
        ).copyWith(layout: PersonaSkinId.quietTransformer),
      );
      await _jumpToSummary(tester);
      expect(_key('wrapped-hide-kg'), findsOneWidget);
      expect(_key('wrapped-blur'), findsOneWidget);
      expect(_key('wrapped-blur-note'), findsOneWidget);
      expect(find.text('Always on for this card style'), findsOneWidget);
      expect(_key('wrapped-brand'), findsNothing);
      await tester.tap(_key('wrapped-hide-kg'));
      await _pumpTransition(tester);
      expect(_key('wrapped-weights'), findsOneWidget);
    });

    testWidgets(
      'F-40: wrapped-hide-kg toggle reveals weights on weightLoss journeys and uses journey metricUnit',
      (tester) async {
        final j = testJourney(
          status: JourneyStatus.ended,
          templateId: TemplateId.weightLoss,
          metricName: 'Weight',
          metricUnit: 'lb',
        );
        await _open(tester, journey: j);
        await _jumpToSummary(tester);
        expect(_key('wrapped-weights'), findsNothing);
        await tester.tap(_key('wrapped-hide-kg'));
        await _pumpTransition(tester);
        expect(_key('wrapped-weights'), findsOneWidget);
        expect(find.text('60.0 lb  >  56.0 lb'), findsOneWidget);
      },
    );

    testWidgets('U4: hide-kg and format are handed to the share card', (
      tester,
    ) async {
      final j = testJourney(
        status: JourneyStatus.ended,
        templateId: TemplateId.weightLoss,
      );
      final h = await _open(tester, journey: j);
      await _jumpToSummary(tester);
      await tester.ensureVisible(_key('wrapped-edit-card'));
      await tester.tap(_key('wrapped-edit-card'));
      await _pumpTransition(tester);
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
      await _jumpToSummary(tester);
      await tester.tap(_key('wrapped-hide-kg'));
      await _pumpTransition(tester);
      await tester.ensureVisible(_key('wrapped-edit-card'));
      await tester.tap(_key('wrapped-edit-card'));
      await _pumpTransition(tester);
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
            journeyByIdProvider('pending-id')
                .overrideWith((ref) => pending.stream),
          ],
        );
        h.container
            .read(routerProvider)
            .go(JourneysPaths.wrapped('pending-id'));
        await tester.pump();
        await tester.pump();
        expect(_key('journey-wrapped-loading'), findsOneWidget);
        pending.add(null);
        await _pumpTransition(tester);
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
        await _pumpTransition(tester);
        expect(h.location, AppRoutes.journeys);
      },
    );

    testWidgets('stream error shows error state with retry (DE-13)', (
      tester,
    ) async {
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
      await _pumpTransition(tester);
      expect(_key('journey-wrapped'), findsOneWidget);
    });

    testWidgets(
      'Share and Save image in share sheet export rendered card image, honor hide-brand toggle, and surface share errors (DE-17, UX-07)',
      (tester) async {
        expect(defaultSharePositionOrigin().isEmpty, isFalse);
        final exporter = FakeExporter();
        final sharer = FakeSharer();
        final saver = _GatedSaver();
        final settings = FakeSettingsOpener();
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
            appSettingsOpenerProvider.overrideWithValue(settings),
          ],
        );
        await _jumpToSummary(tester);
        await tester.ensureVisible(_key('wrapped-share'));
        await tester.tap(_key('wrapped-share'));
        await _pumpTransition(tester);
        expect(_key('wrapped-share-sheet'), findsOneWidget);

        await tester.tap(_key('wrapped-share-now'));
        await _pumpTransition(tester);
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
        await _pumpTransition(tester);
        await tester.tap(_key('wrapped-hide-brand'));
        await _pumpTransition(tester);
        await tester.tap(_key('wrapped-share-now'));
        await _pumpTransition(tester);
        expect(sharer.shared, hasLength(2));
        expect(sharer.shared.last.text, isNot(contains('ourney · ')));
        expect(
          sharer.shared.last.text,
          contains('https://ourney.tech/p/$token'),
        );
        expect(_key('wrapped-brand'), findsNothing);
        expect(h.location, JourneysPaths.wrapped(j.id));

        // Save image exports and saves the rendered card image.
        await tester.tap(_key('wrapped-share'));
        await _pumpTransition(tester);
        await tester.tap(_key('wrapped-share-save'));
        await _pumpTransition(tester);
        expect(saver.saved, isEmpty);
        expect(
          tester.widget<UiButton>(_key('wrapped-share')).onPressed,
          isNull,
        );
        saver.gate.complete();
        await _pumpTransition(tester);
        expect(
          tester.widget<UiButton>(_key('wrapped-share')).onPressed,
          isNotNull,
        );
        expect(saver.saved, hasLength(1));
        expect(find.text('Card saved.'), findsOneWidget);

        saver.error = const ShareCardSaveException(
          code: 'PERMISSION_DENIED',
          message: 'denied',
        );
        await tester.tap(_key('wrapped-share'));
        await _pumpTransition(tester);
        await tester.tap(_key('wrapped-share-save'));
        await _pumpTransition(tester);
        for (
          var i = 0;
          i < 12 && _key('ui-toast-action').hitTestable().evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tap(_key('ui-toast-action'));
        await _pumpTransition(tester);
        expect(settings.opened, 1);

        // A failing export shows a toast instead of an unhandled async error.
        exporter.error = const OurneyException(OurneyErrorCode.unknown);
        await tester.tap(_key('wrapped-share'));
        await _pumpTransition(tester);
        await tester.tap(_key('wrapped-share-now'));
        await _pumpTransition(tester);
        expect(tester.takeException(), isNull);
        expect(
          find.text('Something went wrong. Please try again.'),
          findsOneWidget,
        );
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
        await _jumpToSummary(tester);

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
        await _pumpTransition(tester);
      },
    );

    for (final (globalHide, membershipHide, localHide) in [
      (false, false, false),
      (false, true, false),
      (true, false, false),
      (true, true, false),
      (false, null, false),
      (false, false, true),
    ]) {
      testWidgets('Wrapped caption and PNG with global hide $globalHide, '
          'membership hide $membershipHide, and local hide $localHide', (
        tester,
      ) async {
        final j = testJourney(
          status: JourneyStatus.ended,
          templateId: TemplateId.custom,
          metricName: 'Reading',
          metricUnit: 'kg',
        ).copyWith(layout: PersonaSkinId.quietTransformer);
        final exporter = FakeExporter();
        final sharer = FakeSharer();
        final saver = FakeSaver();
        final pendingMembership = StreamController<Membership?>.broadcast();
        addTearDown(pendingMembership.close);
        final h = await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: JourneysPaths.wrapped(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {
              if (membershipHide != null)
                j.id: testMembership(j, hideMetric: membershipHide),
            },
          ),
          checkIns: FakeCheckInRepository([
            testCheckIn(j.id, const LocalDate(2026, 10, 10), metricValue: 81.2),
            testCheckIn(j.id, const LocalDate(2026, 10, 11), metricValue: 78.4),
          ]),
          extraOverrides: [
            shareCardExporterProvider.overrideWithValue(exporter),
            shareCardSharerProvider.overrideWithValue(sharer),
            shareCardSaverProvider.overrideWithValue(saver),
            if (membershipHide == null)
              myMembershipProvider(j.id)
                  .overrideWith((ref) => pendingMembership.stream),
          ],
        );
        await tester.runAsync(
          () => h.container
              .read(hideWeightOnShareProvider.notifier)
              .set(globalHide),
        );
        await _jumpToSummary(tester);
        if (!localHide) {
          await tester.tap(_key('wrapped-hide-kg'));
          await _pumpTransition(tester);
        }
        final showWeights =
            !globalHide && membershipHide == false && !localHide;
        final boundary = find.descendant(
          of: _key('wrapped-card-story'),
          matching: find.byWidgetPredicate(
            (w) => w is RepaintBoundary && w.key is GlobalKey,
          ),
        );
        expect(boundary, findsOneWidget);
        expect(
          find.descendant(of: boundary, matching: _key('wrapped-weights')),
          showWeights ? findsOneWidget : findsNothing,
        );
        await tester.ensureVisible(_key('wrapped-share'));
        await tester.tap(_key('wrapped-share'));
        await _pumpTransition(tester);
        await tester.tap(_key('wrapped-share-now'));
        await _pumpTransition(tester);
        for (final value in ['81.2', '78.4']) {
          expect(sharer.shared.single.text!.contains(value), showWeights);
        }
        await tester.tap(_key('wrapped-share'));
        await _pumpTransition(tester);
        await tester.tap(_key('wrapped-share-save'));
        await _pumpTransition(tester);
        expect(exporter.exports, hasLength(2));
        expect(saver.saved.single.path, sharer.shared.single.path);
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
            final segments = _progressSegments();
            final count = segments.evaluate().length;
            for (var i = 1; i < count; i++) {
              expect(tester.takeException(), isNull);
              await tester.tap(segments.at(i));
              await _pumpTransition(tester);
            }
            expect(_key('wrapped-summary'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.tap(find.text('4:5'));
            await _pumpTransition(tester);
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
        await _jumpToSummary(tester);
        final title = tester.widget<Text>(_key('wrapped-summary-title')).data!;
        expect(title, contains('3 CHECK-IN DAYS'));
        expect(title, isNot(contains(RegExp(r'[/%]'))));
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
        await _jumpToSummary(tester);
        // The ended-early window is Oct 10 through Oct 14: 4/5 is above 70%.
        expect(find.text('4/5 FINISHED'), findsOneWidget);
        expect(find.textContaining('0 KM'), findsNothing);
      },
    );

    testWidgets(
      'F-01 & F-09: Wrapped summary filters hidden_in_share photos and honors blurPhotosOnShareProvider across all skins',
      (tester) async {
        final j = testJourney(
          status: JourneyStatus.ended,
          templateId: TemplateId.travel,
        );
        final visiblePhoto = testCheckIn(j.id, const LocalDate(2026, 10, 10));
        final hiddenPhoto = testCheckIn(j.id, const LocalDate(2026, 10, 11));
        final pendingShareState = StreamController<JourneyShareState>();
        addTearDown(pendingShareState.close);
        final h = await pumpJourneys(
          tester,
          config: testBackendConfig,
          userId: 'u1',
          locale: const Locale('en'),
          location: JourneysPaths.wrapped(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
          checkIns: FakeCheckInRepository([visiblePhoto, hiddenPhoto]),
          extraOverrides: [
            shareStateProvider(j.id)
                .overrideWith((_) => pendingShareState.stream),
          ],
        );
        await _pumpTransition(tester);
        await tester.runAsync(
          () => h.container.read(blurPhotosOnShareProvider.notifier).set(true),
        );
        await _jumpToSummary(tester);

        final film = _key('wrapped-memory-film');
        expect(film, findsOneWidget);
        final photos = find.descendant(
          of: film,
          matching: find.byType(JourneyPhoto),
        );
        expect(photos, findsNothing);
        pendingShareState.add(
          JourneyShareState(
            journeyId: j.id,
            viewers: const [],
            story: const JourneyStory(),
            publicSettings: const PublicSettings(
              showCounts: false,
              allowPublicReactions: false,
              allowViewerRequests: false,
            ),
            hiddenCheckInIds: {hiddenPhoto.id},
          ),
        );
        await _pumpTransition(tester);
        final renderedPhotos = tester
            .widgetList<JourneyPhoto>(photos)
            .map((w) => w.checkIn.id)
            .toList();
        expect(renderedPhotos, [visiblePhoto.id]);
        final blurFilter = tester.widget<ImageFiltered>(
          find.descendant(of: film, matching: find.byType(ImageFiltered)),
        );
        expect(blurFilter.enabled, isTrue);
      },
    );

    testWidgets(
      'F-25: Wrapped share omits journey.title from shared caption when sensitive or metric hidden',
      (tester) async {
        const secretTitle = 'Hậu sản 68kg của Lan';
        final j = testJourney(
          status: JourneyStatus.ended,
          templateId: TemplateId.weightLoss,
          title: secretTitle,
          metricName: 'Weight',
          metricUnit: 'kg',
        );
        final exporter = FakeExporter();
        final sharer = FakeSharer();
        await pumpJourneys(
          tester,
          locale: const Locale('en'),
          location: JourneysPaths.wrapped(j.id),
          journeys: FakeJourneyRepository(
            journeys: [j],
            memberships: {j.id: testMembership(j)},
          ),
          checkIns: FakeCheckInRepository([
            testCheckIn(j.id, const LocalDate(2026, 10, 10), metricValue: 68.0),
            testCheckIn(j.id, const LocalDate(2026, 10, 14), metricValue: 66.5),
          ]),
          extraOverrides: [
            shareCardExporterProvider.overrideWithValue(exporter),
            shareCardSharerProvider.overrideWithValue(sharer),
          ],
        );
        await _jumpToSummary(tester);
        await tester.ensureVisible(_key('wrapped-share'));
        await tester.tap(_key('wrapped-share'));
        await _pumpTransition(tester);
        await tester.tap(_key('wrapped-share-now'));
        await _pumpTransition(tester);
        expect(sharer.shared, hasLength(1));
        expect(sharer.shared.single.text, isNot(contains(secretTitle)));

        final l10n = lookupJourneysL10n(const Locale('en'));
        final memoryCaption = wrappedShareText(
          l10n,
          testJourney(
            status: JourneyStatus.ended,
            templateId: TemplateId.travel,
            title: secretTitle,
          ),
          PersonaSkinId.memoryCollectors,
          const WrappedStats(
            days: 4,
            moments: 4,
            total: 14,
            streak: 4,
            totalKm: 0,
            photos: [],
            lastCaption: null,
            lastPlace: null,
            pace: null,
          ),
          hideTitle: true,
        );
        expect(memoryCaption, isNot(contains(secretTitle)));
      },
    );

    testWidgets(
      'F-38: Couple Wrapped export falls back to caller latest photo when partner posted on a later day',
      (tester) async {
        final j = testJourney(
          kind: JourneyKind.group,
          maxMembers: 2,
          status: JourneyStatus.ended,
        );
        final myPhoto = testCheckIn(
          j.id,
          const LocalDate(2026, 10, 12),
          userId: 'u1',
        );
        final partnerLaterPhoto = testCheckIn(
          j.id,
          const LocalDate(2026, 10, 13),
          userId: 'u2',
        );
        final stats = WrappedStats(
          days: 1,
          moments: 1,
          total: 14,
          streak: 1,
          totalKm: 0,
          photos: [myPhoto],
          lastCaption: null,
          lastPlace: null,
          pace: null,
          coupleSlots: [
            const CouplePhotoSlot(
              userId: 'u1',
              displayName: 'An',
              isMine: true,
            ),
            CouplePhotoSlot(
              userId: 'u2',
              displayName: 'Binh',
              checkIn: partnerLaterPhoto,
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: OurneyTheme.build(Brightness.light),
              home: Scaffold(
                body: WrappedVisual(
                  skin: PersonaSkinId.coupleRituals,
                  stats: stats,
                  page: 3,
                  exporting: true,
                ),
              ),
            ),
          ),
        );
        final frames = _key('wrapped-couple-frame');
        final photos = find.descendant(
          of: frames,
          matching: find.byType(JourneyPhoto),
        );
        final rendered = tester
            .widgetList<JourneyPhoto>(photos)
            .map((w) => w.checkIn.id)
            .toList();
        expect(rendered, [myPhoto.id]);
        final frame = _key('wrapped-summary-photo-${myPhoto.id}');
        expect(tester.getCenter(frame).dx, tester.getCenter(frames).dx);
        expect(tester.getSize(frame), const Size(120, 160));
      },
    );
  });
}

class _GatedSaver extends FakeSaver {
  final gate = Completer<void>();

  @override
  Future<String> saveImage({
    required String path,
    required String mimeType,
  }) async {
    await gate.future;
    return super.saveImage(path: path, mimeType: mimeType);
  }
}
