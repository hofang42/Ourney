import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/create/dna_pages.dart';
import 'package:ourney/features/journeys/ui/create/dna_questions.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

Widget _host(
  Widget child, {
  required Brightness brightness,
  required double scale,
  required Locale locale,
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

void main() {
  testWidgets(
    'a trip longer than the longest journey says it was cut (B-B11)',
    (tester) async {
      DnaDates? value = DnaDates(DateTime(2026, 11, 20));
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => DnaDateRange(
              today: DateTime(2026, 11, 15),
              value: value,
              locale: 'en',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          brightness: Brightness.light,
          scale: 1,
          locale: const Locale('en'),
        ),
      );
      // 13 months on: Dec 2027, past 365 days after Nov 20 2026.
      for (var i = 0; i < 13; i++) {
        await tester.tap(find.byType(InkWell).last);
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('dna-day-28')));
      await tester.pump();
      expect(find.byKey(const ValueKey('dna-dates-max-note')), findsOneWidget);
      expect(find.byKey(const ValueKey('dna-dates-min-note')), findsNothing);
      expect(dnaTripDays(value!.start, value!.end!), durationMax);
    },
  );

  testWidgets(
    'DnaGhostPage renders sample photo under silhouette and fits at 2.0x on 320dp',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);
      for (final b in Brightness.values) {
        await tester.pumpWidget(
          _host(
            DnaGhostPage(onLater: () {}),
            brightness: b,
            scale: 2.0,
            locale: const Locale('vi'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('dna-ghost-photo')), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(
          find.byKey(const ValueKey('dna-ghost-silhouette')),
          findsOneWidget,
        );
        // F1: Silhouette wireframe aligns the head oval at the top of the
        // 180x240 standing frame (y < 40) with high-contrast light + dark strokes.
        final silhouette = tester.widget<CustomPaint>(
          find.byKey(const ValueKey('dna-ghost-silhouette')),
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        silhouette.painter!.paint(canvas, const Size(180, 240));
        final bytes = await tester.runAsync(() async {
          final img = await recorder.endRecording().toImage(180, 240);
          return (await img.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
        });
        expect(bytes, isNotNull);
        var headTopBandPixels = 0;
        var hasLightDash = false;
        var hasDarkHalo = false;
        for (var y = 4; y < 36; y++) {
          for (var x = 60; x < 120; x++) {
            final idx = (y * 180 + x) * 4;
            final a = bytes!.getUint8(idx + 3);
            if (a > 0) {
              headTopBandPixels++;
              final r = bytes.getUint8(idx);
              if (r > 200) hasLightDash = true;
              if (r < 80) hasDarkHalo = true;
            }
          }
        }
        expect(
          headTopBandPixels,
          greaterThan(20),
          reason: 'head oval must align with standing head at top of frame',
        );
        expect(hasLightDash, isTrue);
        expect(hasDarkHalo, isTrue);
      }
    },
  );

  final pages = <String, Widget Function()>{
    for (final t in TemplateId.values)
      for (final q in dnaQuestionsFor(t).where((q) => q.kind == DnaKind.choice))
        'choice-${t.wireName}-${q.key}': () => DnaChoiceList(
          question: q,
          value: q.choiceIds.first,
          onChanged: (_) {},
        ),
    'couple-ritual': () => DnaChoiceList(
      question: dnaCoupleQuestions.first,
      value: 'cook',
      onChanged: (_) {},
    ),
    'weight': () => DnaWeightPicker(
      weight: 120,
      hide: true,
      onWeight: (_) {},
      onHide: (_) {},
      onSkip: () {},
    ),
    'ghost': () => DnaGhostPage(onLater: () {}),
    'place': () => DnaPlacePicker(
      controller: TextEditingController(text: 'Đà Lạt'),
      place: 'Đà Lạt',
      onChanged: (_) {},
    ),
    'dates': () => DnaDateRange(
      today: DateTime(2026, 11, 15),
      value: DnaDates(DateTime(2026, 11, 20), DateTime(2026, 11, 25)),
      locale: 'vi',
      onChanged: (_) {},
    ),
    'forge': () => const SizedBox(height: 400, child: DnaForge()),
  };
  for (final entry in pages.entries) {
    for (final b in Brightness.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets(
          'DNA ${entry.key} fits 320dp at 1.35x (${b.name}, $locale)',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(320, 640);
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              _host(entry.value(), brightness: b, scale: 1.35, locale: locale),
            );
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
