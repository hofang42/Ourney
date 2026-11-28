import 'dart:ui' show Size;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:ourney_core/ourney_core.dart';

import '../../../data/group_daily_checkins_provider.dart' show compareCheckIns;

/// The two share card sizes (FR-E1). The card is laid out at a logical size
/// of 360 points wide and rendered at [pixelRatio] 3, so the PNG is exactly
/// [pixelWidth] x [pixelHeight] (docs/03 "Share card": view 360x640pt, x3).
enum ShareCardFormat {
  /// 1080x1920. Instagram draws its own UI over the top 250px and the
  /// bottom 340px, so the content stays inside the middle band.
  story(pixelWidth: 1080, pixelHeight: 1920, safeTopPx: 250, safeBottomPx: 340),

  /// 1080x1350 feed post (4:5).
  feed(pixelWidth: 1080, pixelHeight: 1350, safeTopPx: 0, safeBottomPx: 0);

  const ShareCardFormat({
    required this.pixelWidth,
    required this.pixelHeight,
    required this.safeTopPx,
    required this.safeBottomPx,
  });

  final int pixelWidth;
  final int pixelHeight;

  /// Strip reserved for the story viewer's UI (in output pixels).
  final int safeTopPx;
  final int safeBottomPx;

  static const double logicalWidth = 360;

  /// Output pixels per logical point.
  double get pixelRatio => pixelWidth / logicalWidth;

  Size get logicalSize => Size(logicalWidth, pixelHeight / pixelRatio);

  int get coupleTileCount => this == story ? 36 : 16;

  /// Padding of the card content in logical points: the IG safe zones plus
  /// a uniform margin.
  EdgeInsets get contentPadding {
    const margin = 24.0;
    return EdgeInsets.fromLTRB(
      margin,
      safeTopPx / pixelRatio + margin,
      margin,
      safeBottomPx / pixelRatio + margin,
    );
  }
}

/// What the big number shows.
enum ShareCardNumber {
  /// Streak, or completed / checked-in days ([buildShareCard] rules).
  streak,

  /// Today's day N of the journey.
  day,
}

/// Which caption goes with the big number.
enum ShareCardHeadline { streak, checkedIn, finished, day }

/// Everything drawn on the card, derived from the journey, the caller's
/// membership and their check-ins. Big number, milestone and the default
/// photo blur come from `buildShareCard` (packages/ourney_core); the
/// membership's `blurMedia` / `hideMetric` (FR-B7) and the global Settings
/// switches ([hideMetricOnShare] / [blurPhotosOnShare] of [ShareCardContent.from])
/// are applied on top.
class ShareCardContent {
  const ShareCardContent({
    required this.title,
    required this.emoji,
    required this.templateId,
    required this.headline,
    required this.number,
    required this.blurPhoto,
    required this.metricHidden,
    this.totalDays,
    this.milestone,
    this.metricValue,
    this.metricUnit,
    this.dayNumber = 1,
    this.completedDays = 0,
    this.streakDays = 0,
    this.photoCount = 0,
    this.activity = const [],
  });

  factory ShareCardContent.from({
    required Journey journey,
    required Membership? membership,
    required StreakSummary streak,
    required int dayNumber,
    required Iterable<CheckIn> checkIns,
    ShareCardNumber number = ShareCardNumber.streak,
    bool forceHideMetric = false,
    bool hideMetricOnShare = false,
    bool blurPhotosOnShare = false,
    int? photoCount,
  }) {
    final core = buildShareCard(journey, streak);
    var effectiveDay = dayNumber;
    if (journey.status != JourneyStatus.active &&
        journey.durationDays == null) {
      LocalDate? latestDate;
      for (final c in checkIns) {
        if (latestDate == null || c.localDate.isAfter(latestDate)) {
          latestDate = c.localDate;
        }
      }
      final span = latestDate == null
          ? 1
          : (journey.startDate.daysUntil(latestDate) + 1).clamp(1, 100000);
      if (effectiveDay > span) effectiveDay = span;
    }
    final ShareCardHeadline headline;
    final int value;
    if (number == ShareCardNumber.day) {
      headline = ShareCardHeadline.day;
      value = effectiveDay;
    } else {
      value = journey.origin == JourneyOrigin.imported
          ? streak.completed
          : core.headlineNumber;
      headline = core.milestone == Milestone.completed
          ? ShareCardHeadline.finished
          : journey.origin != JourneyOrigin.imported && streak.current > 0
          ? ShareCardHeadline.streak
          : ShareCardHeadline.checkedIn;
    }

    final hideMetric = shareMetricHidden(
      journey,
      membership,
      forceHideMetric: forceHideMetric,
      hideWeight: hideMetricOnShare,
    );
    final hasMetric = journey.metricName != null || journey.metricUnit != null;
    double? metric;
    var metricUnit = journey.metricUnit;
    if (!hideMetric && hasMetric) {
      CheckIn? latest;
      for (final c in checkIns) {
        if (c.metricValue == null) continue;
        if (latest == null || c.localDate.isAfter(latest.localDate)) {
          latest = c;
        }
      }
      metric = latest?.metricValue;
    } else if (!hideMetric && !hasMetric) {
      // Sum every run on the latest day with logged distance.
      LocalDate? latestDate;
      for (final c in checkIns) {
        if (c.extras.km == null) continue;
        if (latestDate == null || c.localDate.isAfter(latestDate)) {
          latestDate = c.localDate;
          metric = c.extras.km;
        } else if (c.localDate == latestDate) {
          metric = (metric ?? 0) + c.extras.km!;
        }
      }
      metricUnit = 'km';
    }

    final days = <LocalDate>{for (final c in checkIns) c.localDate};
    final last = effectiveDay.clamp(0, journey.durationDays ?? effectiveDay);
    final first = (last - shareCardActivityDays).clamp(0, last);
    final activity = [
      for (var i = first; i < last; i++)
        days.contains(journey.startDate.addDays(i)),
    ];

    return ShareCardContent(
      dayNumber: effectiveDay,
      completedDays: streak.completed,
      streakDays: streak.current,
      photoCount:
          photoCount ?? checkIns.where((c) => c.photoPath.isNotEmpty).length,
      activity: activity,
      title: core.title,
      emoji: core.emoji,
      templateId: journey.templateId,
      headline: headline,
      number: value,
      totalDays: journey.durationDays,
      milestone: core.milestone,
      blurPhoto:
          core.blurPhoto ||
          blurPhotosOnShare ||
          (membership?.blurMedia ?? false),
      metricHidden: hideMetric && hasMetric,
      metricValue: metric,
      metricUnit: metric == null ? null : metricUnit,
    );
  }

  final String title;
  final String emoji;

  /// Fallback for the card icon when [emoji] has no vector icon.
  final TemplateId templateId;
  final ShareCardHeadline headline;

  /// The big number.
  final int number;

  /// Journey duration (null = open-ended).
  final int? totalDays;
  final Milestone? milestone;

  /// Default for the blur switch: on when the journey (weight-loss default,
  /// `hideMetricDefault`), the caller's membership (`blurMedia`) or the
  /// global "Blur photos when sharing" setting asks.
  final bool blurPhoto;

  /// True when the journey tracks a metric that must not appear on the card.
  final bool metricHidden;

  /// Latest custom metric or latest day's total km, null when hidden or absent.
  final double? metricValue;
  final String? metricUnit;

  /// Today's day N of the journey (the "NGÀY N" label on skin cards).
  final int dayNumber;

  /// Distinct check-in days inside the journey window.
  final int completedDays;

  /// Current streak (can be 0 while the number shows the day).
  final int streakDays;

  /// Check-ins that carry a photo.
  final int photoCount;

  /// One flag per day (oldest first, at most [shareCardActivityDays]) for the
  /// flexer bars: true when the day has a check-in.
  final List<bool> activity;
}

/// Bars on the flexer card (`FlexerShare` draws 21).
const int shareCardActivityDays = 21;

/// The Settings switch covers weight units and names, the Weight Loss
/// template, and unitless metrics using the Quiet Transformer layout.
bool isWeightMetric(Journey journey) {
  final unit = (journey.metricUnit ?? '').trim().toLowerCase();
  final name = (journey.metricName ?? '').toLowerCase();
  return journey.templateId == TemplateId.weightLoss ||
      (journey.layout == PersonaSkinId.quietTransformer && unit.isEmpty) ||
      unit == 'kg' ||
      unit == 'lb' ||
      unit == 'lbs' ||
      name.contains('weight') ||
      name.contains('cân nặng');
}

/// FR-B7: weight-loss journeys never show kg outside the app; other
/// journeys follow `hideMetricDefault` and the caller's `hideMetric`.
bool metricHiddenFor(Journey journey, Membership? membership) =>
    journey.templateId == TemplateId.weightLoss ||
    journey.hideMetricDefault ||
    (membership?.hideMetric ?? false);

/// Effective redaction for both share cards and Wrapped captions.
bool shareMetricHidden(
  Journey journey,
  Membership? membership, {
  required bool forceHideMetric,
  required bool hideWeight,
}) =>
    forceHideMetric ||
    (hideWeight && isWeightMetric(journey)) ||
    metricHiddenFor(journey, membership);

/// S9: a public link can only be turned on for a finished (ended or
/// archived) or retold (imported) journey.
bool publicLinkEligible(Journey journey) =>
    journey.status != JourneyStatus.active ||
    journey.origin == JourneyOrigin.imported;

/// FR-E3: only the owner of a solo journey, with a backend, gets a public
/// read-only link. Group journeys never have one. S9 (`set_public_link`):
/// a link can only be turned on once the journey is finished (ended or
/// archived) or retold (imported); a running journey that still has a link
/// keeps the section so the owner can revoke it.
bool canHavePublicLink({
  required Journey journey,
  required Membership? membership,
  required String? currentUserId,
  required bool hasBackend,
}) {
  if (!hasBackend) return false;
  if (journey.kind != JourneyKind.solo) return false;
  if (!publicLinkEligible(journey) && activePublicToken(journey) == null) {
    return false;
  }
  final m = membership;
  if (m != null) return m.role == MemberRole.owner && m.isActive;
  return currentUserId != null && journey.ownerId == currentUserId;
}

/// The journey's current public token, if it is a valid `link` token.
String? activePublicToken(Journey journey) {
  final token = journey.publicToken;
  if (journey.kind != JourneyKind.solo) return null;
  if (journey.visibility != JourneyVisibility.link) return null;
  if (token == null || !isValidPublicToken(token)) return null;
  return token;
}

/// Check that a cached link still exists before adding an address to a
/// caption. A different title-bearing address needs a fresh copy action.
Future<String?> publicAddressForCaption(
  Journey journey,
  SharingRepository? Function() sharing, {
  required bool Function() hideTitle,
}) async {
  final token = activePublicToken(journey);
  if (token == null) return null;
  try {
    final repo = sharing();
    if (repo == null) return isTitledPublicSlug(token) ? null : token;
    final state = await repo.watchShareState(journey.id).first;
    return state.publicAddress(
      hideTitle: hideTitle() || state.publicToken != token,
    );
  } on OurneyException {
    return null;
  }
}

/// Check-ins offered as the card photo, newest day first, one per day.
List<CheckIn> photoCandidates(Iterable<CheckIn> checkIns) {
  final byDate = <LocalDate, CheckIn>{};
  for (final c in checkIns) {
    final existing = byDate[c.localDate];
    if (existing == null || compareCheckIns(c, existing) > 0) {
      byDate[c.localDate] = c;
    }
  }
  return byDate.values.toList()
    ..sort((a, b) => b.localDate.compareTo(a.localDate));
}
