import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
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

/// `"!<journeyId>"` entries list the flags the user set by hand for that
/// journey while [_allKey] was pending: the all-marker must skip them.
const String _exclPrefix = '!';

/// Full pushes to every membership that are running right now (in memory:
/// no push survives an app kill) and the flags the user set by hand for a
/// journey meanwhile. A push that fails for such a journey must not record
/// the flag, or the heal would overwrite the user's choice.
int _flights = 0;

/// Per flag: the push sequence at the time of the hand-set (null = none).
final Map<String, ({int? hideSeq, int? blurSeq})> _heldByHand = {};

/// Number of full pushes started so far; a hand-set choice only supersedes
/// failures of pushes that started before it.
int _pushSeq = 0;

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

String? _storedUser(SharedPreferencesWithCache prefs) {
  try {
    final raw = prefs.getString(SharePrivacyPrefs.pendingHeal);
    if (raw == null) return null;
    return (jsonDecode(raw) as Map<String, dynamic>)['user'] as String?;
  } on Object {
    return null;
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
      // Never delete another account's record.
      if (_storedUser(prefs) case final owner? when owner != userId) return;
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
  int? pushSeq,
}) {
  debugPrint('share privacy: journey $journeyId failed: $e');
  if (userId == null || currentUser() != userId) return;
  if (e is OurneyException && e.error == OurneyErrorCode.unauthenticated) {
    return;
  }
  // A hand-set value during a running push supersedes this failure.
  // (only one that happened after this push started or while it ran).
  final held = _heldByHand[journeyId];
  bool superseded(int? heldSeq) =>
      heldSeq != null && pushSeq != null && heldSeq >= pushSeq;
  final hideF = hide && !superseded(held?.hideSeq);
  final blurF = blur && !superseded(held?.blurSeq);
  if (!hideF && !blurF) return;
  final items = _loadPending(prefs, userId);
  final old = items[journeyId];
  items[journeyId] = (
    hide: hideF || (old?.hide ?? false),
    blur: blurF || (old?.blur ?? false),
  );
  _savePending(prefs, userId, items);
}

/// Removes just the given flag(s) of [journeyId] (entry gone when empty).
/// With [byHand] the flags are also excluded from a pending all-marker.
void _clearFlags(
  SharedPreferencesWithCache prefs,
  String? userId,
  String journeyId, {
  required bool hide,
  required bool blur,
  bool byHand = false,
}) {
  if (userId == null) return;
  final items = _loadPending(prefs, userId);
  var changed = false;
  if (byHand && items.containsKey(_allKey) && journeyId != _allKey) {
    final ex = items['$_exclPrefix$journeyId'];
    items['$_exclPrefix$journeyId'] = (
      hide: hide || (ex?.hide ?? false),
      blur: blur || (ex?.blur ?? false),
    );
    changed = true;
  }
  final old = items[journeyId];
  if (old != null) {
    final next = (hide: old.hide && !hide, blur: old.blur && !blur);
    if (next.hide || next.blur) {
      items[journeyId] = next;
    } else {
      items.remove(journeyId);
    }
    changed = true;
  }
  if (!items.containsKey(_allKey)) {
    final before = items.length;
    items.removeWhere((k, _) => k.startsWith(_exclPrefix));
    if (items.length != before) changed = true;
  }
  if (changed) _savePending(prefs, userId, items);
}

/// The user chose a value for [journeyId] by hand (journey settings): any
/// waiting heal for that flag is obsolete and must not overwrite it later.
void forgetSharePrivacyHeal(
  WidgetRef ref,
  String journeyId, {
  bool hide = false,
  bool blur = false,
}) {
  if (_flights > 0) {
    final old = _heldByHand[journeyId];
    _heldByHand[journeyId] = (
      hideSeq: hide ? _pushSeq : old?.hideSeq,
      blurSeq: blur ? _pushSeq : old?.blurSeq,
    );
  }
  try {
    _clearFlags(
      ref.read(sharedPreferencesProvider),
      ref.read(currentUserIdProvider),
      journeyId,
      hide: hide,
      blur: blur,
      byHand: true,
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
      if (entry.key.startsWith(_exclPrefix)) {
        continue;
      }
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
            // Re-read now: the user may have decided meanwhile.
            final fresh = _loadPending(prefs, userId);
            if (!fresh.containsKey(_allKey)) break;
            final ex = fresh['$_exclPrefix${j.id}'];
            final hide = hideOn && isWeightMetric(j) && !(ex?.hide ?? false);
            final blurV = blurOn && !(ex?.blur ?? false);
            if (!hide && !blurV) continue;
            try {
              await repo.updateMyMembership(
                j.id,
                hideMetric: hide ? true : null,
                blurMedia: blurV ? true : null,
              );
            } on OurneyException catch (e) {
              // One journey left meanwhile: the others still get theirs.
              if (e.error != OurneyErrorCode.notFound) rethrow;
            }
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
          // Re-read after the awaits: a hand-set choice (or a newer heal)
          // may have removed the entry or some of its flags.
          final fresh = _loadPending(prefs, userId)[entry.key];
          if (fresh == null) continue;
          hide = hide && fresh.hide;
          final blurNow = blurOn && fresh.blur;
          if (hide || blurNow) {
            await repo.updateMyMembership(
              entry.key,
              hideMetric: hide ? true : null,
              blurMedia: blurNow ? true : null,
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
  // Hand-set choices made while this push runs supersede its failures.
  _flights++;
  final mySeq = ++_pushSeq;
  String? current() {
    try {
      return container.read(currentUserIdProvider);
    } on Object {
      // Unknown user: record nothing (never fall back to the old one).
      return null;
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
    var allOk = true;
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
        allOk = false;
        _noteFailure(
          prefs,
          userId,
          current,
          j.id,
          e,
          hide: hide != null,
          blur: blurV != null,
          pushSeq: mySeq,
        );
      }
    }
    // A full push that reached every membership settles the all-marker.
    if (allOk) {
      _clearFlags(
        prefs,
        userId,
        _allKey,
        hide: hideWeight == true,
        blur: blur == true,
      );
    }
  }

  final previous = _pendingPush;
  final next = previous == null ? run() : previous.then((_) => run());
  _pendingPush = next;
  return next.whenComplete(() {
    _flights--;
    if (_flights == 0) _heldByHand.clear();
    if (identical(_pendingPush, next)) _pendingPush = null;
  });
}

/// Applies the ON Settings switches to one new membership (joined group,
/// accepted invitation, imported journey). Touches only [journeyId].
Future<void> pushSharePrivacyToJourney(WidgetRef ref, String journeyId) =>
    applySharePrivacyToJourney(ref.read, journeyId);

/// [pushSharePrivacyToJourney] for callers that hold a `Ref` (the import job
/// runner): pass `ref.read`.
Future<void> applySharePrivacyToJourney(
  T Function<T>(ProviderListenable<T> provider) read,
  String journeyId,
) async {
  // Read the ref synchronously: callers navigate away right after this call.
  final JourneyRepository repo;
  final SharedPreferencesWithCache prefs;
  final String? userId;
  final bool hideOn;
  final bool blur;
  try {
    repo = read(journeyRepositoryProvider);
    prefs = read(sharedPreferencesProvider);
    userId = read(currentUserIdProvider);
    hideOn = read(hideWeightOnShareProvider);
    blur = read(blurPhotosOnShareProvider);
  } on Object {
    return;
  }
  String? current() {
    try {
      return read(currentUserIdProvider);
    } on Object {
      // Unknown user: record nothing (never fall back to the old one).
      return null;
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
