import '../../app/app_routes.dart';

/// Sub-paths of the sharing feature that have no `AppRoutes` constant.
abstract final class SharingPaths {
  /// Prepare the story (SCR-83): `/sharing/<id>/story`.
  static String story(String journeyId) =>
      '${AppRoutes.shareJourney(journeyId)}/story';

  /// Insights of a public journey (SCR-88): `/sharing/<id>/insights`.
  static String insights(String journeyId) =>
      '${AppRoutes.shareJourney(journeyId)}/insights';

  /// Chat thread (SCR-86), built by the chat feature: `/chat/<id>`. With
  /// [replyTo], the first message sent answers that check-in
  /// (`/chat/<id>?replyTo=<checkInId>`).
  static String chat(String conversationId, {String? replyTo}) {
    final path = '/chat/${Uri.encodeComponent(conversationId)}';
    return replyTo == null
        ? path
        : '$path?replyTo=${Uri.encodeQueryComponent(replyTo)}';
  }

  /// Query parameter of the create form route that opens **More options**
  /// ("Change something" on SCR-87).
  static const moreOptionsParam = 'more';
}
