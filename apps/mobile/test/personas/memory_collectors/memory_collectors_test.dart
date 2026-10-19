import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/persona_theme.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/personas/memory_collectors/camera_hud.dart';
import 'package:ourney/personas/memory_collectors/l10n/generated/memory_collectors_localizations.dart';
import 'package:ourney/personas/memory_collectors/share_card.dart';
import 'package:ourney/personas/memory_collectors/timeline.dart';
import 'package:ourney_core/ourney_core.dart';

const _testTz = 'Asia/Ho_Chi_Minh';

Journey _tripJourney({
  JourneyKind kind = JourneyKind.group,
  int? durationDays = 32,
}) => Journey(
  id: 'j-trip',
  ownerId: 'u-1',
  kind: kind,
  templateId: TemplateId.travel,
  title: 'Chuyến đi Đà Lạt',
  emoji: '✈️',
  startDate: const LocalDate(2026, 10, 1),
  durationDays: durationDays,
  timezone: _testTz,
  visibility: defaultVisibilityFor(kind),
  status: JourneyStatus.active,
);

List<TimelineDay> _buildTripDays(int total) {
  const sampleCaptions = [
    'Rừng thông bình minh',
    'Săn mây Cầu Đất',
    'Đêm lửa trại',
    'Cà phê sương sớm',
  ];
  return [
    for (var i = 1; i <= total; i++)
      TimelineDay(
        date: const LocalDate(2026, 10, 1).addDays(i - 1),
        dayNumber: i,
        isToday: i == total,
        state: i < total ? DayState.checkedIn : DayState.today,
        checkIn: CheckIn(
          id: 'trip-c-$i',
          journeyId: 'j-trip',
          userId: 'u-1',
          localDate: const LocalDate(2026, 10, 1).addDays(i - 1),
          capturedAt: DateTime.utc(2026, 10, 1, 8).add(Duration(days: i - 1)),
          photoPath: 'checkins/j-trip/u-1/trip-c-$i.jpg',
          thumbPath: 'checkins/j-trip/u-1/trip-c-${i}_t.jpg',
          caption: sampleCaptions[(i - 1) % sampleCaptions.length],
          uploaded: true,
        ),
      ),
  ];
}

Future<void> _pumpMemoryWidget(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('vi'),
  double width = 390,
  double height = 844,
  double textScale = 1.0,
  bool reduceMotion = false,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);

  final pTheme = OurneyPersonaTheme.forSkin(
    PersonaSkinId.memoryCollectors,
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
          MemoryCollectorsL10n.delegate,
        ],
        supportedLocales: ourneySupportedLocales,
        theme: pTheme.toThemeData(brightness),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('M1 — ScrapbookThreadTimeline', () {
    testWidgets(
      'renders taped Polaroids on terracotta thread and scrolls smoothly for 32 days',
      (tester) async {
        final journey = _tripJourney(durationDays: 32);
        final days = _buildTripDays(32);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          for (final width in [320.0, 390.0, 430.0]) {
            await _pumpMemoryWidget(
              tester,
              ScrapbookThreadTimeline(
                key: ValueKey('m1-$brightness-$width'),
                journey: journey,
                days: days,
                photoBuilder: (_, d) => ColoredBox(
                  color: Colors.brown,
                  child: Center(child: Text('D${d.dayNumber}')),
                ),
              ),
              brightness: brightness,
              width: width,
              textScale: 1.35,
            );

            expect(
              find.byKey(const ValueKey('m1-scrapbook-header')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('polaroid-masking-tape')),
              findsWidgets,
            );
            expect(
              find.textContaining('NGÀY 01 · RỪNG THÔNG BÌNH MINH'),
              findsOneWidget,
            );

            // Scroll all the way to Day 32 to verify smooth lazy building.
            final scrollable = find.byType(Scrollable).first;
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('m1-node-day-32')),
              300,
              scrollable: scrollable,
            );
            expect(
              find.byKey(const ValueKey('m1-node-day-32')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  });

  group('M2 — DisposableFilmStampHud', () {
    testWidgets(
      'renders FILM ROLL n/N pill and amber date stamp without fake weather/location',
      (tester) async {
        final journey = _tripJourney(durationDays: 36);
        await _pumpMemoryWidget(
          tester,
          SizedBox(
            height: 440,
            child: DisposableFilmStampHud(
              journey: journey,
              checkInCount: 24,
              date: const LocalDate(2026, 10, 16),
            ),
          ),
          locale: const Locale('en'),
          width: 320,
          textScale: 1.35,
        );

        expect(find.byKey(const ValueKey('m2-film-roll-pill')), findsOneWidget);
        expect(find.text('FILM ROLL 24/36'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('m2-amber-date-stamp')),
          findsOneWidget,
        );
        expect(find.text("16 OCT '26"), findsOneWidget);

        // Must NOT fabricate temperature or location (TASKS.md §3 M2).
        expect(find.textContaining('15°C'), findsNothing);
        expect(find.textContaining('DA LAT'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('M3 — FilmContactSheetShareCard', () {
    testWidgets(
      'caps at 20 frames with frame numbers 01..20 and never shows public link for group journeys (FR-E3)',
      (tester) async {
        final groupJourney = _tripJourney(kind: JourneyKind.group);
        final checkIns = [for (final d in _buildTripDays(25)) d.checkIn!];
        var shared = false;

        await _pumpMemoryWidget(
          tester,
          FilmContactSheetShareCard(
            journey: groupJourney,
            checkIns: checkIns,
            onSharePoster: () => shared = true,
            publicLinkSection: const Text('PUBLIC_LINK_SECTION'),
            photoBuilder: (_, c) => ColoredBox(
              color: Colors.grey.shade800,
              child: Center(child: Text(c.id)),
            ),
          ),
          width: 390,
          textScale: 1.35,
        );

        expect(
          find.byKey(const ValueKey('m3-contact-sheet-board')),
          findsOneWidget,
        );
        expect(find.text('20 KHOẢNH KHẮC · PHIM 35MM'), findsOneWidget);
        expect(find.byKey(const ValueKey('m3-film-frame-01')), findsOneWidget);
        expect(find.byKey(const ValueKey('m3-film-frame-20')), findsOneWidget);
        expect(find.byKey(const ValueKey('m3-film-frame-21')), findsNothing);

        // FR-E3: Group journey must NEVER show the public link section.
        expect(find.byKey(const ValueKey('m3-solo-public-link')), findsNothing);
        expect(find.text('PUBLIC_LINK_SECTION'), findsNothing);

        await tester.ensureVisible(
          find.byKey(const ValueKey('m3-share-poster-btn')),
        );
        // The 3-column sheet is taller than the viewport at 1.35x text, so let
        // the scroll settle before hit-testing the button.
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('m3-share-poster-btn')));
        await tester.pumpAndSettle();
        expect(shared, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('allows publicLinkSection only for solo journeys', (
      tester,
    ) async {
      final soloJourney = _tripJourney(kind: JourneyKind.solo);
      final checkIns = [for (final d in _buildTripDays(4)) d.checkIn!];

      await _pumpMemoryWidget(
        tester,
        FilmContactSheetShareCard(
          journey: soloJourney,
          checkIns: checkIns,
          publicLinkSection: const Text('SOLO_PUBLIC_LINK_ALLOWED'),
          photoBuilder: (_, c) => const ColoredBox(color: Colors.black54),
        ),
        brightness: Brightness.dark,
      );

      expect(find.byKey(const ValueKey('m3-solo-public-link')), findsOneWidget);
      expect(find.text('SOLO_PUBLIC_LINK_ALLOWED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
