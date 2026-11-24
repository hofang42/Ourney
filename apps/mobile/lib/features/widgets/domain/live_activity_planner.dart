import '../../../app/redirect.dart' show AuthStatus;
import 'widget_snapshot.dart';

/// Maximum duration before journey-local midnight for an active Check-In Window
/// Live Activity / Live Update, keeping it strictly inside ActivityKit's 8-hour
/// foreground-started ceiling (§6.2).
const Duration kMaxLiveWindowDuration = Duration(hours: 6);

/// Lead time before a journey's daily reminder when the Check-In Window opens (§6.2).
const Duration kReminderWindowLead = Duration(minutes: 30);

/// Lifecycle action decided by [LiveActivityWindowPlanner].
enum LiveActivityAction {
  /// No Live Activity should be active; any running activity ends immediately.
  endImmediate,

  /// Start or update the active Check-In Window countdown.
  startOrUpdate,

  /// All active journeys just became completed today while a Live Activity was
  /// running: transition to the celebration banner and dismiss after 2 minutes
  /// on iOS / cancel notification `42000` on Android (§6.2 #3).
  celebrateAndDismiss,
}

/// Output of [LiveActivityWindowPlanner.plan].
class LiveActivityPlan {
  const LiveActivityPlan({
    required this.action,
    required this.window,
    required this.channelPayload,
  });

  const LiveActivityPlan.end()
    : action = LiveActivityAction.endImmediate,
      window = null,
      channelPayload = null;

  final LiveActivityAction action;

  /// Non-null when an open check-in window is active (`snapshot_v1.json -> liveWindow`).
  final WidgetLiveWindow? window;

  /// Payload passed to `MethodChannel('ourney/widgets').invokeMethod('syncLiveActivity', ...)`
  /// (`null` to end immediately).
  final Map<String, Object?>? channelPayload;
}

/// Pure Dart planner for the evening Check-In Window Live Activity (iOS 16.2+
/// `ActivityKit`) and Ongoing Live Update (Android 16 `ProgressStyle` / API 26–35
/// Chronometer notification `42000`) (§6.2).
abstract final class LiveActivityWindowPlanner {
  /// Evaluates whether a Check-In Window is currently eligible and builds both
  /// the `snapshot_v1.json` [WidgetLiveWindow] and the `syncLiveActivity`
  /// platform-channel payload.
  static LiveActivityPlan plan({
    required DateTime now,
    required AuthStatus authStatus,
    required bool liveActivityEnabled,
    required bool streakAlertsEnabled,
    required bool redactTitleOnLockScreen,
    required String locale,
    required List<WidgetJourneyItem> journeys,
    String? dismissedWindowKey,
    Set<String> dismissedWindowKeys = const {},
    WidgetLiveWindow? previousActiveWindow,
  }) {
    if (!liveActivityEnabled ||
        authStatus == AuthStatus.signedOut ||
        journeys.isEmpty) {
      return const LiveActivityPlan.end();
    }

    final nowUtc = now.toUtc();
    final isEn = locale.toLowerCase().startsWith('en');
    final normalizedLocale = isEn ? 'en' : 'vi';
    final totalActive = journeys.length;
    final pending = [
      for (final j in journeys)
        if (!j.checkedInToday) j,
    ];
    final completedCount = totalActive - pending.length;

    // Celebration transition when the last pending journey of the day is
    // completed while a Live Activity window was active (§6.2 #3).
    if (pending.isEmpty) {
      if (previousActiveWindow == null) {
        return const LiveActivityPlan.end();
      }
      final finishedJourney = journeys.firstWhere(
        (j) => j.id == previousActiveWindow.journeyId,
        orElse: () => journeys.first,
      );
      final celebrationPayload = <String, Object?>{
        'windowKey': previousActiveWindow.windowKey,
        'journeyId': finishedJourney.id,
        'journeyTitle': finishedJourney.title,
        'skinId': finishedJourney.skinId,
        'colorVariant': finishedJourney.colorVariant,
        'typeIcon': finishedJourney.typeIcon,
        'currentStreak': finishedJourney.currentStreak,
        'atRisk': false,
        'pendingCount': 0,
        'completedCount': totalActive,
        'totalActiveCount': totalActive,
        'windowStartUtc': previousActiveWindow.windowStartUtc,
        'deadlineUtc': previousActiveWindow.deadlineUtc,
        'locale': normalizedLocale,
        'redactTitleOnLockScreen': redactTitleOnLockScreen,
        'celebrateAndDismiss': true,
        'isCompletedCelebration': true,
        'snapLabel': isEn ? 'Snap now' : 'Chụp ngay',
        'dismissLabel': isEn ? 'Dismiss' : 'Ẩn hôm nay',
        'statusText': isEn
            ? 'All checked in! Streak ${finishedJourney.currentStreak}'
            : 'Đã hoàn tất hôm nay! Chuỗi ${finishedJourney.currentStreak} ngày',
        'shortCriticalText': isEn ? 'Done' : 'Xong',
        'publicFallbackTitle': isEn
            ? 'Ourney · Check-in window'
            : 'Ourney · Khung giờ check-in',
      };
      return LiveActivityPlan(
        action: LiveActivityAction.celebrateAndDismiss,
        window: null,
        channelPayload: celebrationPayload,
      );
    }

    final dismissed = <String>{
      ...dismissedWindowKeys,
      if (dismissedWindowKey != null && dismissedWindowKey.isNotEmpty)
        dismissedWindowKey,
    };

    for (final j in pending) {
      final deadlineUtc = DateTime.parse(j.midnightRolloverUtc).toUtc();
      if (!nowUtc.isBefore(deadlineUtc)) continue;

      final DateTime? rawStartUtc;
      if (j.reminderAtUtc != null) {
        final reminderUtc = DateTime.parse(j.reminderAtUtc!).toUtc();
        rawStartUtc = reminderUtc.subtract(kReminderWindowLead);
      } else if (streakAlertsEnabled && j.atRisk) {
        rawStartUtc = DateTime.parse(j.eveningCueAtUtc).toUtc();
      } else {
        rawStartUtc = null;
      }
      if (rawStartUtc == null) continue;

      final minStartUtc = deadlineUtc.subtract(kMaxLiveWindowDuration);
      final windowStartUtc = rawStartUtc.isBefore(minStartUtc)
          ? minStartUtc
          : rawStartUtc;
      if (!windowStartUtc.isBefore(deadlineUtc)) continue;

      // Eligible only when `now` is inside `[windowStartUtc, deadlineUtc)`.
      if (nowUtc.isBefore(windowStartUtc)) continue;

      final todayIso = j.weekStrip.isNotEmpty
          ? j.weekStrip.last.date
          : deadlineUtc
                .subtract(const Duration(hours: 12))
                .toIso8601String()
                .substring(0, 10);
      final windowKey = '$todayIso:${j.id}';
      if (dismissed.contains(windowKey)) continue;

      final window = WidgetLiveWindow(
        windowKey: windowKey,
        journeyId: j.id,
        journeyTitle: j.title,
        skinId: j.skinId,
        colorVariant: j.colorVariant,
        typeIcon: j.typeIcon,
        currentStreak: j.currentStreak,
        atRisk: j.atRisk,
        pendingCount: pending.length,
        completedCount: completedCount,
        totalActiveCount: totalActive,
        windowStartUtc: windowStartUtc.toIso8601String(),
        deadlineUtc: deadlineUtc.toIso8601String(),
      );

      final remaining = deadlineUtc.difference(nowUtc);
      final shortCritical = _formatShortCriticalText(remaining, isEn: isEn);
      final statusText = j.atRisk
          ? (isEn
                ? 'Keep your ${j.currentStreak}-day streak before midnight'
                : 'Giữ chuỗi ${j.currentStreak} ngày trước nửa đêm')
          : (isEn
                ? 'Day ${j.dayNumber} check-in window is open'
                : 'Khung giờ check-in ngày ${j.dayNumber} đang mở');

      final payload = <String, Object?>{
        ...window.toJson(),
        'locale': normalizedLocale,
        'redactTitleOnLockScreen': redactTitleOnLockScreen,
        'celebrateAndDismiss': false,
        'isCompletedCelebration': false,
        'snapLabel': isEn ? 'Snap now' : 'Chụp ngay',
        'dismissLabel': isEn ? 'Dismiss' : 'Ẩn hôm nay',
        'statusText': statusText,
        'shortCriticalText': shortCritical,
        'publicFallbackTitle': isEn
            ? 'Ourney · Check-in window'
            : 'Ourney · Khung giờ check-in',
      };

      return LiveActivityPlan(
        action: LiveActivityAction.startOrUpdate,
        window: window,
        channelPayload: payload,
      );
    }

    return const LiveActivityPlan.end();
  }

  /// Formats the Android 16 status-bar chip critical text (`<= 7` chars, §1.2).
  static String _formatShortCriticalText(
    Duration remaining, {
    required bool isEn,
  }) {
    final totalMinutes = remaining.inMinutes.clamp(1, 360);
    if (totalMinutes >= 60) {
      final hours = (totalMinutes / 60).ceil();
      return isEn ? '${hours}h left' : 'Còn ${hours}g';
    }
    return isEn ? '${totalMinutes}m' : '${totalMinutes}p';
  }
}
