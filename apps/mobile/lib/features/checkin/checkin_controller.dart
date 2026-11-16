import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/providers.dart';
import 'captured_photo.dart';
import 'checkin_clock.dart';
import 'checkin_progress.dart';
import 'photo_compressor.dart';

Duration? _noRetry(int _, Object _) => null;

/// The journey being checked in to.
final checkinJourneyProvider = StreamProvider.autoDispose
    .family<Journey?, String>(
      (ref, id) => ref.watch(journeyRepositoryProvider).watch(id),
      retry: _noRetry,
    );

/// The caller's own check-ins for a journey (all of them in local-only mode,
/// where there is no user id and every check-in is the device owner's).
final myCheckInsProvider = StreamProvider.autoDispose
    .family<List<CheckIn>, String>((ref, id) {
      final uid = ref.watch(currentUserIdProvider);
      return ref
          .watch(checkInRepositoryProvider)
          .watchForJourney(id, userId: uid)
          .map(
            (all) => uid == null
                ? all
                : [
                    for (final c in all)
                      if (c.userId == uid) c,
                  ],
          );
    }, retry: _noRetry);

/// The other members' check-ins of [journeyId], newest first (their photos
/// feed the couple "half frame" camera HUD: take `.first` for the latest).
/// The server already filters blocked / reported / hidden rows (RLS); the
/// local-only mode has no partner, so it is empty there. Display a photo with
/// `mediaFileProvider(checkIn.thumbPath)` (or `photoPath`).
final partnerCheckInPhotosProvider = StreamProvider.autoDispose
    .family<List<CheckIn>, String>((ref, id) {
      final uid = ref.watch(currentUserIdProvider);
      if (uid == null) return Stream.value(const <CheckIn>[]);
      return ref
          .watch(checkInRepositoryProvider)
          .watchForJourney(id)
          .map(
            (all) => [
              for (final c in all)
                if (c.userId != uid && c.uploaded) c,
            ]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt)),
          );
    }, retry: _noRetry);

/// A weight (metric value) chosen on the camera screen, waiting to be posted
/// with the next check-in of that journey. The camera slider calls
/// `ref.read(pendingWeightProvider(id).notifier).setPendingWeight(v)`; the
/// post screen prefills its metric field from it and clears it after posting.
class PendingWeight extends Notifier<double?> {
  PendingWeight(this.journeyId);

  final String journeyId;

  @override
  double? build() => null;

  /// [kg] is the metric value (validated like the typed one at post time).
  void setPendingWeight(double kg) => state = kg;

  void clear() => state = null;
}

/// Not auto-disposed: the value must survive the camera -> post navigation.
final pendingWeightProvider =
    NotifierProvider.family<PendingWeight, double?, String>(PendingWeight.new);

/// The caller's membership (join date for streaks, metric privacy).
final myMembershipProvider = StreamProvider.autoDispose
    .family<Membership?, String>(
      (ref, id) => ref.watch(journeyRepositoryProvider).watchMyMembership(id),
      retry: _noRetry,
    );

/// Why posting failed, mapped to a message by the screen.
enum CheckInFailure { photo, ended, generic }

class CheckInPostException implements Exception {
  const CheckInPostException(this.failure, [this.cause]);
  final CheckInFailure failure;
  final Object? cause;

  @override
  String toString() => 'CheckInPostException($failure, $cause)';
}

/// Compresses the photo (FR-C5), saves through [CheckInRepository.submit]
/// (offline-first: the repository stores locally and queues the upload,
/// FR-C6) and computes the streak change and milestone (FR-C8).
class CheckInPoster {
  CheckInPoster({
    required this.repository,
    required this.compressor,
    required this.clock,
    this.drafts,
  });

  final CheckInRepository repository;
  final PhotoCompressor compressor;
  final CheckinClock clock;

  /// Cleans up draft files after a submit; null keeps them (tests).
  final DraftFiles? drafts;

  /// Cleanup never delays the success screen.
  void _discard(List<String> paths) {
    final d = drafts;
    if (d != null) unawaited(d.discard(paths));
  }

  /// Journey-local date the check-in will count for (the server derives
  /// `local_date` from `captured_at` in the journey timezone).
  LocalDate dayOf(Journey journey, CapturedPhoto photo) =>
      clock.localDate(photo.capturedAt, journey.timezone);

  /// Which photo of its day this one will be: 1 for the first check-in of
  /// the day (it counts the day), 2+ for extra same-day photos (FR-C7/C8).
  int photoOfDay(Journey journey, CapturedPhoto photo, List<CheckIn> mine) {
    final day = dayOf(journey, photo);
    return mine.where((c) => c.localDate == day).length + 1;
  }

  /// Throws [CheckInPostException].
  Future<CheckInOutcome> post({
    required Journey journey,
    required Membership? membership,
    required CapturedPhoto photo,
    required List<CheckIn> mine,
    String? caption,
    double? metricValue,
    CheckInExtras extras = CheckInExtras.empty,
    String? partnerPhotoPath,
  }) async {
    final CompressedPhoto files;
    try {
      files = await compressor.compress(photo.path);
    } on Object catch (e) {
      throw CheckInPostException(CheckInFailure.photo, e);
    }
    // Couple journeys: the partner's photo goes through the same pipeline.
    CompressedPhoto? partner;
    if (partnerPhotoPath != null) {
      try {
        partner = await compressor.compress(partnerPhotoPath);
      } on Object catch (e) {
        _discard([files.photoFile, files.thumbFile]);
        throw CheckInPostException(CheckInFailure.photo, e);
      }
    }
    final partnerFiles = [
      if (partner != null) ...[partner.photoFile, partner.thumbFile],
    ];

    final day = dayOf(journey, photo);
    final today = clock.today(journey.timezone);
    final dates = [for (final c in mine) c.localDate];
    final photoOfDay = dates.where((d) => d == day).length + 1;
    final before = memberStreak(
      journey: journey,
      membership: membership,
      today: today,
      dates: dates,
      clock: clock,
    );

    final CheckIn saved;
    try {
      saved = await repository.submit(
        CheckInDraft(
          journeyId: journey.id,
          capturedAt: photo.capturedAt,
          photoFile: files.photoFile,
          thumbFile: files.thumbFile,
          fromLibrary: photo.fromLibrary,
          caption: caption,
          metricValue: metricValue,
          extras: extras,
          partnerPhotoFile: partner?.photoFile,
        ),
      );
    } on OurneyException catch (e) {
      _discard([files.photoFile, files.thumbFile, ...partnerFiles]);
      throw CheckInPostException(
        e.error == OurneyErrorCode.ended
            ? CheckInFailure.ended
            : CheckInFailure.generic,
        e,
      );
    } on Object catch (e) {
      _discard([files.photoFile, files.thumbFile, ...partnerFiles]);
      throw CheckInPostException(CheckInFailure.generic, e);
    }
    // The repository copied the files into the media store.
    _discard([
      files.photoFile,
      files.thumbFile,
      ...partnerFiles,
      photo.path,
      ?partnerPhotoPath,
    ]);

    final after = memberStreak(
      journey: journey,
      membership: membership,
      today: today,
      dates: [...dates, saved.localDate],
      clock: clock,
    );
    return CheckInOutcome(
      checkIn: saved,
      streakBefore: before.current,
      streakAfter: after.current,
      photoOfDay: photoOfDay,
      milestone: detectMilestone(
        journey: journey,
        before: before,
        after: after,
        extraPhoto: photoOfDay > 1,
      ),
    );
  }
}

final checkInPosterProvider = Provider.autoDispose<CheckInPoster>(
  (ref) => CheckInPoster(
    repository: ref.watch(checkInRepositoryProvider),
    compressor: ref.watch(photoCompressorProvider),
    clock: ref.watch(checkinClockProvider),
    drafts: ref.watch(draftFilesProvider),
  ),
);
