import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/data_layer.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/journey_clock.dart';
import 'package:ourney/data/remote/remote_api.dart';
import 'package:ourney_core/ourney_core.dart';

/// Asia/Ho_Chi_Minh (no DST) without loading the tz database.
const Duration vnOffset = Duration(hours: 7);
const String vnZone = 'Asia/Ho_Chi_Minh';

/// Mutable test clock.
class TestClock {
  TestClock(this.value);
  DateTime value;
  DateTime call() => value;
  void advance(Duration d) => value = value.add(d);
}

JourneyClock testJourneyClock(TestClock clock) =>
    JourneyClock(now: clock.call, offsetOf: (_, _) => vnOffset);

/// Deterministic v4-shaped ids: 00000000-0000-4000-8000-00000000000N.
String Function() sequentialIds([String prefix = '0000']) {
  var n = 0;
  return () {
    n++;
    return '$prefix'
        '0000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
  };
}

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

Directory tempDir() {
  final dir = Directory.systemTemp.createTempSync('ourney_data_test');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return dir;
}

/// Writes a fake JPEG (photo + thumb) as a camera feature would.
({String photo, String thumb}) fakeCapture(Directory dir, String name) {
  final photo = File('${dir.path}/$name.jpg')..writeAsBytesSync([1, 2, 3]);
  final thumb = File('${dir.path}/${name}_t.jpg')..writeAsBytesSync([4, 5]);
  return (photo: photo.path, thumb: thumb.path);
}

JourneyDraft soloDraft({
  String title = 'Giảm cân',
  LocalDate start = const LocalDate(2026, 10, 10),
  int? durationDays = 30,
  TemplateId template = TemplateId.weightLoss,
}) => JourneyDraft(
  kind: JourneyKind.solo,
  templateId: template,
  title: title,
  emoji: '🔥',
  startDate: start,
  durationDays: durationDays,
  timezone: vnZone,
  metricName: 'Cân nặng',
  metricUnit: 'kg',
  hideMetricDefault: true,
);

DataLayer localLayer({
  required AppDatabase db,
  required Directory media,
  required TestClock clock,
  String guest = 'aaaaaaaa-0000-4000-8000-000000000001',
}) {
  final layer = DataLayer.localOnly(
    db: db,
    mediaRoot: media,
    guestUserId: guest,
    clock: testJourneyClock(clock),
    newId: sequentialIds(),
  );
  addTearDown(layer.dispose);
  return layer;
}

/// A recorded call on [FakeRemoteApi].
class RemoteCall {
  RemoteCall(this.method, this.target, [this.args]);
  final String method;
  final String target;
  final Object? args;

  @override
  String toString() => '$method($target, $args)';
}

/// In-memory [RemoteApi]: records calls, serves `select` from [tables], and
/// answers RPCs through [rpcHandlers]. Set [failure] to make every call throw
/// (e.g. `offline`), or [failOnce] for a single failure.
class FakeRemoteApi implements RemoteApi {
  FakeRemoteApi({this.userId = 'bbbbbbbb-0000-4000-8000-000000000001'});

  String? userId;
  final calls = <RemoteCall>[];
  final tables = <String, List<RemoteRow>>{};
  final rpcHandlers = <String, Object? Function(Map<String, dynamic>)>{};
  final uploaded = <String, List<int>>{};
  final removed = <String>[];
  final storageObjects = <String, List<int>>{};
  OurneyException? failure;
  final failOnce = <OurneyException>[];
  final _auth = StreamController<String?>.broadcast();

  void emitUser(String? id) {
    userId = id;
    _auth.add(id);
  }

  Future<void> _maybeFail(String method, String target, [Object? args]) async {
    calls.add(RemoteCall(method, target, args));
    if (failOnce.isNotEmpty) throw failOnce.removeAt(0);
    final f = failure;
    if (f != null) throw f;
  }

  List<RemoteCall> callsOf(String method) => [
    for (final c in calls)
      if (c.method == method) c,
  ];

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => _auth.stream;

  @override
  Future<void> sendOtp(String email) => _maybeFail('sendOtp', email);

  @override
  Future<void> verifyOtp(String email, String code) async {
    await _maybeFail('verifyOtp', email, code);
  }

  @override
  Future<void> signOut({bool global = false}) async {
    calls.add(RemoteCall('signOut', global ? 'global' : 'local'));
    emitUser(null);
  }

  @override
  Future<List<RemoteRow>> select(
    String table, {
    Map<String, Object> eq = const {},
    Map<String, List<Object>> inList = const {},
    String? updatedSince,
    bool onlyLive = false,
    int? limit,
  }) async {
    await _maybeFail('select', table, {'eq': eq, 'since': updatedSince});
    final since = updatedSince == null ? null : DateTime.parse(updatedSince);
    final rows =
        [
          for (final r in tables[table] ?? const <RemoteRow>[])
            if (eq.entries.every((e) => r[e.key] == e.value) &&
                inList.entries.every((e) => e.value.contains(r[e.key])) &&
                (!onlyLive || r['deleted_at'] == null) &&
                (since == null ||
                    !DateTime.parse(r['updated_at'] as String).isBefore(since)))
              r,
        ]..sort(
          (a, b) =>
              (a['updated_at'] as String).compareTo(b['updated_at'] as String),
        );
    return limit == null ? rows : rows.take(limit).toList();
  }

  @override
  Future<void> upsert(
    String table,
    RemoteRow row, {
    required String onConflict,
  }) => _maybeFail('upsert', table, {'row': row, 'onConflict': onConflict});

  @override
  Future<void> insert(String table, RemoteRow row) =>
      _maybeFail('insert', table, row);

  @override
  Future<void> delete(String table, {required Map<String, Object> match}) =>
      _maybeFail('delete', table, match);

  /// Realtime channels opened through [watchInserts], by `table` or
  /// `table:column=value`. Push rows with [emitInsert].
  final realtime = <String, StreamController<RemoteRow>>{};

  /// Number of realtime subscriptions currently open.
  int get openChannels => realtime.length;

  @override
  Stream<RemoteRow> watchInserts(
    String table, {
    String? column,
    String? value,
  }) {
    final key = column == null ? table : '$table:$column=$value';
    late final StreamController<RemoteRow> c;
    c = StreamController<RemoteRow>(
      onListen: () => realtime[key] = c,
      onCancel: () {
        if (identical(realtime[key], c)) realtime.remove(key);
      },
    );
    return c.stream;
  }

  /// Delivers [row] to the realtime channel [key] (see [realtime]).
  void emitInsert(String key, RemoteRow row) => realtime[key]?.add(row);

  @override
  Future<void> uploadBytes(String path, List<int> bytes) async {
    await _maybeFail('upload', path);
    uploaded[path] = List.of(bytes);
  }

  /// Rows `update` reports as changed (default: one echo row).
  List<RemoteRow>? updateResult;

  @override
  Future<List<RemoteRow>> update(
    String table,
    RemoteRow values, {
    required Map<String, Object> match,
  }) async {
    await _maybeFail('update', table, {'values': values, 'match': match});
    return updateResult ??
        [
          {...match, ...values},
        ];
  }

  @override
  Future<Object?> rpc(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) async {
    await _maybeFail('rpc', fn, params);
    final handler = rpcHandlers[fn];
    return handler == null ? null : handler(params);
  }

  @override
  Future<Object?> invokeFunction(String name, {Object? body}) async {
    await _maybeFail('invoke', name, body);
    return {'deleted': true};
  }

  @override
  Future<void> uploadFile(String path, File file) async {
    await _maybeFail('upload', path);
    uploaded[path] = file.readAsBytesSync();
  }

  @override
  Future<List<String>> listFiles(String prefix) async {
    await _maybeFail('list', prefix);
    return [
      for (final k in {...uploaded.keys, ...storageObjects.keys})
        if (k.startsWith('$prefix/')) k,
    ];
  }

  @override
  Future<void> removeFiles(List<String> paths) async {
    await _maybeFail('remove', paths.join(','));
    removed.addAll(paths);
  }

  @override
  Future<void> downloadToFile(String path, File target) async {
    await _maybeFail('download', path);
    final bytes = storageObjects[path];
    if (bytes == null) throw OurneyException(OurneyErrorCode.notFound, path);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes);
  }
}

/// Timer factory that records delays instead of scheduling anything.
class RecordingTimers {
  final delays = <Duration>[];
  Timer call(Duration d, void Function() _) {
    delays.add(d);
    return _NoopTimer();
  }
}

/// `Timer.periodic` stand-in: records periodic timers; [tick] fires every
/// active one once.
class FakePeriodicTimers {
  final timers = <FakePeriodicTimer>[];

  Timer call(Duration interval, void Function(Timer) tick) {
    final t = FakePeriodicTimer(interval, tick);
    timers.add(t);
    return t;
  }

  List<FakePeriodicTimer> get active => [
    for (final t in timers)
      if (t.isActive) t,
  ];

  void tick() {
    for (final t in active) {
      t.fire();
    }
  }
}

class FakePeriodicTimer implements Timer {
  FakePeriodicTimer(this.interval, this._tick);
  final Duration interval;
  final void Function(Timer) _tick;
  bool _active = true;
  int _ticks = 0;

  void fire() {
    if (!_active) return;
    _ticks++;
    _tick(this);
  }

  @override
  void cancel() => _active = false;
  @override
  bool get isActive => _active;
  @override
  int get tick => _ticks;
}

class _NoopTimer implements Timer {
  bool _active = true;
  @override
  void cancel() => _active = false;
  @override
  bool get isActive => _active;
  @override
  int get tick => 0;
}

DataLayer supabaseLayer({
  required AppDatabase db,
  required Directory media,
  required TestClock clock,
  required FakeRemoteApi remote,
  RecordingTimers? timers,
  FakePeriodicTimers? socialTimers,
}) {
  final layer = DataLayer.supabase(
    db: db,
    mediaRoot: media,
    remote: remote,
    clock: testJourneyClock(clock),
    newId: sequentialIds('1111'),
    timer: (timers ?? RecordingTimers()).call,
    autoSync: false,
    socialPeriodic: (socialTimers ?? FakePeriodicTimers()).call,
  );
  addTearDown(layer.dispose);
  return layer;
}

/// Server-shaped `journeys` row for [id].
RemoteRow journeyRow(
  String id, {
  required String ownerId,
  String kind = 'solo',
  String visibility = 'private',
  String status = 'active',
  String updatedAt = '2026-10-16T01:00:00.000000+00:00',
  String? inviteCode,
  String? deletedAt,
}) => {
  'id': id,
  'owner_id': ownerId,
  'kind': kind,
  'template_id': 'weight_loss',
  'title': 'Server journey',
  'emoji': '🔥',
  'metric_name': 'Cân nặng',
  'metric_unit': 'kg',
  'hide_metric_default': true,
  'start_date': '2026-10-10',
  'duration_days': 30,
  'timezone': vnZone,
  'visibility': visibility,
  'status': status,
  'invite_code': inviteCode,
  'max_members': kind == 'solo' ? 1 : 10,
  'public_token': null,
  'created_at': updatedAt,
  'updated_at': updatedAt,
  'deleted_at': deletedAt,
};

RemoteRow membershipRow(
  String journeyId,
  String userId, {
  String role = 'owner',
  String status = 'active',
  String updatedAt = '2026-10-16T01:00:00.000000+00:00',
}) => {
  'journey_id': journeyId,
  'user_id': userId,
  'role': role,
  'status': status,
  'joined_at': '2026-10-10T01:00:00+00:00',
  'hide_metric': true,
  'blur_media': false,
  'created_at': updatedAt,
  'updated_at': updatedAt,
  'deleted_at': null,
};
