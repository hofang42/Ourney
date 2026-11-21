import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/features/profile/profile_providers.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';

class _Journeys implements JourneyRepository {
  _Journeys(this.active, this.archived, this.membership);
  final List<Journey> active;
  final List<Journey> archived;
  final Membership membership;

  @override
  Future<List<Journey>> allMine() async => [...active, ...archived];
  @override
  Stream<Membership?> watchMyMembership(String journeyId) =>
      Stream.value(membership);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CheckIns implements CheckInRepository {
  _CheckIns(this.all);
  final List<CheckIn> all;

  @override
  Stream<List<CheckIn>> watchForJourney(
    String journeyId, {
    String? userId,
  }) => Stream.value([
    for (final c in all)
      if (c.journeyId == journeyId && (userId == null || c.userId == userId)) c,
  ]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'local stats count only my check-ins, from my join date, archived too',
    () async {
      final start = LocalDate(2026, 1, 1);
      Journey journey(String id, JourneyStatus status) => Journey(
        id: id,
        ownerId: 'o',
        kind: JourneyKind.group,
        templateId: TemplateId.custom,
        title: id,
        emoji: 'x',
        startDate: start,
        timezone: 'UTC',
        visibility: JourneyVisibility.group,
        status: status,
        durationDays: 3650,
      );
      CheckIn c(String j, String user, int day) => CheckIn(
        id: '$j$user$day',
        journeyId: j,
        userId: user,
        localDate: start.addDays(day),
        capturedAt: DateTime.utc(2026, 1, 1 + day),
        photoPath: 'p',
        thumbPath: 't',
      );
      final membership = Membership(
        journeyId: 'j1',
        userId: 'u1',
        role: MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime.utc(2026, 1, 1),
      );
      final checkIns = [
        c('j1', 'u1', 0),
        c('j1', 'u1', 1),
        for (var d = 0; d < 20; d++) c('j1', 'other', d),
        c('j2', 'u1', 0),
      ];
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(userId: 'u1'),
          ),
          journeyRepositoryProvider.overrideWithValue(
            _Journeys(
              [journey('j1', JourneyStatus.active)],
              [journey('j2', JourneyStatus.active)],
              membership,
            ),
          ),
          checkInRepositoryProvider.overrideWithValue(_CheckIns(checkIns)),
        ],
      );
      addTearDown(container.dispose);

      final stats = await container.read(profileStatsProvider.future);
      expect(stats.totalSnaps, 3); // not 23: other members' photos excluded
      expect(stats.journeysTotal, 2); // archived journey included
      expect(stats.longestStreak, 2);
    },
  );
}
