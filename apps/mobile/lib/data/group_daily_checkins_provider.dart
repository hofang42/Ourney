import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../app/providers.dart';
import '../features/groups/data/groups_providers.dart';

/// Never retry on a timer so widget tests never leak pending timers.
Duration? _noRetry(int _, Object _) => null;

/// **Task D1**: Group check-in data indexed by day and partner status for
/// `PersonaSkinId.coupleRituals` (D2 `DuoSplitTimeline`, D3 `HalfFrameDuoHud`,
/// D4 `CoupleMosaicPosterShareCard`) and any multi-member persona.
///
/// In local-only mode (`appConfigProvider.localOnly`) or when repositories are
/// not wired in a widget test, streams emit empty values gracefully instead of
/// throwing.
class GroupDailySnapshot {
  const GroupDailySnapshot({
    this.myName,
    this.partnerName,
    this.partnerCheckInsByDate = const {},
    this.partnerCheckIns = const [],
    this.partnerTodayCheckIn,
  });

  static const empty = GroupDailySnapshot();

  final String? myName;
  final String? partnerName;
  final Map<LocalDate, CheckIn> partnerCheckInsByDate;
  final List<CheckIn> partnerCheckIns;
  final CheckIn? partnerTodayCheckIn;

  /// Builds a snapshot for [journey] given all visible [allCheckIns], today's
  /// [members], and the current user's [myUserId].
  factory GroupDailySnapshot.build({
    required Journey journey,
    required List<CheckIn> allCheckIns,
    required List<MemberToday> members,
    String? myUserId,
    Set<String> blockedIds = const {},
  }) {
    if (journey.kind != JourneyKind.group) return empty;

    String? myName;
    MemberToday? partnerMember;
    for (final m in members) {
      if (blockedIds.contains(m.userId)) continue;
      if (myUserId != null && m.userId == myUserId) {
        myName = m.displayName;
      } else {
        partnerMember ??= m;
      }
    }

    final partnerId = partnerMember?.userId;
    final byDate = <LocalDate, CheckIn>{};
    final list = <CheckIn>[];

    if (partnerId != null) {
      for (final c in allCheckIns) {
        if (blockedIds.contains(c.userId)) continue;
        if (c.userId != partnerId) continue;

        final prev = byDate[c.localDate];
        if (prev == null || c.capturedAt.isAfter(prev.capturedAt)) {
          byDate[c.localDate] = c;
        }
      }
    }

    list.addAll(byDate.values);
    list.sort((a, b) => a.localDate.compareTo(b.localDate));

    return GroupDailySnapshot(
      myName: myName,
      partnerName: partnerMember?.displayName,
      partnerCheckInsByDate: byDate,
      partnerCheckIns: list,
      partnerTodayCheckIn: partnerMember?.todayCheckIn,
    );
  }
}

/// Safe stream of all check-ins in a group journey (empty in local-only mode).
final groupAllCheckInsSafeProvider = StreamProvider.autoDispose
    .family<List<CheckIn>, String>((ref, journeyId) {
      if (ref.watch(appConfigProvider).localOnly) {
        return Stream.value(const <CheckIn>[]);
      }
      final CheckInRepository repo;
      try {
        repo = ref.watch(checkInRepositoryProvider);
      } on Object {
        return Stream.value(const <CheckIn>[]);
      }
      return repo
          .watchForJourney(journeyId)
          .handleError((Object _) => const <CheckIn>[]);
    }, retry: _noRetry);

/// Safe stream of `group_today` rows (empty in local-only mode or if unwired).
final groupMembersTodaySafeProvider = StreamProvider.autoDispose
    .family<List<MemberToday>, String>((ref, journeyId) {
      if (ref.watch(appConfigProvider).localOnly) {
        return Stream.value(const <MemberToday>[]);
      }
      final GroupRepository repo;
      try {
        repo = ref.watch(groupRepositoryProvider);
      } on Object {
        return Stream.value(const <MemberToday>[]);
      }
      return repo
          .watchToday(journeyId)
          .handleError((Object _) => const <MemberToday>[]);
    }, retry: _noRetry);

/// Computes [GroupDailySnapshot] for [journey].
final groupDailySnapshotProvider = Provider.autoDispose
    .family<GroupDailySnapshot, Journey>((ref, journey) {
      if (journey.kind != JourneyKind.group ||
          ref.watch(appConfigProvider).localOnly) {
        return GroupDailySnapshot.empty;
      }
      final allCheckIns =
          ref.watch(groupAllCheckInsSafeProvider(journey.id)).value ??
          const <CheckIn>[];
      final members =
          ref.watch(groupMembersTodaySafeProvider(journey.id)).value ??
          const <MemberToday>[];
      final blockedIds =
          ref.watch(groupBlockedIdsProvider).value ?? const <String>{};
      final myUserId = ref.watch(currentUserIdProvider);
      return GroupDailySnapshot.build(
        journey: journey,
        allCheckIns: allCheckIns,
        members: members,
        myUserId: myUserId,
        blockedIds: blockedIds,
      );
    });
