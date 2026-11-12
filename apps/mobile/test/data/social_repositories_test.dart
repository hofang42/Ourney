import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/data_layer.dart';
import 'package:ourney/data/db/app_database.dart';
import 'package:ourney/data/media_store.dart';
import 'package:ourney/data/remote/remote_api.dart';
import 'package:ourney/data/social_context.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

const me = 'bbbbbbbb-0000-4000-8000-000000000001';
const bob = 'cccccccc-0000-4000-8000-000000000002';

RemoteRow person(String id, String name) => {
  'user_id': id,
  'username': name,
  'display_name': name,
  'avatar_path': null,
};

RemoteRow friendRow(String id, String created, {String status = 'accepted'}) =>
    {
      'person': person(id, 'u$id'),
      'status': status,
      'direction': 'incoming',
      'source': 'direct',
      'source_journey_id': null,
      'source_journey_title': null,
      'created_at': created,
      'accepted_at': null,
    };

RemoteRow messageRow(String id, String created, {String kind = 'text'}) => {
  'id': id,
  'conversation_id': 'conv',
  'sender_id': bob,
  'kind': kind,
  'body': 'hi',
  'media_path': null,
  'reply_to_checkin_id': null,
  'reply_to_thumb_path': null,
  'created_at': created,
};

/// Lets queued microtasks / async fetches run.
Future<void> pump() => Future<void>.delayed(Duration.zero);

void main() {
  late AppDatabase db;
  late Directory media;
  late TestClock clock;
  late FakeRemoteApi remote;
  late FakePeriodicTimers polls;
  late DataLayer layer;

  setUp(() {
    db = memoryDb();
    media = tempDir();
    clock = TestClock(DateTime.utc(2026, 10, 22, 2));
    remote = FakeRemoteApi(userId: me);
    polls = FakePeriodicTimers();
    layer = supabaseLayer(
      db: db,
      media: media,
      clock: clock,
      remote: remote,
      socialTimers: polls,
    );
  });

  int rpcCount(String fn) =>
      remote.callsOf('rpc').where((c) => c.target == fn).length;

  Map<String, dynamic> lastArgs(String fn) =>
      remote.callsOf('rpc').lastWhere((c) => c.target == fn).args!
          as Map<String, dynamic>;

  group('wiring', () {
    test('local-only layer has no social repositories', () {
      final local = localLayer(db: memoryDb(), media: tempDir(), clock: clock);
      expect(local.friends, isNull);
      expect(local.sharing, isNull);
      expect(local.shareConsents, isNull);
      expect(local.chat, isNull);
      expect(local.insights, isNull);
    });

    test('supabase layer builds all five', () {
      expect(layer.friends, isNotNull);
      expect(layer.sharing, isNotNull);
      expect(layer.shareConsents, isNotNull);
      expect(layer.chat, isNotNull);
      expect(layer.insights, isNotNull);
    });
  });

  group('refreshingStream', () {
    test('fetch on listen, poll, triggers; cancel stops everything', () async {
      final trigger = StreamController<void>.broadcast();
      var n = 0;
      final values = <int>[];
      final sub = refreshingStream<int>(
        fetch: () async => ++n,
        triggers: () => [trigger.stream],
        interval: const Duration(seconds: 20),
        periodic: polls.call,
      ).listen(values.add);
      await pump();
      expect(values, [1]);
      expect(polls.active.single.interval, const Duration(seconds: 20));

      polls.tick();
      await pump();
      trigger.add(null);
      await pump();
      expect(values, [1, 2, 3]);

      await sub.cancel();
      expect(polls.active, isEmpty, reason: 'timer cancelled');
      expect(trigger.hasListener, isFalse, reason: 'trigger released');
      polls.tick();
      trigger.add(null);
      await pump();
      expect(values, [1, 2, 3]);
      await trigger.close();
    });

    test('concurrent refreshes coalesce into one follow-up', () async {
      final trigger = StreamController<void>.broadcast();
      final gate = Completer<void>();
      var n = 0;
      final values = <int>[];
      final sub = refreshingStream<int>(
        fetch: () async {
          n++;
          if (n == 1) await gate.future;
          return n;
        },
        triggers: () => [trigger.stream],
      ).listen(values.add);
      await pump();
      trigger
        ..add(null)
        ..add(null)
        ..add(null);
      await pump();
      gate.complete();
      await pump();
      await pump();
      expect(values, [1, 2]);
      await sub.cancel();
      await trigger.close();
    });

    test('offline after a first value is dropped, other errors pass', () async {
      final trigger = StreamController<void>.broadcast();
      final results = <Object>[
        1,
        const OurneyException(OurneyErrorCode.offline),
        const OurneyException(OurneyErrorCode.forbidden),
        2,
      ];
      final values = <int>[];
      final errors = <Object>[];
      final sub = refreshingStream<int>(
        fetch: () async {
          final r = results.removeAt(0);
          if (r is int) return r;
          throw r;
        },
        triggers: () => [trigger.stream],
      ).listen(values.add, onError: errors.add);
      for (var i = 0; i < 4; i++) {
        if (i > 0) trigger.add(null);
        await pump();
      }
      expect(values, [1, 2]);
      expect(errors.map((e) => (e as OurneyException).error), [
        OurneyErrorCode.forbidden,
      ]);
      await sub.cancel();
      await trigger.close();
    });

    test('an error before any value is forwarded (offline too)', () async {
      final errors = <Object>[];
      final sub = refreshingStream<int>(
        fetch: () async => throw const OurneyException(OurneyErrorCode.offline),
      ).listen((_) {}, onError: errors.add);
      await pump();
      expect(errors.single, isA<OurneyException>());
      await sub.cancel();
    });
  });

  group('friends', () {
    test('watchFriendships parses, sorts newest first, refreshes', () async {
      var rows = [
        friendRow(bob, '2026-10-01T00:00:00Z'),
        friendRow('dd', '2026-10-05T00:00:00Z', status: 'pending'),
      ];
      remote.rpcHandlers['my_friends'] = (_) => rows;
      final seen = <List<Friendship>>[];
      final sub = layer.friends!.watchFriendships().listen(seen.add);
      await pump();
      expect(seen.single.map((f) => f.person.userId), ['dd', bob]);

      rows = [friendRow(bob, '2026-10-01T00:00:00Z')];
      await layer.friends!.respond('dd', accept: false);
      await pump();
      expect(lastArgs('respond_friend_request'), {
        'p_user': 'dd',
        'p_accept': false,
      });
      expect(seen.last.single.person.userId, bob, reason: 'mutation refresh');

      polls.tick();
      await pump();
      expect(rpcCount('my_friends'), 3, reason: 'poll refresh');
      await sub.cancel();
      expect(polls.active, isEmpty);
    });

    test('find, request, remove, invites', () async {
      remote.rpcHandlers['find_user_by_username'] = (p) =>
          p['p_username'] == 'bob' ? person(bob, 'bob') : null;
      expect((await layer.friends!.findByUsername(' @bob '))?.userId, bob);
      expect(await layer.friends!.findByUsername('nobody'), isNull);
      expect(await layer.friends!.findByUsername('  '), isNull);

      await layer.friends!.sendRequest(bob, fromJourneyId: 'j1');
      expect(lastArgs('send_friend_request'), {
        'p_user': bob,
        'p_source_journey': 'j1',
      });
      await layer.friends!.remove(bob);
      expect(lastArgs('remove_friend'), {'p_user': bob});

      remote.rpcHandlers['create_friend_invite'] = (_) => 'tok123456789';
      expect(await layer.friends!.createInvite(), 'tok123456789');
      remote.rpcHandlers['accept_friend_invite'] = (_) => person(bob, 'bob');
      expect((await layer.friends!.acceptInvite('tok')).username, 'bob');
    });

    test('server errors surface as OurneyException codes', () async {
      remote.failOnce.add(const OurneyException(OurneyErrorCode.rateLimited));
      await expectLater(
        layer.friends!.findByUsername('bob'),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.rateLimited,
          ),
        ),
      );
    });

    test('a malformed payload becomes unknown', () async {
      remote.rpcHandlers['my_friends'] = (_) => 'nope';
      await expectLater(
        layer.friends!.watchFriendships().first,
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.unknown,
          ),
        ),
      );
    });
  });

  group('sharing', () {
    test('share / unshare / story / settings / hidden args', () async {
      final s = layer.sharing!;
      await s.shareWithFriends('j1', [bob, bob]);
      expect(lastArgs('share_journey'), {
        'p_journey': 'j1',
        'p_viewers': [bob],
      });
      await s.shareWithFriends('j1', const []);
      expect(rpcCount('share_journey'), 1, reason: 'empty list is a no-op');

      await s.unshare('j1', friendId: bob);
      expect(lastArgs('unshare_journey'), {
        'p_journey': 'j1',
        'p_viewer': bob,
        'p_all': false,
      });
      await s.updateStory(
        'j1',
        const JourneyStory(title: ' T ', coverCheckInId: 'c1'),
      );
      expect(lastArgs('update_journey_story'), {
        'p_journey': 'j1',
        'p_title': 'T',
        'p_intro': '',
        'p_lessons': '',
        'p_cover': 'c1',
      });
      await s.updatePublicSettings(
        'j1',
        const PublicSettings(
          showCounts: true,
          allowPublicReactions: false,
          allowViewerRequests: true,
        ),
      );
      expect(lastArgs('update_public_settings'), {
        'p_journey': 'j1',
        'p_show_counts': true,
        'p_allow_reactions': false,
        'p_allow_requests': true,
      });
      await s.setHiddenInShare('c1', hidden: true);
      expect(lastArgs('set_hidden_in_share'), {
        'p_checkin': 'c1',
        'p_hidden': true,
      });
    });

    test('consent_required is surfaced', () async {
      remote.failOnce.add(
        const OurneyException(OurneyErrorCode.consentRequired),
      );
      await expectLater(
        layer.sharing!.shareWithFriends('j1', [bob]),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.code,
            'code',
            'consent_required',
          ),
        ),
      );
    });

    test('setPublicLink updates the cached journey', () async {
      remote.rpcHandlers['create_journey'] = (p) =>
          journeyRow(p['p_id'] as String, ownerId: me);
      final j = await layer.journeys.create(soloDraft());
      remote.rpcHandlers['set_public_link'] = (p) =>
          p['enabled'] == true ? 'a' * 40 : null;
      expect(
        await layer.sharing!.setPublicLink(j.id, enabled: true, reset: true),
        'a' * 40,
      );
      expect(lastArgs('set_public_link'), {
        'journey': j.id,
        'enabled': true,
        'reset': true,
      });
      var cached = await layer.journeys.watch(j.id).first;
      expect(cached!.publicToken, 'a' * 40);
      expect(cached.visibility, JourneyVisibility.link);

      await layer.sharing!.unshare(j.id, all: true);
      cached = await layer.journeys.watch(j.id).first;
      expect(cached!.publicToken, isNull);
      expect(cached.visibility, JourneyVisibility.private);
    });

    test('shared with me sorts, openShared refreshes it', () async {
      var unseen = true;
      RemoteRow summary(String id, String at) => {
        'journey_id': id,
        'title': id,
        'emoji': '🔥',
        'template_id': 'custom',
        'kind': 'solo',
        'origin': 'live',
        'status': 'active',
        'owner': person(bob, 'bob'),
        'shared_by': person(bob, 'bob'),
        'shared_at': at,
        'photo_count': 1,
        'saved': false,
        'unseen': unseen,
        'first_date': null,
        'last_date': null,
        'cover_thumb_path': null,
      };
      remote.rpcHandlers['shared_with_me'] = (_) => [
        summary('old', '2026-10-01T00:00:00Z'),
        summary('new', '2026-10-10T00:00:00Z'),
      ];
      final seen = <List<SharedJourneySummary>>[];
      final sub = layer.sharing!.watchSharedWithMe().listen(seen.add);
      await pump();
      expect(seen.single.map((s) => s.journeyId), ['new', 'old']);
      expect(seen.single.first.unseen, isTrue);

      unseen = false;
      remote.rpcHandlers['shared_journey'] = (_) => {
        'journey_id': 'new',
        'role': 'friend',
        'title': 'new',
        'emoji': '🔥',
        'template_id': 'custom',
        'kind': 'solo',
        'origin': 'live',
        'status': 'active',
        'owner': person(bob, 'bob'),
        'members': [person(bob, 'bob')],
        'story': null,
        'photos': <Object>[],
        'shared_by': person(bob, 'bob'),
        'can_react': true,
        'can_reply': true,
        'can_follow': false,
        'can_add_owner': false,
        'saved': false,
      };
      final view = await layer.sharing!.openShared('new');
      expect(view.role, ViewerRole.friend);
      await pump();
      expect(seen.last.first.unseen, isFalse);
      await sub.cancel();
    });

    test('forbidden from openShared ("private now")', () async {
      remote.failOnce.add(const OurneyException(OurneyErrorCode.forbidden));
      await expectLater(
        layer.sharing!.openShared('j1'),
        throwsA(
          isA<OurneyException>().having(
            (e) => e.error,
            'error',
            OurneyErrorCode.forbidden,
          ),
        ),
      );
    });

    test(
      'like inserts a reaction, duplicate is ignored; unlike deletes',
      () async {
        await layer.sharing!.like('c1');
        final insert = remote.callsOf('insert').single;
        expect(insert.target, 'reactions');
        expect(insert.args, {'checkin_id': 'c1', 'user_id': me, 'emoji': '❤️'});

        remote.failOnce.add(
          const OurneyException(
            OurneyErrorCode.invalid,
            '23505: duplicate key value violates unique constraint',
          ),
        );
        await layer.sharing!.like('c1');

        remote.failOnce.add(const OurneyException(OurneyErrorCode.forbidden));
        await expectLater(
          layer.sharing!.like('c1'),
          throwsA(isA<OurneyException>()),
        );

        await layer.sharing!.unlike('c1');
        final del = remote.callsOf('delete').single;
        expect(del.target, 'reactions');
        expect(del.args, {'checkin_id': 'c1', 'user_id': me});
      },
    );

    test('follow frame, markFollowed, unsave, openPublic', () async {
      remote.rpcHandlers['follow_frame'] = (_) => {
        'source_journey_id': 'j1',
        'template_id': 'travel',
        'kind': 'solo',
        'title': 'Trip',
        'emoji': '✈️',
        'owner_name': 'Bob',
        'duration_days': 5,
        'metric_name': null,
        'metric_unit': null,
      };
      final f = await layer.sharing!.followFrame('j1');
      expect(f.ownerName, 'Bob');
      await layer.sharing!.markFollowed('j2', 'j1');
      expect(lastArgs('mark_followed'), {'p_journey': 'j2', 'p_source': 'j1'});
      await layer.sharing!.unsave('j1');
      expect(lastArgs('unsave_journey'), {'p_journey': 'j1'});

      remote.failOnce.add(const OurneyException(OurneyErrorCode.notFound));
      await expectLater(
        layer.sharing!.openPublic('tok'),
        throwsA(isA<OurneyException>()),
      );
      expect(lastArgs('public_journey_by_token'), {'p_token': 'tok'});
    });

    test('createImported caches the journey on the shelf', () async {
      const draft = ImportedJourneyDraft(
        id: 'eeeeeeee-0000-4000-8000-000000000009',
        title: 'Hà Giang',
        emoji: '⛰️',
        templateId: TemplateId.travel,
        firstDate: LocalDate(2025, 4, 1),
        lastDate: LocalDate(2025, 4, 5),
        timezone: vnZone,
      );
      remote.rpcHandlers['create_imported_journey'] = (p) => {
        ...journeyRow(p['p_id'] as String, ownerId: me, status: 'ended'),
        'template_id': p['p_template'],
        'title': p['p_title'],
        'start_date': p['p_first'],
        'duration_days': 5,
        'origin': 'imported',
      };
      final j = await layer.sharing!.createImported(draft);
      expect(j.id, draft.id);
      expect(j.origin, JourneyOrigin.imported);
      expect(j.status, JourneyStatus.ended);
      expect(j.startDate, const LocalDate(2025, 4, 1));
      expect(lastArgs('create_imported_journey')['p_last'], '2025-04-05');

      final active = await layer.journeys.watchActive().first;
      expect(active.map((x) => x.id), contains(draft.id));
      final membership = await layer.journeys.watchMyMembership(draft.id).first;
      expect(membership?.role, MemberRole.owner);

      // Retry: no second RPC.
      await layer.sharing!.createImported(draft);
      expect(rpcCount('create_imported_journey'), 1);
    });

    test('createImported rejects bad drafts and needs the server', () async {
      await expectLater(
        layer.sharing!.createImported(
          const ImportedJourneyDraft(
            id: 'x',
            title: 'T',
            emoji: '⛰️',
            templateId: TemplateId.travel,
            firstDate: LocalDate(2025, 4, 5),
            lastDate: LocalDate(2025, 4, 1),
            timezone: vnZone,
          ),
        ),
        throwsA(isA<OurneyException>()),
      );
      remote.failOnce.add(const OurneyException(OurneyErrorCode.offline));
      await expectLater(
        layer.sharing!.createImported(
          const ImportedJourneyDraft(
            id: 'y',
            title: 'T',
            emoji: '⛰️',
            templateId: TemplateId.travel,
            firstDate: LocalDate(2025, 4, 1),
            lastDate: LocalDate(2025, 4, 1),
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
    });
  });

  group('consents', () {
    test('watch + mutations', () async {
      RemoteRow row(String status) => {
        'journey_id': 'j1',
        'journey_title': 'Squad',
        'member': person(me, 'me'),
        'status': status,
        'requested_by': person(bob, 'bob'),
        'decided_at': null,
      };
      var status = 'pending';
      remote.rpcHandlers['my_pending_consents'] = (_) =>
          status == 'pending' ? [row(status)] : <Object>[];
      remote.rpcHandlers['share_consents'] = (_) => [row(status)];
      final pending = <List<ShareConsent>>[];
      final sub = layer.shareConsents!.watchMyPending().listen(pending.add);
      await pump();
      expect(pending.single.single.status, ShareConsentStatus.pending);

      status = 'accepted';
      await layer.shareConsents!.respond('j1', accept: true);
      await pump();
      expect(lastArgs('respond_share_consent'), {
        'p_journey': 'j1',
        'p_accept': true,
      });
      expect(pending.last, isEmpty);

      final forJourney = await layer.shareConsents!.watchForJourney('j1').first;
      expect(forJourney.single.status, ShareConsentStatus.accepted);
      expect(lastArgs('share_consents'), {'p_journey': 'j1'});

      await layer.shareConsents!.request('j1');
      await layer.shareConsents!.withdraw('j1');
      expect(rpcCount('request_share_consent'), 1);
      expect(lastArgs('withdraw_share_consent'), {'p_journey': 'j1'});
      await sub.cancel();
    });
  });

  group('chat', () {
    test('watchMessages: realtime insert triggers a refetch', () async {
      var rows = [messageRow('m1', '2026-10-22T01:00:00Z')];
      remote.rpcHandlers['conversation_messages'] = (_) => rows;
      final seen = <List<ChatMessage>>[];
      final sub = layer.chat!.watchMessages('conv').listen(seen.add);
      await pump();
      expect(seen.single.single.id, 'm1');
      expect(remote.realtime.keys, contains('messages:conversation_id=conv'));

      rows = [
        messageRow('m2', '2026-10-22T02:00:00Z'),
        messageRow('m1', '2026-10-22T01:00:00Z'),
        messageRow('m3', '2026-10-22T03:00:00Z', kind: 'clip'),
      ];
      remote.emitInsert('messages:conversation_id=conv', {'id': 'm2'});
      await pump();
      expect(seen.last.map((m) => m.id), ['m1', 'm2']);

      await sub.cancel();
      expect(remote.openChannels, 0, reason: 'realtime unsubscribed');
      expect(polls.active, isEmpty);
    });

    test('watchConversations refreshes on any new message', () async {
      var unread = 0;
      remote.rpcHandlers['my_conversations'] = (_) => [
        {
          'id': 'conv',
          'journey_id': 'j1',
          'journey_title': 'Run',
          'other': person(bob, 'bob'),
          'unread_count': unread,
          'read_only': false,
          'last_message_at': null,
          'last_message_preview': null,
          'last_message_kind': null,
        },
      ];
      final seen = <List<Conversation>>[];
      final sub = layer.chat!.watchConversations().listen(seen.add);
      await pump();
      expect(seen.single.single.unreadCount, 0);
      unread = 1;
      remote.emitInsert('messages', {'id': 'mX'});
      await pump();
      expect(seen.last.single.unreadCount, 1);
      await sub.cancel();
    });

    test('a realtime failure does not break the stream', () async {
      remote.rpcHandlers['my_conversations'] = (_) => <Object>[];
      final errors = <Object>[];
      final seen = <Object>[];
      final sub = layer.chat!.watchConversations().listen(
        seen.add,
        onError: errors.add,
      );
      await pump();
      remote.realtime['messages']!.addError(
        const OurneyException(OurneyErrorCode.offline),
      );
      polls.tick();
      await pump();
      expect(errors, isEmpty);
      expect(seen, hasLength(2));
      await sub.cancel();
    });

    test('sendText: client id, trimmed body, validation', () async {
      remote.rpcHandlers['send_message'] = (p) => {
        ...messageRow(p['p_id'] as String, '2026-10-22T02:00:00Z'),
        'sender_id': me,
        'body': p['p_body'],
      };
      final m = await layer.chat!.sendText(
        'conv',
        '  hello ',
        replyToCheckInId: 'c1',
      );
      expect(m.body, 'hello');
      expect(m.senderId, me);
      final args = lastArgs('send_message');
      expect(args['p_kind'], 'text');
      expect(args['p_body'], 'hello');
      expect(args['p_media_path'], isNull);
      expect(args['p_reply_to'], 'c1');
      expect(args['p_id'], m.id);

      await expectLater(
        layer.chat!.sendText('conv', '   '),
        throwsA(isA<OurneyException>()),
      );
      await expectLater(
        layer.chat!.sendText('conv', 'x' * 501),
        throwsA(isA<OurneyException>()),
      );
      expect(rpcCount('send_message'), 1);
    });

    test('sendPhoto uploads to the messages bucket path then sends', () async {
      remote.rpcHandlers['send_message'] = (_) => null;
      final m = await layer.chat!.sendPhoto('conv', [9, 8, 7], body: ' look ');
      final path = 'messages/conv/$me/${m.id}.jpg';
      expect(remote.uploaded[path], [9, 8, 7]);
      expect(storageBucketFor(path), messagesBucket);
      final args = lastArgs('send_message');
      expect(args['p_kind'], 'photo');
      expect(args['p_media_path'], path);
      expect(args['p_body'], 'look');
      expect(m.kind, MessageKind.photo);
      expect(m.mediaPath, path);
      // The sender's own copy is cached: no download needed.
      final local = await layer.media.localFileFor(path);
      expect(File(local).readAsBytesSync(), [9, 8, 7]);
      expect(remote.callsOf('download'), isEmpty);
      // Upload goes first: the RPC is not called when it fails.
      remote.failOnce.add(const OurneyException(OurneyErrorCode.forbidden));
      await expectLater(
        layer.chat!.sendPhoto('conv', [1]),
        throwsA(isA<OurneyException>()),
      );
      expect(rpcCount('send_message'), 1);
    });

    test('open / read / clear / hide', () async {
      remote.rpcHandlers['open_conversation'] = (_) => 'conv';
      expect(await layer.chat!.openForReply('j1', checkInId: 'c1'), 'conv');
      expect(lastArgs('open_conversation'), {
        'p_journey': 'j1',
        'p_checkin': 'c1',
      });
      await layer.chat!.markRead('conv');
      await layer.chat!.clear('conv');
      await layer.chat!.hideMessage('m1');
      expect(lastArgs('mark_conversation_read'), {'p_conversation': 'conv'});
      expect(lastArgs('clear_conversation'), {'p_conversation': 'conv'});
      expect(lastArgs('hide_message'), {'p_message': 'm1'});
    });
  });

  group('insights', () {
    test('inbox counts: poll, realtime and markRead refresh', () async {
      var unread = 2;
      remote.rpcHandlers['inbox_counts'] = (_) => {
        'friend_requests': 0,
        'public_requests': 0,
        'new_shares': 0,
        'unread_messages': unread,
        'consent_requests': 0,
      };
      final seen = <InboxCounts>[];
      final sub = layer.insights!.watchInboxCounts().listen(seen.add);
      await pump();
      expect(seen.single.unreadMessages, 2);
      expect(seen.single.hasDot, isTrue);

      unread = 3;
      remote.emitInsert('messages', {'id': 'm'});
      await pump();
      expect(seen.last.unreadMessages, 3);

      unread = 0;
      await layer.chat!.markRead('conv');
      await pump();
      expect(seen.last.hasDot, isFalse);

      polls.tick();
      await pump();
      expect(rpcCount('inbox_counts'), 4);
      await sub.cancel();
      expect(polls.active, isEmpty);
    });

    test('journey insights and reach', () async {
      remote.rpcHandlers['journey_insights'] = (_) => {
        'journey_id': 'j1',
        'views': 5,
        'views_by_day': <Object>[],
        'likes_from_friends': 0,
        'likes_from_strangers': 0,
        'started': 0,
        'views_this_week': 5,
        'likes_this_week': 0,
        'started_this_week': 0,
        'likers': <Object>[],
      };
      remote.rpcHandlers['my_reach'] = (_) => 42;
      expect((await layer.insights!.journeyInsights('j1')).views, 5);
      expect(lastArgs('journey_insights'), {'p_journey': 'j1'});
      expect(await layer.insights!.myReach(), 42);
    });
  });

  group('media', () {
    test('viewer downloads shared check-in photos and chat photos', () async {
      remote.storageObjects['checkins/j1/$bob/c1_t.jpg'] = [1, 2];
      remote.storageObjects['messages/conv/$bob/m1.jpg'] = [3, 4];
      final store = layer.media as CachedMediaStore;
      final a = await store.localFileFor('checkins/j1/$bob/c1_t.jpg');
      final b = await store.localFileFor('messages/conv/$bob/m1.jpg');
      expect(File(a).readAsBytesSync(), [1, 2]);
      expect(File(b).readAsBytesSync(), [3, 4]);
      // Cached by path: a second read does not download again.
      await store.localFileFor('messages/conv/$bob/m1.jpg');
      expect(remote.callsOf('download'), hasLength(2));
    });
  });
}
