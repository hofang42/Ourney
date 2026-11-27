import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/overlays/reminder_banner.dart';
import '../../../app/providers.dart';
import '../../../app/redirect.dart' show AuthStatus;
import '../../../personas/persona_contract.dart' show personaSkinOf;
import '../../../shared/time_zones.dart';
import '../../../ui/ui.dart' show uiSkinIdFor;
import '../../update/data/update_providers.dart';
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

/// Wall clock used for planning. Override in tests.
final remindersClockProvider = Provider<Clock>((ref) => const Clock());

/// Device IANA zone (the user's wall clock for reminder times). Override in
/// tests: it uses a platform channel.
final reminderDeviceTimezoneProvider = FutureProvider<String>((ref) async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    // e.g. Asia/Saigon -> Asia/Ho_Chi_Minh; unknown -> logged guess.
    if (info.identifier.isNotEmpty) {
      return resolveTimeZone(info.identifier).name;
    }
  } on Object {
    // Unsupported platform or channel missing: fall through.
  }
  return guessTimeZoneForOffset(DateTime.now().timeZoneOffset).name;
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

  /// Latest planned notifications after [reschedule], observed by
  /// [ReminderLifecycleHook] to trigger [ReminderBannerHost] in the foreground.
  final ValueNotifier<List<PlannedNotification>> lastPlanned = ValueNotifier(
    const [],
  );

  NotificationGateway get _gateway => _ref.read(notificationGatewayProvider);
  bool get _paused => _ref.read(appUpdateWorkPausedProvider);

  Future<void> reschedule() {
    final next = _last.then((_) => _reschedule());
    _last = next.catchError((Object _) {});
    return _last;
  }

  Future<void> _reschedule() async {
    try {
      if (_paused) return;
      final gateway = _gateway;
      await gateway.initialize();
      final deviceTz = await _ref.read(reminderDeviceTimezoneProvider.future);
      final planned = await gateway.isPermissionGranted()
          ? await buildPlan(deviceTimezone: deviceTz)
          : const <PlannedNotification>[];
      if (_paused) return;
      await _apply(gateway, planned, deviceTimezone: deviceTz);
      lastPlanned.value = List.unmodifiable(planned);
    } on Object catch (e, st) {
      debugPrint('reminders: reschedule skipped: $e');
      if (kDebugMode && e is! UnimplementedError) {
        debugPrintStack(stackTrace: st);
      }
    }
  }

  /// The notifications that should be pending right now.
  Future<List<PlannedNotification>> buildPlan({String? deviceTimezone}) async {
    // Signed out: nothing of the previous account may still fire (its cache
    // is being wiped).
    if (_ref.read(authStatusProvider) == AuthStatus.signedOut) {
      return const [];
    }
    ensureTimeZonesLoaded();
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
      final time = effectiveReminderSettingFor(j, settings).activeTime;
      if (time == null && !streakAlerts) continue;
      inputs.add(await _inputFor(j, time));
    }
    final String deviceTz =
        deviceTimezone ??
        await _ref.read(reminderDeviceTimezoneProvider.future);
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
    List<PlannedNotification> planned, {
    required String deviceTimezone,
  }) async {
    final l10n = lookupRemindersL10n(_ref.read(reminderLocaleProvider));
    for (var i = 0; i < planned.length && i < kMaxPendingNotifications; i++) {
      if (_paused) return;
      final p = planned[i];
      final isAlert = p.kind == PlannedKind.streakAlert;
      final String body;
      if (isAlert) {
        final deadline = p.deadlineLocalTime(deviceTimezone);
        body = deadline == const ReminderTime(0, 0)
            ? l10n.reminders_alertBody(p.journeyTitle)
            : l10n.reminders_alertBodyAt(
                p.journeyTitle,
                deadline.toString(),
              );
      } else {
        body = l10n.reminders_notifBody(p.journeyTitle);
      }
      await gateway.schedule(
        NotificationRequest(
          id: kReminderIdBase + i,
          fireAt: p.fireAt,
          title: isAlert
              ? l10n.reminders_alertTitle
              : l10n.reminders_notifTitle,
          body: body,
          payload: p.journeyId,
        ),
      );
    }
    // Schedule first, then drop only the ids the new plan no longer uses: a
    // failure in between leaves the old reminders (replaced by id) instead
    // of an empty schedule.
    final used = {
      for (var i = 0; i < planned.length && i < kMaxPendingNotifications; i++)
        kReminderIdBase + i,
    };
    final pending = await gateway.pendingIds();
    for (final id in pending.where(_isReminderId)) {
      if (_paused) return;
      if (!used.contains(id)) await gateway.cancel(id);
    }
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final scheduler = ReminderScheduler(ref);
  ref.onDispose(scheduler.lastPlanned.dispose);
  return scheduler;
});

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
  Timer? _bannerTimer;
  ValueNotifier<List<PlannedNotification>>? _plannedListenable;
  ({ReminderBannerData banner, LocalDate date, String journeyTimezone})?
  _shownStreak;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _plannedListenable = ref.read(reminderSchedulerProvider).lastPlanned;
    _plannedListenable!.addListener(_onPlanChanged);
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

  void _onPlanChanged() => _armNextBanner();

  void _armNextBanner([DateTime? afterUtc]) {
    _bannerTimer?.cancel();
    _bannerTimer = null;
    if (!mounted || !_foreground) return;
    final planned = _plannedListenable?.value ?? const <PlannedNotification>[];
    if (planned.isEmpty) return;
    final now = ref.read(remindersClockProvider).now().toUtc();
    final cutoff = afterUtc != null && afterUtc.isAfter(now) ? afterUtc : now;
    PlannedNotification? next;
    for (final p in planned) {
      final matches = afterUtc != null
          ? p.fireAt.isAfter(cutoff)
          : !p.fireAt.isBefore(cutoff);
      if (matches) {
        next = p;
        break;
      }
    }
    if (next == null) return;
    final delay = next.fireAt.difference(now);
    final target = next;
    _bannerTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => unawaited(_showBannerFor(target)),
    );
  }

  Future<void> _showBannerFor(PlannedNotification p) async {
    if (!mounted || !_foreground) return;
    var skinId = 'quiet';
    var day = 1;
    var name = p.journeyTitle;
    var journeyTimezone = p.journeyTimezone;
    try {
      final activeJourneys = await ref
          .read(journeyRepositoryProvider)
          .watchActive()
          .first
          .timeout(_readTimeout);
      if (!mounted) return;
      final now = ref.read(remindersClockProvider).now();
      Journey? journey;
      for (final j in activeJourneys) {
        if (j.id == p.journeyId) {
          journey = j;
          break;
        }
      }
      if (journey == null ||
          journey.status != JourneyStatus.active ||
          journey.isPastEndOn(localDateIn(journey.timezone, now))) {
        _armNextBanner(p.fireAt);
        return;
      }
      name = journey.title;
      journeyTimezone = journey.timezone;
      skinId = uiSkinIdFor(personaSkinOf(journey));
      final computedDay = journey.startDate.daysUntil(p.journeyDate) + 1;
      if (computedDay > 0) day = computedDay;
    } on Object {
      if (!mounted) return;
    }
    final deadline = await _deadlineFor(journeyTimezone, p.journeyDate);
    if (!mounted || !_foreground) return;
    final banner = ReminderBannerData(
      journeyId: p.journeyId,
      journeyName: name,
      skinId: skinId,
      kind: p.kind == PlannedKind.streakAlert
          ? ReminderBannerKind.streak
          : ReminderBannerKind.daily,
      streak: p.streak,
      day: day,
      deadline: deadline ?? '00:00',
    );
    ref.read(reminderBannerProvider.notifier).show(banner);
    _shownStreak = banner.kind == ReminderBannerKind.streak
        ? (
            banner: banner,
            date: p.journeyDate,
            journeyTimezone: journeyTimezone,
          )
        : null;
    _armNextBanner(p.fireAt);
  }

  Future<void> _refreshVisibleDeadline() async {
    final shown = _shownStreak;
    if (shown == null || ref.read(reminderBannerProvider) != shown.banner) {
      return;
    }
    final deadline = await _deadlineFor(shown.journeyTimezone, shown.date);
    final current = shown.banner;
    if (!mounted ||
        !_foreground ||
        deadline == null ||
        deadline == current.deadline ||
        ref.read(reminderBannerProvider) != current) {
      return;
    }
    final updated = ReminderBannerData(
      journeyId: current.journeyId,
      journeyName: current.journeyName,
      skinId: current.skinId,
      kind: current.kind,
      streak: current.streak,
      day: current.day,
      deadline: deadline,
    );
    _shownStreak = (
      banner: updated,
      date: shown.date,
      journeyTimezone: shown.journeyTimezone,
    );
    ref.read(reminderBannerProvider.notifier).show(updated);
  }

  Future<String?> _deadlineFor(String journeyTimezone, LocalDate date) async {
    try {
      final deviceTz = await ref.read(reminderDeviceTimezoneProvider.future);
      return streakDeadlineInDeviceZone(
        journeyTimezone: journeyTimezone,
        deviceTimezone: deviceTz,
        journeyDate: date,
      ).toString();
    } on Object {
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        ref.invalidate(reminderDeviceTimezoneProvider);
        unawaited(ref.read(reminderSchedulerProvider).reschedule());
        unawaited(_refreshVisibleDeadline());
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _foreground = false;
        _bannerTimer?.cancel();
        _bannerTimer = null;
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _plannedListenable?.removeListener(_onPlanChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pending notification texts are written at schedule time: rewrite them
    // in the language just picked in the app.
    ref.listen(reminderLocaleProvider, (prev, next) {
      if (prev != next) {
        unawaited(ref.read(reminderSchedulerProvider).reschedule());
      }
    });
    return widget.child;
  }
}
