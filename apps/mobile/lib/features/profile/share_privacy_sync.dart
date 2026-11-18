import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/providers.dart';
import '../share_card/domain/share_card_content.dart';
import 'settings_providers.dart';

/// Pushes the Settings share-privacy switches to every journey membership so
/// the public link and group walls honour them too, not only the share card
/// (C-B1). [hideWeight] only reaches weight (kg) journeys; minutes / km are
/// never hidden by that switch. Best effort: a journey whose membership can
/// not be updated (offline-first rows not synced yet, left group) is skipped.
Future<void> pushSharePrivacyToMemberships(
  WidgetRef ref, {
  bool? hideWeight,
  bool? blur,
}) async {
  if (hideWeight == null && blur == null) return;
  final JourneyRepository repo;
  final List<Journey> journeys;
  try {
    repo = ref.read(journeyRepositoryProvider);
    journeys = await repo.watchActive().first;
  } on Object {
    return;
  }
  for (final j in journeys) {
    final hide = hideWeight != null && isWeightMetric(j) ? hideWeight : null;
    if (hide == null && blur == null) continue;
    try {
      await repo.updateMyMembership(j.id, hideMetric: hide, blurMedia: blur);
    } on Object {
      // Skipped: the next switch change or journey join pushes it again.
    }
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
