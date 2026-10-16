# Reminders (C3): local check-in reminders + 21:00 streak alert

FR-G1, FR-G2. Screen at `/reminders` (`AppRoutes.reminders`).

- Per journey: on/off + time, prefs key `reminders.<journeyId>` (JSON
  `{"on": bool, "time": "HH:mm"}`). Global 21:00 alert switch:
  `reminders.streakAlerts` (default on). `reminders.permissionAsked` records
  that the OS prompt was shown.
- The notification permission is asked only when the user turns on the
  first reminder (or the alert), after a short in-app explanation (FR-A3).
  If denied, settings are still saved and a banner links to system settings.

## Planning (`domain/reminder_plan.dart`, pure Dart, unit-tested)

`planReminders(now, deviceTimezone, journeys, ...)`: rolling 14 days,
active journeys only, never before the member's start or after the journey
end, skips journey days already checked in, reminder times in the device's
wall clock, 21:00 alert in the journey's timezone when the streak (with no
further check-ins) is >= 1, nearest first, capped at 64 (iOS limit). DST:
gap times move forward by the gap, ambiguous times use the first occurrence.

## Scheduling (`data/reminder_scheduler.dart`)

`ReminderScheduler.reschedule()` reads journeys, memberships and check-ins
from the repositories, plans, cancels this feature's pending ids
(`41000..41063`, nothing else) and schedules the new set through
`NotificationGateway` (flutter_local_notifications 22.x, inexact Android
alarms, UTC `TZDateTime`). Serialised; failures (data layer not wired,
offline, plugin missing) keep the previous schedule.

## Integration hooks (wired in Wave D)

`OurneyApp` wraps the router with `ReminderLifecycleHook`; reschedules run
after a check-in, journey create / end / archive / delete, and group
join / leave / end / delete.

1. **After each check-in** (checkin feature, once `submit` returns):
   `await rescheduleReminders(ref);` (`WidgetRef`), or
   `ref.read(reminderSchedulerProvider).reschedule()` from a `Ref`.
   Also useful after creating/ending/deleting a journey.
2. **App start + resume + notification taps**: wrap the app, e.g. in
   `MaterialApp.router(builder: ...)`:
   ```dart
   builder: (context, child) => ReminderLifecycleHook(
     onOpenJourney: (id) => router.go(AppRoutes.journey(id)),
     child: OurneyTextScaleClamp(child: child ?? const SizedBox.shrink()),
   ),
   ```
   The payload of every notification is the journey id.

Tests override `notificationGatewayProvider`,
`reminderDeviceTimezoneProvider`, `remindersClockProvider` and
`reminderLocaleProvider`.
