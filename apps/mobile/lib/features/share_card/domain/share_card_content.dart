import 'dart:ui' show Size;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:ourney_core/ourney_core.dart';

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
/// membership's `blurMedia` / `hideMetric` (FR-B7) are applied on top.
class ShareCardContent {
  const ShareCardContent({
    required this.title,
    required this.emoji,
    required this.headline,
    required this.number,
    required this.blurPhoto,
    required this.metricHidden,
    this.totalDays,
    this.milestone,
    this.metricValue,
    this.metricUnit,
  });

  factory ShareCardContent.from({
    required Journey journey,
    required Membership? membership,
    required StreakSummary streak,
    required int dayNumber,
    required Iterable<CheckIn> checkIns,
    ShareCardNumber number = ShareCardNumber.streak,
  }) {
    final core = buildShareCard(journey, streak);
    final ShareCardHeadline headline;
    final int value;
    if (number == ShareCardNumber.day) {
      headline = ShareCardHeadline.day;
      value = dayNumber;
    } else {
      value = core.headlineNumber;
      headline = core.milestone == Milestone.completed
          ? ShareCardHeadline.finished
          : streak.current > 0
          ? ShareCardHeadline.streak
          : ShareCardHeadline.checkedIn;
    }

    final hideMetric = metricHiddenFor(journey, membership);
    final hasMetric = journey.metricName != null || journey.metricUnit != null;
    double? metric;
    if (!hideMetric && hasMetric) {
      CheckIn? latest;
      for (final c in checkIns) {
        if (c.metricValue == null) continue;
        if (latest == null || c.localDate.isAfter(latest.localDate)) {
          latest = c;
        }
      }
      metric = latest?.metricValue;
    }

    return ShareCardContent(
      title: core.title,
      emoji: core.emoji,
      headline: headline,
      number: value,
      totalDays: journey.durationDays,
      milestone: core.milestone,
      blurPhoto: core.blurPhoto || (membership?.blurMedia ?? false),
      metricHidden: hideMetric && hasMetric,
      metricValue: metric,
      metricUnit: metric == null ? null : journey.metricUnit,
    );
  }

  final String title;
  final String emoji;
  final ShareCardHeadline headline;

  /// The big number.
  final int number;

  /// Journey duration (null = open-ended).
  final int? totalDays;
  final Milestone? milestone;

  /// Default for the blur switch: on when the journey (weight-loss default,
  /// `hideMetricDefault`) or the caller's membership (`blurMedia`) asks.
  final bool blurPhoto;

  /// True when the journey tracks a metric that must not appear on the card.
  final bool metricHidden;

  /// Latest metric value to print, null when hidden or absent.
  final double? metricValue;
  final String? metricUnit;
}

/// FR-B7: weight-loss journeys never show kg outside the app; other
/// journeys follow `hideMetricDefault` and the caller's `hideMetric`.
bool metricHiddenFor(Journey journey, Membership? membership) =>
    journey.templateId == TemplateId.weightLoss ||
    journey.hideMetricDefault ||
    (membership?.hideMetric ?? false);

/// FR-E3: only the owner of a solo journey, with a backend, gets a public
/// read-only link. Group journeys never have one.
bool canHavePublicLink({
  required Journey journey,
  required Membership? membership,
  required String? currentUserId,
  required bool hasBackend,
}) {
  if (!hasBackend) return false;
  if (journey.kind != JourneyKind.solo) return false;
  if (journey.status == JourneyStatus.archived) return false;
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

/// Check-ins offered as the card photo, newest day first, one per day.
List<CheckIn> photoCandidates(Iterable<CheckIn> checkIns) {
  final byDate = <LocalDate, CheckIn>{};
  for (final c in checkIns) {
    final existing = byDate[c.localDate];
    if (existing == null || c.capturedAt.isAfter(existing.capturedAt)) {
      byDate[c.localDate] = c;
    }
  }
  return byDate.values.toList()
    ..sort((a, b) => b.localDate.compareTo(a.localDate));
}
