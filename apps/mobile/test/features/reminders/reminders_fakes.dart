import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/features/reminders/data/notification_gateway.dart';
import 'package:ourney/features/reminders/data/reminder_scheduler.dart';
import 'package:ourney/features/reminders/ui/reminders_screen.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/test_helpers.dart';

const hcm = 'Asia/Ho_Chi_Minh';

/// 2026-10-16 10:00 in Ho Chi Minh City.
final reminderNow = DateTime.utc(2026, 10, 16, 3);

Journey reminderJourney({
  String id = 'j1',
  String title = 'Tập mỗi ngày',
  JourneyStatus status = JourneyStatus.active,
  LocalDate start = const LocalDate(2026, 10, 1),
  int? durationDays = 60,
}) => Journey(
  id: id,
  ownerId: 'u1',
  kind: JourneyKind.solo,
  templateId: TemplateId.custom,
  title: title,
  emoji: '💪',
  startDate: start,
  durationDays: durationDays,
  timezone: hcm,
  visibility: JourneyVisibility.private,
  status: status,
);

CheckIn reminderCheckIn(
  String journeyId,
  LocalDate day, {
  String user = 'u1',
}) => CheckIn(
  id: '$journeyId-$day',
  journeyId: journeyId,
  userId: user,
  localDate: day,
  capturedAt: DateTime.utc(day.year, day.month, day.day, 2),
  photoPath: 'p',
  thumbPath: 't',
);

class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({this.granted = false, this.grantOnRequest = true});

  bool granted;
  bool grantOnRequest;
  int requests = 0;
  int settingsOpened = 0;
  int initializeCalls = 0;
  final Map<int, NotificationRequest> scheduled = {};
  void Function(String payload)? onTap;
  String? launch;

  /// Pending notifications of other features (must survive a reschedule).
  final Set<int> foreign = {};

  @override
  Future<void> initialize({void Function(String payload)? onTap}) async {
    initializeCalls++;
    if (onTap != null) this.onTap = onTap;
  }

  @override
  Future<String?> launchPayload() async => launch;

  @override
  Future<bool> isPermissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async {
    requests++;
    granted = grantOnRequest;
    return granted;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<List<int>> pendingIds() async => [...foreign, ...scheduled.keys];

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    foreign.remove(id);
  }

  @override
  Future<void> schedule(NotificationRequest request) async =>
      scheduled[request.id] = request;
}

class FakeReminderJourneyRepository implements JourneyRepository {
  FakeReminderJourneyRepository(this.journeys, {this.fail = false});

  List<Journey> journeys;
  bool fail;
  final Map<String, Membership> memberships = {};

  @override
  Stream<List<Journey>> watchActive() =>
      fail ? Stream.error(StateError('offline')) : Stream.value(journeys);

  @override
  Stream<Journey?> watch(String journeyId) =>
      Stream.value(journeys.where((j) => j.id == journeyId).firstOrNull);

  @override
  Stream<Membership?> watchMyMembership(String journeyId) =>
      Stream.value(memberships[journeyId]);

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeReminderCheckInRepository implements CheckInRepository {
  final Map<String, List<CheckIn>> byJourney = {};

  @override
  Stream<List<CheckIn>> watchForJourney(String journeyId, {String? userId}) =>
      Stream.value(byJourney[journeyId] ?? const []);

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class ReminderHarness {
  ReminderHarness({
    required this.container,
    required this.gateway,
    required this.journeys,
    required this.checkIns,
    required this.prefs,
  });

  final ProviderContainer container;
  final FakeNotificationGateway gateway;
  final FakeReminderJourneyRepository journeys;
  final FakeReminderCheckInRepository checkIns;
  final SharedPreferencesWithCache prefs;
}

Future<ReminderHarness> reminderHarness({
  List<Journey>? journeys,
  FakeNotificationGateway? gateway,
  Map<String, Object> prefs = const {},
  bool failJourneys = false,
  bool unwiredJourneys = false,
  Locale locale = const Locale('vi'),
  List<Override> overrides = const [],
}) async {
  final p = await testPrefs(prefs);
  final g = gateway ?? FakeNotificationGateway();
  final jr = FakeReminderJourneyRepository(
    journeys ?? [reminderJourney()],
    fail: failJourneys,
  );
  final cr = FakeReminderCheckInRepository();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(const AppConfig.localOnly()),
      sharedPreferencesProvider.overrideWithValue(p),
      if (unwiredJourneys)
        journeyRepositoryProvider.overrideWith(
          (ref) => throw UnimplementedError('B1'),
        )
      else
        journeyRepositoryProvider.overrideWithValue(jr),
      checkInRepositoryProvider.overrideWithValue(cr),
      notificationGatewayProvider.overrideWithValue(g),
      reminderDeviceTimezoneProvider.overrideWith((ref) async => hcm),
      remindersClockProvider.overrideWithValue(Clock.fixed(reminderNow)),
      reminderLocaleProvider.overrideWithValue(locale),
      ...overrides,
    ],
  );
  return ReminderHarness(
    container: container,
    gateway: g,
    journeys: jr,
    checkIns: cr,
    prefs: p,
  );
}

Widget remindersApp(ReminderHarness h, {Locale locale = const Locale('vi')}) =>
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        locale: locale,
        localizationsDelegates: ourneyLocalizationsDelegates,
        supportedLocales: ourneySupportedLocales,
        home: const RemindersScreen(),
      ),
    );
