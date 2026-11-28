import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_sections.dart';
import 'package:ourney/ui/ui.dart';

Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double scale = 1,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: OurneyTheme.build(brightness),
  locale: locale,
  localizationsDelegates: const [
    JourneysL10n.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: JourneysL10n.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(320, 640),
      textScaler: TextScaler.linear(scale),
    ),
    child: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    ),
  ),
);

Finder _k(String k) => find.byKey(ValueKey(k));

Widget _all(String skin) => Column(
  children: [
    JourneyHomeAttendance(done: 3, total: 4),
    const SizedBox(height: 8),
    JourneyHomeMilestones(
      day: 14,
      total: 30,
      accent: Colors.green,
      onAccent: Colors.white,
    ),
    const SizedBox(height: 8),
    JourneyHomeActions(onShare: () {}, onSquad: () {}),
  ],
);

void main() {
  test('milestone days: 7, half, finish; open-ended 7/14/30', () {
    expect(homeMilestoneDays(30), [7, 15, 30]);
    expect(homeMilestoneDays(14), [7, 14]);
    expect(homeMilestoneDays(7), [7]);
    expect(homeMilestoneDays(null), [7, 14, 30]);
  });

  testWidgets('actions fire; squad row only when provided', (tester) async {
    var shared = 0;
    var squad = 0;
    await tester.pumpWidget(
      _host(
        JourneyHomeActions(onShare: () => shared++, onSquad: () => squad++),
      ),
    );
    await tester.tap(_k('journey-home-card'));
    await tester.tap(_k('journey-home-squad'));
    expect((shared, squad), (1, 1));
    await tester.pumpWidget(_host(JourneyHomeActions(onShare: () {})));
    expect(_k('journey-home-squad'), findsNothing);
  });

  for (final skin in [
    'quiet',
    'squad',
    'memory',
    'couple',
    'flexer',
    'minimal',
  ]) {
    for (final b in Brightness.values) {
      for (final l in const [Locale('vi'), Locale('en')]) {
        testWidgets('$skin sections fit 320dp at 1.35x (${b.name}, $l)', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 640);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _host(_all(skin), brightness: b, scale: 1.35, locale: l),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
