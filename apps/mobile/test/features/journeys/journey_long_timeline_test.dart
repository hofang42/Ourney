import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/features/journeys/domain/journey_progress.dart';
import 'package:ourney/features/journeys/ui/journey_photo.dart';
import 'package:ourney/features/journeys/ui/widgets/timeline_common.dart';
import 'package:ourney/ui/ui.dart' show UiJumpChips, UiMonthHeader;
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

const _skins = <PersonaSkinId>[
  PersonaSkinId.quietTransformer,
  PersonaSkinId.accountabilitySquad,
  PersonaSkinId.memoryCollectors,
  PersonaSkinId.coupleRituals,
  PersonaSkinId.aestheticFlexer,
  PersonaSkinId.minimalistHabit,
];

/// Serves one real file for every photo, so `Image` widgets are built.
class _FileMediaStore implements MediaStore {
  _FileMediaStore(this.path);

  final String path;

  @override
  Future<String> localFileFor(String storagePath) async => path;
}

/// Today is 2026-10-16 (Ho Chi Minh). [elapsed] days have passed.
Journey _journey(
  PersonaSkinId skin, {
  required int elapsed,
  int? duration,
  String tz = testTz,
  JourneyStatus status = JourneyStatus.active,
  int startOffset = 0,
}) => Journey(
  id: 'j1',
  ownerId: 'u1',
  kind: JourneyKind.solo,
  templateId: TemplateId.custom,
  title: 'Một hành trình rất dài ngày',
  emoji: 'x',
  startDate: testToday.addDays(1 - elapsed + startOffset),
  durationDays: duration,
  timezone: tz,
  visibility: defaultVisibilityFor(JourneyKind.solo),
  status: status,
  layout: skin,
  metricName: skin == PersonaSkinId.quietTransformer ? 'Weight' : null,
  metricUnit: skin == PersonaSkinId.quietTransformer ? 'kg' : null,
);

List<CheckIn> _checkIns(Journey j, {LocalDate? until, int perDay = 2}) {
  var last = until ?? testToday;
  final end = j.endDate;
  if (end != null && end.isBefore(last)) last = end;
  return [
    for (var d = 0; d <= j.startDate.daysUntil(last); d++)
      for (var k = 0; k < perDay; k++)
        testCheckIn(
          j.id,
          j.startDate.addDays(d),
          hour: 2 + k,
          metricValue: j.metricName != null ? 80 - d * 0.01 : null,
        ),
  ];
}

late String _photoFile;

Future<JourneysHarness> _pump(
  WidgetTester tester,
  Journey j, {
  Size size = const Size(390, 844),
  double scale = 1,
  Brightness brightness = Brightness.light,
  LocalDate? until,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final h = await pumpJourneys(
    tester,
    locale: const Locale('vi'),
    journeys: FakeJourneyRepository(
      journeys: [j],
      memberships: {j.id: testMembership(j)},
    ),
    checkIns: FakeCheckInRepository(_checkIns(j, until: until)),
    location: AppRoutes.journey(j.id),
    mediaStore: _FileMediaStore(_photoFile),
  );
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
  return h;
}

Finder get _dayTaps => find.byType(TimelineDayTap, skipOffstage: false);
Finder get _images => find.byType(Image, skipOffstage: false);
Finder get _photos => find.byType(JourneyPhoto, skipOffstage: false);

Finder _key(String k) => find.byKey(ValueKey(k));

Finder _header(RegExp label) => find.byWidgetPredicate(
  (w) => w is UiMonthHeader && label.hasMatch(w.semanticLabel),
);

Future<void> _byMonth(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    _key('timeline-mode-month'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(_key('timeline-mode-month'));
  await tester.pumpAndSettle();
}

Future<void> _toggle(WidgetTester tester, RegExp label) async {
  await tester.scrollUntilVisible(
    _header(label),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  // Bring it to mid-screen: clear of the pinned bar and the check-in button.
  await tester.drag(
    find.byType(Scrollable).first,
    Offset(0, 400 - tester.getRect(_header(label)).top),
  );
  await tester.pumpAndSettle();
  await tester.tap(_header(label));
  await tester.pumpAndSettle();
}

/// The header of [label] sits directly under the pinned bar and chips, and
/// no other month header overlaps it.
void _expectLanded(WidgetTester tester, RegExp label) {
  final barBottom = tester.getRect(find.byType(UiJumpChips)).bottom;
  final target = tester.getRect(_header(label));
  expect(target.top, closeTo(barBottom, 2));
  for (final e in find.byType(UiMonthHeader).evaluate()) {
    final other = tester.getRect(find.byElementPredicate((x) => x == e));
    if (other == target) continue;
    expect(
      other.overlaps(target.deflate(2)),
      isFalse,
      reason: 'another pinned header sits on the target',
    );
  }
}

int _monthId(int y, int m) => y * 12 + m - 1;

Future<void> _chip(WidgetTester tester, String key) async {
  final chip = find.byKey(ValueKey(key), skipOffstage: false);
  final list = find.descendant(
    of: find.byType(UiJumpChips),
    matching: find.byType(Scrollable),
  );
  for (var i = 0; i < 24 && chip.evaluate().isEmpty; i++) {
    await tester.drag(list, Offset(i < 12 ? -150 : 150, 0));
    await tester.pumpAndSettle();
  }
  expect(chip, findsOneWidget, reason: 'chip $key');
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    final f = File('${Directory.systemTemp.path}/ourney_long_timeline.jpg')
      ..writeAsBytesSync(List.filled(16, 0));
    _photoFile = f.path;
  });

  Set<int?> widths(WidgetTester tester) => {
    for (final i in _images.evaluate())
      if ((i.widget as Image).image case final ResizeImage r) r.width,
  };

  group('365-day journey stays bounded', () {
    for (final skin in _skins) {
      testWidgets('${skin.name}: Recent and By month', (tester) async {
        final j = _journey(skin, elapsed: 365, duration: 365);
        await _pump(tester, j);
        expect(_key('timeline-mode-recent'), findsOneWidget);
        expect(_dayTaps.evaluate().length, lessThanOrEqualTo(60));
        expect(_photos.evaluate().length, lessThanOrEqualTo(60));
        // Real images, decoded no wider than their tile.
        expect(_images.evaluate(), isNotEmpty);
        expect(_images.evaluate().length, lessThanOrEqualTo(60));
        expect(widths(tester).every((w) => w != null && w <= 320), isTrue);
        expect(_key('day-${j.startDate}'), findsNothing);

        await _byMonth(tester);
        expect(_dayTaps.evaluate().length, lessThanOrEqualTo(60));
        expect(_photos.evaluate().length, lessThanOrEqualTo(60));
        expect(_images.evaluate(), isNotEmpty);
        expect(_images.evaluate().length, lessThanOrEqualTo(60));
        // 390dp: 20dp gutter, 350dp / 7 = 50dp pitch, 47dp tile; covers 56.
        expect(widths(tester), {47, 56});
        expect(_key('day-${j.startDate}'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('800-day open-ended journey: Recent stays short', (tester) async {
    final j = _journey(PersonaSkinId.accountabilitySquad, elapsed: 800);
    await _pump(tester, j);
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final total =
        scrollable.position.maxScrollExtent +
        scrollable.position.viewportDimension;
    expect(total, lessThan(3000));
    expect(_dayTaps.evaluate().length, lessThanOrEqualTo(60));
    await _byMonth(tester);
    expect(_dayTaps.evaluate().length, lessThanOrEqualTo(60));
    await tester.tap(_key('timeline-mode-recent'));
    await tester.pumpAndSettle();
    expect(_key('timeline-end-cap'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('31 days passed: no switch, every day', (tester) async {
    await _pump(tester, _journey(PersonaSkinId.minimalistHabit, elapsed: 31));
    expect(_key('timeline-mode-recent'), findsNothing);
    expect(_dayTaps.evaluate().length, 31);
  });

  testWidgets('32 days passed: the switch and a bounded window', (
    tester,
  ) async {
    await _pump(
      tester,
      _journey(PersonaSkinId.accountabilitySquad, elapsed: 32),
    );
    expect(_key('timeline-mode-recent'), findsOneWidget);
    expect(_dayTaps.evaluate().length, lessThanOrEqualTo(20));
    expect(_key('day-${testToday.addDays(-31)}'), findsNothing);
  });

  testWidgets('fixed 365-day journey on day 5 builds about 10 days', (
    tester,
  ) async {
    final j = _journey(
      PersonaSkinId.accountabilitySquad,
      elapsed: 5,
      duration: 365,
    );
    await _pump(tester, j);
    expect(_key('timeline-mode-recent'), findsNothing);
    expect(_dayTaps.evaluate().length, lessThanOrEqualTo(10));
    expect(_key('timeline-end-cap'), findsOneWidget);
    expect(_key('timeline-trophy'), findsOneWidget);
  });

  testWidgets('a 30-day journey that ended keeps the short layout', (
    tester,
  ) async {
    final j = _journey(
      PersonaSkinId.minimalistHabit,
      elapsed: 40,
      duration: 30,
    );
    await _pump(tester, j);
    expect(_key('timeline-mode-recent'), findsNothing);
    expect(_dayTaps.evaluate().length, 30);
  });

  testWidgets('a 365-day journey that ended lists no month after its end', (
    tester,
  ) async {
    final j = _journey(
      PersonaSkinId.minimalistHabit,
      elapsed: 400,
      duration: 365,
    );
    await _pump(tester, j);
    await _byMonth(tester);
    // The end was 2026-09-11: September is the open month, October absent.
    expect(_header(RegExp(r'^tháng 10 2026, ')), findsNothing);
    expect(_header(RegExp(r'^tháng 9 2026, ')), findsOneWidget);
    expect(_key('day-${j.endDate}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('journey zone differs from the device zone: today follows it', (
    tester,
  ) async {
    final j = _journey(
      PersonaSkinId.quietTransformer,
      elapsed: 100,
      duration: 365,
      tz: 'America/Los_Angeles',
    );
    // 05:00 UTC on Oct 16 is still Oct 15 in Los Angeles.
    await _pump(tester, j, until: const LocalDate(2026, 10, 14));
    final tap = tester.widget<TimelineDayTap>(
      find.ancestor(
        of: _key('journey-today-ring'),
        matching: find.byType(TimelineDayTap),
      ),
    );
    expect(tap.day.date, const LocalDate(2026, 10, 15));
  });

  testWidgets('a fixed journey that starts in 5 days shows a preview', (
    tester,
  ) async {
    final j = _journey(
      PersonaSkinId.accountabilitySquad,
      elapsed: 1,
      duration: 365,
      startOffset: 5,
    );
    await _pump(tester, j, until: testToday.addDays(-1));
    expect(_key('timeline-mode-recent'), findsNothing);
    expect(_dayTaps.evaluate().length, 3);
    expect(_key('timeline-end-cap'), findsOneWidget);
    expect(find.text('Bắt đầu sau 5 ngày · 365 ngày'), findsOneWidget);
  });

  testWidgets('a journey ended early: no upcoming days, no end cap', (
    tester,
  ) async {
    final j = _journey(
      PersonaSkinId.quietTransformer,
      elapsed: 100,
      duration: 365,
      status: JourneyStatus.ended,
    );
    await _pump(tester, j, until: j.startDate.addDays(59));
    expect(_key('timeline-end-cap'), findsNothing);
    final taps = _dayTaps.evaluate().map(
      (e) => (e.widget as TimelineDayTap).day,
    );
    expect(taps.last.date, j.startDate.addDays(59));
    expect(taps.any((d) => d.state == DayState.future), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an open-ended journey ended early builds only its days', (
    tester,
  ) async {
    final j = _journey(
      PersonaSkinId.minimalistHabit,
      elapsed: 200,
      status: JourneyStatus.ended,
    );
    await _pump(tester, j, until: j.startDate.addDays(9));
    final taps = _dayTaps
        .evaluate()
        .map((e) => (e.widget as TimelineDayTap).day)
        .toList();
    expect(taps.length, lessThanOrEqualTo(12));
    expect(taps.last.date, j.startDate.addDays(9));
    expect(taps.any((d) => d.state == DayState.missed), isFalse);
    expect(_key('missed-day-chip'), findsNothing);
  });

  group('month jumps', () {
    testWidgets('land exactly under the pinned bar, months above expanded', (
      tester,
    ) async {
      final messages = <Object?>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            m,
          ) async {
            messages.add(m);
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      final j = _journey(
        PersonaSkinId.minimalistHabit,
        elapsed: 200,
        duration: 365,
      );
      await _pump(tester, j);
      await _byMonth(tester);
      // Open two newer months, then jump below them and back above.
      await _toggle(tester, RegExp(r'^tháng 9 2026, '));
      await _toggle(tester, RegExp(r'^tháng 8 2026, '));
      await _chip(tester, 'jump-month-${_monthId(2026, 5)}');
      _expectLanded(tester, RegExp(r'^tháng 5 2026, '));
      expect(
        messages.any((m) => m.toString().contains('tháng 5 2026')),
        isTrue,
        reason: '$messages',
      );
      await _chip(tester, 'jump-month-${_monthId(2026, 9)}');
      _expectLanded(tester, RegExp(r'^tháng 9 2026, '));
      await _chip(tester, 'jump-month-${_monthId(2026, 4)}');
      _expectLanded(tester, RegExp(r'^tháng 4 2026, '));
    });

    testWidgets('earlier link opens the month before the window', (
      tester,
    ) async {
      final j = _journey(
        PersonaSkinId.quietTransformer,
        elapsed: 100,
        duration: 365,
      );
      await _pump(tester, j);
      await tester.ensureVisible(_key('timeline-earlier'));
      await tester.pumpAndSettle();
      await tester.tap(_key('timeline-earlier'));
      await tester.pumpAndSettle();
      expect(_key('jump-month-${_monthId(2026, 10)}'), findsOneWidget);
      _expectLanded(tester, RegExp(r'^tháng 10 2026, '));
    });

    testWidgets('more than 12 months: year chips filter and land', (
      tester,
    ) async {
      final j = _journey(
        PersonaSkinId.minimalistHabit,
        elapsed: 365,
        duration: 365,
      );
      await _pump(tester, j);
      await _byMonth(tester);
      expect(_key('jump-year-2025'), findsOneWidget);
      expect(_key('jump-month-${_monthId(2025, 11)}'), findsNothing);
      await tester.tap(_key('jump-year-2025'));
      await tester.pumpAndSettle();
      expect(_key('jump-month-${_monthId(2025, 11)}'), findsOneWidget);
      _expectLanded(tester, RegExp(r'^tháng 12 2025, '));
      // The selected year chip says that it clears the filter.
      expect(find.bySemanticsLabel(RegExp('Bỏ lọc năm 2025')), findsOneWidget);
      await tester.tap(_key('jump-year-2025'));
      await tester.pumpAndSettle();
      expect(_key('jump-month-${_monthId(2025, 11)}'), findsNothing);
    });
  });

  testWidgets('choices are kept per journey and Recent goes to the top', (
    tester,
  ) async {
    final j = _journey(
      PersonaSkinId.minimalistHabit,
      elapsed: 200,
      duration: 365,
    );
    final h = await _pump(tester, j);
    await _byMonth(tester);
    await _toggle(tester, RegExp(r'^tháng 9 2026, '));
    await h.go(tester, AppRoutes.journeys);
    await h.go(tester, AppRoutes.journey(j.id));
    // Still By month, with September open.
    expect(_header(RegExp(r'^tháng 9 2026, ')), findsOneWidget);
    final sep = tester.widget<UiMonthHeader>(
      _header(RegExp(r'^tháng 9 2026, ')),
    );
    expect(sep.expanded, isTrue);
    // Back to Recent: the timeline section is at the top of the screen.
    await tester.scrollUntilVisible(
      _key('timeline-mode-recent'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(_key('timeline-mode-recent'));
    await tester.pumpAndSettle();
    expect(tester.getRect(_key('timeline-mode-recent')).top, lessThan(120));
  });

  testWidgets('collapsed month is one node, the current month is open', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final j = _journey(
      PersonaSkinId.minimalistHabit,
      elapsed: 365,
      duration: 365,
    );
    await _pump(tester, j);
    await _byMonth(tester);
    SemanticsNode node(RegExp label) =>
        tester.getSemantics(find.bySemanticsLabel(label));
    final current = node(RegExp(r'^tháng 10 2026, '));
    expect(current.flagsCollection.isExpanded, Tristate.isTrue);
    expect(current.flagsCollection.isHeader, isTrue);
    expect(current.flagsCollection.isButton, isTrue);
    expect(_key('day-$testToday'), findsOneWidget);
    final collapsed = node(RegExp(r'^tháng 9 2026, '));
    expect(collapsed.flagsCollection.isExpanded, Tristate.isFalse);
    expect(_key('day-2026-09-10'), findsNothing);
    expect(
      find.descendant(
        of: _key('archive-collapsed-${_monthId(2026, 9)}'),
        matching: find.byType(Semantics),
      ),
      findsNothing,
    );
    await tester.tap(find.bySemanticsLabel(RegExp(r'^tháng 9 2026, ')));
    await tester.pumpAndSettle();
    expect(
      node(RegExp(r'^tháng 9 2026, ')).flagsCollection.isExpanded,
      Tristate.isTrue,
    );
    handle.dispose();
  });

  group('accessibility and layout', () {
    for (final skin in [
      PersonaSkinId.accountabilitySquad,
      PersonaSkinId.quietTransformer,
    ]) {
      for (final brightness in Brightness.values) {
        testWidgets('${skin.name} guidelines, ${brightness.name}, 1.35x', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          final j = _journey(skin, elapsed: 365, duration: 365);
          await _pump(tester, j, scale: 1.35, brightness: brightness);
          final checkInRect = tester.getRect(_key('journey-checkin'));
          final recentRect = tester.getRect(_key('timeline-mode-recent'));
          final monthRect = tester.getRect(_key('timeline-mode-month'));
          expect(
            recentRect.overlaps(checkInRect),
            isFalse,
            reason: 'recent tab $recentRect must not overlap $checkInRect',
          );
          expect(
            monthRect.overlaps(checkInRect),
            isFalse,
            reason: 'month tab $monthRect must not overlap $checkInRect',
          );
          expect(monthRect.bottom, lessThanOrEqualTo(checkInRect.top));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await _byMonth(tester);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }

    for (final skin in _skins) {
      testWidgets('${skin.name}: no overflow at 320dp, 1.35x', (tester) async {
        final j = _journey(skin, elapsed: 365, duration: 365);
        await _pump(tester, j, size: const Size(320, 900), scale: 1.35);
        expect(tester.takeException(), isNull);
        await _byMonth(tester);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
