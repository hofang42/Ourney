import 'package:drift/drift.dart';
import 'package:ourney_core/ourney_core.dart';

import '../db/app_database.dart';
import '../mapping.dart';
import '../social_context.dart';
import '../social_mapping.dart';

/// The reaction a viewer's "like" writes (S13, S23).
const String likeEmoji = '❤️';

/// [SharingRepository] over the v1.3 RPCs (docs/contracts/sharing.md).
class DataSharingRepository implements SharingRepository {
  DataSharingRepository(this.social);

  final SocialContext social;

  AppDatabase get _db => social.data.db;

  void refresh() => social.changed();

  /// Sends queued writes first so RPCs never race a pending `create_journey`
  /// or check-in upload.
  Future<void> _flushFirst() async {
    final outbox = social.data.outbox;
    if (outbox != null) await outbox.flush(force: true);
  }

  @override
  Stream<JourneyShareState> watchShareState(String journeyId) => social.watch(
    () => social.call('journey_share_state', {
      'p_journey': journeyId,
    }, shareStateFromJson),
  );

  @override
  Future<void> shareWithFriends(
    String journeyId,
    List<String> friendIds,
  ) async {
    if (friendIds.isEmpty) return;
    await _flushFirst();
    await social.mutate('share_journey', {
      'p_journey': journeyId,
      'p_viewers': friendIds.toSet().toList(),
    });
  }

  @override
  Future<void> unshare(
    String journeyId, {
    String? friendId,
    bool all = false,
  }) async {
    await social.mutate('unshare_journey', {
      'p_journey': journeyId,
      'p_viewer': friendId,
      'p_all': all,
    });
    if (all) await _cachePublicToken(journeyId, null);
  }

  @override
  Future<void> updateStory(String journeyId, JourneyStory story) async {
    await _flushFirst();
    await social.mutate('update_journey_story', {
      'p_journey': journeyId,
      'p_title': story.title?.trim() ?? '',
      'p_intro': story.intro?.trim() ?? '',
      'p_lessons': story.lessons?.trim() ?? '',
      'p_cover': story.coverCheckInId,
    });
  }

  @override
  Future<void> updatePublicSettings(
    String journeyId,
    PublicSettings settings,
  ) => social.mutate('update_public_settings', {
    'p_journey': journeyId,
    'p_show_counts': settings.showCounts,
    'p_allow_reactions': settings.allowPublicReactions,
    'p_allow_requests': settings.allowViewerRequests,
  });

  @override
  Future<void> setHiddenInShare(
    String checkInId, {
    required bool hidden,
  }) async {
    await _flushFirst();
    await social.mutate('set_hidden_in_share', {
      'p_checkin': checkInId,
      'p_hidden': hidden,
    });
  }

  @override
  Future<String?> setPublicLink(
    String journeyId, {
    required bool enabled,
    bool reset = false,
  }) async {
    await _flushFirst();
    final token = await social.call('set_public_link', {
      'journey': journeyId,
      'enabled': enabled,
      'reset': reset,
    }, (json) => json is String ? json : null);
    await _cachePublicToken(journeyId, token);
    social.changed();
    return token;
  }

  /// Mirrors the link into the cached journey (Hub / share card). Solo
  /// visibility follows the link; a group stays `group` (sharing.md).
  Future<void> _cachePublicToken(String journeyId, String? token) async {
    final row = await (_db.select(
      _db.journeys,
    )..where((t) => t.id.equals(journeyId))).getSingleOrNull();
    if (row == null) return;
    final solo = row.kind == JourneyKind.solo.wireName;
    await (_db.update(
      _db.journeys,
    )..where((t) => t.id.equals(journeyId))).write(
      JourneysCompanion(
        publicToken: Value(token),
        visibility: solo
            ? Value(
                (token == null
                        ? JourneyVisibility.private
                        : JourneyVisibility.link)
                    .wireName,
              )
            : const Value.absent(),
      ),
    );
  }

  @override
  Stream<List<SharedJourneySummary>> watchSharedWithMe() => social.watch(
    () => social.call('shared_with_me', const {}, (json) {
      final list = [for (final r in rowsOf(json)) sharedSummaryFromJson(r)]
        ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
      return list;
    }),
  );

  @override
  Future<SharedJourneyView> openShared(String journeyId) async {
    final view = await social.call('shared_journey', {
      'p_journey': journeyId,
    }, sharedViewFromJson);
    // Marks the share seen: the inbox dot / Shared with me badge change.
    social.changed();
    return view;
  }

  @override
  Future<SharedJourneyView> openPublic(String token) async {
    final view = await social.call('public_journey_by_token', {
      'p_token': token.trim(),
    }, sharedViewFromJson);
    social.changed();
    return view;
  }

  @override
  Future<void> like(String checkInId) async {
    final me = social.requireUserId();
    try {
      await social.remote.insert('reactions', {
        'checkin_id': checkInId,
        'user_id': me,
        'emoji': likeEmoji,
      });
    } on OurneyException catch (e) {
      // Already liked (unique violation): liking is idempotent.
      if (!(e.detail?.startsWith('23505') ?? false)) rethrow;
    }
    social.changed();
  }

  @override
  Future<void> unlike(String checkInId) async {
    final me = social.requireUserId();
    await social.remote.delete(
      'reactions',
      match: {'checkin_id': checkInId, 'user_id': me},
    );
    social.changed();
  }

  @override
  Future<void> unsave(String journeyId) =>
      social.mutate('unsave_journey', {'p_journey': journeyId});

  @override
  Future<JourneyFrame> followFrame(String journeyId) =>
      social.call('follow_frame', {'p_journey': journeyId}, frameFromJson);

  @override
  Future<void> markFollowed(String newJourneyId, String sourceJourneyId) async {
    // The new journey may still sit in the outbox (offline create).
    await _flushFirst();
    await social.mutate('mark_followed', {
      'p_journey': newJourneyId,
      'p_source': sourceJourneyId,
    });
  }

  @override
  Future<Journey> createImported(ImportedJourneyDraft draft) async {
    if (validateJourneyTitle(draft.title) != null ||
        draft.lastDate.compareTo(draft.firstDate) < 0) {
      throw const OurneyException(OurneyErrorCode.invalid);
    }
    final me = social.requireUserId();
    final data = social.data;
    // Retry of a create that already landed: same journey back.
    final existing = await (_db.select(
      _db.journeys,
    )..where((t) => t.id.equals(draft.id))).getSingleOrNull();
    if (existing != null) return journeyFromRow(existing);

    final row = await social.remote.rpc(
      'create_imported_journey',
      importedJourneyParams(draft),
    );
    if (row is! Map) {
      throw const OurneyException(OurneyErrorCode.unknown, 'no row');
    }
    final json = row.cast<String, dynamic>();
    try {
      // Same caching as JourneyRepository.create: the journey shows on the
      // Hub shelf at once; the pull sync later refreshes it.
      await data.store.applyJourney({
        'origin': JourneyOrigin.imported.wireName,
        ...json,
      });
    } on OurneyException {
      rethrow;
    } on Object catch (e) {
      throw OurneyException(OurneyErrorCode.unknown, 'bad journey row: $e');
    }
    await _db
        .into(_db.memberships)
        .insert(
          MembershipsCompanion.insert(
            journeyId: draft.id,
            userId: me,
            role: MemberRole.owner.wireName,
            status: MemberStatus.active.wireName,
            joinedAt: data.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    data.sync?.notifyChanged();
    social.changed();
    final saved = await (_db.select(
      _db.journeys,
    )..where((t) => t.id.equals(draft.id))).getSingle();
    return journeyFromRow(saved);
  }
}
