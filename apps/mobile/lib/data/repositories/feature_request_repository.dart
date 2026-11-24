import 'package:ourney_core/ourney_core.dart';

import '../social_context.dart';
import '../social_mapping.dart' show rowOf, rowsOf;

/// [FeatureRequestRepository] over the migration `0024` RPCs.
class DataFeatureRequestRepository implements FeatureRequestRepository {
  DataFeatureRequestRepository(this.social);

  final SocialContext social;

  @override
  Future<List<FeatureRequest>> list({
    FeatureRequestTab tab = FeatureRequestTab.popular,
    FeatureRequestCategory? category,
    String? search,
    bool mineOnly = false,
    int limit = featureRequestPageSize,
    int offset = 0,
  }) {
    final trimmedSearch = search?.trim();
    return social.call(
      'list_feature_requests',
      {
        'p_tab': tab.wireName,
        'p_category': category?.wireName,
        'p_search': (trimmedSearch == null || trimmedSearch.isEmpty)
            ? null
            : trimmedSearch,
        'p_mine_only': mineOnly,
        'p_limit': limit,
        'p_offset': offset,
      },
      (json) => [for (final r in rowsOf(json)) FeatureRequest.fromJson(r)],
    );
  }

  @override
  Future<FeatureRequest> getById(String id) => social.call(
        'get_feature_request',
        {'p_id': id},
        (json) => FeatureRequest.fromJson(rowOf(json)),
      );

  @override
  Future<List<FeatureRequest>> searchSimilar(
    String query, {
    int limit = 5,
  }) async {
    final trimmed = query.trim();
    if (trimmed.runes.length < 3) return const [];
    return social.call(
      'search_similar_feature_requests',
      {'p_query': trimmed, 'p_limit': limit},
      (json) => [for (final r in rowsOf(json)) FeatureRequest.fromJson(r)],
    );
  }

  @override
  Future<FeatureRequest> create({
    required String id,
    required String title,
    required String body,
    FeatureRequestCategory category = FeatureRequestCategory.other,
  }) async {
    final created = await social.call(
      'create_feature_request',
      {
        'p_id': id,
        'p_title': title.trim(),
        'p_body': body.trim(),
        'p_category': category.wireName,
      },
      (json) => FeatureRequest.fromJson(rowOf(json)),
    );
    social.changed();
    return created;
  }

  @override
  Future<FeatureRequest> update({
    required String id,
    required String title,
    required String body,
    required FeatureRequestCategory category,
  }) async {
    final updated = await social.call(
      'update_feature_request',
      {
        'p_id': id,
        'p_title': title.trim(),
        'p_body': body.trim(),
        'p_category': category.wireName,
      },
      (json) => FeatureRequest.fromJson(rowOf(json)),
    );
    social.changed();
    return updated;
  }

  @override
  Future<void> delete(String id) =>
      social.mutate('delete_feature_request', {'p_id': id});

  @override
  Future<FeatureRequestVoteResult> toggleVote(
    String requestId, {
    bool? voted,
  }) =>
      social.call(
        'toggle_feature_request_vote',
        {'p_request_id': requestId, 'p_voted': voted},
        (json) => FeatureRequestVoteResult.fromJson(rowOf(json)),
      );

  @override
  Future<String> report({
    required String requestId,
    required ReportReason reason,
    String? note,
  }) async {
    final trimmedNote = note?.trim();
    final reportId = await social.call(
      'report_feature_request',
      {
        'p_request_id': requestId,
        'p_reason': reason.wireName,
        'p_note':
            (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
      },
      (json) => '$json',
    );
    social.changed();
    return reportId;
  }

  @override
  Future<List<ShippedRequestNotification>> myShippedNotifications({
    int limit = 20,
  }) =>
      social.call(
        'my_shipped_request_notifications',
        {'p_limit': limit},
        (json) => [
          for (final r in rowsOf(json)) ShippedRequestNotification.fromJson(r),
        ],
      );

  @override
  Future<int> markShippedSeen({List<String>? requestIds}) async {
    final count = await social.call(
      'mark_shipped_requests_seen',
      {'p_request_ids': requestIds},
      (json) => switch (json) {
        final num n => n.toInt(),
        null => 0,
        _ => int.tryParse('$json') ?? 0,
      },
    );
    social.changed();
    return count;
  }
}
