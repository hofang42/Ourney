import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/providers.dart';
import '../../data/group_daily_checkins_provider.dart';
import '../journeys/data/journeys_providers.dart';
import '../journeys/domain/journey_progress.dart';

/// What the camera needs to know about one journey, read from the caller's
/// own check-ins (moved out of capture_screen.dart). Watch-based: call from
/// a build method.
class CaptureJourneyData {
  CaptureJourneyData(this.ref, this.journey);

  final WidgetRef ref;
  final Journey journey;

  /// The caller's check-ins, newest first.
  late final List<CheckIn> recent = [
    ...ref.watch(myCheckInsProvider(journey.id)).value ?? const <CheckIn>[],
  ]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

  /// Day number and streak (day 1 / streak 0 until check-ins load).
  late final JourneyProgress progress = JourneyProgress.compute(
    journey: journey,
    membership: ref.watch(myMembershipProvider(journey.id)).value,
    checkIns: recent,
    now: clock.now().toUtc(),
  );

  /// Today's photos of this journey (journey-local day), newest first.
  /// Several per day are allowed (FR-C7).
  List<CheckIn> get today => [
    for (final c in recent)
      if (c.localDate == progress.today) c,
  ];

  /// Thumbnail of the other active member's latest visible check-in.
  String? get partnerPhoto {
    final photo = ref
        .watch(groupDailySnapshotProvider(journey))
        .latestPartnerCheckIn;
    return photo == null
        ? null
        : ref.watch(mediaFileProvider(photo.thumbPath)).value;
  }
}
