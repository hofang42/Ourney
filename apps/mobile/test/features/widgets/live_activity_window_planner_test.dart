import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/redirect.dart' show AuthStatus;
import 'package:ourney/features/widgets/domain/live_activity_planner.dart';
import 'package:ourney/features/widgets/domain/widget_snapshot.dart';

WidgetJourneyItem _journeyItem({
  String id = 'j-1',
  String title = 'Tự học IELTS 30 ngày',
  bool checkedInToday = false,
  bool atRisk = true,
  int currentStreak = 14,
  bool isSensitive = false,
  String eveningCueAtUtc = '2026-11-24T11:00:00.000Z', // 18:00 ICT
  String streakAlertAtUtc = '2026-11-24T14:00:00.000Z', // 21:00 ICT
  String midnightRolloverUtc = '2026-11-24T17:00:00.000Z', // 24:00 ICT
  String? reminderAtUtc,
}) => WidgetJourneyItem(
  id: id,
  title: title,
  kind: 'group',
  skinId: 'squad',
  colorVariant: 0,
  typeIcon: 'type-study',
  timezone: 'Asia/Ho_Chi_Minh',
  utcOffsetMinutes: 420,
  pinned: true,
  dayNumber: 15,
  totalDays: 30,
  currentStreak: currentStreak,
  bestStreak: 14,
  checkedInToday: checkedInToday,
  atRisk: atRisk,
  eveningCueAtUtc: eveningCueAtUtc,
  streakAlertAtUtc: streakAlertAtUtc,
  midnightRolloverUtc: midnightRolloverUtc,
  reminderAtUtc: reminderAtUtc,
  heroThumbFile: null,
  heroThumbBlurred: false,
  isSensitive: isSensitive,
  weekStrip: const [
    WidgetWeekDayItem(
      date: '2026-11-24',
      day: 24,
      label: 'HN',
      state: 'today',
    ),
  ],
);

void main() {
  group('LiveActivityWindowPlanner (§6.2, §8.3)', () {
    test('opens window at [reminderTime - 30m, midnight) when reminder is set', () {
      // Reminder at 20:00 ICT (13:00Z) -> window opens at 19:30 ICT (12:30Z).
      final item = _journeyItem(
        atRisk: false,
        reminderAtUtc: '2026-11-24T13:00:00.000Z',
      );

      // Before 12:30Z: not eligible yet.
      final beforePlan = LiveActivityWindowPlanner.plan(
        now: DateTime.utc(2026, 11, 24, 12, 29),
        authStatus: AuthStatus.signedIn,
        liveActivityEnabled: true,
        streakAlertsEnabled: true,
        redactTitleOnLockScreen: false,
        locale: 'vi',
        journeys: [item],
      );
      expect(beforePlan.action, LiveActivityAction.endImmediate);
      expect(beforePlan.window, isNull);

      // At 12:30Z: eligible!
      final activePlan = LiveActivityWindowPlanner.plan(
        now: DateTime.utc(2026, 11, 24, 12, 30),
        authStatus: AuthStatus.signedIn,
        liveActivityEnabled: true,
        streakAlertsEnabled: true,
        redactTitleOnLockScreen: false,
        locale: 'vi',
        journeys: [item],
      );
      expect(activePlan.action, LiveActivityAction.startOrUpdate);
      expect(activePlan.window, isNotNull);
      expect(activePlan.window!.windowKey, '2026-11-24:j-1');
      expect(activePlan.window!.windowStartUtc, '2026-11-24T12:30:00.000Z');
      expect(activePlan.window!.deadlineUtc, '2026-11-24T17:00:00.000Z');
      expect(activePlan.channelPayload!['shortCriticalText'], 'Còn 5g');
    });

    test('clamps early morning reminder window to at most 6 hours before midnight', () {
      // Reminder at 08:00 ICT (01:00Z), midnight at 17:00Z -> clamped to 11:00Z (18:00 ICT).
      final item = _journeyItem(
        atRisk: false,
        reminderAtUtc: '2026-11-24T01:00:00.000Z',
      );

      final earlyMorning = LiveActivityWindowPlanner.plan(
        now: DateTime.utc(2026, 11, 24, 9, 0),
        authStatus: AuthStatus.signedIn,
        liveActivityEnabled: true,
        streakAlertsEnabled: true,
        redactTitleOnLockScreen: false,
        locale: 'en',
        journeys: [item],
      );
      expect(earlyMorning.window, isNull);

      final eveningPlan = LiveActivityWindowPlanner.plan(
        now: DateTime.utc(2026, 11, 24, 11, 15),
        authStatus: AuthStatus.signedIn,
        liveActivityEnabled: true,
        streakAlertsEnabled: true,
        redactTitleOnLockScreen: false,
        locale: 'en',
        journeys: [item],
      );
      expect(eveningPlan.action, LiveActivityAction.startOrUpdate);
      expect(eveningPlan.window!.windowStartUtc, '2026-11-24T11:00:00.000Z');
      expect(eveningPlan.channelPayload!['shortCriticalText'], '6h left');
    });

    test('opens [18:00, midnight) window when atRisk and streakAlertsEnabled without daily reminder', () {
      final item = _journeyItem(atRisk: true, reminderAtUtc: null);

      final plan = LiveActivityWindowPlanner.plan(
        now: DateTime.utc(2026, 11, 24, 11, 0), // 18:00 ICT
        authStatus: AuthStatus.signedIn,
        liveActivityEnabled: true,
        streakAlertsEnabled: true,
        redactTitleOnLockScreen: true,
        locale: 'vi',
        journeys: [item],
      );
      expect(plan.action, LiveActivityAction.startOrUpdate);
      expect(plan.window, isNotNull);
      expect(plan.channelPayload!['redactTitleOnLockScreen'], isTrue);
      expect(plan.channelPayload!['redactLockScreenTitles'], isTrue);
    });

    test(
      'falls back to eveningCueAtUtc (18:00) when reminderAtUtc is after midnightRolloverUtc and journey is atRisk (P1-1)',
      () {
        final item = _journeyItem(
          atRisk: true,
          reminderAtUtc: '2026-11-25T01:00:00.000Z', // past 17:00Z deadline
        );

        final plan = LiveActivityWindowPlanner.plan(
          now: DateTime.utc(2026, 11, 24, 12, 0), // 19:00 ICT (after 18:00 ICT)
          authStatus: AuthStatus.signedIn,
          liveActivityEnabled: true,
          streakAlertsEnabled: true,
          redactLockScreenTitles: true,
          locale: 'vi',
          journeys: [item],
        );
        expect(plan.action, LiveActivityAction.startOrUpdate);
        expect(plan.window, isNotNull);
        expect(plan.window!.windowStartUtc, '2026-11-24T11:00:00.000Z');
        expect(plan.channelPayload!['redactLockScreenTitles'], isTrue);
        expect(plan.channelPayload!['redactTitleOnLockScreen'], isTrue);
      },
    );

    test('suppresses window when liveActivityEnabled is false, signedOut, or dismissedWindowKey matches', () {
      final item = _journeyItem(atRisk: true);
      final now = DateTime.utc(2026, 11, 24, 14, 0);

      expect(
        LiveActivityWindowPlanner.plan(
          now: now,
          authStatus: AuthStatus.signedIn,
          liveActivityEnabled: false,
          streakAlertsEnabled: true,
          redactTitleOnLockScreen: false,
          locale: 'vi',
          journeys: [item],
        ).window,
        isNull,
      );

      expect(
        LiveActivityWindowPlanner.plan(
          now: now,
          authStatus: AuthStatus.signedOut,
          liveActivityEnabled: true,
          streakAlertsEnabled: true,
          redactTitleOnLockScreen: false,
          locale: 'vi',
          journeys: [item],
        ).window,
        isNull,
      );

      expect(
        LiveActivityWindowPlanner.plan(
          now: now,
          authStatus: AuthStatus.signedIn,
          liveActivityEnabled: true,
          streakAlertsEnabled: true,
          redactTitleOnLockScreen: false,
          locale: 'vi',
          journeys: [item],
          dismissedWindowKey: '2026-11-24:j-1',
        ).window,
        isNull,
      );
    });

    test('transitions to celebrateAndDismiss when the last pending journey completes', () {
      final openPlan = LiveActivityWindowPlanner.plan(
        now: DateTime.utc(2026, 11, 24, 14, 0),
        authStatus: AuthStatus.signedIn,
        liveActivityEnabled: true,
        streakAlertsEnabled: true,
        redactTitleOnLockScreen: false,
        locale: 'en',
        journeys: [_journeyItem(checkedInToday: false, currentStreak: 14)],
      );
      expect(openPlan.window, isNotNull);

      final completedPlan = LiveActivityWindowPlanner.plan(
        now: DateTime.utc(2026, 11, 24, 14, 5),
        authStatus: AuthStatus.signedIn,
        liveActivityEnabled: true,
        streakAlertsEnabled: true,
        redactTitleOnLockScreen: false,
        locale: 'en',
        journeys: [
          _journeyItem(checkedInToday: true, atRisk: false, currentStreak: 15),
        ],
        previousActiveWindow: openPlan.window,
      );
      expect(completedPlan.action, LiveActivityAction.celebrateAndDismiss);
      expect(completedPlan.window, isNull);
      expect(completedPlan.channelPayload, isNotNull);
      expect(completedPlan.channelPayload!['celebrateAndDismiss'], isTrue);
      expect(completedPlan.channelPayload!['isCompletedCelebration'], isTrue);
      expect(
        completedPlan.channelPayload!['statusText'],
        'All checked in! Streak 15',
      );
    });

    test(
      'sensitive journey always redacts Lock Screen Live Activity title even when toggle is OFF',
      () {
        final sensitivePending = _journeyItem(
          id: 'j-weight',
          title: 'Giảm cân 60 ngày',
          isSensitive: true,
          atRisk: true,
        );
        final plan = LiveActivityWindowPlanner.plan(
          now: DateTime.utc(2026, 11, 24, 14, 0),
          authStatus: AuthStatus.signedIn,
          liveActivityEnabled: true,
          streakAlertsEnabled: true,
          redactLockScreenTitles: false,
          locale: 'vi',
          journeys: [sensitivePending],
        );
        expect(plan.action, LiveActivityAction.startOrUpdate);
        expect(plan.window!.isSensitive, isTrue);
        expect(plan.window!.toJson()['isSensitive'], isTrue);
        expect(plan.channelPayload!['isSensitive'], isTrue);
        expect(plan.channelPayload!['redactLockScreenTitles'], isTrue);
        expect(plan.channelPayload!['redactTitleOnLockScreen'], isTrue);
      },
    );
  });
}
