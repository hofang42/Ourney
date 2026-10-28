import '../../app/app_routes.dart';

/// Paths of the social feature (SCR-80, 81, 85, 86 and the invite link).
abstract final class SocialPaths {
  static const friends = AppRoutes.friends;
  static const friendsAdd = AppRoutes.friendsAdd;
  static const inbox = AppRoutes.inbox;

  static String chat(String conversationId) => AppRoutes.chat(conversationId);

  static String invite(String token) => AppRoutes.friendInvite(token);

  /// Public URL of an invite token (opens WEB-05 / the app at `/f/<token>`).
  static String inviteUrl(String token) =>
      'https://ourney.app/f/${Uri.encodeComponent(token)}';
}
