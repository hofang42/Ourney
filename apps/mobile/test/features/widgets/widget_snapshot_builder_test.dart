import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/app/redirect.dart' show AuthStatus;
import 'package:ourney/features/reminders/data/reminder_settings.dart';
import 'package:ourney/features/reminders/domain/reminder_plan.dart';
import 'package:ourney/features/widgets/domain/widget_privacy.dart';
import 'package:ourney/features/widgets/domain/widget_snapshot.dart';
import 'package:ourney_core/ourney_core.dart';

Journey _makeJourney({
  required String id,
  required String title,
  JourneyKind kind = JourneyKind.solo,
  TemplateId templateId = TemplateId.englishDaily,
  LocalDate startDate = const LocalDate(2026, 11, 10),
  int? durationDays = 30,
  String timezone = 'Asia/Ho_Chi_Minh',
  bool hideMetricDefault = false,
  String? metricName,
  String? metricUnit,
  int maxMembers = 10,
  String? coupleSelfName,
  String? couplePartnerName,
  PersonaSkinId? layout,
  int? color = 0,
  String? reminderTime,
  Map<String, Object?>? dna,
}) => Journey(
  id: id,
  ownerId: 'u-me',
  kind: kind,
  templateId: templateId,
  title: title,
  emoji: '',
  startDate: startDate,
  durationDays: durationDays,
  timezone: timezone,
  visibility: defaultVisibilityFor(kind),
  status: JourneyStatus.active,
  hideMetricDefault: hideMetricDefault,
  metricName: metricName,
  metricUnit: metricUnit,
  maxMembers: maxMembers,
  coupleSelfName: coupleSelfName,
  couplePartnerName: couplePartnerName,
  layout: layout,
  color: color,
  reminderTime: reminderTime,
  dna: dna,
);

CheckIn _makeCheckIn({
  required String id,
  required String journeyId,
  required LocalDate localDate,
  String userId = 'u-me',
  String thumbPath = 'checkins/j1/u-me/c1_t.jpg',
  DateTime? capturedAt,
  String? partnerPhotoPath,
  double? metricValue,
  String? caption,
}) => CheckIn(
  id: id,
  journeyId: journeyId,
  userId: userId,
  localDate: localDate,
  capturedAt:
      capturedAt ??
      DateTime.utc(localDate.year, localDate.month, localDate.day, 9),
  photoPath: thumbPath.replaceAll('_t.jpg', '.jpg'),
  thumbPath: thumbPath,
  partnerPhotoPath: partnerPhotoPath,
  metricValue: metricValue,
  caption: caption,
);

void main() {
  // 2026-11-24 11:55 UTC == 2026-11-24 18:55 in Asia/Ho_Chi_Minh (+07:00).
  final nowUtc = DateTime.utc(2026, 11, 24, 11, 55);

  group('Couple widgets', () {
    final couple = _makeJourney(
      id: 'j-couple',
      title: 'Our photos',
      kind: JourneyKind.group,
      maxMembers: 2,
      layout: PersonaSkinId.memoryCollectors,
    );
    const today = LocalDate(2026, 11, 24);
    const me = MemberToday(
      userId: 'u-me',
      displayName: 'Minh',
      role: MemberRole.owner,
    );
    const partner = MemberToday(
      userId: 'u-partner',
      displayName: 'Linh',
      role: MemberRole.member,
    );

    WidgetSnapshot build({
      List<MemberToday> members = const [me],
      List<CheckIn> own = const [],
      List<CheckIn> cached = const [],
      WidgetPhotoMode mode = WidgetPhotoMode.clear,
      Set<String> blocked = const {},
      Set<String> hidden = const {},
      DateTime? now,
    }) => WidgetSnapshotBuilder.build(
      now: now ?? nowUtc,
      authStatus: AuthStatus.signedIn,
      currentUserId: me.userId,
      photoMode: mode,
      blockedUserIds: blocked,
      hiddenCheckInIds: hidden,
      journeyInputs: [
        WidgetJourneyBuildInput(
          journey: couple,
          groupMembers: members,
          myCheckIns: own,
          groupCheckIns: cached,
        ),
      ],
    );

    List<Object?> slotIds(WidgetSnapshot snapshot) => snapshot
        .squads
        .single
        .members
        .map((member) => member.toJson()['slotId'])
        .toList();

    test('reserves the open side and keeps author order as photos arrive', () {
      final selfFirst = _makeCheckIn(
        id: 'a-self',
        journeyId: couple.id,
        localDate: today,
        thumbPath: 'checkins/j-couple/u-me/a-self_t.jpg',
      );
      final selfLatest = _makeCheckIn(
        id: 'b-self',
        journeyId: couple.id,
        localDate: today,
        thumbPath: 'checkins/j-couple/u-me/b-self_t.jpg',
        partnerPhotoPath: 'checkins/j-couple/u-me/b-self_p.jpg',
      );
      final partnerPhoto = _makeCheckIn(
        id: 'c-partner',
        journeyId: couple.id,
        localDate: today,
        userId: partner.userId,
        thumbPath: 'checkins/j-couple/u-partner/c-partner_t.jpg',
      );
      final posted = MemberToday(
        userId: partner.userId,
        displayName: partner.displayName,
        role: partner.role,
        todayCheckIn: partnerPhoto,
      );

      final open = build(own: [selfFirst, selfLatest]);
      final openSquad = open.squads.single;
      expect(openSquad.isCouple, isTrue);
      expect(openSquad.memberCount, 1);
      expect(slotIds(open), [me.userId, 'vacant']);
      expect(openSquad.members.last.toJson()['isVacant'], isTrue);
      expect(openSquad.members.last.todayThumbFile, isNull);

      final partnerFirst = build(members: [me, posted]);
      expect(slotIds(partnerFirst), [me.userId, partner.userId]);
      expect(
        partnerFirst.squads.single.members.map(
          (member) => member.checkedInToday,
        ),
        [false, true],
      );

      final paired = build(members: [me, posted], own: [selfFirst, selfLatest]);
      expect(slotIds(paired), slotIds(partnerFirst));
      final slots = paired.squads.single.members;
      expect(slots.map((member) => member.todayThumbFile), [
        for (final checkIn in [selfLatest, partnerPhoto])
          'thumbs/${widgetThumbFileName(sourceKey: checkIn.thumbPath, maxSide: kWidgetGridThumbMaxSide, blur: false)}',
      ]);
      expect(
        paired.thumbRequests.map((request) => request.storagePath),
        isNot(contains(selfLatest.partnerPhotoPath)),
      );
    });

    test(
      'keeps privacy placeholders for hidden photos and clears stale days',
      () {
        final older = _makeCheckIn(
          id: 'old-partner',
          journeyId: couple.id,
          localDate: today,
          userId: partner.userId,
          thumbPath: 'checkins/j-couple/u-partner/old-partner_t.jpg',
        );
        final hidden = _makeCheckIn(
          id: 'new-partner',
          journeyId: couple.id,
          localDate: today,
          userId: partner.userId,
          thumbPath: 'checkins/j-couple/u-partner/new-partner_t.jpg',
          capturedAt: DateTime.utc(2026, 11, 24, 10),
        );
        final posted = MemberToday(
          userId: partner.userId,
          displayName: partner.displayName,
          role: partner.role,
          todayCheckIn: hidden,
        );

        final hiddenSnapshot = build(
          members: [me, posted],
          cached: [older, hidden],
          hidden: {hidden.id},
        );
        final privateSlot = hiddenSnapshot.squads.single.members.last;
        expect(privateSlot.checkedInToday, isTrue);
        expect(privateSlot.todayThumbFile, isNull);
        expect(hiddenSnapshot.thumbRequests, isEmpty);

        final smart = build(mode: WidgetPhotoMode.smart, members: [me, posted]);
        expect(slotIds(smart), slotIds(hiddenSnapshot));
        expect(smart.squads.single.members.last.checkedInToday, isTrue);
        expect(smart.squads.single.members.last.todayThumbFile, isNull);

        final blocked = build(members: [me, posted], blocked: {partner.userId});
        expect(slotIds(blocked), [me.userId, 'vacant']);
        expect(blocked.thumbRequests, isEmpty);

        // 17:00 UTC is the next day in the journey's time zone.
        final nextDay = build(
          members: [me, posted],
          cached: [older, hidden],
          now: DateTime.utc(2026, 11, 24, 17),
        );
        expect(slotIds(nextDay), slotIds(hiddenSnapshot));
        expect(nextDay.squads.single.doneCount, 0);
        expect(nextDay.squads.single.members.last.checkedInToday, isFalse);
        expect(nextDay.squads.single.members.last.todayThumbFile, isNull);
      },
    );
  });

  group('WidgetSnapshotBuilder priority & schema (§4.3, §8.3)', () {
    test(
      'orders journeys: pinned unchecked -> atRisk -> earliest deadline -> checkedInToday',
      () {
        final jCheckedInPinned = _makeJourney(
          id: 'j-done-pinned',
          title: 'Done Pinned',
        );
        final jUncheckedUnpinnedEarly = _makeJourney(
          id: 'j-unchecked-early',
          title: 'Unchecked Early Reminder',
        );
        final jUncheckedAtRisk = _makeJourney(
          id: 'j-unchecked-atrisk',
          title: 'Unchecked At Risk',
        );
        final jUncheckedPinned = _makeJourney(
          id: 'j-unchecked-pinned',
          title: 'Unchecked Pinned',
        );

        final snapshot = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          pinnedJourneyIds: {'j-done-pinned', 'j-unchecked-pinned'},
          reminderSettings: {
            'j-unchecked-early': const ReminderSetting(
              enabled: true,
              time: ReminderTime(19, 30),
            ),
          },
          deviceTimezone: 'Asia/Ho_Chi_Minh',
          journeyInputs: [
            WidgetJourneyBuildInput(
              journey: jCheckedInPinned,
              myCheckIns: [
                _makeCheckIn(
                  id: 'c-done',
                  journeyId: jCheckedInPinned.id,
                  localDate: const LocalDate(2026, 11, 24),
                ),
              ],
            ),
            WidgetJourneyBuildInput(
              journey: jUncheckedUnpinnedEarly,
              myCheckIns: const [],
            ),
            WidgetJourneyBuildInput(
              journey: jUncheckedAtRisk,
              myCheckIns: [
                _makeCheckIn(
                  id: 'c-yesterday',
                  journeyId: jUncheckedAtRisk.id,
                  localDate: const LocalDate(2026, 11, 23),
                ),
              ],
            ),
            WidgetJourneyBuildInput(
              journey: jUncheckedPinned,
              myCheckIns: const [],
            ),
          ],
        );

        expect(
          snapshot.journeys.map((j) => j.id).toList(),
          [
            'j-unchecked-pinned',
            'j-unchecked-atrisk',
            'j-unchecked-early',
            'j-done-pinned',
          ],
        );
        expect(
          snapshot.defaultJourneyId,
          isNull,
          reason:
              'Automatic mode must leave defaultJourneyId null so Streak widget '
              'can select the highest active streak (§4.4)',
        );
        expect(snapshot.defaultSquadId, isNull);
        expect(snapshot.totals.activeCount, 4);
        expect(snapshot.totals.completedTodayCount, 1);
        expect(snapshot.totals.pendingTodayCount, 3);
        expect(snapshot.totals.atRiskCount, 1);
      },
    );

    test(
      'emits defaultJourneyId and defaultSquadId only when explicitly chosen and active (§4.4)',
      () {
        final jSolo = _makeJourney(id: 'j-solo-1', title: 'Solo Run');
        final jSquad = _makeJourney(
          id: 'j-squad-1',
          title: 'IELTS Squad',
          kind: JourneyKind.group,
        );

        final autoSnap = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          defaultJourneyId: 'auto',
          defaultSquadId: 'auto',
          journeyInputs: [
            WidgetJourneyBuildInput(journey: jSolo),
            WidgetJourneyBuildInput(journey: jSquad),
          ],
        );
        expect(autoSnap.defaultJourneyId, isNull);
        expect(autoSnap.defaultSquadId, isNull);
        final autoMap =
            jsonDecode(autoSnap.toJsonString()) as Map<String, Object?>;
        expect(autoMap.containsKey('defaultJourneyId'), isFalse);
        expect(autoMap.containsKey('defaultSquadId'), isFalse);

        final staleSnap = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          defaultJourneyId: 'archived-journey-99',
          defaultSquadId: 'j-solo-1', // solo journey is not in squads
          journeyInputs: [
            WidgetJourneyBuildInput(journey: jSolo),
            WidgetJourneyBuildInput(journey: jSquad),
          ],
        );
        expect(staleSnap.defaultJourneyId, isNull);
        expect(staleSnap.defaultSquadId, isNull);

        final explicitSnap = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          defaultJourneyId: 'j-solo-1',
          defaultSquadId: 'j-squad-1',
          journeyInputs: [
            WidgetJourneyBuildInput(journey: jSolo),
            WidgetJourneyBuildInput(journey: jSquad),
          ],
        );
        expect(explicitSnap.defaultJourneyId, 'j-solo-1');
        expect(explicitSnap.defaultSquadId, 'j-squad-1');
        final explicitMap =
            jsonDecode(explicitSnap.toJsonString()) as Map<String, Object?>;
        expect(explicitMap['defaultJourneyId'], 'j-solo-1');
        expect(explicitMap['defaultSquadId'], 'j-squad-1');
      },
    );

    test(
      'privacy-by-omission: never leaks metricValue (kg), metricUnit, dna, or caption into JSON (§4.3, §7.1)',
      () {
        final weightJourney = _makeJourney(
          id: 'j-weight',
          title: 'Hành trình giảm cân',
          templateId: TemplateId.weightLoss,
          hideMetricDefault: true,
          metricName: 'Cân nặng',
          metricUnit: 'kg',
          dna: const {
            'goal': 'lose_5kg_secret',
            'reason': 'private_health_reason_99',
          },
        );
        final checkIn = _makeCheckIn(
          id: 'c-weight-1',
          journeyId: weightJourney.id,
          localDate: const LocalDate(2026, 11, 24),
          metricValue: 62.5,
          caption: 'Secret diary weight note 62.5kg',
        );

        final snapshot = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          journeyInputs: [
            WidgetJourneyBuildInput(
              journey: weightJourney,
              myCheckIns: [checkIn],
            ),
          ],
        );

        final jsonString = snapshot.toJsonString();
        expect(jsonString.contains('62.5'), isFalse);
        expect(jsonString.contains('lose_5kg_secret'), isFalse);
        expect(jsonString.contains('private_health_reason_99'), isFalse);
        expect(jsonString.contains('Secret diary weight note'), isFalse);
        expect(jsonString.contains('metricValue'), isFalse);
        expect(jsonString.contains('metricUnit'), isFalse);
        expect(jsonString.contains('"dna"'), isFalse);
        expect(jsonString.contains('"caption"'), isFalse);

        // Weight-loss journey defaults Lock Screen title redaction to true!
        expect(snapshot.privacy.redactLockScreenTitles, isTrue);
      },
    );

    test(
      'computes eveningCueAtUtc (18:00), streakAlertAtUtc (21:00), and midnightRolloverUtc (00:00) across timezones and DST (§4.5, §8.3)',
      () {
        final hcmJourney = _makeJourney(
          id: 'j-hcm',
          title: 'HCM Journey',
          timezone: 'Asia/Ho_Chi_Minh', // UTC+7
        );
        final nyJourney = _makeJourney(
          id: 'j-ny',
          title: 'NY Journey',
          timezone: 'America/New_York', // UTC-5 in November (EST)
        );

        final snapshot = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.localOnly,
          locale: 'vi',
          themeMode: ThemeMode.dark,
          journeyInputs: [
            WidgetJourneyBuildInput(journey: hcmJourney),
            WidgetJourneyBuildInput(journey: nyJourney),
          ],
        );

        final hcm = snapshot.journeys.firstWhere((j) => j.id == 'j-hcm');
        expect(hcm.utcOffsetMinutes, 420);
        // 2026-11-24 in UTC+7: 18:00 = 11:00Z, 21:00 = 14:00Z, 24:00 = 17:00Z.
        expect(hcm.eveningCueAtUtc, '2026-11-24T11:00:00.000Z');
        expect(hcm.streakAlertAtUtc, '2026-11-24T14:00:00.000Z');
        expect(hcm.midnightRolloverUtc, '2026-11-24T17:00:00.000Z');
        expect(hcm.weekStrip, hasLength(7));
        expect(hcm.weekStrip.last.date, '2026-11-24');
        expect(hcm.weekStrip.last.label, 'HN');

        final ny = snapshot.journeys.firstWhere((j) => j.id == 'j-ny');
        expect(ny.utcOffsetMinutes, -300);
        // 2026-11-24 in UTC-5: 18:00 = 23:00Z, 21:00 = 2026-11-25T02:00Z, 24:00 = 2026-11-25T05:00Z.
        expect(ny.eveningCueAtUtc, '2026-11-24T23:00:00.000Z');
        expect(ny.streakAlertAtUtc, '2026-11-25T02:00:00.000Z');
        expect(ny.midnightRolloverUtc, '2026-11-25T05:00:00.000Z');

        // Verify DST summer offset in America/New_York (EDT = UTC-4 in July).
        final summerNow = DateTime.utc(2026, 7, 15, 15, 0);
        final summerSnap = WidgetSnapshotBuilder.build(
          now: summerNow,
          authStatus: AuthStatus.localOnly,
          locale: 'en',
          journeyInputs: [WidgetJourneyBuildInput(journey: nyJourney)],
        );
        final nySummer = summerSnap.journeys.single;
        expect(nySummer.utcOffsetMinutes, -240);
        expect(nySummer.eveningCueAtUtc, '2026-07-15T22:00:00.000Z');
        expect(nySummer.streakAlertAtUtc, '2026-07-16T01:00:00.000Z');
        expect(nySummer.midnightRolloverUtc, '2026-07-16T04:00:00.000Z');
        expect(nySummer.weekStrip.last.label, 'TD');
      },
    );
  });

  group('WidgetPrivacyPolicy across photoModes, blockedIds & hiddenCheckInIds (§7.1, §8.3)', () {
    final weightJourney = _makeJourney(
      id: 'j-weight',
      title: 'Weight Loss',
      templateId: TemplateId.weightLoss,
      hideMetricDefault: true,
    );
    final studyJourney = _makeJourney(
      id: 'j-study',
      title: 'IELTS Squad',
      kind: JourneyKind.group,
      templateId: TemplateId.englishDaily,
    );

    test('smart mode blurs weight-loss solo hero, shows study hero clear, omits squad member today photos', () {
      final snapshot = WidgetSnapshotBuilder.build(
        now: nowUtc,
        authStatus: AuthStatus.signedIn,
        photoMode: WidgetPhotoMode.smart,
        currentUserId: 'u-me',
        journeyInputs: [
          WidgetJourneyBuildInput(
            journey: weightJourney,
            myCheckIns: [
              _makeCheckIn(
                id: 'c-w',
                journeyId: weightJourney.id,
                localDate: const LocalDate(2026, 11, 24),
                thumbPath: 'checkins/j-weight/u-me/cw_t.jpg',
              ),
            ],
          ),
          WidgetJourneyBuildInput(
            journey: studyJourney,
            myCheckIns: [
              _makeCheckIn(
                id: 'c-s',
                journeyId: studyJourney.id,
                localDate: const LocalDate(2026, 11, 24),
                thumbPath: 'checkins/j-study/u-me/cs_t.jpg',
              ),
            ],
            groupMembers: [
              MemberToday(
                userId: 'u-me',
                displayName: 'Minh',
                role: MemberRole.owner,
                avatarPath: 'avatars/u-me/a.jpg',
                currentStreak: 5,
                todayCheckIn: _makeCheckIn(
                  id: 'c-s',
                  journeyId: studyJourney.id,
                  localDate: const LocalDate(2026, 11, 24),
                  thumbPath: 'checkins/j-study/u-me/cs_t.jpg',
                ),
              ),
            ],
          ),
        ],
      );

      final wItem = snapshot.journeys.firstWhere((j) => j.id == 'j-weight');
      expect(wItem.heroThumbFile, isNotNull);
      expect(wItem.heroThumbBlurred, isTrue);
      expect(wItem.isSensitive, isTrue);
      expect(wItem.toJson()['isSensitive'], isTrue);

      final sItem = snapshot.journeys.firstWhere((j) => j.id == 'j-study');
      expect(sItem.heroThumbFile, isNotNull);
      expect(sItem.heroThumbBlurred, isFalse);
      expect(sItem.isSensitive, isFalse);
      expect(sItem.toJson()['isSensitive'], isFalse);

      // In smart mode, squad member avatars are shown, but todayThumbFile is omitted!
      final squad = snapshot.squads.single;
      expect(squad.members.single.avatarFile, isNotNull);
      expect(squad.members.single.todayThumbFile, isNull);
    });

    test('blurred, off, and clear modes + blockedIds & hiddenCheckInIds filtering', () {
      final memberCheckIn = _makeCheckIn(
        id: 'c-friend',
        journeyId: studyJourney.id,
        userId: 'u-friend',
        localDate: const LocalDate(2026, 11, 24),
        thumbPath: 'checkins/j-study/u-friend/cf_t.jpg',
      );
      final blockedCheckIn = _makeCheckIn(
        id: 'c-blocked',
        journeyId: studyJourney.id,
        userId: 'u-blocked',
        localDate: const LocalDate(2026, 11, 24),
        thumbPath: 'checkins/j-study/u-blocked/cb_t.jpg',
      );
      final reportedCheckIn = _makeCheckIn(
        id: 'c-reported',
        journeyId: studyJourney.id,
        userId: 'u-reported',
        localDate: const LocalDate(2026, 11, 24),
        thumbPath: 'checkins/j-study/u-reported/cr_t.jpg',
      );

      final members = [
        MemberToday(
          userId: 'u-friend',
          displayName: 'Linh',
          role: MemberRole.member,
          avatarPath: 'avatars/u-friend/a.jpg',
          currentStreak: 4,
          todayCheckIn: memberCheckIn,
        ),
        MemberToday(
          userId: 'u-blocked',
          displayName: 'Blocked',
          role: MemberRole.member,
          avatarPath: 'avatars/u-blocked/a.jpg',
          currentStreak: 2,
          todayCheckIn: blockedCheckIn,
        ),
        MemberToday(
          userId: 'u-reported',
          displayName: 'Reported',
          role: MemberRole.member,
          avatarPath: 'avatars/u-reported/a.jpg',
          currentStreak: 3,
          todayCheckIn: reportedCheckIn,
        ),
      ];

      // 1. Off mode: zero thumbs requested or emitted.
      final offSnap = WidgetSnapshotBuilder.build(
        now: nowUtc,
        authStatus: AuthStatus.signedIn,
        photoMode: WidgetPhotoMode.off,
        blockedUserIds: {'u-blocked'},
        hiddenCheckInIds: {'c-reported'},
        journeyInputs: [
          WidgetJourneyBuildInput(
            journey: studyJourney,
            groupMembers: members,
          ),
        ],
      );
      expect(offSnap.thumbRequests, isEmpty);
      expect(offSnap.squads.single.members.map((m) => m.displayName), [
        'Linh',
        'Reported',
      ]);

      // 2. Clear mode: blocked user stripped, reported check-in photo stripped,
      // friend's photo included unblurred.
      final clearSnap = WidgetSnapshotBuilder.build(
        now: nowUtc,
        authStatus: AuthStatus.signedIn,
        photoMode: WidgetPhotoMode.clear,
        blockedUserIds: {'u-blocked'},
        hiddenCheckInIds: {'c-reported'},
        journeyInputs: [
          WidgetJourneyBuildInput(
            journey: studyJourney,
            groupMembers: members,
          ),
        ],
      );
      final squadMembers = clearSnap.squads.single.members;
      expect(squadMembers.map((m) => m.displayName), ['Linh', 'Reported']);
      final linh = squadMembers.firstWhere((m) => m.displayName == 'Linh');
      expect(linh.todayThumbFile, isNotNull);
      expect(linh.todayThumbBlurred, isFalse);

      final reported = squadMembers.firstWhere(
        (m) => m.displayName == 'Reported',
      );
      expect(reported.checkedInToday, isTrue);
      expect(reported.todayThumbFile, isNull);

      // 3. Blurred mode: friend's photo is included and marked blurred.
      final blurredSnap = WidgetSnapshotBuilder.build(
        now: nowUtc,
        authStatus: AuthStatus.signedIn,
        photoMode: WidgetPhotoMode.blurred,
        blockedUserIds: {'u-blocked'},
        hiddenCheckInIds: {'c-reported'},
        journeyInputs: [
          WidgetJourneyBuildInput(
            journey: studyJourney,
            groupMembers: members,
          ),
        ],
      );
      final linhBlurred = blurredSnap.squads.single.members.firstWhere(
        (m) => m.displayName == 'Linh',
      );
      expect(linhBlurred.todayThumbFile, isNotNull);
      expect(linhBlurred.todayThumbBlurred, isTrue);
      // Content-addressed ID differs between clear and blurred!
      expect(linhBlurred.todayThumbFile, isNot(linh.todayThumbFile));
    });

    test('globalBlurPhotosOnShare forces blur on solo hero and own squad photo even in clear mode', () {
      final solo = _makeJourney(id: 'j-solo', title: 'Solo');
      final snap = WidgetSnapshotBuilder.build(
        now: nowUtc,
        authStatus: AuthStatus.signedIn,
        photoMode: WidgetPhotoMode.clear,
        globalBlurPhotosOnShare: true,
        journeyInputs: [
          WidgetJourneyBuildInput(
            journey: solo,
            myCheckIns: [
              _makeCheckIn(
                id: 'c-1',
                journeyId: solo.id,
                localDate: const LocalDate(2026, 11, 24),
              ),
            ],
          ),
        ],
      );
      expect(snap.journeys.single.heroThumbFile, isNotNull);
      expect(snap.journeys.single.heroThumbBlurred, isTrue);

      final decoded = jsonDecode(snap.toJsonString()) as Map<String, Object?>;
      expect(decoded['schemaVersion'], 1);
    });

    test(
      'omits absent optional keys (never emits :null) and omits totalDays for open-ended journeys (P1-3)',
      () {
        final openEndedGroup = _makeJourney(
          id: 'j-open',
          title: 'Open Ended Group',
          kind: JourneyKind.group,
          durationDays: null,
        );
        final snap = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          photoMode: WidgetPhotoMode.off,
          liveActivityEnabled: false,
          journeyInputs: [
            WidgetJourneyBuildInput(journey: openEndedGroup),
          ],
        );

        final rawJson = snap.toJsonString();
        expect(rawJson.contains(':null'), isFalse);

        final decoded = jsonDecode(rawJson) as Map<String, Object?>;
        expect(decoded.containsKey('liveWindow'), isFalse);

        final jMap =
            (decoded['journeys'] as List<Object?>).single as Map<String, Object?>;
        expect(jMap.containsKey('totalDays'), isFalse);
        expect(jMap.containsKey('reminderAtUtc'), isFalse);
        expect(jMap.containsKey('heroThumbFile'), isFalse);

        final sMap =
            (decoded['squads'] as List<Object?>).single as Map<String, Object?>;
        expect(sMap.containsKey('totalDays'), isFalse);
        final mMap =
            (sMap['members'] as List<Object?>).single as Map<String, Object?>;
        expect(mMap.containsKey('avatarFile'), isFalse);
        expect(mMap.containsKey('todayThumbFile'), isFalse);
        expect(mMap['displayName'], 'Bạn');
        expect(mMap['initial'], 'B');

        final signedOutSnap = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedOut,
          journeyInputs: const [],
        );
        expect(signedOutSnap.toJsonString().contains(':null'), isFalse);
        final signedOutMap =
            jsonDecode(signedOutSnap.toJsonString()) as Map<String, Object?>;
        expect(signedOutMap.containsKey('defaultJourneyId'), isFalse);
        expect(signedOutMap.containsKey('liveWindow'), isFalse);
      },
    );

    test(
      'respects reminder OFF even when Journey.reminderTime is non-null, and aligns cross-timezone reminderAtUtc to journey today (P1-1)',
      () {
        final journeyWithModelTime = _makeJourney(
          id: 'j-rem-off',
          title: 'Reminder Disabled In Settings',
          reminderTime: '20:00',
          timezone: 'Asia/Ho_Chi_Minh',
        );
        final crossTzJourney = _makeJourney(
          id: 'j-cross-tz',
          title: 'HCM Journey On NY Device',
          timezone: 'Asia/Ho_Chi_Minh', // UTC+7
        );

        // At 2026-11-24T12:00:00Z:
        // - In Asia/Ho_Chi_Minh (+07:00), it is 2026-11-24 19:00 (today = 2026-11-24, midnight = 2026-11-24T17:00:00Z).
        // - In America/New_York (-05:00), it is 2026-11-24 07:00 (deviceToday = 2026-11-24).
        // A 20:00 NY reminder on 2026-11-23 is 2026-11-24T01:00:00Z (08:00 ICT on 2026-11-24 == journey today!).
        final snap = WidgetSnapshotBuilder.build(
          now: DateTime.utc(2026, 11, 24, 12, 0),
          authStatus: AuthStatus.signedIn,
          deviceTimezone: 'America/New_York',
          reminderSettings: {
            'j-rem-off': const ReminderSetting(
              enabled: false,
              time: ReminderTime(20, 0),
            ),
            'j-cross-tz': const ReminderSetting(
              enabled: true,
              time: ReminderTime(20, 0),
            ),
          },
          journeyInputs: [
            WidgetJourneyBuildInput(journey: journeyWithModelTime),
            WidgetJourneyBuildInput(journey: crossTzJourney),
          ],
        );

        final offItem = snap.journeys.firstWhere((j) => j.id == 'j-rem-off');
        expect(offItem.reminderAtUtc, isNull);

        final crossItem = snap.journeys.firstWhere((j) => j.id == 'j-cross-tz');
        expect(crossItem.reminderAtUtc, '2026-11-24T01:00:00.000Z');
        expect(
          DateTime.parse(crossItem.reminderAtUtc!).isBefore(
            DateTime.parse(crossItem.midnightRolloverUtc),
          ),
          isTrue,
        );
      },
    );

    test(
      'falls back to prior visible check-in when today check-in is in hiddenCheckInIds and localizes Me/Bạn fallback (P2-3)',
      () {
        final groupJ = _makeJourney(
          id: 'j-hidden-today',
          title: 'Hidden Today CheckIn',
          kind: JourneyKind.group,
        );
        final yesterdayCheckIn = _makeCheckIn(
          id: 'c-yesterday-ok',
          journeyId: groupJ.id,
          localDate: const LocalDate(2026, 11, 23),
          thumbPath: 'checkins/j1/u-me/yesterday_t.jpg',
        );
        final todayHiddenCheckIn = _makeCheckIn(
          id: 'c-today-hidden',
          journeyId: groupJ.id,
          localDate: const LocalDate(2026, 11, 24),
          thumbPath: 'checkins/j1/u-me/today_hidden_t.jpg',
        );

        final snapEn = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          locale: 'en',
          photoMode: WidgetPhotoMode.clear,
          hiddenCheckInIds: {'c-today-hidden'},
          journeyInputs: [
            WidgetJourneyBuildInput(
              journey: groupJ,
              myCheckIns: [yesterdayCheckIn, todayHiddenCheckIn],
            ),
          ],
        );

        final item = snapEn.journeys.single;
        expect(item.heroThumbFile, isNotNull);
        expect(
          snapEn.thumbRequests.single.storagePath,
          'checkins/j1/u-me/yesterday_t.jpg',
        );
        expect(snapEn.squads.single.members.single.displayName, 'Me');
      },
    );

    test(
      'pins privacy JSON keys for iOS Lock Screen title redaction (P3-3): '
      'toggle ON redacts all titles; toggle OFF redacts only sensitive journeys',
      () {
        final inputs = [
          WidgetJourneyBuildInput(journey: weightJourney),
          WidgetJourneyBuildInput(journey: studyJourney),
        ];

        // 1. User toggle ON (explicitRedactLockScreenTitles: true) ->
        // emits redactLockScreenTitles: true AND explicitRedactLockScreenTitles: true
        // so iOS shouldRedactLockScreenTitle redacts ALL journey titles.
        final toggleOnSnap = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          explicitRedactLockScreenTitles: true,
          journeyInputs: inputs,
        );
        final toggleOnJson =
            jsonDecode(toggleOnSnap.toJsonString()) as Map<String, Object?>;
        final privacyOn = toggleOnJson['privacy'] as Map<String, Object?>;
        expect(privacyOn['redactLockScreenTitles'], isTrue);
        expect(privacyOn['explicitRedactLockScreenTitles'], isTrue);

        // 2. User toggle OFF (explicitRedactLockScreenTitles: false) ->
        // emits redactLockScreenTitles: false and OMITS explicitRedactLockScreenTitles
        // while keeping per-journey isSensitive: true/false, so iOS
        // shouldRedactLockScreenTitle falls through to journey.isEffectiveSensitiveJourney
        // (redacting only sensitive journeys, showing non-sensitive titles).
        final toggleOffSnap = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          explicitRedactLockScreenTitles: false,
          journeyInputs: inputs,
        );
        final toggleOffJson =
            jsonDecode(toggleOffSnap.toJsonString()) as Map<String, Object?>;
        final privacyOff = toggleOffJson['privacy'] as Map<String, Object?>;
        expect(privacyOff['redactLockScreenTitles'], isFalse);
        expect(
          privacyOff.containsKey('explicitRedactLockScreenTitles'),
          isFalse,
        );
        final journeysOff = (toggleOffJson['journeys'] as List<Object?>)
            .cast<Map<String, Object?>>();
        final weightJson = journeysOff.firstWhere((j) => j['id'] == 'j-weight');
        final studyJson = journeysOff.firstWhere((j) => j['id'] == 'j-study');
        expect(weightJson['isSensitive'], isTrue);
        expect(studyJson['isSensitive'], isFalse);

        // 3. Unset toggle (explicitRedactLockScreenTitles: null) ->
        // omits explicitRedactLockScreenTitles and defaults redactLockScreenTitles
        // to true when a sensitive journey is present, or false otherwise.
        final unsetMixedSnap = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          journeyInputs: inputs,
        );
        final privacyUnsetMixed =
            (jsonDecode(unsetMixedSnap.toJsonString())
                    as Map<String, Object?>)['privacy']
                as Map<String, Object?>;
        expect(privacyUnsetMixed['redactLockScreenTitles'], isTrue);
        expect(
          privacyUnsetMixed.containsKey('explicitRedactLockScreenTitles'),
          isFalse,
        );

        final unsetNonSensitiveSnap = WidgetSnapshotBuilder.build(
          now: nowUtc,
          authStatus: AuthStatus.signedIn,
          journeyInputs: [WidgetJourneyBuildInput(journey: studyJourney)],
        );
        final privacyUnsetStudy =
            (jsonDecode(unsetNonSensitiveSnap.toJsonString())
                    as Map<String, Object?>)['privacy']
                as Map<String, Object?>;
        expect(privacyUnsetStudy['redactLockScreenTitles'], isFalse);
        expect(
          privacyUnsetStudy.containsKey('explicitRedactLockScreenTitles'),
          isFalse,
        );
      },
    );
  });
}
