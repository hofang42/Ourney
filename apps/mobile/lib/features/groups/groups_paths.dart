import '../../app/app_routes.dart';

/// Sub-paths of the groups feature that have no `AppRoutes` constant. They
/// live under the feature's own prefixes (`/groups`, `/join`).
abstract final class GroupsPaths {
  /// Manual invite-code entry (FR-D1). `AppRoutes.join(code)` pre-fills it.
  static const joinEntry = '/join';

  /// Group "Today" screen (FR-D3): `/groups/<journeyId>`.
  static String today(String journeyId) =>
      '${AppRoutes.groups}/${Uri.encodeComponent(journeyId)}';

  /// Invite code, link and QR: `/groups/<journeyId>/invite`.
  static String invite(String journeyId) => '${today(journeyId)}/invite';
}
