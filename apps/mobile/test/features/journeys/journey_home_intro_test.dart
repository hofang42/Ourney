import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/features/journeys/l10n/generated/journeys_localizations.dart';
import 'package:ourney/features/journeys/ui/home/journey_home_intro.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

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
  bool squadUploadPending = false,
  bool couple = false,
  bool readOnly = false,
  int? total = 30,
}) => JourneyHomeIntro(
  skin: skin,
  day: 12,
  total: total,
  streak: 5,
  today: const LocalDate(2026, 11, 15),
  offline: offline,
  squadUploadPending: squadUploadPending,
  couple: couple,
  readOnly: readOnly,
);

Finder _k(String k) => find.byKey(ValueKey(k));

void main() {
  testWidgets('retold photo log keeps date range without a zero streak line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const JourneyHomeIntro(
          skin: 'quiet',
          day: 9,
          streak: 0,
          showStreak: false,
          today: LocalDate(2026, 11, 28),
          dateRange: 'Day 9 / 30',
        ),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('Day 9 / 30'), findsOneWidget);
    expect(_k('journey-home-line'), findsNothing);
    expect(find.textContaining('streak'), findsNothing);
  });

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
    expect(find.text('Chưa có kết nối mạng'), findsOneWidget);
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

  testWidgets('the squad chip shows the pending photo at 320dp and 2x text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 690);
    addTearDown(tester.view.reset);
    for (final locale in JourneysL10n.supportedLocales) {
      final l10n = lookupJourneysL10n(locale);
      final pending = l10n.journeys_home_offlineSquad;
      final couplePending = l10n.journeys_home_offlineCouple;
      await tester.pumpWidget(
        _host(
          _intro('squad', offline: true, squadUploadPending: true),
          scale: 2,
          locale: locale,
        ),
      );
      expect(find.text(pending), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _host(
          _intro('squad', squadUploadPending: true),
          scale: 2,
          locale: locale,
        ),
      );
      expect(find.text(pending), findsOneWidget);

      await tester.pumpWidget(
        _host(
          _intro('squad', squadUploadPending: true, couple: true),
          scale: 2,
          locale: locale,
        ),
      );
      expect(find.text(couplePending), findsOneWidget);
      expect(find.text(pending), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(_host(_intro('squad'), scale: 2, locale: locale));
      expect(_k('journey-home-offline'), findsNothing);
    }
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

  testWidgets('minimal month header follows the journey day, not the '
      'device clock', (tester) async {
    await tester.pumpWidget(
      _host(
        const JourneyHomeIntro(
          skin: 'minimal',
          day: 1,
          streak: 1,
          today: LocalDate(2026, 12, 1),
        ),
        locale: const Locale('en'),
      ),
    );
    expect(find.textContaining('DECEMBER'), findsOneWidget);
  });

  test('offline stream ignores a connectivity answer after dispose '
      '(B-B15)', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    final answer = Completer<List<String>>();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) => answer.future);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final errors = <Object>[];
    await runZonedGuarded(() async {
      final c = ProviderContainer();
      final sub = c.listen(journeyHomeOfflineProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      sub.close();
      c.dispose();
      answer.complete(['wifi']);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }, (e, _) => errors.add(e));
    expect(errors, isEmpty);
  });
}
