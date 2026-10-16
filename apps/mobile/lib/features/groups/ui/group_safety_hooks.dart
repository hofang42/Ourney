import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Report a member or one of their check-ins (FR-F1). [checkInId] is the
/// photo shown on the "Today" screen, if any.
typedef GroupReportHook = Future<void> Function(
  BuildContext context, {
  required String userId,
  required String displayName,
  String? checkInId,
});

/// Block a member (FR-F2).
typedef GroupBlockHook = Future<void> Function(
  BuildContext context, {
  required String userId,
  required String displayName,
});

/// Entry points into the safety feature (C3), which owns the report and
/// block flows. The groups feature only shows the menu entries:
/// a member's overflow menu on the "Today" screen lists "Report" / "Block"
/// when the matching hook is non-null and calls it.
///
/// Wiring (integration): override [groupSafetyHooksProvider], e.g.
///
/// ```dart
/// groupSafetyHooksProvider.overrideWithValue(GroupSafetyHooks(
///   onReport: (context, {required userId, required displayName, checkInId}) =>
///       showReportSheet(context, userId: userId, checkInId: checkInId),
///   onBlock: (context, {required userId, required displayName}) =>
///       confirmBlock(context, userId: userId, displayName: displayName),
/// ))
/// ```
///
/// Blocked users disappear from the screen on their own: the "Today" screen
/// filters `SafetyRepository.watchBlockedIds()` and the server filters
/// `group_today` / reactions.
class GroupSafetyHooks {
  const GroupSafetyHooks({this.onReport, this.onBlock});

  final GroupReportHook? onReport;
  final GroupBlockHook? onBlock;
}

final groupSafetyHooksProvider = Provider<GroupSafetyHooks>(
  (ref) => const GroupSafetyHooks(),
);
