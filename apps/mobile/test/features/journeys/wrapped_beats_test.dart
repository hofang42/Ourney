import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/journey_clock.dart';
import 'package:ourney/data/group_daily_checkins_provider.dart';
import 'package:ourney/features/journeys/data/journey_reaction_count_provider.dart';
import 'package:ourney/features/journeys/domain/wrapped_story.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/journey_photo.dart';
import 'package:ourney/features/journeys/ui/wrapped/wrapped_roll.dart';
import 'package:ourney/features/journeys/ui/wrapped/wrapped_visuals.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';
import 'wrapped_stats_test.dart' show statsFor;

Finder key(String value) => find.byKey(ValueKey(value));
Future<void> transition(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  await t.pump();
}

const _templates = [
  TemplateId.weightLoss,
  TemplateId.englishDaily,
  TemplateId.travel,
  TemplateId.custom,
  TemplateId.workout30,
  TemplateId.custom,
];
const _albums = [
  'weight_loss',
  'ielts_study',
  'travel_dalat',
  'couple_rituals',
  'morning_run',
  'reading_10_pages',
];
const _titles = [
  'Nhẹ nhàng mỗi ngày',
  'Học cùng nhau',
  'Đà Lạt qua từng tấm ảnh',
  'Bữa tối của An và Mai',
  'Chạy quanh hồ',
  'Đọc trước khi ngủ',
];

Journey fixtureJourney(int index, {bool sparse = false, int? durationDays}) =>
    testJourney(
      templateId: _templates[index],
      emoji: index == 3
          ? '\u{1f49e}'
          : index == 4
          ? '\u{1f3c3}'
          : index == 5
          ? '\u{1f4da}'
          : templateFor(_templates[index]).emoji,
      status: JourneyStatus.ended,
      durationDays: durationDays ?? (sparse ? 7 : 14),
      title: _titles[index],
      kind: index == 1 || index == 3 ? JourneyKind.group : JourneyKind.solo,
      maxMembers: index == 3 ? 2 : 10,
    ).copyWith(
      dna: {
        if (index == 0) 'goal': 'lose',
        if (index == 3) 'ritual': 'cook',
        if (index == 4) ...{'sport': 'run', 'measure': 'km'},
        if (index == 5) ...{
          'habit': 'Mười trang sách',
          'reason': 'Dành thời gian cho mình',
        },
        if (index == 1) 'trophy': 'Chặng đầu tiên',
      },
    );

List<CheckIn> fixturePhotos(
  Journey j,
  int index, {
  bool sparse = false,
  int count = 7,
  int photosPerDay = 1,
}) {
  final files =
      Directory('assets/samples/${_albums[index]}')
          .listSync()
          .whereType<File>()
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (var i = 0; i < (sparse ? 2 : count); i++)
      CheckIn(
        id: 'fixture-$index-$i',
        journeyId: j.id,
        userId: 'u1',
        localDate: j.startDate.addDays(sparse ? i * 6 : i ~/ photosPerDay),
        capturedAt: DateTime.utc(2026, 10, 10 + i),
        photoPath: 'fixture/$i.jpg',
        thumbPath: 'fixture/${i}_t.jpg',
        uploaded: false,
        localPhotoFile:
            files[(i == 6 ? files.length - 1 : i % files.length)].absolute.path,
        caption: i == 0
            ? 'Buổi đầu tiên, nắng vừa lên.'
            : i == 5
            ? 'Hôm nay đã dành trọn một khoảng nhỏ cho điều mình yêu thích.'
            : null,
        metricValue: 74 - i * .25,
        extras: CheckInExtras(
          minutes: 20 + i * 3,
          km: 3 + i * .2,
          pace: '${6 - i % 2}:30',
          place: ['Hồ Xuân Hương', 'Dốc Nhà Bò', 'Cầu Đất'][i % 3],
          mood: 'light',
          cook: i.isEven ? 'An' : 'Mai',
          dish: 'Bữa tối',
          hearts: 5,
        ),
      ),
  ];
}

GroupDailySnapshot fixtureCouple(Journey j, List<CheckIn> own) =>
    GroupDailySnapshot.build(
      journey: j,
      myUserId: 'u1',
      members: const [
        MemberToday(userId: 'u1', displayName: 'An', role: MemberRole.owner),
        MemberToday(userId: 'u2', displayName: 'Mai', role: MemberRole.member),
      ],
      allCheckIns: [
        ...own,
        for (final photo in own)
          CheckIn(
            id: 'partner-${photo.id}',
            journeyId: j.id,
            userId: 'u2',
            localDate: photo.localDate,
            capturedAt: photo.capturedAt,
            photoPath: photo.photoPath,
            thumbPath: photo.thumbPath,
            uploaded: true,
            localPhotoFile: photo.localPhotoFile,
            extras: const CheckInExtras(cook: 'Mai', dish: 'Cơm', hearts: 5),
          ),
      ],
    );

Future<void> loadFonts() async {
  for (final (family, paths) in [
    (
      'BeVietnamPro',
      [
        'BeVietnamPro-Regular.ttf',
        'BeVietnamPro-Medium.ttf',
        'BeVietnamPro-SemiBold.ttf',
        'BeVietnamPro-Bold.ttf',
      ],
    ),
    ('BricolageGrotesque', ['BricolageGrotesque-Variable.ttf']),
    ('SpaceGrotesk', ['SpaceGrotesk-Variable.ttf']),
    ('Fraunces', ['Fraunces-Variable.ttf']),
    ('PlayfairDisplay', ['PlayfairDisplay-Variable.ttf']),
    (
      'BarlowCondensed',
      ['BarlowCondensed-Bold.ttf', 'BarlowCondensed-ExtraBold.ttf'],
    ),
    ('SpaceMono', ['SpaceMono-Regular.ttf', 'SpaceMono-Bold.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final path in paths) {
      loader.addFont(rootBundle.load('assets/fonts/$path'));
    }
    await loader.load();
  }
}

void main() {
  test('render fixtures resolve to the intended drawn journey glyphs', () {
    const expected = [
      'type-weight',
      'type-study',
      'type-trip',
      'type-couple',
      'type-workout',
      'type-study',
    ];
    for (var i = 0; i < expected.length; i++) {
      final journey = fixtureJourney(i);
      final glyph =
          uiJourneyGlyph(journey.emoji, journey.templateId) as OurneyIcon;
      expect(glyph.name, expected[i]);
    }
  });

  for (final minutes in [45, 60, 75]) {
    for (final index in [1, 4]) {
      test('duration copy omits zero units: skin $index, $minutes minutes', () {
        final j = testJourney(
          templateId: index == 1
              ? TemplateId.englishDaily
              : TemplateId.workout30,
          metricUnit: index == 4 ? 'min' : null,
        );
        final stats = statsFor([
          testCheckIn(
            j.id,
            j.startDate,
            extras: CheckInExtras(minutes: minutes),
          ),
        ], journey: j);
        for (final locale in ['vi', 'en']) {
          final beat = wrappedBeatsFor(
            lookupJourneysL10n(Locale(locale)),
            j,
            PersonaSkinId.values[index],
            stats,
            localeName: locale,
          ).singleWhere((b) => b.id == 'signature');
          expect(
            beat.headline,
            isNot(matches(RegExp(r'(^|\s)0 (gi\u1edd|ph\u00fat|h|min)'))),
          );
          expect(beat.headline, contains(minutes < 60 ? '45' : '1'));
          if (minutes == 75) expect(beat.headline, contains('15'));
        }
      });
    }
  }
  test('run signature shows the distance-weighted average separately', () {
    final j = fixtureJourney(4);
    final stats = statsFor(fixturePhotos(j, 4), journey: j);
    for (final locale in ['vi', 'en']) {
      final beat = wrappedBeatsFor(
        lookupJourneysL10n(Locale(locale)),
        j,
        PersonaSkinId.aestheticFlexer,
        stats,
        localeName: locale,
      ).singleWhere((b) => b.id == 'signature');
      expect(
        beat.sub,
        contains(
          '${locale == 'vi' ? 'Pace trung b\u00ecnh' : 'Average pace'} ${stats.pace}/km',
        ),
      );
    }
  });
  test('solo squad skin does not show journey reactions', () {
    final j = testJourney(
      templateId: TemplateId.englishDaily,
      kind: JourneyKind.solo,
    );
    final stats = statsFor(fixturePhotos(j, 1), journey: j);
    final beats = wrappedBeatsFor(
      lookupJourneysL10n(const Locale('en')),
      j,
      PersonaSkinId.accountabilitySquad,
      stats,
      localeName: 'en',
      reactionCount: 12,
    );
    expect(
      beats.map((b) => b.semanticsLabel).join(' '),
      isNot(contains('reactions')),
    );
  });
  for (var index = 0; index < 6; index++) {
    for (final count in [0, 1, 3, 7]) {
      test(
        'beat rules ${PersonaSkinId.values[index].name} $count photos, VI and EN',
        () {
          final j = fixtureJourney(index);
          final photos = fixturePhotos(j, index).take(count).toList();
          final s = statsFor(
            photos,
            journey: j,
            couple: fixtureCouple(j, photos),
          );
          for (final locale in ['vi', 'en']) {
            final l = lookupJourneysL10n(Locale(locale));
            final beats = wrappedBeatsFor(
              l,
              j,
              PersonaSkinId.values[index],
              s,
              localeName: locale,
            );
            final ids = beats.map((b) => b.id).toList();
            expect(ids.first, 'open');
            expect(ids.last, 'finish');
            expect(ids.contains('first'), count > 0);
            expect(ids.contains('roll'), count >= 4);
            expect(ids.length, lessThanOrEqualTo(6));
            expect(beats.last.duration, isNull);
            final copy = beats
                .map((b) => b.semanticsLabel)
                .join(' ')
                .toLowerCase();
            expect(copy, isNot(matches(RegExp(r'missed|broke|bỏ lỡ|đứt'))));
            if (!s.showRatio) {
              expect(
                wrappedSummaryTitle(l, j, PersonaSkinId.values[index], s),
                isNot(matches(RegExp(r'\d+[/\%]'))),
              );
            }
            expect(
              copy.contains(
                locale == 'vi' ? 'chuỗi dài nhất' : 'longest streak',
              ),
              count >= 3,
            );
          }
        },
      );
    }
  }

  testWidgets('squad export trophy stays above its summary title', (t) async {
    final j = fixtureJourney(1);
    await pumpJourneys(
      t,
      location: JourneysPaths.wrapped(j.id),
      journeys: FakeJourneyRepository(journeys: [j]),
      checkIns: FakeCheckInRepository(fixturePhotos(j, 1)),
    );
    await t.tap(key('wrapped-segment-6'));
    await transition(t);
    expect(key('wrapped-summary'), findsOneWidget);
    final trophy = t.getRect(key('wrapped-summary-trophy'));
    final title = t.getRect(key('wrapped-summary-title'));
    expect(t.getSize(key('wrapped-summary-trophy')), const Size(54, 54));
    expect(trophy.overlaps(title), isFalse);
  });

  testWidgets('riffle has bounded cards, 300ms cadence, pause and one haptic', (
    t,
  ) async {
    final shots = Platform.environment['WRAPPED_SHOTS_DIR'];
    if (shots != null) await loadFonts();
    final j = fixtureJourney(5, durationDays: 90);
    final seed = fixturePhotos(j, 5);
    final photos = [
      for (var i = 0; i < 90; i++)
        CheckIn(
          id: 'riffle-$i',
          journeyId: j.id,
          userId: 'u1',
          localDate: j.startDate.addDays(i),
          capturedAt: DateTime.utc(2026, 10, 10 + i),
          photoPath: 'fixture/$i.jpg',
          thumbPath: 'fixture/${i}_t.jpg',
          uploaded: false,
          localPhotoFile: seed[i % seed.length].localPhotoFile,
        ),
    ];
    final deck = statsFor(photos, journey: j).sampleRiffle();
    expect(deck, hasLength(12));
    if (shots != null) {
      await t.pumpWidget(
        const MaterialApp(home: SizedBox(key: ValueKey('riffle-precache'))),
      );
      final context = t.element(key('riffle-precache'));
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await t.runAsync(() async {
        for (final path in photos.map((p) => p.localPhotoFile!).toSet()) {
          for (final width in [240, 480]) {
            await precacheImage(
              ResizeImage(FileImage(File(path)), width: width),
              context,
            );
          }
        }
      });
      await t.pump();
    }
    final paused = ValueNotifier(false);
    addTearDown(paused.dispose);
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: OurneyTheme.build(Brightness.light),
          localizationsDelegates: const [JourneysL10n.delegate],
          home: UiSkinScope(
            skinId: uiSkinIdFor(PersonaSkinId.minimalistHabit),
            child: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: paused,
                    builder: (context, value, child) => WrappedRoll(
                      stats: statsFor(photos, journey: j),
                      blurPhotos: false,
                      paused: value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    final haptics = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    // The incoming beat starts at 0 on the first transition frame.
    final roll = find.byType(WrappedRoll);
    Finder card(int i) => find.descendant(
      of: roll,
      matching: find.byWidgetPredicate(
        (w) => w is Positioned && w.key == ValueKey(deck[i].id),
      ),
    );
    expect(card(0), findsOneWidget);
    expect(card(1), findsNothing);
    await t.pump(const Duration(milliseconds: 299));
    expect(card(1), findsNothing);
    await t.pump(const Duration(milliseconds: 1));
    expect(card(1), findsOneWidget);
    await t.pump(const Duration(milliseconds: 300));
    expect(card(2), findsOneWidget);
    paused.value = !paused.value;
    await t.pump();
    haptics.clear();
    await t.pump(const Duration(seconds: 2));
    expect(card(2), findsOneWidget);
    expect(card(3), findsNothing);
    if (shots != null) {
      await t.runAsync(() async {
        final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        File('$shots/mid-riffle.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
    paused.value = !paused.value;
    await t.pump();
    haptics.clear();
    await t.pump(const Duration(milliseconds: 3401));
    await t.pump();
    expect(card(11), findsNothing);
    expect(key('wrapped-roll-wall'), findsOneWidget);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    await t.pump(const Duration(milliseconds: 500));
    expect(haptics, hasLength(1));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion skips riffle and its haptic', (t) async {
    final j = fixtureJourney(5);
    await pumpJourneys(
      t,
      location: JourneysPaths.wrapped(j.id),
      journeys: FakeJourneyRepository(journeys: [j]),
      checkIns: FakeCheckInRepository(fixturePhotos(j, 5)),
    );
    await t.tap(key('wrapped-segment-2'));
    await transition(t);
    final haptics = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    expect(key('wrapped-roll-wall'), findsOneWidget);
    final roll = find.byType(WrappedRoll);
    for (final photo in fixturePhotos(j, 5)) {
      expect(
        find.descendant(
          of: roll,
          matching: find.byWidgetPredicate(
            (w) => w is Positioned && w.key == ValueKey(photo.id),
          ),
        ),
        findsNothing,
      );
    }
    await t.pump(const Duration(seconds: 3));
    expect(haptics, isEmpty);
  });

  testWidgets(
    'pause resumes timing; finish waits and stamp works by semantics',
    (t) async {
      final j = fixtureJourney(5);
      await pumpJourneys(
        t,
        locale: const Locale('en'),
        location: JourneysPaths.wrapped(j.id),
        journeys: FakeJourneyRepository(journeys: [j]),
        checkIns: FakeCheckInRepository(fixturePhotos(j, 5)),
      );
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await transition(t);
      await t.tap(key('wrapped-pause'));
      await t.pump();
      await t.pump(const Duration(seconds: 8));
      expect(key('wrapped-beat-open'), findsOneWidget);
      await t.tap(key('wrapped-pause'));
      await t.pump();
      await t.pump(const Duration(seconds: 4));
      await transition(t);
      expect(key('wrapped-beat-first'), findsOneWidget);
      await t.tap(key('wrapped-segment-5'));
      await transition(t);
      await t.pump(const Duration(seconds: 12));
      expect(key('wrapped-beat-finish'), findsOneWidget);
      final handle = t.ensureSemantics();
      await t.ensureVisible(key('wrapped-finish-stamp-button'));
      final node = t.getSemantics(key('wrapped-finish-stamp-button'));
      // ignore: deprecated_member_use
      t.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.tap,
      );
      await transition(t);
      expect(key('wrapped-finish-stamp'), findsOneWidget);
      expect(
        find.text('One photo at a time, at your own pace'),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  for (final reduced in [false, true]) {
    testWidgets(
      'stamp announces its result with one or zero haptics: reduced $reduced',
      (t) async {
        final j = fixtureJourney(5);
        await pumpJourneys(
          t,
          locale: const Locale('en'),
          location: JourneysPaths.wrapped(j.id),
          journeys: FakeJourneyRepository(journeys: [j]),
          checkIns: FakeCheckInRepository(fixturePhotos(j, 5)),
        );
        t.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: reduced);
        await t.tap(key('wrapped-segment-5'));
        await transition(t);
        final semantics = t.ensureSemantics();
        final haptics = <String>[];
        t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments as String);
            }
            return null;
          },
        );
        addTearDown(
          () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await t.tap(key('wrapped-finish-stamp-button'));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        await t.pump();
        expect(
          haptics,
          reduced ? isEmpty : ['HapticFeedbackType.mediumImpact'],
        );
        final label = t
            .getSemantics(key('wrapped-finish-result'))
            .getSemanticsData()
            .label;
        expect(label, contains('One photo at a time, at your own pace'));
        expect(
          label,
          contains(formatWrappedDate(j.startDate.addDays(6), 'en')),
        );
        semantics.dispose();
      },
    );
  }
  for (final index in [0, 1, 5]) {
    testWidgets('signature animation freezes and resumes for skin $index', (
      t,
    ) async {
      final j = fixtureJourney(index);
      await pumpJourneys(
        t,
        location: JourneysPaths.wrapped(j.id),
        journeys: FakeJourneyRepository(journeys: [j]),
        checkIns: FakeCheckInRepository(fixturePhotos(j, index)),
      );
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await t.tap(key('wrapped-segment-3'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      await t.pump();
      final visual = find.byType(
        index == 0
            ? WrappedCurve
            : index == 1
            ? WrappedBars
            : WrappedChain,
      );
      final builders = find.descendant(
        of: visual,
        matching: find.byType(AnimatedBuilder),
      );
      final Animation<double> animation;
      if (index == 0) {
        final painter = t
            .widget<CustomPaint>(
              find
                  .descendant(of: visual, matching: find.byType(CustomPaint))
                  .first,
            )
            .painter;
        animation = (painter as dynamic).progress as Animation<double>;
      } else {
        animation =
            t.widget<AnimatedBuilder>(builders.first).animation
                as Animation<double>;
      }
      await t.pump(const Duration(milliseconds: 100));
      final value = animation.value;
      expect(value, inExclusiveRange(0, 1));
      await t.tap(key('wrapped-pause'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(animation.value, value);
      await t.tap(key('wrapped-pause'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(animation.value, 1);
    });
  }

  testWidgets('quiet photo and kg choices stay out of the export', (t) async {
    final j = fixtureJourney(0);
    await pumpJourneys(
      t,
      locale: const Locale('en'),
      location: JourneysPaths.wrapped(j.id),
      journeys: FakeJourneyRepository(journeys: [j]),
      checkIns: FakeCheckInRepository(fixturePhotos(j, 0)),
    );
    await t.tap(key('wrapped-segment-1'));
    await transition(t);
    expect(key('wrapped-first-zoom'), findsNothing);
    for (final photo in t.widgetList<JourneyPhoto>(find.byType(JourneyPhoto))) {
      expect(photo.thumbnail, isFalse);
      expect(photo.cacheWidth, 900);
    }
    expect(
      t
          .widgetList<WrappedPhoto>(find.byType(WrappedPhoto))
          .every((p) => p.blur),
      isTrue,
    );
    await t.ensureVisible(key('wrapped-show-photos'));
    await t.tap(key('wrapped-show-photos'));
    await transition(t);
    expect(
      t
          .widgetList<WrappedPhoto>(find.byType(WrappedPhoto))
          .every((p) => !p.blur),
      isTrue,
    );
    await t.tap(key('wrapped-segment-2'));
    await transition(t);
    expect(key('wrapped-roll-wall'), findsOneWidget);
    await t.tap(key('wrapped-segment-3'));
    await transition(t);
    expect(key('wrapped-show-kg'), findsOneWidget);
    await t.tap(key('wrapped-show-kg'));
    await transition(t);
    expect(find.textContaining('lighter than day one'), findsOneWidget);
    await t.tap(key('wrapped-segment-6'));
    await transition(t);
    expect(key('wrapped-weights'), findsNothing);
    expect(
      t
          .widgetList<WrappedPhoto>(find.byType(WrappedPhoto))
          .every((p) => p.blur),
      isTrue,
    );
  });

  final shots = Platform.environment['WRAPPED_SHOTS_DIR'];
  testWidgets('empty quiet journey has two beats and no photo reveal control', (
    t,
  ) async {
    final j = fixtureJourney(0);
    await pumpJourneys(
      t,
      location: JourneysPaths.wrapped(j.id),
      journeys: FakeJourneyRepository(journeys: [j]),
    );
    expect(key('wrapped-beat-open'), findsOneWidget);
    await t.tap(key('wrapped-segment-1'));
    await transition(t);
    expect(key('wrapped-finish-ticket'), findsOneWidget);
    expect(find.byType(WrappedPhoto), findsNothing);
    expect(key('wrapped-show-photos'), findsNothing);
  });
  for (var index = 0; index < 10; index++) {
    for (final dark in [false, true]) {
      for (final size in [const Size(390, 844), const Size(360, 640)]) {
        testWidgets(
          'all beats ${index >= 6 ? ['sparse', 'few', 'long', 'busy'][index - 6] : PersonaSkinId.values[index].name} ${dark ? 'dark' : 'light'} ${size.width} at 1.35x',
          (t) async {
            if (shots != null) await loadFonts();
            final skinIndex = index >= 6 ? 5 : index;
            final slug = index >= 6
                ? ['sparse', 'few', 'long', 'busy'][index - 6]
                : _albums[index];
            final j = fixtureJourney(
              skinIndex,
              sparse: index == 6,
              durationDays: index == 8 ? 90 : null,
            );
            final photos = fixturePhotos(
              j,
              skinIndex,
              sparse: index == 6,
              count: index == 7
                  ? 3
                  : index == 8
                  ? 90
                  : index == 9
                  ? 12
                  : 7,
              photosPerDay: index == 9 ? 3 : 1,
            );
            if (shots != null) {
              await t.pumpWidget(
                const MaterialApp(
                  home: SizedBox(key: ValueKey('precache-host')),
                ),
              );
              final context = t.element(key('precache-host'));
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              await t.runAsync(() async {
                for (final path
                    in photos.map((p) => p.localPhotoFile!).toSet()) {
                  for (final width in <int?>[null, 160, 240, 480, 900]) {
                    if (!context.mounted) return;
                    await precacheImage(
                      ResizeImage.resizeIfNeeded(
                        width,
                        null,
                        FileImage(File(path)),
                      ),
                      context,
                    );
                  }
                }
              });
              await t.pump();
            }
            t.platformDispatcher.platformBrightnessTestValue = dark
                ? Brightness.dark
                : Brightness.light;
            t.platformDispatcher.textScaleFactorTestValue = 1.35;
            addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            await pumpJourneys(
              t,
              location: JourneysPaths.wrapped(j.id),
              journeys: FakeJourneyRepository(journeys: [j]),
              checkIns: FakeCheckInRepository(photos),
              extraOverrides: [
                if (index == 8)
                  journeysNowProvider.overrideWithValue(DateTime.utc(2027, 2)),
                groupDailySnapshotProvider(j)
                    .overrideWithValue(fixtureCouple(j, photos)),
                journeyReactionCountProvider(j.id)
                    .overrideWith((_) async => 12),
              ],
            );
            t.view.physicalSize = size;
            await transition(t);
            final segments = find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  RegExp(r'^wrapped-segment-\d+$')
                      .hasMatch((w.key! as ValueKey<String>).value),
            );
            final count = segments.evaluate().length;
            for (var page = 0; page < count; page++) {
              if (page > 0) {
                await t.tap(segments.at(page));
                await transition(t);
              }
              // Finish controls may be below the fold, but remain reachable.
              if (key('wrapped-finish-stamp-button').evaluate().isNotEmpty) {
                await t.ensureVisible(key('wrapped-finish-stamp-button'));
                await t.tap(key('wrapped-finish-stamp-button'));
                await transition(t);
              }
              expect(t.takeException(), isNull);
              if (index == 8 &&
                  key('wrapped-beat-signature').evaluate().isNotEmpty) {
                expect(
                  t.widget<WrappedChain>(find.byType(WrappedChain)).days,
                  hasLength(90),
                );
              }
              if (index == 8 &&
                  key('wrapped-beat-roll').evaluate().isNotEmpty) {
                expect(
                  t.widget<WrappedRoll>(find.byType(WrappedRoll)).stats.photos,
                  hasLength(90),
                );
              }

              if (skinIndex == 3 &&
                  key('wrapped-beat-signature').evaluate().isNotEmpty) {
                expect(
                  t
                      .widgetList<WrappedPhoto>(find.byType(WrappedPhoto))
                      .any((photo) => photo.checkIn.userId == 'u2'),
                  isTrue,
                );
              }
              if (skinIndex == 3 &&
                  key('wrapped-summary').evaluate().isNotEmpty) {
                expect(
                  t
                      .widgetList<WrappedPhoto>(find.byType(WrappedPhoto))
                      .every((photo) => photo.checkIn.userId == 'u1'),
                  isTrue,
                );
              }
              if (skinIndex == 1 &&
                  key('wrapped-summary').evaluate().isNotEmpty) {
                expect(
                  t
                      .getRect(key('wrapped-summary-trophy'))
                      .overlaps(t.getRect(key('wrapped-summary-title'))),
                  isFalse,
                );
              }
              if (key('wrapped-finish-ticket').evaluate().isNotEmpty) {
                for (final photo in t.widgetList<JourneyPhoto>(
                  find.byType(JourneyPhoto),
                )) {
                  expect(photo.thumbnail, isFalse);
                  expect(photo.cacheWidth, 900);
                }
              }
              if (shots != null) {
                // Flush image frame callbacks before reading the raster boundary.
                await t.pump(const Duration(milliseconds: 200));
                final beat = key('wrapped-summary').evaluate().isNotEmpty
                    ? 'summary'
                    : (find
                                  .byWidgetPredicate(
                                    (w) =>
                                        w.key is ValueKey<String> &&
                                        (w.key! as ValueKey<String>).value
                                            .startsWith('wrapped-beat-'),
                                  )
                                  .evaluate()
                                  .single
                                  .widget
                                  .key!
                              as ValueKey<String>)
                          .value
                          .substring(13);
                await t.runAsync(() async {
                  final boundary = t.renderObject<RenderRepaintBoundary>(
                    find.byType(RepaintBoundary).first,
                  );
                  final image = await boundary.toImage(pixelRatio: 2);
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  image.dispose();
                  final dir = Directory(shots)..createSync(recursive: true);
                  File(
                    '${dir.path}/$slug-${dark ? 'dark' : 'light'}-${size.width.toInt()}-$beat.png',
                  ).writeAsBytesSync(bytes!.buffer.asUint8List());
                });
              }
            }
            await t.pumpWidget(const SizedBox());
            await t.pump();
          },
        );
      }
    }
  }
}
