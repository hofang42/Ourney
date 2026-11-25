import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../data/data_providers.dart' show dataLayerProvider;
import 'group_invite_admin_repository.dart';
import 'group_invite_repository.dart';

/// Repository streams must not retry on their own: the repositories already
/// handle offline/sync, and retry timers would leak into widget tests.
Duration? _noRetry(int _, Object _) => null;

/// Group journeys of the caller (Groups tab), from
/// `JourneyRepository.watchActive` filtered to `kind == group`.
final groupJourneysProvider = StreamProvider.autoDispose<List<Journey>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref
      .watch(journeyRepositoryProvider)
      .watchActive()
      .map(
        (list) => [
          for (final j in list)
            if (j.kind == JourneyKind.group) j,
        ],
      );
}, retry: _noRetry);

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

/// Join-code preview and group invitations (migration 0008). Built on the
/// data layer; falls back to an always-offline repository when the data layer
/// is not wired (tests, local-only), so screens degrade instead of crashing.
/// Override in tests.
final groupInviteRepositoryProvider = Provider<GroupInviteRepository>((ref) {
  try {
    final ctx = ref.watch(dataLayerProvider).ctx;
    return ctx.remote == null
        ? const UnavailableGroupInviteRepository()
        : DataGroupInviteRepository(ctx);
  } on Object {
    return const UnavailableGroupInviteRepository();
  }
});

/// Preview of an invite code (null while the code is not 8 characters yet).
/// Errors are [GroupException]s; the join screen treats `offline` and
/// unknown failures as "no preview" and keeps the plain join flow.
final groupPreviewProvider = FutureProvider.autoDispose
    .family<GroupPreview, String>(
      (ref, code) =>
          ref.watch(groupInviteRepositoryProvider).previewByCode(code),
      retry: _noRetry,
    );

/// Pending invitations of the caller (Activity feed).
final groupInvitationsProvider =
    FutureProvider.autoDispose<List<GroupInvitation>>(
      (ref) => ref.watch(groupInviteRepositoryProvider).pending(),
      retry: _noRetry,
    );

/// Inviter-side management (list / revoke pending, rename couple; 0010).
/// Falls back to an always-offline repository when the data layer is absent.
final groupInviteAdminRepositoryProvider = Provider<GroupInviteAdminRepository>(
  (ref) {
    try {
      return DataGroupInviteAdminRepository(ref.watch(dataLayerProvider).ctx);
    } on Object {
      return const UnavailableGroupInviteAdminRepository();
    }
  },
);

/// Pending invitations of one group.
final sentGroupInvitationsProvider = FutureProvider.autoDispose
    .family<List<SentGroupInvitation>, String>(
      (ref, journeyId) =>
          ref.watch(groupInviteAdminRepositoryProvider).sent(journeyId),
      retry: _noRetry,
    );
