import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../app/journey_clock.dart';
import '../app/providers.dart';
import '../features/groups/data/groups_providers.dart';
import '../features/journeys/domain/journey_time.dart';

Duration? _noRetry(int _, Object _) => null;

bool isCoupleGroup(Journey journey) =>
    journey.kind == JourneyKind.group && journey.maxMembers == 2;

/// Oldest first, with the same tie-break as the check-in and group-day queries.
int compareCheckIns(CheckIn a, CheckIn b) {
  final time = a.capturedAt.compareTo(b.capturedAt);
  return time == 0 ? a.id.compareTo(b.id) : time;
}

/// The group roster arrives in join order (then account ID). Orient the pair
/// once for both viewers, including an empty slot while the group has one
/// member. The owner's saved side preference applies to that join order.
List<String?> coupleMemberIds({
  required Journey journey,
  required String? myUserId,
  required List<MemberToday> members,
}) {
  final ids = <String>{for (final member in members) member.userId};
  final ordered = switch (ids.length) {
    2 => ids.toList(),
    1 when ids.first != journey.ownerId => <String?>[null, ids.first],
    1 => <String?>[ids.first, null],
    _ when myUserId != null && myUserId != journey.ownerId => <String?>[
      null,
      myUserId,
    ],
    _ => <String?>[myUserId, null],
  };
  return List.unmodifiable(
    journey.dna?['side'] == 'right' ? ordered.reversed : ordered,
  );
}

class CouplePhotoSlot {
  const CouplePhotoSlot({
    this.userId,
    this.displayName,
    this.checkIn,
    this.isMine = false,
    this.photoUnavailable = false,
  });

  final String? userId;
  final String? displayName;
  final CheckIn? checkIn;
  final bool isMine;
  final bool photoUnavailable;
}

class GroupDailySnapshot {
  const GroupDailySnapshot._({
    this.memberIds = const [],
    this.myUserId,
    this.partnerId,
    this.hasLoadedMembers = false,
    this.canInvitePartner = false,
    this.today,
    this.partnerPostedToday = false,
    this.memberNames = const {},
    this.byDate = const {},
    this.latestPartnerCheckIn,
    this.photosByDate = const {},
  });

  static const empty = GroupDailySnapshot._();

  factory GroupDailySnapshot.build({
    required Journey journey,
    required List<CheckIn> allCheckIns,
    required List<MemberToday> members,
    required String? myUserId,
    LocalDate? today,
    bool hasLoadedMembers = true,
    Set<String> blockedIds = const {},
  }) {
    if (!isCoupleGroup(journey)) return empty;
    final visible = [
      for (final member in members)
        if (!blockedIds.contains(member.userId)) member,
    ];
    final memberIds = coupleMemberIds(
      journey: journey,
      myUserId: myUserId,
      members: visible,
    );
    final partner =
        myUserId != null && visible.any((member) => member.userId == myUserId)
        ? visible.where((member) => member.userId != myUserId).singleOrNull
        : null;

    final byDate = <LocalDate, Map<String, CheckIn>>{};
    final photosByDate = <LocalDate, List<CheckIn>>{};
    CheckIn? latestPartner;
    for (final photo in allCheckIns) {
      if (photo.journeyId != journey.id) continue;
      final isMine = myUserId != null && photo.userId == myUserId;
      if (!isMine) {
        if (partner == null ||
            photo.userId != partner.userId ||
            !photo.uploaded) {
          continue;
        }
        // The current group-day result covers reports/moderation even while
        // the historical cache is still reconciling.
        if (photo.localDate == today && photo.id != partner.todayCheckIn?.id) {
          // Older eligible posts stay in the gallery. If the RPC withheld the
          // entire day, withhold all cached photos of that day too.
          if (partner.todayCheckIn == null ||
              compareCheckIns(photo, partner.todayCheckIn!) >= 0) {
            continue;
          }
          (photosByDate[photo.localDate] ??= []).add(photo);
          continue;
        }
        if (latestPartner == null ||
            compareCheckIns(photo, latestPartner) > 0) {
          latestPartner = photo;
        }
      }
      (photosByDate[photo.localDate] ??= []).add(photo);
      final selected = byDate[photo.localDate] ??= {};
      final previous = selected[photo.userId];
      if (previous == null || compareCheckIns(photo, previous) > 0) {
        selected[photo.userId] = photo;
      }
    }

    final orderedNames = [journey.coupleSelfName, journey.couplePartnerName];
    final memberNames = <String, String>{
      for (final member in visible) member.userId: member.displayName,
    };
    for (var index = 0; index < memberIds.length; index++) {
      final id = memberIds[index];
      final name =
          orderedNames[journey.dna?['side'] == 'right' ? 1 - index : index]
              ?.trim();
      if (id != null && name != null && name.isNotEmpty) memberNames[id] = name;
    }

    return GroupDailySnapshot._(
      memberIds: memberIds,
      myUserId: myUserId,
      partnerId: partner?.userId,
      hasLoadedMembers: hasLoadedMembers,
      canInvitePartner:
          hasLoadedMembers &&
          members.length == 1 &&
          members.single.userId == myUserId &&
          blockedIds.isEmpty,
      today: today,
      partnerPostedToday: partner?.checkedIn ?? false,
      memberNames: memberNames,
      byDate: byDate,
      latestPartnerCheckIn: latestPartner,
      photosByDate: photosByDate,
    );
  }

  final List<String?> memberIds;
  final String? myUserId;
  final String? partnerId;
  final bool hasLoadedMembers;
  final bool canInvitePartner;
  final LocalDate? today;
  final bool partnerPostedToday;
  final Map<String, String> memberNames;
  final Map<LocalDate, Map<String, CheckIn>> byDate;
  final Map<LocalDate, List<CheckIn>> photosByDate;
  final CheckIn? latestPartnerCheckIn;

  bool partnerPostedOn(LocalDate date) =>
      (date == today && partnerPostedToday) || byDate[date]?[partnerId] != null;

  List<CouplePhotoSlot> slotsOn(LocalDate date, {CheckIn? ownPhoto}) {
    final entries = byDate[date] ?? const <String, CheckIn>{};
    var mine = entries[myUserId];
    if (ownPhoto != null &&
        ownPhoto.userId == myUserId &&
        ownPhoto.localDate == date &&
        (mine == null || compareCheckIns(ownPhoto, mine) > 0)) {
      mine = ownPhoto;
    }
    return [
      for (final id in memberIds)
        CouplePhotoSlot(
          userId: id,
          displayName: memberNames[id],
          checkIn: id != null && id == myUserId ? mine : entries[id],
          isMine: id != null && id == myUserId,
          photoUnavailable:
              id != null &&
              id == partnerId &&
              date == today &&
              partnerPostedToday &&
              entries[id] == null,
        ),
    ];
  }

  List<CheckIn> photosOn(LocalDate date) => photosByDate[date] ?? const [];

  /// Most recent journey day with a visible authored contribution.
  LocalDate? get latestDate {
    LocalDate? latest;
    for (final date in byDate.keys) {
      if (latest == null || date.isAfter(latest)) latest = date;
    }
    return latest;
  }
}

/// RLS-filtered local history, reconciled when the roster stream opens.
final groupAllCheckInsSafeProvider = StreamProvider.autoDispose
    .family<List<CheckIn>, String>((ref, journeyId) {
      if (ref.watch(appConfigProvider).localOnly) return Stream.value(const []);
      ref.watch(currentUserIdProvider);
      final CheckInRepository repo;
      try {
        repo = ref.watch(checkInRepositoryProvider);
      } on Object {
        return Stream.value(const []);
      }
      return repo.watchForJourney(journeyId);
    }, retry: _noRetry);

/// The latest group-day roster and privacy-filtered photo IDs from the server.
final groupMembersTodaySafeProvider = StreamProvider.autoDispose
    .family<List<MemberToday>, String>((ref, journeyId) {
      if (ref.watch(appConfigProvider).localOnly) return Stream.value(const []);
      ref.watch(currentUserIdProvider);
      final GroupRepository repo;
      try {
        repo = ref.watch(groupRepositoryProvider);
      } on Object {
        return Stream.value(const []);
      }
      return repo.watchToday(journeyId);
    }, retry: _noRetry);

final groupDailySnapshotProvider = Provider.autoDispose
    .family<GroupDailySnapshot, Journey>((ref, journey) {
      if (!isCoupleGroup(journey) || ref.watch(appConfigProvider).localOnly) {
        return GroupDailySnapshot.empty;
      }
      final members = ref
          .watch(groupMembersTodaySafeProvider(journey.id))
          .asData;
      // Sample a fresh instant when either the roster or history refreshes.
      // The app day ticker also invalidates the snapshot at midnight.
      ref.watch(journeysNowProvider);
      return GroupDailySnapshot.build(
        journey: journey,
        allCheckIns:
            ref.watch(groupAllCheckInsSafeProvider(journey.id)).asData?.value ??
            const [],
        members: members?.value ?? const [],
        hasLoadedMembers: members != null,
        myUserId: ref.watch(currentUserIdProvider),
        blockedIds: ref.watch(groupBlockedIdsProvider).value ?? const {},
        today: journeyLocalDate(journey.timezone, ref.watch(journeysClockProvider).now()),
      );
    });
