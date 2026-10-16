import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import 'notification_gateway.dart';
import 'reminder_settings.dart';

/// Current notification permission. `notDetermined` until the prompt has
/// been shown once from the reminders screen (we never ask at app start,
/// FR-A3). Invalidate it after returning from system settings.
final reminderPermissionProvider =
    FutureProvider.autoDispose<NotificationPermission>((ref) async {
      final gateway = ref.watch(notificationGatewayProvider);
      try {
        if (await gateway.isPermissionGranted()) {
          return NotificationPermission.granted;
        }
      } on Object {
        // Plugin unavailable (e.g. unsupported platform): treat as not granted.
      }
      final asked =
          ref
              .watch(sharedPreferencesProvider)
              .getBool(ReminderPrefs.permissionAsked) ??
          false;
      return asked
          ? NotificationPermission.denied
          : NotificationPermission.notDetermined;
    }, retry: (_, _) => null);

/// Shows the OS prompt once and remembers that it was shown. Returns
/// whether notifications are allowed afterwards.
Future<bool> requestReminderPermission(WidgetRef ref) async {
  final gateway = ref.read(notificationGatewayProvider);
  await ref
      .read(sharedPreferencesProvider)
      .setBool(ReminderPrefs.permissionAsked, true);
  bool granted;
  try {
    granted = await gateway.requestPermission();
  } on Object {
    granted = false;
  }
  ref.invalidate(reminderPermissionProvider);
  return granted;
}
