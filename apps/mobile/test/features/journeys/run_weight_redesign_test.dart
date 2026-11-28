import 'dart:io';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/checkin/post_extras.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/journeys_paths.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_intro.dart';
import 'package:ourney/features/journeys/ui/journey_photo.dart';
import 'package:ourney/features/journeys/ui/widgets/photo_log_timelines.dart';
import 'package:ourney/features/journeys/ui/widgets/timeline_common.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import 'journeys_fakes.dart';

const _timeout = Timeout(Duration(seconds: 60));
Finder _key(String key) => find.byKey(ValueKey(key));
ProviderContainer? _activeContainer;

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<ProviderContainer> _open(
  WidgetTester tester,
  Journey journey,
  List<CheckIn> photos, {
  Locale locale = const Locale('vi'),
  double width = 390,
  Brightness brightness = Brightness.light,
  double scale = 1,
  GlobalKey? boundary,
  MediaStore? media,
}) async {
  if (_activeContainer != null) {
    await tester.pumpWidget(const SizedBox.shrink());
    _activeContainer!.dispose();
    _activeContainer = null;
    await _frames(tester);
  }
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  final prefs = await testPrefs({
    OnboardingComplete.prefsKey: true,
    SafetyPrefs.eulaAccepted: true,
  });
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      supabaseClientProvider.overrideWithValue(null),
      journeyRepositoryProvider.overrideWithValue(
        FakeJourneyRepository(
          journeys: [journey],
          memberships: {journey.id: testMembership(journey)},
        ),
      ),
      checkInRepositoryProvider.overrideWithValue(
        FakeCheckInRepository(photos),
      ),
      mediaStoreProvider.overrideWithValue(media ?? FakeMediaStore()),
      journeysClockProvider.overrideWithValue(Clock.fixed(testNow)),
      deviceTimezoneProvider.overrideWith((ref) => testTz),
      journeyHomeOfflineProvider.overrideWith((ref) => Stream.value(false)),
    ],
  );
  _activeContainer = container;
  addTearDown(() {
    if (_activeContainer == container) {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
      container.dispose();
      _activeContainer = null;
    }
  });
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: UncontrolledProviderScope(
        container: container,
        child: const OurneyApp(),
      ),
    ),
  );
  await _frames(tester);
  container.read(routerProvider).go(AppRoutes.journey(journey.id));
  await _frames(tester);
  return container;
}

Journey _journey({
  bool weight = false,
  bool gym = false,
  int elapsed = 21,
  int? duration = 30,
}) => testJourney(
  templateId: weight ? TemplateId.weightLoss : TemplateId.workout30,
  title: weight ? 'Nhìn lại từng chút' : 'Chạy sáng',
  startDate: testToday.addDays(1 - elapsed),
  durationDays: duration,
  metricName: weight ? 'Cân nặng' : null,
  metricUnit: weight ? 'kg' : null,
).copyWith(dna: weight ? null : {'sport': gym ? 'gym' : 'run'});

List<CheckIn> _photos(Journey j) => [
  for (var i = 0; i < 18; i++)
    testCheckIn(
      j.id,
      j.startDate.addDays(i < 7 ? i : i + 2),
      metricValue: j.templateId == TemplateId.weightLoss
          ? 74.0 - i * .15
          : null,
      extras: j.templateId == TemplateId.workout30
          ? const CheckInExtras(km: 4.8, pace: '5:42')
          : CheckInExtras.empty,
    ),
];

List<CheckIn> _renderPhotos(Journey journey) {
  const entries = [
    (day: 0, kg: 74.0, km: 3.2, pace: '6:18'),
    (day: 1, kg: 74.2, km: 4.6, pace: '6:04'),
    (day: 2, kg: 73.9, km: 3.8, pace: '5:57'),
    (day: 3, kg: 73.6, km: 6.3, pace: '5:48'),
    (day: 4, kg: 73.8, km: 2.7, pace: '6:25'),
    (day: 5, kg: 73.4, km: 5.1, pace: '5:42'),
    (day: 6, kg: 73.5, km: 7.8, pace: '6:12'),
    (day: 9, kg: 73.1, km: 4.4, pace: null),
    (day: 10, kg: 73.4, km: 5.4, pace: '5:35'),
    (day: 11, kg: 73.0, km: 3.1, pace: '6:15'),
    (day: 12, kg: 72.8, km: 7.2, pace: '5:56'),
    (day: 13, kg: 72.9, km: 4.2, pace: '5:32'),
    (day: 14, kg: 72.5, km: 6.5, pace: '5:46'),
    (day: 16, kg: 72.6, km: 3.6, pace: '5:59'),
    (day: 17, kg: 72.2, km: 4.9, pace: '5:22'),
    (day: 18, kg: 72.5, km: 7.4, pace: '5:52'),
    (day: 19, kg: 72.1, km: 3.3, pace: '6:07'),
    (day: 20, kg: 72.0, km: 5.2, pace: '5:42'),
  ];
  final weight = journey.templateId == TemplateId.weightLoss;
  return [
    for (final entry in entries)
      testCheckIn(
        journey.id,
        journey.startDate.addDays(entry.day),
        metricValue: weight ? entry.kg : null,
        extras: weight
            ? CheckInExtras.empty
            : CheckInExtras(km: entry.km, pace: entry.pace),
      ),
  ];
}

class _FixtureMedia implements MediaStore {
  _FixtureMedia(List<CheckIn> photos, {required bool weight}) {
    final assets = weight
        ? [
            'weight_loss/02.webp',
            'weight_loss/cover.webp',
            'weight_loss/03.webp',
          ]
        : [
            'morning_run/01.webp',
            'workout_30/01.webp',
            'morning_run/cover.webp',
          ];
    for (var i = 0; i < photos.length; i++) {
      final path = 'assets/samples/${assets[i % assets.length]}';
      _files[photos[i].photoPath] = path;
      _files[photos[i].thumbPath] = path;
    }
  }

  final _files = <String, String>{};

  @override
  Future<String> localFileFor(String storagePath) async => _files[storagePath]!;
}

void main() {
  testWidgets(
    'run totals use locale decimals, omit gaps and future days, and retain flame',
    (tester) async {
      final j = _journey();
      await _open(tester, j, _photos(j));
      expect(find.text('86,4 km'), findsOneWidget);
      expect(find.text('5:42 /km'), findsOneWidget);
      expect(_key('run-bar-${j.startDate.addDays(7)}'), findsNothing);
      expect(_key('day-${testToday.addDays(1)}'), findsNothing);
      expect(find.text('Còn 9 ngày'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is OurneyIcon && w.name == 'flame'),
        findsOneWidget,
      );
      await _open(tester, j, _photos(j), locale: const Locale('en'));
      expect(find.text('86.4 km'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    timeout: _timeout,
  );

  testWidgets(
    'weight numbers reset when the app goes inactive or another route opens',
    (tester) async {
      final j = _journey(weight: true);
      final container = await _open(tester, j, _photos(j));
      final semantics = tester.ensureSemantics();

      expect(find.textContaining(RegExp(r'\d+[,.]\d kg')), findsNothing);
      expect(find.bySemanticsLabel('Hiện số'), findsOneWidget);
      final toggle = _key('weight-trend-toggle');
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await _frames(tester);
      expect(find.textContaining(RegExp(r'\d+[,.]\d kg')), findsWidgets);
      final hide = find.bySemanticsLabel('Ẩn số');
      expect(hide, findsOneWidget);
      expect(
        tester.getSemantics(hide),
        isSemantics(hasToggledState: true, isToggled: true),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await _frames(tester);
      expect(find.textContaining(RegExp(r'\d+[,.]\d kg')), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.tap(toggle);
      await _frames(tester);
      expect(find.textContaining(RegExp(r'\d+[,.]\d kg')), findsWidgets);

      final router = container.read(routerProvider);
      final viewer = router.push(JourneysPaths.day(j.id, j.startDate));
      await _frames(tester);
      expect(_key('journey-day-metric-shown'), findsOneWidget);
      router.pop();
      await viewer;
      await _frames(tester);
      expect(find.textContaining(RegExp(r'\d+[,.]\d kg')), findsNothing);
      await tester.tap(toggle);
      await _frames(tester);
      expect(find.textContaining(RegExp(r'\d+[,.]\d kg')), findsWidgets);
      container.read(routerProvider).go('/journeys');
      await _frames(tester);
      container.read(routerProvider).go(AppRoutes.journey(j.id));
      await _frames(tester);
      expect(find.textContaining(RegExp(r'\d+[,.]\d kg')), findsNothing);
      expect(_key('missed-day-chip'), findsNothing);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
    timeout: _timeout,
  );

  testWidgets('custom weight metrics start masked in the day viewer', (
    tester,
  ) async {
    final journey = testJourney(
      templateId: TemplateId.custom,
      metricName: 'Morning weight',
      metricUnit: 'kg',
    );
    final photo = testCheckIn(journey.id, testToday, metricValue: 72.4);
    final container = await _open(tester, journey, [
      photo,
    ], locale: const Locale('en'));
    container.read(routerProvider).go(JourneysPaths.day(journey.id, testToday));
    await _frames(tester);
    expect(find.text('Morning weight:'), findsOneWidget);
    expect(find.text('72.4 kg'), findsNothing);
    await tester.tap(find.text('Show'));
    await _frames(tester);
    expect(find.text('72.4 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: _timeout);

  testWidgets(
    'weight day viewer starts private even with hideMetric off and localizes reveal',
    (tester) async {
      final j = _journey(weight: true);
      final photo = testCheckIn(j.id, testToday, metricValue: 72.4);
      final c = await _open(tester, j, [photo], locale: const Locale('en'));
      c.read(routerProvider).go(JourneysPaths.day(j.id, testToday));
      await _frames(tester);
      expect(find.text('72.4 kg'), findsNothing);
      expect(find.text('Weight:'), findsOneWidget);
      expect(find.text('••.• kg'), findsOneWidget);
      await tester.tap(find.text('Show'));
      await _frames(tester);
      expect(find.text('72.4 kg'), findsOneWidget);
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _frames(tester);
      expect(find.text('72.4 kg'), findsNothing);
      expect(find.text('Show'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final vi = await _open(tester, j, [photo], width: 320, scale: 1.35);
      vi.read(routerProvider).go(JourneysPaths.day(j.id, testToday));
      await _frames(tester);
      expect(find.text('72,4 kg'), findsNothing);
      expect(find.text('••,• kg'), findsOneWidget);
      await tester.ensureVisible(find.text('Hiện'));
      await _frames(tester);
      await tester.tap(find.text('Hiện'));
      await _frames(tester);
      expect(find.text('72,4 kg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    timeout: _timeout,
  );

  for (final brightness in Brightness.values) {
    testWidgets('viewer reveal uses themed ink in ${brightness.name}', (
      tester,
    ) async {
      final j = _journey(weight: true);
      final photo = testCheckIn(j.id, testToday, metricValue: 72.4);
      final c = await _open(
        tester,
        j,
        [photo],
        locale: const Locale('en'),
        width: 360,
        scale: 1.35,
        brightness: brightness,
      );
      c.read(routerProvider).go(JourneysPaths.day(j.id, testToday));
      await _frames(tester);
      final action = find.widgetWithText(UiTextAction, 'Show');
      expect(action, findsOneWidget);
      final context = tester.element(action);
      expect(Theme.of(context).brightness, brightness);
      expect(tester.widget<UiTextAction>(action).color, isNull);
      final text = tester.widget<Text>(
        find.descendant(of: action, matching: find.text('Show')),
      );
      expect(text.style!.color, context.ui.inkSoft);
      expect(find.text('72.4 kg'), findsNothing);
      await tester.ensureVisible(action);
      await _frames(tester);
      await tester.tap(action);
      await _frames(tester);
      expect(find.text('72.4 kg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, timeout: _timeout);
  }

  testWidgets('day one and short weight logs have calm empty states', (
    tester,
  ) async {
    final j = _journey(weight: true, elapsed: 1);
    await _open(tester, j, []);
    expect(find.text('Cân thêm vài lần nữa là thấy xu hướng.'), findsOneWidget);
    expect(_key('weight-first-latest'), findsNothing);
    expect(_key('weight-trend-line'), findsNothing);
    await _open(tester, j, [testCheckIn(j.id, testToday, metricValue: 74)]);
    expect(_key('weight-trend-empty'), findsOneWidget);
    expect(_key('weight-first-latest'), findsNothing);
    await _open(tester, j, [testCheckIn(j.id, testToday)]);
    expect(_key('weight-trend-card'), findsNothing);
    expect(_key('weight-trend-empty'), findsNothing);
    expect(tester.takeException(), isNull);
  }, timeout: _timeout);

  testWidgets('first and latest photos can come from the same day', (
    tester,
  ) async {
    final j = _journey(weight: true, elapsed: 1);
    final first = testCheckIn(j.id, testToday, hour: 1);
    final latest = testCheckIn(j.id, testToday, hour: 8);
    await _open(tester, j, [first, latest]);
    final pair = _key('weight-first-latest');
    expect(pair, findsOneWidget);
    expect(
      tester
          .widgetList<JourneyPhoto>(
            find.descendant(of: pair, matching: find.byType(JourneyPhoto)),
          )
          .map((photo) => photo.checkIn.id),
      [first.id, latest.id],
    );
    expect(tester.takeException(), isNull);
  }, timeout: _timeout);

  testWidgets('smoothed change uses Vietnamese decimals after reveal', (
    tester,
  ) async {
    final j = _journey(weight: true);
    final values = [74.0, 68.0, 67.4];
    await _open(tester, j, [
      for (var i = 0; i < values.length; i++)
        testCheckIn(j.id, j.startDate.addDays(i), metricValue: values[i]),
    ]);
    expect(find.text('−1,2 kg từ ngày 1'), findsNothing);
    await tester.tap(_key('weight-trend-toggle'));
    await _frames(tester);
    expect(find.text('−1,2 kg từ ngày 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: _timeout);

  testWidgets('gym and photo-only runs have no distance bars or pace', (
    tester,
  ) async {
    final j = _journey(gym: true);
    await _open(tester, j, _photos(j), locale: const Locale('en'));
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.byType(RunKmBars), findsNothing);
    final run = _journey();
    await _open(tester, run, [testCheckIn(run.id, testToday)]);
    expect(find.byType(RunKmBars), findsNothing);
    expect(find.text('5:42 /km'), findsNothing);
  }, timeout: _timeout);

  testWidgets(
    '120-day open journey uses weekly marks and a bounded recent grid',
    (tester) async {
      final j = _journey(elapsed: 120, duration: null);
      final clock = Stopwatch()..start();
      await _open(tester, j, [
        for (var i = 0; i < 120; i++)
          testCheckIn(
            j.id,
            j.startDate.addDays(i),
            extras: const CheckInExtras(km: 3),
          ),
      ]);
      clock.stop();
      expect(_key('run-week-bar-18'), findsOneWidget);
      expect(clock.elapsed, lessThan(const Duration(seconds: 15)));
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(
        position.maxScrollExtent + position.viewportDimension,
        lessThan(3000),
      );
      expect(
        find.byType(TimelineDayTap).evaluate().length,
        lessThanOrEqualTo(14),
      );
      expect(tester.takeException(), isNull);
    },
    timeout: _timeout,
  );

  testWidgets(
    'render run, hidden and revealed weight, and pace inputs',
    (tester) async {
      final out = Directory(Platform.environment['OURNEY_SHOTS_DIR']!);
      await tester.runAsync(() async {
        await out.create(recursive: true);
        for (final entry in <String, List<String>>{
          'BeVietnamPro': ['Regular', 'Medium', 'SemiBold', 'Bold'],
          'BarlowCondensed': ['Bold', 'ExtraBold'],
          'SpaceMono': ['Regular', 'Bold'],
        }.entries) {
          final loader = FontLoader(entry.key);
          for (final weight in entry.value) {
            loader.addFont(
              Future.value(
                ByteData.sublistView(
                  File('assets/fonts/${entry.key}-$weight.ttf')
                      .readAsBytesSync(),
                ),
              ),
            );
          }
          await loader.load();
        }
        for (final name in ['BricolageGrotesque', 'SpaceGrotesk', 'Fraunces']) {
          final file = File('assets/fonts/$name-Variable.ttf');
          if (file.existsSync()) {
            final loader = FontLoader(name)
              ..addFont(
                Future.value(ByteData.sublistView(file.readAsBytesSync())),
              );
            await loader.load();
          }
        }
      });
      for (final width in [390.0, 360.0]) {
        for (final scale in [1.0, 1.35]) {
          final suffix = scale == 1 ? '' : '_135';
          for (final brightness in Brightness.values) {
            final tone = brightness.name;
            for (final weight in [false, true]) {
              final key = GlobalKey();
              final j = _journey(weight: weight);
              final photos = _renderPhotos(j);
              final container = await _open(
                tester,
                j,
                photos,
                width: width,
                scale: scale,
                brightness: brightness,
                boundary: key,
                media: _FixtureMedia(photos, weight: weight),
              );
              await tester.runAsync(() async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
              });
              await _frames(tester);
              for (var frame = 0; frame < 40; frame++) {
                await tester.runAsync(
                  () => Future<void>.delayed(const Duration(milliseconds: 25)),
                );
                await tester.pump(const Duration(milliseconds: 50));
                final images = tester.widgetList<RawImage>(
                  find.byType(RawImage),
                );
                if (images.isNotEmpty &&
                    images.every((image) => image.image != null)) {
                  break;
                }
              }
              expect(find.byType(Image), findsWidgets);
              expect(
                find.byWidgetPredicate((w) => w is RawImage && w.image == null),
                findsNothing,
              );
              await _frames(tester);
              Future<void> capture(String name) async {
                final boundary =
                    key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final image = await boundary.toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                File('${out.path}/$name')
                    .writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              }

              await tester.runAsync(
                () => capture(
                  '${weight ? 'weight_home_hidden' : 'run_home'}_${tone}_${width.toInt()}$suffix.png',
                ),
              );
              if (weight) {
                await tester.tap(_key('weight-trend-toggle'));
                await _frames(tester);
                await tester.runAsync(
                  () => capture(
                    'weight_home_shown_${tone}_${width.toInt()}$suffix.png',
                  ),
                );
              }
              if (weight) {
                container
                    .read(routerProvider)
                    .go(JourneysPaths.day(j.id, photos.last.localDate));
                await _frames(tester);
                for (var frame = 0; frame < 40; frame++) {
                  await tester.runAsync(
                    () =>
                        Future<void>.delayed(const Duration(milliseconds: 25)),
                  );
                  await tester.pump(const Duration(milliseconds: 50));
                  if (tester
                      .widgetList<RawImage>(find.byType(RawImage))
                      .any((image) => image.image != null)) {
                    break;
                  }
                }
                await _frames(tester);
                expect(_key('journey-day-metric-shown'), findsOneWidget);
                expect(find.text('••,• kg'), findsOneWidget);
                final show = find.widgetWithText(UiTextAction, 'Hiện');
                await tester.ensureVisible(show);
                await _frames(tester);
                await tester.runAsync(
                  () => capture(
                    'weight_viewer_hidden_${tone}_${width.toInt()}$suffix.png',
                  ),
                );
                await tester.tap(show);
                await _frames(tester);
                await tester.runAsync(
                  () => capture(
                    'weight_viewer_shown_${tone}_${width.toInt()}$suffix.png',
                  ),
                );
              }
              expect(tester.takeException(), isNull);
            }
            final key = GlobalKey();
            final c = PostExtrasController();
            addTearDown(c.dispose);
            c.km.text = '5,2';
            c.setPaceParts('5', '42');
            await tester.pumpWidget(
              RepaintBoundary(
                key: key,
                child: ProviderScope(
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: OurneyTheme.build(brightness),
                    locale: const Locale('vi'),
                    localizationsDelegates: ourneyLocalizationsDelegates,
                    supportedLocales: const [Locale('vi'), Locale('en')],
                    home: Scaffold(
                      body: UiSkinScope(
                        skinId: 'flexer',
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: PostExtrasSection(
                            skin: PersonaSkinId.aestheticFlexer,
                            controller: c,
                            selfName: null,
                            partnerName: null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await _frames(tester);
            await tester.runAsync(() async {
              final b =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await b.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File('${out.path}/run_input_${tone}_${width.toInt()}$suffix.png')
                  .writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
    skip: Platform.environment['OURNEY_SHOTS_DIR'] == null,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
