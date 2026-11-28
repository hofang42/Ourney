import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/data/group_daily_checkins_provider.dart';
import 'package:ourney/features/groups/data/groups_providers.dart';
import 'package:ourney/features/groups/ui/reaction_bar.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney/features/journeys/ui/day_photo_fullscreen.dart';
import 'package:ourney/features/journeys/ui/day_viewer_parts.dart';
import 'package:ourney/features/journeys/ui/day_viewer_screen.dart';
import 'package:ourney/features/journeys/ui/journey_photo.dart';
import 'package:ourney/ui/ui.dart';
import 'package:ourney_core/ourney_core.dart';

import 'journeys_fakes.dart';

class ViewerActiveJourney extends ActiveJourneyId {
  @override
  String? build() => null;
  @override
  Future<void> select(String id) async {
    state = id;
  }
}

const viewerPixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC';
const viewerTimeout = Timeout(Duration(seconds: 30));
Finder dayKey(String key) => find.byKey(ValueKey(key));

CheckIn viewerPhoto({
  String id = 'photo',
  LocalDate date = testToday,
  String user = 'u1',
  bool library = false,
  bool uploaded = true,
  bool moderated = false,
  String? caption,
  double? metric,
  CheckInExtras extras = CheckInExtras.empty,
  int hour = 12,
  int minute = 29,
  String? path,
}) => CheckIn(
  id: id,
  journeyId: 'j1',
  userId: user,
  localDate: date,
  capturedAt: DateTime.utc(date.year, date.month, date.day, hour, minute),
  photoPath: 'photos/$id',
  thumbPath: 'thumbs/$id',
  localPhotoFile: path,
  fromLibrary: library,
  uploaded: uploaded,
  moderated: moderated,
  caption: caption,
  metricValue: metric,
  extras: extras,
);

/// Bounded widget host with isolated provider lifetimes.
Future<ProviderContainer> pumpDayViewer(
  WidgetTester tester, {
  Journey? journey,
  Stream<List<CheckIn>> Function()? photoStream,
  List<CheckIn> photos = const [],
  LocalDate? date = testToday,
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('vi'),
  double scale = 1,
  bool localOnly = true,
  bool activeMember = true,
  GroupDailySnapshot? couple,
  List<Reaction> reactions = const [],
  Set<String> blocked = const {},
  String? imagePath,
  bool reduced = true,
  bool use24h = true,
  CheckInRepository? repository,
  bool editCaption = false,
}) async {
  final j = journey ?? testJourney(durationDays: 30);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final overrides = [
    if (repository != null)
      checkInRepositoryProvider.overrideWithValue(repository),
    appConfigProvider.overrideWithValue(
      localOnly
          ? const AppConfig.localOnly()
          : const AppConfig(
              supabaseUrl: 'https://example.supabase.co',
              supabaseAnonKey: 'anon',
            ),
    ),
    currentUserIdProvider.overrideWithValue('u1'),
    activeJourneyIdProvider.overrideWith(ViewerActiveJourney.new),
    journeyByIdProvider(j.id).overrideWith((ref) => Stream.value(j)),
    myCheckInsProvider(j.id).overrideWith(
      (ref) =>
          photoStream?.call() ??
          Stream.value(photos.where((c) => c.userId == 'u1').toList()),
    ),
    myMembershipProvider(j.id).overrideWith(
      (ref) => Stream.value(
        activeMember
            ? testMembership(j)
            : Membership(
                journeyId: j.id,
                userId: 'u1',
                role: MemberRole.member,
                status: MemberStatus.left,
                joinedAt: DateTime.utc(2026),
              ),
      ),
    ),
    journeysNowProvider.overrideWithValue(testNow),
    groupDailySnapshotProvider(j)
        .overrideWithValue(couple ?? GroupDailySnapshot.empty),
    groupBlockedIdsProvider.overrideWith((ref) => Stream.value(blocked)),
    groupReactionsProvider.overrideWith((ref, id) => Stream.value(reactions)),
    mediaFileProvider.overrideWith(
      (ref, path) async =>
          imagePath ?? '${Directory.systemTemp.path}/unavailable-day-photo.jpg',
    ),
  ];
  final router = GoRouter(
    initialLocation: '/day',
    routes: [
      GoRoute(
        path: AppRoutes.capture,
        builder: (_, _) => const Scaffold(body: Text('Camera destination')),
      ),
      GoRoute(
        path: '/day',
        builder: (_, _) => DayViewerScreen(
          journeyId: j.id,
          date: date,
          editCaption: editCaption,
        ),
      ),
      GoRoute(
        path: '/journey/:id',
        builder: (_, _) => const Scaffold(body: Text('Journey destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overrides,
      child: RepaintBoundary(
        key: const ValueKey('day-viewer-test-boundary'),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: buildAppTheme(brightness),
          locale: locale,
          localizationsDelegates: ourneyLocalizationsDelegates,
          supportedLocales: ourneySupportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduced,
              alwaysUse24HourFormat: use24h,
            ),
            child: child!,
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
  return ProviderScope.containerOf(
    tester.element(find.byType(DayViewerScreen)),
  );
}

void main() {
  testWidgets('right-side preference keeps photo pages in chip order', (
    tester,
  ) async {
    final journey = testJourney(
      kind: JourneyKind.group,
      maxMembers: 2,
    ).copyWith(dna: {'side': 'right'});
    final mine = viewerPhoto();
    final partner = viewerPhoto(id: 'partner', user: 'u2');
    await pumpDayViewer(
      tester,
      journey: journey,
      photos: [mine],
      couple: GroupDailySnapshot.build(
        journey: journey,
        allCheckIns: [mine, partner],
        members: const [
          MemberToday(userId: 'u1', displayName: 'An', role: MemberRole.owner),
          MemberToday(
            userId: 'u2',
            displayName: 'Binh',
            role: MemberRole.member,
          ),
        ],
        myUserId: 'u1',
      ),
    );
    final partnerChip = find.byKey(
      const ValueKey<(String, int, String?)>(('day-person-chip', 0, 'u2')),
    );
    final ownChip = find.byKey(
      const ValueKey<(String, int, String?)>(('day-person-chip', 1, 'u1')),
    );
    expect(tester.widget<UiPressable>(partnerChip).selected, isTrue);
    expect(dayKey('journey-day-add-caption'), findsNothing);
    expect(dayKey('journey-day-edit-caption'), findsNothing);
    expect(
      tester.widget<JourneyPhoto>(dayKey('journey-day-photo')).checkIn.id,
      partner.id,
    );
    await tester.drag(dayKey('journey-day-pages'), const Offset(-350, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<UiPressable>(ownChip).selected, isTrue);
    expect(
      tester.widget<JourneyPhoto>(dayKey('journey-day-photo')).checkIn.id,
      mine.id,
    );
    expect(tester.takeException(), isNull);
  }, timeout: viewerTimeout);

  testWidgets('partner-only day has grammatical own-chip semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final journey = testJourney(kind: JourneyKind.group, maxMembers: 2);
    final partner = viewerPhoto(id: 'partner', user: 'u2');
    await pumpDayViewer(
      tester,
      journey: journey,
      locale: const Locale('en'),
      couple: GroupDailySnapshot.build(
        journey: journey,
        allCheckIns: [partner],
        members: const [
          MemberToday(userId: 'u1', displayName: 'An', role: MemberRole.owner),
          MemberToday(
            userId: 'u2',
            displayName: 'Binh',
            role: MemberRole.member,
          ),
        ],
        myUserId: 'u1',
      ),
    );
    final ownChip = find.byKey(
      const ValueKey<(String, int, String?)>(('day-person-chip', 0, 'u1')),
    );
    expect(tester.getSemantics(ownChip).label, 'No photo for this day');
    expect(tester.widget<UiPressable>(ownChip).onPressed, isNull);
    expect(
      find.bySemanticsLabel('You has no photo for this day'),
      findsNothing,
    );
    expect(dayKey('journey-day-photo'), findsOneWidget);
    semantics.dispose();
  }, timeout: viewerTimeout);

  testWidgets('neighbor navigation resets long entry scroll to the header', (
    tester,
  ) async {
    const before = LocalDate(2026, 10, 14);
    final caption = List.filled(80, 'A long caption.').join(' ');
    await pumpDayViewer(
      tester,
      photos: [
        viewerPhoto(caption: caption),
        viewerPhoto(id: 'before', date: before, caption: caption),
      ],
    );
    final scroll = tester
        .widget<UiScaffold>(dayKey('journey-day-viewer'))
        .controller!;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    await tester.ensureVisible(dayKey('day-previous'));
    expect(scroll.offset, greaterThan(0));
    await tester.tap(dayKey('day-previous'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(scroll.offset, 0);
    expect(tester.getTopLeft(find.byType(DayViewerHeader)).dy, closeTo(0, 1));
    expect(
      tester.widget<JourneyPhoto>(dayKey('journey-day-photo')).checkIn.id,
      'before',
    );
    expect(tester.takeException(), isNull);
  }, timeout: viewerTimeout);

  testWidgets('system back closes fullscreen and retains the day viewer', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('day-back-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/photo.png')
      ..writeAsBytesSync(base64Decode(viewerPixelPng));
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: SizedBox()),
    );
    await tester.runAsync(
      () =>
          precacheImage(FileImage(file), tester.element(find.byType(SizedBox))),
    );
    await pumpDayViewer(tester, photos: [viewerPhoto(path: file.path)]);
    await tester.tap(dayKey('journey-day-photo'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DayPhotoFullscreen), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DayPhotoFullscreen), findsNothing);
    expect(find.byType(DayViewerScreen), findsOneWidget);
    expect(dayKey('journey-day-photo'), findsOneWidget);
    expect(find.text('Journey destination'), findsNothing);
    expect(tester.takeException(), isNull);
  }, timeout: viewerTimeout);

  testWidgets('couple keeps local photos while the roster is unavailable', (
    tester,
  ) async {
    await pumpDayViewer(
      tester,
      journey: testJourney(kind: JourneyKind.group, maxMembers: 2),
      photos: [viewerPhoto(caption: 'Saved locally', metric: 71)],
    );
    expect(dayKey('journey-day-photo'), findsOneWidget);
    expect(find.text('Saved locally'), findsOneWidget);
    expect(dayKey('journey-day-metric-shown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: viewerTimeout);
  testWidgets('empty couple shows disabled unselected people chips', (
    tester,
  ) async {
    await pumpDayViewer(
      tester,
      journey: testJourney(kind: JourneyKind.group, maxMembers: 2),
    );
    expect(find.byType(DayEmptyState), findsOneWidget);
    final chips = tester.widgetList<UiPressable>(
      find.descendant(
        of: find.byType(DayPeopleSwitch),
        matching: find.byType(UiPressable),
      ),
    );
    expect(chips, hasLength(2));
    for (final chip in chips) {
      expect(chip.onPressed, isNull);
      expect(chip.selected, isFalse);
    }
    expect(tester.takeException(), isNull);
  }, timeout: viewerTimeout);
  testWidgets(
    'couple neighbors include partner-only dates and exclude blocked photos',
    (tester) async {
      final j = testJourney(kind: JourneyKind.group, maxMembers: 2);
      final mine = viewerPhoto();
      final partner = viewerPhoto(
        id: 'partner-only',
        user: 'u2',
        date: const LocalDate(2026, 10, 18),
      );
      for (final blocked in [false, true]) {
        final snapshot = GroupDailySnapshot.build(
          journey: j,
          allCheckIns: [mine, partner],
          members: const [
            MemberToday(
              userId: 'u1',
              displayName: 'An',
              role: MemberRole.owner,
            ),
            MemberToday(
              userId: 'u2',
              displayName: 'Binh',
              role: MemberRole.member,
            ),
          ],
          myUserId: 'u1',
          blockedIds: blocked ? {'u2'} : {},
          hasLoadedMembers: false,
        );
        await pumpDayViewer(
          tester,
          journey: j,
          photos: [mine],
          couple: snapshot,
        );
        if (blocked) {
          expect(dayKey('day-next'), findsNothing);
        } else {
          await tester.ensureVisible(dayKey('day-next'));
          await tester.tap(dayKey('day-next'));
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            tester.widget<JourneyPhoto>(dayKey('journey-day-photo')).checkIn.id,
            partner.id,
          );
          expect(dayKey('journey-day-caption'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      }
    },
    timeout: viewerTimeout,
  );
  testWidgets('neighbor navigation resets an existing multi-photo page', (
    tester,
  ) async {
    const before = LocalDate(2026, 10, 14);
    await pumpDayViewer(
      tester,
      photos: [
        viewerPhoto(id: 'old', hour: 10),
        viewerPhoto(id: 'latest'),
        viewerPhoto(id: 'before-old', date: before, hour: 9),
        viewerPhoto(id: 'before-new', date: before, hour: 11),
      ],
    );
    await tester.drag(dayKey('journey-day-pages'), const Offset(350, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1/2'), findsOneWidget);
    await tester.ensureVisible(dayKey('day-previous'));
    await tester.tap(dayKey('day-previous'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2/2'), findsOneWidget);
    expect(
      tester.widget<JourneyPhoto>(dayKey('journey-day-photo')).checkIn.id,
      'before-new',
    );
    final pageView = tester.widget<PageView>(dayKey('journey-day-pages'));
    expect(pageView.controller!.page, 1);
    expect(tester.takeException(), isNull);
  }, timeout: viewerTimeout);
  testWidgets(
    'unreadable image disables expand and retries a repaired file at the same path',
    (tester) async {
      final missing =
          '${Directory.systemTemp.path}/missing-viewer-'
          '${DateTime.now().microsecondsSinceEpoch}.jpg';
      final container = await pumpDayViewer(
        tester,
        photos: [viewerPhoto(library: true, path: missing)],
      );
      // Flush file I/O and image callbacks with a bounded number of event turns.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 400));
      }
      final expand = tester.widget<UiIconButton>(
        find.byWidgetPredicate(
          (w) => w is UiIconButton && w.label == 'Xem ảnh đầy đủ',
        ),
      );
      expect(expand.onPressed, isNull);
      expect(find.text('Ảnh chưa tải được'), findsOneWidget);
      final size = tester.getSize(dayKey('journey-day-pages'));
      expect(size.width / size.height, closeTo(.75, .01));
      expect(find.byType(DayPhotoFullscreen), findsNothing);
      final file = File(missing)
        ..writeAsBytesSync(base64Decode(viewerPixelPng));
      addTearDown(() => file.deleteSync());
      await tester.runAsync(() async {
        await FileImage(file).evict();
        await precacheImage(
          FileImage(file),
          tester.element(dayKey('journey-day-photo')),
        );
      });
      container.invalidate(myCheckInsProvider('j1'));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.tap(
        find.bySemanticsLabel('Xem \u1ea3nh \u0111\u1ea7y \u0111\u1ee7'),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DayPhotoFullscreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    timeout: viewerTimeout,
  );
  testWidgets(
    'non-reduced ratio switch and double-tap animate; fullscreen stays black',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('day-viewer-');
      addTearDown(() => dir.deleteSync(recursive: true));
      // A real 800x200 PNG, without depending on the test rasterizer.
      final file = File('${dir.path}/landscape.png')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAyAAAADICAIAAACf7RJNAAADpElEQVR4nO3WUQkAIBTAwBfOLFawviUGghxcgH1u1tkAAITmeQEAwGcMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQMFgBAzGABAMQuY4e6UI2BDZsAAAAASUVORK5CYII=',
          ),
        );
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          FileImage(file),
          tester.element(find.byType(SizedBox)),
        ),
      );
      await pumpDayViewer(
        tester,
        reduced: false,
        photos: [
          viewerPhoto(library: true, path: file.path),
          viewerPhoto(id: 'camera', hour: 13, path: file.path),
        ],
      );
      final portraitHeight = tester
          .getSize(
            find.descendant(
              of: dayKey('journey-day-drag-surface'),
              matching: find.byType(AnimatedSize),
            ),
          )
          .height;
      final controller = tester
          .widget<PageView>(dayKey('journey-day-pages'))
          .controller!;
      controller.jumpToPage(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final middleHeight = tester
          .getSize(
            find.descendant(
              of: dayKey('journey-day-drag-surface'),
              matching: find.byType(AnimatedSize),
            ),
          )
          .height;
      await tester.pump(const Duration(milliseconds: 200));
      final landscapeHeight = tester
          .getSize(dayKey('journey-day-pages'))
          .height;
      expect(middleHeight, lessThan(portraitHeight));
      expect(middleHeight, greaterThan(landscapeHeight));
      expect(dayKey('journey-day-chrome-fade'), findsOneWidget);
      final size = tester.getSize(dayKey('journey-day-pages'));
      expect(size.width / size.height, closeTo(4 / 3, .02));
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is UiIconButton &&
              w.label == 'Xem \u1ea3nh \u0111\u1ea7y \u0111\u1ee7',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DayPhotoFullscreen), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(DayPhotoFullscreen),
          matching: find.byType(Scaffold),
        ),
      );
      expect(scaffold.backgroundColor, UiCamera.bg);
      await tester.tap(find.byType(UiIconButton).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DayPhotoFullscreen), findsNothing);
      await tester.tap(dayKey('journey-day-photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DayPhotoFullscreen), findsOneWidget);
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final midScale = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value
          .getMaxScaleOnAxis();
      expect(midScale, greaterThan(1));
      expect(midScale, lessThan(2.5));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .transformationController!
            .value
            .getMaxScaleOnAxis(),
        closeTo(2.5, .01),
      );
      await pumpDayViewer(
        tester,
        brightness: Brightness.dark,
        photos: [viewerPhoto(library: true, path: file.path)],
      );
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is UiIconButton &&
              w.label == 'Xem \u1ea3nh \u0111\u1ea7y \u0111\u1ee7',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<Scaffold>(
              find.descendant(
                of: find.byType(DayPhotoFullscreen),
                matching: find.byType(Scaffold),
              ),
            )
            .backgroundColor,
        UiCamera.bg,
      );
    },
    timeout: viewerTimeout,
  );
  testWidgets(
    'short entries keep neighbor buttons above the bottom safe inset',
    (tester) async {
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      await pumpDayViewer(
        tester,
        photos: [
          viewerPhoto(),
          viewerPhoto(id: 'before', date: const LocalDate(2026, 10, 14)),
          viewerPhoto(id: 'after', date: const LocalDate(2026, 10, 18)),
        ],
      );
      expect(
        tester.getRect(find.byType(DayNeighborNav)).bottom,
        closeTo(844 - 34 - UiSpace.md, .1),
      );
      expect(tester.takeException(), isNull);
    },
    timeout: viewerTimeout,
  );
  testWidgets(
    'camera portrait and compact viewport height cap, themed canvas',
    (tester) async {
      await pumpDayViewer(
        tester,
        photos: [viewerPhoto()],
        size: const Size(360, 640),
      );
      final size = tester.getSize(dayKey('journey-day-pages'));
      expect(size.width / size.height, closeTo(.75, .01));
      expect(size.height, lessThanOrEqualTo(640 * .62));
      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: dayKey('journey-day-viewer'),
          matching: find.byType(Scaffold),
        ),
      );
      expect(
        scaffold.backgroundColor,
        tester.element(dayKey('journey-day-viewer')).ui.bg,
      );
      expect(scaffold.backgroundColor, isNot(UiCamera.bg));
      expect(tester.takeException(), isNull);
    },
    timeout: viewerTimeout,
  );
  testWidgets(
    'header follows camera time and same-day paging, neighbors reset page',
    (tester) async {
      await pumpDayViewer(
        tester,
        photos: [
          viewerPhoto(id: 'old', hour: 10, metric: 70),
          viewerPhoto(id: 'latest', metric: 71),
          viewerPhoto(
            id: 'prev',
            date: const LocalDate(2026, 10, 14),
            metric: 69,
          ),
        ],
      );
      expect(find.text('Ng\u00e0y 7/30 \u00b7 19:29'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);
      await tester.drag(dayKey('journey-day-pages'), const Offset(350, 0));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Ng\u00e0y 7/30 \u00b7 17:29'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      await tester.ensureVisible(dayKey('day-previous'));
      await tester.tap(dayKey('day-previous'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Ng\u00e0y 5/30 \u00b7 19:29'), findsOneWidget);
      expect(dayKey('journey-day-counter'), findsNothing);
      expect(dayKey('day-next'), findsOneWidget);
    },
    timeout: viewerTimeout,
  );
  testWidgets(
    'library suppresses time and after-end/open terms use uncapped ordinal',
    (tester) async {
      await pumpDayViewer(
        tester,
        journey: testJourney(durationDays: 3),
        photos: [viewerPhoto(library: true)],
      );
      expect(find.text('Ng\u00e0y 7'), findsOneWidget);
      expect(find.textContaining('19:29'), findsNothing);
    },
    timeout: viewerTimeout,
  );
  testWidgets('day 32 and open-ended header retain the authored ordinal', (
    tester,
  ) async {
    const afterEnd = LocalDate(2026, 11, 10);
    await pumpDayViewer(
      tester,
      date: afterEnd,
      photos: [viewerPhoto(date: afterEnd)],
    );
    expect(find.text('Ng\u00e0y 32 \u00b7 19:29'), findsOneWidget);
    await pumpDayViewer(
      tester,
      journey: testJourney(durationDays: null),
      photos: [viewerPhoto()],
    );
    expect(find.text('Ng\u00e0y 7 \u00b7 19:29'), findsOneWidget);
  }, timeout: viewerTimeout);
  testWidgets('12 hour header respects system preference', (tester) async {
    await pumpDayViewer(
      tester,
      locale: const Locale('en'),
      use24h: false,
      photos: [viewerPhoto()],
    );
    expect(find.textContaining('7:29 PM'), findsOneWidget);
  }, timeout: viewerTimeout);
  testWidgets('empty past has journey exit and neighbors; no check-in', (
    tester,
  ) async {
    await pumpDayViewer(
      tester,
      date: const LocalDate(2026, 10, 15),
      photos: [
        viewerPhoto(date: const LocalDate(2026, 10, 14)),
        viewerPhoto(),
      ],
    );
    expect(find.text('Check-in'), findsNothing);
    expect(dayKey('day-previous'), findsOneWidget);
    expect(dayKey('day-next'), findsOneWidget);
    await tester.tap(find.text('M\u1edf h\u00e0nh tr\u00ecnh'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Journey destination'), findsOneWidget);
  }, timeout: viewerTimeout);
  testWidgets('empty today allows check-in; inactive membership does not', (
    tester,
  ) async {
    final container = await pumpDayViewer(tester);
    await tester.tap(find.widgetWithText(UiButton, 'Check-in'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Camera destination'), findsOneWidget);
    expect(container.read(activeJourneyIdProvider), 'j1');
    await pumpDayViewer(tester);
    expect(find.widgetWithText(UiButton, 'Check-in'), findsOneWidget);
    await pumpDayViewer(tester, activeMember: false);
    expect(find.widgetWithText(UiButton, 'Check-in'), findsNothing);
  }, timeout: viewerTimeout);
  testWidgets('invalid and ended empty days have no check-in; error retries', (
    tester,
  ) async {
    await pumpDayViewer(tester, date: null);
    expect(dayKey('day-previous'), findsNothing);
    expect(find.widgetWithText(UiButton, 'Check-in'), findsNothing);
    await pumpDayViewer(
      tester,
      journey: testJourney(status: JourneyStatus.ended),
    );
    expect(find.widgetWithText(UiButton, 'Check-in'), findsNothing);
    var calls = 0;
    await pumpDayViewer(
      tester,
      photoStream: () => ++calls == 1
          ? Stream.error(const FileSystemException('offline'))
          : Stream.value([]),
    );
    expect(dayKey('journey-day-error'), findsOneWidget);
    await tester.tap(dayKey('journey-day-retry'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(calls, 2);
    expect(dayKey('journey-day-error'), findsNothing);
  }, timeout: viewerTimeout);
  testWidgets('vertical drag still dismisses with reduced motion', (
    tester,
  ) async {
    await pumpDayViewer(tester, photos: [viewerPhoto()]);
    await tester.drag(dayKey('journey-day-drag-surface'), const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Journey destination'), findsOneWidget);
    expect(dayKey('journey-day-drag-transform'), findsNothing);
  }, timeout: viewerTimeout);
  testWidgets('couple missing partner is a disabled chip; both photos switch', (
    tester,
  ) async {
    final j = testJourney(kind: JourneyKind.group, maxMembers: 2);
    final mine = viewerPhoto(caption: 'Mine');
    final partner = viewerPhoto(id: 'partner', user: 'u2');
    GroupDailySnapshot snapshot(
      List<CheckIn> photos,
    ) => GroupDailySnapshot.build(
      journey: j,
      allCheckIns: photos,
      members: const [
        MemberToday(userId: 'u1', displayName: 'An', role: MemberRole.owner),
        MemberToday(userId: 'u2', displayName: 'Binh', role: MemberRole.member),
      ],
      myUserId: 'u1',
      hasLoadedMembers: false,
    );
    await pumpDayViewer(
      tester,
      journey: j,
      photos: [mine],
      couple: snapshot([mine]),
    );
    expect(
      find.text('Binh ch\u01b0a c\u00f3 \u1ea3nh ng\u00e0y n\u00e0y'),
      findsOneWidget,
    );
    final chip = find.byKey(
      const ValueKey<(String, int, String?)>(('day-person-chip', 1, 'u2')),
    );
    expect(tester.widget<UiPressable>(chip).onPressed, isNull);
    await pumpDayViewer(
      tester,
      journey: j,
      photos: [mine],
      couple: snapshot([mine, partner]),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<(String, int, String?)>(('day-person-chip', 1, 'u2')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2/2'), findsOneWidget);
    expect(dayKey('journey-day-caption'), findsNothing);
  }, timeout: viewerTimeout);
  testWidgets('partner photo reactions enable only while journey active', (
    tester,
  ) async {
    final j = testJourney(kind: JourneyKind.group, maxMembers: 2);
    final mine = viewerPhoto();
    final partner = viewerPhoto(id: 'partner', user: 'u2');
    final snapshot = GroupDailySnapshot.build(
      journey: j,
      allCheckIns: [mine, partner],
      members: const [
        MemberToday(userId: 'u1', displayName: 'An', role: MemberRole.owner),
        MemberToday(userId: 'u2', displayName: 'Binh', role: MemberRole.member),
      ],
      myUserId: 'u1',
      hasLoadedMembers: false,
    );
    for (final ended in [false, true]) {
      await pumpDayViewer(
        tester,
        journey: ended ? j.copyWith(status: JourneyStatus.ended) : j,
        photos: [mine],
        couple: snapshot,
        localOnly: false,
      );
      await tester.tap(
        find.byKey(
          const ValueKey<(String, int, String?)>(('day-person-chip', 1, 'u2')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ReactionBar), findsOneWidget);
      expect(
        tester.widget<ReactionBar>(find.byType(ReactionBar)).enabled,
        !ended,
      );
    }
  }, timeout: viewerTimeout);
  testWidgets(
    'reactions respect own zero, uploads, membership, blocking and local mode',
    (tester) async {
      final j = testJourney(kind: JourneyKind.group);
      final r = Reaction(
        checkInId: 'photo',
        userId: 'u2',
        emoji: '\u2764\ufe0f',
        createdAt: testNow,
      );
      await pumpDayViewer(
        tester,
        journey: j,
        localOnly: false,
        photos: [viewerPhoto()],
      );
      expect(find.byType(ReactionBar), findsNothing);
      await pumpDayViewer(
        tester,
        journey: j,
        localOnly: false,
        photos: [viewerPhoto()],
        reactions: [r],
      );
      expect(find.byType(ReactionBar), findsOneWidget);
      expect(
        tester.widget<ReactionBar>(find.byType(ReactionBar)).enabled,
        isFalse,
      );
      await pumpDayViewer(
        tester,
        journey: j,
        localOnly: false,
        photos: [viewerPhoto()],
        reactions: [r],
        blocked: {'u2'},
      );
      expect(find.byType(ReactionBar), findsNothing);
      await pumpDayViewer(
        tester,
        journey: j,
        localOnly: false,
        photos: [viewerPhoto(uploaded: false)],
        reactions: [r],
      );
      expect(find.byType(ReactionBar), findsNothing);
      await pumpDayViewer(
        tester,
        journey: j,
        photos: [viewerPhoto()],
        reactions: [r],
      );
      expect(find.byType(ReactionBar), findsNothing);
      await pumpDayViewer(
        tester,
        journey: j,
        localOnly: false,
        activeMember: false,
        photos: [viewerPhoto()],
        reactions: [r],
      );
      expect(find.byType(ReactionBar), findsNothing);
      await pumpDayViewer(
        tester,
        localOnly: false,
        photos: [viewerPhoto()],
        reactions: [r],
      );
      expect(find.byType(ReactionBar), findsNothing);
    },
    timeout: viewerTimeout,
  );
  for (final brightness in Brightness.values) {
    testWidgets('header semantics and accessible controls $brightness', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpDayViewer(
          tester,
          brightness: brightness,
          photos: [
            viewerPhoto(id: 'before', date: const LocalDate(2026, 10, 14)),
            viewerPhoto(id: 'after', date: const LocalDate(2026, 10, 18)),
          ],
        );
        expect(find.bySemanticsLabel(RegExp('Check-in tr')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Check-in sau')), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.header == true,
          ),
          findsOneWidget,
        );
        final scaffold = tester.widget<Scaffold>(
          find.descendant(
            of: dayKey('journey-day-viewer'),
            matching: find.byType(Scaffold),
          ),
        );
        expect(
          scaffold.backgroundColor,
          tester.element(dayKey('journey-day-viewer')).ui.bg,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        handle.dispose();
      }
    }, timeout: viewerTimeout);
  }
  for (final brightness in Brightness.values) {
    for (final lang in ['vi', 'en']) {
      testWidgets('large type long entry $brightness $lang has no overflow', (
        tester,
      ) async {
        await pumpDayViewer(
          tester,
          brightness: brightness,
          locale: Locale(lang),
          scale: 1.35,
          size: const Size(360, 780),
          journey: testJourney(
            title: List.filled(12, 'A long journey').join(' '),
          ),
          photos: [
            viewerPhoto(caption: List.filled(140, 'a').join()),
            viewerPhoto(id: 'before', date: const LocalDate(2026, 10, 14)),
            viewerPhoto(id: 'after', date: const LocalDate(2026, 10, 18)),
          ],
        );
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(find.byType(DayNeighborNav), findsOneWidget);
      }, timeout: viewerTimeout);
    }
  }
}
