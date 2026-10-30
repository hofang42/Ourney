import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/router.dart';
import 'package:ourney/features/groups/data/groups_providers.dart';
import 'package:ourney/features/groups/ui/group_safety_hooks.dart';
import 'package:ourney/features/journeys/data/journeys_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';
import '../journeys/journeys_fakes.dart';

export '../journeys/journeys_fakes.dart'
    show
        FakeCheckInRepository,
        FakeJourneyRepository,
        FakeMediaStore,
        testCheckIn,
        testNow,
        testToday,
        testTz;

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

const me = 'u1';

Journey groupJourney({
  String id = 'g1',
  String ownerId = me,
  String title = 'Chạy bộ cùng nhau',
  LocalDate startDate = const LocalDate(2026, 10, 10),
  int? durationDays = 30,
  JourneyStatus status = JourneyStatus.active,
  String? inviteCode = 'ABCD1234',
  JourneyKind kind = JourneyKind.group,
}) => Journey(
  id: id,
  ownerId: ownerId,
  kind: kind,
  templateId: TemplateId.workout30,
  title: title,
  emoji: '🏃',
  startDate: startDate,
  durationDays: durationDays,
  timezone: testTz,
  visibility: defaultVisibilityFor(kind),
  status: status,
  inviteCode: kind == JourneyKind.group ? inviteCode : null,
);

Membership groupMembership(
  Journey j, {
  String userId = me,
  MemberRole? role,
  DateTime? joinedAt,
}) => Membership(
  journeyId: j.id,
  userId: userId,
  role: role ?? (j.ownerId == userId ? MemberRole.owner : MemberRole.member),
  status: MemberStatus.active,
  joinedAt: joinedAt ?? DateTime.utc(2026, 10, 9, 18),
);

MemberToday memberToday(
  String userId,
  String name, {
  MemberRole role = MemberRole.member,
  CheckIn? today,
  int streak = 0,
}) => MemberToday(
  userId: userId,
  displayName: name,
  role: role,
  todayCheckIn: today,
  currentStreak: streak,
);

class FakeGroupRepository implements GroupRepository {
  FakeGroupRepository({
    Map<String, List<MemberToday>> today = const {},
    Map<String, List<Reaction>> reactions = const {},
  }) : _today = {for (final e in today.entries) e.key: _Live(e.value)},
       _reactions = {for (final e in reactions.entries) e.key: _Live(e.value)};

  final Map<String, _Live<List<MemberToday>>> _today;
  final Map<String, _Live<List<Reaction>>> _reactions;
  final List<String> calls = [];

  /// Thrown by the next matching call when set.
  Object? joinError;
  Object? todayError;
  Object? reactError;
  String joinResult = 'g1';
  String rotateResult = 'NEWCODE9';

  /// Completes `joinByCode` (null = immediately).
  Completer<void>? joinGate;

  @override
  Future<String> joinByCode(String code) async {
    calls.add('join:$code');
    if (joinGate case final g?) await g.future;
    if (joinError case final e?) throw e;
    return joinResult;
  }

  @override
  Future<String> rotateInviteCode(String journeyId) async {
    calls.add('rotate:$journeyId');
    return rotateResult;
  }

  @override
  Stream<List<MemberToday>> watchToday(String journeyId) {
    if (todayError case final e?) return Stream.error(e);
    return _today.putIfAbsent(journeyId, () => _Live(const [])).watch();
  }

  void setToday(String journeyId, List<MemberToday> rows) =>
      _today.putIfAbsent(journeyId, () => _Live(const [])).set(rows);

  _Live<List<Reaction>> _r(String id) =>
      _reactions.putIfAbsent(id, () => _Live(const []));

  @override
  Future<void> react(String checkInId, String emoji) async {
    calls.add('react:$checkInId:$emoji');
    if (reactError case final e?) throw e;
    final live = _r(checkInId);
    live.set([
      for (final r in live.value)
        if (r.userId != me) r,
      Reaction(
        checkInId: checkInId,
        userId: me,
        emoji: emoji,
        createdAt: testNow,
      ),
    ]);
  }

  @override
  Future<void> unreact(String checkInId) async {
    calls.add('unreact:$checkInId');
    final live = _r(checkInId);
    live.set([
      for (final r in live.value)
        if (r.userId != me) r,
    ]);
  }

  @override
  Stream<List<Reaction>> watchReactions(String checkInId) =>
      _r(checkInId).watch();

  @override
  Future<void> leave(String journeyId) async => calls.add('leave:$journeyId');

  @override
  Future<void> removeMember(String journeyId, String userId) async {
    calls.add('remove:$journeyId:$userId');
    final live = _today[journeyId];
    if (live != null) {
      live.set([
        for (final m in live.value)
          if (m.userId != userId) m,
      ]);
    }
  }
}

class FakeSafetyRepository implements SafetyRepository {
  FakeSafetyRepository([Set<String> blocked = const {}])
    : _blocked = _Live(blocked);

  final _Live<Set<String>> _blocked;

  void setBlocked(Set<String> ids) => _blocked.set(ids);

  @override
  Stream<Set<String>> watchBlockedIds() => _blocked.watch();

  @override
  Future<void> block(String userId) async =>
      _blocked.set({..._blocked.value, userId});

  @override
  Future<void> unblock(String userId) async =>
      _blocked.set({..._blocked.value}..remove(userId));

  @override
  Future<void> report({
    String? checkInId,
    String? userId,
    required ReportReason reason,
    String? note,
  }) async {}
}

class GroupsHarness {
  GroupsHarness(
    this.container,
    this.groups,
    this.journeys,
    this.safety,
    this.shared,
    this.copied,
  );

  final ProviderContainer container;
  final FakeGroupRepository groups;
  final FakeJourneyRepository journeys;
  final FakeSafetyRepository safety;
  final List<String> shared;
  final List<String> copied;

  String get location => container.read(routerProvider).state.uri.toString();

  Future<void> go(WidgetTester tester, String path) async {
    container.read(routerProvider).go(path);
    await tester.pumpAndSettle();
  }
}

/// Pumps the real app with a backend config, signed in as [me], fake
/// repositories and a fixed clock, then opens [location].
Future<GroupsHarness> pumpGroups(
  WidgetTester tester, {
  String location = '/groups',
  FakeGroupRepository? groups,
  FakeJourneyRepository? journeys,
  FakeCheckInRepository? checkIns,
  FakeSafetyRepository? safety,
  GroupSafetyHooks hooks = const GroupSafetyHooks(),
  AppConfig config = testBackendConfig,
  Locale locale = const Locale('en'),
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(420, 2400);
  addTearDown(tester.view.reset);
  final g = groups ?? FakeGroupRepository();
  final j = journeys ?? FakeJourneyRepository();
  final s = safety ?? FakeSafetyRepository();
  final shared = <String>[];
  final copied = <String>[];
  final container = await pumpOurneyApp(
    tester,
    config: config,
    locale: locale,
    auth: FakeAuthRepository(userId: me),
    overrides: [
      groupRepositoryProvider.overrideWithValue(g),
      journeyRepositoryProvider.overrideWithValue(j),
      checkInRepositoryProvider.overrideWithValue(
        checkIns ?? FakeCheckInRepository(),
      ),
      safetyRepositoryProvider.overrideWithValue(s),
      mediaStoreProvider.overrideWithValue(FakeMediaStore()),
      journeysClockProvider.overrideWithValue(Clock.fixed(testNow)),
      groupSafetyHooksProvider.overrideWithValue(hooks),
      groupShareLauncherProvider.overrideWithValue(({
        required text,
        subject,
      }) async {
        shared.add(text);
      }),
      groupClipboardProvider.overrideWithValue(
        (text) async => copied.add(text),
      ),
    ],
  );
  final h = GroupsHarness(container, g, j, s, shared, copied);
  await h.go(tester, location);
  return h;
}
