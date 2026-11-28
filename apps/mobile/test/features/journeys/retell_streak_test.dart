import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/redirect.dart';
import 'package:ourney/features/checkin/captured_photo.dart';
import 'package:ourney/features/checkin/checkin_controller.dart';
import 'package:ourney/features/checkin/checkin_progress.dart';
import 'package:ourney/features/checkin/checkin_success.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/domain/wrapped_story.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_intro.dart';
import 'package:ourney/features/journeys/ui/widgets/timeline_common.dart';
import 'package:ourney/features/reminders/domain/reminder_plan.dart';
import 'package:ourney/features/share_card/domain/share_card_content.dart';
import 'package:ourney/features/widgets/domain/widget_snapshot.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../checkin/fakes.dart' as checkin;

Journey journey([JourneyOrigin origin = JourneyOrigin.imported]) => Journey(
  id: 'retold',
  ownerId: 'me',
  kind: JourneyKind.solo,
  templateId: TemplateId.custom,
  title: 'A few days',
  emoji: '',
  startDate: const LocalDate(2026, 11, 20),
  timezone: 'Asia/Ho_Chi_Minh',
  visibility: JourneyVisibility.private,
  status: JourneyStatus.active,
  origin: origin,
);
CheckIn photo(int day, {bool library = true, String suffix = ''}) => CheckIn(
  id: '$day-$library-$suffix',
  journeyId: 'retold',
  userId: 'me',
  localDate: LocalDate(2026, 11, day),
  capturedAt: DateTime.utc(2026, 11, day),
  photoPath: '',
  thumbPath: '',
  fromLibrary: library,
);

final now = DateTime.utc(2026, 11, 28, 5);
final retold = [photo(20), photo(23), photo(27)];
JourneyProgress progress(
  List<CheckIn> photos, {
  JourneyOrigin origin = JourneyOrigin.imported,
}) => JourneyProgress.compute(
  journey: journey(origin),
  membership: null,
  checkIns: photos,
  now: now,
);

void main() {
  setUpAll(() async {
    if (Platform.environment['RETELL_MOCK_DIR'] == null) return;
    for (final font in ['BeVietnamPro', 'BricolageGrotesque']) {
      final loader = FontLoader(font);
      loader.addFont(
        rootBundle.load(
          font == 'BeVietnamPro'
              ? 'assets/fonts/BeVietnamPro-Regular.ttf'
              : 'assets/fonts/BricolageGrotesque-Variable.ttf',
        ),
      );
      await loader.load();
    }
  });
  test('retold photos ending yesterday have no streak or at-risk state; gaps are quiet', () {
    final p = progress(retold);
    expect(p.summary.current, 0);
    expect(p.summary.best, 0);
    expect(p.summary.atRisk, isFalse);
    expect(p.showStreak, isFalse);
    expect(p.summary.completed, 3);
    expect(p.dayAt(const LocalDate(2026, 11, 21)).state, DayState.quiet);
    expect(p.dayAt(const LocalDate(2026, 11, 27)).state, DayState.checkedIn);
    final later = JourneyProgress.compute(
      journey: journey(),
      membership: null,
      checkIns: retold,
      now: now.add(const Duration(days: 2)),
    );
    expect(later.dayAt(const LocalDate(2026, 11, 28)).state, DayState.missed);
  });
  test('camera starts fresh at one, library today never builds a streak', () {
    final p = progress([...retold, photo(28, library: false)]);
    expect(p.summary.current, 1);
    expect(p.summary.best, 1);
    expect(p.showStreak, isTrue);
    final libraryToday = progress([...retold, photo(28)]);
    expect(libraryToday.summary.current, 0);
    expect(libraryToday.checkedInToday, isTrue);
    expect(libraryToday.summary.checkedInToday, isFalse);
  });
  test(
    'library photo today stays separate from camera streak in widget wire data',
    () {
      final snap = WidgetSnapshotBuilder.build(
        now: now,
        authStatus: AuthStatus.signedIn,
        journeyInputs: [
          WidgetJourneyBuildInput(
            journey: journey(),
            myCheckIns: [photo(27, library: false), photo(28)],
          ),
        ],
        currentUserId: 'me',
      );
      final item = snap.journeys.single;
      expect(item.checkedInToday, isTrue);
      expect(item.currentStreak, 1);
      expect(item.streakCheckedInToday, isFalse);
      expect(item.toJson()['streakCheckedInToday'], isFalse);
    },
  );
  for (final library in [true, false]) {
    test(
      'check-in success computes camera-only streak, library=$library',
      () async {
        final poster = CheckInPoster(
          repository: checkin.FakeCheckInRepository(),
          compressor: checkin.FakePhotoCompressor(),
          clock: checkin.FakeCheckinClock(now),
        );
        final outcome = await poster.post(
          journey: journey(),
          membership: null,
          photo: CapturedPhoto(
            journeyId: 'retold',
            path: '/retell-test.jpg',
            capturedAt: now,
            fromLibrary: library,
          ),
          mine: retold,
        );
        expect(outcome.streakBefore, 0);
        expect(outcome.streakAfter, library ? 0 : 1);
      },
    );
  }
  test('live journey keeps library streak and missed days', () {
    final p = progress(retold, origin: JourneyOrigin.live);
    expect(p.summary.current, 1);
    expect(p.summary.best, 1);
    expect(p.dayAt(const LocalDate(2026, 11, 21)).state, DayState.missed);
  });
  test('same-day camera does not hide the library boundary', () {
    final p = progress([...retold, photo(27, library: false)]);
    expect(p.retoldThrough, const LocalDate(2026, 11, 27));
    expect(p.dayAt(const LocalDate(2026, 11, 26)).state, DayState.quiet);
  });
  test('retold reminders preserve daily reminders without a streak alert', () {
    final j = journey();
    final input = JourneyReminderInput.fromJourney(
      j,
      checkedInDates: retold.map((c) => c.localDate),
      streakDates: retold
          .where((c) => countsTowardStreak(j, c))
          .map((c) => c.localDate),
      reminderTime: const ReminderTime(20, 0),
    );
    final plan = planReminders(
      now: now,
      deviceTimezone: j.timezone,
      journeys: [input],
    );
    expect(plan, isNotEmpty);
    expect(plan.every((p) => p.kind == PlannedKind.reminder), isTrue);
  });
  test('library photo today does not satisfy a live camera streak alert', () {
    final j = journey();
    final photos = [photo(27, library: false), photo(28)];
    final input = JourneyReminderInput.fromJourney(
      j,
      checkedInDates: photos.map((c) => c.localDate),
      streakDates: photos
          .where((c) => countsTowardStreak(j, c))
          .map((c) => c.localDate),
      reminderTime: const ReminderTime(20, 0),
    );
    final plan = planReminders(
      now: now,
      deviceTimezone: j.timezone,
      journeys: [input],
    );
    final today = plan.where(
      (p) => p.journeyDate == const LocalDate(2026, 11, 28),
    );
    expect(today.single.kind, PlannedKind.streakAlert);
    expect(today.single.streak, 1);
  });
  test('widget snapshot has no retold streak or at-risk state', () {
    final snap = WidgetSnapshotBuilder.build(
      now: now,
      authStatus: AuthStatus.signedIn,
      journeyInputs: [
        WidgetJourneyBuildInput(journey: journey(), myCheckIns: retold),
      ],
      currentUserId: 'me',
    );
    expect(snap.journeys.single.currentStreak, 0);
    expect(snap.journeys.single.bestStreak, 0);
    expect(snap.journeys.single.atRisk, isFalse);
    expect(snap.journeys.single.showStreak, isFalse);
    expect(snap.journeys.single.streakCheckedInToday, isFalse);
    expect(snap.journeys.single.toJson()['showStreak'], isFalse);
  });
  test('share card always uses photo days for retold journeys, even with live streak', () {
    final p = progress([...retold, photo(28, library: false)]);
    final card = ShareCardContent.from(
      journey: p.journey,
      membership: null,
      streak: p.summary,
      dayNumber: p.dayNumber,
      checkIns: p.allCheckIns,
    );
    expect(card.headline, ShareCardHeadline.checkedIn);
    expect(card.number, 4);
    expect(WrappedStats.from(p).streak, isNull);
  });
  testWidgets('retold library check-in success has no zero flame', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: testApp(
          CheckinSuccessView(
            journey: journey(),
            outcome: CheckInOutcome(
              checkIn: photo(28),
              streakBefore: 0,
              streakAfter: 0,
            ),
            haptics: false,
            onDone: () {},
            onShare: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.byKey(const ValueKey('checkin-streak')), findsNothing);
    expect(find.byType(UiStreakNumber), findsNothing);
    await tester.pump(CheckinSuccessView.autoCloseDelay);
  });
  for (final brightness in Brightness.values) {
    testWidgets('quiet cell and retold intro in ${brightness.name}', (
      tester,
    ) async {
      final p = progress(retold);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: JourneysL10n.localizationsDelegates,
          supportedLocales: JourneysL10n.supportedLocales,
          theme: OurneyTheme.build(brightness),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: key,
                child: Builder(
                  builder: (context) {
                    final l10n = JourneysL10n.of(context);
                    final empty = p.dayAt(const LocalDate(2026, 11, 21));
                    return ColoredBox(
                      color: context.ui.bg,
                      child: SizedBox(
                        width: 390,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.journeys_imported,
                                style: UiText.eyebrow(
                                  color: context.ui.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                p.journey.title,
                                style: UiText.h1(color: context.ui.ink),
                              ),
                              const SizedBox(height: 12),
                              JourneyHomeIntro(
                                skin: 'minimal',
                                day: 9,
                                streak: 0,
                                today: p.today,
                                showStreak: p.showStreak,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.journeys_wrappedPhotoDays(
                                  p.checkInsByDate.length,
                                ),
                                style: UiText.body(color: context.ui.inkMuted),
                              ),
                              const SizedBox(height: 24),
                              TimelineDayTap(
                                day: empty,
                                onTap: (_) {},
                                child: Row(
                                  children: [
                                    TimelineTile(day: empty, size: 48),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: ExcludeSemantics(
                                        child: Text(
                                          timelineDayLabel(context, empty),
                                          style: UiText.body(
                                            color: context.ui.inkMuted,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final semantics = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp(r'Day 2, .*: no photo')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              (w.painter is DashedOutlinePainter ||
                  w.foregroundPainter is DashedOutlinePainter),
        ),
        findsNothing,
      );
      expect(find.textContaining('streak'), findsNothing);
      final l10n = JourneysL10n.of(
        tester.element(find.byType(JourneyHomeIntro)),
      );
      final stats = WrappedStats.from(p);
      for (final skin in PersonaSkinId.values) {
        expect(
          wrappedBeatsFor(
            l10n,
            p.journey,
            skin,
            stats,
            localeName: l10n.localeName,
          ).map((beat) => beat.semanticsLabel).join(' ').toLowerCase(),
          isNot(contains('streak')),
        );
      }
      final mockDir = Platform.environment['RETELL_MOCK_DIR'];
      if (mockDir != null) {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(mockDir).create(recursive: true);
          await File('$mockDir/retell-streak-${brightness.name}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      semantics.dispose();
    });
  }
}
