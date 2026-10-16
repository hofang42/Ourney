import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/sync/outbox.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

void main() {
  group('outboxBackoff', () {
    test('doubles from 2 s and caps at 15 min', () {
      expect(outboxBackoff(0), Duration.zero);
      expect(outboxBackoff(1), const Duration(seconds: 2));
      expect(outboxBackoff(2), const Duration(seconds: 4));
      expect(outboxBackoff(5), const Duration(seconds: 32));
      expect(outboxBackoff(10), const Duration(minutes: 15));
      expect(outboxBackoff(1000), const Duration(minutes: 15));
    });

    test('transient vs permanent codes', () {
      expect(isTransient(OurneyErrorCode.offline), isTrue);
      expect(isTransient(OurneyErrorCode.internal), isTrue);
      expect(isTransient(OurneyErrorCode.unauthenticated), isTrue);
      expect(isTransient(OurneyErrorCode.ended), isFalse);
      expect(isTransient(OurneyErrorCode.forbidden), isFalse);
      expect(isTransient(OurneyErrorCode.invalidCapturedAt), isFalse);
    });
  });

  group('Outbox', () {
    late AppDatabase db;
    late TestClock clock;
    late RecordingTimers timers;
    late List<String> executed;
    late List<OurneyException> failures;

    Outbox build(AppDatabase database) {
      final outbox = Outbox(
        database,
        executor: (kind, payload) async {
          if (failures.isNotEmpty) throw failures.removeAt(0);
          executed.add('${kind.wire}:${payload['n']}');
        },
        now: clock.call,
        timer: timers.call,
      );
      addTearDown(outbox.dispose);
      return outbox;
    }

    setUp(() {
      db = memoryDb();
      clock = TestClock(DateTime.utc(2026, 10, 16));
      timers = RecordingTimers();
      executed = [];
      failures = [];
    });

    test('runs items in FIFO order and removes them', () async {
      final outbox = build(db);
      await outbox.enqueue(OutboxKind.createJourney, 'journey:1', {'n': 1});
      await outbox.enqueue(OutboxKind.upsertCheckIn, 'checkin:1', {'n': 2});
      expect(await outbox.watchPending().first, 2);
      expect(
        await outbox.watchPending(kind: OutboxKind.upsertCheckIn).first,
        1,
      );
      await outbox.flush();
      expect(executed, ['create_journey:1', 'upsert_check_in:2']);
      expect(await outbox.watchPending().first, 0);
    });

    test('transient failure keeps the item, backs off, then retries', () async {
      final outbox = build(db);
      await outbox.enqueue(OutboxKind.upsertCheckIn, 'k', {'n': 1});
      await outbox.enqueue(OutboxKind.upsertCheckIn, 'k2', {'n': 2});
      failures.add(const OurneyException(OurneyErrorCode.offline));
      await outbox.flush();
      expect(executed, isEmpty, reason: 'head blocks the queue');
      expect(timers.delays.last, const Duration(seconds: 2));
      expect(await outbox.pendingKeys(), {'k', 'k2'});

      // Not due yet: a normal flush waits for the backoff.
      await outbox.flush();
      expect(executed, isEmpty);

      failures.add(const OurneyException(OurneyErrorCode.internal));
      clock.advance(const Duration(seconds: 3));
      await outbox.flush();
      expect(
        timers.delays.last,
        const Duration(seconds: 4),
        reason: '2nd attempt',
      );

      // Connectivity regained / app resumed: force ignores the backoff.
      await outbox.flush(force: true);
      expect(executed, ['upsert_check_in:1', 'upsert_check_in:2']);
      expect(await outbox.watchPending().first, 0);
    });

    test('permanent rejection marks the item dead and moves on', () async {
      final outbox = build(db);
      await outbox.enqueue(OutboxKind.upsertCheckIn, 'k', {'n': 1});
      await outbox.enqueue(OutboxKind.react, 'r', {'n': 2});
      failures.add(const OurneyException(OurneyErrorCode.ended));
      await outbox.flush();
      expect(executed, ['react:2']);
      expect(await outbox.watchPending().first, 0);
      final rows = await db.select(db.uploadQueue).get();
      expect(rows.single.dead, isTrue);
      expect(rows.single.lastError, contains('ended'));
    });

    test('gives up after maxAttempts non-offline failures', () async {
      final outbox = Outbox(
        db,
        executor: (_, _) async =>
            throw const OurneyException(OurneyErrorCode.internal),
        now: clock.call,
        timer: timers.call,
        maxAttempts: 3,
      );
      addTearDown(outbox.dispose);
      await outbox.enqueue(OutboxKind.react, 'r', {});
      for (var i = 0; i < 3; i++) {
        await outbox.flush(force: true);
      }
      expect(await outbox.watchPending().first, 0);
    });

    test('cancel drops pending items for an entity', () async {
      final outbox = build(db);
      await outbox.enqueue(OutboxKind.upsertCheckIn, 'k', {'n': 1});
      await outbox.enqueue(OutboxKind.deleteMedia, 'k', {'n': 2});
      await outbox.cancel('k', kind: OutboxKind.upsertCheckIn);
      await outbox.flush();
      expect(executed, ['delete_media:2']);
    });

    test('survives a restart (persisted queue, attempts kept)', () async {
      final file = '${tempDir().path}/q.sqlite';
      final db1 = AppDatabase(NativeDatabase(File(file)));
      final first = build(db1);
      await first.enqueue(OutboxKind.upsertCheckIn, 'k', {'n': 7});
      failures.add(const OurneyException(OurneyErrorCode.offline));
      await first.flush();
      first.dispose();
      await db1.close();

      final db2 = AppDatabase(NativeDatabase(File(file)));
      addTearDown(db2.close);
      final second = build(db2);
      expect(await second.watchPending().first, 1);
      final row = await db2.select(db2.uploadQueue).getSingle();
      expect(row.attempts, 1);
      await second.flush(force: true);
      expect(executed, ['upsert_check_in:7']);
    });
  });
}
