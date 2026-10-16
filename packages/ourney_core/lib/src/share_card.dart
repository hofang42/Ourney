import 'models.dart';
import 'streak.dart';

enum Milestone { sevenDays, thirtyDays, completed }

/// Completion wins over streak milestones; 7/30 fire on the exact day.
Milestone? milestoneFor(StreakSummary streak, Journey journey) {
  final duration = journey.durationDays;
  if (duration != null && streak.completed >= duration) return Milestone.completed;
  if (streak.current == 30) return Milestone.thirtyDays;
  if (streak.current == 7) return Milestone.sevenDays;
  return null;
}

/// View-model for the share card (Vietnamese copy).
class ShareCardData {
  const ShareCardData({
    required this.title,
    required this.emoji,
    required this.headlineNumber,
    required this.subtitle,
    required this.blurPhoto,
    this.displayName,
    this.milestone,
  });

  final String title;
  final String emoji;
  final int headlineNumber;
  final String subtitle;
  final String? displayName;
  final Milestone? milestone;

  /// Blur the photo when sharing outside the app (weight-loss default).
  final bool blurPhoto;
}

ShareCardData buildShareCard(Journey journey, StreakSummary streak, {String? displayName}) {
  final milestone = milestoneFor(streak, journey);
  final int headline;
  final String subtitle;
  if (milestone == Milestone.completed) {
    headline = streak.completed;
    subtitle = 'Hoàn thành ${streak.completed}/${journey.durationDays} ngày';
  } else if (streak.current > 0) {
    headline = streak.current;
    subtitle = '${streak.current} ngày liên tiếp';
  } else {
    headline = streak.completed;
    subtitle = '${streak.completed} ngày đã check-in';
  }
  return ShareCardData(
    title: journey.title,
    emoji: journey.emoji,
    headlineNumber: headline,
    subtitle: subtitle,
    displayName: displayName,
    milestone: milestone,
    blurPhoto: journey.hideMetricDefault,
  );
}
