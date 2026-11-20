import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ourney_core/ourney_core.dart';

import '../db/app_database.dart';

/// Kinds of queued writes. [wire] is what is persisted in `upload_queue.kind`.
enum OutboxKind {
  createJourney('create_journey'),
  upsertCheckIn('upsert_check_in'),
  deleteMedia('delete_media'),
  react('react'),
  updateMembership('update_membership'),
  updateJourney('update_journey');

  const OutboxKind(this.wire);
  final String wire;

  static OutboxKind? fromWire(String wire) {
    for (final k in values) {
      if (k.wire == wire) return k;
    }
    return null;
  }
}

/// Executes one queued item against the server. Throws [OurneyException].
typedef OutboxExecutor = Future<void> Function(
  OutboxKind kind,
  Map<String, dynamic> payload,
);

/// Delay before attempt `attempts + 1`: 2 s, 4 s, 8 s ... capped at 15 min.
Duration outboxBackoff(int attempts) {
  if (attempts <= 0) return Duration.zero;
  const cap = Duration(minutes: 15);
  final exp = attempts > 20 ? 20 : attempts - 1;
  final d = const Duration(seconds: 2) * (1 << exp);
  return d > cap ? cap : d;
}

/// Errors worth retrying later (network, auth refresh, server hiccups).
/// Everything else is a permanent rejection (the item is marked dead).
bool isTransient(OurneyErrorCode code) => switch (code) {
  OurneyErrorCode.offline ||
  OurneyErrorCode.unknown ||
  OurneyErrorCode.internal ||
  OurneyErrorCode.unauthenticated ||
  OurneyErrorCode.rateLimited ||
  OurneyErrorCode.storageListingFailed ||
  OurneyErrorCode.storageCleanupFailed ||
  OurneyErrorCode.storageCleanupIncomplete => true,
  _ => false,
};

/// Persistent FIFO outbox (FR-C6) stored in drift `upload_queue`, so it
/// survives app restarts. Items run strictly in insertion order (a check-in
/// never overtakes the `create_journey` it depends on). A transient failure
/// stops the pass and schedules a retry with [outboxBackoff]; a permanent one
/// marks the item dead and moves on.
class Outbox {
  Outbox(
    this._db, {
    required this._executor,
    DateTime Function()? now,
    Timer Function(Duration, void Function())? timer,
    this.maxAttempts = 50,
  }) : _now = now ?? DateTime.now,
       _timer = timer ?? Timer.new;

  final AppDatabase _db;
  final OutboxExecutor _executor;
  final DateTime Function() _now;
  final Timer Function(Duration, void Function()) _timer;

  /// Non-`offline` failures after which an item is given up.
  final int maxAttempts;

  Timer? _retry;
  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;

  /// Consecutive failed passes (database errors); drives the retry backoff.
  int _passFailures = 0;
  final _processed = StreamController<OutboxKind>.broadcast();

  /// Emits the kind of each item the server confirmed.
  Stream<OutboxKind> get processed => _processed.stream;

  /// [delay] keeps the item out of a flush for that long (the caller is
  /// sending it right now and only wants a later flush to replay it).
  Future<int> enqueue(
    OutboxKind kind,
    String entityKey,
    Map<String, dynamic> payload, {
    Duration delay = Duration.zero,
  }) => _db
      .into(_db.uploadQueue)
      .insert(
        UploadQueueCompanion.insert(
          kind: kind.wire,
          entityKey: entityKey,
          payload: jsonEncode(payload),
          createdAt: _now(),
          nextAttemptAt: delay == Duration.zero
              ? const Value.absent()
              : Value(_now().toUtc().add(delay).microsecondsSinceEpoch),
        ),
      );

  /// Drops pending (not yet sent) items for [entityKey]; [includeDead] also
  /// drops items already given up on.
  Future<void> cancel(
    String entityKey, {
    OutboxKind? kind,
    bool includeDead = false,
  }) =>
      (_db.delete(_db.uploadQueue)..where(
            (t) =>
                t.entityKey.equals(entityKey) &
                (includeDead ? const Constant(true) : t.dead.equals(false)) &
                (kind == null
                    ? const Constant(true)
                    : t.kind.equals(kind.wire)),
          ))
          .go();

  /// Clears the delay of the live items of [entityKey].
  Future<void> makeDue(String entityKey) =>
      (_db.update(
            _db.uploadQueue,
          )..where((t) => t.entityKey.equals(entityKey) & t.dead.equals(false)))
          .write(const UploadQueueCompanion(nextAttemptAt: Value(0)));

  /// Entity keys with live (not dead) items: pull sync must not overwrite them.
  Future<Set<String>> pendingKeys() async {
    final rows = await (_db.select(
      _db.uploadQueue,
    )..where((t) => t.dead.equals(false))).get();
    return {for (final r in rows) r.entityKey};
  }

  /// Live (not dead) items, oldest first.
  Future<List<OutboxRow>> pendingRows() =>
      (_db.select(_db.uploadQueue)
            ..where((t) => t.dead.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Stream<int> watchPending({OutboxKind? kind}) {
    final count = _db.uploadQueue.id.count();
    final q = _db.selectOnly(_db.uploadQueue)
      ..addColumns([count])
      ..where(
        _db.uploadQueue.dead.equals(false) &
            (kind == null
                ? const Constant(true)
                : _db.uploadQueue.kind.equals(kind.wire)),
      );
    return q.map((r) => r.read(count) ?? 0).watchSingle();
  }

  /// Processes due items. [force] ignores backoff (connectivity regained,
  /// app resumed). Concurrent calls coalesce into one extra pass.
  Future<void> flush({bool force = false}) {
    if (_disposed) return Future.value();
    if (_running != null) {
      _again = true;
      return _running!;
    }
    final run = _runGuarded(force).whenComplete(() => _running = null);
    _running = run;
    return run;
  }

  /// A database error inside a pass (e.g. on `_markDead` or the delete after
  /// a successful execute) must not leak out of the `unawaited(flush())`
  /// callers: it is logged and a retry is armed.
  Future<void> _runGuarded(bool force) async {
    try {
      await _run(force);
      _passFailures = 0;
    } on Object catch (e) {
      debugPrint('outbox: flush failed: $e');
      // A closed database never recovers: do not keep a timer alive for it.
      if (!await _isDatabaseUsable()) return;
      _schedule(outboxBackoff(++_passFailures));
    }
  }

  Future<bool> _isDatabaseUsable() async {
    try {
      await _db.customSelect('SELECT 1').get();
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _run(bool force) async {
    var forceNow = force;
    do {
      _again = false;
      await _pass(forceNow);
      forceNow = false;
    } while (_again && !_disposed);
  }

  Future<void> _pass(bool force) async {
    while (!_disposed) {
      final head =
          await (_db.select(_db.uploadQueue)
                ..where((t) => t.dead.equals(false))
                ..orderBy([(t) => OrderingTerm.asc(t.id)])
                ..limit(1))
              .getSingleOrNull();
      if (head == null) return;

      final nowUs = _now().toUtc().microsecondsSinceEpoch;
      if (!force && head.nextAttemptAt > nowUs) {
        _schedule(Duration(microseconds: head.nextAttemptAt - nowUs));
        return;
      }

      final kind = OutboxKind.fromWire(head.kind);
      if (kind == null) {
        await _markDead(head, 'unknown kind ${head.kind}');
        continue;
      }
      try {
        await _executor(
          kind,
          (jsonDecode(head.payload) as Map).cast<String, dynamic>(),
        );
      } on Object catch (e) {
        final error = e is OurneyException
            ? e
            : OurneyException(OurneyErrorCode.unknown, e.toString());
        if (!isTransient(error.error)) {
          await _markDead(head, error.toString());
          continue;
        }
        final attempts = head.attempts + 1;
        // Waiting for the network or a fresh sign-in never kills an item.
        final waiting =
            error.error == OurneyErrorCode.offline ||
            error.error == OurneyErrorCode.unauthenticated;
        if (!waiting && attempts >= maxAttempts) {
          await _markDead(head, error.toString());
          continue;
        }
        final delay = outboxBackoff(attempts);
        await (_db.update(
          _db.uploadQueue,
        )..where((t) => t.id.equals(head.id))).write(
          UploadQueueCompanion(
            attempts: Value(attempts),
            nextAttemptAt: Value(nowUs + delay.inMicroseconds),
            lastError: Value(error.toString()),
          ),
        );
        _schedule(delay);
        return;
      }
      await (_db.delete(
        _db.uploadQueue,
      )..where((t) => t.id.equals(head.id))).go();
      if (!_processed.isClosed) _processed.add(kind);
    }
  }

  Future<void> _markDead(OutboxRow row, String reason) =>
      (_db.update(_db.uploadQueue)..where((t) => t.id.equals(row.id))).write(
        UploadQueueCompanion(dead: const Value(true), lastError: Value(reason)),
      );

  void _schedule(Duration delay) {
    _retry?.cancel();
    if (_disposed) return;
    _retry = _timer(delay, () {
      _retry = null;
      unawaited(flush());
    });
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    unawaited(_processed.close());
  }
}
