import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ourney/app/account_reset.dart';
import 'package:ourney/app/app_routes.dart';
import 'package:ourney/app/config.dart';
import 'package:ourney/app/localization.dart';
import 'package:ourney/app/providers.dart';
import 'package:ourney/app/theme/app_theme.dart';
import 'package:ourney/data/data_context.dart';
import 'package:ourney/data/remote/remote_api.dart';
import 'package:ourney/data/repositories/feature_request_repository.dart';
import 'package:ourney/data/social_context.dart';
import 'package:ourney/features/feedback/data/feedback_providers.dart';
import 'package:ourney/features/feedback/ui/feature_request_detail_screen.dart';
import 'package:ourney/features/feedback/ui/feature_requests_screen.dart';
import 'package:ourney/features/profile/settings_screen.dart';
import 'package:ourney/features/safety/data/safety_providers.dart';
import 'package:ourney/features/safety/ui/contact_screen.dart';
import 'package:ourney/features/social/data/social_providers.dart';
import 'package:ourney/features/social/ui/inbox_screen.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/test_helpers.dart';

class FakeFeatureRequestRepository implements FeatureRequestRepository {
  FakeFeatureRequestRepository({
    List<FeatureRequest>? initial,
    this.shippedNotifications = const [],
  }) : items = List<FeatureRequest>.of(initial ?? _defaultItems());

  final List<FeatureRequest> items;
  List<ShippedRequestNotification> shippedNotifications;
  Object? listError;
  Object? detailError;
  Object? createError;
  Object? voteError;

  final List<String> listCalls = [];
  final List<String> createdIds = [];
  final List<(String, bool?)> voteCalls = [];
  final List<(String, ReportReason, String?)> reportCalls = [];
  final List<List<String>?> markedSeenCalls = [];
  Completer<FeatureRequestVoteResult>? voteGate;
  Future<FeatureRequestVoteResult> Function(String requestId, bool? voted)?
      onToggleVote;
  Future<List<FeatureRequest>> Function(String query, int limit)?
      onSearchSimilar;
  Future<List<FeatureRequest>> Function(
    FeatureRequestTab tab,
    FeatureRequestCategory? category,
    String? search,
    bool mineOnly,
    int limit,
    int offset,
  )? onList;

  static List<FeatureRequest> _defaultItems() => [
        FeatureRequest(
          id: 'req-1',
          title: 'Widget chuỗi ngày ngoài màn hình khóa',
          body: 'Xem nhanh chuỗi ngày mỗi sáng ngay trên màn hình khóa iOS và Android.',
          category: FeatureRequestCategory.design,
          status: FeatureRequestStatus.planned,
          voteCount: 42,
          votedByMe: true,
          isMine: false,
          author: const PersonSummary(
            userId: 'u-lan',
            username: 'lan_tran',
            displayName: 'Lan Trần',
          ),
          adminReply: 'Nhóm Ourney đang thiết kế widget cho bản cập nhật tiếp theo!',
          adminRepliedAt: DateTime.utc(2026, 11, 22, 10),
          createdAt: DateTime.utc(2026, 11, 18, 8),
          updatedAt: DateTime.utc(2026, 11, 22, 10),
        ),
        FeatureRequest(
          id: 'req-2',
          title: 'Xuất video timelapse từ toàn bộ hành trình',
          body: 'Ghép tự động các ảnh check-in thành video ngắn 15 giây để lưu kỷ niệm.',
          category: FeatureRequestCategory.sharing,
          status: FeatureRequestStatus.newRequest,
          voteCount: 18,
          votedByMe: false,
          isMine: true,
          author: const PersonSummary(
            userId: 'u-me',
            username: 'minh_hoang',
            displayName: 'Minh Hoàng',
          ),
          createdAt: DateTime.utc(2026, 11, 20, 9),
          updatedAt: DateTime.utc(2026, 11, 20, 9),
        ),
        FeatureRequest(
          id: 'req-3',
          title: 'Chế độ hẹn giờ chụp 3 giây và 10 giây',
          body: 'Giúp tự chụp ảnh toàn thân dễ hơn khi tập luyện một mình.',
          category: FeatureRequestCategory.camera,
          status: FeatureRequestStatus.shipped,
          voteCount: 65,
          votedByMe: true,
          isMine: false,
          author: null,
          adminReply: 'Đã ra mắt trên màn hình Máy ảnh!',
          adminRepliedAt: DateTime.utc(2026, 11, 23, 12),
          shippedAt: DateTime.utc(2026, 11, 23, 12),
          createdAt: DateTime.utc(2026, 11, 10, 7),
          updatedAt: DateTime.utc(2026, 11, 23, 12),
        ),
      ];

  @override
  Future<List<FeatureRequest>> list({
    FeatureRequestTab tab = FeatureRequestTab.popular,
    FeatureRequestCategory? category,
    String? search,
    bool mineOnly = false,
    int limit = featureRequestPageSize,
    int offset = 0,
  }) async {
    listCalls.add(
      'tab=${tab.wireName};cat=${category?.wireName};search=$search;mine=$mineOnly;offset=$offset',
    );
    if (onList != null) {
      return onList!(tab, category, search, mineOnly, limit, offset);
    }
    if (listError != null) throw listError!;

    final foldedQuery =
        search == null ? '' : foldVietnameseDiacritics(search.trim());
    final filtered = items.where((item) {
      if (mineOnly) {
        if (!item.isMine) return false;
      } else {
        if (item.duplicateOf != null || item.isDeclined) return false;
        switch (tab) {
          case FeatureRequestTab.popular || FeatureRequestTab.newest:
            if (item.isShipped) return false;
          case FeatureRequestTab.planned:
            if (item.status != FeatureRequestStatus.planned &&
                item.status != FeatureRequestStatus.inProgress) {
              return false;
            }
          case FeatureRequestTab.shipped:
            if (!item.isShipped) return false;
        }
      }
      if (category != null && item.category != category) return false;
      if (foldedQuery.isNotEmpty) {
        final matchTitle =
            foldVietnameseDiacritics(item.title).contains(foldedQuery);
        final matchBody =
            foldVietnameseDiacritics(item.body).contains(foldedQuery);
        if (!matchTitle && !matchBody) return false;
      }
      return true;
    }).toList();

    return filtered.skip(offset).take(limit).toList();
  }

  @override
  Future<FeatureRequest> getById(String id) async {
    if (detailError != null) throw detailError!;
    for (final item in items) {
      if (item.id == id) return item;
    }
    throw const OurneyException(OurneyErrorCode.notFound);
  }

  @override
  Future<List<FeatureRequest>> searchSimilar(
    String query, {
    int limit = 5,
  }) async {
    if (onSearchSimilar != null) {
      return onSearchSimilar!(query, limit);
    }
    final folded = foldVietnameseDiacritics(query.trim());
    if (folded.length < 3) return const [];
    final tokens = folded
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toList();
    return [
      for (final item in items)
        if (item.duplicateOf == null &&
            !item.isDeclined &&
            (foldVietnameseDiacritics(item.title).contains(folded) ||
                (tokens.isNotEmpty &&
                    tokens.every(
                      (t) => foldVietnameseDiacritics(item.title).contains(t),
                    ))))
          item,
    ].take(limit).toList();
  }

  @override
  Future<FeatureRequest> create({
    required String id,
    required String title,
    required String body,
    FeatureRequestCategory category = FeatureRequestCategory.other,
  }) async {
    createdIds.add(id);
    if (createError != null) throw createError!;
    final now = DateTime.utc(2026, 11, 24, 7);
    final created = FeatureRequest(
      id: id,
      title: title,
      body: body,
      category: category,
      status: FeatureRequestStatus.newRequest,
      voteCount: 1,
      votedByMe: true,
      isMine: true,
      author: const PersonSummary(
        userId: 'u-me',
        username: 'minh_hoang',
        displayName: 'Minh Hoàng',
      ),
      createdAt: now,
      updatedAt: now,
    );
    items.insert(0, created);
    return created;
  }

  @override
  Future<FeatureRequest> update({
    required String id,
    required String title,
    required String body,
    required FeatureRequestCategory category,
  }) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx < 0) throw const OurneyException(OurneyErrorCode.notFound);
    final current = items[idx];
    if (!current.canAuthorModify) {
      throw const OurneyException(OurneyErrorCode.forbidden);
    }
    final updated = current.copyWith(
      title: title,
      body: body,
      category: category,
      updatedAt: current.createdAt.add(const Duration(minutes: 5)),
    );
    items[idx] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx < 0) throw const OurneyException(OurneyErrorCode.notFound);
    if (!items[idx].canAuthorModify) {
      throw const OurneyException(OurneyErrorCode.forbidden);
    }
    items.removeAt(idx);
  }

  @override
  Future<FeatureRequestVoteResult> toggleVote(
    String requestId, {
    bool? voted,
  }) async {
    voteCalls.add((requestId, voted));
    if (onToggleVote != null) {
      return onToggleVote!(requestId, voted);
    }
    if (voteGate != null) {
      return voteGate!.future;
    }
    if (voteError != null) throw voteError!;
    final idx = items.indexWhere((i) => i.id == requestId);
    if (idx < 0) throw const OurneyException(OurneyErrorCode.notFound);
    final item = items[idx];
    if (!item.canVote) throw const OurneyException(OurneyErrorCode.ended);
    final nextVoted = voted ?? !item.votedByMe;
    final delta = nextVoted == item.votedByMe ? 0 : (nextVoted ? 1 : -1);
    final nextCount = (item.voteCount + delta).clamp(0, 1 << 30);
    items[idx] = item.copyWith(votedByMe: nextVoted, voteCount: nextCount);
    return FeatureRequestVoteResult(
      requestId: requestId,
      voteCount: nextCount,
      votedByMe: nextVoted,
    );
  }

  @override
  Future<String> report({
    required String requestId,
    required ReportReason reason,
    String? note,
  }) async {
    reportCalls.add((requestId, reason, note));
    items.removeWhere((i) => i.id == requestId);
    return 'rep-1';
  }

  @override
  Future<List<ShippedRequestNotification>> myShippedNotifications({
    int limit = 20,
  }) async =>
      shippedNotifications.take(limit).toList();

  @override
  Future<int> markShippedSeen({List<String>? requestIds}) async {
    markedSeenCalls.add(requestIds);
    return requestIds?.length ?? shippedNotifications.length;
  }
}

class _FakeSafetyRepository implements SafetyRepository {
  final _blockedController = StreamController<Set<String>>.broadcast();
  Set<String> blocked = {};

  @override
  Future<void> block(String userId) async {
    blocked = {...blocked, userId};
    _blockedController.add(blocked);
  }

  @override
  Future<void> unblock(String userId) async {
    blocked = {...blocked}..remove(userId);
    _blockedController.add(blocked);
  }

  @override
  Future<List<PersonSummary>> myBlockedPeople() async => const [];

  @override
  Future<void> report({
    String? checkInId,
    String? userId,
    String? messageId,
    required ReportReason reason,
    String? note,
  }) async {}

  @override
  Stream<Set<String>> watchBlockedIds() async* {
    yield blocked;
    yield* _blockedController.stream;
  }
}

class _FakeRpcRemote extends Fake implements RemoteApi {
  _FakeRpcRemote(this._handler);

  final Future<Object?> Function(String fn, Map<String, dynamic> params)
      _handler;

  @override
  String? get currentUserId => 'u-me';

  @override
  Future<Object?> rpc(
    String fn, [
    Map<String, dynamic> params = const {},
  ]) =>
      _handler(fn, params);
}

class _FakeDataContext extends Fake implements DataContext {
  _FakeDataContext(this._remote);

  final RemoteApi _remote;

  @override
  RemoteApi requireRemote() => _remote;

  @override
  String requireUserId() => 'u-me';
}

Future<ProviderContainer> _pumpFeedbackRouter(
  WidgetTester tester, {
  required FakeFeatureRequestRepository repo,
  _FakeSafetyRepository? safety,
  FakeAuthRepository? authRepo,
  String initialLocation = AppRoutes.feedback,
  AppConfig config = testBackendConfig,
  Locale locale = const Locale('vi'),
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final prefs = await testPrefs({
    OnboardingComplete.prefsKey: true,
    SafetyPrefs.eulaAccepted: true,
  });
  final safetyRepo = safety ?? _FakeSafetyRepository();
  final auth = authRepo ?? FakeAuthRepository(userId: 'u-me');

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const Scaffold(body: Text('Profile Stub')),
      ),
      GoRoute(
        path: '/safety/contact',
        builder: (_, _) => const ContactScreen(),
      ),
      GoRoute(
        path: AppRoutes.feedback,
        builder: (_, _) => const FeatureRequestsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => FeatureRequestDetailScreen(
              requestId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      sharedPreferencesProvider.overrideWithValue(prefs),
      supabaseClientProvider.overrideWithValue(null),
      authRepositoryProvider.overrideWithValue(auth),
      featureRequestRepositoryProvider.overrideWithValue(repo),
      safetyRepositoryProvider.overrideWithValue(safetyRepo),
    ],
  );
  addTearDown(container.dispose);
  container.listen(accountSessionResetProvider, (_, _) {});

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildAppTheme(brightness),
        locale: locale,
        localizationsDelegates: ourneyLocalizationsDelegates,
        supportedLocales: ourneySupportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('Board screen (/feedback)', () {
    testWidgets('renders cards, switches tabs, filters by category & mine', (
      tester,
    ) async {
      final repo = FakeFeatureRequestRepository();
      await _pumpFeedbackRouter(tester, repo: repo);

      // Popular tab shows non-shipped items (req-1 and req-2).
      expect(find.byKey(const ValueKey('feedback-card-req-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('feedback-card-req-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('feedback-card-req-3')), findsNothing);
      expect(find.text('Phản hồi Ourney'), findsOneWidget);

      // Switch to Shipped tab -> shows req-3.
      final shippedTab = find.byKey(const ValueKey('feedback-tab-shipped'));
      await tester.ensureVisible(shippedTab);
      await tester.pumpAndSettle();
      await tester.tap(shippedTab);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('feedback-card-req-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('feedback-card-req-1')), findsNothing);

      // Toggle "Của tôi" chip -> shows only my requests (req-2).
      await tester.tap(find.byKey(const ValueKey('feedback-chip-mine')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('feedback-card-req-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('feedback-card-req-3')), findsNothing);
    });

    testWidgets(
      'search with no matches offers pre-filled Create Sheet CTA',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        await _pumpFeedbackRouter(tester, repo: repo);

        await tester.enterText(
          find.byKey(const ValueKey('feedback-search-input')),
          'Đồng bộ Apple Watch',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('feedback-empty-search')),
          findsOneWidget,
        );
        final cta = find.byKey(const ValueKey('feedback-empty-search-cta'));
        await tester.ensureVisible(cta);
        await tester.pumpAndSettle();
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('feedback-compose-sheet')),
          findsOneWidget,
        );
        final titleField = tester.widget<TextField>(
          find.byKey(const ValueKey('feedback-title-input')),
        );
        expect(titleField.controller?.text, 'Đồng bộ Apple Watch');
      },
    );

    testWidgets(
      'UX-31: empty board shows only the pinned bottom create CTA without duplicate buttons',
      (tester) async {
        final repo = FakeFeatureRequestRepository()..items.clear();
        await _pumpFeedbackRouter(tester, repo: repo);

        expect(
          find.byKey(const ValueKey('feedback-empty-popular')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('feedback-create-cta')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('feedback-add-icon')), findsNothing);
        expect(find.text('Gửi đề xuất mới'), findsOneWidget);
      },
    );

    testWidgets(
      'optimistic vote updates immediately, coalesces rapid taps, and rolls back on failure',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        final gate = Completer<FeatureRequestVoteResult>();
        repo.voteGate = gate;

        await _pumpFeedbackRouter(tester, repo: repo);

        // req-2 starts at 18 votes, unvoted.
        expect(find.text('18'), findsOneWidget);

        // Rapid triple-tap while the first RPC is in flight:
        // tap 1 -> 19 (voted: true)
        // tap 2 -> 18 (voted: false)
        // tap 3 -> 19 (voted: true)
        await tester.tap(find.byKey(const ValueKey('feedback-vote-req-2')));
        await tester.pump();
        expect(find.text('19'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('feedback-vote-req-2')));
        await tester.pump();
        expect(find.text('18'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('feedback-vote-req-2')));
        await tester.pump();
        expect(find.text('19'), findsOneWidget);

        // Only 1 RPC was started while gate was pending.
        expect(repo.voteCalls.length, 1);

        // Release gate -> coalesced follow-up call fires with latest desired state (true).
        repo.voteGate = null;
        gate.complete(
          const FeatureRequestVoteResult(
            requestId: 'req-2',
            voteCount: 19,
            votedByMe: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(repo.voteCalls.last, ('req-2', true));
        expect(find.text('19'), findsOneWidget);

        // Now simulate an offline failure -> optimistic state rolls back to 19!
        repo.voteError = const OurneyException(OurneyErrorCode.offline);
        await tester.tap(find.byKey(const ValueKey('feedback-vote-req-2')));
        await tester.pumpAndSettle();
        expect(find.text('19'), findsOneWidget);
      },
    );

    testWidgets(
      'P1-2 races: coalesced partial success rolls back to committed baseline, '
      'settled overlays do not clobber newer server counts, and sign-out drops stale in-flight votes',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        final auth = FakeAuthRepository(userId: 'u-me');
        final rpc1 = Completer<FeatureRequestVoteResult>();
        final rpc2 = Completer<FeatureRequestVoteResult>();
        var callIndex = 0;
        repo.onToggleVote = (requestId, voted) {
          callIndex++;
          if (callIndex == 1) return rpc1.future;
          return rpc2.future;
        };

        final container = await _pumpFeedbackRouter(
          tester,
          repo: repo,
          authRepo: auth,
        );

        // Race 1: req-2 starts at (votedByMe: false, voteCount: 18).
        // Tap 1 (voted: true -> 19) and Tap 2 (voted: false -> 18) while Tap 1 is in flight.
        await tester.tap(find.byKey(const ValueKey('feedback-vote-req-2')));
        await tester.pump();
        expect(find.text('19'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('feedback-vote-req-2')));
        await tester.pump();
        expect(find.text('18'), findsOneWidget);

        // Iteration 1 (voted: true) succeeds on the server with (true, 19).
        rpc1.complete(
          const FeatureRequestVoteResult(
            requestId: 'req-2',
            voteCount: 19,
            votedByMe: true,
          ),
        );
        await tester.pump();

        // Iteration 2 (voted: false) fails with rateLimited.
        rpc2.completeError(
          const OurneyException(OurneyErrorCode.rateLimited),
        );
        await tester.pumpAndSettle();

        // Must roll back to Iteration 1's committed (true, 19), NOT pre-tap (false, 18)!
        expect(find.text('19'), findsOneWidget);
        expect(
          container.read(feedbackVoteOverlayProvider)['req-2'],
          (votedByMe: true, voteCount: 19),
        );
        // Shows action rate-limit copy (P3-1), not creation 5/24h copy.
        expect(
          find.text(
            'Bạn đang thao tác quá nhanh. Vui lòng thử lại sau ít phút nhé.',
          ),
          findsOneWidget,
        );

        // Race 2: 10 other users upvote req-2 on the server (voteCount becomes 29).
        final idx2 = repo.items.indexWhere((i) => i.id == 'req-2');
        repo.items[idx2] = repo.items[idx2].copyWith(
          votedByMe: true,
          voteCount: 29,
        );
        container.invalidate(rawFeedbackBoardProvider);
        await tester.pumpAndSettle();

        // Settled overlay for req-2 is cleared on server refresh so 29 is shown!
        expect(find.text('29'), findsOneWidget);
        expect(
          container.read(feedbackVoteOverlayProvider).containsKey('req-2'),
          isFalse,
        );

        // Race 3: In-flight vote started before sign-out is dropped after sign-out.
        final staleGate = Completer<FeatureRequestVoteResult>();
        repo.onToggleVote = (_, _) => staleGate.future;
        await tester.tap(find.byKey(const ValueKey('feedback-vote-req-1')));
        await tester.pump();
        expect(
          container.read(feedbackVoteOverlayProvider)['req-1']?.voteCount,
          41,
        );

        // User signs out while the RPC is still in flight.
        await auth.signOut();
        await tester.pumpAndSettle();
        expect(container.read(feedbackVoteOverlayProvider), isEmpty);

        // Old user's delayed RPC now resolves — must be dropped without mutating state!
        staleGate.complete(
          const FeatureRequestVoteResult(
            requestId: 'req-1',
            voteCount: 41,
            votedByMe: false,
          ),
        );
        await tester.pumpAndSettle();
        expect(container.read(feedbackVoteOverlayProvider), isEmpty);
      },
    );

    testWidgets(
      'local-only mode shows NeedsServerView without crashing',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        await _pumpFeedbackRouter(
          tester,
          repo: repo,
          config: const AppConfig.localOnly(),
        );
        expect(find.byKey(const ValueKey('needs-server')), findsOneWidget);
      },
    );

    testWidgets(
      'serverOutdated (PGRST202) shows friendly coming-soon state without crashing',
      (tester) async {
        final repo = FakeFeatureRequestRepository()
          ..listError = const OurneyException(OurneyErrorCode.serverOutdated);
        await _pumpFeedbackRouter(tester, repo: repo);
        expect(
          find.byKey(const ValueKey('feedback-coming-soon')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows cached list with offline strip and respects active tab when offline (P2-1)',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        final container = await _pumpFeedbackRouter(tester, repo: repo);
        expect(
          find.byKey(const ValueKey('feedback-card-req-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('feedback-card-req-2')),
          findsOneWidget,
        );

        // Go offline and refresh.
        repo.listError = const OurneyException(OurneyErrorCode.offline);
        container.invalidate(rawFeedbackBoardProvider);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('feedback-offline-strip')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('feedback-card-req-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('feedback-card-req-2')),
          findsOneWidget,
        );

        // Switch to Planned tab offline -> only planned req-1 is shown (new req-2 is filtered out).
        final plannedTab = find.byKey(const ValueKey('feedback-tab-planned'));
        await tester.ensureVisible(plannedTab);
        await tester.pumpAndSettle();
        await tester.tap(plannedTab);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('feedback-offline-strip')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('feedback-card-req-1')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('feedback-card-req-2')), findsNothing);

        // Switch to Shipped tab offline -> unshipped req-1 & req-2 are not shown,
        // and the offline strip remains visible above the empty state.
        final shippedTab = find.byKey(const ValueKey('feedback-tab-shipped'));
        await tester.ensureVisible(shippedTab);
        await tester.pumpAndSettle();
        await tester.tap(shippedTab);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('feedback-offline-strip')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('feedback-empty-shipped')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('feedback-card-req-1')), findsNothing);
        expect(find.byKey(const ValueKey('feedback-card-req-2')), findsNothing);
      },
    );
  });

  group('Detail screen (/feedback/:id)', () {
    testWidgets(
      'renders official Ourney reply card and allows reporting & blocking non-author request',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        await _pumpFeedbackRouter(
          tester,
          repo: repo,
          initialLocation: AppRoutes.featureRequest('req-1'),
        );

        expect(
          find.byKey(const ValueKey('feedback-admin-reply')),
          findsOneWidget,
        );
        expect(find.text('PHẢN HỒI TỪ OURNEY'), findsOneWidget);
        expect(
          find.text(
            'Nhóm Ourney đang thiết kế widget cho bản cập nhật tiếp theo!',
          ),
          findsOneWidget,
        );

        // Open overflow menu for non-author request -> Report & Block are shown.
        await tester.tap(find.byKey(const ValueKey('feedback-detail-more')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('feedback-menu-report')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('feedback-menu-block')),
          findsOneWidget,
        );

        // Tap Report -> verify mutually-exclusive radio semantics (P2-2) -> select Spam -> submit.
        await tester.tap(find.byKey(const ValueKey('feedback-menu-report')));
        await tester.pumpAndSettle();
        final spamFinder = find.byKey(
          const ValueKey('feedback-report-reason-spam'),
        );
        final nudityFinder = find.byKey(
          const ValueKey('feedback-report-reason-nudity'),
        );
        expect(
          tester.getSemantics(spamFinder),
          matchesSemantics(
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            hasSelectedState: true,
            isSelected: false,
            isInMutuallyExclusiveGroup: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );
        await tester.tap(spamFinder);
        await tester.pump();
        expect(
          tester.getSemantics(spamFinder),
          matchesSemantics(
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            hasSelectedState: true,
            isSelected: true,
            isInMutuallyExclusiveGroup: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );
        expect(
          tester.getSemantics(nudityFinder),
          matchesSemantics(
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            hasSelectedState: true,
            isSelected: false,
            isInMutuallyExclusiveGroup: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );
        final reportSubmit = find.byKey(
          const ValueKey('feedback-report-submit'),
        );
        await tester.ensureVisible(reportSubmit);
        await tester.pumpAndSettle();
        await tester.tap(reportSubmit);
        await tester.pumpAndSettle();

        expect(repo.reportCalls.single.$1, 'req-1');
        expect(repo.reportCalls.single.$2, ReportReason.spam);
        expect(find.byKey(const ValueKey('feedback-screen')), findsOneWidget);
        expect(find.byKey(const ValueKey('feedback-card-req-1')), findsNothing);
      },
    );

    testWidgets(
      'author can edit and delete own new request',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        await _pumpFeedbackRouter(
          tester,
          repo: repo,
          initialLocation: AppRoutes.featureRequest('req-2'),
        );

        expect(
          find.byKey(const ValueKey('feedback-author-edit-hint')),
          findsOneWidget,
        );

        // Edit title via overflow menu.
        await tester.tap(find.byKey(const ValueKey('feedback-detail-more')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('feedback-menu-edit')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('feedback-title-input')),
          'Xuất video timelapse 4K từ toàn bộ hành trình',
        );
        final submitBtn = find.byKey(const ValueKey('feedback-compose-submit'));
        await tester.ensureVisible(submitBtn);
        await tester.pumpAndSettle();
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Xuất video timelapse 4K từ toàn bộ hành trình'),
          findsOneWidget,
        );

        // Delete via overflow menu.
        await tester.tap(find.byKey(const ValueKey('feedback-detail-more')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('feedback-menu-delete')));
        await tester.pumpAndSettle();
        final confirmDeleteBtn = find.byKey(
          const ValueKey('feedback-delete-confirm-btn'),
        );
        await tester.ensureVisible(confirmDeleteBtn);
        await tester.pumpAndSettle();
        await tester.tap(confirmDeleteBtn);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('feedback-screen')), findsOneWidget);
        expect(find.byKey(const ValueKey('feedback-card-req-2')), findsNothing);
      },
    );
  });

  group('Create sheet, duplicate deflection & validation', () {
    testWidgets(
      'shows live duplicate suggestions and deflects into existing request on +1 tap',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        await _pumpFeedbackRouter(tester, repo: repo);

        await tester.tap(find.byKey(const ValueKey('feedback-create-cta')));
        await tester.pumpAndSettle();

        // Type "man hinh khoa" (diacritic-insensitive match against req-1).
        await tester.enterText(
          find.byKey(const ValueKey('feedback-title-input')),
          'man hinh khoa',
        );
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('feedback-similar-card')),
          findsOneWidget,
        );
        final similarVoteChip = find.byKey(
          const ValueKey('feedback-similar-vote-req-1'),
        );
        await tester.ensureVisible(similarVoteChip);
        await tester.pumpAndSettle();
        await tester.tap(similarVoteChip);
        await tester.pumpAndSettle();

        // Navigates straight to req-1 detail screen!
        expect(
          find.byKey(const ValueKey('feedback-detail-screen')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'validates links, maps contentPolicy error, and saves draft when offline',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        final container = await _pumpFeedbackRouter(tester, repo: repo);

        await tester.tap(find.byKey(const ValueKey('feedback-create-cta')));
        await tester.pumpAndSettle();

        // 1. Disallowed URL in title.
        await tester.enterText(
          find.byKey(const ValueKey('feedback-title-input')),
          'Xem https://spam.example.com ngay',
        );
        await tester.enterText(
          find.byKey(const ValueKey('feedback-body-input')),
          'Mô tả hợp lệ dài hơn mười ký tự cho đề xuất này.',
        );
        final submitBtn = find.byKey(const ValueKey('feedback-compose-submit'));
        await tester.ensureVisible(submitBtn);
        await tester.pumpAndSettle();
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Vui lòng không chèn đường dẫn web vào đề xuất.'),
          findsOneWidget,
        );

        // 2. Server contentPolicy error.
        repo.createError = const OurneyException(OurneyErrorCode.contentPolicy);
        await tester.enterText(
          find.byKey(const ValueKey('feedback-title-input')),
          'Chế độ tập trung khi học nhóm',
        );
        await tester.ensureVisible(submitBtn);
        await tester.pumpAndSettle();
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Nội dung chứa từ ngữ không phù hợp với quy tắc cộng đồng của Ourney.',
          ),
          findsOneWidget,
        );

        // 3. Offline error saves draft and keeps sheet open.
        repo.createError = const OurneyException(OurneyErrorCode.offline);
        await tester.ensureVisible(submitBtn);
        await tester.pumpAndSettle();
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Không có mạng. Bản nháp của bạn vẫn được giữ nguyên.'),
          findsOneWidget,
        );
        expect(
          container.read(feedbackDraftProvider)?.title,
          'Chế độ tập trung khi học nhóm',
        );
      },
    );
  });

  group('Entry points & DataFeatureRequestRepository RPC contract', () {
    testWidgets(
      'SettingsScreen and ContactScreen expose feature request entry points when signed in',
      (tester) async {
        final repo = FakeFeatureRequestRepository(
          shippedNotifications: [
            ShippedRequestNotification(
              requestId: 'req-3',
              title: 'Chế độ hẹn giờ chụp 3 giây và 10 giây',
              category: FeatureRequestCategory.camera,
              adminReply: 'Đã ra mắt trên màn hình Máy ảnh!',
              isAuthor: false,
              shippedAt: DateTime.now().toUtc(),
              createdAt: DateTime.now().toUtc(),
              seen: false,
            ),
          ],
        );
        final prefs = await testPrefs({
          OnboardingComplete.prefsKey: true,
          SafetyPrefs.eulaAccepted: true,
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              supabaseClientProvider.overrideWithValue(null),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: 'u-me'),
              ),
              featureRequestRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              theme: buildAppTheme(Brightness.light),
              locale: const Locale('vi'),
              localizationsDelegates: ourneyLocalizationsDelegates,
              supportedLocales: ourneySupportedLocales,
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('settings-feature-requests')),
          findsOneWidget,
        );

        // ContactScreen when signed in shows safety-contact-feature-requests.
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              supabaseClientProvider.overrideWithValue(null),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: 'u-me'),
              ),
              featureRequestRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              theme: buildAppTheme(Brightness.light),
              locale: const Locale('vi'),
              localizationsDelegates: ourneyLocalizationsDelegates,
              supportedLocales: ourneySupportedLocales,
              home: const ContactScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('safety-contact-feature-requests')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'InboxScreen renders shipped request notifications and marks unseen items seen',
      (tester) async {
        final repo = FakeFeatureRequestRepository(
          shippedNotifications: [
            ShippedRequestNotification(
              requestId: 'req-3',
              title: 'Chế độ hẹn giờ chụp 3 giây và 10 giây',
              category: FeatureRequestCategory.camera,
              adminReply: 'Đã ra mắt trên màn hình Máy ảnh!',
              isAuthor: false,
              shippedAt: DateTime.now().toUtc(),
              createdAt: DateTime.now().toUtc(),
              seen: false,
            ),
          ],
        );
        final prefs = await testPrefs({
          OnboardingComplete.prefsKey: true,
          SafetyPrefs.eulaAccepted: true,
        });
        final safetyRepo = _FakeSafetyRepository();

        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const InboxScreen()),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(testBackendConfig),
              sharedPreferencesProvider.overrideWithValue(prefs),
              supabaseClientProvider.overrideWithValue(null),
              authRepositoryProvider.overrideWithValue(
                FakeAuthRepository(userId: 'u-me'),
              ),
              safetyRepositoryProvider.overrideWithValue(safetyRepo),
              featureRequestRepositoryProvider.overrideWithValue(repo),
              friendshipsProvider.overrideWith(
                (ref) => Stream.value(const <Friendship>[]),
              ),
              pendingConsentsProvider.overrideWith(
                (ref) => Stream.value(const <ShareConsent>[]),
              ),
              conversationsProvider.overrideWith(
                (ref) => Stream.value(const <Conversation>[]),
              ),
              rawInboxCountsProvider.overrideWith(
                (ref) => Stream.value(
                  const InboxCounts(
                    friendRequests: 0,
                    publicRequests: 0,
                    newShares: 0,
                    unreadMessages: 0,
                    consentRequests: 0,
                    shippedRequests: 1,
                  ),
                ),
              ),
            ],
            child: MaterialApp.router(
              theme: buildAppTheme(Brightness.light),
              locale: const Locale('vi'),
              localizationsDelegates: ourneyLocalizationsDelegates,
              supportedLocales: ourneySupportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('inbox-shipped-request-req-3')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Tính năng bạn bình chọn đã ra mắt: Chế độ hẹn giờ chụp 3 giây và 10 giây',
          ),
          findsOneWidget,
        );
        expect(repo.markedSeenCalls, [
          ['req-3'],
        ]);
      },
    );

    test(
      'DataFeatureRequestRepository calls exact 0024 RPC names and parameters',
      () async {
        final calls = <(String, Map<String, dynamic>)>[];
        final remote = _FakeRpcRemote((fn, params) async {
          calls.add((fn, params));
          return switch (fn) {
            'list_feature_requests' || 'search_similar_feature_requests' => [
                {
                  'id': 'req-1',
                  'title': 'Widget màn hình khóa',
                  'body': 'Xem nhanh chuỗi ngày ngoài màn hình khóa.',
                  'category': 'design',
                  'status': 'planned',
                  'vote_count': 10,
                  'voted_by_me': true,
                  'is_mine': false,
                  'created_at': '2026-11-24T00:00:00Z',
                  'updated_at': '2026-11-24T00:00:00Z',
                },
              ],
            'get_feature_request' ||
            'create_feature_request' ||
            'update_feature_request' =>
              {
                'id': 'req-1',
                'title': 'Widget màn hình khóa',
                'body': 'Xem nhanh chuỗi ngày ngoài màn hình khóa.',
                'category': 'design',
                'status': 'new',
                'vote_count': 1,
                'voted_by_me': true,
                'is_mine': true,
                'created_at': '2026-11-24T00:00:00Z',
                'updated_at': '2026-11-24T00:00:00Z',
              },
            'delete_feature_request' => null,
            'toggle_feature_request_vote' => {
                'request_id': 'req-1',
                'vote_count': 11,
                'voted_by_me': true,
              },
            'report_feature_request' => 'rep-123',
            'my_shipped_request_notifications' => [
                {
                  'request_id': 'req-1',
                  'title': 'Widget màn hình khóa',
                  'category': 'design',
                  'admin_reply': 'Đã ra mắt!',
                  'is_author': true,
                  'shipped_at': '2026-11-24T01:00:00Z',
                  'created_at': '2026-11-24T01:00:00Z',
                  'seen': false,
                },
              ],
            'mark_shipped_requests_seen' => 1,
            _ => throw UnimplementedError(fn),
          };
        });
        final social = SocialContext(
          _FakeDataContext(remote),
          pollInterval: null,
        );
        addTearDown(social.dispose);
        final repo = DataFeatureRequestRepository(social);

        final list = await repo.list(
          tab: FeatureRequestTab.planned,
          category: FeatureRequestCategory.design,
          search: 'widget',
          mineOnly: false,
          limit: 30,
          offset: 0,
        );
        expect(list.single.id, 'req-1');
        expect(calls.last.$1, 'list_feature_requests');
        expect(calls.last.$2, {
          'p_tab': 'planned',
          'p_category': 'design',
          'p_search': 'widget',
          'p_mine_only': false,
          'p_limit': 30,
          'p_offset': 0,
        });

        await repo.getById('req-1');
        expect(calls.last.$1, 'get_feature_request');
        expect(calls.last.$2, {'p_id': 'req-1'});

        await repo.searchSimilar('wid', limit: 3);
        expect(calls.last.$1, 'search_similar_feature_requests');
        expect(calls.last.$2, {'p_query': 'wid', 'p_limit': 3});

        await repo.create(
          id: 'req-1',
          title: 'Widget màn hình khóa',
          body: 'Xem nhanh chuỗi ngày ngoài màn hình khóa.',
          category: FeatureRequestCategory.design,
        );
        expect(calls.last.$1, 'create_feature_request');
        expect(calls.last.$2['p_category'], 'design');

        await repo.update(
          id: 'req-1',
          title: 'Widget màn hình khóa 2',
          body: 'Xem nhanh chuỗi ngày ngoài màn hình khóa.',
          category: FeatureRequestCategory.design,
        );
        expect(calls.last.$1, 'update_feature_request');

        await repo.delete('req-1');
        expect(calls.last.$1, 'delete_feature_request');
        expect(calls.last.$2, {'p_id': 'req-1'});

        final vote = await repo.toggleVote('req-1', voted: true);
        expect(vote.voteCount, 11);
        expect(calls.last.$1, 'toggle_feature_request_vote');
        expect(calls.last.$2, {'p_request_id': 'req-1', 'p_voted': true});

        final repId = await repo.report(
          requestId: 'req-1',
          reason: ReportReason.spam,
          note: 'Spam link',
        );
        expect(repId, 'rep-123');
        expect(calls.last.$1, 'report_feature_request');
        expect(calls.last.$2, {
          'p_request_id': 'req-1',
          'p_reason': 'spam',
          'p_note': 'Spam link',
        });

        final shipped = await repo.myShippedNotifications(limit: 10);
        expect(shipped.single.isAuthor, isTrue);
        expect(calls.last.$1, 'my_shipped_request_notifications');
        expect(calls.last.$2, {'p_limit': 10});

        final marked = await repo.markShippedSeen(requestIds: ['req-1']);
        expect(marked, 1);
        expect(calls.last.$1, 'mark_shipped_requests_seen');
        expect(calls.last.$2, {
          'p_request_ids': ['req-1'],
        });
      },
    );

    testWidgets(
      'renders cleanly at 320dp width in light and dark mode up to 2.0x text scale (P2-2)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = FakeFeatureRequestRepository();
        await _pumpFeedbackRouter(
          tester,
          repo: repo,
          brightness: Brightness.dark,
          locale: const Locale('en'),
          textScaler: const TextScaler.linear(2.0),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('feedback-card-req-1')),
          findsOneWidget,
        );

        // Open Create sheet at 320dp @ 2.0x text scale.
        await tester.tap(find.byKey(const ValueKey('feedback-create-cta')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('feedback-compose-sheet')),
          findsOneWidget,
        );
        final cancelBtn = find.byKey(
          const ValueKey('feedback-compose-cancel'),
        );
        await tester.ensureVisible(cancelBtn);
        await tester.pumpAndSettle();
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Open Detail screen at 320dp @ 2.0x text scale.
        final card1 = find.byKey(const ValueKey('feedback-card-req-1'));
        await tester.ensureVisible(card1);
        await tester.pumpAndSettle();
        await tester.tap(card1);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('feedback-detail-screen')),
          findsOneWidget,
        );
      },
    );
  });

  group('Cubic review regression tests', () {
    testWidgets(
      'create sheet clears duplicate suggestions on title change and drops stale search responses (#2)',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        await _pumpFeedbackRouter(tester, repo: repo);

        await tester.tap(find.byKey(const ValueKey('feedback-create-cta')));
        await tester.pumpAndSettle();

        // Initial search populates duplicate suggestion card.
        await tester.enterText(
          find.byKey(const ValueKey('feedback-title-input')),
          'man hinh khoa',
        );
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('feedback-similar-card')),
          findsOneWidget,
        );

        // Gate subsequent search calls so we can resolve them out of order.
        final staleCompleter = Completer<List<FeatureRequest>>();
        final currentCompleter = Completer<List<FeatureRequest>>();
        repo.onSearchSimilar = (query, _) {
          if (query == 'man hinh') return staleCompleter.future;
          return currentCompleter.future;
        };

        // Changing title clears old suggestions immediately before debounce/network completes.
        await tester.enterText(
          find.byKey(const ValueKey('feedback-title-input')),
          'man hinh',
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('feedback-similar-card')),
          findsNothing,
        );
        // Fire the debounce for 'man hinh' so staleCompleter is in flight.
        await tester.pump(const Duration(milliseconds: 350));

        // Now change title to 'timelapse' and fire its debounce.
        await tester.enterText(
          find.byKey(const ValueKey('feedback-title-input')),
          'timelapse',
        );
        await tester.pump(const Duration(milliseconds: 350));

        // Stale response for 'man hinh' arrives late — must be ignored!
        staleCompleter.complete([repo.items[0]]);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('feedback-similar-card')),
          findsNothing,
        );

        // Response for current query 'timelapse' arrives — applied!
        currentCompleter.complete([repo.items[1]]);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('feedback-similar-card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('feedback-similar-vote-req-2')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'create sheet persists draft request id and reuses it on reopen after failure (#3)',
      (tester) async {
        final repo = FakeFeatureRequestRepository()
          ..createError = const OurneyException(OurneyErrorCode.offline);
        final container = await _pumpFeedbackRouter(tester, repo: repo);

        await tester.tap(find.byKey(const ValueKey('feedback-create-cta')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('feedback-title-input')),
          'Đồng bộ lịch tập sang lịch cá nhân',
        );
        await tester.enterText(
          find.byKey(const ValueKey('feedback-body-input')),
          'Tự động hiển thị các ngày đã check-in trên lịch của điện thoại.',
        );
        final submitBtn = find.byKey(const ValueKey('feedback-compose-submit'));
        await tester.ensureVisible(submitBtn);
        await tester.pumpAndSettle();
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(repo.createdIds, hasLength(1));
        final firstId = repo.createdIds.single;
        expect(container.read(feedbackDraftProvider)?.id, firstId);

        // Close sheet, go back online, reopen sheet, and retry submit.
        final cancelBtn = find.byKey(const ValueKey('feedback-compose-cancel'));
        await tester.ensureVisible(cancelBtn);
        await tester.pumpAndSettle();
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        repo.createError = null;
        await tester.tap(find.byKey(const ValueKey('feedback-create-cta')));
        await tester.pumpAndSettle();

        final retrySubmit = find.byKey(
          const ValueKey('feedback-compose-submit'),
        );
        await tester.ensureVisible(retrySubmit);
        await tester.pumpAndSettle();
        await tester.tap(retrySubmit);
        await tester.pumpAndSettle();

        expect(repo.createdIds, [firstId, firstId]);
        expect(container.read(feedbackDraftProvider), isNull);
      },
    );

    testWidgets(
      'board shows load-more when first page is fully filtered but hasMore is true (#4) and separates card & vote semantics (#6)',
      (tester) async {
        final page1 = [
          for (var i = 0; i < featureRequestPageSize; i++)
            FeatureRequest(
              id: 'req-p1-$i',
              title: 'Ý tưởng trang đầu $i',
              body: 'Mô tả chi tiết cho ý tưởng trang đầu số $i.',
              category: FeatureRequestCategory.other,
              status: FeatureRequestStatus.newRequest,
              voteCount: 5,
              votedByMe: false,
              isMine: false,
              author: const PersonSummary(
                userId: 'u-blocked',
                username: 'blocked_user',
                displayName: 'Blocked User',
              ),
              createdAt: DateTime.utc(2026, 11, 20),
              updatedAt: DateTime.utc(2026, 11, 20),
            ),
        ];
        final page2Item = FeatureRequest(
          id: 'req-p2-0',
          title: 'Ý tưởng trang hai hợp lệ',
          body: 'Mô tả chi tiết cho ý tưởng ở trang thứ hai.',
          category: FeatureRequestCategory.design,
          status: FeatureRequestStatus.planned,
          voteCount: 15,
          votedByMe: false,
          isMine: false,
          createdAt: DateTime.utc(2026, 11, 21),
          updatedAt: DateTime.utc(2026, 11, 21),
        );
        final repo = FakeFeatureRequestRepository(
          initial: [...page1, page2Item],
        );
        final safety = _FakeSafetyRepository();
        await _pumpFeedbackRouter(tester, repo: repo, safety: safety);

        // Verify #6: card and vote button have separate button semantics.
        final cardFinder = find.byKey(const ValueKey('feedback-card-req-p1-0'));
        final voteFinder = find.byKey(const ValueKey('feedback-vote-req-p1-0'));
        final cardSemantics = tester.getSemantics(cardFinder);
        final voteSemantics = tester.getSemantics(voteFinder);
        expect(cardSemantics, isNot(same(voteSemantics)));
        expect(
          cardSemantics,
          matchesSemantics(
            label:
                'Ý tưởng trang đầu 0\nMô tả chi tiết cho ý tưởng trang đầu số 0.\nKhác',
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );
        expect(
          voteSemantics,
          matchesSemantics(
            label: 'Ý tưởng trang đầu 0, 5 lượt bình chọn, chưa bình chọn',
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: true,
          ),
        );

        // Verify #4: block the author of all 30 items on page 1 -> items is empty, hasMore is true.
        await safety.block('u-blocked');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('feedback-empty-popular')),
          findsNothing,
        );
        final loadMoreBtn = find.byKey(const ValueKey('feedback-load-more'));
        expect(loadMoreBtn, findsOneWidget);

        await tester.tap(loadMoreBtn);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('feedback-card-req-p2-0')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'inbox marks shipped notifications seen when provider resolves after initial _autoRead without duplicate calls (#7)',
      (tester) async {
        final shippedCompleter =
            Completer<List<ShippedRequestNotification>>();
        final repo = FakeFeatureRequestRepository();
        final prefs = await testPrefs({
          OnboardingComplete.prefsKey: true,
          SafetyPrefs.eulaAccepted: true,
        });
        final safetyRepo = _FakeSafetyRepository();

        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const InboxScreen()),
          ],
        );
        addTearDown(router.dispose);

        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(testBackendConfig),
            sharedPreferencesProvider.overrideWithValue(prefs),
            supabaseClientProvider.overrideWithValue(null),
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(userId: 'u-me'),
            ),
            safetyRepositoryProvider.overrideWithValue(safetyRepo),
            featureRequestRepositoryProvider.overrideWithValue(repo),
            shippedRequestNotificationsProvider.overrideWith(
              (ref) => shippedCompleter.future,
            ),
            friendshipsProvider.overrideWith(
              (ref) => Stream.value([
                Friendship(
                  person: const PersonSummary(
                    userId: 'u-khoa',
                    username: 'khoa',
                    displayName: 'Khoa Le',
                  ),
                  status: FriendStatus.pending,
                  direction: FriendDirection.incoming,
                  source: FriendSource.direct,
                  createdAt: DateTime.now().toUtc(),
                ),
              ]),
            ),
            pendingConsentsProvider.overrideWith(
              (ref) => Stream.value(const <ShareConsent>[]),
            ),
            conversationsProvider.overrideWith(
              (ref) => Stream.value(const <Conversation>[]),
            ),
            rawInboxCountsProvider.overrideWith(
              (ref) => Stream.value(
                const InboxCounts(
                  friendRequests: 1,
                  publicRequests: 0,
                  newShares: 0,
                  unreadMessages: 0,
                  consentRequests: 0,
                  shippedRequests: 1,
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: buildAppTheme(Brightness.light),
              locale: const Locale('vi'),
              localizationsDelegates: ourneyLocalizationsDelegates,
              supportedLocales: ourneySupportedLocales,
              routerConfig: router,
            ),
          ),
        );
        // Pump initial frames so friendshipsProvider resolves and _autoRead becomes true.
        await tester.pump();
        await tester.pump();
        expect(
          find.byKey(const ValueKey('inbox-request-u-khoa')),
          findsOneWidget,
        );
        expect(repo.markedSeenCalls, isEmpty);

        // Now shippedRequestNotificationsProvider resolves after _autoRead is already true.
        shippedCompleter.complete([
          ShippedRequestNotification(
            requestId: 'req-3',
            title: 'Chế độ hẹn giờ chụp 3 giây và 10 giây',
            category: FeatureRequestCategory.camera,
            adminReply: 'Đã ra mắt trên màn hình Máy ảnh!',
            isAuthor: false,
            shippedAt: DateTime.now().toUtc(),
            createdAt: DateTime.now().toUtc(),
            seen: false,
          ),
        ]);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('inbox-shipped-request-req-3')),
          findsOneWidget,
        );
        expect(repo.markedSeenCalls, [
          ['req-3'],
        ]);
        // Unread dot on the shipped card is cleared after post-frame markSeen.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('inbox-shipped-request-req-3')),
            matching: find.byKey(const ValueKey('unread-dot')),
          ),
          findsNothing,
        );

        // Tapping filter tabs triggers rebuilds but must NOT re-send markShippedSeen for 'req-3'.
        await tester.tap(find.byKey(const ValueKey('inbox-filter-invites')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('inbox-filter-all')));
        await tester.pumpAndSettle();
        expect(repo.markedSeenCalls, [
          ['req-3'],
        ]);
      },
    );

    testWidgets(
      'offline detail fallback skips cached request if id is in hiddenFeatureRequestIdsProvider (#8)',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        final container = await _pumpFeedbackRouter(tester, repo: repo);

        // Cache is populated with req-1 and req-2 from initial board load.
        expect(
          container
              .read(feedbackCacheStoreProvider)
              .read(mineOnly: false)
              ?.map((i) => i.id),
          containsAll(['req-1', 'req-2']),
        );

        // Hide req-1 locally (as after reporting or deleting) and go offline.
        container.read(hiddenFeatureRequestIdsProvider.notifier).hide('req-1');
        repo.detailError = const OurneyException(OurneyErrorCode.offline);
        repo.listError = const OurneyException(OurneyErrorCode.offline);

        // Unhidden req-2 still resolves from offline cache.
        final cachedReq2 = await container.read(
          rawFeatureRequestDetailProvider('req-2').future,
        );
        expect(cachedReq2.id, 'req-2');

        // Hidden req-1 skips the cache hit and fails instead of returning cached content.
        await expectLater(
          container.read(rawFeatureRequestDetailProvider('req-1').future),
          throwsA(isA<OurneyException>()),
        );
        expect(
          container.read(featureRequestDetailProvider('req-1')).hasError,
          isTrue,
        );
      },
    );

    testWidgets(
      'prependCreated inserts only when matching current FeedbackBoardQuery, else refreshes (#9)',
      (tester) async {
        final repo = FakeFeatureRequestRepository();
        final container = await _pumpFeedbackRouter(tester, repo: repo);

        // Switch to Planned tab.
        container
            .read(feedbackQueryProvider.notifier)
            .setTab(FeatureRequestTab.planned);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('feedback-card-req-1')),
          findsOneWidget,
        );
        final listCallsBefore = repo.listCalls.length;

        final created = FeatureRequest(
          id: 'req-new-1',
          title: 'Ý tưởng mới vừa tạo',
          body: 'Ý tưởng này có trạng thái new nên không thuộc tab Planned.',
          category: FeatureRequestCategory.design,
          status: FeatureRequestStatus.newRequest,
          voteCount: 1,
          votedByMe: true,
          isMine: true,
          createdAt: DateTime.utc(2026, 11, 24, 9),
          updatedAt: DateTime.utc(2026, 11, 24, 9),
        );

        // Call prependCreated while on Planned tab -> must NOT insert into Planned list; refreshes instead.
        container
            .read(rawFeedbackBoardProvider.notifier)
            .prependCreated(created);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('feedback-card-req-new-1')),
          findsNothing,
        );
        expect(repo.listCalls.length, greaterThan(listCallsBefore));

        // Now switch to Popular tab where 'new' requests match -> prependCreated inserts directly.
        container
            .read(feedbackQueryProvider.notifier)
            .setTab(FeatureRequestTab.popular);
        await tester.pumpAndSettle();
        final popularCallsBefore = repo.listCalls.length;

        container
            .read(rawFeedbackBoardProvider.notifier)
            .prependCreated(created);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('feedback-card-req-new-1')),
          findsOneWidget,
        );
        expect(repo.listCalls.length, popularCallsBefore);
      },
    );

    testWidgets(
      'loadMore drops stale page results when FeedbackBoardQuery changes during await (#10)',
      (tester) async {
        final page1 = [
          for (var i = 0; i < featureRequestPageSize; i++)
            FeatureRequest(
              id: 'req-pop-$i',
              title: 'Ý tưởng phổ biến $i',
              body: 'Mô tả chi tiết cho ý tưởng phổ biến số $i.',
              category: FeatureRequestCategory.design,
              status: FeatureRequestStatus.newRequest,
              voteCount: 50 - i,
              votedByMe: false,
              isMine: false,
              createdAt: DateTime.utc(2026, 11, 20),
              updatedAt: DateTime.utc(2026, 11, 20),
            ),
        ];
        final shippedItem = FeatureRequest(
          id: 'req-shipped-1',
          title: 'Tính năng đã ra mắt',
          body: 'Mô tả tính năng đã ra mắt trên bảng đề xuất.',
          category: FeatureRequestCategory.camera,
          status: FeatureRequestStatus.shipped,
          voteCount: 80,
          votedByMe: true,
          isMine: false,
          shippedAt: DateTime.utc(2026, 11, 23),
          createdAt: DateTime.utc(2026, 11, 10),
          updatedAt: DateTime.utc(2026, 11, 23),
        );
        final stalePage2Item = FeatureRequest(
          id: 'req-pop-stale-page2',
          title: 'Ý tưởng trang 2 cũ',
          body: 'Không được nối vào tab Shipped khi người dùng đã chuyển tab.',
          category: FeatureRequestCategory.design,
          status: FeatureRequestStatus.newRequest,
          voteCount: 1,
          votedByMe: false,
          isMine: false,
          createdAt: DateTime.utc(2026, 11, 19),
          updatedAt: DateTime.utc(2026, 11, 19),
        );

        final repo = FakeFeatureRequestRepository(
          initial: [...page1, shippedItem],
        );
        final page2Completer = Completer<List<FeatureRequest>>();
        repo.onList = (tab, category, search, mineOnly, limit, offset) async {
          if (tab == FeatureRequestTab.popular && offset > 0) {
            return page2Completer.future;
          }
          if (tab == FeatureRequestTab.shipped) {
            return [shippedItem];
          }
          return page1;
        };

        final container = await _pumpFeedbackRouter(tester, repo: repo);
        expect(
          container.read(feedbackBoardProvider).asData?.value.hasMore,
          isTrue,
        );

        // Start loading page 2 of Popular tab.
        unawaited(container.read(rawFeedbackBoardProvider.notifier).loadMore());
        await tester.pump();

        // Change query to Shipped tab while Popular page 2 is still awaiting.
        container
            .read(feedbackQueryProvider.notifier)
            .setTab(FeatureRequestTab.shipped);
        await tester.pumpAndSettle();
        expect(
          container
              .read(feedbackBoardProvider)
              .asData
              ?.value
              .items
              .map((i) => i.id),
          ['req-shipped-1'],
        );

        // Now complete the stale Popular page 2 request — must be dropped!
        page2Completer.complete([stalePage2Item]);
        await tester.pumpAndSettle();

        expect(
          container
              .read(feedbackBoardProvider)
              .asData
              ?.value
              .items
              .map((i) => i.id),
          ['req-shipped-1'],
        );
      },
    );
  });
}
