import '../../app/app_routes.dart';

/// Sub-paths of the safety feature (no `AppRoutes` constants; they live
/// under `AppRoutes.safety`). Every path is reachable before sign-in, but
/// report/block/blocked need a backend and show "needs server" otherwise.
abstract final class SafetyPaths {
  /// Hub: links to terms, privacy, contact, blocked list.
  static const hub = AppRoutes.safety;

  /// Terms of use (EULA), read-only.
  static const eula = '${AppRoutes.safety}/eula';

  /// EULA acceptance gate (FR-F3). Add `?from=<path>` to come back after.
  static const eulaAccept = '${AppRoutes.safety}/eula/accept';

  static const privacy = '${AppRoutes.safety}/privacy';
  static const contact = '${AppRoutes.safety}/contact';

  /// Blocked users with unblock (FR-F2).
  static const blocked = '${AppRoutes.safety}/blocked';

  /// Report a check-in (FR-F1). [userId] (the author) is optional and only
  /// used to offer "also block" afterwards.
  static String reportCheckIn(
    String checkInId, {
    String? userId,
    String? name,
  }) => Uri(
    path:
        '${AppRoutes.safety}/report/checkin/${Uri.encodeComponent(checkInId)}',
    queryParameters: _query(userId: userId, name: name),
  ).toString();

  /// Report a user (FR-F1). [name] is shown in the "also block" step.
  static String reportUser(String userId, {String? name}) => Uri(
    path: '${AppRoutes.safety}/report/user/${Uri.encodeComponent(userId)}',
    queryParameters: _query(name: name),
  ).toString();

  /// Block confirmation page for [userId] (FR-F2).
  static String block(String userId, {String? name}) => Uri(
    path: '${AppRoutes.safety}/block/${Uri.encodeComponent(userId)}',
    queryParameters: _query(name: name),
  ).toString();

  /// Query parameter names.
  static const userIdParam = 'userId';
  static const nameParam = 'name';

  static Map<String, String>? _query({String? userId, String? name}) {
    final q = {
      if (userId != null && userId.isNotEmpty) userIdParam: userId,
      if (name != null && name.isNotEmpty) nameParam: name,
    };
    return q.isEmpty ? null : q;
  }
}
