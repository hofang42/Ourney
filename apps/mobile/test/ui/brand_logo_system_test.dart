import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/auth/auth_screen.dart';
import 'package:ourney/features/journeys/data/create_progress.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_intro.dart'
    show journeyHomeOfflineProvider;
import 'package:ourney/features/journeys/ui/journeys_list_screen.dart';
import 'package:ourney/features/journeys/ui/wrapped/journey_wrapped_screen.dart';
import 'package:ourney/features/share_card/data/share_card_exporter.dart';
import 'package:ourney/features/share_card/domain/share_card_content.dart';
import 'package:ourney/features/share_card/ui/share_card.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../app/test_helpers.dart';
import '../features/journeys/journeys_fakes.dart';
import '../features/share_card/share_card_fakes.dart'
    as share_fakes
    show streakCheckIns, testJourney;

bool _fontsLoaded = false;

Future<void> _loadBundledFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  const families = <String, List<String>>{
    'BeVietnamPro': [
      'assets/fonts/BeVietnamPro-Regular.ttf',
      'assets/fonts/BeVietnamPro-Medium.ttf',
      'assets/fonts/BeVietnamPro-SemiBold.ttf',
      'assets/fonts/BeVietnamPro-Bold.ttf',
    ],
    'BricolageGrotesque': ['assets/fonts/BricolageGrotesque-Variable.ttf'],
    'SpaceGrotesk': ['assets/fonts/SpaceGrotesk-Variable.ttf'],
    'Fraunces': ['assets/fonts/Fraunces-Variable.ttf'],
    'PlayfairDisplay': ['assets/fonts/PlayfairDisplay-Variable.ttf'],
    'BarlowCondensed': [
      'assets/fonts/BarlowCondensed-Bold.ttf',
      'assets/fonts/BarlowCondensed-ExtraBold.ttf',
    ],
    'SpaceMono': [
      'assets/fonts/SpaceMono-Regular.ttf',
      'assets/fonts/SpaceMono-Bold.ttf',
    ],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
    }
    await loader.load();
  }
}

class _NoResume extends CreateProgressController {
  @override
  int? build() => null;
}

/// Captures a [RepaintBoundary] to raw RGBA bytes + width/height.
Future<({Uint8List rgba, int width, int height, Uint8List png})>
_captureBoundary(GlobalKey key, {double pixelRatio = 2.0}) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final rgbaData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
  final w = image.width;
  final h = image.height;
  image.dispose();
  return (
    rgba: rgbaData!.buffer.asUint8List(),
    width: w,
    height: h,
    png: pngData!.buffer.asUint8List(),
  );
}

bool _hasColorNear(Uint8List rgba, Color target, {int tolerance = 18}) {
  final tr = (target.r * 255).round();
  final tg = (target.g * 255).round();
  final tb = (target.b * 255).round();
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    if (rgba[i + 3] < 200) continue;
    final dr = (rgba[i] - tr).abs();
    final dg = (rgba[i + 1] - tg).abs();
    final db = (rgba[i + 2] - tb).abs();
    if (dr <= tolerance && dg <= tolerance && db <= tolerance) {
      return true;
    }
  }
  return false;
}

ShareCardContent _sampleContent(String skinId, {String title = 'Đà Lạt'}) =>
    ShareCardContent(
      headline: ShareCardHeadline.streak,
      number: 7,
      dayNumber: 7,
      totalDays: 14,
      completedDays: 7,
      streakDays: 7,
      photoCount: 12,
      title: title,
      emoji: '🌿',
      templateId: TemplateId.travel,
      blurPhoto: false,
      metricHidden: false,
      metricValue: 21.5,
      metricUnit: 'km',
      activity: const [true, true, true, false, true, true, true],
    );

void main() {
  setUpAll(_loadBundledFonts);

  group('B11 Logo System — Assets & Android Native Launch Screen', () {
    test('ships @1x/@2x/@3x PNGs and SVG vectors for full, compact A, and "o" sticker', () {
      const files = [
        'assets/brand/logo_full.png',
        'assets/brand/2.0x/logo_full.png',
        'assets/brand/3.0x/logo_full.png',
        'assets/brand/logo_full.svg',
        'assets/brand/logo_compact.png',
        'assets/brand/2.0x/logo_compact.png',
        'assets/brand/3.0x/logo_compact.png',
        'assets/brand/logo_compact.svg',
        'assets/brand/logo_o.png',
        'assets/brand/2.0x/logo_o.png',
        'assets/brand/3.0x/logo_o.png',
        'assets/brand/logo_o.svg',
        'assets/brand/logo_o_dark.png',
        'assets/brand/2.0x/logo_o_dark.png',
        'assets/brand/3.0x/logo_o_dark.png',
        'assets/brand/logo_o_dark.svg',
      ];
      for (final path in files) {
        final f = File(path);
        expect(f.existsSync(), isTrue, reason: 'Missing brand asset: $path');
        expect(f.lengthSync(), greaterThan(100), reason: 'Empty asset: $path');
      }
    });

    test('Android native launch screen replaces white flash with "o" on cream and dark', () {
      final launchXml = File(
        'android/app/src/main/res/drawable/launch_background.xml',
      ).readAsStringSync();
      final launchV21Xml = File(
        'android/app/src/main/res/drawable-v21/launch_background.xml',
      ).readAsStringSync();
      final lightO = File('android/app/src/main/res/drawable/ic_launch_o.xml');
      final darkO = File(
        'android/app/src/main/res/drawable-night/ic_launch_o.xml',
      );

      expect(launchXml.contains('@android:color/white'), isFalse);
      expect(launchXml, contains('@color/widget_bg'));
      expect(launchXml, contains('@drawable/ic_launch_o'));
      expect(launchV21Xml, contains('@color/widget_bg'));
      expect(launchV21Xml, contains('@drawable/ic_launch_o'));
      expect(lightO.existsSync(), isTrue);
      expect(darkO.existsSync(), isTrue);
      expect(lightO.readAsStringSync(), contains('#FFFFF8EE'));
      expect(darkO.readAsStringSync(), contains('#FFFF8A3D'));
    });
  });

  group('B11 Logo System — Golden / Widget Size & Colour Ladder', () {
    for (final width in const [96.0, 122.0, 174.0]) {
      for (final isDark in const [false, true]) {
        testWidgets(
          'full cut-out renders at ${width.toInt()}px on ${isDark ? "dark" : "cream"} with all 6 letter colours and zero yellow-bar defects',
          (tester) async {
            final bg = isDark ? OurneyUi.dark.bg : OurneyUi.light.bg;
            final boundaryKey = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: buildAppTheme(
                  isDark ? Brightness.dark : Brightness.light,
                ),
                home: Scaffold(
                  backgroundColor: bg,
                  body: Center(
                    child: RepaintBoundary(
                      key: boundaryKey,
                      child: ColoredBox(
                        color: bg,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: UiRansomWordmark(
                            key: ValueKey('full-$width'),
                            size: width,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            expect(tester.takeException(), isNull);
            final size = tester.getSize(find.byKey(ValueKey('full-$width')));
            expect(size.width, closeTo(width, 0.01));
            expect(
              size.height,
              closeTo(width * FullWordmarkPainter.aspectRatio, 0.05),
            );
            expect(find.bySemanticsLabel('Ourney'), findsOneWidget);

            final shot = await tester.runAsync(
              () => _captureBoundary(boundaryKey, pixelRatio: 2.0),
            );
            expect(shot, isNotNull);
            for (final c in const [
              Color(0xFF10B981), // o
              Color(0xFFFF9F1C), // u
              Color(0xFFC2452B), // r
              Color(0xFF2AA7E0), // n
              Color(0xFFFF4D6D), // e
              Color(0xFFA13CC9), // y
            ]) {
              expect(
                _hasColorNear(shot!.rgba, c),
                isTrue,
                reason: 'Expected letter colour $c at ${width.toInt()}px',
              );
            }
            // No #FFFF00 defect bars.
            expect(
              _hasColorNear(shot!.rgba, const Color(0xFFFFFF00), tolerance: 4),
              isFalse,
            );
          },
        );
      }
    }

    for (final width in const [64.0, 84.0]) {
      for (final isDark in const [false, true]) {
        testWidgets(
          'compact A renders at ${width.toInt()}px on ${isDark ? "dark" : "cream"} with cream sticker edge and 6 letter colours',
          (tester) async {
            final bg = isDark ? OurneyUi.dark.bg : OurneyUi.light.bg;
            final boundaryKey = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: buildAppTheme(
                  isDark ? Brightness.dark : Brightness.light,
                ),
                home: Scaffold(
                  backgroundColor: bg,
                  body: Center(
                    child: RepaintBoundary(
                      key: boundaryKey,
                      child: ColoredBox(
                        color: bg,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: UiCompactWordmark(
                            key: ValueKey('compact-$width'),
                            size: width,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            expect(tester.takeException(), isNull);
            final size = tester.getSize(find.byKey(ValueKey('compact-$width')));
            expect(size.width, closeTo(width, 0.01));
            expect(
              size.height,
              closeTo(width * CompactWordmarkPainter.aspectRatio, 0.05),
            );
            expect(find.bySemanticsLabel('Ourney'), findsOneWidget);

            final shot = await tester.runAsync(
              () => _captureBoundary(boundaryKey, pixelRatio: 2.0),
            );
            expect(shot, isNotNull);
            // Unified cream sticker edge (#FFF8EE) + all 6 letters present even on dark.
            expect(
              _hasColorNear(shot!.rgba, const Color(0xFFFFF8EE)),
              isTrue,
              reason:
                  'Unified cream sticker edge must be visible on dark/cream',
            );
            for (final c in const [
              Color(0xFF10B981),
              Color(0xFFFF9F1C),
              Color(0xFFC2452B),
              Color(0xFF2AA7E0),
              Color(0xFFFF4D6D),
              Color(0xFFA13CC9),
            ]) {
              expect(
                _hasColorNear(shot.rgba, c),
                isTrue,
                reason: 'Expected letter colour $c at ${width.toInt()}px',
              );
            }
          },
        );
      }
    }

    for (final dim in const [16.0, 24.0, 48.0]) {
      for (final isDark in const [false, true]) {
        testWidgets(
          '"o" sticker renders at ${dim.toInt()}px on ${isDark ? "dark" : "cream"}',
          (tester) async {
            final bg = isDark ? OurneyUi.dark.bg : OurneyUi.light.bg;
            final boundaryKey = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: buildAppTheme(
                  isDark ? Brightness.dark : Brightness.light,
                ),
                home: Scaffold(
                  backgroundColor: bg,
                  body: Center(
                    child: RepaintBoundary(
                      key: boundaryKey,
                      child: ColoredBox(
                        color: bg,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: UiOSticker(
                            key: ValueKey('o-$dim'),
                            size: dim,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            expect(tester.takeException(), isNull);
            expect(
              tester.getSize(find.byKey(ValueKey('o-$dim'))),
              Size(dim, dim),
            );
            expect(find.bySemanticsLabel('Ourney'), findsOneWidget);

            final shot = await tester.runAsync(
              () => _captureBoundary(boundaryKey, pixelRatio: 2.0),
            );
            expect(shot, isNotNull);
            expect(
              _hasColorNear(shot!.rgba, const Color(0xFFFFD84D)),
              isTrue,
              reason:
                  'Underline yellow bar must be visible at ${dim.toInt()}px',
            );
            if (isDark) {
              expect(
                _hasColorNear(shot.rgba, const Color(0xFFFF8A3D)),
                isTrue,
                reason:
                    'Dark "o" sticker uses brand orange body with cream edge',
              );
            } else {
              expect(
                _hasColorNear(shot.rgba, const Color(0xFF1A1A1A)),
                isTrue,
                reason: 'Cream "o" sticker uses ink outline and shadow',
              );
            }
          },
        );
      }
    }
  });

  group('B11 Logo System — 1080x1920 Story Safe Band & All 6 Skins x Both Ratios', () {
    for (final skin in shareCardSkins) {
      testWidgets(
        '1080x1920 Story export ($skin): compact A mark rect sits strictly inside y 16–62% and x 8–92%',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(400, 720));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('vi'),
              localizationsDelegates: ourneyLocalizationsDelegates,
              supportedLocales: ourneySupportedLocales,
              theme: buildAppTheme(Brightness.light),
              home: Scaffold(
                body: Center(
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: ShareCard(
                      content: _sampleContent(skin),
                      format: ShareCardFormat.story,
                      blur: false,
                      skinId: skin,
                      hideBrand: false,
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);

          final cardFinder = find.byKey(const ValueKey('share-card-story'));
          final logoFinder = find.byKey(const ValueKey('share-card-logo'));
          expect(cardFinder, findsOneWidget);
          expect(logoFinder, findsOneWidget);

          final cardRect = tester.getRect(cardFinder);
          final logoRect = tester.getRect(logoFinder);
          expect(cardRect.size, const Size(360, 640));

          const pr = 3.0; // ShareCardFormat.story.pixelRatio -> 1080x1920
          final exportLeft = (logoRect.left - cardRect.left) * pr;
          final exportRight = (logoRect.right - cardRect.left) * pr;
          final exportTop = (logoRect.top - cardRect.top) * pr;
          final exportBottom = (logoRect.bottom - cardRect.top) * pr;

          // Safe band: x in [8%, 92%] of 1080 = [86.4, 993.6]
          //            y in [16%, 62%] of 1920 = [307.2, 1190.4]
          expect(exportLeft, greaterThanOrEqualTo(1080 * 0.08));
          expect(exportRight, lessThanOrEqualTo(1080 * 0.92));
          expect(exportTop, greaterThanOrEqualTo(1920 * 0.16));
          expect(exportBottom, lessThanOrEqualTo(1920 * 0.62));

          if (skin == 'flexer') {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await tester.runAsync(
              () =>
                  ShareCardExporter().capture(boundary, ShareCardFormat.story),
            );
            expect(image, isNotNull);
            expect(image!.width, 1080);
            expect(image.height, 1920);
            image.dispose();
          }
        },
      );

      for (final format in ShareCardFormat.values) {
        testWidgets(
          '$skin (${format.name}): wordmark rect does not intersect any photo, grid, filmstrip, or text rect',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(400, 720));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            await tester.pumpWidget(
              MaterialApp(
                locale: const Locale('vi'),
                localizationsDelegates: ourneyLocalizationsDelegates,
                supportedLocales: ourneySupportedLocales,
                theme: buildAppTheme(Brightness.light),
                home: Scaffold(
                  body: Center(
                    child: ShareCard(
                      content: _sampleContent(skin),
                      format: format,
                      blur: false,
                      skinId: skin,
                      hideBrand: false,
                    ),
                  ),
                ),
              ),
            );
            expect(tester.takeException(), isNull);

            final cardFinder = find.byKey(
              ValueKey('share-card-${format.name}'),
            );
            final logoFinder = find.byKey(const ValueKey('share-card-logo'));
            expect(cardFinder, findsOneWidget);
            expect(logoFinder, findsOneWidget);
            final logoRect = tester.getRect(logoFinder);

            // 1. Never overlaps any Text on the card.
            final textFinders = find.descendant(
              of: cardFinder,
              matching: find.byType(Text),
            );
            for (final element in textFinders.evaluate()) {
              final r = tester.getRect(
                find.byElementPredicate((e) => e == element),
              );
              expect(
                logoRect.overlaps(r),
                isFalse,
                reason:
                    '$skin (${format.name}): wordmark $logoRect overlaps text rect $r',
              );
            }

            if (skin == 'flexer') {
              // Full-bleed photo skin: check HUD box and activity bars.
              final bars = find.descendant(
                of: cardFinder,
                matching: find.byType(FractionallySizedBox),
              );
              expect(bars, findsWidgets);
              for (final element in bars.evaluate()) {
                final r = tester.getRect(
                  find.byElementPredicate((e) => e == element),
                );
                expect(
                  logoRect.overlaps(r),
                  isFalse,
                  reason:
                      'flexer (${format.name}): wordmark $logoRect overlaps activity bar $r',
                );
              }
            } else {
              // Poster skins (quiet, squad, memory, couple, minimal):
              // Every _CardPhoto renders inside a ClipRRect; memory and couple
              // also have GridView (and memory has the #111111 filmstrip Container).
              final photoClips = find.descendant(
                of: cardFinder,
                matching: find.byType(ClipRRect),
              );
              expect(photoClips, findsWidgets);
              for (final element in photoClips.evaluate()) {
                final r = tester.getRect(
                  find.byElementPredicate((e) => e == element),
                );
                expect(
                  logoRect.overlaps(r),
                  isFalse,
                  reason:
                      '$skin (${format.name}): wordmark $logoRect overlaps photo tile $r',
                );
              }

              final grids = find.descendant(
                of: cardFinder,
                matching: find.byType(GridView),
              );
              for (final element in grids.evaluate()) {
                final r = tester.getRect(
                  find.byElementPredicate((e) => e == element),
                );
                expect(
                  logoRect.overlaps(r),
                  isFalse,
                  reason:
                      '$skin (${format.name}): wordmark $logoRect overlaps grid $r',
                );
              }

              if (skin == 'memory') {
                final filmstrip = find.descendant(
                  of: cardFinder,
                  matching: find.byWidgetPredicate(
                    (w) => w is Container && w.color == const Color(0xFF111111),
                  ),
                );
                expect(filmstrip, findsOneWidget);
                final filmRect = tester.getRect(filmstrip);
                expect(
                  logoRect.overlaps(filmRect),
                  isFalse,
                  reason:
                      'memory (${format.name}): wordmark $logoRect overlaps 35mm filmstrip $filmRect',
                );
              }
            }
          },
        );

        testWidgets(
          '$skin (${format.name}) renders without overflow and respects hideBrand / quiet default',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(400, 720));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final defaultHide = shareCardHidesBrandByDefault(skin);
            await tester.pumpWidget(
              MaterialApp(
                locale: const Locale('vi'),
                localizationsDelegates: ourneyLocalizationsDelegates,
                supportedLocales: ourneySupportedLocales,
                theme: buildAppTheme(Brightness.light),
                home: Scaffold(
                  body: Center(
                    child: ShareCard(
                      content: _sampleContent(skin),
                      format: format,
                      blur: false,
                      skinId: skin,
                      hideBrand: defaultHide,
                    ),
                  ),
                ),
              ),
            );
            expect(tester.takeException(), isNull);
            if (defaultHide) {
              expect(
                find.byKey(const ValueKey('share-card-logo')),
                findsNothing,
              );
            } else {
              expect(
                find.byKey(const ValueKey('share-card-logo')),
                findsOneWidget,
              );
              expect(find.byType(UiCompactWordmark), findsOneWidget);
            }
          },
        );
      }
    }
  });

  group(
    'B11 Logo System — Auth ≥120px, Hub Header Semantics & Owner Renders',
    () {
      testWidgets(
        'UiTopBar wraps titleWidget in Semantics(header: true) so Hub logo is a semantic heading',
        (tester) async {
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(Brightness.light),
              home: const Scaffold(
                body: UiTopBar(
                  titleWidget: Align(
                    alignment: Alignment.centerLeft,
                    child: UiCompactWordmark(
                      key: ValueKey('hub-logo'),
                      size: 84,
                      semanticsLabel: 'Ourney',
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(find.bySemanticsLabel('Ourney'), findsOneWidget);
          final node = tester.getSemantics(
            find.byKey(const ValueKey('hub-logo')),
          );
          expect(node.flagsCollection.isHeader, isTrue);
          handle.dispose();
        },
      );

      testWidgets(
        'Auth screen renders full cut-out wordmark at ≥120px (was 64)',
        (tester) async {
          final prefs = await testPrefs();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appConfigProvider.overrideWithValue(
                  const AppConfig.localOnly(),
                ),
                sharedPreferencesProvider.overrideWithValue(prefs),
                supabaseClientProvider.overrideWithValue(null),
              ],
              child: MaterialApp(
                locale: const Locale('vi'),
                localizationsDelegates: ourneyLocalizationsDelegates,
                supportedLocales: ourneySupportedLocales,
                theme: buildAppTheme(Brightness.light),
                home: const AuthScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final wordmark = find.byType(UiRansomWordmark);
          expect(wordmark, findsOneWidget);
          expect(tester.getSize(wordmark).width, greaterThanOrEqualTo(120));
        },
      );

      testWidgets(
        'generates owner renders into E:/Ourney/agy-work/tmp/logo-app/',
        (tester) async {
          final prefs = await testPrefs();
          final parentTmp = Directory('E:/Ourney/agy-work/tmp');
          final outDir = Directory('E:/Ourney/agy-work/tmp/logo-app');
          if (parentTmp.existsSync() && !outDir.existsSync()) {
            outDir.createSync(recursive: true);
          }

          Future<void> saveBoundary(
            GlobalKey key,
            String fileName, {
            double pixelRatio = 2.0,
          }) async {
            final shot = await tester.runAsync(
              () => _captureBoundary(key, pixelRatio: pixelRatio),
            );
            expect(shot, isNotNull);
            if (outDir.existsSync()) {
              File('${outDir.path}/$fileName').writeAsBytesSync(shot!.png);
            }
          }

          // 0. Ensure @3x "o" sticker PNGs are exact 192x192 (3.0x of 64x64).
          for (final isDark in const [false, true]) {
            final key = GlobalKey();
            await tester.binding.setSurfaceSize(const Size(64, 64));
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(
                  isDark ? Brightness.dark : Brightness.light,
                ),
                home: RepaintBoundary(
                  key: key,
                  child: UiOSticker(size: 64, isDark: isDark),
                ),
              ),
            );
            final shot = await tester.runAsync(
              () => _captureBoundary(key, pixelRatio: 3.0),
            );
            expect(shot, isNotNull);
            expect(shot!.width, 192);
            expect(shot.height, 192);
            final outPath = isDark
                ? 'assets/brand/3.0x/logo_o_dark.png'
                : 'assets/brand/3.0x/logo_o.png';
            File(outPath).writeAsBytesSync(shot.png);
          }

          // 1. Hub light & dark
          for (final isDark in const [false, true]) {
            final key = GlobalKey();
            final j = testJourney();
            await tester.binding.setSurfaceSize(const Size(390, 844));
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  appConfigProvider.overrideWithValue(
                    const AppConfig.localOnly(),
                  ),
                  sharedPreferencesProvider.overrideWithValue(prefs),
                  supabaseClientProvider.overrideWithValue(null),
                  journeyRepositoryProvider.overrideWithValue(
                    FakeJourneyRepository(
                      journeys: [j],
                      memberships: {j.id: testMembership(j)},
                    ),
                  ),
                  checkInRepositoryProvider.overrideWithValue(
                    FakeCheckInRepository([testCheckIn(j.id, testToday)]),
                  ),
                  mediaStoreProvider.overrideWithValue(FakeMediaStore()),
                  journeysClockProvider.overrideWithValue(Clock.fixed(testNow)),
                  deviceTimezoneProvider.overrideWith((ref) => testTz),
                  journeyHomeOfflineProvider.overrideWith(
                    (ref) => Stream.value(false),
                  ),
                  createProgressProvider.overrideWith(_NoResume.new),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: const Locale('vi'),
                  localizationsDelegates: ourneyLocalizationsDelegates,
                  supportedLocales: ourneySupportedLocales,
                  theme: buildAppTheme(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
                  home: RepaintBoundary(
                    key: key,
                    child: const JourneysListScreen(),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await saveBoundary(
              key,
              isDark ? 'hub-dark.png' : 'hub-light.png',
              pixelRatio: 2.0,
            );
          }

          // 2. Splash
          {
            final key = GlobalKey();
            await tester.binding.setSurfaceSize(const Size(390, 844));
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(Brightness.light),
                home: RepaintBoundary(
                  key: key,
                  child: const Scaffold(
                    body: SizedBox.expand(
                      child: UiSplash(tagline: 'Góp tấm hình, giữ nhịp mình.'),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await saveBoundary(key, 'splash.png', pixelRatio: 2.0);
          }

          // 3. Auth (full >= 120px)
          {
            final key = GlobalKey();
            await tester.binding.setSurfaceSize(const Size(390, 844));
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  appConfigProvider.overrideWithValue(
                    const AppConfig.localOnly(),
                  ),
                  sharedPreferencesProvider.overrideWithValue(prefs),
                  supabaseClientProvider.overrideWithValue(null),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: const Locale('vi'),
                  localizationsDelegates: ourneyLocalizationsDelegates,
                  supportedLocales: ourneySupportedLocales,
                  theme: buildAppTheme(Brightness.light),
                  home: RepaintBoundary(key: key, child: const AuthScreen()),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await saveBoundary(key, 'auth.png', pixelRatio: 2.0);
          }

          // 4. 3 share cards (light photo, dark photo, busy photo) x 9:16 + 4:5
          final photoSpecs = <(String, String, String, String)>[
            (
              'light',
              'assets/samples/weight_loss/02.webp',
              'flexer',
              'Ăn sạch 14 ngày',
            ),
            (
              'dark',
              'assets/samples/workout_30/01.webp',
              'flexer',
              'Tập tạ 30 ngày',
            ),
            (
              'busy',
              'assets/samples/travel_dalat/02.webp',
              'flexer',
              'Đà Lạt · Đồi chè',
            ),
          ];

          for (final (tag, photoPath, skinId, title) in photoSpecs) {
            final bytes = File(photoPath).readAsBytesSync();
            final provider = MemoryImage(bytes);
            await tester.runAsync(() async {
              final completer = Completer<ImageInfo>();
              final stream = provider.resolve(ImageConfiguration.empty);
              late final ImageStreamListener listener;
              listener = ImageStreamListener((info, _) {
                if (!completer.isCompleted) completer.complete(info);
                stream.removeListener(listener);
              });
              stream.addListener(listener);
              await completer.future;
            });

            for (final format in ShareCardFormat.values) {
              final key = GlobalKey();
              final ratioTag = format == ShareCardFormat.story ? '9x16' : '4x5';
              await tester.binding.setSurfaceSize(format.logicalSize);
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: const Locale('vi'),
                  localizationsDelegates: ourneyLocalizationsDelegates,
                  supportedLocales: ourneySupportedLocales,
                  theme: buildAppTheme(Brightness.light),
                  home: Scaffold(
                    body: Center(
                      child: RepaintBoundary(
                        key: key,
                        child: ShareCard(
                          content: _sampleContent(skinId, title: title),
                          format: format,
                          blur: false,
                          photo: provider,
                          gallery: [provider, provider, provider, provider],
                          skinId: skinId,
                          hideBrand: false,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 50));
              await saveBoundary(
                key,
                'share-$tag-$ratioTag.png',
                pixelRatio: format.pixelRatio,
              );
            }
          }

          // 4b. All 6 skins x 9:16 + 4:5 light -> tmp/logo-app/skins-*.png
          // plus one contact sheet tmp/logo-app/skins-all.png.
          final skinPhotoPaths = [
            'assets/samples/weight_loss/02.webp',
            'assets/samples/workout_30/01.webp',
            'assets/samples/travel_dalat/02.webp',
          ];
          final skinProviders = <MemoryImage>[
            for (final p in skinPhotoPaths)
              MemoryImage(File(p).readAsBytesSync()),
          ];
          for (final provider in skinProviders) {
            await tester.runAsync(() async {
              final completer = Completer<ImageInfo>();
              final stream = provider.resolve(ImageConfiguration.empty);
              late final ImageStreamListener listener;
              listener = ImageStreamListener((info, _) {
                if (!completer.isCompleted) completer.complete(info);
                stream.removeListener(listener);
              });
              stream.addListener(listener);
              await completer.future;
            });
          }
          final galleryProviders = <ImageProvider>[
            for (var i = 0; i < 36; i++)
              skinProviders[i % skinProviders.length],
          ];
          const skinTitles = <String, String>{
            'quiet': 'Ăn sạch 14 ngày',
            'squad': 'Học IELTS 6.5',
            'memory': 'Đà Lạt',
            'couple': 'Hai đứa mình',
            'flexer': 'Chạy bộ 5km',
            'minimal': 'Đọc 10 trang sách',
          };
          for (final skinId in shareCardSkins) {
            for (final format in ShareCardFormat.values) {
              final key = GlobalKey();
              final ratioTag = format == ShareCardFormat.story ? '9x16' : '4x5';
              await tester.binding.setSurfaceSize(format.logicalSize);
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: const Locale('vi'),
                  localizationsDelegates: ourneyLocalizationsDelegates,
                  supportedLocales: ourneySupportedLocales,
                  theme: buildAppTheme(Brightness.light),
                  home: Scaffold(
                    body: Center(
                      child: RepaintBoundary(
                        key: key,
                        child: ShareCard(
                          content: _sampleContent(
                            skinId,
                            title: skinTitles[skinId] ?? 'Đà Lạt',
                          ),
                          format: format,
                          blur: false,
                          photo: galleryProviders.first,
                          gallery: galleryProviders,
                          couplePhotos: galleryProviders,
                          skinId: skinId,
                          hideBrand: false,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 50));
              await saveBoundary(
                key,
                'skins-$skinId-$ratioTag.png',
                pixelRatio: format.pixelRatio,
              );
            }
          }

          // Contact sheet: all 6 skins x 9:16 (top row) + 4:5 (bottom row) light -> skins-all.png
          {
            final key = GlobalKey();
            const sheetSize = Size(1380, 760);
            await tester.binding.setSurfaceSize(sheetSize);
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: const Locale('vi'),
                localizationsDelegates: ourneyLocalizationsDelegates,
                supportedLocales: ourneySupportedLocales,
                theme: buildAppTheme(Brightness.light),
                home: Scaffold(
                  backgroundColor: const Color(0xFFE8E2D6),
                  body: RepaintBoundary(
                    key: key,
                    child: ColoredBox(
                      color: const Color(0xFFE8E2D6),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final skinId in shareCardSkins)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$skinId · 9:16 & 4:5',
                                        style: const TextStyle(
                                          fontFamily: 'SpaceMono',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E1A15),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 204,
                                        height: 362.67,
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: ShareCard(
                                            content: _sampleContent(
                                              skinId,
                                              title:
                                                  skinTitles[skinId] ??
                                                  'Đà Lạt',
                                            ),
                                            format: ShareCardFormat.story,
                                            blur: false,
                                            photo: galleryProviders.first,
                                            gallery: galleryProviders,
                                            couplePhotos: galleryProviders,
                                            skinId: skinId,
                                            hideBrand: false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: 204,
                                        height: 255,
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: ShareCard(
                                            content: _sampleContent(
                                              skinId,
                                              title:
                                                  skinTitles[skinId] ??
                                                  'Đà Lạt',
                                            ),
                                            format: ShareCardFormat.feed,
                                            blur: false,
                                            photo: galleryProviders.first,
                                            gallery: galleryProviders,
                                            couplePhotos: galleryProviders,
                                            skinId: skinId,
                                            hideBrand: false,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));
            await saveBoundary(key, 'skins-all.png', pixelRatio: 2.0);
          }

          // 5. Wrapped summary screen
          {
            final key = GlobalKey();
            final j = share_fakes
                .testJourney(
                  templateId: TemplateId.englishDaily,
                  title: 'Đọc sách mỗi tối',
                  emoji: '📚',
                )
                .copyWith(status: JourneyStatus.ended);
            final checkIns = share_fakes.streakCheckIns(j.id);
            await tester.binding.setSurfaceSize(const Size(390, 844));
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  appConfigProvider.overrideWithValue(
                    const AppConfig.localOnly(),
                  ),
                  sharedPreferencesProvider.overrideWithValue(prefs),
                  supabaseClientProvider.overrideWithValue(null),
                  journeyRepositoryProvider.overrideWithValue(
                    FakeJourneyRepository(
                      journeys: [j],
                      memberships: {j.id: testMembership(j)},
                    ),
                  ),
                  checkInRepositoryProvider.overrideWithValue(
                    FakeCheckInRepository(checkIns),
                  ),
                  mediaStoreProvider.overrideWithValue(FakeMediaStore()),
                  journeysClockProvider.overrideWithValue(Clock.fixed(testNow)),
                  deviceTimezoneProvider.overrideWith((ref) => testTz),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: const Locale('vi'),
                  localizationsDelegates: ourneyLocalizationsDelegates,
                  supportedLocales: ourneySupportedLocales,
                  theme: buildAppTheme(Brightness.light),
                  home: RepaintBoundary(
                    key: key,
                    child: JourneyWrappedScreen(journeyId: j.id),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            // Jump to the final segment (Wrapped summary card)
            final segments = find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(
                    'wrapped-segment-',
                  ) &&
                  !(w.key! as ValueKey<String>).value.startsWith(
                    'wrapped-segment-fill-',
                  ),
            );
            await tester.tap(segments.last);
            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('wrapped-brand')), findsOneWidget);
            await saveBoundary(key, 'wrapped.png', pixelRatio: 2.0);
          }

          await tester.binding.setSurfaceSize(null);
        },
      );
    },
  );
}
