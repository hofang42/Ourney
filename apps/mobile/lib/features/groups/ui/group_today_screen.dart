import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/app_routes.dart';
import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../personas/active_journey_sync.dart';
import '../../../personas/persona_contract.dart' show personaSkinOf;
import '../../../ui/ui.dart';
import '../../journeys/data/journeys_providers.dart';
import '../../journeys/journeys_paths.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../../safety/data/safety_providers.dart';
import '../data/groups_providers.dart';
import '../domain/group_today.dart';
import '../groups_paths.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';
import 'group_photo.dart';
import 'group_safety_hooks.dart';
import 'reaction_bar.dart';

part 'group_wall_skins.dart';

enum GroupAction { invite, rotate, timeline, end, delete, leave }

enum _MemberAction { report, block, remove }

/// What the caller may do in a group journey (FR-D6/D7).
class GroupPermissions {
  const GroupPermissions({
    required this.journey,
    required this.membership,
    required this.currentUserId,
    required this.isAlone,
  });

  final Journey journey;
  final Membership? membership;
  final String? currentUserId;

  /// Only the caller is left among the visible active members.
  final bool isAlone;

  bool get isOwner {
    final m = membership;
    if (m != null) return m.role == MemberRole.owner;
    return currentUserId != null && journey.ownerId == currentUserId;
  }

  bool get isActive => journey.status == JourneyStatus.active;
  bool get canInvite => isActive;
  bool get canRotate => isOwner && isActive;
  bool get canEnd => isOwner && isActive;
  bool get canRemoveMembers => isOwner && isActive;

  /// Delete only when alone (SRS 3.1); otherwise the owner ends it. The
  /// server enforces it too (`not_alone`).
  bool get canDelete => isOwner && isAlone;
  bool get canLeave => membership?.isActive ?? true;
}

/// `/groups/:journeyId`: the squad wall (FR-D3, App.tsx `SquadWall`). Who
/// checked in today as polaroids with reactions (FR-D4), who has not yet as
/// waiting tiles. Consistency only: no ranking and no metric values (FR-D5).
/// Blocked users' content is hidden (FR-F2).
class GroupTodayScreen extends ConsumerWidget {
  const GroupTodayScreen({required this.journeyId, super.key});

  final String journeyId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.groups);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final app = AppLocalizations.of(context);
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;

    Widget frame({String? title, required Widget body}) => UiScaffold(
      key: const ValueKey('group-today'),
      scroll: false,
      padTop: 0,
      child: Column(
        children: [
          UiBackHeader(
            onBack: () => _back(context),
            backLabel: backLabel,
            title: title ?? l10n.groups_title,
          ),
          Expanded(child: UiFillScroll(child: body)),
        ],
      ),
    );

    if (ref.watch(appConfigProvider).localOnly) {
      return frame(body: const GroupsNeedsServer());
    }

    final journeyAsync = ref.watch(journeyByIdProvider(journeyId));
    final todayAsync = ref.watch(groupTodayProvider(journeyId));
    final firstError = journeyAsync.error ?? todayAsync.error;
    if (firstError != null && isNotWired(firstError)) {
      return GroupsNotWired(id: 'group-today', title: l10n.groups_title);
    }

    final journey = journeyAsync.value;
    Widget? state;
    if (journeyAsync.hasValue && journey == null) {
      state = UiEmptyState(
        key: const ValueKey('group-not-found'),
        glyph: const OurneyIcon(name: 'search', size: 30),
        title: l10n.groups_notFoundTitle,
        actionLabel: l10n.groups_title,
        onAction: () => context.go(AppRoutes.groups),
      );
    } else if (todayAsync.hasError || journeyAsync.hasError) {
      final e = rootError(firstError!);
      final forbidden =
          e is OurneyException && e.error == OurneyErrorCode.forbidden;
      state = UiEmptyState(
        key: ValueKey(forbidden ? 'group-not-member' : 'group-error'),
        glyph: OurneyIcon(name: forbidden ? 'lock' : 'error', size: 30),
        title: forbidden ? l10n.groups_notMember : l10n.groups_todayLoadError,
        body: forbidden ? null : groupErrorMessage(context, e),
        actionLabel: forbidden ? l10n.groups_title : app.common_retry,
        onAction: forbidden
            ? () => context.go(AppRoutes.groups)
            : () {
                ref
                  ..invalidate(journeyByIdProvider(journeyId))
                  ..invalidate(groupTodayProvider(journeyId));
              },
      );
    } else if (journey == null || !todayAsync.hasValue) {
      state = Center(child: UiSpinner(semanticsLabel: app.common_loading));
    }
    if (state != null) return frame(title: journey?.title, body: state);

    final myId = ref.watch(currentUserIdProvider);
    final membership = ref.watch(myMembershipProvider(journeyId)).value;
    final view = GroupTodayView.build(
      journey: journey!,
      members: todayAsync.value!,
      now: ref.watch(journeysClockProvider).now(),
      myUserId: myId,
      blockedIds: ref.watch(groupBlockedIdsProvider).value ?? const {},
      hiddenCheckInIds: ref.watch(hiddenCheckInIdsProvider),
      checkIns:
          ref.watch(groupCheckInsProvider(journeyId)).value ??
          const <CheckIn>[],
      myMembership: membership,
    );
    final perms = GroupPermissions(
      journey: journey,
      membership: membership,
      currentUserId: myId,
      isAlone: view.isAlone,
    );
    final style = uiStyleForSkin(personaSkinOf(journey));

    return ActiveJourneySync(
      journeyId: journey.id,
      child: UiSkinScope(
        skinId: uiSkinIdFor(personaSkinOf(journey)),
        child: Builder(
          builder: (context) => _wall(
            context,
            ref: ref,
            journey: journey,
            view: view,
            perms: perms,
            style: style,
            backLabel: backLabel,
            skinId: uiSkinIdFor(personaSkinOf(journey)),
            now: ref.watch(journeysClockProvider).now(),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(journeyByIdProvider(journeyId))
      ..invalidate(groupTodayProvider(journeyId))
      ..invalidate(groupCheckInsProvider(journeyId))
      ..invalidate(myMembershipProvider(journeyId));
  }

  Widget _wall(
    BuildContext context, {
    required WidgetRef ref,
    required Journey journey,
    required GroupTodayView view,
    required GroupPermissions perms,
    required UiJourneyStyle style,
    required String backLabel,
    required String skinId,
    required DateTime now,
  }) {
    final l10n = GroupsL10n.of(context);
    final app = AppLocalizations.of(context);
    final ui = context.ui;
    return UiRefreshScaffold(
      onRefresh: () => _refresh(ref),
      semanticsLabel: app.common_loading,
      child: UiScaffold(
        key: const ValueKey('group-today'),
        background: ui.bg,
        padTop: 0,
        gutter: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: UiSpace.sm),
              child: UiBackHeader(
                onBack: () => _back(context),
                backLabel: backLabel,
                title: journey.title,
                bordered: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (perms.canInvite)
                      UiIconButton(
                        key: const ValueKey('group-invite'),
                        glyph: const OurneyIcon(name: 'user-plus', size: 20),
                        label: l10n.groups_invite,
                        onPressed: () =>
                            context.push(GroupsPaths.invite(journeyId)),
                      ),
                    _GroupMenu(perms: perms),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                UiSpace.xl,
                UiSpace.xl,
                UiSpace.xl,
                UiSpace.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!perms.isActive) ...[
                    UiBanner(
                      key: const ValueKey('group-ended-banner'),
                      kind: UiBannerKind.archived,
                      message: l10n.groups_endedBanner,
                    ),
                    const SizedBox(height: UiSpace.md),
                  ],
                  _SkinWall(
                    skinId: skinId,
                    view: view,
                    perms: perms,
                    now: now,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.shared-streak`: day, "done of members" and a progress bar.
class _SharedStreak extends StatelessWidget {
  const _SharedStreak({required this.view});

  final GroupTodayView view;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final total = view.memberCount;
    final value = total == 0 ? 0.0 : view.doneCount / total;
    return Column(
      key: const ValueKey('group-today-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const OurneyIcon(name: 'flame', size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                view.totalDays == null
                    ? l10n.groups_dayOpen(view.dayNumber)
                    : l10n.groups_dayOf(view.dayNumber, view.totalDays!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  height: 1.4,
                  color: ui.inkMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${view.doneCount}/$total',
          style: UiText.display(
            size: 48,
            weight: 800,
            height: 1.15,
            color: ui.ink,
          ),
        ),
        const SizedBox(height: UiSpace.sm),
        UiProgressBar(
          value: value,
          color: ui.accent,
          semanticLabel: l10n.groups_todayHeader(view.doneCount, total),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.groups_todayHeader(view.doneCount, total),
          style: UiText.body(
            size: 12,
            weight: FontWeight.w700,
            height: 1.4,
            color: ui.ink,
          ),
        ),
      ],
    );
  }
}

/// The polaroid wall: done members first, then the ones still waiting.
class _MemberWall extends StatelessWidget {
  const _MemberWall({required this.view, required this.perms});

  final GroupTodayView view;
  final GroupPermissions perms;

  @override
  Widget build(BuildContext context) {
    Widget grid(List<GroupMemberEntry> entries) => LayoutBuilder(
      builder: (context, c) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final cols = c.maxWidth >= 300 && scale <= 1.35 ? 2 : 1;
        final rows = <Widget>[];
        for (var i = 0; i < entries.length; i += cols) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: UiSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var k = 0; k < cols; k++) ...[
                    if (k > 0) const SizedBox(width: UiSpace.md),
                    Expanded(
                      child: i + k < entries.length
                          ? _MemberTile(
                              entry: entries[i + k],
                              perms: perms,
                              tilt: (i + k).isEven ? -1 : 1.2,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
    // V2 `.squad-wall`: one wall, done members first, then the waiting ones.
    return grid([...view.done, ...view.pending]);
  }
}

class _GroupMenu extends ConsumerWidget {
  const _GroupMenu({required this.perms});

  final GroupPermissions perms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    Future<void> open() async {
      final action = await showUiSheet<GroupAction>(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UiRow(
              key: const ValueKey('group-action-timeline'),
              title: l10n.groups_openTimeline,
              leading: const OurneyIcon(name: 'journeys', size: 22, flat: true),
              showChevron: false,
              onPressed: () => Navigator.of(context).pop(GroupAction.timeline),
            ),
            if (perms.canRotate)
              UiRow(
                key: const ValueKey('group-action-rotate'),
                title: l10n.groups_actionRotate,
                leading: const OurneyIcon(
                  name: 'refresh',
                  size: 22,
                  flat: true,
                ),
                showChevron: false,
                onPressed: () => Navigator.of(context).pop(GroupAction.rotate),
              ),
            if (perms.canEnd)
              UiRow(
                key: const ValueKey('group-action-end'),
                title: l10n.groups_actionEnd,
                leading: const OurneyIcon(name: 'flag', size: 22, flat: true),
                showChevron: false,
                onPressed: () => Navigator.of(context).pop(GroupAction.end),
              ),
            if (perms.canDelete)
              UiRow(
                key: const ValueKey('group-action-delete'),
                title: l10n.groups_actionDelete,
                leading: const OurneyIcon(name: 'trash', size: 22, flat: true),
                showChevron: false,
                onPressed: () => Navigator.of(context).pop(GroupAction.delete),
              ),
            if (perms.canLeave)
              UiRow(
                key: const ValueKey('group-action-leave'),
                title: l10n.groups_actionLeave,
                leading: const OurneyIcon(name: 'logout', size: 22, flat: true),
                showChevron: false,
                divider: false,
                onPressed: () => Navigator.of(context).pop(GroupAction.leave),
              ),
          ],
        ),
      );
      if (action != null && context.mounted) {
        await runGroupAction(context, ref, perms, action);
      }
    }

    return UiIconButton(
      key: const ValueKey('group-menu'),
      glyph: const OurneyIcon(name: 'more', size: 20),
      label: l10n.groups_moreActions,
      onPressed: open,
    );
  }
}

/// Runs a journey-level action with its confirmation (FR-D6/D7).
Future<void> runGroupAction(
  BuildContext context,
  WidgetRef ref,
  GroupPermissions perms,
  GroupAction action,
) async {
  final l10n = GroupsL10n.of(context);
  final id = perms.journey.id;
  final groups = ref.read(groupRepositoryProvider);
  final journeys = ref.read(journeyRepositoryProvider);
  // Ending, deleting or leaving a group changes its reminders (FR-G1).
  final reminders = ref.read(reminderSchedulerProvider);
  switch (action) {
    case GroupAction.invite:
      await context.push(GroupsPaths.invite(id));
      return;
    case GroupAction.timeline:
      // Lives in the Journeys tab: switch tabs rather than push across.
      context.go(AppRoutes.journey(id));
      return;
    case GroupAction.rotate:
      final ok = await confirmGroupAction(
        context,
        title: l10n.groups_rotateTitle,
        message: l10n.groups_rotateMessage,
        confirmLabel: l10n.groups_actionRotate,
      );
      if (!ok || !context.mounted) return;
      await _guard(context, () async {
        await groups.rotateInviteCode(id);
        if (context.mounted) showGroupSnack(context, l10n.groups_rotateDone);
      });
    case GroupAction.end:
      final ok = await confirmGroupAction(
        context,
        title: l10n.groups_endTitle,
        message: l10n.groups_endMessage,
        confirmLabel: l10n.groups_actionEnd,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await _guard(context, () async {
        await journeys.end(id);
        unawaited(reminders.reschedule());
      });
    case GroupAction.delete:
      final ok = await confirmGroupAction(
        context,
        title: l10n.groups_deleteTitle,
        message: l10n.groups_deleteMessage,
        confirmLabel: l10n.groups_actionDelete,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await _guard(context, () async {
        await journeys.delete(id);
        unawaited(reminders.reschedule());
        if (context.mounted) context.go(AppRoutes.groups);
      });
    case GroupAction.leave:
      final notes = [
        l10n.groups_leaveMessage,
        if (perms.isAlone)
          l10n.groups_leaveAloneNote
        else if (perms.isOwner)
          l10n.groups_leaveOwnerNote,
      ];
      final ok = await confirmGroupAction(
        context,
        title: l10n.groups_leaveTitle,
        message: notes.join('\n\n'),
        confirmLabel: l10n.groups_actionLeave,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await _guard(context, () async {
        await groups.leave(id);
        unawaited(reminders.reschedule());
        if (!context.mounted) return;
        showGroupSnack(context, l10n.groups_leftDone);
        context.go(AppRoutes.groups);
      });
  }
}

Future<void> _guard(BuildContext context, Future<void> Function() body) async {
  try {
    await body();
  } on Object catch (e) {
    if (context.mounted) showGroupSnack(context, groupErrorMessage(context, e));
  }
}

/// One member on the wall: a polaroid when there is a photo, a waiting tile
/// otherwise (`.waiting-tile`). Carries the report, block and remove actions.
class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.entry,
    required this.perms,
    required this.tilt,
  });

  final GroupMemberEntry entry;
  final GroupPermissions perms;
  final double tilt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final app = AppLocalizations.of(context);
    final ui = context.ui;
    final m = entry.member;
    final photo = entry.photo;
    final hooks = ref.watch(groupSafetyHooksProvider);
    final memberActions = <_MemberAction>[
      if (!entry.isMe && hooks.onReport != null) _MemberAction.report,
      if (!entry.isMe && hooks.onBlock != null) _MemberAction.block,
      if (!entry.isMe && perms.canRemoveMembers) _MemberAction.remove,
    ];
    final tags = [
      if (entry.isMe) l10n.groups_you,
      if (m.role == MemberRole.owner) l10n.groups_ownerBadge,
    ];

    final nameRow = Row(
      children: [
        Expanded(
          child: Text(
            m.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: UiText.body(
              size: 14,
              weight: FontWeight.w700,
              height: 1.4,
              color: ui.ink,
            ),
          ),
        ),
        if (memberActions.isNotEmpty)
          UiIconButton(
            key: ValueKey('group-member-menu-${m.userId}'),
            glyph: const OurneyIcon(name: 'more', size: 20),
            label: l10n.groups_memberActions(m.displayName),
            size: UiSize.tap,
            iconSize: 18,
            onPressed: () => _openMenu(context, ref, memberActions),
          ),
      ],
    );
    final status = Row(
      key: ValueKey('group-member-status-${m.userId}'),
      children: [
        OurneyIcon(
          name: entry.checkedInToday ? 'check-circle' : 'radio-off',
          size: 14,
          flat: true,
          color: entry.checkedInToday ? ui.success : ui.inkMuted,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            entry.checkedInToday
                ? l10n.groups_statusDone
                : l10n.groups_statusPending,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.body(size: 11, height: 1.4, color: ui.inkMuted),
          ),
        ),
      ],
    );
    final streak = Semantics(
      label: app.streak_semantics(entry.streak),
      excludeSemantics: true,
      child: Row(
        key: ValueKey('group-member-streak-${m.userId}'),
        children: [
          const OurneyIcon(name: 'flame', size: 12),
          const SizedBox(width: 2),
          Text(
            '${entry.streak}',
            style: UiText.body(size: 11, height: 1.4, color: ui.inkMuted),
          ),
        ],
      ),
    );
    final tagLine = tags.isEmpty
        ? null
        : Text(
            tags.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.body(size: 11, height: 1.4, color: ui.inkMuted),
          );

    if (photo == null) {
      return Container(
        key: ValueKey('group-member-${m.userId}'),
        padding: const EdgeInsets.all(UiSpace.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UiRadius.menu),
          border: ui.stickerBorder(),
        ),
        child: Column(
          children: [
            UiAvatar(
              name: m.displayName,
              colorIndex: UiAvatar.indexFor(m.userId),
              size: UiSize.avatarLarge,
              image: groupAvatarImage(ref, m.avatarPath),
            ),
            const SizedBox(height: UiSpace.sm),
            nameRow,
            ?tagLine,
            status,
            const SizedBox(height: 4),
            Text(
              l10n.groups_wallWaiting(m.displayName.toUpperCase()),
              key: ValueKey('group-member-nophoto-${m.userId}'),
              textAlign: TextAlign.center,
              style: UiText.body(size: 12, height: 1.45, color: ui.inkMuted),
            ),
          ],
        ),
      );
    }

    final Widget rawPhoto = GroupPhoto(
      key: ValueKey('group-member-photo-${m.userId}'),
      checkIn: photo,
      dimmed: !entry.photoIsToday,
    );
    final Widget photoBox = SizedBox(
      height: 158,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (entry.isMe)
            UiHero(
              tag: UiHeroTags.dayPhoto(photo.id),
              borderRadiusBegin: BorderRadius.circular(UiRadius.thumb),
              borderRadiusEnd: BorderRadius.circular(UiRadius.card),
              child: rawPhoto,
            )
          else
            rawPhoto,
          if (entry.checkedInToday)
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: ui.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ui.outline,
                    width: UiBorder.hairline,
                  ),
                ),
                child: OurneyIcon(
                  name: 'check',
                  size: 14,
                  flat: true,
                  color: ui.bg,
                ),
              ),
            ),
        ],
      ),
    );

    return KeyedSubtree(
      key: ValueKey('group-member-${m.userId}'),
      child: UiPolaroid(
        tilt: tilt,
        photo: entry.isMe
            ? UiPressable(
                key: ValueKey('group-member-photo-tap-${m.userId}'),
                onPressed: () => context.push(
                  JourneysPaths.day(perms.journey.id, photo.localDate),
                ),
                pressScale: 1.0,
                semanticLabel: '${m.displayName}, ${l10n.groups_openTimeline}',
                excludeChildSemantics: true,
                borderRadius: BorderRadius.circular(UiRadius.thumb),
                child: photoBox,
              )
            : photoBox,
        footer: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              nameRow,
              ?tagLine,
              status,
              if (!entry.photoIsToday)
                Text(
                  l10n.groups_latestPhoto(
                    MaterialLocalizations.of(context).formatMediumDate(
                      DateTime(
                        photo.localDate.year,
                        photo.localDate.month,
                        photo.localDate.day,
                      ),
                    ),
                  ),
                  style: UiText.body(size: 11, height: 1.4, color: ui.inkMuted),
                ),
              streak,
              if (photo.caption case final caption?
                  when caption.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.body(size: 12, height: 1.45, color: ui.ink),
                  ),
                ),
              const SizedBox(height: UiSpace.sm),
              ReactionBar(
                checkInId: photo.id,
                enabled: perms.isActive && !entry.isMe,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu(
    BuildContext context,
    WidgetRef ref,
    List<_MemberAction> actions,
  ) async {
    final l10n = GroupsL10n.of(context);
    final picked = await showUiSheet<_MemberAction>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, a) in actions.indexed)
            UiRow(
              key: ValueKey('group-member-action-${a.name}'),
              title: switch (a) {
                _MemberAction.report => l10n.groups_actionReport,
                _MemberAction.block => l10n.groups_actionBlock,
                _MemberAction.remove => l10n.groups_actionRemove,
              },
              leading: OurneyIcon(
                name: switch (a) {
                  _MemberAction.report => 'flag',
                  _MemberAction.block => 'block',
                  _MemberAction.remove => 'user-minus',
                },
                size: 22,
                flat: true,
              ),
              showChevron: false,
              divider: i < actions.length - 1,
              onPressed: () => Navigator.of(context).pop(a),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    await _onMemberAction(context, ref, picked);
  }

  Future<void> _onMemberAction(
    BuildContext context,
    WidgetRef ref,
    _MemberAction action,
  ) async {
    final m = entry.member;
    final hooks = ref.read(groupSafetyHooksProvider);
    switch (action) {
      case _MemberAction.report:
        await hooks.onReport?.call(
          context,
          userId: m.userId,
          displayName: m.displayName,
          checkInId: entry.photo?.id,
        );
      case _MemberAction.block:
        await hooks.onBlock?.call(
          context,
          userId: m.userId,
          displayName: m.displayName,
        );
      case _MemberAction.remove:
        final l10n = GroupsL10n.of(context);
        final repo = ref.read(groupRepositoryProvider);
        final ok = await confirmGroupAction(
          context,
          title: l10n.groups_removeTitle(m.displayName),
          message: l10n.groups_removeMessage,
          confirmLabel: l10n.groups_actionRemove,
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        await _guard(context, () async {
          await repo.removeMember(perms.journey.id, m.userId);
          if (context.mounted) {
            showGroupSnack(context, l10n.groups_removedDone(m.displayName));
          }
        });
    }
  }
}
