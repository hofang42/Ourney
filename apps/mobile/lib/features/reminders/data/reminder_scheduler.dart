import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../app/providers.dart';
import '../domain/reminder_plan.dart';
import '../l10n/generated/reminders_localizations.dart';
import 'notification_gateway.dart';
import 'reminder_settings.dart';

/// Notification ids owned by the reminders feature:
/// `[kReminderIdBase, kReminderIdBase + kMaxPendingNotifications)`. Other
/// features must not use this range; anything else pending is left alone.
const int kReminderIdBase = 41000;

bool _isReminderId(int id) =>
    id >= kReminderIdBase && id < kReminderIdBase + kMaxPendingNotifications;

const Duration _readTimeout = Duration(seconds: 5);

void _ensureTimeZones() {
  if (!tz.timeZoneDatabase.isInitialized) tzdata.initializeTimeZones();
}

/// Wall clock used for planning. Override in tests.
final remindersClockProvider = Provider<Clock>((ref) => const Clock());

/// Device IANA zone (the user's wall clock for reminder times). Override in
/// tests: it uses a platform channel.
final reminderDeviceTimezoneProvider = FutureProvider<String>((ref) async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    if (info.identifier.isNotEmpty) return info.identifier;
  } on Object {
    // Unsupported platform or channel missing: fall through.
  }
  return 'Etc/UTC';
}, retry: (_, _) => null);

/// Builds the plan from the repositories and settings, then replaces the
/// pending reminder notifications with it (FR-G1, FR-G2).
///
/// Call [reschedule] on app start/resume and after every check-in, journey
/// change or settings change. Calls are serialised; failures (data layer not
/// wired, plugin missing, offline) are logged and leave the previous
/// schedule in place.
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;
  Future<void> _last = Future.value();

  NotificationGateway get _gateway => _ref.read(notificationGatewayProvider);

  Future<void> reschedule() {
    final next = _last.then((_) => _reschedule());
    _last = next.catchError((Object _) {});
    return _last;
  }

  Future<void> _reschedule() async {
    try {
      final gateway = _gateway;
      await gateway.initialize();
      final planned = await gateway.isPermissionGranted()
          ? await buildPlan()
          : const <PlannedNotification>[];
      await _apply(gateway, planned);
    } on Object catch (e, st) {
      debugPrint('reminders: reschedule skipped: $e');
      if (e is! UnimplementedError) debugPrintStack(stackTrace: st);
    }
  }

  /// The notifications that should be pending right now.
  Future<List<PlannedNotification>> buildPlan() async {
    _ensureTimeZones();
    final settings = _ref.read(reminderSettingsProvider);
    final streakAlerts = _ref.read(streakAlertsEnabledProvider);
    final journeys = await _ref
        .read(journeyRepositoryProvider)
        .watchActive()
        .first
        .timeout(_readTimeout);
    final inputs = <JourneyReminderInput>[];
    for (final j in journeys) {
      if (j.status != JourneyStatus.active) continue;
      final time = settings[j.id]?.activeTime;
      if (time == null && !streakAlerts) continue;
      inputs.add(await _inputFor(j, time));
    }
    final deviceTz = await _ref.read(reminderDeviceTimezoneProvider.future);
    return planReminders(
      now: _ref.read(remindersClockProvider).now(),
      deviceTimezone: deviceTz,
      journeys: inputs,
      streakAlerts: streakAlerts,
    );
  }

  Future<JourneyReminderInput> _inputFor(Journey j, ReminderTime? time) async {
    final uid = _ref.read(currentUserIdProvider);
    Membership? membership;
    try {
      membership = await _ref
          .read(journeyRepositoryProvider)
          .watchMyMembership(j.id)
          .first
          .timeout(_readTimeout);
    } on Object {
      membership = null; // Fall back to the journey start.
    }
    final checkIns = await _ref
        .read(checkInRepositoryProvider)
        .watchForJourney(j.id, userId: uid)
        .first
        .timeout(_readTimeout);
    return JourneyReminderInput.fromJourney(
      j,
      checkedInDates: [
        for (final c in checkIns)
          if (uid == null || c.userId == uid) c.localDate,
      ],
      joinedLocalDate: membership == null
          ? null
          : localDateIn(j.timezone, membership.joinedAt),
      reminderTime: time,
    );
  }

  Future<void> _apply(
    NotificationGateway gateway,
    List<PlannedNotification> planned,
  ) async {
    final pending = await gateway.pendingIds();
    for (final id in pending.where(_isReminderId)) {
      await gateway.cancel(id);
    }
    final l10n = lookupRemindersL10n(_ref.read(reminderLocaleProvider));
    for (var i = 0; i < planned.length && i < kMaxPendingNotifications; i++) {
      final p = planned[i];
      final isAlert = p.kind == PlannedKind.streakAlert;
      await gateway.schedule(
        NotificationRequest(
          id: kReminderIdBase + i,
          fireAt: p.fireAt,
          title: isAlert
              ? l10n.reminders_alertTitle
              : l10n.reminders_notifTitle,
          body: isAlert
              ? l10n.reminders_alertBody(p.journeyTitle, p.streak)
              : l10n.reminders_notifBody(p.journeyTitle),
          payload: p.journeyId,
        ),
      );
    }
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  ReminderScheduler.new,
);

/// Rebuilds the reminder schedule. Call after a check-in is saved (the day
/// is then skipped and the 21:00 alert moves to tomorrow), and whenever
/// journeys change. Never throws.
Future<void> rescheduleReminders(WidgetRef ref) =>
    ref.read(reminderSchedulerProvider).reschedule();

/// Wrap the app (e.g. in `MaterialApp.router(builder: ...)`) to reschedule
/// reminders on start and on every resume, and to route notification taps.
/// [onOpenJourney] receives the journey id of a tapped reminder (also when
/// the tap launched the app).
class ReminderLifecycleHook extends ConsumerStatefulWidget {
  const ReminderLifecycleHook({
    required this.child,
    this.onOpenJourney,
    super.key,
  });

  final Widget child;
  final void Function(String journeyId)? onOpenJourney;

  @override
  ConsumerState<ReminderLifecycleHook> createState() =>
      _ReminderLifecycleHookState();
}

class _ReminderLifecycleHookState extends ConsumerState<ReminderLifecycleHook>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final gateway = ref.read(notificationGatewayProvider);
      await gateway.initialize(onTap: _open);
      final launch = await gateway.launchPayload();
      if (launch != null) _open(launch);
    } on Object catch (e) {
      debugPrint('reminders: notifications unavailable: $e');
    }
    if (!mounted) return;
    await ref.read(reminderSchedulerProvider).reschedule();
  }

  void _open(String journeyId) {
    if (mounted) widget.onOpenJourney?.call(journeyId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(reminderSchedulerProvider).reschedule());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
