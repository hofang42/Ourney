import 'package:flutter/widgets.dart';
import 'package:ourney_core/ourney_core.dart';

import '../features/groups/domain/group_today.dart';
import '../features/journeys/domain/journey_progress.dart';

/// Input contracts of the persona widgets (task F1).
///
/// Every persona implements three screens from these objects, plus the squad
/// wall for the group tab. The screens in `lib/features/` build the object and
/// hand it to a switcher (`persona_switchers.dart`); the persona widget never
/// reads a repository itself, so it can be tested with plain fake data.
///
/// Only show what the model has: `Journey.metricName`, `Journey.metricUnit`,
/// `CheckIn.metricValue`, streak, day N and today's group members. Anything
/// else on a mockup (temperature, place, pace) is left out, never invented.

/// The persona skin that styles [journey] (`CLAUDE.md` §4).
PersonaSkinId personaSkinOf(Journey journey) => personaSkinForTemplate(
  journey.templateId,
  kind: journey.kind,
  maxMembers: journey.maxMembers,
  emoji: journey.emoji,
);

/// Builds the photo of a day, for tests that must not touch the disk.
typedef PersonaDayPhotoBuilder = Widget Function(
  BuildContext context,
  TimelineDay day,
);

/// Builds the photo of a check-in, for tests that must not touch the disk.
typedef PersonaCheckInPhotoBuilder = Widget Function(
  BuildContext context,
  CheckIn checkIn,
);

/// Input of the timeline (journey detail).
@immutable
class PersonaTimelineData {
  const PersonaTimelineData({
    required this.journey,
    required this.days,
    this.currentStreak = 0,
    this.hideMetric = false,
    this.myName,
    this.partnerName,
    this.partnerCheckInsByDate = const {},
    this.onTapDay,
    this.photoBuilder,
    this.partnerPhotoBuilder,
    this.shrinkWrap = false,
    this.physics,
  });

  /// Builds the data from [progress]: the days, today's streak, and the
  /// caller's "hide my metric" flag (FR-B7).
  factory PersonaTimelineData.fromProgress(
    JourneyProgress progress, {
    bool hideMetric = false,
    String? myName,
    String? partnerName,
    Map<LocalDate, CheckIn> partnerCheckInsByDate = const {},
    ValueChanged<TimelineDay>? onTapDay,
    PersonaDayPhotoBuilder? photoBuilder,
    PersonaCheckInPhotoBuilder? partnerPhotoBuilder,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) => PersonaTimelineData(
    journey: progress.journey,
    days: progress.timeline(),
    currentStreak: progress.summary.current,
    hideMetric: hideMetric,
    myName: myName,
    partnerName: partnerName,
    partnerCheckInsByDate: partnerCheckInsByDate,
    onTapDay: onTapDay,
    photoBuilder: photoBuilder,
    partnerPhotoBuilder: partnerPhotoBuilder,
    shrinkWrap: shrinkWrap,
    physics: physics,
  );

  final Journey journey;

  /// One cell per day from the journey start (see [JourneyProgress.timeline]).
  final List<TimelineDay> days;
  final int currentStreak;

  /// The caller hides their metric: draw no number and no curve (FR-B7).
  final bool hideMetric;

  /// Optional display name for the current user (used by `coupleRituals` D2).
  final String? myName;

  /// Optional display name for the partner in a 2-member journey (D2).
  final String? partnerName;

  /// Partner's check-ins indexed by journey-local date (D1/D2).
  final Map<LocalDate, CheckIn> partnerCheckInsByDate;

  final ValueChanged<TimelineDay>? onTapDay;
  final PersonaDayPhotoBuilder? photoBuilder;
  final PersonaCheckInPhotoBuilder? partnerPhotoBuilder;

  /// True when the timeline sits inside another scrollable.
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// 1-based day N of today, or the last day when the journey is over.
  int get dayNumber {
    for (final d in days) {
      if (d.isToday) return d.dayNumber;
    }
    return days.isEmpty ? 1 : days.last.dayNumber;
  }

  /// Days with a check-in.
  int get checkInCount => days.where((d) => d.checkIn != null).length;
}

/// Input of the share board (share-card screen).
@immutable
class PersonaShareData {
  const PersonaShareData({
    required this.journey,
    required this.checkIns,
    this.partnerCheckIns = const [],
    this.currentStreak = 0,
    this.dayNumber = 1,
    this.hideMetric = false,
    this.onShare,
    this.publicLinkSection,
    this.photoBuilder,
    this.shrinkWrap = false,
    this.physics,
  });

  final Journey journey;

  /// The caller's check-ins, any order.
  final List<CheckIn> checkIns;

  /// Optional partner check-ins for couple mosaic posters (D4).
  final List<CheckIn> partnerCheckIns;
  final int currentStreak;
  final int dayNumber;

  /// Hide the metric on the card; the default for outside shares (FR-B7).
  final bool hideMetric;

  /// Runs the app's image export and the system share sheet.
  final VoidCallback? onShare;

  /// Public-link controls. Group journeys never get one (FR-E3).
  final Widget? publicLinkSection;
  final PersonaCheckInPhotoBuilder? photoBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// Check-ins in date order.
  List<CheckIn> get sortedCheckIns =>
      [...checkIns]..sort((a, b) => a.localDate.compareTo(b.localDate));
}

/// Input of the squad wall (group "Today" screen).
@immutable
class PersonaGroupData {
  const PersonaGroupData({
    required this.journey,
    required this.members,
    this.onNudge,
    this.reactionsEnabled = true,
    this.photoBuilder,
    this.shrinkWrap = false,
    this.physics,
  });

  final Journey journey;

  /// Everyone in the group, checked in or not, in the server's join order.
  final List<GroupMemberEntry> members;
  final ValueChanged<GroupMemberEntry>? onNudge;
  final bool reactionsEnabled;
  final Widget Function(BuildContext context, GroupMemberEntry entry)?
  photoBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  int get doneCount => members.where((m) => m.checkedInToday).length;
}
