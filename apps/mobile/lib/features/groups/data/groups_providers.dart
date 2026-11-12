import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';

/// Repository streams must not retry on their own: the repositories already
/// handle offline/sync, and retry timers would leak into widget tests.
Duration? _noRetry(int _, Object _) => null;

/// Group journeys of the caller (Groups tab), from
/// `JourneyRepository.watchActive` filtered to `kind == group`.
final groupJourneysProvider = StreamProvider.autoDispose<List<Journey>>(
  (ref) => ref
      .watch(journeyRepositoryProvider)
      .watchActive()
      .map(
        (list) => [
          for (final j in list)
            if (j.kind == JourneyKind.group) j,
        ],
      ),
  retry: _noRetry,
);

/// `group_today` rows (FR-D3).
final groupTodayProvider = StreamProvider.autoDispose
    .family<List<MemberToday>, String>(
      (ref, id) => ref.watch(groupRepositoryProvider).watchToday(id),
      retry: _noRetry,
    );

/// Every check-in of the journey the caller can see (latest photo per member
/// and the caller's local streak). Optional: the screen works without it.
final groupCheckInsProvider = StreamProvider.autoDispose
    .family<List<CheckIn>, String>(
      (ref, id) => ref.watch(checkInRepositoryProvider).watchForJourney(id),
      retry: _noRetry,
    );

/// Live reactions on one check-in (FR-D4).
final groupReactionsProvider = StreamProvider.autoDispose
    .family<List<Reaction>, String>(
      (ref, checkInId) =>
          ref.watch(groupRepositoryProvider).watchReactions(checkInId),
      retry: _noRetry,
    );

/// Users the caller blocked (FR-F2). Empty while the safety repository is
/// not wired or failing: the server already hides blocked users' content.
final groupBlockedIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final SafetyRepository repo;
  try {
    repo = ref.watch(safetyRepositoryProvider);
  } on Object {
    return Stream.value(const <String>{});
  }
  return repo.watchBlockedIds().handleError((Object _) {});
}, retry: _noRetry);

/// Opens the system share sheet with [text]. Override in tests.
typedef GroupShareLauncher = Future<void> Function({
  required String text,
  String? subject,
});

final groupShareLauncherProvider = Provider<GroupShareLauncher>(
  (ref) => ({required text, subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  },
);

/// Copies [text] to the clipboard. Override in tests.
final groupClipboardProvider = Provider<Future<void> Function(String text)>(
  (ref) =>
      (text) => Clipboard.setData(ClipboardData(text: text)),
);
