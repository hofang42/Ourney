import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/mapping.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

void main() {
  test('create_journey params use wire names (never Enum.name)', () {
    final p = createJourneyParams(
      'id1',
      soloDraft(template: TemplateId.weightLoss),
    );
    expect(p['p_template_id'], 'weight_loss');
    expect(p['p_kind'], 'solo');
    expect(p['p_visibility'], 'private');
    expect(p['p_start_date'], '2026-10-10');
    expect(p['p_max_members'], 1);
    expect(
      p.keys,
      containsAll(<String>[
        'p_id',
        'p_kind',
        'p_template_id',
        'p_title',
        'p_emoji',
        'p_metric_name',
        'p_metric_unit',
        'p_hide_metric_default',
        'p_start_date',
        'p_duration_days',
        'p_timezone',
        'p_max_members',
        'p_visibility',
      ]),
    );

    final group = createJourneyParams(
      'id2',
      JourneyDraft(
        kind: JourneyKind.group,
        templateId: TemplateId.workout30,
        title: ' Nhóm ',
        emoji: '💪',
        startDate: const LocalDate(2026, 10, 16),
        timezone: vnZone,
        visibility: JourneyVisibility.private,
      ),
    );
    expect(group['p_template_id'], 'workout_30');
    expect(
      group['p_visibility'],
      'group',
      reason: 'normalised like the server',
    );
    expect(group['p_title'], 'Nhóm');
    expect(group['p_max_members'], maxGroupMembers);
  });

  test('server journey row round-trips through drift', () async {
    final db = memoryDb();
    final row = journeyRow(
      'j1',
      ownerId: 'u1',
      kind: 'group',
      visibility: 'group',
      inviteCode: 'ABCD1234',
    )..['template_id'] = 'english_daily';
    await db.into(db.journeys).insert(journeyFromRemote(row));
    final j = journeyFromRow(await db.select(db.journeys).getSingle());
    expect(j.kind, JourneyKind.group);
    expect(j.templateId, TemplateId.englishDaily);
    expect(j.visibility, JourneyVisibility.group);
    expect(j.startDate, const LocalDate(2026, 10, 10));
    expect(j.endDate, const LocalDate(2026, 11, 8));
    expect(j.inviteCode, 'ABCD1234');
  });

  test('unknown enum wire values are rejected', () {
    final row = journeyRow('j1', ownerId: 'u1')..['template_id'] = 'weightLoss';
    expect(() => journeyFromRemote(row), throwsFormatException);
  });

  test('check-in upsert body and numeric metric parsing', () {
    final remote = {
      'id': 'c1',
      'journey_id': 'j1',
      'user_id': 'u1',
      'local_date': '2026-10-16',
      'captured_at': '2026-10-16T02:00:00+00:00',
      'photo_path': checkInPhotoPath('j1', 'u1', 'c1'),
      'thumb_path': checkInThumbPath('j1', 'u1', 'c1'),
      'from_library': true,
      'caption': null,
      'metric_value': '70.5', // numeric may arrive as a string
      'updated_at': '2026-10-16T02:00:01+00:00',
      'deleted_at': null,
    };
    final c = checkInFromRemote(remote);
    expect(c.metricValue, const Value<double?>(70.5));
    expect(c.uploaded, const Value(true));
    expect(c.capturedAt.value.isUtc, isTrue);

    final row = CheckInRow(
      id: 'c1',
      journeyId: 'j1',
      userId: 'u1',
      localDate: const LocalDate(2026, 10, 16),
      capturedAt: DateTime.utc(2026, 10, 16, 2),
      photoPath: checkInPhotoPath('j1', 'u1', 'c1'),
      thumbPath: checkInThumbPath('j1', 'u1', 'c1'),
      fromLibrary: false,
      metricValue: 1,
      uploaded: false,
    );
    final body = checkInToRemote(row);
    expect(body['captured_at'], '2026-10-16T02:00:00.000Z');
    expect(body['local_date'], '2026-10-16');
    expect(
      body.containsKey('hidden_by_leave'),
      isFalse,
      reason: 'server-managed',
    );
    expect(body.containsKey('uploaded'), isFalse);
  });

  test('group_today row -> MemberToday', () {
    final m = memberTodayFromRemote(
      {
        'user_id': 'u2',
        'username': 'lan',
        'display_name': 'Lan',
        'avatar_path': null,
        'role': 'member',
        'checked_in': true,
        'checkin_id': 'c9',
        'thumb_path': checkInThumbPath('j1', 'u2', 'c9'),
        'captured_at': '2026-10-16T02:00:00+00:00',
        'current_streak': 4,
      },
      journeyId: 'j1',
      today: const LocalDate(2026, 10, 16),
    );
    expect(m.role, MemberRole.member);
    expect(m.currentStreak, 4);
    expect(m.checkedIn, isTrue);
    expect(m.todayCheckIn!.photoPath, checkInPhotoPath('j1', 'u2', 'c9'));

    final none = memberTodayFromRemote(
      {
        'user_id': 'u3',
        'display_name': 'X',
        'role': 'owner',
        'checked_in': false,
      },
      journeyId: 'j1',
      today: const LocalDate(2026, 10, 16),
    );
    expect(none.checkedIn, isFalse);
    expect(none.role, MemberRole.owner);
  });

  test('membership tombstone maps to left', () {
    final m = membershipFromRemote(
      membershipRow('j', 'u')..['deleted_at'] = '2026-10-16T00:00:00+00:00',
    );
    expect(m.status.value, 'left');
  });
}
