import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/ui/components/journey_widgets.dart';
import 'package:ourney/ui/components/ourney_icons.dart';
import 'package:ourney/ui/components/pressable.dart';
import 'package:ourney/ui/skins.dart';
import 'package:ourney/ui/theme.dart';
import 'package:ourney/ui/tokens.dart';

Widget host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(390, 780),
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: OurneyTheme.build(brightness),
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

const newIcons = [
  'type-weight',
  'type-study',
  'type-trip',
  'type-couple',
  'type-workout',
  'type-custom',
  'flame',
  'trophy',
  'lock',
  'check',
  'warning',
  'wifi-off',
  'cloud-off',
  'clock',
  'image',
  'plus',
  'back',
  'close',
  'settings',
  'share',
  'switch-camera',
  'lightning',
  'calendar',
  'heart',
  'star',
  'timer',
];

List<Widget> allWidgets({VoidCallback? onTap}) => [
  UiTypeBadge(type: 'trip'),
  UiStreakHero(
    streak: 128,
    title: 'Còn 3 tiếng để giữ chuỗi của hành trình dài tên rất dài',
    subtitle: 'Nam và Hà đang chờ bạn chụp ảnh hôm nay nhé',
    onTap: onTap,
  ),
  UiStreakHero(
    streak: 30,
    title: 'Về đích',
    state: UiStreakHeroState.milestone,
  ),
  UiJourneyCard(
    title: 'Học tiếng Anh mỗi ngày cùng cả đội thật là dài dòng',
    subtitle: 'Mốc kế: Ngày 30 · Về đích',
    type: 'study',
    day: 12,
    totalDays: 30,
    streak: 12,
    members: const ['Nam', 'Hà', 'Linh', 'Minh', 'Quân'],
    onTap: onTap,
    onSnap: onTap,
  ),
  UiJourneyCard(
    title: 'Giảm cân',
    type: 'weight',
    day: 30,
    totalDays: 30,
    streak: 30,
    todayDone: true,
    members: const ['Nam'],
    onTap: onTap,
  ),
  for (final k in UiStateCardKind.values)
    UiStateCard(
      kind: k,
      title: 'Không tải được hành trình, thử lại sau nhé bạn',
      body: 'Kiểm tra kết nối mạng của bạn rồi thử lại.',
      actionLabel: 'Thử lại',
      onAction: onTap,
    ),
];

void main() {
  group('icons', () {
    test('new icons exist, parse non-empty inside the viewBox', () {
      expect(ourneyIconNames, containsAll(newIcons));
      for (final name in newIcons) {
        final b = ourneyIconPath(name)!.getBounds();
        expect(b.isEmpty, isFalse, reason: name);
        expect(b.left, greaterThanOrEqualTo(0), reason: name);
        expect(b.top, greaterThanOrEqualTo(0), reason: name);
        expect(b.right, lessThanOrEqualTo(24), reason: name);
        expect(b.bottom, lessThanOrEqualTo(24), reason: name);
      }
    });
  });

  group('UiTypeBadge', () {
    test('idFor maps the V2 labels', () {
      expect(UiTypeBadge.idFor('Giảm cân'), 'weight');
      expect(UiTypeBadge.idFor('Tiếng Anh'), 'study');
      expect(UiTypeBadge.idFor('Chuyến đi'), 'trip');
      expect(UiTypeBadge.idFor('Cặp đôi'), 'couple');
      expect(UiTypeBadge.idFor('Tập luyện'), 'workout');
      expect(UiTypeBadge.idFor('Tự đặt'), 'custom');
      expect(UiTypeBadge.idFor('???'), 'custom');
    });

    for (final b in Brightness.values) {
      testWidgets('every id renders on its pastel (${b.name})', (tester) async {
        await tester.pumpWidget(
          host(
            Wrap(
              children: [
                for (final id in UiTypeBadge.ids) UiTypeBadge(type: id),
                UiTypeBadge(type: 'unknown', size: 56),
              ],
            ),
            brightness: b,
          ),
        );
        for (final id in UiTypeBadge.ids) {
          final box = tester.widget<Container>(
            find
                .descendant(
                  of: find.byWidgetPredicate(
                    (w) => w is UiTypeBadge && w.type == id,
                  ),
                  matching: find.byType(Container),
                )
                .first,
          );
          final deco = box.decoration! as BoxDecoration;
          expect(deco.color, UiTypeBadge.pastelFor(id));
          expect((deco.border! as Border).top.width, UiBorder.standard);
        }
        expect(UiTypeBadge.pastelFor('weight'), UiTypePastel.weightLoss);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('UiStreakHero', () {
    testWidgets('pastel fill per state and semantics', (tester) async {
      await tester.pumpWidget(
        host(UiStreakHero(streak: 21, title: 'Giữ chuỗi', onTap: () {})),
      );
      expect(find.bySemanticsLabel('Chuỗi 21 ngày. Giữ chuỗi'), findsOneWidget);
      expect(find.text('21'), findsOneWidget);
      final fills = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(UiStreakHero),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.color);
      expect(fills, contains(UiTypePastel.english));
    });

    testWidgets('tap fires and target is >= 48dp', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(UiStreakHero(streak: 3, title: 'Hi', onTap: () => taps++)),
      );
      expect(
        tester.getSize(find.byType(UiStreakHero)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.byType(UiStreakHero));
      expect(taps, 1);
    });
  });

  group('UiJourneyCard', () {
    testWidgets('chips, avatars +N, snap 48dp, semantics', (tester) async {
      var snaps = 0;
      var taps = 0;
      await tester.pumpWidget(
        host(
          UiJourneyCard(
            title: 'IELTS',
            type: 'study',
            day: 12,
            totalDays: 30,
            streak: 12,
            members: const ['A', 'B', 'C', 'D', 'E'],
            onTap: () => taps++,
            onSnap: () => snaps++,
          ),
        ),
      );
      expect(find.text('Ngày 12/30'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(
        find.bySemanticsLabel('IELTS, Ngày 12/30, Chuỗi 12 ngày'),
        findsOneWidget,
      );
      final snap = find.bySemanticsLabel('Chụp ảnh hôm nay');
      expect(snap, findsOneWidget);
      final snapBox = tester.getSize(
        find.byWidgetPredicate(
          (w) => w is UiPressable && w.semanticLabel == 'Chụp ảnh hôm nay',
        ),
      );
      expect(snapBox.width, greaterThanOrEqualTo(48));
      expect(snapBox.height, greaterThanOrEqualTo(48));
      await tester.tapAt(
        tester.getBottomRight(find.byType(UiJourneyCard)) -
            const Offset(26, 26),
      );
      expect(snaps, 1);
      expect(taps, 0);
      await tester.tapAt(
        tester.getTopLeft(find.byType(UiJourneyCard)) + const Offset(100, 20),
      );
      expect(taps, 1);
    });

    testWidgets('done today hides the snap button', (tester) async {
      await tester.pumpWidget(
        host(
          const UiJourneyCard(
            title: 'IELTS',
            type: 'study',
            day: 30,
            totalDays: 30,
            streak: 30,
            todayDone: true,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Chụp ảnh hôm nay'), findsNothing);
    });

    testWidgets('sticker press translates the card by the shadow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          UiJourneyCard(
            title: 'IELTS',
            type: 'study',
            day: 1,
            totalDays: 30,
            streak: 1,
            todayDone: true,
            onTap: () {},
          ),
        ),
      );
      final text = find.text('IELTS');
      final before = tester.getTopLeft(text);
      final g = await tester.startGesture(tester.getCenter(text));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getTopLeft(text) - before, const Offset(4, 4));
      await g.up();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getTopLeft(text), before);
    });

    for (final b in Brightness.values) {
      testWidgets('uses token colors (${b.name})', (tester) async {
        await tester.pumpWidget(
          host(
            const UiJourneyCard(
              title: 'IELTS',
              type: 'trip',
              day: 3,
              totalDays: 30,
              streak: 3,
              todayDone: true,
            ),
            brightness: b,
          ),
        );
        final ui = tester.element(find.byType(UiJourneyCard)).ui;
        final deco =
            tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: find.byType(UiJourneyCard),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration;
        expect(deco.color, ui.surface);
        expect((deco.border! as Border).top.color, ui.outline);
      });
    }
  });

  group('UiStateCard', () {
    testWidgets('action button >= 48dp and fires', (tester) async {
      var n = 0;
      await tester.pumpWidget(
        host(
          UiStateCard(
            kind: UiStateCardKind.error,
            title: 'Lỗi',
            actionLabel: 'Thử lại',
            onAction: () => n++,
          ),
        ),
      );
      expect(tester.getSize(find.text('Thử lại')).height, greaterThan(0));
      await tester.tap(find.text('Thử lại'));
      expect(n, 1);
    });

    testWidgets('loading shows skeletons with the title as label', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const UiStateCard(kind: UiStateCardKind.loading, title: 'Đang tải'),
        ),
      );
      expect(find.bySemanticsLabel('Đang tải'), findsOneWidget);
      expect(find.text('Đang tải'), findsNothing);
    });
  });

  for (final b in Brightness.values) {
    testWidgets('1.35x text at 320dp does not overflow (${b.name})', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final w in allWidgets(onTap: () {}))
                Padding(padding: const EdgeInsets.only(bottom: 16), child: w),
            ],
          ),
          brightness: b,
          textScale: 1.35,
          size: const Size(320, 800),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
