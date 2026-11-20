import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/providers.dart';
import '../share_card/domain/share_card_content.dart';
import 'settings_providers.dart';

Future<void>? _pendingPush;

/// Set when a membership update failed: [SharePrivacyHealHook] re-applies the
/// ON switches at the next app resume.
bool _needsHeal = false;

/// Whether a failed push is waiting to be re-applied.
@visibleForTesting
bool get sharePrivacyNeedsHeal => _needsHeal;

void _noteFailure(String what, Object e) {
  _needsHeal = true;
  debugPrint('share privacy: $what failed: $e');
}

/// Re-applies the ON Settings switches to every membership after a failed
/// push (no-op otherwise). Called at app resume.
Future<void> healSharePrivacy(WidgetRef ref) {
  if (!_needsHeal) return Future<void>.value();
  _needsHeal = false;
  return pushSharePrivacyToMemberships(ref, hideWeight: true, blur: true);
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
    if (state == AppLifecycleState.resumed) unawaited(healSharePrivacy(ref));
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
/// re-read the switch before writing, so rapid toggles cannot leave a stale
/// value behind. Best effort: a membership that can not be updated is skipped.
Future<void> pushSharePrivacyToMemberships(
  WidgetRef ref, {
  bool? hideWeight,
  bool? blur,
}) {
  if (hideWeight != true && blur != true) {
    return _pendingPush ?? Future<void>.value();
  }
  // Everything that needs the ref is read before the first await: the caller
  // may unmount (and dispose the ref) while the push is still running.
  final JourneyRepository repo;
  final bool hideAtStart;
  final bool blurAtStart;
  try {
    repo = ref.read(journeyRepositoryProvider);
    hideAtStart = ref.read(hideWeightOnShareProvider);
    blurAtStart = ref.read(blurPhotosOnShareProvider);
  } on Object {
    return Future<void>.value();
  }
  bool readOr(bool Function() read, bool fallback) {
    try {
      return read();
    } on Object {
      return fallback;
    }
  }

  Future<void> run() async {
    try {
      final journeys = await repo.allMine();
      final hideNow =
          hideWeight == true &&
          readOr(() => ref.read(hideWeightOnShareProvider), hideAtStart);
      final blurNow =
          blur == true &&
          readOr(() => ref.read(blurPhotosOnShareProvider), blurAtStart);
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
          // Skipped now; healed at the next app resume (_needsHeal).
          _noteFailure('membership ${j.id}', e);
        }
      }
    } on Object catch (e) {
      _noteFailure('listing journeys', e);
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
  final bool hideOn;
  final bool blur;
  try {
    repo = ref.read(journeyRepositoryProvider);
    hideOn = ref.read(hideWeightOnShareProvider);
    blur = ref.read(blurPhotosOnShareProvider);
  } on Object {
    return;
  }
  try {
    final journey = await repo.watch(journeyId).first;
    if (journey == null) return;
    final hide = hideOn && isWeightMetric(journey);
    if (!hide && !blur) return;
    await repo.updateMyMembership(
      journeyId,
      hideMetric: hide ? true : null,
      blurMedia: blur ? true : null,
    );
  } on Object catch (e) {
    // Healed at the next app resume (_needsHeal).
    _noteFailure('journey $journeyId', e);
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
