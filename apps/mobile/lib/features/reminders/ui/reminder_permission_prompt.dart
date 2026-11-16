import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../onboarding/permission_sheets.dart' show showNotificationSheet;
import '../data/notification_gateway.dart';
import '../data/reminder_permission.dart';
import '../data/reminder_scheduler.dart';
import '../data/reminder_settings.dart';
import '../domain/reminder_plan.dart';

/// In-context notification offer (V2 `PermissionSheet kind="notification"`,
/// prototype `create.tsx` reminder toggle and the first check-in).
///
/// Reminders are switched on outside the reminders screen (the quiz's
/// reminder time is saved when a journey is created; the 21:00 streak alert
/// is on by default), but the OS permission used to be asked only from
/// `/reminders`. Without it the scheduler plans nothing, so no reminder was
/// ever delivered. Call this right after such a moment:
///
/// * does nothing when notifications are already allowed, the OS prompt was
///   already shown once, the sheet was already offered, or the plugin is not
///   available (tests, unsupported platforms);
/// * otherwise shows the sheet once (FR-A3: the person sees why first) and,
///   on "Allow", the OS prompt, then rebuilds the schedule.
///
/// Returns whether notifications are allowed afterwards. Never throws.
Future<bool> offerReminderPermission(
  BuildContext context,
  WidgetRef ref, {
  ReminderTime? time,
}) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final gateway = ref.read(notificationGatewayProvider);
  // Read before any await: the caller may navigate away meanwhile.
  final scheduler = ref.read(reminderSchedulerProvider);
  bool granted;
  try {
    granted = await gateway.isPermissionGranted();
  } on Object {
    return false; // Plugin unavailable: nothing to offer.
  }
  if (granted) return true;
  final alreadyAsked =
      (prefs.getBool(ReminderPrefs.permissionAsked) ?? false) ||
      (prefs.getBool(ReminderPrefs.promptOffered) ?? false);
  if (alreadyAsked || !context.mounted) return false;

  await prefs.setBool(ReminderPrefs.promptOffered, true);
  if (!context.mounted) return false;
  final allow = await showNotificationSheet(
    context,
    timeLabel: (time ?? kStreakAlertTime).toString(),
  );
  if (!allow || !context.mounted) return false;
  final ok = await requestReminderPermission(ref);
  await scheduler.reschedule();
  return ok;
}

/// The time to show in the offer for [journeyId]: its own reminder when on,
/// else the 21:00 streak alert.
ReminderTime reminderOfferTime(WidgetRef ref, String journeyId) =>
    ref.read(reminderSettingsProvider)[journeyId]?.activeTime ??
    kStreakAlertTime;
