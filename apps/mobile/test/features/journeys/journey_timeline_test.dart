import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/journey_style.dart';
import 'package:ourney/features/journeys/ui/widgets/journey_timeline.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

const _skins = ['quiet', 'squad', 'memory', 'couple', 'flexer', 'minimal'];

List<TimelineDay> _days() {
  final j = testJourney();
  return [
    for (var i = 0; i < 14; i++)
      TimelineDay(
        date: LocalDate(2026, 10, 10 + i),
        dayNumber: i + 1,
        isToday: i == 6,
        state: i == 6
            ? DayState.today
            : i > 6
            ? DayState.future
            : i == 2
            ? DayState.missed
            : DayState.checkedIn,
        checkIn: i < 6 && i != 2
            ? testCheckIn(j.id, LocalDate(2026, 10, 10 + i))
            : null,
      ),
  ];
}

Widget _host(
  String skin, {
  required Brightness brightness,
  required double scale,
  required ValueChanged<TimelineDay> onTap,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: JourneysL10n.localizationsDelegates,
      supportedLocales: JourneysL10n.supportedLocales,
      theme: OurneyTheme.build(brightness),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 800),
          textScaler: TextScaler.linear(scale),
        ),
        child: UiSkinScope(
          skinId: skin,
          child: Builder(
            builder: (context) => Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: JourneyTimeline(
                  skinId: skin,
                  days: _days(),
                  pal: JourneyPalette.of(
                    context,
                    styleOfJourney(testJourney()),
                  ),
                  onTapDay: onTap,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final skin in _skins) {
    for (final dark in [false, true]) {
      testWidgets('$skin timeline ${dark ? 'dark' : 'light'} 320dp 1.35x', (
        tester,
      ) async {
        TimelineDay? tapped;
        await tester.pumpWidget(
          _host(
            skin,
            brightness: dark ? Brightness.dark : Brightness.light,
            scale: 1.35,
            onTap: (d) => tapped = d,
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('journey-timeline')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('journey-today-ring')),
          findsOneWidget,
        );
        final all = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('day-'),
        );
        expect(all, findsNWidgets(14));

        final day = find.byKey(const ValueKey('day-2026-10-11'));
        await tester.ensureVisible(day);
        await tester.pump();
        await tester.tap(day);
        expect(tapped?.dayNumber, 2);

        tapped = null;
        final missed = find.byKey(const ValueKey('day-2026-10-12'));
        await tester.ensureVisible(missed);
        await tester.pump();
        await tester.tap(missed);
        expect(tapped, isNull);
      });
    }
  }
}
