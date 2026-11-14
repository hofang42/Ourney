import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/mapping.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

void main() {
  test('v1 → v3 adds journeys.origin (existing rows are live)', () async {
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
    expect(version.data.values.single, 3);
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
}

/// Turns a current database back into the pre-0007 shape.
Future<void> _dropV3Columns(AppDatabase db) async {
  await db.customStatement('alter table check_ins drop column extras');
  await db.customStatement(
    'alter table check_ins drop column partner_photo_path',
  );
  await db.customStatement('alter table journeys drop column couple_self_name');
  await db.customStatement(
    'alter table journeys drop column couple_partner_name',
  );
}
