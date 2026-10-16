import 'package:ourney_core/ourney_core.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Journey-local calendar date of [instant] in the IANA zone [timezone]
/// (same rule as the server's `local_date`). Unknown zones fall back to the
/// device offset so a bad server value never crashes the UI.
LocalDate groupLocalDate(String timezone, DateTime instant) {
  if (!tz.timeZoneDatabase.isInitialized) tzdata.initializeTimeZones();
  Duration offset;
  try {
    offset = tz.TZDateTime.from(
      instant,
      tz.getLocation(timezone),
    ).timeZoneOffset;
  } on tz.LocationNotFoundException {
    offset = instant.toLocal().timeZoneOffset;
  }
  return localDateOf(instant, offset);
}

/// One member row of the group "Today" screen (FR-D3).
class GroupMemberEntry {
  const GroupMemberEntry({
    required this.member,
    required this.isMe,
    required this.checkedInToday,
    required this.streak,
    this.photo,
    this.photoIsToday = false,
  });

  final MemberToday member;
  final bool isMe;
  final bool checkedInToday;

  /// Current streak counted from the member's join date (late-join aware).
  final int streak;

  /// Today's check-in, or the member's latest one when not checked in yet.
  final CheckIn? photo;

  /// True when [photo] is today's check-in (false for an older photo shown
  /// because today's was hidden or not taken yet).
  final bool photoIsToday;
}

/// Everything the "Today" screen shows. Consistency only (FR-D5): members
/// keep the server's join order inside the "done" / "not yet" sections and
/// metric values are never used.
class GroupTodayView {
  GroupTodayView._({
    required this.today,
    required this.dayNumber,
    required this.totalDays,
    required this.done,
    required this.pending,
  });

  /// Builds the view from `group_today` rows.
  ///
  /// * [blockedIds]: members (and their content) hidden on this device
  ///   (FR-F2; the server already filters, this covers the moment after a
  ///   block and an offline cache).
  /// * [hiddenCheckInIds]: check-ins reported from this device (FR-F2); the
  ///   member still counts as done today but the photo is not shown.
  /// * [checkIns]: check-ins of the journey the caller can see, used for
  ///   "latest photo" and, for the caller only, a local streak via
  ///   [computeMemberStreak] (includes a check-in not uploaded yet).
  /// * [myMembership]: the caller's membership (join date for the streak).
  factory GroupTodayView.build({
    required Journey journey,
    required List<MemberToday> members,
    required DateTime now,
    String? myUserId,
    Set<String> blockedIds = const {},
    Set<String> hiddenCheckInIds = const {},
    Iterable<CheckIn> checkIns = const [],
    Membership? myMembership,
  }) {
    final today = groupLocalDate(journey.timezone, now);
    final latest = <String, CheckIn>{};
    final myDates = <LocalDate>{};
    for (final c in checkIns) {
      if (blockedIds.contains(c.userId) || c.localDate.isAfter(today)) {
        continue;
      }
      if (c.userId == myUserId) myDates.add(c.localDate);
      if (hiddenCheckInIds.contains(c.id)) continue;
      final prev = latest[c.userId];
      if (prev == null ||
          c.localDate.isAfter(prev.localDate) ||
          (c.localDate == prev.localDate &&
              c.capturedAt.isAfter(prev.capturedAt))) {
        latest[c.userId] = c;
      }
    }

    final done = <GroupMemberEntry>[];
    final pending = <GroupMemberEntry>[];
    for (final m in members) {
      if (blockedIds.contains(m.userId)) continue;
      final isMe = m.userId == myUserId;
      final latestOwn = latest[m.userId];
      final localToday = latestOwn != null && latestOwn.localDate == today
          ? latestOwn
          : null;
      final serverToday = m.todayCheckIn;
      final checkedInToday = serverToday != null || localToday != null;
      final todayCheckIn =
          (serverToday != null && !hiddenCheckInIds.contains(serverToday.id)
              ? serverToday
              : null) ??
          localToday;
      var streak = m.currentStreak;
      if (isMe && myMembership != null && myDates.isNotEmpty) {
        streak = computeMemberStreak(
          journeyStart: journey.startDate,
          durationDays: journey.durationDays,
          joinedLocalDate: groupLocalDate(
            journey.timezone,
            myMembership.joinedAt,
          ),
          today: today,
          dates: myDates,
        ).current;
      }
      final entry = GroupMemberEntry(
        member: m,
        isMe: isMe,
        checkedInToday: checkedInToday,
        streak: streak,
        photo: todayCheckIn ?? latestOwn,
        photoIsToday: todayCheckIn != null,
      );
      (entry.checkedInToday ? done : pending).add(entry);
    }

    var day = journey.startDate.daysUntil(today) + 1;
    if (day < 1) day = 1;
    final total = journey.durationDays;
    if (total != null && day > total) day = total;

    return GroupTodayView._(
      today: today,
      dayNumber: day,
      totalDays: total,
      done: done,
      pending: pending,
    );
  }

  final LocalDate today;
  final int dayNumber;
  final int? totalDays;
  final List<GroupMemberEntry> done;
  final List<GroupMemberEntry> pending;

  int get memberCount => done.length + pending.length;
  int get doneCount => done.length;

  /// True when the caller is the only visible active member (delete allowed,
  /// FR-D7; the server still answers `not_alone` otherwise).
  bool get isAlone => memberCount <= 1;
}

/// Counts per emoji for a check-in (FR-D4), in [reactionEmojis] order,
/// without blocked users, plus the caller's own reaction.
class ReactionSummary {
  ReactionSummary._(this.counts, this.mine);

  factory ReactionSummary.of(
    Iterable<Reaction> reactions, {
    String? myUserId,
    Set<String> blockedIds = const {},
  }) {
    final counts = {for (final e in reactionEmojis) e: 0};
    String? mine;
    for (final r in reactions) {
      if (blockedIds.contains(r.userId) || !counts.containsKey(r.emoji)) {
        continue;
      }
      counts[r.emoji] = counts[r.emoji]! + 1;
      if (r.userId == myUserId) mine = r.emoji;
    }
    return ReactionSummary._(counts, mine);
  }

  final Map<String, int> counts;
  final String? mine;

  int get total => counts.values.fold(0, (a, b) => a + b);
}
