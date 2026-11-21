// TEMPORARY ui-bug-scan harness. Delete test/zz_uxscan/ when the scan ends.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/router.dart';

import '../app/test_helpers.dart';

/// Loads the bundled fonts so screenshots show real Vietnamese glyphs
/// instead of the Ahem test font (black boxes).
Future<void> loadOurneyFonts() async {
  const families = {
    'BeVietnamPro': [
      'BeVietnamPro-Regular.ttf',
      'BeVietnamPro-Medium.ttf',
      'BeVietnamPro-SemiBold.ttf',
      'BeVietnamPro-Bold.ttf',
    ],
    'BricolageGrotesque': ['BricolageGrotesque-Variable.ttf'],
    'SpaceGrotesk': ['SpaceGrotesk-Variable.ttf'],
    'Fraunces': ['Fraunces-Variable.ttf'],
    'PlayfairDisplay': ['PlayfairDisplay-Variable.ttf'],
    'BarlowCondensed': [
      'BarlowCondensed-Bold.ttf',
      'BarlowCondensed-ExtraBold.ttf',
    ],
    'SpaceMono': ['SpaceMono-Regular.ttf', 'SpaceMono-Bold.ttf'],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

/// One cell of the scan matrix.
class ScanConfig {
  const ScanConfig(this.width, this.height, this.brightness, this.scale,
      [this.locale = const Locale('vi')]);
  final double width;
  final double height;
  final Brightness brightness;
  final double scale;
  final Locale locale;

  String get name =>
      '${locale.languageCode}_${width.toInt()}_${brightness.name}_x$scale';
}

/// Default matrix: narrowest phone, a standard phone in both themes,
/// Dynamic Type 1.35x (CLAUDE.md 3.5), the 2x app clamp, English, Pro Max.
const scanMatrix = [
  ScanConfig(320, 568, Brightness.light, 1),
  ScanConfig(360, 780, Brightness.light, 1),
  ScanConfig(360, 780, Brightness.dark, 1),
  ScanConfig(393, 852, Brightness.light, 1.35),
  ScanConfig(320, 568, Brightness.dark, 2),
  ScanConfig(393, 852, Brightness.light, 1, Locale('en')),
  ScanConfig(430, 932, Brightness.dark, 1.35),
];

/// Pumps the real app at [c] with an iPhone safe area (59 top, 34 bottom).
Future<void> setUpView(WidgetTester tester, ScanConfig c) async {
  const dpr = 3.0;
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = Size(c.width * dpr, c.height * dpr)
    ..padding = const FakeViewPadding(top: 59 * dpr, bottom: 34 * dpr)
    ..viewPadding = const FakeViewPadding(top: 59 * dpr, bottom: 34 * dpr);
  addTearDown(tester.view.reset);
  tester.platformDispatcher
    ..textScaleFactorTestValue = c.scale
    ..platformBrightnessTestValue = c.brightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

void main() {
  setUpAll(loadOurneyFonts);

  // Screens to scan: route -> name. Add overrides / seeded data per screen.
  const screens = {AppRoutes.journeys: 'hub', AppRoutes.groups: 'squad'};

  for (final c in scanMatrix) {
    for (final MapEntry(key: route, value: screen) in screens.entries) {
      testWidgets('$screen ${c.name}', (tester) async {
        await setUpView(tester, c);
        final container = await pumpOurneyApp(
          tester,
          config: testBackendConfig,
          auth: FakeAuthRepository(userId: 'u'),
          locale: c.locale,
        );
        container.read(routerProvider).go(route);
        await tester.pumpAndSettle();

        // 1. Overflow / layout exceptions (RenderFlex overflowed...).
        final error = tester.takeException();
        // 2. Screenshot for visual review (read the PNG afterwards).
        await expectLater(
          find.byType(MaterialApp).first,
          matchesGoldenFile('out/${screen}_${c.name}.png'),
        );
        // 3. Guidelines. Collect, do not stop at the first failure.
        final handle = tester.ensureSemantics();
        final failures = <String>[];
        for (final g in [
          labeledTapTargetGuideline,
          iOSTapTargetGuideline,
          androidTapTargetGuideline,
          textContrastGuideline,
        ]) {
          final r = await g.evaluate(tester);
          if (!r.passed) failures.add('${g.description}: ${r.reason}');
        }
        handle.dispose();
        expect(error, isNull, reason: 'layout exception');
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  }
}
