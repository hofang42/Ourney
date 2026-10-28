import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/mapping.dart';
import 'package:ourney/data/remote/remote_api.dart';
import 'package:ourney/data/social_mapping.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

const alice = 'aaaaaaaa-0000-4000-8000-00000000000a';
const bob = 'bbbbbbbb-0000-4000-8000-00000000000b';

RemoteRow person(String id, [String name = 'alice']) => {
  'user_id': id,
  'username': name,
  'display_name': name.toUpperCase(),
  'avatar_path': 'avatars/$id/x.jpg',
};

RemoteRow viewJson() => {
  'journey_id': 'j1',
  'role': 'friend',
  'title': 'Đà Lạt',
  'emoji': '🌲',
  'template_id': 'travel',
  'kind': 'group',
  'origin': 'imported',
  'status': 'ended',
  'duration_days': 3,
  'start_date': '2026-09-01',
  'owner': person(alice),
  'members': [person(alice), person(bob, 'bob')],
  'story': {
    'title': 'Trip',
    'intro': '',
    'lessons': null,
    'cover_checkin_id': 'c2',
  },
  'photos': [
    {
      'checkin_id': 'c2',
      'author': person(bob, 'bob'),
      'local_date': '2026-09-02',
      'photo_path': 'checkins/j1/$bob/c2.jpg',
      'thumb_path': 'checkins/j1/$bob/c2_t.jpg',
      'caption': null,
      'metric_value': '72.5',
      'like_count': 0,
      'liked_by_me': true,
      'blurred': true,
    },
    {
      'checkin_id': 'c1',
      'author': person(alice),
      'local_date': '2026-09-01',
      'photo_path': 'checkins/j1/$alice/c1.jpg',
      'thumb_path': 'checkins/j1/$alice/c1_t.jpg',
      'caption': 'hi',
      'metric_value': null,
      'like_count': 4,
      'liked_by_me': false,
      'blurred': false,
    },
  ],
  'current_streak': null,
  'like_count': null,
  'follow_count': 2,
  'metric_name': null,
  'metric_unit': null,
  'shared_by': person(bob, 'bob'),
  'can_react': true,
  'can_reply': true,
  'can_follow': true,
  'can_add_owner': false,
  'saved': false,
};

void main() {
  test('person and friendship', () {
    final f = friendshipFromJson({
      'person': person(bob, 'bob'),
      'status': 'pending',
      'direction': 'incoming',
      'source': 'public_journey',
      'source_journey_id': 'j1',
      'source_journey_title': 'Run',
      'created_at': '2026-10-20T08:00:00+07:00',
      'accepted_at': null,
    });
    expect(f.person.userId, bob);
    expect(f.person.displayName, 'BOB');
    expect(f.status, FriendStatus.pending);
    expect(f.direction, FriendDirection.incoming);
    expect(f.source, FriendSource.publicJourney);
    expect(f.isIncomingRequest, isTrue);
    expect(f.createdAt, DateTime.utc(2026, 10, 20, 1));
    expect(f.createdAt.isUtc, isTrue);
    expect(f.sourceJourneyTitle, 'Run');
  });

  test('unknown enum wire values are rejected', () {
    expect(
      () => friendshipFromJson({
        'person': person(bob),
        'status': 'weird',
        'direction': 'incoming',
        'source': 'direct',
        'created_at': '2026-10-20T00:00:00Z',
      }),
      throwsFormatException,
    );
  });

  test('share state', () {
    final s = shareStateFromJson({
      'journey_id': 'j1',
      'viewers': [person(bob, 'bob')],
      'story': {
        'title': '',
        'intro': 'Hello',
        'lessons': null,
        'cover_checkin_id': null,
      },
      'public': {
        'show_counts': false,
        'allow_public_reactions': true,
        'allow_viewer_requests': true,
      },
      'hidden_checkin_ids': ['c1', 'c1', 'c2'],
      'public_token': null,
    });
    expect(s.viewers.single.username, 'bob');
    expect(s.story.title, isNull, reason: 'empty string → null');
    expect(s.story.intro, 'Hello');
    expect(s.publicSettings.allowPublicReactions, isTrue);
    expect(s.publicSettings.showCounts, isFalse);
    expect(s.hiddenCheckInIds, {'c1', 'c2'});
    expect(s.linkOn, isFalse);
  });

  test('shared with me summary', () {
    final s = sharedSummaryFromJson({
      'journey_id': 'j1',
      'title': 'Run',
      'emoji': '🏃',
      'template_id': 'workout_30',
      'kind': 'solo',
      'origin': 'live',
      'status': 'active',
      'owner': person(alice),
      'shared_by': null,
      'shared_at': '2026-10-21T00:00:00Z',
      'photo_count': 12,
      'saved': true,
      'unseen': false,
      'first_date': '2026-10-01',
      'last_date': null,
      'cover_thumb_path': null,
    });
    expect(s.templateId, TemplateId.workout30);
    expect(s.sharedBy.userId, alice, reason: 'saved: shared_by = owner');
    expect(s.photoCount, 12);
    expect(s.saved, isTrue);
    expect(s.firstDate, const LocalDate(2026, 10, 1));
    expect(s.lastDate, isNull);
  });

  test('shared journey view: photos oldest first, numbers parsed', () {
    final v = sharedViewFromJson(viewJson());
    expect(v.role, ViewerRole.friend);
    expect(v.origin, JourneyOrigin.imported);
    expect(v.kind, JourneyKind.group);
    expect(v.startDate, const LocalDate(2026, 9, 1));
    expect(v.members, hasLength(2));
    expect(v.story.coverCheckInId, 'c2');
    expect(v.story.intro, isNull);
    expect(v.photos.map((p) => p.checkInId), ['c1', 'c2']);
    expect(v.photos.last.metricValue, 72.5);
    expect(v.photos.last.blurred, isTrue);
    expect(v.photos.last.likedByMe, isTrue);
    expect(v.photos.first.likeCount, 4);
    expect(v.currentStreak, isNull);
    expect(v.likeCount, isNull);
    expect(v.followCount, 2);
    expect(v.sharedBy?.userId, bob);
    expect(v.canReply, isTrue);
    expect(v.canAddOwner, isFalse);
  });

  test('follow frame and imported params', () {
    final f = frameFromJson({
      'source_journey_id': 'j1',
      'template_id': 'english_daily',
      'kind': 'solo',
      'title': 'English',
      'emoji': '📚',
      'owner_name': 'Alice',
      'duration_days': 30,
      'metric_name': 'Phút',
      'metric_unit': 'min',
    });
    expect(f.templateId, TemplateId.englishDaily);
    expect(f.durationDays, 30);
    expect(f.ownerName, 'Alice');

    final p = importedJourneyParams(
      const ImportedJourneyDraft(
        id: 'j9',
        title: ' Hà Giang ',
        emoji: '⛰️',
        templateId: TemplateId.travel,
        firstDate: LocalDate(2025, 4, 1),
        lastDate: LocalDate(2025, 4, 5),
        timezone: vnZone,
      ),
    );
    expect(p, {
      'p_id': 'j9',
      'p_title': 'Hà Giang',
      'p_emoji': '⛰️',
      'p_template': 'travel',
      'p_first': '2025-04-01',
      'p_last': '2025-04-05',
      'p_timezone': vnZone,
      'p_metric_name': null,
      'p_metric_unit': null,
    });
  });

  test('consent', () {
    final c = consentFromJson({
      'journey_id': 'j1',
      'journey_title': 'Squad',
      'member': person(bob, 'bob'),
      'status': 'withdrawn',
      'requested_by': person(alice),
      'decided_at': '2026-10-22T10:00:00.123456+00:00',
    });
    expect(c.status, ShareConsentStatus.withdrawn);
    expect(c.requestedBy.userId, alice);
    expect(c.decidedAt, DateTime.utc(2026, 10, 22, 10, 0, 0, 123, 456));
  });

  test('conversation and messages', () {
    final c = conversationFromJson({
      'id': 'conv',
      'journey_id': 'j1',
      'journey_title': 'Run',
      'other': person(bob, 'bob'),
      'unread_count': 3,
      'read_only': true,
      'last_message_at': '2026-10-22T10:00:00Z',
      'last_message_preview': 'hey',
      'last_message_kind': 'clip',
    });
    expect(c.unreadCount, 3);
    expect(c.readOnly, isTrue);
    expect(c.lastMessageKind, isNull, reason: 'clip is not a v1 kind');

    final m = messageFromJson({
      'id': 'm1',
      'conversation_id': 'conv',
      'sender_id': bob,
      'kind': 'photo',
      'body': null,
      'media_path': 'messages/conv/$bob/m1.jpg',
      'reply_to_checkin_id': 'c1',
      'reply_to_thumb_path': 'checkins/j1/$alice/c1_t.jpg',
      'created_at': '2026-10-22T10:00:00Z',
    })!;
    expect(m.kind, MessageKind.photo);
    expect(m.mediaPath, 'messages/conv/$bob/m1.jpg');
    expect(m.replyToThumbPath, endsWith('c1_t.jpg'));
    expect(
      messageFromJson({
        'id': 'm2',
        'conversation_id': 'conv',
        'sender_id': bob,
        'kind': 'clip',
        'created_at': '2026-10-22T10:00:00Z',
      }),
      isNull,
    );
    expect(messagePhotoPath('conv', bob, 'm1'), 'messages/conv/$bob/m1.jpg');
    expect(storageBucketFor('messages/conv/$bob/m1.jpg'), messagesBucket);
    expect(storageBucketFor('checkins/j1/$bob/c1.jpg'), mediaBucket);
  });

  test('inbox counts and insights', () {
    final i = inboxCountsFromJson({
      'friend_requests': 0,
      'public_requests': 2,
      'new_shares': 0,
      'unread_messages': 0,
      'consent_requests': 0,
    });
    expect(i.publicRequests, 2);
    expect(i.hasDot, isFalse, reason: 'public requests never light the dot');
    expect(inboxCountsFromJson(null).hasDot, isFalse);

    final s = insightsFromJson({
      'journey_id': 'j1',
      'views': 10,
      'views_by_day': [
        {'day': '2026-10-20', 'count': 4},
        {'day': '2026-10-21', 'count': 6},
      ],
      'likes_from_friends': 1,
      'likes_from_strangers': 2,
      'started': 3,
      'views_this_week': 10,
      'likes_this_week': 3,
      'started_this_week': 1,
      'likers': [person(bob, 'bob')],
    });
    expect(s.viewsByDay.last.day, const LocalDate(2026, 10, 21));
    expect(s.viewsByDay.last.count, 6);
    expect(s.started, 3);
    expect(s.likers.single.userId, bob);
  });

  test('journey origin maps from the remote row (absent → live)', () {
    final row = journeyRow('j1', ownerId: alice);
    expect(journeyFromRemote(row).origin.value, 'live');
    expect(
      journeyFromRemote({...row, 'origin': 'imported'}).origin.value,
      'imported',
    );
  });

  test('rowsOf accepts null and rejects non-lists', () {
    expect(rowsOf(null), isEmpty);
    expect(
      rowsOf([
        {'a': 1},
      ]).single['a'],
      1,
    );
    expect(() => rowsOf('x'), throwsFormatException);
  });
}
