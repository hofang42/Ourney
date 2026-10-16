import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/data_layer.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/remote/remote_api.dart';
import 'package:ourney/data/sync/sync_engine.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

const me = 'bbbbbbbb-0000-4000-8000-000000000001';
const other = 'cccccccc-0000-4000-8000-000000000002';
const offline = OurneyException(OurneyErrorCode.offline);

void main() {
  late AppDatabase db;
  late Directory media;
  late Directory camera;
  late TestClock clock;
  late FakeRemoteApi remote;
  late RecordingTimers timers;
  late DataLayer layer;

  setUp(() {
    db = memoryDb();
    media = tempDir();
    camera = tempDir();
    clock = TestClock(DateTime.utc(2026, 10, 16, 2));
    remote = FakeRemoteApi(userId: me);
    timers = RecordingTimers();
    remote.rpcHandlers['create_journey'] = (p) => journeyRow(
      p['p_id'] as String,
      ownerId: me,
      kind: p['p_kind'] as String,
      visibility: p['p_visibility'] as String,
    )..['start_date'] = p['p_start_date'];
    layer = supabaseLayer(
      db: db,
      media: media,
      clock: clock,
      remote: remote,
      timers: timers,
    );
  });

  Future<CheckIn> checkIn(
    String journeyId,
    String name, {
    DateTime? at,
    double? metric,
  }) {
    final shot = fakeCapture(camera, name);
    return layer.checkIns.submit(
      CheckInDraft(
        journeyId: journeyId,
        capturedAt: at ?? clock.value,
        photoFile: shot.photo,
        thumbFile: shot.thumb,
        metricValue: metric,
      ),
    );
  }

  List<RemoteCall> upsertsOf(String table) => [
    for (final c in remote.callsOf('upsert'))
      if (c.target == table) c,
  ];

  Future<void> settle() => layer.ctx.outbox!.flush(force: true);

  test('auth reflects the Supabase session', () {
    expect(layer.auth.isLocalOnly, isFalse);
    expect(layer.auth.currentUserId, me);
  });

  test(
    'create journey online calls create_journey and caches the row',
    () async {
      final j = await layer.journeys.create(soloDraft());
      final call = remote.callsOf('rpc').single;
      expect(call.target, 'create_journey');
      final params = call.args! as Map<String, dynamic>;
      expect(params['p_id'], j.id);
      expect(params['p_template_id'], 'weight_loss');
      expect(j.title, 'Server journey', reason: 'server row wins');
      expect(await layer.journeys.watchActive().first, hasLength(1));
      expect(await layer.journeys.watchMyMembership(j.id).first, isNotNull);
    },
  );

  test('server limit becomes JourneyLimitException', () async {
    remote.failOnce.add(const OurneyException(OurneyErrorCode.limit, 'limit'));
    await expectLater(
      layer.journeys.create(soloDraft()),
      throwsA(isA<JourneyLimitException>()),
    );
  });

  test(
    'solo journey created offline is replayed before its check-ins',
    () async {
      remote.failure = offline;
      final j = await layer.journeys.create(soloDraft());
      final c = await checkIn(j.id, 'a');
      expect(await layer.checkIns.watchPendingUploads().first, 1);
      expect(timers.delays, isNotEmpty, reason: 'retry scheduled');

      remote.failure = null;
      remote.calls.clear();
      await settle();
      expect(remote.calls.map((c) => '${c.method}:${c.target}'), [
        'rpc:create_journey',
        'upload:${c.photoPath}',
        'upload:${c.thumbPath}',
        'upsert:check_ins',
        'upsert:check_in_metrics',
      ]);
      expect(await layer.checkIns.watchPendingUploads().first, 0);
    },
  );

  test('group journeys need the server (offline throws)', () async {
    remote.failure = offline;
    await expectLater(
      layer.journeys.create(
        JourneyDraft(
          kind: JourneyKind.group,
          templateId: TemplateId.custom,
          title: 'G',
          emoji: '💪',
          startDate: const LocalDate(2026, 10, 16),
          timezone: vnZone,
        ),
      ),
      throwsA(
        isA<OurneyException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.offline,
        ),
      ),
    );
    expect(await layer.journeys.watchActive().first, isEmpty);
  });

  test(
    'check-in: media then upsert on (journey_id,user_id,local_date)',
    () async {
      final j = await layer.journeys.create(soloDraft());
      final c = await checkIn(j.id, 'a', metric: 70.5);
      expect(c.uploaded, isFalse);
      expect(c.localPhotoFile, isNotNull, reason: 'visible at once');
      await settle();

      expect(remote.uploaded.keys, [
        checkInPhotoPath(j.id, me, c.id),
        checkInThumbPath(j.id, me, c.id),
      ]);
      final upsert =
          upsertsOf('check_ins').single.args! as Map<String, dynamic>;
      expect(upsert['onConflict'], 'journey_id,user_id,local_date');
      final row = upsert['row'] as Map<String, dynamic>;
      expect(row['id'], c.id);
      expect(row['user_id'], me);
      expect(row['local_date'], '2026-10-16');
      expect(row.containsKey('metric_value'), isFalse, reason: '0005 (H1)');
      final metric =
          upsertsOf('check_in_metrics').single.args! as Map<String, dynamic>;
      expect(metric['onConflict'], 'checkin_id');
      expect(metric['row'], {
        'checkin_id': c.id,
        'journey_id': j.id,
        'user_id': me,
        'metric_value': 70.5,
      });
      final saved = (await layer.checkIns.watchForJourney(j.id).first).single;
      expect(saved.uploaded, isTrue);
      expect(saved.localPhotoFile, isNull);
      // Own media stays on disk: no download needed to display it.
      expect(
        File(await layer.media.localFileFor(saved.photoPath)).existsSync(),
        isTrue,
      );
      expect(remote.callsOf('download'), isEmpty);
    },
  );

  test(
    'retake replaces the pending take, or the uploaded one + its media',
    () async {
      final j = await layer.journeys.create(soloDraft());
      remote.failure = offline;
      final a = await checkIn(j.id, 'a');
      final b = await checkIn(j.id, 'b');
      expect(await layer.checkIns.watchPendingUploads().first, 1);
      remote.failure = null;
      await settle();
      expect(remote.uploaded.keys, isNot(contains(a.photoPath)));
      expect(upsertsOf('check_ins'), hasLength(1));

      final c = await checkIn(j.id, 'c');
      await settle();
      expect(upsertsOf('check_ins'), hasLength(2));
      expect(remote.removed, containsAll([b.photoPath, b.thumbPath]));
      final list = await layer.checkIns.watchForJourney(j.id).first;
      expect(list.single.id, c.id);
    },
  );

  test(
    'server rejection (ended) drops the upload instead of retrying',
    () async {
      final j = await layer.journeys.create(soloDraft());
      remote.failOnce.addAll([const OurneyException(OurneyErrorCode.ended)]);
      await checkIn(j.id, 'a');
      await settle();
      expect(await layer.checkIns.watchPendingUploads().first, 0);
    },
  );

  test('pull sync applies rows by updated_at cursor', () async {
    const jid = 'dddddddd-0000-4000-8000-000000000001';
    const cid = 'eeeeeeee-0000-4000-8000-000000000001';
    remote.tables['journeys'] = [
      journeyRow(
        jid,
        ownerId: other,
        kind: 'group',
        visibility: 'group',
        inviteCode: 'ABCD1234',
      ),
    ];
    remote.tables['memberships'] = [
      membershipRow(jid, other),
      membershipRow(jid, me, role: 'member'),
    ];
    final checkInRow = {
      'id': cid,
      'journey_id': jid,
      'user_id': other,
      'local_date': '2026-10-16',
      'captured_at': '2026-10-16T01:00:00+00:00',
      'photo_path': checkInPhotoPath(jid, other, cid),
      'thumb_path': checkInThumbPath(jid, other, cid),
      'from_library': false,
      'caption': 'hi',
      'metric_value': null,
      'updated_at': '2026-10-16T01:30:00.123456+00:00',
      'deleted_at': null,
    };
    remote.tables['check_ins'] = [checkInRow];
    remote.tables['reactions'] = [
      {
        'checkin_id': cid,
        'user_id': me,
        'emoji': '🔥',
        'created_at': '2026-10-16T01:40:00+00:00',
        'updated_at': '2026-10-16T01:40:00+00:00',
        'deleted_at': null,
      },
    ];

    expect(await layer.syncNow(), isA<SyncOk>());
    final journeys = await layer.journeys.watchActive().first;
    expect(journeys.single.kind, JourneyKind.group);
    final checkIns = await layer.checkIns.watchForJourney(jid).first;
    expect(checkIns.single.caption, 'hi');
    expect(checkIns.single.uploaded, isTrue);
    expect(await layer.groups.watchReactions(cid).first, hasLength(1));
    expect(
      await db.readCursor('check_ins'),
      '2026-10-16T01:30:00.123456+00:00',
    );
    expect(await db.readCursor(ownerCursorKey), me);

    // Next pull asks only for rows changed since the cursor (minus overlap).
    remote.calls.clear();
    checkInRow['deleted_at'] = '2026-10-16T03:00:00+00:00';
    checkInRow['updated_at'] = '2026-10-16T03:00:00+00:00';
    await layer.syncNow();
    final since =
        remote
                .callsOf('select')
                .firstWhere((c) => c.target == 'check_ins')
                .args!
            as Map<String, Object?>;
    expect(since['since'], '2026-10-16T01:29:00.123456Z');
    expect(
      await layer.checkIns.watchForJourney(jid).first,
      isEmpty,
      reason: 'tombstone',
    );

    // Other members' media is fetched once (signed URL) and cached by path.
    remote.storageObjects[checkInThumbPath(jid, other, cid)] = [7, 7];
    final path1 = await layer.media.localFileFor(
      checkInThumbPath(jid, other, cid),
    );
    final path2 = await layer.media.localFileFor(
      checkInThumbPath(jid, other, cid),
    );
    expect(path1, path2);
    expect(File(path1).readAsBytesSync(), [7, 7]);
    expect(remote.callsOf('download'), hasLength(1));
  });

  group('0005 security hardening', () {
    const jid = 'dddddddd-0000-4000-8000-000000000001';
    const cid = 'eeeeeeee-0000-4000-8000-000000000001';

    RemoteRow otherCheckIn({String updatedAt = '2026-10-16T01:30:00+00:00'}) =>
        {
          'id': cid,
          'journey_id': jid,
          'user_id': other,
          'local_date': '2026-10-16',
          'captured_at': '2026-10-16T01:00:00+00:00',
          'photo_path': checkInPhotoPath(jid, other, cid),
          'thumb_path': checkInThumbPath(jid, other, cid),
          'from_library': false,
          'caption': 'hi',
          'metric_value': null,
          'updated_at': updatedAt,
          'deleted_at': null,
        };

    RemoteRow metricRow(double? v, {String at = '2026-10-16T01:31:00+00:00'}) =>
        {
          'checkin_id': cid,
          'journey_id': jid,
          'user_id': other,
          'metric_value': v,
          'created_at': at,
          'updated_at': at,
        };

    void seedGroup({bool otherHides = false}) {
      remote.tables['journeys'] = [
        journeyRow(jid, ownerId: other, kind: 'group', visibility: 'group'),
      ];
      remote.tables['memberships'] = [
        membershipRow(jid, other)..['hide_metric'] = otherHides,
        membershipRow(jid, me, role: 'member'),
      ];
    }

    Future<CheckIn?> cached() async {
      final list = await layer.checkIns.watchForJourney(jid).first;
      return list.isEmpty ? null : list.single;
    }

    test('metrics are pulled from check_in_metrics', () async {
      seedGroup();
      remote.tables['check_ins'] = [otherCheckIn()];
      remote.tables['check_in_metrics'] = [metricRow(81.2)];
      expect(await layer.syncNow(), isA<SyncOk>());
      expect((await cached())!.metricValue, 81.2);
      expect(await db.readCursor('check_in_metrics'), isNotNull);

      // A later check-ins pull (metric_value always null) keeps the value.
      remote.tables['check_ins'] = [
        otherCheckIn(updatedAt: '2026-10-16T02:00:00+00:00'),
      ];
      await layer.syncNow();
      expect((await cached())!.metricValue, 81.2);
    });

    test('a metric whose check-in is not cached yet fetches it', () async {
      seedGroup();
      await layer.syncNow(); // check_ins cursor exists, row not seen
      remote.tables['check_ins'] = [
        otherCheckIn(updatedAt: '2026-10-15T00:00:00+00:00'),
      ];
      remote.tables['check_in_metrics'] = [metricRow(64)];
      await db.writeCursor('check_ins', '2026-10-16T05:00:00+00:00');
      await layer.syncNow();
      expect((await cached())!.metricValue, 64);
    });

    test('hide_metric on a co-member drops cached values', () async {
      seedGroup();
      remote.tables['check_ins'] = [otherCheckIn()];
      remote.tables['check_in_metrics'] = [metricRow(81.2)];
      await layer.syncNow();
      remote.tables['memberships'] = [
        membershipRow(jid, other, updatedAt: '2026-10-16T03:00:00+00:00')
          ..['hide_metric'] = true,
        membershipRow(jid, me, role: 'member'),
      ];
      remote.tables['check_in_metrics'] = []; // RLS hides it now
      await layer.syncNow();
      expect((await cached())!.metricValue, isNull);
    });

    test('checkin_tombstones removes deleted check-ins of others', () async {
      seedGroup();
      remote.tables['check_ins'] = [otherCheckIn()];
      remote.storageObjects[checkInThumbPath(jid, other, cid)] = [1];
      await layer.syncNow();
      await layer.media.localFileFor(checkInThumbPath(jid, other, cid));
      expect(await cached(), isNotNull);

      final sinceArgs = <Object?>[];
      remote.rpcHandlers['checkin_tombstones'] = (p) {
        sinceArgs.add(p['since']);
        return p['since'] == null
            ? null
            : [
                {
                  'id': cid,
                  'journey_id': jid,
                  'updated_at': '2026-10-16T04:00:00+00:00',
                },
              ];
      };
      await layer.syncNow(); // first call: since null, nothing yet
      await db.writeCursor(tombstoneCursorKey, '2026-10-16T03:00:00+00:00');
      await layer.syncNow();
      expect(await cached(), isNull);
      expect(
        File(layer.ctx.files.fileFor(checkInThumbPath(jid, other, cid)).path)
            .existsSync(),
        isFalse,
        reason: 'cached media evicted',
      );
      expect(sinceArgs.last, '2026-10-16T02:59:00.000Z');
      expect(
        await db.readCursor(tombstoneCursorKey),
        '2026-10-16T04:00:00+00:00',
      );
      final args = remote.callsOf('rpc').last.args! as Map;
      expect(args['lim'], pullPageSize);
    });

    test('pullJourney refreshes metrics of the journey', () async {
      seedGroup();
      remote.tables['check_ins'] = [otherCheckIn()];
      remote.tables['check_in_metrics'] = [metricRow(70)];
      await layer.ctx.sync!.pullJourney(jid);
      expect((await cached())!.metricValue, 70);
    });

    test('joinByCode: empty row from the server is not_found', () async {
      remote.rpcHandlers['join_by_code'] = (_) => {'id': null, 'kind': null};
      await expectLater(
        layer.groups.joinByCode('ZZZZ9999'),
        throwsA(
          isA<GroupException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.notFound,
          ),
        ),
      );
      remote.failOnce.add(
        OurneyException(
          OurneyErrorCode.fromServer(
            message: 'rate_limited',
            sqlstate: 'P0001',
          ),
        ),
      );
      await expectLater(
        layer.groups.joinByCode('ZZZZ9999'),
        throwsA(
          isA<GroupException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.rateLimited,
          ),
        ),
      );
    });

    test('signOut is global and wipes local data', () async {
      final j = await layer.journeys.create(soloDraft());
      await checkIn(j.id, 'a');
      await layer.auth.signOut();
      expect(remote.callsOf('signOut').single.target, 'global');
      expect(await db.select(db.journeys).get(), isEmpty);
      expect(await db.select(db.checkIns).get(), isEmpty);
      expect(await db.select(db.uploadQueue).get(), isEmpty);
      expect(media.existsSync(), isFalse);
      expect(remote.userId, isNull);
    });
  });

  test('a different user signing in wipes the previous cache', () async {
    await layer.journeys.create(soloDraft());
    await layer.syncNow();
    remote.userId = other;
    await layer.syncNow();
    expect(await db.select(db.journeys).get(), isEmpty);
    expect(await db.readCursor(ownerCursorKey), other);
  });

  test('offline pull reports SyncOffline', () async {
    remote.failure = offline;
    expect(await layer.syncNow(), isA<SyncOffline>());
  });

  test(
    'reactions: upsert with deleted_at null, unreact soft-deletes',
    () async {
      const jid = 'dddddddd-0000-4000-8000-000000000001';
      remote.tables['journeys'] = [
        journeyRow(jid, ownerId: other, kind: 'group', visibility: 'group'),
      ];
      remote.tables['memberships'] = [membershipRow(jid, me, role: 'member')];
      await layer.syncNow();
      await expectLater(
        layer.groups.react('c1', '👍'),
        throwsA(
          isA<GroupException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.invalid,
          ),
        ),
      );
      await layer.groups.react('c1', '🔥');
      expect(await layer.groups.watchReactions('c1').first, hasLength(1));
      await settle();
      final up = remote.callsOf('upsert').single.args! as Map<String, dynamic>;
      expect(up['onConflict'], 'checkin_id,user_id');
      expect(up['row'], {
        'checkin_id': 'c1',
        'user_id': me,
        'emoji': '🔥',
        'deleted_at': null,
      });

      await layer.groups.unreact('c1');
      expect(await layer.groups.watchReactions('c1').first, isEmpty);
      await settle();
      final upd = remote.callsOf('update').last.args! as Map<String, dynamic>;
      expect((upd['values'] as Map)['deleted_at'], isNotNull);
      expect(upd['match'], {'checkin_id': 'c1', 'user_id': me});
    },
  );

  test('joinByCode normalises the code and maps server errors', () async {
    const jid = 'dddddddd-0000-4000-8000-000000000001';
    remote.rpcHandlers['join_by_code'] = (p) =>
        journeyRow(jid, ownerId: other, kind: 'group', visibility: 'group');
    remote.tables['journeys'] = [
      journeyRow(jid, ownerId: other, kind: 'group', visibility: 'group'),
    ];
    remote.tables['memberships'] = [membershipRow(jid, me, role: 'member')];
    expect(await layer.groups.joinByCode(' abcd1234 '), jid);
    expect(remote.callsOf('rpc').first.args, {'code': 'ABCD1234'});
    expect(await layer.journeys.watchActive().first, hasLength(1));

    await expectLater(
      layer.groups.joinByCode('short'),
      throwsA(
        isA<GroupException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.notFound,
        ),
      ),
    );
    remote.failOnce.add(
      OurneyException(
        OurneyErrorCode.fromServer(message: 'full', sqlstate: 'P0001'),
      ),
    );
    await expectLater(
      layer.groups.joinByCode('ZZZZ9999'),
      throwsA(isA<GroupException>().having((e) => e.code, 'code', 'full')),
    );
  });

  test('RPC argument names follow 0004_rpc.sql', () async {
    final j = await layer.journeys.create(soloDraft());
    remote.rpcHandlers['set_public_link'] = (_) => 'a' * 40;
    expect(await layer.journeys.setPublicLink(j.id, enabled: true), 'a' * 40);
    expect(
      (await layer.journeys.watch(j.id).first)!.visibility,
      JourneyVisibility.link,
    );
    await layer.safety.report(checkInId: 'c', reason: ReportReason.selfHarm);
    await layer.safety.block(other);
    await layer.groups.leave(j.id);
    final rpcs = {for (final c in remote.callsOf('rpc')) c.target: c.args};
    expect(rpcs['set_public_link'], {'journey': j.id, 'enabled': true});
    expect(rpcs['report_content'], {
      'p_checkin': 'c',
      'p_user': null,
      'p_reason': 'self_harm',
      'p_note': null,
    });
    expect(rpcs['block_user'], {'p_user': other});
    expect(rpcs['leave_journey'], {'journey': j.id});
    expect(await layer.safety.watchBlockedIds().first, {other});
  });

  test('delete journey tombstones via RPC then removes own media', () async {
    final j = await layer.journeys.create(soloDraft());
    final c = await checkIn(j.id, 'a');
    await settle();
    await layer.journeys.delete(j.id);
    await settle();
    expect(
      remote.callsOf('rpc').map((c) => c.target),
      contains('delete_journey'),
    );
    expect(remote.removed, containsAll([c.photoPath, c.thumbPath]));
    expect(await layer.journeys.watch(j.id).first, isNull);
  });

  test('profile: update first, insert when missing', () async {
    remote.updateResult = [];
    await layer.profiles.upsertMe(username: 'linh', displayName: 'Linh');
    expect(remote.callsOf('insert').single.args, {
      'id': me,
      'username': 'linh',
      'display_name': 'Linh',
    });
    remote.updateResult = null;
    await layer.profiles.setAvatar([1]);
    final me0 = await layer.profiles.watchMe().first;
    expect(remote.uploaded.keys.single, me0!.avatarPath);
  });

  test(
    'deleteAccount invokes the Edge Function, wipes and signs out',
    () async {
      await layer.journeys.create(soloDraft());
      await layer.auth.deleteAccount();
      expect(remote.callsOf('invoke').single.target, deleteAccountFunction);
      expect(await db.select(db.journeys).get(), isEmpty);
      expect(remote.userId, isNull);
    },
  );

  test('deleteAccount failure keeps local data (safe to retry)', () async {
    await layer.journeys.create(soloDraft());
    remote.failOnce.add(
      const OurneyException(OurneyErrorCode.storageCleanupFailed),
    );
    await expectLater(
      layer.auth.deleteAccount(),
      throwsA(
        isA<OurneyException>().having(
          (e) => e.code,
          'code',
          'storage_cleanup_failed',
        ),
      ),
    );
    expect(await db.select(db.journeys).get(), hasLength(1));
    expect(remote.userId, me);
  });

  test('watchMe fetches the server profile before its first event', () async {
    remote.tables['profiles'] = [
      {
        'id': me,
        'username': 'linh',
        'display_name': 'Linh',
        'avatar_path': null,
        'updated_at': '2026-10-16T01:00:00+00:00',
        'deleted_at': null,
      },
    ];
    final first = await layer.profiles.watchMe().first;
    expect(first?.username, 'linh');

    remote.tables['profiles'] = [];
    await db.delete(db.profiles).go();
    expect(
      await layer.profiles.watchMe().first,
      isNull,
      reason: 'no profile yet',
    );

    remote.failure = offline;
    await expectLater(
      layer.profiles.watchMe().first,
      throwsA(
        isA<OurneyException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.offline,
        ),
      ),
    );
  });

  test('taken username (23505) surfaces as invalid', () async {
    remote.updateResult = [];
    remote.failOnce.addAll([
      OurneyException(
        OurneyErrorCode.fromServer(
          message: 'duplicate key value violates unique constraint "profiles_username_key"',
          sqlstate: '23505',
        ),
      ),
    ]);
    // First failure hits the update call.
    await expectLater(
      layer.profiles.upsertMe(username: 'taken', displayName: 'X'),
      throwsA(
        isA<OurneyException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.invalid,
        ),
      ),
    );
    expect(await db.select(db.profiles).get(), isEmpty);
  });
}
