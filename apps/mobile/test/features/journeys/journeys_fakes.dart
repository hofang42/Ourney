import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';

const testTz = 'Asia/Ho_Chi_Minh';

/// 2026-10-16 12:00 in Ho Chi Minh City.
final testNow = DateTime.utc(2026, 10, 16, 5);
const testToday = LocalDate(2026, 10, 16);

/// A value plus a broadcast of its changes; new listeners get the current
/// value first (like the real repositories' local DB streams).
class _Live<T> {
  _Live(this.value);

  T value;
  final _changes = StreamController<T>.broadcast();

  void set(T v) {
    value = v;
    _changes.add(v);
  }

  Stream<T> watch() async* {
    yield value;
    yield* _changes.stream;
  }
}

Journey testJourney({
  String id = 'j1',
  String ownerId = 'u1',
  JourneyKind kind = JourneyKind.solo,
  TemplateId templateId = TemplateId.workout30,
  String title = 'Tập mỗi ngày',
  String emoji = '💪',
  LocalDate startDate = const LocalDate(2026, 10, 10),
  int? durationDays = 14,
  JourneyStatus status = JourneyStatus.active,
  String? metricName,
  String? metricUnit,
  bool hideMetricDefault = false,
}) => Journey(
  id: id,
  ownerId: ownerId,
  kind: kind,
  templateId: templateId,
  title: title,
  emoji: emoji,
  startDate: startDate,
  durationDays: durationDays,
  timezone: testTz,
  visibility: defaultVisibilityFor(kind),
  status: status,
  metricName: metricName,
  metricUnit: metricUnit,
  hideMetricDefault: hideMetricDefault,
);

Membership testMembership(
  Journey j, {
  String userId = 'u1',
  MemberRole? role,
  bool hideMetric = false,
}) => Membership(
  journeyId: j.id,
  userId: userId,
  role: role ?? (j.ownerId == userId ? MemberRole.owner : MemberRole.member),
  status: MemberStatus.active,
  // Joined at the journey start (00:30 local).
  joinedAt: DateTime.utc(
    j.startDate.year,
    j.startDate.month,
    j.startDate.day,
  ).subtract(const Duration(hours: 6, minutes: 30)),
  hideMetric: hideMetric,
);

CheckIn testCheckIn(
  String journeyId,
  LocalDate date, {
  String userId = 'u1',
  String? caption,
  double? metricValue,
}) => CheckIn(
  id: 'c-$journeyId-$date',
  journeyId: journeyId,
  userId: userId,
  localDate: date,
  capturedAt: DateTime.utc(date.year, date.month, date.day, 2),
  photoPath: checkInPhotoPath(journeyId, userId, 'c-$date'),
  thumbPath: checkInThumbPath(journeyId, userId, 'c-$date'),
  caption: caption,
  metricValue: metricValue,
  uploaded: true,
);

class FakeJourneyRepository implements JourneyRepository {
  FakeJourneyRepository({
    List<Journey> journeys = const [],
    Map<String, Membership> memberships = const {},
  }) : _journeys = _Live(List.of(journeys)),
       _memberships = {
         for (final e in memberships.entries) e.key: _Live(e.value),
       };

  final _Live<List<Journey>> _journeys;
  final Map<String, _Live<Membership?>> _memberships;

  final List<JourneyDraft> created = [];

  /// Every draft passed to [create], failed attempts included.
  final List<JourneyDraft> attempts = [];
  final List<String> calls = [];
  final List<({String id, bool? hideMetric, bool? blurMedia})> prefUpdates = [];

  /// When set, the next matching call throws it.
  Object? createError;
  Object? endError;
  Object? deleteError;

  List<Journey> get journeys => _journeys.value;

  void _replace(String id, Journey Function(Journey) f) =>
      _journeys.set([for (final j in _journeys.value) j.id == id ? f(j) : j]);

  @override
  Stream<List<Journey>> watchActive() => _journeys.watch();

  @override
  Stream<Journey?> watch(String journeyId) => _journeys.watch().map(
    (list) => list.where((j) => j.id == journeyId).firstOrNull,
  );

  @override
  Stream<Membership?> watchMyMembership(String journeyId) =>
      _memberships.putIfAbsent(journeyId, () => _Live(null)).watch();

  @override
  Future<Journey> create(JourneyDraft draft) async {
    calls.add('create');
    attempts.add(draft);
    if (createError case final e?) throw e;
    created.add(draft);
    final j = Journey(
      id: 'new-${created.length}',
      ownerId: 'u1',
      kind: draft.kind,
      templateId: draft.templateId,
      title: draft.title,
      emoji: draft.emoji,
      startDate: draft.startDate,
      durationDays: draft.durationDays,
      timezone: draft.timezone,
      visibility: draft.visibility,
      status: JourneyStatus.active,
      metricName: draft.metricName,
      metricUnit: draft.metricUnit,
      hideMetricDefault: draft.hideMetricDefault,
    );
    _journeys.set([..._journeys.value, j]);
    return j;
  }

  @override
  Future<void> end(String journeyId) async {
    calls.add('end:$journeyId');
    if (endError case final e?) throw e;
    _replace(journeyId, (j) => _copy(j, JourneyStatus.ended));
  }

  @override
  Future<void> archive(String journeyId) async {
    calls.add('archive:$journeyId');
    _replace(journeyId, (j) => _copy(j, JourneyStatus.archived));
  }

  @override
  Future<void> delete(String journeyId) async {
    calls.add('delete:$journeyId');
    if (deleteError case final e?) throw e;
    _journeys.set([
      for (final j in _journeys.value)
        if (j.id != journeyId) j,
    ]);
  }

  @override
  Future<String?> setPublicLink(String journeyId, {required bool enabled}) =>
      throw UnimplementedError();

  @override
  Future<void> updateMyMembership(
    String journeyId, {
    bool? hideMetric,
    bool? blurMedia,
  }) async {
    calls.add('updateMyMembership:$journeyId');
    prefUpdates.add((
      id: journeyId,
      hideMetric: hideMetric,
      blurMedia: blurMedia,
    ));
  }

  static Journey _copy(Journey j, JourneyStatus status) => Journey(
    id: j.id,
    ownerId: j.ownerId,
    kind: j.kind,
    templateId: j.templateId,
    title: j.title,
    emoji: j.emoji,
    startDate: j.startDate,
    durationDays: j.durationDays,
    timezone: j.timezone,
    visibility: j.visibility,
    status: status,
    metricName: j.metricName,
    metricUnit: j.metricUnit,
    hideMetricDefault: j.hideMetricDefault,
  );
}

class FakeCheckInRepository implements CheckInRepository {
  FakeCheckInRepository([List<CheckIn> checkIns = const []])
    : _all = _Live(List.of(checkIns));

  final _Live<List<CheckIn>> _all;
  final List<String?> requestedUserIds = [];

  @override
  Stream<List<CheckIn>> watchForJourney(String journeyId, {String? userId}) {
    requestedUserIds.add(userId);
    return _all.watch().map(
      (list) => [
        for (final c in list)
          if (c.journeyId == journeyId &&
              (userId == null || c.userId == userId))
            c,
      ],
    );
  }

  @override
  Future<CheckIn> submit(CheckInDraft draft) => throw UnimplementedError();

  @override
  Stream<int> watchPendingUploads() => Stream.value(0);
}

/// Never resolves files (no disk IO in widget tests): cells fall back to the
/// "checked" placeholder.
class FakeMediaStore implements MediaStore {
  @override
  Future<String> localFileFor(String storagePath) async =>
      throw const OurneyException(OurneyErrorCode.offline);
}

class JourneysHarness {
  JourneysHarness(this.container, this.journeys, this.checkIns);

  final ProviderContainer container;
  final FakeJourneyRepository journeys;
  final FakeCheckInRepository checkIns;

  /// Top-most location, including pushed routes.
  String get location => container.read(routerProvider).state.uri.toString();

  Future<void> go(WidgetTester tester, String path) async {
    container.read(routerProvider).go(path);
    await tester.pumpAndSettle();
  }
}

/// Pumps the real app (router + shell) with fake repositories, a fixed clock
/// and reduce motion on (no looping flame), then opens [location].
Future<JourneysHarness> pumpJourneys(
  WidgetTester tester, {
  FakeJourneyRepository? journeys,
  FakeCheckInRepository? checkIns,
  String location = '/journeys',
  AppConfig config = const AppConfig.localOnly(),
  String? userId,
  Locale locale = const Locale('vi'),
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  // Phone-shaped and tall enough that the whole detail screen is built.
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(420, 1800);
  addTearDown(tester.view.reset);
  final repo = journeys ?? FakeJourneyRepository();
  final ci = checkIns ?? FakeCheckInRepository();
  final container = await pumpOurneyApp(
    tester,
    config: config,
    locale: locale,
    auth: userId == null ? null : FakeAuthRepository(userId: userId),
    overrides: [
      journeyRepositoryProvider.overrideWithValue(repo),
      checkInRepositoryProvider.overrideWithValue(ci),
      mediaStoreProvider.overrideWithValue(FakeMediaStore()),
      journeysClockProvider.overrideWithValue(Clock.fixed(testNow)),
      deviceTimezoneProvider.overrideWith((ref) => testTz),
    ],
  );
  final h = JourneysHarness(container, repo, ci);
  await h.go(tester, location);
  return h;
}
