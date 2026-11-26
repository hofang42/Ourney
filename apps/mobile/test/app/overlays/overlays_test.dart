import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/overlays/missed_day_overlay.dart';
import 'package:ourney/app/overlays/not_found_screen.dart';
import 'package:ourney/app/overlays/reminder_banner.dart';
import 'package:ourney/l10n/generated/app_localizations.dart';
import 'package:ourney/ui/ui.dart';

Widget _wrap(
  Widget child, {
  Brightness b = Brightness.light,
  double scale = 1,
}) => MaterialApp(
  theme: OurneyTheme.build(b),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(320, 640),
      textScaler: TextScaler.linear(scale),
    ),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('reminder banner: copy per skin, open and dismiss', (t) async {
    var opened = 0;
    var dismissed = 0;
    for (final b in Brightness.values) {
      await t.pumpWidget(
        _wrap(
          ReminderBanner(
            data: const ReminderBannerData(
              journeyId: 'j',
              journeyName: 'Chạy sáng',
              skinId: 'flexer',
              kind: ReminderBannerKind.streak,
              streak: 21,
            ),
            onOpen: () => opened++,
            onDismiss: () => dismissed++,
          ),
          b: b,
          scale: 1.35,
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('CHUỖI 21 NGÀY. MỘT TẤM CHO HÔM NAY.'), findsOneWidget);
      expect(find.text('Chạy sáng'), findsOneWidget);
      expect(t.takeException(), isNull);
    }
    await t.tap(find.byKey(const ValueKey('reminder-banner-open')));
    await t.tap(find.byKey(const ValueKey('reminder-banner-dismiss')));
    expect((opened, dismissed), (1, 1));
  });

  testWidgets('banner host shows and hides from the provider', (t) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    String? opened;
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: _wrap(
          ReminderBannerHost(
            onOpenJourneyCamera: (id) => opened = id,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    expect(find.byType(ReminderBanner), findsNothing);
    c
        .read(reminderBannerProvider.notifier)
        .show(
          const ReminderBannerData(
            journeyId: 'j1',
            journeyName: 'A',
            skinId: 'quiet',
            kind: ReminderBannerKind.daily,
          ),
        );
    await t.pumpAndSettle();
    expect(find.text('Đến giờ của bạn rồi. Một tấm là đủ.'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('reminder-banner-open')));
    await t.pumpAndSettle();
    expect(opened, 'j1');
    expect(find.byType(ReminderBanner), findsNothing);
  });

  testWidgets('missed day: only quiet and squad, sheet opens', (t) async {
    await t.pumpWidget(_wrap(const MissedDayOverlay(skinId: 'memory', day: 9)));
    expect(find.byKey(const ValueKey('missed-day-chip')), findsNothing);
    await t.pumpWidget(
      _wrap(
        const MissedDayOverlay(skinId: 'squad', day: 9),
        b: Brightness.dark,
      ),
    );
    expect(find.text('NGÀY 9 · TẠM NGHỈ'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('missed-day-chip')));
    await t.pumpAndSettle();
    expect(find.text('nghỉ một nhịp.'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('missed-day-dismiss')));
    await t.pumpAndSettle();
    expect(find.text('nghỉ một nhịp.'), findsNothing);
  });

  testWidgets('unknown route shows not-found screen with way home (DE-14)', (
    t,
  ) async {
    final r = GoRouter(
      initialLocation: '/nope',
      errorBuilder: (c, s) => const NotFoundRedirect(),
      routes: [
        GoRoute(
          path: AppRoutes.capture,
          builder: (c, s) => const Text('camera'),
        ),
      ],
    );
    await t.pumpWidget(
      MaterialApp.router(
        theme: OurneyTheme.build(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        routerConfig: r,
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('not-found-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('not-found-home')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('not-found-home')));
    await t.pumpAndSettle();
    expect(find.text('camera'), findsOneWidget);
  });
}
