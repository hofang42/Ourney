import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/providers.dart' show appConfigProvider;
import '../../data/group_daily_checkins_provider.dart'
    show groupMembersTodaySafeProvider, isCoupleGroup;
import '../sharing/data/sharing_providers.dart' show shareStateProvider;

enum CheckinAudience { unknown, private, shared, couple, squad, futureMembers }

/// The audience copy is shared by compose and completion. A group check-in can
/// be viewed by members who join after it was posted.
CheckinAudience watchCheckinAudience(WidgetRef ref, Journey? journey) {
  if (journey == null) return CheckinAudience.unknown;
  final group = journey.kind == JourneyKind.group;
  final hasLink =
      journey.visibility == JourneyVisibility.link ||
      (journey.publicToken?.trim().isNotEmpty ?? false);
  if (ref.watch(appConfigProvider).localOnly) {
    if (group) return CheckinAudience.unknown;
    return hasLink ? CheckinAudience.shared : CheckinAudience.private;
  }

  final sharing = ref.watch(shareStateProvider(journey.id));
  final members = group
      ? ref.watch(groupMembersTodaySafeProvider(journey.id))
      : null;
  if (sharing.isLoading || sharing.hasError || sharing.asData == null) {
    return CheckinAudience.unknown;
  }
  if (members != null &&
      (members.isLoading || members.hasError || members.asData == null)) {
    return CheckinAudience.unknown;
  }
  final shareState = sharing.requireValue;
  if (hasLink || shareState.linkOn || shareState.viewers.isNotEmpty) {
    return CheckinAudience.shared;
  }
  if (!group) return CheckinAudience.private;

  final memberCount = members!.requireValue.length;
  if (memberCount == 0) return CheckinAudience.unknown;
  if (memberCount == 1) return CheckinAudience.futureMembers;
  return isCoupleGroup(journey)
      ? CheckinAudience.couple
      : CheckinAudience.squad;
}
