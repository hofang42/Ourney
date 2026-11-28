// Client cache mirroring docs/contracts/schema.md (v1.1) plus the upload
// outbox and sync cursors. Enums are stored as their wire names (never
// `Enum.name`); mapping to domain models lives in lib/data/mapping.dart.
//
// Regenerate app_database.g.dart with `dart run build_runner build -d`.
import 'package:drift/drift.dart';
import 'package:ourney_core/ourney_core.dart';

part 'app_database.g.dart';

/// Stores instants as UTC microseconds since epoch (lossless, sortable).
class UtcMicrosConverter extends TypeConverter<DateTime, int> {
  const UtcMicrosConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMicrosecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.toUtc().microsecondsSinceEpoch;
}

/// Stores [LocalDate] as `YYYY-MM-DD` (sortable, same as Postgres `date`).
class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.toString();
}

@DataClassName('ProfileRow')
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarPath => text().nullable()();
  IntColumn get termsVersion =>
      integer().withDefault(const Constant(0))();

  /// Server `updated_at` (null while only local).
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('JourneyRow')
class Journeys extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get kind => text()();
  TextColumn get templateId => text()();
  TextColumn get title => text()();
  TextColumn get emoji => text()();
  TextColumn get metricName => text().nullable()();
  TextColumn get metricUnit => text().nullable()();
  BoolColumn get hideMetricDefault =>
      boolean().withDefault(const Constant(false))();
  TextColumn get startDate => text().map(const LocalDateConverter())();
  IntColumn get durationDays => integer().nullable()();
  TextColumn get timezone => text()();
  TextColumn get visibility => text()();
  TextColumn get status => text()();
  TextColumn get inviteCode => text().nullable()();
  IntColumn get maxMembers => integer().withDefault(const Constant(10))();
  TextColumn get publicToken => text().nullable()();

  /// `journeys.origin` wire value (v1.3, schema version 2).
  TextColumn get origin => text().withDefault(const Constant('live'))();

  /// Couple names (`journeys.couple_*_name`, 0007; schema version 3).
  TextColumn get coupleSelfName => text().nullable()();
  TextColumn get couplePartnerName => text().nullable()();

  /// Edit-journey fields (0012; schema version 5). `dna` is a JSON object.
  TextColumn get layout => text().nullable()();
  IntColumn get cover => integer().nullable()();
  IntColumn get color => integer().nullable()();
  TextColumn get reminderTime => text().nullable()();
  TextColumn get dna => text().nullable()();

  /// Client-only "archive" (JourneyRepository.archive): hidden from the list.
  BoolColumn get localArchived =>
      boolean().withDefault(const Constant(false))();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MembershipRow')
class Memberships extends Table {
  TextColumn get journeyId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();
  TextColumn get status => text()();
  IntColumn get joinedAt => integer().map(const UtcMicrosConverter())();
  BoolColumn get hideMetric => boolean().withDefault(const Constant(false))();
  BoolColumn get blurMedia => boolean().withDefault(const Constant(false))();

  /// `memberships.hide_extras` / `pinned` (0011; schema version 4).
  BoolColumn get hideExtras => boolean().withDefault(const Constant(false))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {journeyId, userId};
}

@DataClassName('CheckInRow')
class CheckIns extends Table {
  TextColumn get id => text()();
  TextColumn get journeyId => text()();
  TextColumn get userId => text()();
  TextColumn get localDate => text().map(const LocalDateConverter())();
  IntColumn get capturedAt => integer().map(const UtcMicrosConverter())();
  TextColumn get photoPath => text()();
  TextColumn get thumbPath => text()();
  BoolColumn get fromLibrary => boolean().withDefault(const Constant(false))();
  TextColumn get caption => text().nullable()();
  RealColumn get metricValue => real().nullable()();

  /// `check_ins.extras` as JSON text (0007; schema version 3).
  TextColumn get extras => text().withDefault(const Constant('{}'))();

  /// `check_ins.partner_photo_path` (couple journeys).
  TextColumn get partnerPhotoPath => text().nullable()();

  /// True once the server confirmed the row (and its media).
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();
  TextColumn get updatedAt => text().nullable()();

  // No unique (journey, user, local date): several check-ins per day are
  // allowed (FR-C7, server migration 0014; local schema version 6).
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReactionRow')
class Reactions extends Table {
  TextColumn get checkInId => text()();
  TextColumn get userId => text()();
  TextColumn get emoji => text()();
  IntColumn get createdAt => integer().map(const UtcMicrosConverter())();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {checkInId, userId};
}

/// Users the current user blocked (server `blocks` rows where blocker = me).
@DataClassName('BlockRow')
class Blocks extends Table {
  TextColumn get blockedId => text()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {blockedId};
}

/// Persistent outbox (FR-C6): processed strictly in [id] order.
@DataClassName('OutboxRow')
class UploadQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// One of `OutboxKind.wire`.
  TextColumn get kind => text()();

  /// Entity the item writes (e.g. `checkin:<journey>:<date>`); pull sync does
  /// not overwrite local rows while an item for the same key is pending.
  TextColumn get entityKey => text()();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  /// Permanently rejected by the server (kept for diagnostics, not retried).
  BoolColumn get dead => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer().map(const UtcMicrosConverter())();
}

/// Pull-sync cursors: server `updated_at` (exact string) per table, plus
/// bookkeeping keys such as `_owner` (user the cache belongs to).
/// DB cursor holding the JSON list of committed, deletable media trash paths
/// (see `MediaWipe`).
const String pendingTrashCursorKey = 'media.pendingTrash';

/// Prefix for isolated per-account unsynced outbox/post bundles kept across
/// account switches when an earlier session expired with unsynced local work.
const String isolatedOutboxCursorPrefix = 'outbox.isolated.';

String isolatedOutboxCursorKey(String userId) =>
    '$isolatedOutboxCursorPrefix$userId';

@DataClassName('SyncCursorRow')
class SyncCursor extends Table {
  TextColumn get tableKey => text()();
  TextColumn get cursor => text()();

  @override
  Set<Column> get primaryKey => {tableKey};
}

/// A durable "retell a past journey" job (schema version 7, not released yet:
/// these tables may still change in place): the draft, so a
/// kill mid-import is finished at the next launch. `id` is the journey's
/// client id, so a resume never creates a second journey.
@DataClassName('ImportJobRow')
class ImportJobs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get emoji => text()();
  TextColumn get templateId => text()();
  TextColumn get layout => text().nullable()();
  TextColumn get startDate => text().map(const LocalDateConverter())();
  TextColumn get endDate => text().map(const LocalDateConverter())();
  TextColumn get timezone => text()();
  BoolColumn get continues => boolean().withDefault(const Constant(false))();

  /// `ImportPhase.wire`.
  TextColumn get phase => text()();

  /// The account that started the job; no other account may run it.
  TextColumn get ownerId => text()();

  /// Saving was paused by the person; the launch resume leaves it alone.
  BoolColumn get paused => boolean().withDefault(const Constant(false))();

  /// `ImportFailure.wire` of the last failed create (null: none).
  TextColumn get createFailure => text().nullable()();
  IntColumn get createdAt => integer().map(const UtcMicrosConverter())();

  @override
  Set<Column> get primaryKey => {id};
}

/// One photo of an [ImportJobs] row. `id` is also the check-in id.
@TableIndex(name: 'import_job_photos_job_pos', columns: {#jobId, #position})
@DataClassName('ImportJobPhotoRow')
class ImportJobPhotos extends Table {
  TextColumn get caption => text().nullable()();
  TextColumn get id => text()();
  TextColumn get jobId => text()();
  IntColumn get position => integer()();
  TextColumn get sourcePath => text().nullable()();
  TextColumn get photoFile => text().nullable()();
  TextColumn get thumbFile => text().nullable()();
  TextColumn get localDate => text().map(const LocalDateConverter())();
  IntColumn get secondsOfDay => integer()();
  IntColumn get offsetMinutes => integer().nullable()();

  /// Content key of the picked photo (so "Edit details" still recognises it).
  TextColumn get dedupeKey => text().nullable()();

  /// `ImportPhotoState.wire`.
  TextColumn get state => text()();

  /// `ImportFailure.wire`.
  TextColumn get failure => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Profiles,
    Journeys,
    Memberships,
    CheckIns,
    Reactions,
    Blocks,
    UploadQueue,
    SyncCursor,
    ImportJobs,
    ImportJobPhotos,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement(
        'CREATE INDEX IF NOT EXISTS import_job_photos_job_pos '
        'ON import_job_photos (job_id, position)',
      );
    },
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS check_ins_journey_idx '
        'ON check_ins (journey_id, local_date)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS import_job_photos_job_pos '
        'ON import_job_photos (job_id, position)',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v1.3: journeys.origin. Rows cached before it are all lived.
        await m.addColumn(journeys, journeys.origin);
      }
      if (from < 3) {
        // 0007: per-skin Post extras, partner photo, couple names.
        await m.addColumn(checkIns, checkIns.extras);
        await m.addColumn(checkIns, checkIns.partnerPhotoPath);
        await m.addColumn(journeys, journeys.coupleSelfName);
        await m.addColumn(journeys, journeys.couplePartnerName);
      }
      if (from < 4) {
        // 0011: per-user pin and "hide my extras" preference.
        await m.addColumn(memberships, memberships.hideExtras);
        await m.addColumn(memberships, memberships.pinned);
      }
      if (from < 5) {
        // 0012: layout / cover / colour / reminder time / DNA.
        await m.addColumn(journeys, journeys.layout);
        await m.addColumn(journeys, journeys.cover);
        await m.addColumn(journeys, journeys.color);
        await m.addColumn(journeys, journeys.reminderTime);
        await m.addColumn(journeys, journeys.dna);
      }
      if (from < 6) {
        // 0014: several check-ins per day. SQLite cannot drop a table-level
        // UNIQUE, so the table is rebuilt (rows kept) and the index restored.
        await m.alterTable(TableMigration(checkIns));
        await customStatement(
          'CREATE INDEX IF NOT EXISTS check_ins_journey_idx '
          'ON check_ins (journey_id, local_date)',
        );
      }
      if (from < 7) {
        // Durable retell (import) jobs + profiles.terms_version (0018).
        await m.createTable(importJobs);
        await m.createTable(importJobPhotos);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS import_job_photos_job_pos '
          'ON import_job_photos (job_id, position)',
        );
        final cols = await customSelect(
          "SELECT 1 FROM pragma_table_info('profiles') "
          "WHERE name = 'terms_version'",
        ).get();
        if (cols.isEmpty) {
          await m.addColumn(profiles, profiles.termsVersion);
        }
      }
      if (from < 8) {
        // from < 7 already created the table with the current columns.
        final has = await customSelect(
          "SELECT 1 FROM pragma_table_info('import_job_photos') WHERE name = 'caption'",
        ).get();
        if (has.isEmpty) {
          await m.addColumn(importJobPhotos, importJobPhotos.caption);
        }
      }
    },
  );

  /// Removes every cached row (sign-out, account deletion, user switch).
  /// Keeps [pendingTrashCursorKey] (the media-wipe record must survive the
  /// wipe it is written alongside) and any [isolatedOutboxCursorPrefix]
  /// records (unsynced work of a previous account isolated across user switch).
  Future<void> wipe() => transaction(() async {
    for (final table in allTables) {
      if (table.actualTableName == syncCursor.actualTableName) {
        await (delete(
          syncCursor,
        )..where(
              (t) =>
                  t.tableKey.equals(pendingTrashCursorKey).not() &
                  t.tableKey.like('$isolatedOutboxCursorPrefix%').not(),
            ))
            .go();
        continue;
      }
      await delete(table).go();
    }
  });

  Future<String?> readCursor(String key) async {
    final row = await (select(
      syncCursor,
    )..where((t) => t.tableKey.equals(key))).getSingleOrNull();
    return row?.cursor;
  }

  Future<void> writeCursor(String key, String value) => into(syncCursor)
      .insertOnConflictUpdate(
        SyncCursorCompanion.insert(tableKey: key, cursor: value),
      );
}
