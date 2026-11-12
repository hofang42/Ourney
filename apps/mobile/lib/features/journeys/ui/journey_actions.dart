import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../domain/journey_progress.dart';
import '../domain/journey_time.dart';
import '../journeys_paths.dart';
import '../l10n/generated/journeys_localizations.dart';

/// What the caller may do with a journey (FR-B6, docs/02 9.1).
class JourneyPermissions {
  const JourneyPermissions({
    required this.journey,
    required this.membership,
    required this.currentUserId,
  });

  final Journey journey;
  final Membership? membership;
  final String? currentUserId;

  bool get isOwner {
    final m = membership;
    if (m != null) return m.role == MemberRole.owner;
    // Local-only mode has no user id: every (solo) journey is the caller's.
    return currentUserId == null || journey.ownerId == currentUserId;
  }

  bool get isActive => journey.status == JourneyStatus.active;
  bool get canCheckIn => isActive && (membership?.isActive ?? true);
  bool get canEnd => isOwner && isActive;
  bool get canArchive => journey.status == JourneyStatus.ended;

  /// Owner only. For a group the server also requires the owner to be alone
  /// and answers `not_alone` otherwise (mapped to a message).
  bool get canDelete => isOwner;
}

/// Opens the camera with [journeyId] preselected: makes it the active
/// journey (`camera.lastJourneyId`) and passes `?journeyId=`.
Future<void> checkInNow(
  BuildContext context,
  WidgetRef ref,
  String journeyId,
) async {
  final router = GoRouter.of(context);
  // Through the provider, not prefs: the open camera listens to it.
  await ref.read(activeJourneyIdProvider.notifier).select(journeyId);
  router.go(JourneysPaths.captureFor(journeyId));
}

/// The most recent photo of a journey, if any.
CheckIn? latestCheckIn(JourneyProgress p) {
  CheckIn? latest;
  for (final c in p.checkInsByDate.values) {
    if (latest == null || c.localDate.isAfter(latest.localDate)) latest = c;
  }
  return latest;
}

/// "Day 7 of 14" / "Day 7" for open-ended journeys.
String journeyDayOf(JourneysL10n l10n, JourneyProgress p) => p.totalDays == null
    ? l10n.journeys_dayOpen(p.dayNumber)
    : l10n.journeys_dayOf(p.dayNumber, p.totalDays!);

/// "Day 7/14" compact form (Today card photo).
String journeyDayShort(JourneysL10n l10n, JourneyProgress p) =>
    p.totalDays == null
    ? l10n.journeys_dayOpen(p.dayNumber)
    : l10n.journeys_dayShort(p.dayNumber, p.totalDays!);

/// "Starts today" on day 1, otherwise the time left before the journey's
/// local midnight ("Ends in 3h").
String journeyDeadlineText(JourneysL10n l10n, JourneyProgress p, DateTime now) {
  if (p.journey.startDate == p.today && p.summary.current == 0) {
    return l10n.journeys_startsToday;
  }
  final offset = utcOffsetIn(p.journey.timezone, now);
  final local = now.toUtc().add(offset);
  final minutesLeft = (24 * 60) - (local.hour * 60 + local.minute);
  final hours = minutesLeft ~/ 60;
  return hours < 1 ? l10n.journeys_endsSoon : l10n.journeys_endsInHours(hours);
}

/// Makes [journeyId] the active journey while its screen is open, so the
/// dock and the camera chip follow the journey the user is looking at.
class ActiveJourneyScope extends ConsumerStatefulWidget {
  const ActiveJourneyScope({
    required this.journeyId,
    required this.child,
    super.key,
  });

  final String journeyId;
  final Widget child;

  @override
  ConsumerState<ActiveJourneyScope> createState() => _ActiveJourneyScopeState();
}

class _ActiveJourneyScopeState extends ConsumerState<ActiveJourneyScope> {
  @override
  void initState() {
    super.initState();
    _select();
  }

  @override
  void didUpdateWidget(ActiveJourneyScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.journeyId != widget.journeyId) _select();
  }

  /// Deferred: a provider must not change during a widget lifecycle call.
  void _select() {
    final id = widget.journeyId;
    scheduleMicrotask(() {
      if (!mounted) return;
      unawaited(ref.read(activeJourneyIdProvider.notifier).select(id));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
