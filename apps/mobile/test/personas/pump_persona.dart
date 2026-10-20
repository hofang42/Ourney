import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney_core/ourney_core.dart';

/// Pumps [widget] the way a persona screen sees it: the app theme of [skin]
/// in [brightness], every localization delegate, a screen [width] dp wide
/// and a text scale of [textScale].
///
/// Use it for every persona test so the checks in `docs/TASKS.md` §2 (light
/// and dark; 320, 390 and 430dp; text at 1.35x) are one argument each:
///
/// ```dart
/// await pumpPersona(tester, widget, skin: PersonaSkinId.coupleRituals,
///     brightness: Brightness.dark, width: 320, textScale: 1.35);
/// expect(tester.takeException(), isNull);
/// ```
Future<void> pumpPersona(
  WidgetTester tester,
  Widget widget, {
  PersonaSkinId skin = PersonaSkinId.quietTransformer,
  Brightness brightness = Brightness.light,
  double width = 390,
  double height = 844,
  double textScale = 1,
  Locale locale = const Locale('vi'),
  List<Override> overrides = const [],
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(brightness, skin),
        // Re-pumping with another skin must show it at once.
        themeAnimationDuration: Duration.zero,
        locale: locale,
        supportedLocales: ourneySupportedLocales,
        localizationsDelegates: ourneyLocalizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: SafeArea(child: widget)),
      ),
    ),
  );
  await tester.pump();
}

/// The six skins, for loops.
const allSkins = PersonaSkinId.values;

/// Light and dark, for loops.
const bothBrightness = [Brightness.light, Brightness.dark];
