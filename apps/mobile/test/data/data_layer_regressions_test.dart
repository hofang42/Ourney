import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/data_layer.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/local_store.dart' show journeyKey;
import 'package:ourney/data/remote/remote_api.dart';
import 'package:ourney/data/sync/outbox.dart';
import 'package:ourney/data/sync/sync_engine.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

const me = 'bbbbbbbb-0000-4000-8000-000000000001';
const other = 'cccccccc-0000-4000-8000-000000000002';
const jid = 'dddddddd-0000-4000-8000-000000000001';
const offline = OurneyException(OurneyErrorCode.offline);

/// [FakeRemoteApi] whose next `select` of [gateTable] answers late: the rows
/// are read at call time, delivered after [release].
class GatedRemoteApi extends FakeRemoteApi {
  GatedRemoteApi({super.userId});

  String? gateTable;
  final reached = Completer<void>();
  final release = Completer<void>();

  @override
  Future<List<RemoteRow>> select(
    String table, {
    Map<String, Object> eq = const {},
    Map<String, List<Object>> inList = const {},
    String? updatedSince,
    bool onlyLive = false,
    int? limit,
  }) async {
    final rows = await super.select(
      table,
      eq: eq,
      inList: inList,
      updatedSince: updatedSince,
      onlyLive: onlyLive,
      limit: limit,
    );
    if (table == gateTable) {
      gateTable = null;
      reached.complete();
      await release.future;
    }
    return rows;
  }
}

void main() {
  late AppDatabase db;
  late Directory media;
  late Directory camera;
  late TestClock clock;
  late GatedRemoteApi remote;
  late DataLayer layer;

  setUp(() {
    db = memoryDb();
    media = tempDir();
    camera = tempDir();
    clock = TestClock(DateTime.utc(2026, 10, 16, 2));
    remote = GatedRemoteApi(userId: me);
    remote.rpcHandlers['create_journey'] = (p) => journeyRow(
      p['p_id'] as String,
      ownerId: me,
      kind: p['p_kind'] as String,
      visibility: p['p_visibility'] as String,
    )..['start_date'] = p['p_start_date'];
    layer = supabaseLayer(db: db, media: media, clock: clock, remote: remote);
  });

  Future<CheckIn> checkIn(String journeyId, String name, DateTime at) {
    final shot = fakeCapture(camera, name);
    return layer.checkIns.submit(
      CheckInDraft(
        journeyId: journeyId,
        capturedAt: at,
        photoFile: shot.photo,
        thumbFile: shot.thumb,
      ),
    );
  }

  Future<void> cacheGroup({String? inviteCode}) async {
    remote.tables['journeys'] = [
      journeyRow(
        jid,
        ownerId: me,
        kind: 'group',
        visibility: 'group',
        inviteCode: inviteCode,
      ),
    ];
    remote.tables['memberships'] = [membershipRow(jid, me)];
    await layer.syncNow();
  }

  group('A-B1 watchToday with several photos today', () {
    Map<String, dynamic> todayRow({String? checkinId, String? capturedAt}) => {
      'user_id': me,
      'username': 'me',
      'display_name': 'Me',
      'avatar_path': null,
      'role': 'owner',
      'checked_in': checkinId != null,
      'checkin_id': checkinId,
      'thumb_path': null,
      'captured_at': capturedAt,
      'current_streak': 1,
    };

    test(
      'two pending local photos: the newest is shown, no StateError',
      () async {
        await cacheGroup();
        remote.failure = offline;
        await checkIn(jid, 'a', DateTime.utc(2026, 10, 16, 1));
        final newest = await checkIn(
          jid,
          'b',
          DateTime.utc(2026, 10, 16, 1, 30),
        );
        remote.failure = null;
        remote.rpcHandlers['group_today'] = (_) => [todayRow()];

        final members = await layer.groups.watchToday(jid).first;
        expect(members.single.todayCheckIn?.id, newest.id);
      },
    );

    test('a newer local photo wins over the uploaded one', () async {
      await cacheGroup();
      remote.failure = offline;
      final local = await checkIn(jid, 'b', DateTime.utc(2026, 10, 16, 1, 30));
      remote.failure = null;
      remote.rpcHandlers['group_today'] = (_) => [
        todayRow(
          checkinId: 'eeeeeeee-0000-4000-8000-000000000001',
          capturedAt: '2026-10-16T00:30:00+00:00',
        ),
      ];

      final members = await layer.groups.watchToday(jid).first;
      expect(members.single.todayCheckIn?.id, local.id);
    });
  });

  test('A-B5 a pull in flight during sign-out does not leak into the next '
      'account', () async {
    remote.tables['journeys'] = [journeyRow('journey-of-user-a', ownerId: me)];
    remote.tables['memberships'] = [membershipRow('journey-of-user-a', me)];
    remote.gateTable = 'journeys';
    final pullA = layer.syncNow();
    await remote.reached.future;

    await layer.auth.signOut();
    // User B signs in; their journey is older than A's cursor.
    remote.emitUser(other);
    remote.tables['journeys'] = [
      journeyRow(
        'journey-of-user-b',
        ownerId: other,
        updatedAt: '2026-10-01T01:00:00.000000+00:00',
      ),
    ];
    remote.tables['memberships'] = [
      membershipRow(
        'journey-of-user-b',
        other,
        updatedAt: '2026-10-01T01:00:00.000000+00:00',
      ),
    ];
    final pullB = layer.syncNow();
    remote.release.complete();
    await pullA;
    await pullB;

    final ids = [for (final j in await db.select(db.journeys).get()) j.id];
    expect(ids, ['journey-of-user-b']);
    expect(await db.readCursor(ownerCursorKey), other);
  });

  test('A-B6 a couple journey is created with max_members 2', () async {
    final j = await layer.journeys.create(
      JourneyDraft(
        kind: JourneyKind.group,
        templateId: TemplateId.custom,
        title: 'Hai đứa',
        emoji: '💞',
        startDate: const LocalDate(2026, 10, 16),
        timezone: vnZone,
        coupleSelfName: 'An',
        couplePartnerName: 'Bình',
      ),
    );
    final params = remote.callsOf('rpc').first.args! as Map<String, dynamic>;
    expect(params['p_max_members'], 2);
    expect(j.id, isNotEmpty);
  });

  group('A-B12 create extras when update_journey fails', () {
    JourneyDraft draft({String? id}) => JourneyDraft(
      id: id,
      kind: JourneyKind.solo,
      templateId: TemplateId.custom,
      title: 'Sáng sớm',
      emoji: '🔥',
      startDate: const LocalDate(2026, 10, 16),
      timezone: vnZone,
      reminderTime: '07:30',
      color: 1,
    );

    test('offline: kept locally and queued', () async {
      remote.rpcHandlers['update_journey'] = (_) => throw offline;
      final j = await layer.journeys.create(draft());
      expect(j.reminderTime, '07:30');
      expect(j.color, 1);
      expect(
        await layer.ctx.outbox!.pendingKeys(),
        contains('${journeyKey(j.id)}:extras'),
      );
    });

    test('a rejection (invalid) still surfaces', () async {
      remote.rpcHandlers['update_journey'] = (_) =>
          throw const OurneyException(OurneyErrorCode.invalid);
      await expectLater(
        layer.journeys.create(draft()),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.invalid,
          ),
        ),
      );
    });

    test('a retryable error does not fail create; extras are queued', () async {
      remote.rpcHandlers['update_journey'] = (_) =>
          throw const OurneyException(OurneyErrorCode.unknown, 'boom');
      final j = await layer.journeys.create(draft());
      expect(j.reminderTime, '07:30');
      expect(j.color, 1);
      expect(
        await layer.ctx.outbox!.pendingKeys(),
        contains('${journeyKey(j.id)}:extras'),
      );
    });

    test('a retry with the same client id re-applies lost extras', () async {
      const id = 'retry-journey-id';
      remote.rpcHandlers['update_journey'] = (_) =>
          throw const OurneyException(OurneyErrorCode.invalid);
      await expectLater(
        layer.journeys.create(draft(id: id)),
        throwsA(isA<OurneyException>()),
      );
      // Review 2: the rejected values do not stay in the cache.
      final after = await (db.select(
        db.journeys,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(after.reminderTime, isNull);
      expect(after.color, isNull);
      expect(await layer.ctx.outbox!.pendingKeys(), isEmpty);
      remote.rpcHandlers['update_journey'] = (p) =>
          journeyRow(id, ownerId: me)
            ..addAll({'reminder_time': '07:30', 'color': 1});
      final j = await layer.journeys.create(draft(id: id));
      expect(j.reminderTime, '07:30');
      expect(j.color, 1);
    });

    test('a retry after a rejection raises it again, not success', () async {
      const id = 'retry-rejected-id';
      remote.rpcHandlers['update_journey'] = (_) =>
          throw const OurneyException(OurneyErrorCode.invalid);
      for (var i = 0; i < 2; i++) {
        await expectLater(
          layer.journeys.create(draft(id: id)),
          throwsA(isA<OurneyException>()),
        );
      }
    });

    test(
      'extras are queued before the call (survive a crash mid-call)',
      () async {
        Set<String>? queuedDuringCall;
        Object? cachedColor;
        remote.rpcHandlers['update_journey'] = (p) async {
          // The call is in flight: the outbox already holds the extras and the
          // cache already carries them.
          queuedDuringCall = await layer.ctx.outbox!.pendingKeys();
          final cached = await db.select(db.journeys).getSingle();
          cachedColor = cached.color;
          return journeyRow(cached.id, ownerId: me)
            ..addAll({'reminder_time': '07:30', 'color': 1});
        };
        final j = await layer.journeys.create(draft());
        expect(queuedDuringCall, contains('${journeyKey(j.id)}:extras'));
        expect(cachedColor, 1);
        // Success drops the queued item again.
        expect(await layer.ctx.outbox!.pendingKeys(), isEmpty);
      },
    );

    test(
      'a complete row is not re-sent (HH:MM:SS time, dna key order)',
      () async {
        const id = 'complete-row-id';
        JourneyDraft withDna() => JourneyDraft(
          id: id,
          kind: JourneyKind.solo,
          templateId: TemplateId.custom,
          title: 'Sáng sớm',
          emoji: '🔥',
          startDate: const LocalDate(2026, 10, 16),
          timezone: vnZone,
          reminderTime: '07:30',
          dna: {'b': 1, 'a': 2},
        );
        remote.rpcHandlers['update_journey'] = (p) =>
            journeyRow(id, ownerId: me)..addAll({
              'reminder_time': '07:30:00',
              'dna': {'a': 2, 'b': 1},
            });
        await layer.journeys.create(withDna());
        final before = remote.callsOf('rpc').length;
        await layer.journeys.create(withDna());
        expect(remote.callsOf('rpc').length, before);
      },
    );
  });

  group('review 2 owner claim', () {
    test(
      'offline journeys of a user signing in survive the first pull',
      () async {
        await layer.auth.signOut();
        remote.emitUser(other);
        remote.failure = offline;
        final j = await layer.journeys.create(
          JourneyDraft(
            kind: JourneyKind.solo,
            templateId: TemplateId.custom,
            title: 'Offline',
            emoji: '🔥',
            startDate: const LocalDate(2026, 10, 16),
            timezone: vnZone,
          ),
        );
        remote.failure = null;
        await layer.syncNow();
        final ids = [for (final r in await db.select(db.journeys).get()) r.id];
        expect(ids, contains(j.id));
        // The sync flushed the queued create: it reached the server.
        expect(
          remote.callsOf('rpc').map((c) => c.target),
          contains('create_journey'),
        );
      },
    );

    test('leftover rows of any table are wiped for a new owner', () async {
      await layer.auth.signOut();
      // A stale write after the wipe: a membership only, no owner recorded.
      await db
          .into(db.memberships)
          .insert(
            MembershipsCompanion.insert(
              journeyId: 'ghost',
              userId: me,
              role: 'owner',
              status: 'active',
              joinedAt: DateTime.utc(2026, 10, 1),
            ),
          );
      remote.emitUser(other);
      await layer.syncNow();
      expect(await db.select(db.memberships).get(), isEmpty);
      expect(await db.readCursor(ownerCursorKey), other);
    });
  });

  group('review 3 owner wipe', () {
    test(
      'a write in flight at sign-out cannot leak to the next user',
      () async {
        await layer.syncNow();
        await layer.auth.signOut();
        // Late write of user A after the wipe: a row and a queued create.
        await db.writeCursor('unrelated', 'x');
        await db
            .into(db.memberships)
            .insert(
              MembershipsCompanion.insert(
                journeyId: 'ghost',
                userId: me,
                role: 'owner',
                status: 'active',
                joinedAt: DateTime.utc(2026, 10, 1),
              ),
            );
        await layer.ctx.outbox!.enqueue(
          OutboxKind.createJourney,
          journeyKey('ghost'),
          {'p_id': 'ghost'},
        );
        expect(await db.readCursor(ownerCursorKey), wipedOwner);

        remote.emitUser(other);
        await layer.syncNow();

        expect(await db.select(db.memberships).get(), isEmpty);
        expect(await db.select(db.uploadQueue).get(), isEmpty);
        expect(
          remote.callsOf('rpc').map((c) => c.target),
          isNot(contains('create_journey')),
        );
        expect(await db.readCursor(ownerCursorKey), other);
      },
    );

    test(
      'concurrent ensureOwner calls do not wipe a write in between',
      () async {
        final sync = layer.ctx.sync!;
        await sync.ensureOwner(me);
        final first = sync.ensureOwner(other);
        final second = sync.ensureOwner(other);
        await first;
        await db
            .into(db.memberships)
            .insert(
              MembershipsCompanion.insert(
                journeyId: 'mine',
                userId: other,
                role: 'owner',
                status: 'active',
                joinedAt: DateTime.utc(2026, 10, 1),
              ),
            );
        await second;
        expect(await db.select(db.memberships).get(), hasLength(1));
        expect(await db.readCursor(ownerCursorKey), other);
      },
    );
  });

  group('imported (retold) journeys accept check-ins like the server', () {
    Future<void> cacheImported({String owner = me}) async {
      remote.tables['journeys'] = [
        journeyRow(jid, ownerId: owner, status: 'ended')
          ..['origin'] = 'imported',
      ];
      remote.tables['memberships'] = [membershipRow(jid, me)];
      await layer.syncNow();
    }

    test('the owner adds photos inside the dates', () async {
      await cacheImported();
      final c = await checkIn(jid, 'a', DateTime.utc(2026, 10, 12, 5));
      expect(c.localDate, const LocalDate(2026, 10, 12));
    });

    test('a photo outside the dates is invalid_captured_at', () async {
      await cacheImported();
      await expectLater(
        checkIn(jid, 'a', DateTime.utc(2026, 10, 5, 5)),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.invalidCapturedAt,
          ),
        ),
      );
    });

    test('a journey that is still going has no upper date cap', () async {
      remote.tables['journeys'] = [
        journeyRow(jid, ownerId: me)
          ..['origin'] = 'imported'
          ..['duration_days'] = null,
      ];
      remote.tables['memberships'] = [membershipRow(jid, me)];
      await layer.syncNow();
      final c = await checkIn(jid, 'a', DateTime.utc(2026, 10, 15, 5));
      expect(c.localDate, const LocalDate(2026, 10, 15));
      // The same date is past the end of a finished 3-day retelling.
      remote.tables['journeys'] = [
        journeyRow(jid, ownerId: me, status: 'ended')
          ..['origin'] = 'imported'
          ..['duration_days'] = 3,
      ];
      await layer.syncNow();
      await expectLater(
        checkIn(jid, 'b', DateTime.utc(2026, 10, 15, 6)),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.invalidCapturedAt,
          ),
        ),
      );
    });

    test('an ended open-ended retold journey refuses check-ins', () async {
      remote.tables['journeys'] = [
        journeyRow(jid, ownerId: me, status: 'ended')
          ..['origin'] = 'imported'
          ..['duration_days'] = null,
      ];
      remote.tables['memberships'] = [membershipRow(jid, me)];
      await layer.syncNow();
      await expectLater(
        checkIn(jid, 'a', DateTime.utc(2026, 10, 12, 5)),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.ended,
          ),
        ),
      );
    });

    test('an ended live journey still refuses check-ins', () async {
      remote.tables['journeys'] = [
        journeyRow(jid, ownerId: me, status: 'ended'),
      ];
      remote.tables['memberships'] = [membershipRow(jid, me)];
      await layer.syncNow();
      await expectLater(
        checkIn(jid, 'a', DateTime.utc(2026, 10, 12, 5)),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.ended,
          ),
        ),
      );
    });
  });

  group('final review: offline edits and end with pending uploads', () {
    Future<void> cacheActive() async {
      remote.tables['journeys'] = [journeyRow(jid, ownerId: me)];
      remote.tables['memberships'] = [membershipRow(jid, me)];
      await layer.syncNow();
    }

    test('two offline edits in a row succeed locally', () async {
      await cacheActive();
      remote.failure = offline;
      final a = await layer.journeys.update(
        jid,
        const JourneyUpdate(title: 'Một'),
      );
      expect(a.title, 'Một');
      final b = await layer.journeys.update(
        jid,
        const JourneyUpdate(title: 'Hai'),
      );
      expect(b.title, 'Hai');
      expect(
        await layer.ctx.outbox!.pendingKeys(),
        contains('${journeyKey(jid)}:edit'),
      );
    });

    test('an edit after an offline photo succeeds locally', () async {
      await cacheActive();
      remote.failure = offline;
      await checkIn(jid, 'a', DateTime.utc(2026, 10, 16, 1));
      final j = await layer.journeys.update(
        jid,
        const JourneyUpdate(title: 'Sau ảnh'),
      );
      expect(j.title, 'Sau ảnh');
    });

    test('online edit with the create still queued stays local', () async {
      remote.rpcHandlers['create_journey'] = (_) => throw offline;
      final j = await layer.journeys.create(soloDraft());
      // Back online, but the queue head is in backoff (unforced flush).
      remote.rpcHandlers.remove('create_journey');
      final before = remote.callsOf('rpc').length;
      final edited = await layer.journeys.update(
        j.id,
        const JourneyUpdate(title: 'Sau tạo'),
      );
      expect(edited.title, 'Sau tạo');
      // Whatever replays does so in queue order: create first, never the
      // edit jumping ahead of it (it would be notFound on the server).
      final sent = [
        for (final c in remote.callsOf('rpc').skip(before)) c.target,
      ];
      expect(sent.first, 'create_journey');
      expect(
        await layer.ctx.outbox!.pendingKeys(),
        contains('${journeyKey(j.id)}:edit'),
      );
    });

    test('a group owner can edit while uploads are queued', () async {
      await cacheGroup();
      remote.failure = offline;
      await checkIn(jid, 'a', DateTime.utc(2026, 10, 16, 1));
      remote.failure = null;
      remote.rpcHandlers['update_journey'] = (p) =>
          journeyRow(jid, ownerId: me, kind: 'group', visibility: 'group')
            ..['title'] = p['p_title'];
      final j = await layer.journeys.update(
        jid,
        const JourneyUpdate(title: 'Đổi tên'),
      );
      expect(j.title, 'Đổi tên');
      expect(
        remote.callsOf('rpc').any((c) => c.target == 'update_journey'),
        isTrue,
      );
    });

    test('end is refused with syncPending while an upload is queued', () async {
      await cacheActive();
      remote.failure = offline;
      await checkIn(jid, 'a', DateTime.utc(2026, 10, 16, 1));
      await expectLater(
        layer.journeys.end(jid),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.syncPending,
          ),
        ),
      );
      expect(
        remote.callsOf('rpc').where((c) => c.target == 'end_journey'),
        isEmpty,
      );
    });
  });

  test('check-ins of the same day are newest first', () async {
    remote.tables['journeys'] = [journeyRow(jid, ownerId: me)];
    remote.tables['memberships'] = [membershipRow(jid, me)];
    await layer.syncNow();
    remote.failure = offline;
    // Inserted oldest first, so insertion order is the opposite of the expected.
    final earlier = await checkIn(jid, 'b', DateTime.utc(2026, 10, 16, 0, 10));
    final middle = await checkIn(jid, 'c', DateTime.utc(2026, 10, 16, 0, 40));
    final later = await checkIn(jid, 'a', DateTime.utc(2026, 10, 16, 1, 10));
    final list = await layer.checkIns.watchForJourney(jid).first;
    expect([for (final c in list) c.id], [later.id, middle.id, earlier.id]);
  });

  test('removeMember refreshes the rotated invite code', () async {
    await cacheGroup(inviteCode: 'OLDCODE1');
    remote.tables['journeys'] = [
      journeyRow(
        jid,
        ownerId: me,
        kind: 'group',
        visibility: 'group',
        inviteCode: 'NEWCODE2',
      ),
    ];
    await layer.groups.removeMember(jid, other);
    final row = await (db.select(
      db.journeys,
    )..where((t) => t.id.equals(jid))).getSingle();
    expect(row.inviteCode, 'NEWCODE2');
  });

  test('block refreshes the social streams', () async {
    var changes = 0;
    final sub = layer.social!.changes.listen((_) => changes++);
    addTearDown(sub.cancel);
    await layer.safety.block(other);
    await pumpEventQueue();
    expect(changes, greaterThan(0));
  });
}
