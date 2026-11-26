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
  updateJourney('update_journey'),
  renameCouple('rename_couple');

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
  OurneyErrorCode.clientOutdated ||
  OurneyErrorCode.serverOutdated ||
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
    this.onDead,
  }) : _now = now ?? DateTime.now,
       _timer = timer ?? Timer.new;

  final AppDatabase _db;
  final OutboxExecutor _executor;
  final DateTime Function() _now;
  final Timer Function(Duration, void Function()) _timer;

  /// Non-`offline` failures after which an item is given up.
  final int maxAttempts;

  /// Called after an item was marked dead.
  final void Function(OutboxRow row)? onDead;

  Timer? _retry;
  Future<void>? _running;

  /// Calls of [exclusive] that are waiting or running.
  int _exclusive = 0;

  /// Tail of the [exclusive] queue: a mutex, calls run one after another.
  Future<void> _lockTail = Future<void>.value();

  /// Flushes asked while the lock is held: they run (and complete) once it
  /// is free, with the strongest `force` among them.
  final List<Completer<void>> _blockedFlushes = [];
  bool _blockedForce = false;

  /// Runs [fn] while no pass is running and none can start. Calls queue up
  /// one behind the other (a mutex); flushes asked meanwhile wait for the lock
  /// and then run. For read-modify-write on queued rows, e.g. merging a queued
  /// update into a new one.
  ///
  /// Deadlocks: [fn] must not await [flush], must not call [exclusive] again
  /// (nested calls wait for themselves), and [exclusive] must never be called
  /// from inside an executor (the pass it waits for is the caller). It must
  /// never be called inside a `db.transaction` either: the lock holder may
  /// wait for the database while the transaction waits for the lock.
  Future<T> exclusive<T>(Future<T> Function() fn) async {
    _exclusive++;
    final prev = _lockTail;
    final release = Completer<void>();
    _lockTail = release.future;
    try {
      await prev;
      while (_running != null) {
        await _running;
      }
      return await fn();
    } finally {
      _exclusive--;
      release.complete();
      if (_exclusive == 0 && _blockedFlushes.isNotEmpty) {
        final waiting = List.of(_blockedFlushes);
        _blockedFlushes.clear();
        final force = _blockedForce;
        _blockedForce = false;
        final run = flush(force: force);
        for (final c in waiting) {
          unawaited(run.whenComplete(c.complete));
        }
      }
    }
  }

  bool _again = false;
  bool _forceAgain = false;
  bool _disposed = false;
  bool _paused = false;
  int _abortEpoch = 0;

  void setPaused(bool paused) {
    _paused = paused;
    if (paused) abortCurrentPass();
  }

  /// Cancels any running pass after its current step so a session wipe
  /// (`signOut`, `deleteAccount`) does not wait for the whole queue or write
  /// stale attempt updates back into the wiped table (FS-27).
  void abortCurrentPass() {
    _abortEpoch++;
    _again = false;
    _forceAgain = false;
    _retry?.cancel();
  }

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

  /// Items given up on (permanent failure or too many attempts), oldest
  /// first. They stay in the queue only so the UI can offer retry / discard.
  Stream<List<OutboxRow>> watchDead({OutboxKind? kind}) =>
      (_db.select(_db.uploadQueue)
            ..where(
              (t) =>
                  t.dead.equals(true) &
                  (kind == null
                      ? const Constant(true)
                      : t.kind.equals(kind.wire)),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  /// Revives dead items [ids] (attempts reset) and flushes.
  Future<void> retryDead(Iterable<int> ids) async {
    await (_db.update(_db.uploadQueue)..where((t) => t.id.isIn(ids))).write(
      const UploadQueueCompanion(
        dead: Value(false),
        attempts: Value(0),
        nextAttemptAt: Value(0),
      ),
    );
    unawaited(flush(force: true));
  }

  /// Removes queue items [ids] (the caller drops what they were for).
  Future<void> deleteItems(Iterable<int> ids) =>
      (_db.delete(_db.uploadQueue)..where((t) => t.id.isIn(ids))).go();

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
    if (_disposed || _paused) return Future.value();
    if (_exclusive > 0) {
      // Held by [exclusive]: run (and complete) once it is over.
      _blockedForce = _blockedForce || force;
      final c = Completer<void>();
      _blockedFlushes.add(c);
      return c.future;
    }
    if (_running != null) {
      _again = true;
      // A forced flush asked while one is running must still ignore backoff.
      if (force) _forceAgain = true;
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
      // A flush() that arrived meanwhile was coalesced into this failed run.
      if (_again) _schedule(Duration.zero);
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
      final forced = forceNow || _forceAgain;
      _forceAgain = false;
      forceNow = false;
      await _pass(forced);
    } while (_again && !_disposed && !_paused);
  }

  Future<void> _pass(bool force) async {
    final epoch = _abortEpoch;
    while (!_disposed && !_paused && _abortEpoch == epoch) {
      final head =
          await (_db.select(_db.uploadQueue)
                ..where((t) => t.dead.equals(false))
                ..orderBy([(t) => OrderingTerm.asc(t.id)])
                ..limit(1))
              .getSingleOrNull();
      if (head == null || _abortEpoch != epoch) return;

      final nowUs = _now().toUtc().microsecondsSinceEpoch;
      // An initial `enqueue(..., delay: ...)` guard (`attempts == 0`) protects
      // an in-flight direct RPC (e.g. `_applyExtras`) and must not be bypassed
      // by `flush(force: true)` (F-30). `force: true` only overrides retry
      // backoff (`attempts > 0`).
      final inInitialDelay = head.attempts == 0 && head.nextAttemptAt > nowUs;
      if ((inInitialDelay || !force) && head.nextAttemptAt > nowUs) {
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
        if (_disposed || _abortEpoch != epoch) return;
        final error = e is OurneyException
            ? e
            : OurneyException(OurneyErrorCode.unknown, e.toString());
        if (!isTransient(error.error)) {
          await _markDead(head, error.toString());
          continue;
        }
        if (error.error == OurneyErrorCode.unauthenticated) {
          // Signed out / session expired (F-10): pause the outbox without
          // burning retry attempts or scheduling retry timers while signed out.
          // The queue resumes when the user signs back in.
          await (_db.update(
            _db.uploadQueue,
          )..where((t) => t.id.equals(head.id))).write(
            UploadQueueCompanion(
              lastError: Value(error.toString()),
            ),
          );
          return;
        }
        final attempts = head.attempts + 1;
        // Waiting for connectivity, sign-in or a client/server update
        // never kills an item: dead items get re-pulled
        // over and can lose unsynced photos.
        final waiting =
            error.error == OurneyErrorCode.offline ||
            error.error == OurneyErrorCode.unauthenticated ||
            error.error == OurneyErrorCode.clientOutdated ||
            error.error == OurneyErrorCode.serverOutdated;
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
      if (_disposed || _abortEpoch != epoch) return;
      await (_db.delete(
        _db.uploadQueue,
      )..where((t) => t.id.equals(head.id))).go();
      if (!_processed.isClosed) _processed.add(kind);
    }
  }

  Future<void> _markDead(OutboxRow row, String reason) async {
    debugPrint('outbox: giving up on ${row.kind} ${row.entityKey}: $reason');
    await (_db.update(
      _db.uploadQueue,
    )..where((t) => t.id.equals(row.id))).write(
      UploadQueueCompanion(dead: const Value(true), lastError: Value(reason)),
    );
    if (!_paused) onDead?.call(row);
  }

  void _schedule(Duration delay) {
    _retry?.cancel();
    if (_disposed || _paused) return;
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
