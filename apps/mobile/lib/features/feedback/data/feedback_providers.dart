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

/// Shared-preferences keys of the feedback feature.
abstract final class FeedbackPrefs {
  static const draftPrefix = 'feedback.composeDraft.';
  static const cachePrefix = 'feedback.cache.';
  static const cachePopularPrefix = 'feedback.cache.popular.';
  static const cacheMinePrefix = 'feedback.cache.mine.';

  static String draftFor(String userId) => '$draftPrefix$userId';

  static String cacheFor(String userId, {required bool mineOnly}) =>
      '${mineOnly ? cacheMinePrefix : cachePopularPrefix}$userId';

  /// The user id of a feedback draft or board cache preference [key], else
  /// null.
  static String? userIdOfKey(String key) {
    if (key.startsWith(draftPrefix)) {
      final uid = key.substring(draftPrefix.length);
      return uid.isEmpty ? null : uid;
    }
    if (key.startsWith(cachePrefix)) {
      final rest = key.substring(cachePrefix.length);
      final dot = rest.indexOf('.');
      if (dot <= 0 || dot >= rest.length - 1) return null;
      return rest.substring(dot + 1);
    }
    return null;
  }
}

/// Unsent draft preserved in `SharedPreferencesWithCache` per user.
@immutable
class FeedbackComposeDraft {
  const FeedbackComposeDraft({
    this.id,
    this.title = '',
    this.body = '',
    this.category = FeatureRequestCategory.other,
  });

  factory FeedbackComposeDraft.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] as String?)?.trim();
    return FeedbackComposeDraft(
      id: (rawId == null || rawId.isEmpty) ? null : rawId,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: FeatureRequestCategory.fromWire(json['category'] as String?),
    );
  }

  final String? id;
  final String title;
  final String body;
  final FeatureRequestCategory category;

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'title': title,
        'body': body,
        'category': category.wireName,
      };
}

class FeedbackDraftNotifier extends Notifier<FeedbackComposeDraft?> {
  String get _prefsKey {
    final uid = ref.read(currentUserIdProvider) ?? 'guest';
    return FeedbackPrefs.draftFor(uid);
  }

  @override
  FeedbackComposeDraft? build() {
    final uid = ref.watch(currentUserIdProvider) ?? 'guest';
    final key = FeedbackPrefs.draftFor(uid);
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

  Future<void> clearAll() async {
    state = null;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      for (final key in prefs.keys.toList()) {
        if (key.startsWith(FeedbackPrefs.draftPrefix)) {
          await prefs.remove(key);
        }
      }
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
    return FeedbackPrefs.cacheFor(uid, mineOnly: mineOnly);
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

  Future<void> clearAll() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      for (final key in prefs.keys.toList()) {
        if (key.startsWith(FeedbackPrefs.cachePrefix)) {
          await prefs.remove(key);
        }
      }
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
  int _epoch = 0;
  final Set<String> _inFlight = {};
  final Map<String, bool> _desired = {};
  final Map<String, VoteOverlayEntry> _baseline = {};

  @override
  Map<String, VoteOverlayEntry> build() {
    ref.watch(currentUserIdProvider);
    _epoch++;
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

  /// Drops settled overlay entries for [freshItems] once fresh server data has
  /// arrived so stale session votes never clobber newer server vote counts.
  /// Entries with an in-flight or queued vote RPC keep their optimistic state
  /// and refresh their rollback baseline against the server's latest count.
  void reconcileServerItems(Iterable<FeatureRequest> freshItems) {
    if (state.isEmpty && _baseline.isEmpty) return;
    Map<String, VoteOverlayEntry>? nextState;
    for (final item in freshItems) {
      final serverEntry = (
        votedByMe: item.votedByMe,
        voteCount: item.voteCount,
      );
      if (_inFlight.contains(item.id) || _desired.containsKey(item.id)) {
        _baseline[item.id] = serverEntry;
        final desired = _desired[item.id];
        if (desired != null) {
          final delta =
              desired == serverEntry.votedByMe ? 0 : (desired ? 1 : -1);
          nextState ??= {...state};
          nextState[item.id] = (
            votedByMe: desired,
            voteCount: math.max(0, serverEntry.voteCount + delta),
          );
        }
      } else if (state.containsKey(item.id)) {
        nextState ??= {...state};
        nextState.remove(item.id);
      }
    }
    if (nextState != null) {
      state = nextState;
    }
  }

  void _reconcileBoard(String requestId, VoteOverlayEntry committed) {
    if (!ref.exists(rawFeedbackBoardProvider)) return;
    ref.read(rawFeedbackBoardProvider.notifier).reconcileVote(
          requestId,
          votedByMe: committed.votedByMe,
          voteCount: committed.voteCount,
        );
  }

  /// Toggles the caller's vote on [item] optimistically and coalesces rapid
  /// taps into the latest desired state. Returns `null` on success or the
  /// failure [OurneyErrorCode] if the server rejected the vote and state was
  /// rolled back.
  Future<OurneyErrorCode?> toggle(FeatureRequest item) async {
    if (!item.canVote) return OurneyErrorCode.ended;
    final epoch = _epoch;
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
        if (epoch != _epoch) return null;
        final targetVoted = _desired.remove(item.id)!;
        final result = await repo.toggleVote(item.id, voted: targetVoted);
        if (epoch != _epoch) return null;
        final committed = (
          votedByMe: result.votedByMe,
          voteCount: result.voteCount,
        );
        _baseline[item.id] = committed;
        _reconcileBoard(item.id, committed);
        final nextDesired = _desired[item.id];
        if (nextDesired == null) {
          state = {...state, item.id: committed};
        } else {
          final delta =
              nextDesired == committed.votedByMe ? 0 : (nextDesired ? 1 : -1);
          state = {
            ...state,
            item.id: (
              votedByMe: nextDesired,
              voteCount: math.max(0, committed.voteCount + delta),
            ),
          };
        }
      }
      return null;
    } on Object catch (e) {
      if (epoch != _epoch) return null;
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
      if (epoch == _epoch) {
        _inFlight.remove(item.id);
        _baseline.remove(item.id);
      }
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
  int _buildEpoch = 0;
  List<FeatureRequest> _rawItems = const [];
  bool _hasMore = false;
  bool _isOfflineCached = false;
  bool _isLoadingMore = false;

  @override
  Future<FeedbackBoardData> build() async {
    final epoch = ++_buildEpoch;
    _isLoadingMore = false;
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
      if (epoch == _buildEpoch) {
        _rawItems = fetched;
        _hasMore = fetched.length >= featureRequestPageSize;
        _isOfflineCached = false;
        _isLoadingMore = false;
      }
      ref.read(feedbackVoteOverlayProvider.notifier).reconcileServerItems(
            fetched,
          );
      if (query.isCacheableDefault) {
        unawaited(cache.write(mineOnly: query.mineOnly, items: fetched));
      }
      return FeedbackBoardData(
        items: fetched,
        hasMore: fetched.length >= featureRequestPageSize,
      );
    } on Object catch (e) {
      if (feedbackErrorCode(e) == OurneyErrorCode.offline) {
        final cached = _readMergedCache(cache, mineOnly: query.mineOnly);
        if (cached != null && cached.isNotEmpty) {
          final filtered = _filterCached(cached, query);
          if (epoch == _buildEpoch) {
            _rawItems = filtered;
            _hasMore = false;
            _isOfflineCached = true;
            _isLoadingMore = false;
          }
          return FeedbackBoardData(
            items: filtered,
            hasMore: false,
            isOfflineCached: true,
          );
        }
      }
      rethrow;
    }
  }

  List<FeatureRequest>? _readMergedCache(
    FeedbackCacheStore cache, {
    required bool mineOnly,
  }) {
    final primary = cache.read(mineOnly: mineOnly);
    final secondary = cache.read(mineOnly: !mineOnly);
    if (primary == null && secondary == null) return null;
    final seen = <String>{};
    final merged = <FeatureRequest>[];
    for (final list in [primary, secondary]) {
      if (list == null) continue;
      for (final item in list) {
        if (seen.add(item.id)) merged.add(item);
      }
    }
    return merged;
  }

  List<FeatureRequest> _filterCached(
    List<FeatureRequest> cached,
    FeedbackBoardQuery query,
  ) {
    final hidden = ref.read(hiddenFeatureRequestIdsProvider);
    final matches = <FeatureRequest>[
      for (final item in cached)
        if (!hidden.contains(item.id) && _matchesQuery(item, query)) item,
    ];
    if (query.mineOnly) {
      matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      switch (query.tab) {
        case FeatureRequestTab.popular:
          matches.sort((a, b) {
            final byVotes = b.voteCount.compareTo(a.voteCount);
            return byVotes != 0 ? byVotes : b.createdAt.compareTo(a.createdAt);
          });
        case FeatureRequestTab.newest:
          matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        case FeatureRequestTab.planned:
          matches.sort((a, b) {
            final aInProgress = a.status == FeatureRequestStatus.inProgress;
            final bInProgress = b.status == FeatureRequestStatus.inProgress;
            if (aInProgress != bInProgress) return bInProgress ? 1 : -1;
            final byVotes = b.voteCount.compareTo(a.voteCount);
            return byVotes != 0 ? byVotes : b.createdAt.compareTo(a.createdAt);
          });
        case FeatureRequestTab.shipped:
          matches.sort(
            (a, b) => (b.shippedAt ?? b.updatedAt).compareTo(
              a.shippedAt ?? a.updatedAt,
            ),
          );
      }
    }
    return matches;
  }

  bool _matchesQuery(FeatureRequest item, FeedbackBoardQuery query) {
    if (!_matchesCachedTab(item, query)) return false;
    if (query.category != null && item.category != query.category) {
      return false;
    }
    final foldedSearch = foldVietnameseDiacritics(query.search.trim());
    if (foldedSearch.isNotEmpty &&
        !foldVietnameseDiacritics(item.title).contains(foldedSearch) &&
        !foldVietnameseDiacritics(item.body).contains(foldedSearch)) {
      return false;
    }
    return true;
  }

  bool _matchesCachedTab(FeatureRequest item, FeedbackBoardQuery query) {
    if (query.mineOnly) return item.isMine;
    if (item.duplicateOf != null || item.isDeclined) return false;
    return switch (query.tab) {
      FeatureRequestTab.popular || FeatureRequestTab.newest => !item.isShipped,
      FeatureRequestTab.planned =>
        item.status == FeatureRequestStatus.planned ||
            item.status == FeatureRequestStatus.inProgress,
      FeatureRequestTab.shipped => item.isShipped,
    };
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isOfflineCached) return;
    final current = state.asData?.value;
    if (current == null) return;

    final epoch = _buildEpoch;
    final query = ref.read(feedbackQueryProvider);
    final offset = _rawItems.length;
    _isLoadingMore = true;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final repo = ref.read(featureRequestRepositoryProvider);
      final next = await repo.list(
        tab: query.tab,
        category: query.category,
        search: query.search.trim().isEmpty ? null : query.search.trim(),
        mineOnly: query.mineOnly,
        limit: featureRequestPageSize,
        offset: offset,
      );
      if (epoch != _buildEpoch || ref.read(feedbackQueryProvider) != query) {
        return;
      }
      ref.read(feedbackVoteOverlayProvider.notifier).reconcileServerItems(next);
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
      if (epoch != _buildEpoch || ref.read(feedbackQueryProvider) != query) {
        return;
      }
      _isLoadingMore = false;
      final latest = state.asData?.value ?? current;
      state = AsyncData(latest.copyWith(isLoadingMore: false));
    }
  }

  void prependCreated(FeatureRequest created) {
    ref.read(feedbackVoteOverlayProvider.notifier).reconcileServerItems([
      created,
    ]);
    final query = ref.read(feedbackQueryProvider);
    if (!_matchesQuery(created, query)) {
      ref.invalidateSelf();
      return;
    }
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
    ref.read(feedbackVoteOverlayProvider.notifier).reconcileServerItems([
      updated,
    ]);
    _rawItems = [
      for (final item in _rawItems) item.id == updated.id ? updated : item,
    ];
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(items: _rawItems));
    }
  }

  void reconcileVote(
    String requestId, {
    required bool votedByMe,
    required int voteCount,
  }) {
    var changed = false;
    _rawItems = [
      for (final item in _rawItems)
        if (item.id == requestId &&
            (item.votedByMe != votedByMe || item.voteCount != voteCount))
          (() {
            changed = true;
            return item.copyWith(votedByMe: votedByMe, voteCount: voteCount);
          })()
        else
          item,
    ];
    if (!changed) return;
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
      final item = await repo.getById(id);
      ref.read(feedbackVoteOverlayProvider.notifier).reconcileServerItems([
        item,
      ]);
      if (ref.exists(rawFeedbackBoardProvider)) {
        ref.read(rawFeedbackBoardProvider.notifier).reconcileVote(
              item.id,
              votedByMe: item.votedByMe,
              voteCount: item.voteCount,
            );
      }
      return item;
    } on Object catch (e) {
      if (feedbackErrorCode(e) == OurneyErrorCode.offline) {
        final hidden = ref.read(hiddenFeatureRequestIdsProvider);
        if (!hidden.contains(id)) {
          final blocked =
              ref.read(blockedUserIdsProvider).asData?.value ?? const {};
          final cache = ref.read(feedbackCacheStoreProvider);
          final boardItems = ref.exists(rawFeedbackBoardProvider)
              ? ref.read(rawFeedbackBoardProvider).asData?.value.items
              : null;
          for (final list in [
            boardItems,
            cache.read(mineOnly: false),
            cache.read(mineOnly: true),
          ]) {
            if (list == null) continue;
            for (final item in list) {
              if (item.id == id && !hidden.contains(item.id)) {
                if (item.authorUserId != null &&
                    blocked.contains(item.authorUserId)) {
                  throw const OurneyException(OurneyErrorCode.notFound);
                }
                return item;
              }
            }
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
  final hidden = ref.watch(hiddenFeatureRequestIdsProvider);
  final blocked = ref.watch(blockedUserIdsProvider).asData?.value ?? const {};
  final voteOverlay = ref.watch(feedbackVoteOverlayProvider);
  return raw.when(
    data: (item) {
      if (hidden.contains(item.id) ||
          (item.authorUserId != null && blocked.contains(item.authorUserId))) {
        return AsyncError(
          const OurneyException(OurneyErrorCode.notFound),
          StackTrace.empty,
        );
      }
      final ov = voteOverlay[item.id];
      return AsyncData(
        ov == null
            ? item
            : item.copyWith(votedByMe: ov.votedByMe, voteCount: ov.voteCount),
      );
    },
    error: AsyncError.new,
    loading: AsyncLoading.new,
  );
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
