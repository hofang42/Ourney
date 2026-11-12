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

  /// Whether [mine] already has a check-in on the photo's day (FR-C7).
  bool replacesExisting(
    Journey journey,
    CapturedPhoto photo,
    List<CheckIn> mine,
  ) {
    final day = dayOf(journey, photo);
    return mine.any((c) => c.localDate == day);
  }

  /// Throws [CheckInPostException].
  Future<CheckInOutcome> post({
    required Journey journey,
    required Membership? membership,
    required CapturedPhoto photo,
    required List<CheckIn> mine,
    String? caption,
    double? metricValue,
  }) async {
    final CompressedPhoto files;
    try {
      files = await compressor.compress(photo.path);
    } on Object catch (e) {
      throw CheckInPostException(CheckInFailure.photo, e);
    }

    final day = dayOf(journey, photo);
    final today = clock.today(journey.timezone);
    final dates = [for (final c in mine) c.localDate];
    final replaced = dates.contains(day);
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
        ),
      );
    } on OurneyException catch (e) {
      _discard([files.photoFile, files.thumbFile]);
      throw CheckInPostException(
        e.error == OurneyErrorCode.ended
            ? CheckInFailure.ended
            : CheckInFailure.generic,
        e,
      );
    } on Object catch (e) {
      _discard([files.photoFile, files.thumbFile]);
      throw CheckInPostException(CheckInFailure.generic, e);
    }
    // The repository copied the files into the media store.
    _discard([files.photoFile, files.thumbFile, photo.path]);

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
      replaced: replaced,
      milestone: detectMilestone(
        journey: journey,
        before: before,
        after: after,
        replaced: replaced,
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
