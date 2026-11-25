import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/data_layer.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/remote/error_mapping.dart';
import 'package:ourney/data/remote/remote_api.dart';
import 'package:ourney/data/remote/supabase_remote_api.dart';
import 'package:ourney/data/sync/sync_engine.dart';
import 'package:ourney_core/ourney_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  test('a retried create reuses the client id (no duplicate)', () async {
    const clientId = 'cccccccc-0000-4000-8000-000000000001';
    final draft = JourneyDraft(
      kind: JourneyKind.solo,
      templateId: TemplateId.custom,
      title: 'Retry',
      emoji: '🔥',
      startDate: const LocalDate(2026, 10, 16),
      timezone: vnZone,
      id: clientId,
    );
    // The response of the first attempt is lost.
    remote.failOnce.add(const OurneyException(OurneyErrorCode.unknown));
    await expectLater(layer.journeys.create(draft), throwsA(anything));
    final j = await layer.journeys.create(draft);
    expect(j.id, clientId);
    expect(
      [
        for (final c in remote.callsOf('rpc'))
          (c.args! as Map<String, dynamic>)['p_id'],
      ],
      [clientId, clientId],
    );
    // Tapping again after success returns the same journey.
    expect((await layer.journeys.create(draft)).id, clientId);
    expect(await layer.journeys.watchActive().first, hasLength(1));
  });

  test('a fourth active journey is created (no cap, FR-B3)', () async {
    for (var i = 0; i < 4; i++) {
      await layer.journeys.create(soloDraft(title: 'J$i'));
    }
    expect(await layer.journeys.watchActive().first, hasLength(4));
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
        'upsert:check_in_extras',
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

  test('check-in: media then upsert on id', () async {
    final j = await layer.journeys.create(soloDraft());
    final c = await checkIn(j.id, 'a', metric: 70.5);
    expect(c.uploaded, isFalse);
    expect(c.localPhotoFile, isNotNull, reason: 'visible at once');
    await settle();

    expect(remote.uploaded.keys, [
      checkInPhotoPath(j.id, me, c.id),
      checkInThumbPath(j.id, me, c.id),
    ]);
    final upsert = upsertsOf('check_ins').single.args! as Map<String, dynamic>;
    expect(upsert['onConflict'], 'id');
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
  });

  test(
    'several photos the same day are each uploaded, none replaced (bug #2)',
    () async {
      final j = await layer.journeys.create(soloDraft());
      remote.failure = offline;
      final a = await checkIn(j.id, 'a');
      final b = await checkIn(j.id, 'b');
      expect(a.localDate, b.localDate);
      expect(await layer.checkIns.watchPendingUploads().first, 2);
      remote.failure = null;
      await settle();
      expect(remote.uploaded.keys, containsAll([a.photoPath, b.photoPath]));
      expect(upsertsOf('check_ins'), hasLength(2));

      final c = await checkIn(j.id, 'c');
      await settle();
      expect(upsertsOf('check_ins'), hasLength(3));
      expect(remote.removed, isEmpty, reason: 'no photo is replaced');
      final list = await layer.checkIns.watchForJourney(j.id).first;
      expect(list.map((x) => x.id), unorderedEquals([a.id, b.id, c.id]));
      expect(list.every((x) => x.uploaded), isTrue);
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

    test(
      'extras are pulled from check_in_extras and survive a re-pull',
      () async {
        seedGroup();
        remote.tables['check_ins'] = [otherCheckIn()];
        remote.tables['check_in_extras'] = [
          {
            'checkin_id': cid,
            'journey_id': jid,
            'user_id': other,
            'extras': {'mood': 'light', 'km': 5.3},
            'updated_at': '2026-10-16T01:31:00+00:00',
          },
        ];
        expect(await layer.syncNow(), isA<SyncOk>());
        expect(
          (await cached())!.extras,
          const CheckInExtras(mood: 'light', km: 5.3),
        );
        remote.tables['check_ins'] = [
          otherCheckIn(updatedAt: '2026-10-16T02:00:00+00:00'),
        ];
        await layer.syncNow();
        expect((await cached())!.extras.km, 5.3);
      },
    );

    test('hide_extras on a co-member drops cached extras', () async {
      seedGroup();
      remote.tables['check_ins'] = [otherCheckIn()];
      remote.tables['check_in_extras'] = [
        {
          'checkin_id': cid,
          'journey_id': jid,
          'user_id': other,
          'extras': {'mood': 'tired'},
          'updated_at': '2026-10-16T01:31:00+00:00',
        },
      ];
      await layer.syncNow();
      remote.tables['memberships'] = [
        membershipRow(jid, other, updatedAt: '2026-10-16T03:00:00+00:00')
          ..['hide_extras'] = true,
        membershipRow(jid, me, role: 'member'),
      ];
      remote.tables['check_in_extras'] = []; // RLS hides it now
      await layer.syncNow();
      expect((await cached())!.extras.isEmpty, isTrue);
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

  test('RPC argument names follow the server signatures', () async {
    final j = await layer.journeys.create(soloDraft());
    const slug = 'journey-abcdefghijklmnop';
    remote.rpcHandlers['set_readable_public_link'] = (_) => slug;
    expect(await layer.journeys.setPublicLink(j.id, enabled: true), slug);
    expect(
      (await layer.journeys.watch(j.id).first)!.visibility,
      JourneyVisibility.link,
    );
    await layer.safety.report(checkInId: 'c', reason: ReportReason.selfHarm);
    await layer.safety.block(other);
    await layer.groups.leave(j.id);
    final rpcs = {for (final c in remote.callsOf('rpc')) c.target: c.args};
    expect(rpcs['set_readable_public_link'], {
      'journey': j.id,
      'enabled': true,
    });
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
    remote.rpcHandlers['check_username_available'] =
        (p) => p['p_username'] != 'taken_user';
    expect(await layer.profiles.isUsernameAvailable('  LINH  '), isTrue);
    expect(await layer.profiles.isUsernameAvailable('TAKEN_USER'), isFalse);
    expect(await layer.profiles.isUsernameAvailable('ab'), isFalse);

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

  test('username availability requires a boolean RPC response', () async {
    for (final payload in [
      null,
      'true',
      {'available': true},
    ]) {
      remote.rpcHandlers['check_username_available'] = (_) => payload;
      await expectLater(
        layer.profiles.isUsernameAvailable('linh'),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.unknown,
          ),
        ),
      );
    }
    remote.failOnce.add(offline);
    await expectLater(
      layer.profiles.isUsernameAvailable('linh'),
      throwsA(same(offline)),
    );
  });

  test('username availability skips the RPC without a session', () async {
    remote.userId = null;
    await expectLater(
      layer.profiles.isUsernameAvailable('linh'),
      throwsA(
        isA<OurneyException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.unauthenticated,
        ),
      ),
    );
    expect(remote.callsOf('rpc'), isEmpty);
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
        'terms_version': 1,
        'updated_at': '2026-10-16T01:00:00+00:00',
        'deleted_at': null,
      },
    ];
    expect(layer.auth.acceptedTermsVersion, isNull);
    final first = await layer.profiles.watchMe().first;
    expect(first?.username, 'linh');
    expect(first?.termsVersion, 1);
    expect(
      layer.auth.acceptedTermsVersion,
      1,
      reason: 'H2: own terms_version read from existing profile select',
    );

    // H2 cold start: when a ProfileRow is already cached in Drift, watchMe()
    // emits the cached termsVersion immediately even when remote is fresh
    // (acceptedTermsVersion == null) and offline.
    remote.termsVersion = null;
    remote.failure = offline;
    final cachedColdStart = await layer.profiles.watchMe().first;
    expect(cachedColdStart?.termsVersion, 1);
    remote.failure = null;

    await layer.auth.recordTermsAccepted(1);
    final acceptRpc = remote
        .callsOf('rpc')
        .where((c) => c.target == 'accept_terms')
        .single;
    expect(acceptRpc.args, {'p_version': 1});
    expect(layer.auth.acceptedTermsVersion, 1);

    remote.tables['profiles'] = [];
    await db.delete(db.profiles).go();
    expect(
      await layer.profiles.watchMe().first,
      isNull,
      reason: 'no profile yet',
    );

    // H1: verifyOtp on a brand-new account without a profile row defers full
    // table pull sync until upsertMe creates the profile row.
    remote.calls.clear();
    await layer.auth.verifyOtp('linh@example.com', '123456');
    await Future<void>.delayed(Duration.zero);
    expect(
      remote.callsOf('rpc').where((c) => c.target == 'checkin_tombstones'),
      isEmpty,
      reason: 'H1: no pull sync before profile setup completes',
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

  test('a username unique violation surfaces as a username conflict', () async {
    remote.failOnce.add(
      mapRemoteError(
        const PostgrestException(
          message: 'duplicate key value violates unique constraint "profiles_username_key"',
          code: '23505',
        ),
      ),
    );
    await expectLater(
      layer.profiles.upsertMe(username: 'taken', displayName: 'X'),
      throwsA(
        isA<ProfileUsernameTakenException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.invalid,
        ),
      ),
    );
    expect(await db.select(db.profiles).get(), isEmpty);
  });

  test('other profile constraint violations retain their error', () async {
    for (final failure in [
      const PostgrestException(
        message:
            'duplicate key value violates unique constraint "profiles_pkey"',
        code: '23505',
      ),
      const PostgrestException(
        message:
            'new row violates check constraint "profiles_display_name_check"',
        code: '23514',
      ),
      const PostgrestException(message: 'content_policy', code: '23514'),
    ]) {
      final mapped = mapRemoteError(failure);
      remote.failOnce.add(mapped);
      await expectLater(
        layer.profiles.upsertMe(username: 'valid', displayName: 'X'),
        throwsA(same(mapped)),
      );
    }
  });

  test(
    'hasPassword and updatePassword delegate to remote',
    () async {
      remote.rpcHandlers['auth_has_password'] = (_) => false;
      expect(await layer.auth.hasPassword(), isFalse);
      expect(
        remote.callsOf('rpc').where((c) => c.target == 'auth_has_password'),
        hasLength(1),
      );

      remote.rpcHandlers['auth_has_password'] = (_) => true;
      expect(await layer.auth.hasPassword(), isTrue);

      await layer.auth.updatePassword(
        'newpassword123',
        code: '654321',
        signOutOthers: true,
      );
      final upd = remote.callsOf('updatePassword').single;
      expect(upd.target, 'newpassword123');
      expect(upd.args, {
        'code': '654321',
        'signOutOthers': true,
      });

      await layer.auth.cancelPasswordFlow();
      expect(remote.callsOf('cancelPasswordFlow'), hasLength(1));
    },
  );

  group('SupabaseRemoteApi auth & session logic (F-1..F-3, R-2, R-3)', () {
    late HttpServer server;
    late SupabaseClient client;
    late SupabaseRemoteApi api;
    late DateTime now;
    final requests = <({String method, String path, String query, Map<String, dynamic>? json})>[];
    late FutureOr<({int status, Object? body})> Function(
      String method,
      String path,
      String query,
      Map<String, dynamic>? json,
    ) handler;

    String fakeJwt(String sub) {
      String b64(Map<String, Object?> m) =>
          base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      final exp =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      return '${b64({'alg': 'HS256', 'typ': 'JWT'})}.'
          '${b64({'sub': sub, 'exp': exp, 'role': 'authenticated'})}.sig';
    }

    Map<String, Object?> userJson({
      String id = 'u1',
      String? email = 'user@example.com',
      String? phone,
    }) => {
      'id': id,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': email,
      'phone': ?phone,
      'app_metadata': {'provider': email != null ? 'email' : 'phone'},
      'user_metadata': <String, Object?>{},
      'created_at': '2026-10-16T00:00:00.000000Z',
    };

    Map<String, Object?> sessionJson({
      String id = 'u1',
      String? email = 'user@example.com',
      String? phone,
    }) => {
      'access_token': fakeJwt(id),
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'ref-$id',
      'user': userJson(id: id, email: email, phone: phone),
    };

    setUp(() async {
      final prevOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = prevOverrides);

      requests.clear();
      handler = (method, path, query, body) => (status: 200, body: <String, Object?>{});
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        final raw = await utf8.decoder.bind(req).join();
        Map<String, dynamic>? decoded;
        if (raw.isNotEmpty) {
          final parsed = jsonDecode(raw);
          if (parsed is Map<String, dynamic>) decoded = parsed;
        }
        requests.add((
          method: req.method,
          path: req.uri.path,
          query: req.uri.query,
          json: decoded,
        ));
        final res = await handler(
          req.method,
          req.uri.path,
          req.uri.query,
          decoded,
        );
        req.response.statusCode = res.status;
        req.response.headers.contentType = ContentType.json;
        if (res.body != null) {
          req.response.write(jsonEncode(res.body));
        }
        await req.response.close();
      });
      client = SupabaseClient(
        'http://${server.address.host}:${server.port}',
        'test-anon-key',
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
      );
      now = DateTime.utc(2026, 11, 25, 12);
      api = SupabaseRemoteApi(client, now: () => now);
      addTearDown(() async {
        await client.dispose();
        await server.close(force: true);
      });
    });

    test(
      'hasPassword returns false without HTTP when signed out and queries /rpc/auth_has_password when signed in',
      () async {
        expect(api.currentUserId, isNull);
        expect(await api.hasPassword(), isFalse);
        expect(requests, isEmpty);

        var hasPwResponse = false;
        handler = (method, path, query, body) {
          if (path == '/auth/v1/verify') {
            return (status: 200, body: sessionJson());
          }
          if (path == '/rest/v1/rpc/auth_has_password') {
            return (status: 200, body: hasPwResponse);
          }
          return (status: 200, body: <String, Object?>{});
        };

        await api.verifyOtp('user@example.com', '123456');
        expect(api.currentUserId, 'u1');

        expect(await api.hasPassword(), isFalse);
        hasPwResponse = true;
        expect(await api.hasPassword(), isTrue);
        expect(
          requests.where((r) => r.path == '/rest/v1/rpc/auth_has_password'),
          hasLength(2),
        );
      },
    );

    test(
      'resetPassword holds currentUserId and watchUserId until updateUser succeeds, skips verifyOTP on retry, and treats same_password as idempotent success with SignOutScope.others',
      () async {
        final watchedUserIds = <String?>[];
        final sub = api.watchUserId().listen(watchedUserIds.add);
        addTearDown(sub.cancel);

        final putGate = Completer<void>();
        var putAttempt = 0;
        handler = (method, path, query, body) async {
          if (path == '/auth/v1/recover') {
            return (status: 200, body: <String, Object?>{});
          }
          if (path == '/auth/v1/verify') {
            return (status: 200, body: sessionJson());
          }
          if (path == '/auth/v1/user' && method == 'PUT') {
            putAttempt++;
            if (putAttempt == 1) {
              await putGate.future;
              return (
                status: 422,
                body: {
                  'code': 422,
                  'error_code': 'weak_password',
                  'msg': 'Password is too weak',
                },
              );
            }
            return (
              status: 422,
              body: {
                'code': 422,
                'error_code': 'same_password',
                'msg': 'New password should be different from the old password.',
              },
            );
          }
          if (path == '/auth/v1/logout') {
            // Simulate a 500 on logout?scope=others to verify best-effort swallowing.
            return (status: 500, body: {'msg': 'transient logout error'});
          }
          return (status: 200, body: <String, Object?>{});
        };

        await api.sendPasswordReset('  user@example.com ');
        expect(requests.single.path, '/auth/v1/recover');
        expect(requests.single.json?['email'], 'user@example.com');
        requests.clear();

        // Attempt 1: verifyOTP succeeds, PUT /auth/v1/user is in flight, then fails with weak_password.
        final attempt1 = api.resetPassword(
          ' user@example.com ',
          ' 123456 ',
          'weakpass1',
        );
        while (!requests.any((r) => r.path == '/auth/v1/user')) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        // F-2: While updateUser is in flight, currentUserId is still null and watchUserId has not emitted 'u1'.
        expect(api.currentUserId, isNull);
        expect(watchedUserIds, isNot(contains('u1')));

        putGate.complete();
        await expectLater(
          attempt1,
          throwsA(
            isA<OurneyException>().having(
              (e) => e.error,
              'error',
              OurneyErrorCode.invalid,
            ),
          ),
        );
        // F-2: Even after updateUser failed, currentUserId remains held at null so router stays on /auth for retry.
        expect(api.currentUserId, isNull);
        expect(watchedUserIds, isNot(contains('u1')));
        expect(
          requests.where((r) => r.path == '/auth/v1/verify'),
          hasLength(1),
        );

        // Attempt 2 (retry with same code): skips /auth/v1/verify, receives 422 same_password,
        // treats it as idempotent success, calls /auth/v1/logout?scope=others, and releases 'u1'.
        await api.resetPassword('user@example.com', '123456', 'existingpass123');
        expect(
          requests.where((r) => r.path == '/auth/v1/verify'),
          hasLength(1),
          reason: 'retry with already-verified recovery code must not re-call /auth/v1/verify',
        );
        expect(
          requests.where((r) => r.path == '/auth/v1/user'),
          hasLength(2),
        );
        final logoutReq = requests.singleWhere((r) => r.path == '/auth/v1/logout');
        expect(logoutReq.query, contains('scope=others'));
        await pumpEventQueue();
        expect(api.currentUserId, 'u1');
        expect(watchedUserIds, contains('u1'));
        // R-3: verifyOTP(type: OtpType.recovery) propagated the new JWT to client.realtime.
        expect(
          client.realtime.accessToken,
          equals(client.auth.currentSession?.accessToken),
        );
      },
    );

    test(
      'updatePassword verifies recovery OTP, propagates new JWT to realtime, keeps verified session across same_password without re-verifying, and respects signOutOthers',
      () async {
        var putCall = 0;
        var verifyCount = 0;
        handler = (method, path, query, body) {
          if (path == '/auth/v1/verify') {
            verifyCount++;
            return (status: 200, body: sessionJson(id: 'u1'));
          }
          if (path == '/auth/v1/user' && method == 'PUT') {
            putCall++;
            if (putCall == 1) {
              return (
                status: 422,
                body: {
                  'code': 422,
                  'error_code': 'same_password',
                  'msg': 'New password should be different from the old password.',
                },
              );
            }
            return (status: 200, body: userJson());
          }
          if (path == '/auth/v1/logout') {
            return (status: 204, body: null);
          }
          return (status: 200, body: <String, Object?>{});
        };

        // Sign in first as email user; simulate stale/cleared realtime token before recovery.
        await api.verifyOtp('user@example.com', '111111');
        await client.realtime.setAuth('stale-token');
        requests.clear();
        verifyCount = 0;

        // 1. updatePassword with same_password verifies recovery OTP ('654321'),
        // updates client.realtime.accessToken (R-3), rethrows same_password, and preserves _verifiedRecoveryKey.
        await expectLater(
          api.updatePassword(
            'samepass123',
            code: ' 654321 ',
            signOutOthers: true,
          ),
          throwsA(
            isA<OurneyException>()
                .having((e) => e.error, 'error', OurneyErrorCode.invalid)
                .having((e) => e.detail, 'detail', contains('same_password')),
          ),
        );
        expect(verifyCount, 1);
        expect(
          client.realtime.accessToken,
          equals(client.auth.currentSession?.accessToken),
        );
        expect(
          requests.where((r) => r.path == '/auth/v1/verify'),
          hasLength(1),
        );
        expect(
          requests.first.json,
          containsPair('type', 'recovery'),
        );
        expect(
          requests.first.json,
          containsPair('token', '654321'),
        );
        expect(
          requests.where((r) => r.path == '/auth/v1/logout'),
          isEmpty,
        );

        // 2. Retrying updatePassword with a different password reuses the kept verified
        // session (skips /auth/v1/verify) and revokes other devices (scope=others).
        await api.updatePassword(
          'differentpass123',
          code: '654321',
          signOutOthers: true,
        );
        expect(
          requests.where((r) => r.path == '/auth/v1/verify'),
          hasLength(1),
          reason: 'kept verified session must not call /auth/v1/verify a second time',
        );
        final putRequests = requests.where((r) => r.path == '/auth/v1/user').toList();
        expect(putRequests, hasLength(2));
        expect(
          putRequests.last.json,
          {'password': 'differentpass123'},
        );
        final logoutReq = requests.singleWhere((r) => r.path == '/auth/v1/logout');
        expect(logoutReq.query, contains('scope=others'));

        // 3. First-time set (signOutOthers: false) verifies the new recovery code and
        // updates the password without calling /auth/v1/logout?scope=others.
        requests.clear();
        await api.updatePassword(
          'firsttimepass123',
          code: '999999',
          signOutOthers: false,
        );
        expect(
          requests.where((r) => r.path == '/auth/v1/verify'),
          hasLength(1),
        );
        expect(
          requests.where((r) => r.path == '/auth/v1/user'),
          hasLength(1),
        );
        expect(
          requests.where((r) => r.path == '/auth/v1/logout'),
          isEmpty,
        );
      },
    );

    test(
      'R-2: verified recovery key expires after TTL, clears on sendPasswordReset and cancelPasswordFlow, and cancelPasswordFlow signs out half-completed unauthenticated reset',
      () async {
        var failUpdate = true;
        handler = (method, path, query, body) {
          if (path == '/auth/v1/recover') {
            return (status: 200, body: <String, Object?>{});
          }
          if (path == '/auth/v1/verify') {
            return (status: 200, body: sessionJson());
          }
          if (path == '/auth/v1/user' && method == 'PUT') {
            if (failUpdate) {
              return (
                status: 422,
                body: {
                  'code': 422,
                  'error_code': 'weak_password',
                  'msg': 'Password is too weak',
                },
              );
            }
            return (status: 200, body: userJson());
          }
          if (path == '/auth/v1/logout') {
            return (status: 204, body: null);
          }
          return (status: 200, body: <String, Object?>{});
        };

        // 1. Unauthenticated resetPassword fails on updateUser after verifyOTP succeeded;
        // abandoning via cancelPasswordFlow signs out the half-completed session locally.
        await expectLater(
          api.resetPassword('user@example.com', '123456', 'weakpass'),
          throwsA(isA<OurneyException>()),
        );
        expect(api.currentUserId, isNull);
        expect(client.auth.currentSession, isNotNull);

        await api.cancelPasswordFlow();
        expect(api.currentUserId, isNull);
        expect(
          client.auth.currentSession,
          isNull,
          reason: 'abandoned unauthenticated recovery session must be signed out locally',
        );

        // 2. Signed-in updatePassword caches _verifiedRecoveryKey on failure;
        // cancelPasswordFlow clears the key WITHOUT signing out the signed-in user.
        await api.verifyOtp('user@example.com', '111111');
        requests.clear();

        await expectLater(
          api.updatePassword('weakpass', code: '222222'),
          throwsA(isA<OurneyException>()),
        );
        expect(
          requests.where((r) => r.path == '/auth/v1/verify'),
          hasLength(1),
        );
        await api.cancelPasswordFlow();
        expect(api.currentUserId, 'u1');
        expect(client.auth.currentSession, isNotNull);

        // Next attempt with '222222' must re-call /auth/v1/verify because cancelPasswordFlow cleared the cache.
        await expectLater(
          api.updatePassword('weakpass', code: '222222'),
          throwsA(isA<OurneyException>()),
        );
        expect(
          requests.where((r) => r.path == '/auth/v1/verify'),
          hasLength(2),
        );

        // 3. sendPasswordReset clears _verifiedRecoveryKey.
        await api.sendPasswordReset('user@example.com');
        await expectLater(
          api.updatePassword('weakpass', code: '222222'),
          throwsA(isA<OurneyException>()),
        );
        expect(
          requests.where((r) => r.path == '/auth/v1/verify'),
          hasLength(3),
        );

        // 4. Advancing clock past verifiedRecoveryTtl (5 min) expires _verifiedRecoveryKey.
        now = now.add(const Duration(minutes: 6));
        failUpdate = false;
        await api.updatePassword('validpass123', code: '222222');
        expect(
          requests.where((r) => r.path == '/auth/v1/verify'),
          hasLength(4),
          reason: 'expired _verifiedRecoveryKey must re-verify with /auth/v1/verify',
        );
      },
    );

    test(
      'updatePassword rejects phone-only account (no email) without hitting /auth/v1/verify',
      () async {
        handler = (method, path, query, body) {
          if (path == '/auth/v1/verify') {
            return (
              status: 200,
              body: sessionJson(email: null, phone: '+84912345678'),
            );
          }
          return (status: 200, body: <String, Object?>{});
        };

        await api.verifyPhoneOtp('+84912345678', '123456');
        requests.clear();

        await expectLater(
          api.updatePassword('newpass123', code: '654321'),
          throwsA(
            isA<OurneyException>().having(
              (e) => e.error,
              'error',
              OurneyErrorCode.invalid,
            ),
          ),
        );
        expect(requests, isEmpty);
      },
    );
  });
}
