import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/mapping.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

void main() {
  test('v1 → v2 adds journeys.origin (existing rows are live)', () async {
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
    await v2.customStatement('pragma user_version = 1');
    await v2.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final row = await db.select(db.journeys).getSingle();
    expect(row.origin, 'live');
    expect(journeyFromRow(row).origin, JourneyOrigin.live);
    final version = await db.customSelect('pragma user_version').getSingle();
    expect(version.data.values.single, 2);
  });
}
