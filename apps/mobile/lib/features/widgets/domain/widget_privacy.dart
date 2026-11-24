import 'package:ourney_core/ourney_core.dart';

import '../../../personas/persona_contract.dart' show personaSkinOf;

/// How home-screen widgets handle journey and squad member photos (§7.1, §7.2).
///
/// Lock-screen widgets (`accessory*`) and Live Activities / Live Updates never
/// display photos regardless of this setting.
enum WidgetPhotoMode {
  /// Default: solo non-weight-loss photos show clear (unless global/membership
  /// share-blur is on); weight-loss photos are pre-blurred (`sigma = 18`);
  /// squad widgets show member avatars/initials only (`todayThumbFile == null`).
  smart('smart'),

  /// All solo hero photos and squad member today photos are pre-blurred
  /// (`sigma = 18`) before being written to the widget thumbnail cache.
  blurred('blurred'),

  /// No photos or avatar image files are written to the widget container;
  /// widgets render vector stickers, initial discs, and streak counters only.
  off('off'),

  /// User explicitly opted in to unblurred photos on the unlocked Home Screen
  /// (including weight-loss solo journeys and squad/couple Polaroid grids),
  /// while still honoring blocked users, reported check-ins, and share-blur.
  clear('clear');

  const WidgetPhotoMode(this.wireName);

  final String wireName;

  /// Lenient parser: unknown or null wire values default to [smart].
  static WidgetPhotoMode fromWire(String? wire) {
    for (final mode in values) {
      if (mode.wireName == wire) return mode;
    }
    return WidgetPhotoMode.smart;
  }
}

/// Result of evaluating [WidgetPrivacyPolicy] for one image slot.
class WidgetPhotoDecision {
  const WidgetPhotoDecision({
    required this.includePhoto,
    required this.blurPhoto,
  });

  /// Omit the file path from `snapshot_v1.json` and do not copy it to `thumbs/`.
  static const omit = WidgetPhotoDecision(
    includePhoto: false,
    blurPhoto: false,
  );

  /// Copy a pre-blurred (`sigma = 18`) thumbnail to `thumbs/` and set the
  /// corresponding `*Blurred` flag to `true` in `snapshot_v1.json`.
  static const blurred = WidgetPhotoDecision(
    includePhoto: true,
    blurPhoto: true,
  );

  /// Copy a downsampled crisp thumbnail to `thumbs/`.
  static const clear = WidgetPhotoDecision(
    includePhoto: true,
    blurPhoto: false,
  );

  final bool includePhoto;
  final bool blurPhoto;

  @override
  bool operator ==(Object other) =>
      other is WidgetPhotoDecision &&
      other.includePhoto == includePhoto &&
      other.blurPhoto == blurPhoto;

  @override
  int get hashCode => Object.hash(includePhoto, blurPhoto);

  @override
  String toString() =>
      'WidgetPhotoDecision(includePhoto: $includePhoto, blurPhoto: $blurPhoto)';
}

/// Pure privacy rules for `snapshot_v1.json` and widget thumbnail preparation
/// (§7.1 Non-Negotiable Privacy Rules).
///
/// Privacy-by-omission invariant:
/// * `metricValue` (weight/kg), `metricUnit`, `dna` (`goal`, `reason`),
///   `caption`, `email`, and `phone` do not exist in `snapshot_v1.json`.
/// * Sensitive weight-loss photos never touch the widget container unblurred
///   unless the user explicitly selects [WidgetPhotoMode.clear].
abstract final class WidgetPrivacyPolicy {
  /// True when [journey] is a weight-loss or default-hidden-metric journey.
  static bool isSensitiveMetricJourney(Journey journey) =>
      journey.templateId == TemplateId.weightLoss ||
      journey.hideMetricDefault ||
      personaSkinOf(journey) == PersonaSkinId.quietTransformer;

  /// Resolves the effective Lock Screen title redaction flag (§7.1).
  ///
  /// When the user has not explicitly toggled the preference (`null`), defaults
  /// to `true` if any active journey is a weight-loss/sensitive-metric journey,
  /// and `false` otherwise.
  static bool resolveRedactLockScreenTitles({
    required bool? explicitPreference,
    required Iterable<Journey> activeJourneys,
  }) {
    if (explicitPreference != null) return explicitPreference;
    return activeJourneys.any(isSensitiveMetricJourney);
  }

  /// Decides whether and how a journey's hero check-in photo may appear on the
  /// Home Screen (`OurneyTodayWidget`).
  static WidgetPhotoDecision decideHeroPhoto({
    required WidgetPhotoMode photoMode,
    required Journey journey,
    Membership? membership,
    bool globalBlurPhotosOnShare = false,
    bool isHiddenCheckIn = false,
  }) {
    if (isHiddenCheckIn || photoMode == WidgetPhotoMode.off) {
      return WidgetPhotoDecision.omit;
    }
    if (photoMode == WidgetPhotoMode.blurred) {
      return WidgetPhotoDecision.blurred;
    }
    final shareBlurred =
        globalBlurPhotosOnShare || (membership?.blurMedia ?? false);
    if (shareBlurred) {
      return WidgetPhotoDecision.blurred;
    }
    if (photoMode == WidgetPhotoMode.smart) {
      return isSensitiveMetricJourney(journey)
          ? WidgetPhotoDecision.blurred
          : WidgetPhotoDecision.clear;
    }
    return WidgetPhotoDecision.clear;
  }

  /// Decides whether and how a squad/couple member's today photo may appear on
  /// `OurneySquadWidget` (§7.1).
  ///
  /// In [WidgetPhotoMode.smart] (the default), Squad widgets show avatars and
  /// initials only (`todayThumbFile == null`) so a friend's photo never
  /// unexpectedly appears on the user's Home Screen.
  static WidgetPhotoDecision decideSquadMemberPhoto({
    required WidgetPhotoMode photoMode,
    required bool isMe,
    Membership? myMembership,
    bool globalBlurPhotosOnShare = false,
    bool isBlocked = false,
    bool checkedInHidden = false,
  }) {
    if (isBlocked ||
        checkedInHidden ||
        photoMode == WidgetPhotoMode.off ||
        photoMode == WidgetPhotoMode.smart) {
      return WidgetPhotoDecision.omit;
    }
    if (photoMode == WidgetPhotoMode.blurred) {
      return WidgetPhotoDecision.blurred;
    }
    final selfShareBlurred =
        isMe && (globalBlurPhotosOnShare || (myMembership?.blurMedia ?? false));
    return selfShareBlurred
        ? WidgetPhotoDecision.blurred
        : WidgetPhotoDecision.clear;
  }

  /// Decides whether a squad member's profile avatar file may be copied to
  /// `thumbs/` (omitted for blocked users or when [photoMode] is `off`).
  static WidgetPhotoDecision decideSquadMemberAvatar({
    required WidgetPhotoMode photoMode,
    bool isBlocked = false,
  }) {
    if (isBlocked || photoMode == WidgetPhotoMode.off) {
      return WidgetPhotoDecision.omit;
    }
    return WidgetPhotoDecision.clear;
  }
}
