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
/// per-journey choice. The key [_allKey] means "every membership" (the
/// journey list itself could not be read).
const String _allKey = '*';

typedef _Flags = ({bool hide, bool blur});

Map<String, _Flags> _loadPending(
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
    final out = <String, _Flags>{};
    for (final e in items.entries) {
      // One malformed item must not drop the others.
      try {
        final v = e.value as Map;
        out[e.key] = (hide: v['h'] == true, blur: v['b'] == true);
      } on Object {
        continue;
      }
    }
    return out;
  } on Object {
    return {};
  }
}

void _logStore(Object e) => debugPrint('share privacy: prefs write failed: $e');

void _savePending(
  SharedPreferencesWithCache prefs,
  String userId,
  Map<String, _Flags> items,
) {
  try {
    final Future<void> write;
    if (items.isEmpty) {
      write = prefs.remove(SharePrivacyPrefs.pendingHeal);
    } else {
      write = prefs.setString(
        SharePrivacyPrefs.pendingHeal,
        jsonEncode({
          'user': userId,
          'items': {
            for (final e in items.entries)
              e.key: {'h': e.value.hide, 'b': e.value.blur},
          },
        }),
      );
    }
    unawaited(write.catchError(_logStore));
  } on Object catch (e) {
    _logStore(e);
  }
}

/// Records that [journeyId] still needs the given flag(s). Skipped when
/// signed out, when the account changed meanwhile, or when the error is an
/// expired session (nothing to heal for that account).
void _noteFailure(
  SharedPreferencesWithCache prefs,
  String? userId,
  String? Function() currentUser,
  String journeyId,
  Object e, {
  required bool hide,
  required bool blur,
}) {
  debugPrint('share privacy: journey $journeyId failed: $e');
  if (userId == null || currentUser() != userId) return;
  if (e is OurneyException && e.error == OurneyErrorCode.unauthenticated) {
    return;
  }
  final items = _loadPending(prefs, userId);
  final old = items[journeyId];
  items[journeyId] = (
    hide: hide || (old?.hide ?? false),
    blur: blur || (old?.blur ?? false),
  );
  _savePending(prefs, userId, items);
}

/// Removes just the given flag(s) of [journeyId] (entry gone when empty).
void _clearFlags(
  SharedPreferencesWithCache prefs,
  String? userId,
  String journeyId, {
  required bool hide,
  required bool blur,
}) {
  if (userId == null) return;
  final items = _loadPending(prefs, userId);
  final old = items[journeyId];
  if (old == null) return;
  final next = (hide: old.hide && !hide, blur: old.blur && !blur);
  if (next.hide || next.blur) {
    items[journeyId] = next;
  } else {
    items.remove(journeyId);
  }
  _savePending(prefs, userId, items);
}

/// The user chose a value for [journeyId] by hand (journey settings): any
/// waiting heal for that flag is obsolete and must not overwrite it later.
void forgetSharePrivacyHeal(
  WidgetRef ref,
  String journeyId, {
  bool hide = false,
  bool blur = false,
}) {
  try {
    _clearFlags(
      ref.read(sharedPreferencesProvider),
      ref.read(currentUserIdProvider),
      journeyId,
      hide: hide,
      blur: blur,
    );
  } on Object {
    // Nothing recorded, nothing to forget.
  }
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
/// journey, so per-journey choices stay. Called at app start and resume.
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
  String? current() => container.read(currentUserIdProvider);
  // Drops the snapshot flags, but only if the entry was not touched since
  // (a push that failed meanwhile keeps its flags for the next heal).
  void done(String key, _Flags snapshot) {
    final now = _loadPending(prefs, userId);
    if (now[key] != snapshot) return;
    _clearFlags(prefs, userId, key, hide: snapshot.hide, blur: snapshot.blur);
  }

  _healing = true;
  try {
    for (final entry in pending.entries) {
      if (current() != userId) break;
      final snapshot = entry.value;
      final hideOn = snapshot.hide && container.read(hideWeightOnShareProvider);
      final blurOn = snapshot.blur && container.read(blurPhotosOnShareProvider);
      if (!hideOn && !blurOn) {
        done(entry.key, snapshot);
        continue;
      }
      try {
        if (entry.key == _allKey) {
          for (final j in await repo.allMine()) {
            if (current() != userId) return;
            final hide = hideOn && isWeightMetric(j);
            if (!hide && !blurOn) continue;
            await repo.updateMyMembership(
              j.id,
              hideMetric: hide ? true : null,
              blurMedia: blurOn ? true : null,
            );
          }
        } else {
          var hide = hideOn;
          if (hide) {
            // The weight status may have been unknown when it failed.
            final journey = await repo.watch(entry.key).first;
            if (journey == null) {
              done(entry.key, snapshot);
              continue;
            }
            hide = isWeightMetric(journey);
          }
          if (current() != userId) break;
          if (hide || blurOn) {
            await repo.updateMyMembership(
              entry.key,
              hideMetric: hide ? true : null,
              blurMedia: blurOn ? true : null,
            );
          }
        }
        done(entry.key, snapshot);
      } on OurneyException catch (e) {
        debugPrint('share privacy: heal ${entry.key} failed: $e');
        if (e.error == OurneyErrorCode.notFound) done(entry.key, snapshot);
      } on Object catch (e) {
        debugPrint('share privacy: heal ${entry.key} failed: $e');
      }
    }
  } finally {
    _healing = false;
  }
}

/// Heals failed share-privacy pushes at app start and when it resumes.
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(healSharePrivacy(ProviderScope.containerOf(context)));
    });
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
/// not be updated (or a journey list that can not be read) is recorded with
/// just the failed flag and healed later.
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
  String? current() {
    try {
      return container.read(currentUserIdProvider);
    } on Object {
      return userId;
    }
  }

  Future<void> run() async {
    List<Journey> journeys;
    try {
      journeys = await repo.allMine();
    } on Object catch (e) {
      _noteFailure(
        prefs,
        userId,
        current,
        _allKey,
        e,
        hide: hideWeight == true,
        blur: blur == true,
      );
      return;
    }
    final hideNow =
        hideWeight == true && container.read(hideWeightOnShareProvider);
    final blurNow = blur == true && container.read(blurPhotosOnShareProvider);
    for (final j in journeys) {
      final hide = hideNow && isWeightMetric(j) ? true : null;
      final blurV = blurNow ? true : null;
      if (hide == null && blurV == null) continue;
      try {
        await repo.updateMyMembership(j.id, hideMetric: hide, blurMedia: blurV);
        _clearFlags(
          prefs,
          userId,
          j.id,
          hide: hide != null,
          blur: blurV != null,
        );
      } on Object catch (e) {
        _noteFailure(
          prefs,
          userId,
          current,
          j.id,
          e,
          hide: hide != null,
          blur: blurV != null,
        );
      }
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
  String? current() {
    try {
      return ref.read(currentUserIdProvider);
    } on Object {
      return userId;
    }
  }

  // Unknown until the journey is read: a failure before that records hide
  // anyway and the heal decides (it only applies it to weight journeys).
  var hide = hideOn;
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
    _clearFlags(prefs, userId, journeyId, hide: hide, blur: blur);
  } on Object catch (e) {
    // Recorded with the flag(s) that were meant; healed at the next resume.
    _noteFailure(prefs, userId, current, journeyId, e, hide: hide, blur: blur);
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
