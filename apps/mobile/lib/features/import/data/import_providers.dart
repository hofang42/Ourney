import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../checkin/photo_compressor.dart';
import '../../journeys/data/journeys_providers.dart';
import '../../profile/share_privacy_sync.dart';
import '../../reminders/data/reminder_scheduler.dart';
import 'import_files.dart';
import 'import_job.dart';
import 'import_job_runner.dart';
import 'import_job_store.dart';

/// The one runner of import jobs (the screen and the launch resume share it,
/// so a job is never run twice at once).
final importJobRunnerProvider = Provider<ImportJobRunner>((ref) {
  final runner = ImportJobRunner(
    store: ref.watch(importJobStoreProvider),
    files: ref.watch(importFilesProvider),
    currentUserId: () => ref.read(currentUserIdProvider),
    compress: (path) => ref.read(photoCompressorProvider).compress(path),
    createJourney: (draft) =>
        ref.read(sharingRepositoryProvider).createImported(draft),
    submit: (draft) async {
      await ref.read(checkInRepositoryProvider).submit(draft);
    },
    discardFiles: (paths) => ref.read(draftFilesProvider).discard(paths),
    now: () => ref.read(journeysClockProvider).now(),
    onJourneyCreated: (journey) async {
      // The Settings share-privacy switches apply to the new membership.
      unawaited(applySharePrivacyToJourney(ref.read, journey.id));
    },
    onFinished: (job) async {
      // A journey that is still going gets its reminders planned.
      if (job.continues) {
        unawaited(ref.read(reminderSchedulerProvider).reschedule());
      }
    },
  );
  ref.onDispose(runner.active.dispose);
  return runner;
});

/// A job that was stored when the screen opened: [importJobProvider] follows
/// it. Null once deleted.
final importJobProvider = StreamProvider.autoDispose.family<ImportJob?, String>(
  (ref, id) => ref.watch(importJobStoreProvider).watch(id),
  retry: (_, _) => null,
);

/// Finishes jobs a kill interrupted. Watched once from the app root; it only
/// runs for a signed-in person with a server (retell needs one).
final importResumeProvider = Provider<void>((ref) {
  if (ref.watch(appConfigProvider).localOnly) return;
  if (ref.watch(currentUserIdProvider) == null) return;
  final ImportJobRunner runner;
  try {
    runner = ref.read(importJobRunnerProvider);
  } on Object {
    // The store is not wired (tests without a data layer).
    return;
  }
  unawaited(
    runner.resumeAll().catchError((Object e) {
      debugPrint('import: resume failed: $e');
    }),
  );
});
