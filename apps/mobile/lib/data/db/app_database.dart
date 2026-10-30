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

  /// True once the server confirmed the row (and its media).
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {journeyId, userId, localDate},
  ];
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
@DataClassName('SyncCursorRow')
class SyncCursor extends Table {
  TextColumn get tableKey => text()();
  TextColumn get cursor => text()();

  @override
  Set<Column> get primaryKey => {tableKey};
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX check_ins_journey_idx ON check_ins (journey_id, local_date)',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v1.3: journeys.origin. Rows cached before it are all lived.
        await m.addColumn(journeys, journeys.origin);
      }
    },
  );

  /// Removes every cached row (sign-out, account deletion, user switch).
  Future<void> wipe() => transaction(() async {
    for (final table in allTables) {
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
