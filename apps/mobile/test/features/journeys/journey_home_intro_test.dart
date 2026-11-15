import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_intro.dart';
import 'package:ourney/ui/ui.dart';

Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double scale = 1,
  Locale locale = const Locale('vi'),
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

JourneyHomeIntro _intro(
  String skin, {
  bool offline = false,
  bool readOnly = false,
  int? total = 30,
}) => JourneyHomeIntro(
  skin: skin,
  day: 12,
  total: total,
  streak: 5,
  now: DateTime(2026, 11, 15),
  offline: offline,
  readOnly: readOnly,
);

Finder _k(String k) => find.byKey(ValueKey(k));

void main() {
  const skins = ['quiet', 'squad', 'memory', 'couple', 'flexer', 'minimal'];

  testWidgets('each skin has its own headline copy (Figma)', (tester) async {
    final expected = {
      'quiet': 'Nhìn lại từng chút một.',
      'squad': 'hôm nay học bao lâu.',
      'memory': 'Hôm nay cả bọn lạc ở đâu?',
      'couple': 'Hôm nay hai đứa nấu gì?',
    };
    for (final e in expected.entries) {
      await tester.pumpWidget(_host(_intro(e.key)));
      expect(find.text(e.value), findsOneWidget, reason: e.key);
      expect(find.text('Ngày 12/30 · chuỗi 5'), findsOneWidget);
    }
    // Flexer has no headline; Minimal shows the month + streak header.
    await tester.pumpWidget(_host(_intro('flexer')));
    expect(_k('journey-home-headline'), findsNothing);
    await tester.pumpWidget(_host(_intro('minimal')));
    expect(_k('journey-home-headline'), findsNothing);
    expect(find.textContaining('CHUỖI 5 NGÀY'), findsOneWidget);
  });

  testWidgets('offline and read-only chips use the skin copy', (tester) async {
    await tester.pumpWidget(_host(_intro('quiet', offline: true)));
    expect(find.text('Đang lưu trên máy · sẽ đồng bộ sau'), findsOneWidget);
    await tester.pumpWidget(_host(_intro('squad', offline: true)));
    expect(find.text('CHỜ ĐỒNG BỘ · ĐÃ LƯU TRÊN MÁY'), findsOneWidget);
    await tester.pumpWidget(_host(_intro('quiet', readOnly: true)));
    expect(find.text('Hành trình đã kết thúc · chỉ xem'), findsOneWidget);
    await tester.pumpWidget(_host(_intro('flexer', readOnly: true)));
    expect(find.text('ĐÃ VỀ ĐÍCH · CHỈ ĐỌC'), findsOneWidget);
    await tester.pumpWidget(_host(_intro('minimal', readOnly: true)));
    expect(find.text('ĐÃ KẾT THÚC · CHỈ ĐỌC'), findsOneWidget);
    await tester.pumpWidget(_host(_intro('quiet')));
    expect(_k('journey-home-offline'), findsNothing);
    expect(_k('journey-home-readonly'), findsNothing);
  });

  testWidgets('open-ended journeys show day without total', (tester) async {
    await tester.pumpWidget(_host(_intro('quiet', total: null)));
    expect(find.text('Ngày 12 · chuỗi 5'), findsOneWidget);
  });

  for (final skin in skins) {
    for (final b in Brightness.values) {
      for (final l in const [Locale('vi'), Locale('en')]) {
        testWidgets('$skin fits 320dp at 1.35x (${b.name}, $l)', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 640);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _host(
              _intro(skin, offline: true, readOnly: true),
              brightness: b,
              scale: 1.35,
              locale: l,
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
