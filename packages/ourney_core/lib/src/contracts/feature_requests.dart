// In-App Feature Requests & Roadmap Board contract (migration 0024).
//
// App-side RPC mapping (supabase/migrations/0024_feature_requests.sql):
//   FeatureRequestRepository.list                  -> rpc list_feature_requests
//   FeatureRequestRepository.getById               -> rpc get_feature_request
//   FeatureRequestRepository.searchSimilar         -> rpc search_similar_feature_requests
//   FeatureRequestRepository.create                -> rpc create_feature_request
//   FeatureRequestRepository.update                -> rpc update_feature_request
//   FeatureRequestRepository.delete                -> rpc delete_feature_request
//   FeatureRequestRepository.toggleVote            -> rpc toggle_feature_request_vote
//   FeatureRequestRepository.report                -> rpc report_feature_request
//   FeatureRequestRepository.myShippedNotifications-> rpc my_shipped_request_notifications
//   FeatureRequestRepository.markShippedSeen       -> rpc mark_shipped_requests_seen

import '../models.dart';
import 'social.dart' show PersonSummary;

const int featureRequestTitleMin = 6;
const int featureRequestTitleMax = 80;
const int featureRequestBodyMin = 10;
const int featureRequestBodyMax = 1000;
const int featureRequestPageSize = 30;

/// Matches raw URLs rejected by the `0024` trigger (`links_not_allowed`).
final RegExp _disallowedUrlPattern = RegExp(
  r'(?:https?://|www\.[a-z0-9-]+|\b[a-z0-9-]+\.(?:com|net|org|io|vn|xyz|me|app|gg)/)',
  caseSensitive: false,
);

/// True when [text] contains a web URL that public feature requests forbid.
bool hasDisallowedFeatureRequestLink(String text) =>
    _disallowedUrlPattern.hasMatch(text);

enum FeatureRequestTitleError { tooShort, tooLong, linksNotAllowed }

enum FeatureRequestBodyError { tooShort, tooLong, linksNotAllowed }

/// Validates a feature request title (6..80 Unicode code points after trim,
/// no external links).
FeatureRequestTitleError? validateFeatureRequestTitle(String raw) {
  final trimmed = raw.trim();
  final len = trimmed.runes.length;
  if (len < featureRequestTitleMin) return FeatureRequestTitleError.tooShort;
  if (len > featureRequestTitleMax) return FeatureRequestTitleError.tooLong;
  if (hasDisallowedFeatureRequestLink(trimmed)) {
    return FeatureRequestTitleError.linksNotAllowed;
  }
  return null;
}

/// Validates a feature request body (10..1000 Unicode code points after trim,
/// no external links).
FeatureRequestBodyError? validateFeatureRequestBody(String raw) {
  final trimmed = raw.trim();
  final len = trimmed.runes.length;
  if (len < featureRequestBodyMin) return FeatureRequestBodyError.tooShort;
  if (len > featureRequestBodyMax) return FeatureRequestBodyError.tooLong;
  if (hasDisallowedFeatureRequestLink(trimmed)) {
    return FeatureRequestBodyError.linksNotAllowed;
  }
  return null;
}

/// Folds Vietnamese diacritics to ASCII lowercase for client-side search and
/// duplicate matching.
String foldVietnameseDiacritics(String input) {
  const map = <String, String>{
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'đ': 'd',
  };
  final lower = input.toLowerCase();
  final sb = StringBuffer();
  for (var i = 0; i < lower.length; i++) {
    final ch = lower[i];
    sb.write(map[ch] ?? ch);
  }
  return sb.toString();
}

/// `feature_requests.category`.
enum FeatureRequestCategory {
  camera('camera'),
  journeys('journeys'),
  squad('squad'),
  sharing('sharing'),
  design('design'),
  other('other');

  const FeatureRequestCategory(this.wireName);
  final String wireName;

  /// Unknown values degrade to [other] so older clients never crash on new
  /// categories.
  static FeatureRequestCategory fromWire(String? wire) {
    for (final c in values) {
      if (c.wireName == wire) return c;
    }
    return other;
  }
}

/// `feature_requests.status`.
enum FeatureRequestStatus {
  newRequest('new'),
  underReview('under_review'),
  planned('planned'),
  inProgress('in_progress'),
  shipped('shipped'),
  declined('declined');

  const FeatureRequestStatus(this.wireName);
  final String wireName;

  /// Unknown values degrade to [newRequest].
  static FeatureRequestStatus fromWire(String? wire) {
    for (final s in values) {
      if (s.wireName == wire) return s;
    }
    return newRequest;
  }

  /// Whether community votes can be toggled in this status.
  bool get canVote => switch (this) {
        newRequest || underReview || planned || inProgress => true,
        shipped || declined => false,
      };
}

/// The 4 horizon tabs on the Feature Requests board (`/feedback`).
enum FeatureRequestTab {
  popular('popular'),
  newest('new'),
  planned('planned'),
  shipped('shipped');

  const FeatureRequestTab(this.wireName);
  final String wireName;

  static FeatureRequestTab fromWire(String? wire) {
    for (final t in values) {
      if (t.wireName == wire) return t;
    }
    return popular;
  }
}

DateTime _parseInstant(Object? raw) {
  if (raw is DateTime) return raw.toUtc();
  if (raw is String && raw.isNotEmpty) return DateTime.parse(raw).toUtc();
  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

DateTime? _parseInstantOrNull(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw.toUtc();
  if (raw is String && raw.isNotEmpty) return DateTime.parse(raw).toUtc();
  return null;
}

PersonSummary? _parseAuthorOrNull(Object? raw) {
  if (raw is! Map) return null;
  final map = raw.cast<String, dynamic>();
  final userId = (map['user_id'] as String?)?.trim() ?? '';
  final username = (map['username'] as String?)?.trim() ?? '';
  final displayName = (map['display_name'] as String?)?.trim() ?? '';
  if (userId.isEmpty && username.isEmpty && displayName.isEmpty) {
    return null;
  }
  if (userId == '00000000-0000-0000-0000-000000000000') {
    return null;
  }
  return PersonSummary(
    userId: userId,
    username: username,
    displayName: displayName,
  );
}

/// One feature request card or detail payload returned by `0024` RPCs.
class FeatureRequest {
  const FeatureRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.status,
    required this.voteCount,
    required this.votedByMe,
    required this.isMine,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.adminReply,
    this.adminRepliedAt,
    this.shippedAt,
    this.duplicateOf,
    this.canonicalTitle,
  });

  factory FeatureRequest.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseInstant(json['created_at']);
    final updatedAt = _parseInstantOrNull(json['updated_at']) ?? createdAt;
    final reply = (json['admin_reply'] as String?)?.trim();
    return FeatureRequest(
      id: json['id'] as String,
      title: (json['title'] as String? ?? '').trim(),
      body: (json['body'] as String? ?? '').trim(),
      category: FeatureRequestCategory.fromWire(json['category'] as String?),
      status: FeatureRequestStatus.fromWire(json['status'] as String?),
      voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      votedByMe: json['voted_by_me'] == true,
      isMine: json['is_mine'] == true,
      author: _parseAuthorOrNull(json['author']),
      adminReply: (reply == null || reply.isEmpty) ? null : reply,
      adminRepliedAt: _parseInstantOrNull(json['admin_replied_at']),
      shippedAt: _parseInstantOrNull(json['shipped_at']),
      duplicateOf: json['duplicate_of'] as String?,
      canonicalTitle: json['canonical_title'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String title;
  final String body;
  final FeatureRequestCategory category;
  final FeatureRequestStatus status;
  final int voteCount;
  final bool votedByMe;
  final bool isMine;

  /// Null when the original author deleted their account (`ON DELETE SET NULL`).
  /// Never exposes email or private `avatar_path`.
  final PersonSummary? author;

  /// Official public reply from Ourney team (`admin_reply`).
  final String? adminReply;
  final DateTime? adminRepliedAt;
  final DateTime? shippedAt;

  /// Canonical target request ID when merged as a duplicate.
  final String? duplicateOf;

  /// Optional title of the canonical request (`get_feature_request`).
  final String? canonicalTitle;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isShipped => status == FeatureRequestStatus.shipped;
  bool get isDeclined => status == FeatureRequestStatus.declined;
  bool get isMerged => duplicateOf != null;

  /// Votes are locked once shipped, declined, or merged into another request.
  bool get canVote => status.canVote && duplicateOf == null;

  /// Authors can edit or delete their own request only while `status == 'new'`
  /// and not merged.
  bool get canAuthorModify =>
      isMine && status == FeatureRequestStatus.newRequest && duplicateOf == null;

  /// True when the author edited the request while still in `new` status.
  bool get wasEdited =>
      status == FeatureRequestStatus.newRequest &&
      updatedAt.difference(createdAt).inSeconds > 2;

  String? get authorUserId {
    final uid = author?.userId;
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  FeatureRequest copyWith({
    String? title,
    String? body,
    FeatureRequestCategory? category,
    FeatureRequestStatus? status,
    int? voteCount,
    bool? votedByMe,
    bool? isMine,
    PersonSummary? author,
    String? adminReply,
    DateTime? adminRepliedAt,
    DateTime? shippedAt,
    String? duplicateOf,
    String? canonicalTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      FeatureRequest(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        category: category ?? this.category,
        status: status ?? this.status,
        voteCount: voteCount ?? this.voteCount,
        votedByMe: votedByMe ?? this.votedByMe,
        isMine: isMine ?? this.isMine,
        author: author ?? this.author,
        adminReply: adminReply ?? this.adminReply,
        adminRepliedAt: adminRepliedAt ?? this.adminRepliedAt,
        shippedAt: shippedAt ?? this.shippedAt,
        duplicateOf: duplicateOf ?? this.duplicateOf,
        canonicalTitle: canonicalTitle ?? this.canonicalTitle,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category.wireName,
        'status': status.wireName,
        'vote_count': voteCount,
        'voted_by_me': votedByMe,
        'is_mine': isMine,
        'author': author == null
            ? null
            : {
                'user_id': author!.userId,
                'username': author!.username,
                'display_name': author!.displayName,
              },
        'admin_reply': adminReply,
        'admin_replied_at': adminRepliedAt?.toUtc().toIso8601String(),
        'shipped_at': shippedAt?.toUtc().toIso8601String(),
        'duplicate_of': duplicateOf,
        'canonical_title': canonicalTitle,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}

/// Authoritative vote state returned by `toggle_feature_request_vote`.
class FeatureRequestVoteResult {
  const FeatureRequestVoteResult({
    required this.requestId,
    required this.voteCount,
    required this.votedByMe,
  });

  factory FeatureRequestVoteResult.fromJson(Map<String, dynamic> json) =>
      FeatureRequestVoteResult(
        requestId: json['request_id'] as String,
        voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
        votedByMe: json['voted_by_me'] == true,
      );

  final String requestId;
  final int voteCount;
  final bool votedByMe;
}

/// In-app Activity/Inbox item returned by `my_shipped_request_notifications`.
class ShippedRequestNotification {
  const ShippedRequestNotification({
    required this.requestId,
    required this.title,
    required this.category,
    required this.isAuthor,
    required this.createdAt,
    required this.seen,
    this.adminReply,
    this.shippedAt,
  });

  factory ShippedRequestNotification.fromJson(Map<String, dynamic> json) {
    final reply = (json['admin_reply'] as String?)?.trim();
    return ShippedRequestNotification(
      requestId: json['request_id'] as String,
      title: (json['title'] as String? ?? '').trim(),
      category: FeatureRequestCategory.fromWire(json['category'] as String?),
      adminReply: (reply == null || reply.isEmpty) ? null : reply,
      isAuthor: json['is_author'] == true,
      shippedAt: _parseInstantOrNull(json['shipped_at']),
      createdAt: _parseInstant(json['created_at']),
      seen: json['seen'] == true,
    );
  }

  final String requestId;
  final String title;
  final FeatureRequestCategory category;
  final String? adminReply;
  final bool isAuthor;
  final DateTime? shippedAt;
  final DateTime createdAt;
  final bool seen;
}

/// Contract for the In-App Feature Requests & Roadmap Board (`0024`).
abstract interface class FeatureRequestRepository {
  /// `list_feature_requests`: paginated board query.
  Future<List<FeatureRequest>> list({
    FeatureRequestTab tab = FeatureRequestTab.popular,
    FeatureRequestCategory? category,
    String? search,
    bool mineOnly = false,
    int limit = featureRequestPageSize,
    int offset = 0,
  });

  /// `get_feature_request`: single request detail. Throws `notFound` when
  /// hidden, blocked, reported, or missing.
  Future<FeatureRequest> getById(String id);

  /// `search_similar_feature_requests`: live duplicate deflection while typing
  /// a title in the Create Sheet (min 3 characters).
  Future<List<FeatureRequest>> searchSimilar(
    String query, {
    int limit = 5,
  });

  /// `create_feature_request`: creates a request (`status = 'new'`) and
  /// automatically casts the author's initial upvote (`vote_count = 1`,
  /// `voted_by_me = true`). Idempotent on retry with the same [id].
  /// Rate-limited to 5 / 24h (`rateLimited`). Rejects profanity
  /// (`contentPolicy`) and links (`linksNotAllowed`).
  Future<FeatureRequest> create({
    required String id,
    required String title,
    required String body,
    FeatureRequestCategory category = FeatureRequestCategory.other,
  });

  /// `update_feature_request`: author-only edit while `status == 'new'`, not
  /// hidden, and not merged.
  Future<FeatureRequest> update({
    required String id,
    required String title,
    required String body,
    required FeatureRequestCategory category,
  });

  /// `delete_feature_request`: author-only delete while `status == 'new'`.
  Future<void> delete(String id);

  /// `toggle_feature_request_vote`: sets or toggles the caller's vote on
  /// [requestId]. Throws `ended` if the request is already shipped, declined,
  /// or merged.
  Future<FeatureRequestVoteResult> toggleVote(
    String requestId, {
    bool? voted,
  });

  /// `report_feature_request`: submits a UGC report (24h moderation SLA),
  /// hides the request from the caller immediately, and returns the report ID.
  Future<String> report({
    required String requestId,
    required ReportReason reason,
    String? note,
  });

  /// `my_shipped_request_notifications`: shipped requests the caller voted for
  /// or authored (shown in the Activity Inbox).
  Future<List<ShippedRequestNotification>> myShippedNotifications({
    int limit = 20,
  });

  /// `mark_shipped_requests_seen`: clears unseen shipped-request notifications
  /// (all unseen when [requestIds] is null, or the given subset).
  Future<int> markShippedSeen({List<String>? requestIds});
}
