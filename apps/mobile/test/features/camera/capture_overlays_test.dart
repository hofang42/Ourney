import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/camera/capture_overlays.dart';
import 'package:ourney/features/camera/journey_picker_sheet.dart';
import 'package:ourney/features/camera/l10n/generated/camera_localizations.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import '../checkin/fakes.dart';

Widget _host(Widget child, {required bool dark, double scale = 1.35}) =>
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: CameraL10n.localizationsDelegates,
      supportedLocales: CameraL10n.supportedLocales,
      theme: OurneyTheme.build(dark ? Brightness.dark : Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 640),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(body: SizedBox(width: 240, height: 320, child: child)),
      ),
    );

void main() {
  const keys = {
    PersonaSkinId.quietTransformer: 'overlay-quiet',
    PersonaSkinId.accountabilitySquad: 'overlay-study',
    PersonaSkinId.memoryCollectors: 'overlay-film',
    PersonaSkinId.coupleRituals: 'overlay-half-divider',
    PersonaSkinId.aestheticFlexer: 'overlay-hud-bold',
  };

  for (final dark in [false, true]) {
    for (final e in keys.entries) {
      testWidgets('${e.key.name} overlay ${dark ? 'dark' : 'light'} 1.35x', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            CaptureSkinOverlay(skin: e.key, dayNumber: 7, streak: 5),
            dark: dark,
          ),
        );
        expect(find.byKey(ValueKey(e.value)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('minimalist overlay draws no text', (tester) async {
    await tester.pumpWidget(
      _host(
        const CaptureSkinOverlay(
          skin: PersonaSkinId.minimalistHabit,
          dayNumber: 7,
          streak: 5,
        ),
        dark: true,
      ),
    );
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('quiet ghost toggles off', (tester) async {
    await tester.pumpWidget(
      _host(
        const CaptureSkinOverlay(
          skin: PersonaSkinId.quietTransformer,
          dayNumber: 3,
          streak: 2,
        ),
        dark: false,
      ),
    );
    expect(find.byKey(const ValueKey('overlay-ghost')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('overlay-ghost-toggle')));
    await tester.pump();
    expect(find.byKey(const ValueKey('overlay-ghost')), findsNothing);
  });

  testWidgets('flexer switches to the film strip', (tester) async {
    await tester.pumpWidget(
      _host(
        const CaptureSkinOverlay(
          skin: PersonaSkinId.aestheticFlexer,
          dayNumber: 3,
          streak: 2,
        ),
        dark: true,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('overlay-hud-pick-strip')));
    await tester.pump();
    expect(find.byKey(const ValueKey('overlay-film-strip')), findsOneWidget);
  });

  testWidgets('journey picker filters by search', (tester) async {
    final list = [
      testJourney(title: 'Chạy bộ'),
      testJourney(id: 'j2', title: 'Đà Lạt', templateId: TemplateId.travel),
    ];
    String? picked;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (c) => TextButton(
            onPressed: () async => picked = await showJourneyPickerSheet(
              c,
              journeys: list,
              selectedId: list.first.id,
            ),
            child: const Text('open'),
          ),
        ),
        dark: true,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journey-picker-j2')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('journey-picker-search')),
      'lạt',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('journey-picker-${'j1'}')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('journey-picker-search')),
      'zzz',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('journey-picker-empty')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('journey-picker-search')),
      'lạt',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('journey-picker-j2')));
    await tester.pumpAndSettle();
    expect(picked, 'j2');
  });
}
