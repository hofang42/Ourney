import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/mapping.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

void main() {
  test('v1 → v5 adds journeys.origin (existing rows are live)', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final file = File('${tempDir().path}/ourney.sqlite');

    // Build the current schema, then turn it back into v1: no origin column.
    final v2 = AppDatabase(NativeDatabase(file));
    await v2.customSelect('select 1').get();
    await v2.customStatement(
      'insert into journeys (id, owner_id, kind, template_id, title, emoji, '
      "start_date, timezone, visibility, status) values ('j1', 'u1', 'solo', "
      "'custom', 'Old', '🔥', '2026-01-01', 'UTC', 'private', 'active')",
    );
    await v2.customStatement('alter table journeys drop column origin');
    await _dropV3Columns(v2);
    await v2.customStatement('pragma user_version = 1');
    await v2.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final row = await db.select(db.journeys).getSingle();
    expect(row.origin, 'live');
    expect(journeyFromRow(row).origin, JourneyOrigin.live);
    final version = await db.customSelect('pragma user_version').getSingle();
    expect(version.data.values.single, 7);
  });

  test('v2 → v3 adds extras, partner photo and couple names', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final file = File('${tempDir().path}/ourney_v2.sqlite');
    final v3 = AppDatabase(NativeDatabase(file));
    await v3.customSelect('select 1').get();
    await v3.customStatement(
      'insert into journeys (id, owner_id, kind, template_id, title, emoji, '
      "start_date, timezone, visibility, status) values ('j1', 'u1', 'solo', "
      "'custom', 'Old', '🔥', '2026-01-01', 'UTC', 'private', 'active')",
    );
    await v3.customStatement(
      'insert into check_ins (id, journey_id, user_id, local_date, captured_at, '
      "photo_path, thumb_path) values ('c1', 'j1', 'u1', '2026-01-01', 0, 'p', 't')",
    );
    await _dropV3Columns(v3);
    await v3.customStatement('pragma user_version = 2');
    await v3.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final check = await db.select(db.checkIns).getSingle();
    expect(check.extras, '{}');
    expect(check.partnerPhotoPath, isNull);
    final journey = await db.select(db.journeys).getSingle();
    expect(journey.coupleSelfName, isNull);
    expect(journey.couplePartnerName, isNull);
  });

  test('v3 → v4 adds membership pin and hide_extras (default off)', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final file = File('${tempDir().path}/ourney_v3.sqlite');
    final v4 = AppDatabase(NativeDatabase(file));
    await v4.customSelect('select 1').get();
    await v4.customStatement(
      'insert into memberships (journey_id, user_id, role, status, joined_at) '
      "values ('j1', 'u1', 'owner', 'active', 0)",
    );
    await v4.customStatement('alter table memberships drop column hide_extras');
    await v4.customStatement('alter table memberships drop column pinned');
    await _dropV5Columns(v4);
    await v4.customStatement('pragma user_version = 3');
    await v4.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final m = await db.select(db.memberships).getSingle();
    expect(m.hideExtras, isFalse);
    expect(m.pinned, isFalse);
  });

  test('v4 to v5 adds journey layout, cover, colour, reminder, dna', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final file = File('${tempDir().path}/ourney_v4.sqlite');
    final v5 = AppDatabase(NativeDatabase(file));
    await v5.customSelect('select 1').get();
    await v5.customStatement(
      'insert into journeys (id, owner_id, kind, template_id, title, emoji, '
      'start_date, timezone, visibility, status) values '
      "('j1', 'u1', 'solo', 'custom', 'T', 'x', '2026-01-01', 'UTC', "
      "'private', 'active')",
    );
    await _dropV5Columns(v5);
    await v5.customStatement('pragma user_version = 4');
    await v5.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final j = await db.select(db.journeys).getSingle();
    expect(j.layout, isNull);
    expect(j.dna, isNull);
  });

  test('v5 to v6 drops the one-check-in-per-day unique (bug #2)', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final file = File('${tempDir().path}/ourney_v5.sqlite');
    final v6 = AppDatabase(NativeDatabase(file));
    await v6.customSelect('select 1').get();
    // Rebuild check_ins with the v5 table-level UNIQUE.
    final ddl = await v6
        .customSelect(
          "select sql from sqlite_master where type = 'table' "
          "and name = 'check_ins'",
        )
        .getSingle();
    final sql = ddl.data['sql'] as String;
    final v5Sql =
        '${sql.substring(0, sql.lastIndexOf(')'))}, '
        'UNIQUE (journey_id, user_id, local_date))';
    await v6.customStatement('drop table check_ins');
    await v6.customStatement(v5Sql);
    await v6.customStatement(
      'insert into check_ins (id, journey_id, user_id, local_date, captured_at, '
      "photo_path, thumb_path) values ('c1', 'j1', 'u1', '2026-01-01', 0, 'p', 't')",
    );
    await expectLater(
      v6.customStatement(
        'insert into check_ins (id, journey_id, user_id, local_date, '
        "captured_at, photo_path, thumb_path) values ('c2', 'j1', 'u1', "
        "'2026-01-01', 1, 'p2', 't2')",
      ),
      throwsA(anything),
      reason: 'the v5 shape really rejects a second photo',
    );
    await v6.customStatement('pragma user_version = 5');
    await v6.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    await db.customStatement(
      'insert into check_ins (id, journey_id, user_id, local_date, captured_at, '
      "photo_path, thumb_path) values ('c2', 'j1', 'u1', '2026-01-01', 1, 'p2', 't2')",
    );
    final rows = await db.select(db.checkIns).get();
    expect(rows.map((r) => r.id), unorderedEquals(['c1', 'c2']));
    final index = await db
        .customSelect(
          "select name from sqlite_master where type = 'index' "
          "and name = 'check_ins_journey_idx'",
        )
        .get();
    expect(index, hasLength(1));
  });

  test('v6 to v7 adds the durable import job tables', () async {
    final dir = Directory.systemTemp.createTempSync('ourney_mig_v7');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final v7 = AppDatabase(NativeDatabase(file));
    // Rows a v6 install already had.
    await v7.customStatement(
      'insert into journeys (id, owner_id, kind, template_id, title, emoji, '
      'start_date, timezone, visibility, status) values '
      "('j1', 'u1', 'solo', 'custom', 'T', 'x', '2026-01-01', 'UTC', "
      "'private', 'active')",
    );
    await v7.customStatement(
      'insert into check_ins (id, journey_id, user_id, local_date, captured_at, '
      "photo_path, thumb_path) values ('c1', 'j1', 'u1', '2026-01-01', 0, 'p', 't')",
    );
    await v7.customStatement('drop table import_job_photos');
    await v7.customStatement('drop table import_jobs');
    await v7.customStatement('pragma user_version = 6');
    await v7.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final tables = await db
        .customSelect(
          "select name from sqlite_master where type = 'table' "
          "and name like 'import_job%'",
        )
        .get();
    // The upgrade kept what was there.
    expect((await db.select(db.journeys).getSingle()).id, 'j1');
    expect((await db.select(db.checkIns).getSingle()).id, 'c1');
    expect(
      tables.map((r) => r.data['name']),
      unorderedEquals(['import_jobs', 'import_job_photos']),
    );
    final idx = await db
        .customSelect(
          "select name from sqlite_master where type = 'index' "
          "and name = 'import_job_photos_job_pos'",
        )
        .get();
    expect(idx, hasLength(1));
  });

  test('existing v7 database without import_job_photos_job_pos index receives it on open (FS-34)', () async {
    final dir = Directory.systemTemp.createTempSync('ourney_mig_v7_idx');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final initial = AppDatabase(NativeDatabase(file));
    await initial.customStatement('drop index if exists import_job_photos_job_pos');
    await initial.customStatement('pragma user_version = 7');
    await initial.close();

    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    final idx = await reopened
        .customSelect(
          "select name from sqlite_master where type = 'index' "
          "and name = 'import_job_photos_job_pos'",
        )
        .get();
    expect(idx, hasLength(1));
  });
}

/// Turns a current database back into the pre-0007 shape.
Future<void> _dropV3Columns(AppDatabase db) async {
  await db.customStatement('alter table memberships drop column hide_extras');
  await db.customStatement('alter table memberships drop column pinned');
  await db.customStatement('alter table check_ins drop column extras');
  await db.customStatement(
    'alter table check_ins drop column partner_photo_path',
  );
  await _dropV5Columns(db);
  await db.customStatement('alter table journeys drop column couple_self_name');
  await db.customStatement(
    'alter table journeys drop column couple_partner_name',
  );
}

/// Turns a current database back into the pre-0012 shape.
Future<void> _dropV5Columns(AppDatabase db) async {
  for (final c in ['layout', 'cover', 'color', 'reminder_time', 'dna']) {
    await db.customStatement('alter table journeys drop column $c');
  }
}
