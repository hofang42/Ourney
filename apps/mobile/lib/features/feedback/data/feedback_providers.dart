import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../safety/data/safety_providers.dart';

/// Unwraps Riverpod's [ProviderException].
Object feedbackRootError(Object error) {
  var e = error;
  while (e is ProviderException) {
    e = e.exception;
  }
  return e;
}

/// Extracts [OurneyErrorCode] from a repository or provider exception.
OurneyErrorCode? feedbackErrorCode(Object error) {
  final root = feedbackRootError(error);
  if (root is OurneyException) return root.error;
  if (root is UnimplementedError) return OurneyErrorCode.serverOutdated;
  return null;
}

/// True when the backend does not have migration `0024` deployed yet or the
/// repository provider is unwired (Amendment F5).
bool isFeedbackServerOutdated(Object error) {
  final root = feedbackRootError(error);
  if (root is UnimplementedError) return true;
  return root is OurneyException &&
      root.error == OurneyErrorCode.serverOutdated;
}

/// Unsent draft preserved in `SharedPreferencesWithCache` per user.
@immutable
class FeedbackComposeDraft {
  const FeedbackComposeDraft({
    this.title = '',
    this.body = '',
    this.category = FeatureRequestCategory.other,
  });

  factory FeedbackComposeDraft.fromJson(Map<String, dynamic> json) =>
      FeedbackComposeDraft(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        category: FeatureRequestCategory.fromWire(json['category'] as String?),
      );

  final String title;
  final String body;
  final FeatureRequestCategory category;

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'category': category.wireName,
      };
}

class FeedbackDraftNotifier extends Notifier<FeedbackComposeDraft?> {
  String get _prefsKey {
    final uid = ref.read(currentUserIdProvider) ?? 'guest';
    return 'feedback.composeDraft.$uid';
  }

  @override
  FeedbackComposeDraft? build() {
    final uid = ref.watch(currentUserIdProvider) ?? 'guest';
    final key = 'feedback.composeDraft.$uid';
    try {
      final raw = ref.watch(sharedPreferencesProvider).getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final draft = FeedbackComposeDraft.fromJson(
        decoded.cast<String, dynamic>(),
      );
      return draft.isEmpty ? null : draft;
    } on Object {
      return null;
    }
  }

  Future<void> save(FeedbackComposeDraft draft) async {
    if (draft.isEmpty) {
      await clear();
      return;
    }
    state = draft;
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(_prefsKey, jsonEncode(draft.toJson()));
    } on Object {
      // Ignore if SharedPreferences is not overridden in a minimal unit test.
    }
  }

  Future<void> clear() async {
    state = null;
    try {
      await ref.read(sharedPreferencesProvider).remove(_prefsKey);
    } on Object {
      // Ignore if SharedPreferences is not overridden.
    }
  }
}

final feedbackDraftProvider =
    NotifierProvider<FeedbackDraftNotifier, FeedbackComposeDraft?>(
  FeedbackDraftNotifier.new,
);

/// Read cache for the first page of `popular` and `mine` lists per user.
class FeedbackCacheStore {
  FeedbackCacheStore(this._ref);

  final Ref _ref;

  String _key({required bool mineOnly}) {
    final uid = _ref.read(currentUserIdProvider) ?? 'guest';
    final bucket = mineOnly ? 'mine' : 'popular';
    return 'feedback.cache.$bucket.$uid';
  }

  List<FeatureRequest>? read({required bool mineOnly}) {
    try {
      final raw = _ref
          .read(sharedPreferencesProvider)
          .getString(_key(mineOnly: mineOnly));
      if (raw == null || raw.isEmpty) return null;
      final list = jsonDecode(raw);
      if (list is! List) return null;
      return [
        for (final item in list)
          if (item is Map)
            FeatureRequest.fromJson(item.cast<String, dynamic>()),
      ];
    } on Object {
      return null;
    }
  }

  Future<void> write({
    required bool mineOnly,
    required List<FeatureRequest> items,
  }) async {
    try {
      final capped = items.take(featureRequestPageSize).toList();
      await _ref.read(sharedPreferencesProvider).setString(
            _key(mineOnly: mineOnly),
            jsonEncode([for (final i in capped) i.toJson()]),
          );
    } on Object {
      // Ignore in tests without SharedPreferences.
    }
  }
}

final feedbackCacheStoreProvider = Provider<FeedbackCacheStore>(
  FeedbackCacheStore.new,
);

/// Requests hidden locally on this device during the current session (after a
/// UGC report or author deletion).
class HiddenFeatureRequests extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(currentUserIdProvider);
    return const {};
  }

  void hide(String requestId) => state = {...state, requestId};
}

final hiddenFeatureRequestIdsProvider =
    NotifierProvider<HiddenFeatureRequests, Set<String>>(
  HiddenFeatureRequests.new,
);

/// Optimistic vote state `(votedByMe, voteCount)` overlaid on top of board and
/// detail providers, with per-request RPC serialization and coalescing.
typedef VoteOverlayEntry = ({bool votedByMe, int voteCount});

class FeedbackVoteOverlayNotifier
    extends Notifier<Map<String, VoteOverlayEntry>> {
  final Set<String> _inFlight = {};
  final Map<String, bool> _desired = {};
  final Map<String, VoteOverlayEntry> _baseline = {};

  @override
  Map<String, VoteOverlayEntry> build() {
    ref.watch(currentUserIdProvider);
    _inFlight.clear();
    _desired.clear();
    _baseline.clear();
    return const {};
  }

  FeatureRequest applyTo(FeatureRequest item) {
    final entry = state[item.id];
    if (entry == null) return item;
    return item.copyWith(
      votedByMe: entry.votedByMe,
      voteCount: entry.voteCount,
    );
  }

  void seed(
    String requestId, {
    required bool votedByMe,
    required int voteCount,
  }) {
    state = {
      ...state,
      requestId: (votedByMe: votedByMe, voteCount: voteCount),
    };
  }

  /// Toggles the caller's vote on [item] optimistically and coalesces rapid
  /// taps into the latest desired state. Returns `null` on success or the
  /// failure [OurneyErrorCode] if the server rejected the vote and state was
  /// rolled back.
  Future<OurneyErrorCode?> toggle(FeatureRequest item) async {
    if (!item.canVote) return OurneyErrorCode.ended;
    final current = applyTo(item);
    final nextVoted = !current.votedByMe;
    final nextCount = math.max(0, current.voteCount + (nextVoted ? 1 : -1));

    if (!_inFlight.contains(item.id)) {
      _baseline[item.id] = (
        votedByMe: current.votedByMe,
        voteCount: current.voteCount,
      );
    }

    state = {
      ...state,
      item.id: (votedByMe: nextVoted, voteCount: nextCount),
    };
    _desired[item.id] = nextVoted;

    if (_inFlight.contains(item.id)) {
      return null;
    }

    _inFlight.add(item.id);
    try {
      final repo = ref.read(featureRequestRepositoryProvider);
      while (_desired.containsKey(item.id)) {
        final targetVoted = _desired.remove(item.id)!;
        final result = await repo.toggleVote(item.id, voted: targetVoted);
        if (!_desired.containsKey(item.id)) {
          state = {
            ...state,
            item.id: (
              votedByMe: result.votedByMe,
              voteCount: result.voteCount,
            ),
          };
        }
      }
      return null;
    } on Object catch (e) {
      _desired.remove(item.id);
      final base = _baseline[item.id];
      if (base != null) {
        state = {...state, item.id: base};
      } else {
        final copy = {...state}..remove(item.id);
        state = copy;
      }
      return feedbackErrorCode(e) ?? OurneyErrorCode.unknown;
    } finally {
      _inFlight.remove(item.id);
      _baseline.remove(item.id);
    }
  }
}

final feedbackVoteOverlayProvider =
    NotifierProvider<FeedbackVoteOverlayNotifier, Map<String, VoteOverlayEntry>>(
  FeedbackVoteOverlayNotifier.new,
);

/// Current board filter state on `/feedback`.
@immutable
class FeedbackBoardQuery {
  const FeedbackBoardQuery({
    this.tab = FeatureRequestTab.popular,
    this.category,
    this.search = '',
    this.mineOnly = false,
  });

  final FeatureRequestTab tab;
  final FeatureRequestCategory? category;
  final String search;
  final bool mineOnly;

  bool get isCacheableDefault =>
      category == null &&
      search.trim().isEmpty &&
      (mineOnly || tab == FeatureRequestTab.popular);

  FeedbackBoardQuery copyWith({
    FeatureRequestTab? tab,
    FeatureRequestCategory? category,
    bool clearCategory = false,
    String? search,
    bool? mineOnly,
  }) =>
      FeedbackBoardQuery(
        tab: tab ?? this.tab,
        category: clearCategory ? null : (category ?? this.category),
        search: search ?? this.search,
        mineOnly: mineOnly ?? this.mineOnly,
      );

  @override
  bool operator ==(Object other) =>
      other is FeedbackBoardQuery &&
      other.tab == tab &&
      other.category == category &&
      other.search == search &&
      other.mineOnly == mineOnly;

  @override
  int get hashCode => Object.hash(tab, category, search, mineOnly);
}

@immutable
class FeedbackBoardData {
  const FeedbackBoardData({
    required this.items,
    required this.hasMore,
    this.isOfflineCached = false,
    this.isLoadingMore = false,
  });

  final List<FeatureRequest> items;
  final bool hasMore;
  final bool isOfflineCached;
  final bool isLoadingMore;

  FeedbackBoardData copyWith({
    List<FeatureRequest>? items,
    bool? hasMore,
    bool? isOfflineCached,
    bool? isLoadingMore,
  }) =>
      FeedbackBoardData(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        isOfflineCached: isOfflineCached ?? this.isOfflineCached,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class FeedbackQueryNotifier extends Notifier<FeedbackBoardQuery> {
  @override
  FeedbackBoardQuery build() => const FeedbackBoardQuery();

  void setTab(FeatureRequestTab tab) {
    if (state.tab == tab && !state.mineOnly) return;
    state = state.copyWith(tab: tab, mineOnly: false);
  }

  void toggleMine() {
    state = state.copyWith(mineOnly: !state.mineOnly);
  }

  void setCategory(FeatureRequestCategory? category) {
    if (state.category == category) return;
    state = category == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(category: category);
  }

  void setSearch(String search) {
    if (state.search == search) return;
    state = state.copyWith(search: search);
  }
}

final feedbackQueryProvider =
    NotifierProvider.autoDispose<FeedbackQueryNotifier, FeedbackBoardQuery>(
  FeedbackQueryNotifier.new,
);

class FeedbackBoardController extends AsyncNotifier<FeedbackBoardData> {
  List<FeatureRequest> _rawItems = const [];
  bool _hasMore = false;
  bool _isOfflineCached = false;
  bool _isLoadingMore = false;

  @override
  Future<FeedbackBoardData> build() async {
    final query = ref.watch(feedbackQueryProvider);
    final repo = ref.watch(featureRequestRepositoryProvider);
    final cache = ref.read(feedbackCacheStoreProvider);

    try {
      final fetched = await repo.list(
        tab: query.tab,
        category: query.category,
        search: query.search.trim().isEmpty ? null : query.search.trim(),
        mineOnly: query.mineOnly,
        limit: featureRequestPageSize,
        offset: 0,
      );
      _rawItems = fetched;
      _hasMore = fetched.length >= featureRequestPageSize;
      _isOfflineCached = false;
      _isLoadingMore = false;
      if (query.isCacheableDefault) {
        unawaited(cache.write(mineOnly: query.mineOnly, items: fetched));
      }
      return FeedbackBoardData(
        items: _rawItems,
        hasMore: _hasMore,
      );
    } on Object catch (e) {
      if (feedbackErrorCode(e) == OurneyErrorCode.offline) {
        final cached = cache.read(mineOnly: query.mineOnly) ??
            cache.read(mineOnly: false);
        if (cached != null && cached.isNotEmpty) {
          final filtered = _filterCached(cached, query);
          _rawItems = filtered;
          _hasMore = false;
          _isOfflineCached = true;
          _isLoadingMore = false;
          return FeedbackBoardData(
            items: _rawItems,
            hasMore: false,
            isOfflineCached: true,
          );
        }
      }
      rethrow;
    }
  }

  List<FeatureRequest> _filterCached(
    List<FeatureRequest> cached,
    FeedbackBoardQuery query,
  ) {
    final foldedSearch = foldVietnameseDiacritics(query.search.trim());
    return [
      for (final item in cached)
        if ((!query.mineOnly || item.isMine) &&
            (query.category == null || item.category == query.category) &&
            (foldedSearch.isEmpty ||
                foldVietnameseDiacritics(item.title).contains(foldedSearch) ||
                foldVietnameseDiacritics(item.body).contains(foldedSearch)))
          item,
    ];
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isOfflineCached) return;
    final current = state.asData?.value;
    if (current == null) return;

    _isLoadingMore = true;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final query = ref.read(feedbackQueryProvider);
      final repo = ref.read(featureRequestRepositoryProvider);
      final next = await repo.list(
        tab: query.tab,
        category: query.category,
        search: query.search.trim().isEmpty ? null : query.search.trim(),
        mineOnly: query.mineOnly,
        limit: featureRequestPageSize,
        offset: _rawItems.length,
      );
      final existingIds = {for (final i in _rawItems) i.id};
      _rawItems = [
        ..._rawItems,
        for (final i in next)
          if (!existingIds.contains(i.id)) i,
      ];
      _hasMore = next.length >= featureRequestPageSize;
      _isLoadingMore = false;
      state = AsyncData(
        FeedbackBoardData(
          items: _rawItems,
          hasMore: _hasMore,
          isOfflineCached: _isOfflineCached,
        ),
      );
    } on Object {
      _isLoadingMore = false;
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  void prependCreated(FeatureRequest created) {
    ref.read(feedbackVoteOverlayProvider.notifier).seed(
          created.id,
          votedByMe: created.votedByMe,
          voteCount: created.voteCount,
        );
    _rawItems = [
      created,
      for (final item in _rawItems)
        if (item.id != created.id) item,
    ];
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(items: _rawItems));
    }
  }

  void replaceUpdated(FeatureRequest updated) {
    _rawItems = [
      for (final item in _rawItems) item.id == updated.id ? updated : item,
    ];
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(items: _rawItems));
    }
  }
}

final rawFeedbackBoardProvider =
    AsyncNotifierProvider.autoDispose<FeedbackBoardController, FeedbackBoardData>(
  FeedbackBoardController.new,
  retry: (_, _) => null,
);

/// Board data with blocked authors, locally reported/deleted items, and
/// optimistic vote overlays applied immediately.
final feedbackBoardProvider =
    Provider.autoDispose<AsyncValue<FeedbackBoardData>>((ref) {
  final raw = ref.watch(rawFeedbackBoardProvider);
  final blocked = ref.watch(blockedUserIdsProvider).asData?.value ?? const {};
  final hidden = ref.watch(hiddenFeatureRequestIdsProvider);
  final voteOverlay = ref.watch(feedbackVoteOverlayProvider);

  return raw.whenData((data) {
    final visible = <FeatureRequest>[];
    for (final item in data.items) {
      if (hidden.contains(item.id)) continue;
      if (item.authorUserId != null && blocked.contains(item.authorUserId)) {
        continue;
      }
      final ov = voteOverlay[item.id];
      visible.add(
        ov == null
            ? item
            : item.copyWith(
                votedByMe: ov.votedByMe,
                voteCount: ov.voteCount,
              ),
      );
    }
    return data.copyWith(items: visible);
  });
});

/// Single feature request detail (`/feedback/:id`), overlaid with optimistic
/// votes and falling back to cached board data when offline.
final rawFeatureRequestDetailProvider = FutureProvider.autoDispose
    .family<FeatureRequest, String>(
  (ref, id) async {
    final repo = ref.watch(featureRequestRepositoryProvider);
    try {
      return await repo.getById(id);
    } on Object catch (e) {
      if (feedbackErrorCode(e) == OurneyErrorCode.offline) {
        final cache = ref.read(feedbackCacheStoreProvider);
        for (final list in [
          cache.read(mineOnly: false),
          cache.read(mineOnly: true),
        ]) {
          if (list == null) continue;
          for (final item in list) {
            if (item.id == id) return item;
          }
        }
      }
      rethrow;
    }
  },
  retry: (_, _) => null,
);

final featureRequestDetailProvider =
    Provider.autoDispose.family<AsyncValue<FeatureRequest>, String>((ref, id) {
  final raw = ref.watch(rawFeatureRequestDetailProvider(id));
  final voteOverlay = ref.watch(feedbackVoteOverlayProvider);
  return raw.whenData((item) {
    final ov = voteOverlay[item.id];
    return ov == null
        ? item
        : item.copyWith(votedByMe: ov.votedByMe, voteCount: ov.voteCount);
  });
});

/// Shipped feature request notifications for the Activity Inbox (`/inbox`).
/// Gracefully returns an empty list if backend migration `0024` is not
/// deployed yet or the repository is not wired (Amendment F5).
final shippedRequestNotificationsProvider =
    FutureProvider.autoDispose<List<ShippedRequestNotification>>(
  (ref) async {
    if (ref.watch(appConfigProvider).localOnly) return const [];
    try {
      final repo = ref.watch(featureRequestRepositoryProvider);
      return await repo.myShippedNotifications();
    } on Object catch (e) {
      if (isFeedbackServerOutdated(e) ||
          feedbackErrorCode(e) == OurneyErrorCode.offline) {
        return const [];
      }
      return const [];
    }
  },
  retry: (_, _) => null,
);
