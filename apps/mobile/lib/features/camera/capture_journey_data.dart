import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/providers.dart';
import '../checkin/checkin_controller.dart' show partnerCheckInPhotosProvider;
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

  /// Latest partner photo of a couple journey: the local file when the
  /// check-in still has it, else the downloaded copy of the storage path.
  String? get partnerPhoto {
    final partner =
        ref.watch(partnerCheckInPhotosProvider(journey.id)).value ??
        const <CheckIn>[];
    if (partner.isNotEmpty) {
      final f = ref.watch(mediaFileProvider(partner.first.thumbPath)).value;
      if (f != null && f.isNotEmpty) return f;
    }
    for (final c in recent) {
      final local = c.localPartnerPhotoFile;
      if (local != null && local.isNotEmpty) return local;
      final remote = c.partnerPhotoPath;
      if (remote != null && remote.isNotEmpty) {
        return ref.watch(mediaFileProvider(remote)).value;
      }
    }
    return null;
  }
}
