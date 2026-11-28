import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:ourney_core/ourney_core.dart';

import '../../../app/redirect.dart' show AuthStatus;
import '../../../data/group_daily_checkins_provider.dart'
    show compareCheckIns, coupleMemberIds, isCoupleGroup;
import '../../../personas/persona_contract.dart' show personaSkinOf;
import '../../../shared/time_zones.dart';
import '../../../ui/components/avatar.dart' show UiAvatar;
import '../../../ui/journey_style_for.dart' show uiSkinIdFor;
import '../../groups/domain/group_today.dart';
import '../../journeys/domain/journey_progress.dart';
import '../../reminders/data/reminder_settings.dart';
import '../../reminders/domain/reminder_plan.dart';
import 'live_activity_planner.dart';
import 'widget_privacy.dart';

/// Current `snapshot_v1.json` schema version (§4.3).
const int kWidgetSnapshotSchemaVersion = 1;

/// Max side in pixels for a Today widget hero thumbnail (§1.2, §4.2, §4.4).
const int kWidgetHeroThumbMaxSide = 320;

/// Max side in pixels for a Squad grid thumbnail or member avatar (§1.2, §4.2, §4.4).
const int kWidgetGridThumbMaxSide = 160;

/// Evening warm reminder cue wall-clock time (`18:00` journey-local, §1.1, §4.5).
const ReminderTime kWidgetEveningCueTime = ReminderTime(18, 0);

/// Maps a [Journey] to one of the 6 exported `type-*` icon names (§4.3, §5.3.2).
String widgetTypeIconFor(Journey journey) {
  if (personaSkinOf(journey) == PersonaSkinId.coupleRituals ||
      journey.maxMembers == 2 ||
      journey.coupleSelfName != null) {
    return 'type-couple';
  }
  return switch (journey.templateId) {
    TemplateId.weightLoss => 'type-weight',
    TemplateId.englishDaily => 'type-study',
    TemplateId.travel => 'type-trip',
    TemplateId.workout30 => 'type-workout',
    TemplateId.custom => 'type-custom',
  };
}

/// Deterministic content-addressed filename `<sha256_16>.jpg` for a widget
/// thumbnail (§4.2, §4.4). Including [maxSide] and [blur] guarantees that
/// switching privacy mode never reuses an unblurred cached file for a blurred
/// request or vice versa.
String widgetThumbFileName({
  required String sourceKey,
  required int maxSide,
  required bool blur,
}) {
  final digest = sha256
      .convert(utf8.encode('$sourceKey|$maxSide|blur:$blur'))
      .toString();
  return '${digest.substring(0, 16)}.jpg';
}

/// One thumbnail image that must be prepared and passed in the `"thumbs"` array
/// of `MethodChannel('ourney/widgets').invokeMethod('syncSnapshot', ...)` (§4.4).
class WidgetThumbRequest {
  const WidgetThumbRequest({
    required this.id,
    required this.storagePath,
    required this.maxSide,
    required this.blur,
    this.localFilePath,
  });

  /// `<sha256_16>.jpg`.
  final String id;

  /// Canonical storage key or local path of the source media.
  final String storagePath;

  /// Optional already-known local file path on disk (e.g. `CheckIn.localPhotoFile`).
  final String? localFilePath;

  /// Target maximum short side (`320` for Today hero, `160` for Squad/avatar).
  final int maxSide;

  /// Whether the thumbnail must be pre-blurred (`sigma = 18`) before saving.
  final bool blur;

  /// Relative path stored inside `snapshot_v1.json` (`"thumbs/<sha256_16>.jpg"`).
  String get snapshotRelativePath => 'thumbs/$id';

  @override
  bool operator ==(Object other) =>
      other is WidgetThumbRequest &&
      other.id == id &&
      other.storagePath == storagePath &&
      other.localFilePath == localFilePath &&
      other.maxSide == maxSide &&
      other.blur == blur;

  @override
  int get hashCode =>
      Object.hash(id, storagePath, localFilePath, maxSide, blur);
}

/// One day cell in `WidgetJourneyItem.weekStrip` (7 days ending today, §4.3).
class WidgetWeekDayItem {
  const WidgetWeekDayItem({
    required this.date,
    required this.day,
    required this.label,
    required this.state,
  });

  /// `YYYY-MM-DD`.
  final String date;

  /// Day of month (`1..31`).
  final int day;

  /// Short localized label: `T2`..`T7`/`CN` (`HN` for today) in `vi`,
  /// `M`..`S` (`TD` for today) in `en`.
  final String label;

  /// `'done'` | `'today'` | `'missed'` | `'before'`.
  final String state;

  Map<String, Object?> toJson() => {
    'date': date,
    'day': day,
    'label': label,
    'state': state,
  };
}

/// One active journey serialized in `snapshot_v1.json -> journeys` (§4.3).
///
/// Privacy-by-omission: no `metricValue`, `metricUnit`, `dna`, or `caption`.
class WidgetJourneyItem {
  const WidgetJourneyItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.skinId,
    required this.colorVariant,
    required this.typeIcon,
    required this.timezone,
    required this.utcOffsetMinutes,
    required this.pinned,
    required this.dayNumber,
    required this.totalDays,
    required this.currentStreak,
    required this.bestStreak,
    required this.checkedInToday,
    required this.atRisk,
    required this.eveningCueAtUtc,
    required this.streakAlertAtUtc,
    required this.midnightRolloverUtc,
    required this.reminderAtUtc,
    required this.heroThumbFile,
    required this.heroThumbBlurred,
    required this.weekStrip,
    this.isSensitive = false,
  });

  final String id;
  final String title;
  final String kind;
  final String skinId;
  final int colorVariant;
  final String typeIcon;
  final String timezone;
  final int utcOffsetMinutes;
  final bool pinned;
  final int dayNumber;
  final int? totalDays;
  final int currentStreak;
  final int bestStreak;
  final bool checkedInToday;
  final bool atRisk;
  final String eveningCueAtUtc;
  final String streakAlertAtUtc;
  final String midnightRolloverUtc;
  final String? reminderAtUtc;
  final String? heroThumbFile;
  final bool heroThumbBlurred;
  final List<WidgetWeekDayItem> weekStrip;

  /// True when the journey is a weight-loss or default-hidden-metric journey
  /// (`WidgetPrivacyPolicy.isSensitiveMetricJourney`), allowing Lock Screen
  /// widgets pinned to a non-sensitive journey to display its title in smart
  /// mode while still redacting weight-loss titles (§B.5).
  final bool isSensitive;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'kind': kind,
    'skinId': skinId,
    'colorVariant': colorVariant,
    'typeIcon': typeIcon,
    'timezone': timezone,
    'utcOffsetMinutes': utcOffsetMinutes,
    'pinned': pinned,
    'dayNumber': dayNumber,
    if (totalDays != null) 'totalDays': totalDays,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'checkedInToday': checkedInToday,
    'atRisk': atRisk,
    'eveningCueAtUtc': eveningCueAtUtc,
    'streakAlertAtUtc': streakAlertAtUtc,
    'midnightRolloverUtc': midnightRolloverUtc,
    if (reminderAtUtc != null) 'reminderAtUtc': reminderAtUtc,
    if (heroThumbFile != null) 'heroThumbFile': heroThumbFile,
    'heroThumbBlurred': heroThumbBlurred,
    'isSensitive': isSensitive,
    'weekStrip': [for (final w in weekStrip) w.toJson()],
  };
}

/// One member entry inside `WidgetSquadItem.members` (§4.3).
class WidgetSquadMemberItem {
  const WidgetSquadMemberItem({
    required this.displayName,
    required this.initial,
    required this.avatarColorIndex,
    required this.isMe,
    required this.checkedInToday,
    required this.streak,
    required this.avatarFile,
    required this.todayThumbFile,
    required this.todayThumbBlurred,
    this.slotId,
    this.isVacant = false,
  });

  const WidgetSquadMemberItem.vacant({required String slotId})
    : this(
        displayName: '',
        initial: '',
        avatarColorIndex: 0,
        isMe: false,
        checkedInToday: false,
        streak: 0,
        avatarFile: null,
        todayThumbFile: null,
        todayThumbBlurred: false,
        slotId: slotId,
        isVacant: true,
      );

  final String displayName;
  final String initial;
  final int avatarColorIndex;
  final bool isMe;
  final bool checkedInToday;
  final int streak;
  final String? avatarFile;
  final String? todayThumbFile;
  final bool todayThumbBlurred;

  /// Account ID for an occupied Couple slot. Vacant slots use anonymous IDs.
  final String? slotId;
  final bool isVacant;

  Map<String, Object?> toJson() => {
    'displayName': displayName,
    'initial': initial,
    'avatarColorIndex': avatarColorIndex,
    'isMe': isMe,
    'checkedInToday': checkedInToday,
    'streak': streak,
    if (avatarFile != null) 'avatarFile': avatarFile,
    if (todayThumbFile != null) 'todayThumbFile': todayThumbFile,
    'todayThumbBlurred': todayThumbBlurred,
    if (slotId != null) 'slotId': slotId,
    if (isVacant) 'isVacant': true,
  };
}

/// One group/couple journey serialized in `snapshot_v1.json -> squads` (§4.3).
class WidgetSquadItem {
  const WidgetSquadItem({
    required this.journeyId,
    required this.title,
    required this.skinId,
    required this.colorVariant,
    required this.typeIcon,
    required this.isCouple,
    required this.dayNumber,
    required this.totalDays,
    required this.doneCount,
    required this.memberCount,
    required this.meCheckedInToday,
    required this.midnightRolloverUtc,
    required this.members,
  });

  final String journeyId;
  final String title;
  final String skinId;
  final int colorVariant;
  final String typeIcon;
  final bool isCouple;
  final int dayNumber;
  final int? totalDays;
  final int doneCount;
  final int memberCount;
  final bool meCheckedInToday;
  final String midnightRolloverUtc;
  final List<WidgetSquadMemberItem> members;

  Map<String, Object?> toJson() => {
    'journeyId': journeyId,
    'title': title,
    'skinId': skinId,
    'colorVariant': colorVariant,
    'typeIcon': typeIcon,
    'isCouple': isCouple,
    'dayNumber': dayNumber,
    if (totalDays != null) 'totalDays': totalDays,
    'doneCount': doneCount,
    'memberCount': memberCount,
    'meCheckedInToday': meCheckedInToday,
    'midnightRolloverUtc': midnightRolloverUtc,
    'members': [for (final m in members) m.toJson()],
  };
}

/// Evening / Reminder Check-In Window serialized in `snapshot_v1.json -> liveWindow` (§4.3).
class WidgetLiveWindow {
  const WidgetLiveWindow({
    required this.windowKey,
    required this.journeyId,
    required this.journeyTitle,
    required this.skinId,
    required this.colorVariant,
    required this.typeIcon,
    required this.currentStreak,
    required this.atRisk,
    required this.pendingCount,
    required this.completedCount,
    required this.totalActiveCount,
    required this.windowStartUtc,
    required this.deadlineUtc,
    this.isSensitive = false,
  });

  final String windowKey;
  final String journeyId;
  final String journeyTitle;
  final String skinId;
  final int colorVariant;
  final String typeIcon;
  final int currentStreak;
  final bool atRisk;
  final int pendingCount;
  final int completedCount;
  final int totalActiveCount;
  final String windowStartUtc;
  final String deadlineUtc;
  final bool isSensitive;

  Map<String, Object?> toJson() => {
    'windowKey': windowKey,
    'journeyId': journeyId,
    'journeyTitle': journeyTitle,
    'skinId': skinId,
    'colorVariant': colorVariant,
    'typeIcon': typeIcon,
    'currentStreak': currentStreak,
    'atRisk': atRisk,
    'pendingCount': pendingCount,
    'completedCount': completedCount,
    'totalActiveCount': totalActiveCount,
    'windowStartUtc': windowStartUtc,
    'deadlineUtc': deadlineUtc,
    'isSensitive': isSensitive,
  };
}

/// `snapshot_v1.json -> privacy` block (§4.3).
class WidgetPrivacySnapshot {
  const WidgetPrivacySnapshot({
    required this.photoMode,
    required this.redactLockScreenTitles,
    this.explicitRedactLockScreenTitles,
    required this.liveActivityEnabled,
  });

  final String photoMode;
  final bool redactLockScreenTitles;
  final bool? explicitRedactLockScreenTitles;
  final bool liveActivityEnabled;

  Map<String, Object?> toJson() => {
    'photoMode': photoMode,
    'redactLockScreenTitles': redactLockScreenTitles,
    if (explicitRedactLockScreenTitles == true)
      'explicitRedactLockScreenTitles': true,
    'liveActivityEnabled': liveActivityEnabled,
  };
}

/// `snapshot_v1.json -> totals` block (§4.3).
class WidgetTotalsSnapshot {
  const WidgetTotalsSnapshot({
    required this.activeCount,
    required this.completedTodayCount,
    required this.pendingTodayCount,
    required this.atRiskCount,
    required this.bestActiveStreak,
  });

  final int activeCount;
  final int completedTodayCount;
  final int pendingTodayCount;
  final int atRiskCount;
  final int bestActiveStreak;

  Map<String, Object?> toJson() => {
    'activeCount': activeCount,
    'completedTodayCount': completedTodayCount,
    'pendingTodayCount': pendingTodayCount,
    'atRiskCount': atRiskCount,
    'bestActiveStreak': bestActiveStreak,
  };
}

/// Full immutable representation of `snapshot_v1.json` (§4.3) plus the
/// content-addressed [thumbRequests] needed by native `syncSnapshot` (§4.4).
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.schemaVersion,
    required this.generatedAtUtc,
    required this.authState,
    required this.locale,
    required this.themeMode,
    required this.privacy,
    required this.defaultJourneyId,
    this.defaultSquadId,
    required this.totals,
    required this.journeys,
    required this.squads,
    required this.liveWindow,
    this.thumbRequests = const [],
  });

  final int schemaVersion;
  final String generatedAtUtc;
  final String authState;
  final String locale;
  final String themeMode;
  final WidgetPrivacySnapshot privacy;
  final String? defaultJourneyId;
  final String? defaultSquadId;
  final WidgetTotalsSnapshot totals;
  final List<WidgetJourneyItem> journeys;
  final List<WidgetSquadItem> squads;
  final WidgetLiveWindow? liveWindow;
  final List<WidgetThumbRequest> thumbRequests;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'generatedAtUtc': generatedAtUtc,
    'authState': authState,
    'locale': locale,
    'themeMode': themeMode,
    'privacy': privacy.toJson(),
    if (defaultJourneyId != null) 'defaultJourneyId': defaultJourneyId,
    if (defaultSquadId != null) 'defaultSquadId': defaultSquadId,
    'totals': totals.toJson(),
    'journeys': [for (final j in journeys) j.toJson()],
    'squads': [for (final s in squads) s.toJson()],
    if (liveWindow != null) 'liveWindow': liveWindow!.toJson(),
  };

  String toJsonString() => jsonEncode(toJson());

  /// Canonical SHA-256 digest of the snapshot content (excluding wall-clock
  /// [generatedAtUtc]) and sorted [thumbRequests], used by
  /// `WidgetSyncController` to suppress duplicate native bridge writes (§4.5).
  String computeContentDigest() {
    final map = toJson()..remove('generatedAtUtc');
    final thumbsMeta = [
      for (final t in thumbRequests)
        '${t.id}:${t.storagePath}:${t.maxSide}:${t.blur}',
    ]..sort();
    final payload = '${jsonEncode(map)}|${thumbsMeta.join(',')}';
    return sha256.convert(utf8.encode(payload)).toString();
  }
}

/// Input data for one journey passed to [WidgetSnapshotBuilder.build].
class WidgetJourneyBuildInput {
  const WidgetJourneyBuildInput({
    required this.journey,
    this.membership,
    this.myCheckIns = const [],
    this.groupMembers,
    this.groupCheckIns = const [],
  });

  final Journey journey;
  final Membership? membership;
  final List<CheckIn> myCheckIns;

  /// Non-null for group journeys when `group_today` rows are available.
  final List<MemberToday>? groupMembers;
  final List<CheckIn> groupCheckIns;
}

/// Pure, deterministic builder for [WidgetSnapshot] (`snapshot_v1.json`, §4.3).
abstract final class WidgetSnapshotBuilder {
  static const List<String> _viWeekdays = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  static const List<String> _enWeekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Short weekday label for [date] (`weekday` 1=Mon..7=Sun), or `'HN'` / `'TD'`
  /// when [isToday] is true (§4.3).
  static String weekdayLabel(
    LocalDate date, {
    required bool isToday,
    required String locale,
  }) {
    final isEn = locale.toLowerCase().startsWith('en');
    if (isToday) return isEn ? 'TD' : 'HN';
    final weekday = DateTime.utc(date.year, date.month, date.day).weekday;
    final idx = (weekday - 1).clamp(0, 6);
    return isEn ? _enWeekdays[idx] : _viWeekdays[idx];
  }

  /// Extracts a single uppercase initial for an avatar disc.
  static String initialFor(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  /// Builds a complete [WidgetSnapshot] and collects unique [WidgetThumbRequest]s.
  static WidgetSnapshot build({
    required DateTime now,
    required AuthStatus authStatus,
    required List<WidgetJourneyBuildInput> journeyInputs,
    String locale = 'vi',
    ThemeMode themeMode = ThemeMode.system,
    String? deviceTimezone,
    Set<String> pinnedJourneyIds = const {},
    Map<String, ReminderSetting> reminderSettings = const {},
    bool streakAlertsEnabled = true,
    WidgetPhotoMode photoMode = WidgetPhotoMode.smart,
    bool? explicitRedactLockScreenTitles,
    bool liveActivityEnabled = true,
    bool globalBlurPhotosOnShare = false,
    Set<String> blockedUserIds = const {},
    Set<String> hiddenCheckInIds = const {},
    String? currentUserId,
    String? dismissedWindowKey,
  }) {
    ensureTimeZonesLoaded();
    final nowUtc = now.toUtc();
    final normalizedLocale = locale.toLowerCase().startsWith('en')
        ? 'en'
        : 'vi';
    final normalizedTheme = switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    final activeInputs = <WidgetJourneyBuildInput>[];
    for (final input in journeyInputs) {
      final today = journeyLocalDate(input.journey.timezone, nowUtc);
      final settled = input.journey.settledOn(today);
      if (settled.status == JourneyStatus.active) {
        activeInputs.add(
          WidgetJourneyBuildInput(
            journey: settled,
            membership: input.membership,
            myCheckIns: input.myCheckIns,
            groupMembers: input.groupMembers,
            groupCheckIns: input.groupCheckIns,
          ),
        );
      }
    }

    final redactTitles = WidgetPrivacyPolicy.resolveRedactLockScreenTitles(
      explicitPreference: explicitRedactLockScreenTitles,
      activeJourneys: activeInputs.map((e) => e.journey),
    );

    if (authStatus == AuthStatus.signedOut) {
      return WidgetSnapshot(
        schemaVersion: kWidgetSnapshotSchemaVersion,
        generatedAtUtc: nowUtc.toIso8601String(),
        authState: 'signedOut',
        locale: normalizedLocale,
        themeMode: normalizedTheme,
        privacy: WidgetPrivacySnapshot(
          photoMode: photoMode.wireName,
          redactLockScreenTitles: redactTitles,
          explicitRedactLockScreenTitles: explicitRedactLockScreenTitles,
          liveActivityEnabled: liveActivityEnabled,
        ),
        defaultJourneyId: null,
        totals: const WidgetTotalsSnapshot(
          activeCount: 0,
          completedTodayCount: 0,
          pendingTodayCount: 0,
          atRiskCount: 0,
          bestActiveStreak: 0,
        ),
        journeys: const [],
        squads: const [],
        liveWindow: null,
      );
    }

    final thumbsById = <String, WidgetThumbRequest>{};
    String? registerThumb({
      required String? storagePath,
      required String? localFilePath,
      required int maxSide,
      required WidgetPhotoDecision decision,
    }) {
      if (!decision.includePhoto) return null;
      final effectiveStorage = (storagePath != null && storagePath.isNotEmpty)
          ? storagePath
          : localFilePath;
      if (effectiveStorage == null || effectiveStorage.isEmpty) return null;
      final fileName = widgetThumbFileName(
        sourceKey: effectiveStorage,
        maxSide: maxSide,
        blur: decision.blurPhoto,
      );
      final req = WidgetThumbRequest(
        id: fileName,
        storagePath: effectiveStorage,
        localFilePath: localFilePath,
        maxSide: maxSide,
        blur: decision.blurPhoto,
      );
      thumbsById[fileName] = req;
      return req.snapshotRelativePath;
    }

    final deviceLoc = resolveTimeZone(
      (deviceTimezone != null && deviceTimezone.trim().isNotEmpty)
          ? deviceTimezone
          : 'UTC',
    );
    final deviceToday = localDateIn(deviceLoc.name, nowUtc);

    final journeyItems = <WidgetJourneyItem>[];
    final squadItems = <WidgetSquadItem>[];

    for (final input in activeInputs) {
      final j = input.journey;
      final membership = input.membership;
      final progress = JourneyProgress.compute(
        journey: j,
        membership: membership,
        checkIns: input.myCheckIns,
        now: nowUtc,
      );
      final summary = progress.summary;
      final today = progress.today;
      final zone = resolveTimeZone(j.timezone);
      final offsetMinutes = timeZoneOffsetAt(j.timezone, nowUtc).inMinutes;
      final isPinned =
          pinnedJourneyIds.contains(j.id) || (membership?.pinned ?? false);

      final eveningCueUtc = wallClockToUtc(zone, today, kWidgetEveningCueTime);
      final streakAlertUtc = wallClockToUtc(zone, today, kStreakAlertTime);
      final midnightRolloverUtc = wallClockToUtc(
        zone,
        today.addDays(1),
        const ReminderTime(0, 0),
      );

      final reminderTime = reminderSettings.containsKey(j.id)
          ? reminderSettings[j.id]!.activeTime
          : ReminderTime.tryParse(j.reminderTime);
      final String? reminderAtUtc;
      if (reminderTime != null) {
        final hasDeviceZone =
            deviceTimezone != null && deviceTimezone.trim().isNotEmpty;
        final deviceZoneForReminder = hasDeviceZone ? deviceLoc : zone;
        final baseDate = hasDeviceZone ? deviceToday : today;
        DateTime? alignedReminderUtc;
        for (final offset in const [0, -1, 1]) {
          final candidate = wallClockToUtc(
            deviceZoneForReminder,
            baseDate.addDays(offset),
            reminderTime,
          );
          if (localDateIn(zone.name, candidate) == today) {
            alignedReminderUtc = candidate;
            break;
          }
        }
        alignedReminderUtc ??= wallClockToUtc(
          deviceZoneForReminder,
          baseDate,
          reminderTime,
        );
        reminderAtUtc = alignedReminderUtc.toIso8601String();
      } else {
        reminderAtUtc = null;
      }

      // Hero thumbnail: prefer today's latest visible check-in photo, else the
      // latest visible check-in photo from an earlier day of this journey.
      CheckIn? heroCheckIn;
      for (final candidate in progress.checkInsOn(today).reversed) {
        if (!hiddenCheckInIds.contains(candidate.id)) {
          heroCheckIn = candidate;
          break;
        }
      }
      if (heroCheckIn == null && progress.checkInsByDate.isNotEmpty) {
        final sortedDates = progress.checkInsByDate.keys.toList()..sort();
        outer:
        for (final d in sortedDates.reversed) {
          if (d == today) continue;
          for (final candidate in progress.checkInsOn(d).reversed) {
            if (!hiddenCheckInIds.contains(candidate.id)) {
              heroCheckIn = candidate;
              break outer;
            }
          }
        }
      }

      String? heroThumbFile;
      var heroThumbBlurred = false;
      if (heroCheckIn != null) {
        final decision = WidgetPrivacyPolicy.decideHeroPhoto(
          photoMode: photoMode,
          journey: j,
          membership: membership,
          globalBlurPhotosOnShare: globalBlurPhotosOnShare,
          isHiddenCheckIn: hiddenCheckInIds.contains(heroCheckIn.id),
        );
        heroThumbFile = registerThumb(
          storagePath: heroCheckIn.thumbPath.isNotEmpty
              ? heroCheckIn.thumbPath
              : heroCheckIn.photoPath,
          localFilePath: heroCheckIn.localPhotoFile,
          maxSide: kWidgetHeroThumbMaxSide,
          decision: decision,
        );
        heroThumbBlurred = heroThumbFile != null && decision.blurPhoto;
      }

      final weekStrip = <WidgetWeekDayItem>[];
      for (var i = 6; i >= 0; i--) {
        final date = today.addDays(-i);
        final isToday = i == 0;
        final hasCheckIn = progress.checkInsByDate.containsKey(date);
        final String state;
        if (hasCheckIn) {
          state = 'done';
        } else if (isToday) {
          state = 'today';
        } else if (date.isBefore(progress.memberStart)) {
          state = 'before';
        } else {
          state = 'missed';
        }
        weekStrip.add(
          WidgetWeekDayItem(
            date: date.toString(),
            day: date.day,
            label: weekdayLabel(
              date,
              isToday: isToday,
              locale: normalizedLocale,
            ),
            state: state,
          ),
        );
      }

      final skinId = uiSkinIdFor(personaSkinOf(j));
      final colorVariant = (j.color ?? 0).clamp(0, 2);
      final typeIcon = widgetTypeIconFor(j);

      journeyItems.add(
        WidgetJourneyItem(
          id: j.id,
          title: j.title,
          kind: j.kind.wireName,
          skinId: skinId,
          colorVariant: colorVariant,
          typeIcon: typeIcon,
          timezone: zone.name,
          utcOffsetMinutes: offsetMinutes,
          pinned: isPinned,
          dayNumber: progress.dayNumber,
          totalDays: progress.totalDays,
          currentStreak: summary.current,
          bestStreak: summary.best,
          checkedInToday: summary.checkedInToday,
          atRisk: summary.atRisk,
          eveningCueAtUtc: eveningCueUtc.toIso8601String(),
          streakAlertAtUtc: streakAlertUtc.toIso8601String(),
          midnightRolloverUtc: midnightRolloverUtc.toIso8601String(),
          reminderAtUtc: reminderAtUtc,
          heroThumbFile: heroThumbFile,
          heroThumbBlurred: heroThumbBlurred,
          weekStrip: weekStrip,
          isSensitive: WidgetPrivacyPolicy.isSensitiveMetricJourney(j),
        ),
      );

      if (j.kind == JourneyKind.group) {
        final isCouple = isCoupleGroup(j);
        final myUserId = currentUserId ?? membership?.userId;
        final rawMembers = input.groupMembers;
        final combinedCheckIns = <CheckIn>[
          ...input.groupCheckIns,
          for (final c in input.myCheckIns)
            if (!input.groupCheckIns.any((g) => g.id == c.id)) c,
        ];
        final effectiveMembers =
            rawMembers ??
            <MemberToday>[
              MemberToday(
                userId: currentUserId ?? membership?.userId ?? j.ownerId,
                displayName:
                    j.coupleSelfName ??
                    (normalizedLocale == 'en' ? 'Me' : 'Bạn'),
                role: membership?.role ?? MemberRole.owner,
                currentStreak: summary.current,
                todayCheckIn:
                    heroCheckIn != null && heroCheckIn.localDate == today
                    ? heroCheckIn
                    : null,
              ),
            ];
        final groupView = GroupTodayView.build(
          journey: j,
          members: effectiveMembers,
          now: nowUtc,
          myUserId: myUserId,
          blockedIds: blockedUserIds,
          hiddenCheckInIds: hiddenCheckInIds,
          checkIns: combinedCheckIns,
          myMembership: membership,
        );
        final entries = <GroupMemberEntry>[
          ...groupView.done,
          ...groupView.pending,
        ];
        final entriesById = {
          for (final entry in entries) entry.member.userId: entry,
        };
        final Iterable<String?> slotIds = isCouple
            ? coupleMemberIds(
                journey: j,
                myUserId: null,
                members: [
                  for (final member in effectiveMembers)
                    if (entriesById.containsKey(member.userId)) member,
                ],
              )
            : entries
                  .take(j.maxMembers.clamp(1, 10))
                  .map((entry) => entry.member.userId);
        final squadMembers = <WidgetSquadMemberItem>[];
        var vacantCount = 0;
        for (final slotId in slotIds) {
          final entry = entriesById[slotId];
          if (entry == null) {
            vacantCount++;
            squadMembers.add(
              WidgetSquadMemberItem.vacant(
                slotId: vacantCount == 1 ? 'vacant' : 'vacant-$vacantCount',
              ),
            );
            continue;
          }
          final m = entry.member;
          final avatarDecision = WidgetPrivacyPolicy.decideSquadMemberAvatar(
            photoMode: photoMode,
            isBlocked: blockedUserIds.contains(m.userId),
          );
          final avatarFile = registerThumb(
            storagePath: m.avatarPath,
            localFilePath: null,
            maxSide: kWidgetGridThumbMaxSide,
            decision: avatarDecision,
          );

          String? todayThumbFile;
          var todayThumbBlurred = false;
          final photo = isCouple
              ? _coupleTodayPhoto(
                  journey: j,
                  today: today,
                  member: m,
                  isMe: entry.isMe,
                  cachedCheckIns: combinedCheckIns,
                )
              : entry.photoIsToday
              ? entry.photo
              : null;
          final checkedInToday = isCouple
              ? m.checkedInHidden || photo != null
              : entry.checkedInToday;
          if (checkedInToday && photo != null) {
            final photoDecision = WidgetPrivacyPolicy.decideSquadMemberPhoto(
              photoMode: photoMode,
              isMe: entry.isMe,
              myMembership: membership,
              globalBlurPhotosOnShare: globalBlurPhotosOnShare,
              isBlocked: blockedUserIds.contains(m.userId),
              checkedInHidden:
                  m.checkedInHidden || hiddenCheckInIds.contains(photo.id),
            );
            todayThumbFile = registerThumb(
              storagePath: photo.thumbPath.isNotEmpty
                  ? photo.thumbPath
                  : photo.photoPath,
              localFilePath: photo.localPhotoFile,
              maxSide: kWidgetGridThumbMaxSide,
              decision: photoDecision,
            );
            todayThumbBlurred =
                todayThumbFile != null && photoDecision.blurPhoto;
          }

          squadMembers.add(
            WidgetSquadMemberItem(
              displayName: m.displayName,
              initial: initialFor(m.displayName),
              avatarColorIndex: UiAvatar.indexFor(m.userId),
              isMe: entry.isMe,
              checkedInToday: checkedInToday,
              streak: entry.streak,
              avatarFile: avatarFile,
              todayThumbFile: todayThumbFile,
              todayThumbBlurred: todayThumbBlurred,
              slotId: isCouple ? m.userId : null,
            ),
          );
        }

        squadItems.add(
          WidgetSquadItem(
            journeyId: j.id,
            title: j.title,
            skinId: skinId,
            colorVariant: colorVariant,
            typeIcon: typeIcon,
            isCouple: isCouple,
            dayNumber: groupView.dayNumber,
            totalDays: groupView.totalDays,
            doneCount: isCouple
                ? squadMembers.where((member) => member.checkedInToday).length
                : groupView.doneCount,
            memberCount: groupView.memberCount,
            meCheckedInToday: summary.checkedInToday,
            midnightRolloverUtc: midnightRolloverUtc.toIso8601String(),
            members: squadMembers,
          ),
        );
      }
    }

    // Priority ordering (§8.3):
    // 1. Unchecked (!checkedInToday) before checked-in (checkedInToday)
    // 2. Pinned before unpinned
    // 3. At-risk before not at-risk
    // 4. Earliest deadline (reminderAtUtc ?? midnightRolloverUtc, then midnightRolloverUtc)
    // 5. Higher currentStreak, then id
    journeyItems.sort(_compareJourneyPriority);

    // Order squads matching their journey's priority in journeyItems.
    final journeyRank = {
      for (var i = 0; i < journeyItems.length; i++) journeyItems[i].id: i,
    };
    squadItems.sort(
      (a, b) => (journeyRank[a.journeyId] ?? 999).compareTo(
        journeyRank[b.journeyId] ?? 999,
      ),
    );

    final activeCount = journeyItems.length;
    final completedTodayCount = journeyItems
        .where((j) => j.checkedInToday)
        .length;
    final pendingTodayCount = activeCount - completedTodayCount;
    final atRiskCount = journeyItems.where((j) => j.atRisk).length;
    var bestActiveStreak = 0;
    for (final j in journeyItems) {
      if (j.currentStreak > bestActiveStreak) {
        bestActiveStreak = j.currentStreak;
      }
    }

    final livePlan = LiveActivityWindowPlanner.plan(
      now: nowUtc,
      authStatus: authStatus,
      liveActivityEnabled: liveActivityEnabled,
      streakAlertsEnabled: streakAlertsEnabled,
      redactTitleOnLockScreen: redactTitles,
      locale: normalizedLocale,
      journeys: journeyItems,
      dismissedWindowKey: dismissedWindowKey,
    );

    return WidgetSnapshot(
      schemaVersion: kWidgetSnapshotSchemaVersion,
      generatedAtUtc: nowUtc.toIso8601String(),
      authState: 'ready',
      locale: normalizedLocale,
      themeMode: normalizedTheme,
      privacy: WidgetPrivacySnapshot(
        photoMode: photoMode.wireName,
        redactLockScreenTitles: redactTitles,
        explicitRedactLockScreenTitles: explicitRedactLockScreenTitles,
        liveActivityEnabled: liveActivityEnabled,
      ),
      defaultJourneyId: null,
      totals: WidgetTotalsSnapshot(
        activeCount: activeCount,
        completedTodayCount: completedTodayCount,
        pendingTodayCount: pendingTodayCount,
        atRiskCount: atRiskCount,
        bestActiveStreak: bestActiveStreak,
      ),
      journeys: journeyItems,
      squads: squadItems,
      liveWindow: livePlan.window,
      thumbRequests: thumbsById.values.toList(growable: false),
    );
  }

  static CheckIn? _coupleTodayPhoto({
    required Journey journey,
    required LocalDate today,
    required MemberToday member,
    required bool isMe,
    required Iterable<CheckIn> cachedCheckIns,
  }) {
    bool isTodaysOwnPhoto(CheckIn photo) =>
        photo.journeyId == journey.id &&
        photo.userId == member.userId &&
        photo.localDate == today &&
        journeyLocalDate(journey.timezone, photo.capturedAt) == today;

    final server = member.todayCheckIn;
    CheckIn? selected = server != null && isTodaysOwnPhoto(server)
        ? server
        : null;
    for (final photo in cachedCheckIns) {
      if (!isMe && photo.id != selected?.id) continue;
      if (!isTodaysOwnPhoto(photo)) continue;
      // Local media is useful for pending self posts and for the exact
      // co-member post that the current group-day RPC returned.
      if (selected == null || compareCheckIns(photo, selected) >= 0) {
        selected = photo;
      }
    }
    return selected;
  }

  static int _compareJourneyPriority(WidgetJourneyItem a, WidgetJourneyItem b) {
    if (a.checkedInToday != b.checkedInToday) {
      return a.checkedInToday ? 1 : -1;
    }
    if (a.pinned != b.pinned) {
      return a.pinned ? -1 : 1;
    }
    if (a.atRisk != b.atRisk) {
      return a.atRisk ? -1 : 1;
    }
    final aDeadline = DateTime.parse(a.reminderAtUtc ?? a.midnightRolloverUtc);
    final bDeadline = DateTime.parse(b.reminderAtUtc ?? b.midnightRolloverUtc);
    final deadlineCmp = aDeadline.compareTo(bDeadline);
    if (deadlineCmp != 0) return deadlineCmp;

    final aMidnight = DateTime.parse(a.midnightRolloverUtc);
    final bMidnight = DateTime.parse(b.midnightRolloverUtc);
    final midnightCmp = aMidnight.compareTo(bMidnight);
    if (midnightCmp != 0) return midnightCmp;

    final streakCmp = b.currentStreak.compareTo(a.currentStreak);
    if (streakCmp != 0) return streakCmp;

    return a.id.compareTo(b.id);
  }
}
