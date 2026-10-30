import 'package:ourney_core/ourney_core.dart';

import '../social_context.dart';
import '../social_mapping.dart';

/// [FriendRepository] over the v1.3 RPCs (docs/contracts/sharing.md).
class DataFriendRepository implements FriendRepository {
  DataFriendRepository(this.social);

  final SocialContext social;

  /// Re-fetches every open social stream (pull-to-refresh).
  void refresh() => social.changed();

  @override
  Stream<List<Friendship>> watchFriendships() => social.watch(
    () => social.call('my_friends', const {}, (json) {
      final list = [for (final r in rowsOf(json)) friendshipFromJson(r)]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }),
  );

  @override
  Future<PersonSummary?> findByUsername(String username) {
    final name = username.trim().replaceFirst(RegExp('^@'), '');
    if (name.isEmpty) return Future.value();
    return social.call('find_user_by_username', {
      'p_username': name,
    }, personOrNull);
  }

  @override
  Future<void> sendRequest(String userId, {String? fromJourneyId}) =>
      social.mutate('send_friend_request', {
        'p_user': userId,
        'p_source_journey': fromJourneyId,
      });

  @override
  Future<void> respond(String userId, {required bool accept}) => social.mutate(
    'respond_friend_request',
    {'p_user': userId, 'p_accept': accept},
  );

  @override
  Future<void> remove(String userId) =>
      social.mutate('remove_friend', {'p_user': userId});

  @override
  Future<String> createInvite() =>
      social.call('create_friend_invite', const {}, (json) => json! as String);

  @override
  Future<PersonSummary> acceptInvite(String token) async {
    final person = await social.call('accept_friend_invite', {
      'p_token': token.trim(),
    }, personFromJson);
    social.changed();
    return person;
  }
}
