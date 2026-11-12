// Wire JSON (docs/contracts/sharing.md) -> social models of ourney_core.
// Dates go through `LocalDate.parse`, instants through a UTC parse and enums
// through `fromWire` only. Malformed payloads throw [FormatException] /
// [TypeError]; repositories turn those into `OurneyException(unknown)`.
import 'package:ourney_core/ourney_core.dart';

import 'mapping.dart' show parseInstant;
import 'remote/remote_api.dart';

RemoteRow _map(Object? v) => switch (v) {
  final Map<String, dynamic> m => m,
  final Map<dynamic, dynamic> m => m.cast<String, dynamic>(),
  _ => throw FormatException('expected a JSON object', '$v'),
};

/// The rows of a `setof json` RPC (null → empty).
List<RemoteRow> rowsOf(Object? v) => switch (v) {
  null => const [],
  final List<dynamic> l => [for (final e in l) _map(e)],
  _ => throw FormatException('expected a JSON array', '$v'),
};

/// A single JSON object result.
RemoteRow rowOf(Object? v) => _map(v);

DateTime? _instantOrNull(Object? v) => v == null ? null : parseInstant(v);

LocalDate? _dateOrNull(Object? v) =>
    v == null ? null : LocalDate.parse(v as String);

int _int(Object? v, [int fallback = 0]) => switch (v) {
  final num n => n.toInt(),
  final String s => int.tryParse(s) ?? fallback,
  _ => fallback,
};

int? _intOrNull(Object? v) => v == null ? null : _int(v);

double? _doubleOrNull(Object? v) => switch (v) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};

bool _bool(Object? v) => v == true;

/// Empty strings are treated like null (story fields).
String? _text(Object? v) => switch (v) {
  final String s when s.isNotEmpty => s,
  _ => null,
};

// --- people / friends -------------------------------------------------------

PersonSummary personFromJson(Object? json) {
  final r = _map(json);
  return PersonSummary(
    userId: r['user_id'] as String,
    username: r['username'] as String? ?? '',
    displayName: r['display_name'] as String? ?? '',
    avatarPath: r['avatar_path'] as String?,
  );
}

PersonSummary? personOrNull(Object? json) =>
    json == null ? null : personFromJson(json);

List<PersonSummary> peopleFromJson(Object? json) => [
  for (final p in json as List<dynamic>? ?? const []) personFromJson(p),
];

Friendship friendshipFromJson(Object? json) {
  final r = _map(json);
  return Friendship(
    person: personFromJson(r['person']),
    status: FriendStatus.fromWire(r['status'] as String),
    direction: FriendDirection.fromWire(
      r['direction'] as String? ?? FriendDirection.outgoing.wireName,
    ),
    source: FriendSource.fromWire(
      r['source'] as String? ?? FriendSource.direct.wireName,
    ),
    sourceJourneyId: r['source_journey_id'] as String?,
    sourceJourneyTitle: r['source_journey_title'] as String?,
    createdAt: parseInstant(r['created_at']),
    acceptedAt: _instantOrNull(r['accepted_at']),
  );
}

// --- sharing ----------------------------------------------------------------

JourneyStory storyFromJson(Object? json) {
  if (json == null) return const JourneyStory();
  final r = _map(json);
  return JourneyStory(
    title: _text(r['title']),
    intro: _text(r['intro']),
    lessons: _text(r['lessons']),
    coverCheckInId: r['cover_checkin_id'] as String?,
  );
}

PublicSettings publicSettingsFromJson(Object? json) {
  final r = json == null ? const <String, dynamic>{} : _map(json);
  return PublicSettings(
    showCounts: _bool(r['show_counts']),
    allowPublicReactions: _bool(r['allow_public_reactions']),
    allowViewerRequests: _bool(r['allow_viewer_requests']),
  );
}

JourneyShareState shareStateFromJson(Object? json) {
  final r = _map(json);
  return JourneyShareState(
    journeyId: r['journey_id'] as String,
    viewers: peopleFromJson(r['viewers']),
    story: storyFromJson(r['story']),
    publicSettings: publicSettingsFromJson(r['public']),
    hiddenCheckInIds: {
      for (final id in r['hidden_checkin_ids'] as List<dynamic>? ?? const [])
        id as String,
    },
    publicToken: r['public_token'] as String?,
  );
}

SharedJourneySummary sharedSummaryFromJson(Object? json) {
  final r = _map(json);
  final owner = personFromJson(r['owner']);
  return SharedJourneySummary(
    journeyId: r['journey_id'] as String,
    title: r['title'] as String,
    emoji: r['emoji'] as String,
    templateId: TemplateId.fromWire(r['template_id'] as String),
    kind: JourneyKind.fromWire(r['kind'] as String),
    origin: JourneyOrigin.fromWire(r['origin'] as String? ?? 'live'),
    status: JourneyStatus.fromWire(r['status'] as String),
    owner: owner,
    sharedBy: personOrNull(r['shared_by']) ?? owner,
    sharedAt: parseInstant(r['shared_at']),
    photoCount: _int(r['photo_count']),
    saved: _bool(r['saved']),
    unseen: _bool(r['unseen']),
    firstDate: _dateOrNull(r['first_date']),
    lastDate: _dateOrNull(r['last_date']),
    coverThumbPath: r['cover_thumb_path'] as String?,
  );
}

SharedPhoto sharedPhotoFromJson(Object? json) {
  final r = _map(json);
  return SharedPhoto(
    checkInId: r['checkin_id'] as String,
    author: personFromJson(r['author']),
    localDate: LocalDate.parse(r['local_date'] as String),
    photoPath: r['photo_path'] as String,
    thumbPath: r['thumb_path'] as String,
    caption: r['caption'] as String?,
    metricValue: _doubleOrNull(r['metric_value']),
    likeCount: _int(r['like_count']),
    likedByMe: _bool(r['liked_by_me']),
    blurred: _bool(r['blurred']),
  );
}

SharedJourneyView sharedViewFromJson(Object? json) {
  final r = _map(json);
  final photos = [
    for (final p in r['photos'] as List<dynamic>? ?? const [])
      sharedPhotoFromJson(p),
  ];
  // Contract: oldest first. Keep the server order but make it stable.
  final sorted = [for (final (i, p) in photos.indexed) (i, p)]
    ..sort((a, b) {
      final byDate = a.$2.localDate.compareTo(b.$2.localDate);
      return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
    });
  return SharedJourneyView(
    journeyId: r['journey_id'] as String,
    role: ViewerRole.fromWire(r['role'] as String),
    title: r['title'] as String,
    emoji: r['emoji'] as String,
    templateId: TemplateId.fromWire(r['template_id'] as String),
    kind: JourneyKind.fromWire(r['kind'] as String),
    origin: JourneyOrigin.fromWire(r['origin'] as String? ?? 'live'),
    status: JourneyStatus.fromWire(r['status'] as String),
    durationDays: _intOrNull(r['duration_days']),
    startDate: _dateOrNull(r['start_date']),
    owner: personFromJson(r['owner']),
    members: peopleFromJson(r['members']),
    story: storyFromJson(r['story']),
    photos: [for (final e in sorted) e.$2],
    currentStreak: _intOrNull(r['current_streak']),
    likeCount: _intOrNull(r['like_count']),
    followCount: _intOrNull(r['follow_count']),
    metricName: r['metric_name'] as String?,
    metricUnit: r['metric_unit'] as String?,
    sharedBy: personOrNull(r['shared_by']),
    canReact: _bool(r['can_react']),
    canReply: _bool(r['can_reply']),
    canFollow: _bool(r['can_follow']),
    canAddOwner: _bool(r['can_add_owner']),
    saved: _bool(r['saved']),
  );
}

JourneyFrame frameFromJson(Object? json) {
  final r = _map(json);
  return JourneyFrame(
    sourceJourneyId: r['source_journey_id'] as String,
    templateId: TemplateId.fromWire(r['template_id'] as String),
    kind: JourneyKind.fromWire(r['kind'] as String),
    title: r['title'] as String,
    emoji: r['emoji'] as String,
    ownerName: r['owner_name'] as String? ?? '',
    durationDays: _intOrNull(r['duration_days']),
    metricName: r['metric_name'] as String?,
    metricUnit: r['metric_unit'] as String?,
  );
}

/// `create_imported_journey` arguments.
Map<String, dynamic> importedJourneyParams(ImportedJourneyDraft d) => {
  'p_id': d.id,
  'p_title': d.title.trim(),
  'p_emoji': d.emoji,
  'p_template': d.templateId.wireName,
  'p_first': d.firstDate.toString(),
  'p_last': d.lastDate.toString(),
  'p_timezone': d.timezone,
  'p_metric_name': d.metricName,
  'p_metric_unit': d.metricUnit,
};

// --- consents ---------------------------------------------------------------

ShareConsent consentFromJson(Object? json) {
  final r = _map(json);
  return ShareConsent(
    journeyId: r['journey_id'] as String,
    journeyTitle: r['journey_title'] as String? ?? '',
    member: personFromJson(r['member']),
    status: ShareConsentStatus.fromWire(r['status'] as String),
    requestedBy: personFromJson(r['requested_by']),
    decidedAt: _instantOrNull(r['decided_at']),
  );
}

// --- chat -------------------------------------------------------------------

Conversation conversationFromJson(Object? json) {
  final r = _map(json);
  final kind = r['last_message_kind'] as String?;
  return Conversation(
    id: r['id'] as String,
    journeyId: r['journey_id'] as String,
    journeyTitle: r['journey_title'] as String? ?? '',
    other: personFromJson(r['other']),
    unreadCount: _int(r['unread_count']),
    readOnly: _bool(r['read_only']),
    lastMessageAt: _instantOrNull(r['last_message_at']),
    lastMessagePreview: r['last_message_preview'] as String?,
    lastMessageKind: kind == null ? null : _messageKindOrNull(kind),
  );
}

/// `clip` (v0.2) and future kinds are not shown by v1 clients.
MessageKind? _messageKindOrNull(String wire) {
  for (final k in MessageKind.values) {
    if (k.wireName == wire) return k;
  }
  return null;
}

/// Null for kinds a v1 client does not render (`clip`).
ChatMessage? messageFromJson(Object? json) {
  final r = _map(json);
  final kind = _messageKindOrNull(r['kind'] as String);
  if (kind == null) return null;
  return ChatMessage(
    id: r['id'] as String,
    conversationId: r['conversation_id'] as String,
    senderId: r['sender_id'] as String,
    kind: kind,
    createdAt: parseInstant(r['created_at']),
    body: r['body'] as String?,
    mediaPath: r['media_path'] as String?,
    replyToCheckInId: r['reply_to_checkin_id'] as String?,
    replyToThumbPath: r['reply_to_thumb_path'] as String?,
  );
}

/// Storage path of a chat photo (checked by `send_message`).
String messagePhotoPath(String conversationId, String senderId, String id) =>
    '$messagesBucket/$conversationId/$senderId/$id.jpg';

// --- inbox & insights -------------------------------------------------------

InboxCounts inboxCountsFromJson(Object? json) {
  final r = json == null ? const <String, dynamic>{} : _map(json);
  return InboxCounts(
    friendRequests: _int(r['friend_requests']),
    publicRequests: _int(r['public_requests']),
    newShares: _int(r['new_shares']),
    unreadMessages: _int(r['unread_messages']),
    consentRequests: _int(r['consent_requests']),
  );
}

JourneyInsights insightsFromJson(Object? json) {
  final r = _map(json);
  return JourneyInsights(
    journeyId: r['journey_id'] as String,
    views: _int(r['views']),
    viewsByDay: [
      for (final d in r['views_by_day'] as List<dynamic>? ?? const [])
        DailyCount(
          LocalDate.parse(_map(d)['day'] as String),
          _int(_map(d)['count']),
        ),
    ],
    likesFromFriends: _int(r['likes_from_friends']),
    likesFromStrangers: _int(r['likes_from_strangers']),
    started: _int(r['started']),
    viewsThisWeek: _int(r['views_this_week']),
    likesThisWeek: _int(r['likes_this_week']),
    startedThisWeek: _int(r['started_this_week']),
    likers: peopleFromJson(r['likers']),
  );
}
