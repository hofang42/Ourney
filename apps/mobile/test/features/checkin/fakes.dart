// Test doubles for the camera and checkin features (B3). Repository
// providers throw until B1 wires lib/data, so every test overrides them.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/camera/camera_session.dart';
import 'package:ourney/features/camera/capture_services.dart';
import 'package:ourney/features/checkin/journey_clock.dart';
import 'package:ourney/features/checkin/photo_compressor.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed "now" used by the fakes: 2026-10-16 10:00 in Asia/Ho_Chi_Minh.
final testNowUtc = DateTime.utc(2026, 10, 16, 3);
const testToday = LocalDate(2026, 10, 16);
const testOffset = Duration(hours: 7);

Journey testJourney({
  String id = 'j1',
  String title = 'Chạy bộ',
  LocalDate start = const LocalDate(2026, 10, 1),
  int? durationDays = 30,
  String? metricName,
  String? metricUnit,
  bool hideMetricDefault = false,
  TemplateId templateId = TemplateId.custom,
  JourneyStatus status = JourneyStatus.active,
}) => Journey(
  id: id,
  ownerId: 'me',
  kind: JourneyKind.solo,
  templateId: templateId,
  title: title,
  emoji: '🏃',
  startDate: start,
  durationDays: durationDays,
  timezone: 'Asia/Ho_Chi_Minh',
  visibility: JourneyVisibility.private,
  status: status,
  metricName: metricName,
  metricUnit: metricUnit,
  hideMetricDefault: hideMetricDefault,
);

CheckIn testCheckIn(LocalDate day, {String journeyId = 'j1'}) => CheckIn(
  id: 'c-$day',
  journeyId: journeyId,
  userId: 'me',
  localDate: day,
  capturedAt: DateTime.utc(day.year, day.month, day.day, 3),
  photoPath: 'p/$day.jpg',
  thumbPath: 'p/${day}_t.jpg',
);

class FakeJourneyRepository implements JourneyRepository {
  FakeJourneyRepository({List<Journey>? journeys, this.membership})
    : journeys = journeys ?? [testJourney()];

  final List<Journey> journeys;
  final Membership? membership;
  Object? activeError;

  @override
  Stream<List<Journey>> watchActive() => activeError != null
      ? Stream.error(activeError!)
      : Stream.value(List.of(journeys));

  @override
  Stream<Journey?> watch(String journeyId) =>
      Stream.value(journeys.where((j) => j.id == journeyId).firstOrNull);

  @override
  Stream<Membership?> watchMyMembership(String journeyId) =>
      Stream.value(membership);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeCheckInRepository implements CheckInRepository {
  FakeCheckInRepository({List<CheckIn>? existing}) : existing = existing ?? [];

  final List<CheckIn> existing;
  final List<CheckInDraft> submitted = [];
  Object? submitError;

  @override
  Stream<List<CheckIn>> watchForJourney(String journeyId, {String? userId}) =>
      Stream.value([
        for (final c in existing)
          if (c.journeyId == journeyId) c,
      ]);

  @override
  Future<CheckIn> submit(CheckInDraft draft) async {
    if (submitError != null) throw submitError!;
    submitted.add(draft);
    final day = localDateOf(draft.capturedAt, testOffset);
    return CheckIn(
      id: 'new-${submitted.length}',
      journeyId: draft.journeyId,
      userId: 'me',
      localDate: day,
      capturedAt: draft.capturedAt,
      photoPath: 'remote/photo.jpg',
      thumbPath: 'remote/thumb.jpg',
      fromLibrary: draft.fromLibrary,
      caption: draft.caption,
      metricValue: draft.metricValue,
      localPhotoFile: draft.photoFile,
    );
  }

  @override
  Stream<int> watchPendingUploads() => Stream.value(0);
}

class FakePhotoCompressor implements PhotoCompressor {
  final List<String> sources = [];
  bool fail = false;

  @override
  Future<CompressedPhoto> compress(String sourcePath) async {
    if (fail) throw const PhotoCompressException('test');
    sources.add(sourcePath);
    return CompressedPhoto(
      photoFile: '$sourcePath.1080.jpg',
      thumbFile: '$sourcePath.thumb.jpg',
    );
  }
}

/// Fixed clock in a +07:00 zone, so tests never load the tz database.
class FakeJourneyClock implements JourneyClock {
  FakeJourneyClock([DateTime? now]) : now = now ?? testNowUtc;

  DateTime now;

  @override
  DateTime nowUtc() => now;

  @override
  LocalDate localDate(DateTime instant, String timezone) =>
      localDateOf(instant, testOffset);
}

class FakeCameraSession implements CameraSession {
  FakeCameraSession({this.failure, this.switchable = true});

  /// When set, [start] throws this failure.
  CameraFailure? failure;
  bool switchable;

  int starts = 0;
  int stops = 0;
  int pictures = 0;
  final List<FlashSetting> flashes = [];
  bool _ready = false;
  bool _front = false;

  @override
  Future<void> start({bool front = false}) async {
    starts++;
    final f = failure;
    if (f != null) throw CameraStartException(f);
    _front = front;
    _ready = true;
  }

  @override
  bool get isReady => _ready;

  @override
  bool get canSwitch => switchable;

  @override
  bool get hasFlash => _ready && !_front;

  @override
  bool get isFront => _front;

  @override
  Widget buildPreview() =>
      const ColoredBox(key: ValueKey('fake-preview'), color: Colors.black);

  @override
  Future<void> setFlash(FlashSetting flash) async => flashes.add(flash);

  @override
  Future<void> switchLens() => start(front: !_front);

  @override
  Future<String> takePicture() async {
    pictures++;
    return '/tmp/shot$pictures.jpg';
  }

  @override
  Future<void> stop() async {
    stops++;
    _ready = false;
  }
}

class FakeGalleryPicker implements GalleryPicker {
  FakeGalleryPicker([this.result = '/tmp/library.jpg']);

  final String? result;
  int calls = 0;

  @override
  Future<String?> pickPhoto() async {
    calls++;
    return result;
  }
}

class FakeSettingsOpener implements AppSettingsOpener {
  FakeSettingsOpener({this.supported = true});

  @override
  final bool supported;
  int opened = 0;

  @override
  Future<bool> open() async {
    opened++;
    return true;
  }
}

/// Records the path and `extra` of every route the harness renders.
class RouteLog {
  final List<String> locations = [];
  final List<Object?> extras = [];
}

Widget _stub(String label, GoRouterState state, RouteLog log) {
  log.locations.add(state.uri.toString());
  log.extras.add(state.extra);
  return Scaffold(body: Text('stub:$label', key: ValueKey('stub-$label')));
}

/// Builds a [GoRouter] app with [routes] plus stubs for the routes the B3
/// screens navigate to (`/journeys/new`, `/share/:id`, and `/capture` or
/// `/checkin` when not provided).
Widget routedTestApp({
  required ProviderContainer container,
  required List<RouteBase> routes,
  required String initialLocation,
  Object? initialExtra,
  required RouteLog log,
  Locale locale = const Locale('vi'),
}) {
  final paths = {
    for (final r in routes)
      if (r is GoRoute) r.path,
  };
  final router = GoRouter(
    initialLocation: initialLocation,
    initialExtra: initialExtra,
    routes: [
      ...routes,
      if (!paths.contains('/capture'))
        GoRoute(path: '/capture', builder: (_, s) => _stub('capture', s, log)),
      if (!paths.contains('/checkin'))
        GoRoute(path: '/checkin', builder: (_, s) => _stub('checkin', s, log)),
      GoRoute(
        path: '/journeys/new',
        builder: (_, s) => _stub('journeys-new', s, log),
      ),
      GoRoute(
        path: '/share/:journeyId',
        builder: (_, s) => _stub('share', s, log),
      ),
    ],
  );
  addTearDown(router.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: buildAppTheme(Brightness.light),
      locale: locale,
      localizationsDelegates: ourneyLocalizationsDelegates,
      supportedLocales: ourneySupportedLocales,
      routerConfig: router,
    ),
  );
}

List<Override> baseOverrides({
  required SharedPreferencesWithCache prefs,
  JourneyRepository? journeys,
  CheckInRepository? checkIns,
}) => [
  appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
  sharedPreferencesProvider.overrideWithValue(prefs),
  supabaseClientProvider.overrideWithValue(null),
  draftFilesProvider.overrideWithValue(FakeDraftFiles()),
  if (journeys != null) journeyRepositoryProvider.overrideWithValue(journeys),
  if (checkIns != null) checkInRepositoryProvider.overrideWithValue(checkIns),
];

/// Records which draft files the check-in flow discards.
class FakeDraftFiles implements DraftFiles {
  final List<String> discarded = [];

  @override
  Future<void> discard(Iterable<String> paths) async => discarded.addAll(paths);
}
