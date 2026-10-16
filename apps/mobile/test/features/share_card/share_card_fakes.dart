import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/share_card/data/share_card_exporter.dart';
import 'package:ourney/features/share_card/data/share_card_providers.dart';
import 'package:ourney/features/share_card/domain/share_card_content.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';

const testTz = 'Asia/Ho_Chi_Minh';

/// 2026-10-16 12:00 in Ho Chi Minh City.
final testNow = DateTime.utc(2026, 10, 16, 5);

/// A valid `[a-z0-9]{40}` public token.
final testToken = 'tok${'0' * 37}';

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
  JourneyVisibility? visibility,
  String? publicToken,
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
  visibility: visibility ?? defaultVisibilityFor(kind),
  status: status,
  publicToken: publicToken,
  metricName: metricName,
  metricUnit: metricUnit,
  hideMetricDefault: hideMetricDefault,
);

/// Weight-loss journey as the create flow makes it (FR-B7 defaults).
Journey weightLossJourney() => testJourney(
  templateId: TemplateId.weightLoss,
  title: 'Giảm cân',
  emoji: '⚖️',
  metricName: 'Cân nặng',
  metricUnit: 'kg',
  hideMetricDefault: true,
);

Membership testMembership(
  Journey j, {
  String userId = 'u1',
  MemberRole? role,
  bool hideMetric = false,
  bool blurMedia = false,
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
  blurMedia: blurMedia,
);

CheckIn testCheckIn(
  String journeyId,
  LocalDate date, {
  String userId = 'u1',
  double? metricValue,
}) => CheckIn(
  id: 'c-$date',
  journeyId: journeyId,
  userId: userId,
  localDate: date,
  capturedAt: DateTime.utc(date.year, date.month, date.day, 2),
  photoPath: checkInPhotoPath(journeyId, userId, 'c-$date'),
  thumbPath: checkInThumbPath(journeyId, userId, 'c-$date'),
  metricValue: metricValue,
  uploaded: true,
);

/// Check-ins on Oct 10..[lastDay] (consecutive), so today (16th, still open)
/// has a live streak.
List<CheckIn> streakCheckIns(
  String journeyId, {
  int lastDay = 15,
  double? metricValue,
}) => [
  for (var d = 10; d <= lastDay; d++)
    testCheckIn(journeyId, LocalDate(2026, 10, d), metricValue: metricValue),
];

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

  final List<String> calls = [];

  /// When set, the next setPublicLink throws it.
  Object? linkError;

  /// Whether setPublicLink also updates the journey stream (like the real
  /// repository after the RPC).
  bool echoLinkChanges = true;

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
  Future<String?> setPublicLink(
    String journeyId, {
    required bool enabled,
  }) async {
    calls.add('setPublicLink:$journeyId:$enabled');
    if (linkError case final e?) {
      linkError = null;
      throw e;
    }
    final token = enabled ? testToken : null;
    if (echoLinkChanges) {
      _journeys.set([
        for (final j in _journeys.value)
          j.id == journeyId ? _withLink(j, token) : j,
      ]);
    }
    return token;
  }

  static Journey _withLink(Journey j, String? token) => Journey(
    id: j.id,
    ownerId: j.ownerId,
    kind: j.kind,
    templateId: j.templateId,
    title: j.title,
    emoji: j.emoji,
    startDate: j.startDate,
    durationDays: j.durationDays,
    timezone: j.timezone,
    visibility: token == null
        ? JourneyVisibility.private
        : JourneyVisibility.link,
    status: j.status,
    metricName: j.metricName,
    metricUnit: j.metricUnit,
    hideMetricDefault: j.hideMetricDefault,
    publicToken: token,
  );

  @override
  Future<Journey> create(JourneyDraft draft) => throw UnimplementedError();

  @override
  Future<void> end(String journeyId) => throw UnimplementedError();

  @override
  Future<void> archive(String journeyId) => throw UnimplementedError();

  @override
  Future<void> delete(String journeyId) => throw UnimplementedError();

  @override
  Future<void> updateMyMembership(
    String journeyId, {
    bool? hideMetric,
    bool? blurMedia,
  }) => throw UnimplementedError();
}

class FakeCheckInRepository implements CheckInRepository {
  FakeCheckInRepository([List<CheckIn> checkIns = const []])
    : _all = _Live(List.of(checkIns));

  final _Live<List<CheckIn>> _all;

  @override
  Stream<List<CheckIn>> watchForJourney(String journeyId, {String? userId}) =>
      _all.watch().map(
        (list) => [
          for (final c in list)
            if (c.journeyId == journeyId &&
                (userId == null || c.userId == userId))
              c,
        ],
      );

  @override
  Future<CheckIn> submit(CheckInDraft draft) => throw UnimplementedError();

  @override
  Stream<int> watchPendingUploads() => Stream.value(0);
}

/// Resolves every path to a (non-existent) local file when [resolve] is
/// true, so the card has a photo; otherwise fails like an offline cache
/// miss and the card falls back to its illustration.
class FakeMediaStore implements MediaStore {
  FakeMediaStore({this.resolve = false});

  final bool resolve;
  final List<String> requested = [];

  @override
  Future<String> localFileFor(String storagePath) async {
    requested.add(storagePath);
    if (!resolve) throw const OurneyException(OurneyErrorCode.offline);
    return '/nonexistent/$storagePath';
  }
}

class SharedImage {
  const SharedImage(this.path, this.mimeType, this.text, this.origin);
  final String path;
  final String mimeType;
  final String? text;
  final Rect? origin;
}

class FakeSharer implements ShareCardSharer {
  final List<SharedImage> shared = [];

  @override
  Future<void> shareImage({
    required String path,
    required String mimeType,
    String? text,
    Rect? origin,
  }) async {
    shared.add(SharedImage(path, mimeType, text, origin));
  }
}

/// Records what would be captured instead of rendering (toImage needs real
/// async; the real exporter is covered in share_card_export_test.dart).
class FakeExporter extends ShareCardExporter {
  final List<({Size boundarySize, ShareCardFormat format, String baseName})>
  exports = [];

  Object? error;

  @override
  Future<ShareCardFile> export(
    RenderRepaintBoundary boundary,
    ShareCardFormat format, {
    required String baseName,
  }) async {
    if (error case final e?) throw e;
    exports.add((
      boundarySize: boundary.size,
      format: format,
      baseName: baseName,
    ));
    return ShareCardFile(
      path: '/tmp/$baseName.png',
      image: ShareCardImage(
        bytes: Uint8List(0),
        width: format.pixelWidth,
        height: format.pixelHeight,
        format: ShareCardImageFormat.png,
      ),
    );
  }
}

class ShareHarness {
  ShareHarness(
    this.container,
    this.journeys,
    this.sharer,
    this.exporter,
    this.clipboard,
  );

  final ProviderContainer container;
  final FakeJourneyRepository journeys;
  final FakeSharer sharer;
  final FakeExporter exporter;
  final List<String> clipboard;

  String get location => container.read(routerProvider).state.uri.toString();
}

/// Pumps the real app (router) on `/share/<journey.id>` with fakes, a fixed
/// clock and reduce motion on.
Future<ShareHarness> pumpShare(
  WidgetTester tester, {
  required Journey journey,
  Membership? membership,
  List<CheckIn> checkIns = const [],
  bool backend = false,
  bool photos = false,
  Locale locale = const Locale('vi'),
  double textScale = 1,
  Size size = const Size(420, 1800),
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  final clipboard = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  final repo = FakeJourneyRepository(
    journeys: [journey],
    memberships: {journey.id: membership ?? testMembership(journey)},
  );
  final sharer = FakeSharer();
  final exporter = FakeExporter();
  final container = await pumpOurneyApp(
    tester,
    config: backend ? testBackendConfig : const AppConfig.localOnly(),
    locale: locale,
    auth: backend ? FakeAuthRepository(userId: 'u1') : null,
    overrides: [
      journeyRepositoryProvider.overrideWithValue(repo),
      checkInRepositoryProvider.overrideWithValue(
        FakeCheckInRepository(checkIns),
      ),
      mediaStoreProvider.overrideWithValue(FakeMediaStore(resolve: photos)),
      shareCardClockProvider.overrideWithValue(Clock.fixed(testNow)),
      shareCardSharerProvider.overrideWithValue(sharer),
      shareCardExporterProvider.overrideWithValue(exporter),
    ],
  );
  container.read(routerProvider).go(AppRoutes.share(journey.id));
  await tester.pumpAndSettle();
  return ShareHarness(container, repo, sharer, exporter, clipboard);
}
