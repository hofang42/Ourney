import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/ui/widgets/departure_ticket.dart';
import 'package:ourney/ui/ui.dart';

Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(390, 800),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

DepartureTicket _ticket(
  String skin, {
  String duration = '21 ngày',
  VoidCallback? onChange,
}) => DepartureTicket(
  skinId: skin,
  title: 'Tiêu đề $skin',
  goalLine: 'Dòng mục tiêu $skin',
  durationLabel: duration,
  datesLabel: '16 THG 10 – 20 THG 10',
  milestones: const ['Tuần đầu', 'Nửa chặng', 'Về đích'],
  leftName: 'Linh',
  rightName: 'Nam',
  onChangeVariant: onChange,
);

Finder _hasText(String d) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').toLowerCase().contains(d.toLowerCase()),
);

const _skins = ['quiet', 'squad', 'memory', 'couple', 'flexer', 'minimal'];

void main() {
  for (final skin in _skins) {
    for (final b in Brightness.values) {
      testWidgets('$skin renders in ${b.name}', (tester) async {
        await tester.pumpWidget(_host(_ticket(skin), brightness: b));
        await tester.pumpAndSettle();
        expect(find.text('Tiêu đề $skin'), findsOneWidget);
        expect(_hasText('21 ngày'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$skin has no overflow at 1.35x / 320dp', (tester) async {
      await tester.pumpWidget(
        _host(
          _ticket(skin, duration: 'không hẹn ngày về'),
          textScale: 1.35,
          size: const Size(320, 700),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Tiêu đề $skin'), findsOneWidget);
    });
  }

  testWidgets('couple shows both names from the caller', (tester) async {
    await tester.pumpWidget(_host(_ticket('couple')));
    await tester.pumpAndSettle();
    expect(find.text('Linh'), findsOneWidget);
    expect(find.text('Nam'), findsOneWidget);
  });

  for (final d in ['7 ngày', '14 ngày', '21 ngày', '30 ngày', '66 ngày']) {
    for (final skin in _skins) {
      testWidgets('$skin duration reflects "$d"', (tester) async {
        await tester.pumpWidget(_host(_ticket(skin, duration: d)));
        await tester.pumpAndSettle();
        expect(_hasText(d), findsWidgets);
        if (d != '30 ngày') {
          expect(find.textContaining('30'), findsNothing);
        }
      });
    }
  }

  testWidgets('open-ended duration is shown and flexer uses infinity bib', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_ticket('flexer', duration: 'không hẹn ngày về')),
    );
    await tester.pumpAndSettle();
    expect(find.text('không hẹn ngày về'), findsOneWidget);
    expect(find.text('∞'), findsOneWidget);
  });

  testWidgets('flexer bib shows the caller number', (tester) async {
    await tester.pumpWidget(_host(_ticket('flexer', duration: '66 ngày')));
    await tester.pumpAndSettle();
    expect(find.text('66'), findsOneWidget);
  });

  testWidgets('memory shows the film line exactly once', (tester) async {
    await tester.pumpWidget(_host(_ticket('memory')));
    await tester.pumpAndSettle();
    expect(find.text('Dòng mục tiêu memory'), findsOneWidget);
  });

  testWidgets('quiet shows the private label', (tester) async {
    await tester.pumpWidget(_host(_ticket('quiet')));
    await tester.pumpAndSettle();
    expect(find.text('HỒ SƠ RIÊNG TƯ'), findsOneWidget);
  });

  testWidgets('change variant action fires', (tester) async {
    var n = 0;
    await tester.pumpWidget(_host(_ticket('squad', onChange: () => n++)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đổi màu'));
    expect(n, 1);
  });
}
