import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../safety/ui/block_dialogs.dart';
import '../../safety/ui/report_form.dart';

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
/// [groupSafetyHooksProvider] is wired to the safety feature by default
/// ([safetyGroupHooks]: `showReportSheet` / `confirmBlock`); tests override
/// it with recording hooks or `const GroupSafetyHooks()` (no menu entries).
///
/// Blocked users disappear from the screen on their own: the "Today" screen
/// filters `SafetyRepository.watchBlockedIds()` and the server filters
/// `group_today` / reactions. Reported check-ins are filtered with
/// `hiddenCheckInIdsProvider` at once (FR-F2).
class GroupSafetyHooks {
  const GroupSafetyHooks({this.onReport, this.onBlock});

  final GroupReportHook? onReport;
  final GroupBlockHook? onBlock;
}

/// The production wiring: report sheet and block confirmation from safety.
/// Reporting a member reports the photo shown on their card when there is
/// one (with "also block" afterwards), otherwise the member.
final GroupSafetyHooks safetyGroupHooks = GroupSafetyHooks(
  onReport:
      (context, {required userId, required displayName, checkInId}) async {
        await showReportSheet(
          context,
          checkInId: checkInId,
          userId: userId,
          name: displayName,
        );
      },
  onBlock: (context, {required userId, required displayName}) async {
    await confirmBlock(context, userId: userId, name: displayName);
  },
);

final groupSafetyHooksProvider = Provider<GroupSafetyHooks>(
  (ref) => safetyGroupHooks,
);
