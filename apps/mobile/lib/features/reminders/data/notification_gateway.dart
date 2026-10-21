import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/generated/reminders_localizations.dart';

/// Permission state as the reminders UI needs it.
enum NotificationPermission {
  granted,

  /// Refused (or switched off in system settings).
  denied,

  /// Never asked on this device (the prompt has not been shown yet).
  notDetermined,
}

/// One notification to schedule (absolute instant).
class NotificationRequest {
  const NotificationRequest({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;

  /// UTC instant.
  final DateTime fireAt;
  final String title;
  final String body;

  /// Journey id; opened when the notification is tapped.
  final String payload;
}

/// Everything the reminders feature needs from the OS. The real
/// implementation wraps flutter_local_notifications; tests use a fake.
abstract interface class NotificationGateway {
  /// Idempotent. Never shows a permission prompt (FR-A3). [onTap] gets the
  /// payload of a notification tapped while the app runs.
  Future<void> initialize({void Function(String payload)? onTap});

  /// Payload of the notification that launched the app, if any.
  Future<String?> launchPayload();

  /// Whether the OS currently lets the app post notifications.
  Future<bool> isPermissionGranted();

  /// Shows the OS prompt. Returns whether notifications are now allowed.
  Future<bool> requestPermission();

  /// Opens the app's notification settings (after a denial).
  Future<void> openSettings();

  /// Ids of the notifications currently pending.
  Future<List<int>> pendingIds();

  Future<void> cancel(int id);

  Future<void> schedule(NotificationRequest request);
}

/// Android channel for check-in reminders (docs/05 §5.2: "Nhắc check-in").
const String kReminderChannelId = 'checkin_reminders';

/// flutter_local_notifications 22.x implementation.
///
/// * iOS: initialised with every `request*Permission: false` so the prompt
///   only appears from [requestPermission] (in context, FR-A3).
/// * Android: inexact alarms (`inexactAllowWhileIdle`), so no
///   `SCHEDULE_EXACT_ALARM` permission is needed (docs/platform/android.md).
class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    required this.channelName,
    required this.channelDescription,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Localized channel name/description shown in Android settings.
  final String channelName;
  final String channelDescription;

  Future<void>? _init;
  void Function(String payload)? _onTap;

  @override
  Future<void> initialize({void Function(String payload)? onTap}) {
    if (onTap != null) _onTap = onTap;
    return _init ??= _plugin
        .initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestSoundPermission: false,
              requestBadgePermission: false,
            ),
          ),
          onDidReceiveNotificationResponse: (response) {
            final payload = response.payload;
            if (payload != null && payload.isNotEmpty) _onTap?.call(payload);
          },
        )
        .then((_) {});
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<String?> launchPayload() async {
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  @override
  Future<bool> isPermissionGranted() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.areNotificationsEnabled() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final options = await _ios?.checkPermissions();
      return options?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _ios?.requestPermissions(
            alert: true,
            sound: true,
            badge: true,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<void> openSettings() async {
    await initialize();
    await _plugin.openAppNotificationSettings();
  }

  @override
  Future<List<int>> pendingIds() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return [for (final p in pending) p.id];
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> schedule(NotificationRequest request) async {
    await initialize();
    await _plugin.zonedSchedule(
      id: request.id,
      title: request.title,
      body: request.body,
      payload: request.payload,
      // Absolute instant: UTC avoids depending on `tz.local`.
      scheduledDate: tz.TZDateTime.from(request.fireAt, tz.UTC),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          kReminderChannelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

/// Language of notification texts (scheduled outside any widget tree).
/// Follows the device language; Vietnamese unless it is English (NFR-6).
final reminderLocaleProvider = Provider<Locale>((ref) {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return Locale(code == 'en' ? 'en' : 'vi');
});

/// The OS gateway (flutter_local_notifications). Overridden in tests.
final notificationGatewayProvider = Provider<NotificationGateway>((ref) {
  final l10n = lookupRemindersL10n(ref.watch(reminderLocaleProvider));
  return LocalNotificationGateway(
    channelName: l10n.reminders_channelName,
    channelDescription: l10n.reminders_channelDescription,
  );
});
