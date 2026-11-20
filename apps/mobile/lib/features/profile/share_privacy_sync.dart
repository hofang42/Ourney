import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../share_card/domain/share_card_content.dart';
import 'settings_providers.dart';

Future<void>? _pendingPush;

/// Failed membership pushes waiting to be healed, kept in prefs so they
/// survive a restart. Account scoped: [SharePrivacyPrefs.pendingHeal] is in
/// `accountPrefsKeys` and also carries the user it belongs to.
/// Shape: `{"user": id, "items": {journeyId: {"h": bool, "b": bool}}}`, where
/// only the flag(s) that failed are set, so healing never touches another
/// per-journey choice.
Map<String, ({bool hide, bool blur})> _loadPending(
  SharedPreferencesWithCache prefs,
  String? userId,
) {
  if (userId == null) return {};
  try {
    final raw = prefs.getString(SharePrivacyPrefs.pendingHeal);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['user'] != userId) return {};
    final items = (map['items'] as Map<String, dynamic>?) ?? const {};
    return {
      for (final e in items.entries)
        e.key: (
          hide: (e.value as Map)['h'] == true,
          blur: (e.value as Map)['b'] == true,
        ),
    };
  } on Object {
    return {};
  }
}

void _savePending(
  SharedPreferencesWithCache prefs,
  String userId,
  Map<String, ({bool hide, bool blur})> items,
) {
  try {
    if (items.isEmpty) {
      unawaited(prefs.remove(SharePrivacyPrefs.pendingHeal));
      return;
    }
    unawaited(
      prefs.setString(
        SharePrivacyPrefs.pendingHeal,
        jsonEncode({
          'user': userId,
          'items': {
            for (final e in items.entries)
              e.key: {'h': e.value.hide, 'b': e.value.blur},
          },
        }),
      ),
    );
  } on Object {
    // Storage failure: the push is not retried; the next switch change does.
  }
}

/// Records that [journeyId] still needs the given flag(s). Signed out: only
/// logged (there is no account to heal for).
void _noteFailure(
  SharedPreferencesWithCache prefs,
  String? userId,
  String journeyId,
  Object e, {
  required bool hide,
  required bool blur,
}) {
  debugPrint('share privacy: journey $journeyId failed: $e');
  if (userId == null) return;
  final items = _loadPending(prefs, userId);
  final old = items[journeyId];
  items[journeyId] = (
    hide: hide || (old?.hide ?? false),
    blur: blur || (old?.blur ?? false),
  );
  _savePending(prefs, userId, items);
}

/// Journeys with a failed push waiting for [healSharePrivacy].
@visibleForTesting
Map<String, ({bool hide, bool blur})> pendingSharePrivacy(
  ProviderContainer container,
) => _loadPending(
  container.read(sharedPreferencesProvider),
  container.read(currentUserIdProvider),
);

bool _healing = false;

/// Re-applies ONLY the failed flag(s) of the journeys recorded by a failed
/// push, and only while the matching Settings switch is still ON. A
/// membership that no longer exists is forgotten. Never touches any other
/// journey, so per-journey choices stay. Called at app resume.
Future<void> healSharePrivacy(ProviderContainer container) async {
  if (_healing) return;
  final SharedPreferencesWithCache prefs;
  final JourneyRepository repo;
  final String? userId;
  try {
    prefs = container.read(sharedPreferencesProvider);
    repo = container.read(journeyRepositoryProvider);
    userId = container.read(currentUserIdProvider);
  } on Object {
    return;
  }
  final pending = _loadPending(prefs, userId);
  if (userId == null || pending.isEmpty) return;
  _healing = true;
  try {
    for (final entry in pending.entries) {
      final hide =
          entry.value.hide && container.read(hideWeightOnShareProvider);
      final blur =
          entry.value.blur && container.read(blurPhotosOnShareProvider);
      var done = true;
      if (hide || blur) {
        try {
          await repo.updateMyMembership(
            entry.key,
            hideMetric: hide ? true : null,
            blurMedia: blur ? true : null,
          );
        } on OurneyException catch (e) {
          done = e.error == OurneyErrorCode.notFound;
          debugPrint('share privacy: heal ${entry.key} failed: $e');
        } on Object catch (e) {
          done = false;
          debugPrint('share privacy: heal ${entry.key} failed: $e');
        }
      }
      if (done && container.read(currentUserIdProvider) == userId) {
        final cur = _loadPending(prefs, userId)..remove(entry.key);
        _savePending(prefs, userId, cur);
      }
    }
  } finally {
    _healing = false;
  }
}

/// Heals failed share-privacy pushes when the app resumes.
class SharePrivacyHealHook extends ConsumerStatefulWidget {
  const SharePrivacyHealHook({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SharePrivacyHealHook> createState() =>
      _SharePrivacyHealHookState();
}

class _SharePrivacyHealHookState extends ConsumerState<SharePrivacyHealHook>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(healSharePrivacy(ProviderScope.containerOf(context)));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Pushes a Settings share-privacy switch that was just turned ON to every
/// journey membership (archived and ended ones included) so the public link
/// and group walls honour it too, not only the share card (C-B1). Turning a
/// switch OFF never touches memberships: explicit per-journey choices stay.
/// [hideWeight] only reaches weight (kg) journeys. Pushes are serialised and
/// re-read the switch from [container] before writing, so rapid toggles (or
/// leaving Settings) cannot leave a stale value behind. A membership that can
/// not be updated is recorded (with just the failed flag) and healed later.
Future<void> pushSharePrivacyToMemberships(
  ProviderContainer container, {
  bool? hideWeight,
  bool? blur,
}) {
  if (hideWeight != true && blur != true) {
    return _pendingPush ?? Future<void>.value();
  }
  final JourneyRepository repo;
  final SharedPreferencesWithCache prefs;
  final String? userId;
  try {
    repo = container.read(journeyRepositoryProvider);
    prefs = container.read(sharedPreferencesProvider);
    userId = container.read(currentUserIdProvider);
  } on Object {
    return Future<void>.value();
  }

  Future<void> run() async {
    try {
      final journeys = await repo.allMine();
      final hideNow =
          hideWeight == true && container.read(hideWeightOnShareProvider);
      final blurNow = blur == true && container.read(blurPhotosOnShareProvider);
      for (final j in journeys) {
        final hide = hideNow && isWeightMetric(j) ? true : null;
        final blurV = blurNow ? true : null;
        if (hide == null && blurV == null) continue;
        try {
          await repo.updateMyMembership(
            j.id,
            hideMetric: hide,
            blurMedia: blurV,
          );
        } on Object catch (e) {
          _noteFailure(
            prefs,
            userId,
            j.id,
            e,
            hide: hide != null,
            blur: blurV != null,
          );
        }
      }
    } on Object catch (e) {
      debugPrint('share privacy: listing journeys failed: $e');
    }
  }

  final previous = _pendingPush;
  final next = previous == null ? run() : previous.then((_) => run());
  _pendingPush = next;
  return next.whenComplete(() {
    if (identical(_pendingPush, next)) _pendingPush = null;
  });
}

/// Applies the ON Settings switches to one new membership (joined group,
/// accepted invitation, imported journey). Touches only [journeyId].
Future<void> pushSharePrivacyToJourney(WidgetRef ref, String journeyId) async {
  // Read the ref synchronously: callers navigate away right after this call.
  final JourneyRepository repo;
  final SharedPreferencesWithCache prefs;
  final String? userId;
  final bool hideOn;
  final bool blur;
  try {
    repo = ref.read(journeyRepositoryProvider);
    prefs = ref.read(sharedPreferencesProvider);
    userId = ref.read(currentUserIdProvider);
    hideOn = ref.read(hideWeightOnShareProvider);
    blur = ref.read(blurPhotosOnShareProvider);
  } on Object {
    return;
  }
  var hide = false;
  try {
    final journey = await repo.watch(journeyId).first;
    if (journey == null) return;
    hide = hideOn && isWeightMetric(journey);
    if (!hide && !blur) return;
    await repo.updateMyMembership(
      journeyId,
      hideMetric: hide ? true : null,
      blurMedia: blur ? true : null,
    );
  } on Object catch (e) {
    // Recorded with the flag(s) that were meant; healed at the next resume.
    _noteFailure(prefs, userId, journeyId, e, hide: hide, blur: blur);
  }
}

/// What a new membership should start with: the quiz answers OR the global
/// Settings switches.
({bool hideMetric, bool blurMedia}) newMembershipPrivacy(
  WidgetRef ref,
  Journey journey, {
  required bool hideMetric,
  required bool blurMedia,
}) => (
  hideMetric:
      hideMetric ||
      (ref.read(hideWeightOnShareProvider) && isWeightMetric(journey)),
  blurMedia: blurMedia || ref.read(blurPhotosOnShareProvider),
);
