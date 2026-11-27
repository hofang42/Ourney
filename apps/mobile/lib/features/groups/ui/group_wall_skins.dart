part of 'group_today_screen.dart';

// Per-skin group "Today" walls (V2 `SquadToday`, `QuietSquad`, `MemorySquad`,
// `CoupleSquad`, `FlexerSquad`, `MinimalSquad`). The data is the same
// [GroupTodayView]; only the layout and the voice change per skin.

String _hm(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)}';
}

/// Time of the member's check-in today, or null while still waiting.
String? _todayTime(GroupMemberEntry e) {
  final p = e.photo;
  return e.photoIsToday && p != null ? _hm(p.capturedAt) : null;
}

List<GroupMemberEntry> _allEntries(GroupTodayView v) => [
  ...v.done,
  ...v.pending,
];

/// Chooses the wall for [skinId] (`quiet`, `squad`, `memory`, `couple`,
/// `flexer`, `minimal`).
class _SkinWall extends StatelessWidget {
  const _SkinWall({
    required this.skinId,
    required this.view,
    required this.perms,
    required this.now,
  });

  final String skinId;
  final GroupTodayView view;
  final GroupPermissions perms;
  final DateTime now;

  @override
  Widget build(BuildContext context) => switch (skinId) {
    'quiet' => _QuietWall(view: view, perms: perms),
    'memory' => _MemoryWall(view: view, perms: perms),
    'couple' => _CoupleWall(view: view, perms: perms),
    'flexer' => _RunnerWall(view: view, perms: perms, flexer: true),
    'minimal' => _RunnerWall(view: view, perms: perms, flexer: false),
    _ => _SquadWall(view: view, perms: perms, now: now),
  };
}

/// Squad skin: attendance bar, "updated at" line, polaroid wall (done first,
/// then "NAME · WAITING" tiles). The nudge button is not built (no backend).
class _SquadWall extends StatelessWidget {
  const _SquadWall({
    required this.view,
    required this.perms,
    required this.now,
  });

  final GroupTodayView view;
  final GroupPermissions perms;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SharedStreak(view: view),
        const SizedBox(height: 4),
        Text(
          l10n.groups_wallUpdated(_hm(now)),
          style: UiText.body(size: 11, height: 1.4, color: ui.inkMuted),
        ),
        const SizedBox(height: UiSpace.lg),
        _MemberWall(view: view, perms: perms),
      ],
    );
  }
}

/// Avatar + name + status block shared by the row-based skins.
class _RowAvatar extends ConsumerWidget {
  const _RowAvatar({required this.entry});

  final GroupMemberEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) => UiAvatar(
    name: entry.member.displayName,
    colorIndex: UiAvatar.indexFor(entry.member.userId),
    size: UiSize.avatarLarge,
    image: groupAvatarImage(ref, entry.member.avatarPath),
  );
}

/// The "more" menu of a member (report / block / remove) used by the
/// row-based skins; null for the caller and when nothing is allowed.
Widget? _memberMenu(
  BuildContext context,
  WidgetRef ref,
  GroupMemberEntry entry,
  GroupPermissions perms, {
  Color? color,
}) {
  final l10n = GroupsL10n.of(context);
  final hooks = ref.watch(groupSafetyHooksProvider);
  final actions = <_MemberAction>[
    if (!entry.isMe && hooks.onReport != null) _MemberAction.report,
    if (!entry.isMe && hooks.onBlock != null) _MemberAction.block,
    if (!entry.isMe && perms.canRemoveMembers) _MemberAction.remove,
  ];
  if (actions.isEmpty) return null;
  final tile = _MemberTile(entry: entry, perms: perms, tilt: 0);
  return UiIconButton(
    key: ValueKey('group-member-menu-${entry.member.userId}'),
    glyph: OurneyIcon(
      name: 'more',
      size: 20,
      color: color,
      flat: color != null,
    ),
    label: l10n.groups_memberActions(entry.member.displayName),
    size: UiSize.tap,
    iconSize: 18,
    onPressed: () => tile._openMenu(context, ref, actions),
  );
}

/// Quiet skin: names sorted alphabetically, steadiness dots, photos hidden
/// (blurred) until the viewer chooses to show them.
class _QuietWall extends ConsumerStatefulWidget {
  const _QuietWall({required this.view, required this.perms});

  final GroupTodayView view;
  final GroupPermissions perms;

  @override
  ConsumerState<_QuietWall> createState() => _QuietWallState();
}

class _QuietWallState extends ConsumerState<_QuietWall> {
  final _shown = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final entries = _allEntries(widget.view)
      ..sort(
        (a, b) => a.member.displayName.toLowerCase().compareTo(
          b.member.displayName.toLowerCase(),
        ),
      );
    return Column(
      key: const ValueKey('group-wall-quiet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.groups_quietTitle,
            key: const ValueKey('group-today-header'),
            style: UiText.heading(
              font: 'Space Grotesk',
              size: 28,
              height: 1.25,
              color: ui.ink,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.groups_quietIntro,
          style: UiText.muted(color: ui.inkMuted, size: 14),
        ),
        const SizedBox(height: UiSpace.lg),
        for (final e in entries) _row(context, e, l10n, ui),
        const SizedBox(height: UiSpace.md),
        Text(
          l10n.groups_quietFooter,
          style: UiText.muted(color: ui.inkMuted, size: 13),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    GroupMemberEntry e,
    GroupsL10n l10n,
    OurneyUi ui,
  ) {
    final id = e.member.userId;
    final time = _todayTime(e);
    final visible = _shown.contains(id);
    final count = widget.view.weekDays[id] ?? 0;
    final photo = e.photo;
    final menu = _memberMenu(context, ref, e, widget.perms);
    return Container(
      key: ValueKey('group-member-$id'),
      margin: const EdgeInsets.only(bottom: UiSpace.md),
      padding: const EdgeInsets.all(UiSpace.md),
      decoration: BoxDecoration(
        color: ui.surface,
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: ui.stickerBorder(UiBorder.thin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RowAvatar(entry: e),
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.member.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 15,
                        weight: FontWeight.w800,
                        height: 1.4,
                        color: ui.ink,
                      ),
                    ),
                    Row(
                      key: ValueKey('group-member-status-$id'),
                      children: [
                        OurneyIcon(
                          name: time == null ? 'clock' : 'check',
                          size: 14,
                          flat: true,
                          color: ui.inkMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            time == null
                                ? l10n.groups_quietNotYet
                                : l10n.groups_quietDone(time),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.body(
                              size: 12,
                              height: 1.4,
                              color: ui.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (var i = 0; i < 7; i++)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < count ? ui.ink : Colors.transparent,
                              border: Border.all(color: ui.inkMuted),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.groups_quietSteady(count),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.body(
                              size: 11,
                              height: 1.4,
                              color: ui.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ?menu,
            ],
          ),
          if (photo != null) ...[
            const SizedBox(height: UiSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: UiButton.secondary(
                key: ValueKey('group-quiet-toggle-$id'),
                compact: true,
                expand: false,
                label: visible ? l10n.groups_quietHide : l10n.groups_quietShow,
                onPressed: () => setState(() {
                  visible ? _shown.remove(id) : _shown.add(id);
                }),
              ),
            ),
            const SizedBox(height: UiSpace.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(UiRadius.input),
              child: SizedBox(
                height: 150,
                child: ImageFiltered(
                  enabled: !visible,
                  imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: GroupPhoto(
                    key: ValueKey('group-member-photo-$id'),
                    checkIn: photo,
                    dimmed: !e.photoIsToday,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A 35mm frame: sprocket strip, photo, caption (memory skin).
class _FilmFrame extends ConsumerWidget {
  const _FilmFrame({
    required this.entry,
    required this.perms,
    required this.caption,
  });

  final GroupMemberEntry entry;
  final GroupPermissions perms;
  final String caption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = context.ui;
    final photo = entry.photo;
    final id = entry.member.userId;
    // The menu sits on the ink-coloured film strip: draw it in the page
    // background colour so it reads in light and dark.
    final menu = _memberMenu(context, ref, entry, perms, color: ui.bg);
    Widget sprockets() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < 10; i++)
          Container(
            width: 8,
            height: 6,
            decoration: BoxDecoration(
              color: ui.bg,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
    return Container(
      key: ValueKey('group-member-$id'),
      margin: const EdgeInsets.only(bottom: UiSpace.md),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: ui.ink,
        borderRadius: BorderRadius.circular(UiRadius.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sprockets(),
          const SizedBox(height: 6),
          SizedBox(
            height: 170,
            child: photo == null || !entry.photoIsToday
                ? Container(
                    key: ValueKey('group-member-nophoto-$id'),
                    decoration: BoxDecoration(
                      border: Border.all(color: ui.bg.withValues(alpha: 0.5)),
                    ),
                  )
                : GroupPhoto(
                    key: ValueKey('group-member-photo-$id'),
                    checkIn: photo,
                  ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 12,
                    weight: FontWeight.w800,
                    height: 1.4,
                    color: ui.bg,
                  ),
                ),
              ),
              ?menu,
            ],
          ),
          if (photo != null && entry.photoIsToday)
            ReactionBar(
              checkInId: photo.id,
              enabled: perms.isActive && !entry.isMe,
            ),
          const SizedBox(height: 6),
          sprockets(),
        ],
      ),
    );
  }
}

class _MemoryWall extends StatelessWidget {
  const _MemoryWall({required this.view, required this.perms});

  final GroupTodayView view;
  final GroupPermissions perms;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    return Column(
      key: const ValueKey('group-wall-memory'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.groups_memoryTitle(view.doneCount, view.memberCount),
            key: const ValueKey('group-today-header'),
            style: UiText.heading(
              font: 'Space Grotesk',
              size: 22,
              height: 1.3,
              color: ui.ink,
            ),
          ),
        ),
        const SizedBox(height: UiSpace.lg),
        for (final e in _allEntries(view))
          _FilmFrame(
            entry: e,
            perms: perms,
            caption: _todayTime(e) == null
                ? l10n.groups_memoryMissing(e.member.displayName.toUpperCase())
                : l10n.groups_memoryFrame(
                    e.member.displayName.toUpperCase(),
                    _todayTime(e)!,
                  ),
          ),
      ],
    );
  }
}

/// Couple skin: "today of the two of you", one half per partner.
class _CoupleWall extends ConsumerWidget {
  const _CoupleWall({required this.view, required this.perms});

  final GroupTodayView view;
  final GroupPermissions perms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final entries = _allEntries(view).take(2).toList();
    return Column(
      key: const ValueKey('group-wall-couple'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.groups_coupleTitle,
            key: const ValueKey('group-today-header'),
            style: UiText.heading(
              font: 'Space Grotesk',
              size: 28,
              height: 1.25,
              color: ui.ink,
            ),
          ),
        ),
        const SizedBox(height: UiSpace.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, e) in entries.indexed) ...[
              if (i > 0) const SizedBox(width: UiSpace.md),
              Expanded(child: _half(context, ref, e, l10n, ui)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _half(
    BuildContext context,
    WidgetRef ref,
    GroupMemberEntry e,
    GroupsL10n l10n,
    OurneyUi ui,
  ) {
    final id = e.member.userId;
    final time = _todayTime(e);
    final photo = e.photo;
    final name = e.member.displayName;
    final menu = _memberMenu(context, ref, e, perms);
    return Column(
      key: ValueKey('group-member-$id'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UiRadius.menu),
            child: photo != null && time != null
                ? GroupPhoto(
                    key: ValueKey('group-member-photo-$id'),
                    checkIn: photo,
                  )
                : Container(
                    key: ValueKey('group-member-nophoto-$id'),
                    decoration: BoxDecoration(
                      border: Border.all(color: ui.inkMuted, width: 2),
                      borderRadius: BorderRadius.circular(UiRadius.menu),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                !e.checkedInToday
                    ? l10n.groups_coupleWaiting(name)
                    : time == null
                    ? l10n.groups_coupleCheckedIn(name)
                    : l10n.groups_coupleDone(name, time),
                key: ValueKey('group-member-status-$id'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: UiText.body(
                  size: 13,
                  weight: FontWeight.w800,
                  height: 1.4,
                  color: e.checkedInToday ? ui.ink : ui.inkMuted,
                ),
              ),
            ),
            ?menu,
          ],
        ),
        if (photo != null && time != null)
          ReactionBar(checkInId: photo.id, enabled: perms.isActive && !e.isMe),
      ],
    );
  }
}

/// Flexer and minimal skins: "n/m DONE" header, one row per member with the
/// photo on the right; pending members get a muted row.
class _RunnerWall extends ConsumerWidget {
  const _RunnerWall({
    required this.view,
    required this.perms,
    required this.flexer,
  });

  final GroupTodayView view;
  final GroupPermissions perms;
  final bool flexer;

  bool get _isRunning {
    final j = perms.journey;
    final sport = j.dna?['sport'] as String?;
    final measure = j.dna?['measure'] as String?;
    final unit = (j.metricUnit ?? '').trim().toLowerCase();
    return (sport == null || sport == 'run') &&
        (measure == null || measure == 'km') &&
        (unit.isEmpty || unit == 'km');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final isRun = _isRunning;
    final title = flexer
        ? (isRun
              ? l10n.groups_flexerTitle(view.doneCount, view.memberCount)
              : l10n.groups_flexerTrainedTitle(
                  view.doneCount,
                  view.memberCount,
                ))
        : l10n.groups_minimalTitle(view.doneCount, view.memberCount);
    return Column(
      key: ValueKey(flexer ? 'group-wall-flexer' : 'group-wall-minimal'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            key: const ValueKey('group-today-header'),
            style: UiText.heading(
              font: 'Space Grotesk',
              size: 28,
              height: 1.25,
              color: ui.ink,
            ),
          ),
        ),
        const SizedBox(height: UiSpace.lg),
        for (final e in view.done) _row(context, ref, e, l10n, ui, true),
        for (final e in view.pending) _row(context, ref, e, l10n, ui, false),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    WidgetRef ref,
    GroupMemberEntry e,
    GroupsL10n l10n,
    OurneyUi ui,
    bool done,
  ) {
    final id = e.member.userId;
    final photo = e.photo;
    final time = _todayTime(e);
    final name = e.member.displayName.toUpperCase();
    final km = flexer && done && e.photoIsToday ? e.photo?.extras.km : null;
    final pace = flexer && done && e.photoIsToday ? e.photo?.extras.pace : null;
    final kmText = km == null
        ? null
        : NumberFormat(
            '0.00',
            Localizations.localeOf(context).toString(),
          ).format(km);
    final stat = kmText == null
        ? null
        : (pace == null
              ? l10n.groups_flexerKm(kmText)
              : l10n.groups_flexerKmPace(kmText, pace.toString()));
    final menu = _memberMenu(context, ref, e, perms);
    final isRun = _isRunning;
    final status = done
        ? (flexer
              ? (isRun
                    ? l10n.groups_flexerDone(time ?? '')
                    : l10n.groups_flexerTrainedDone(time ?? ''))
              : (time ?? ''))
        : (flexer
              ? (isRun
                    ? l10n.groups_flexerPending
                    : l10n.groups_flexerTrainedPending)
              : l10n.groups_minimalPending);
    return Container(
      key: ValueKey('group-member-$id'),
      margin: const EdgeInsets.only(bottom: UiSpace.md),
      padding: const EdgeInsets.all(UiSpace.md),
      decoration: BoxDecoration(
        color: ui.surface,
        borderRadius: BorderRadius.circular(flexer ? UiRadius.card : 6),
        border: ui.stickerBorder(UiBorder.thin),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RowAvatar(entry: e),
          const SizedBox(width: UiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 14,
                          weight: FontWeight.w900,
                          height: 1.4,
                          color: ui.ink,
                        ),
                      ),
                    ),
                    ?menu,
                  ],
                ),
                Row(
                  key: ValueKey('group-member-status-$id'),
                  children: [
                    if (done && flexer)
                      OurneyIcon(
                        name: 'check',
                        size: 14,
                        flat: true,
                        color: ui.ink,
                      ),
                    if (done && flexer) const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 12,
                          height: 1.4,
                          color: done ? ui.ink : ui.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (stat != null)
                  Text(
                    stat,
                    style: UiText.body(
                      size: 12,
                      weight: FontWeight.w800,
                      height: 1.4,
                      color: ui.accentText,
                    ),
                  ),
                if (done && photo != null && e.photoIsToday)
                  ReactionBar(
                    checkInId: photo.id,
                    enabled: perms.isActive && !e.isMe,
                  ),
              ],
            ),
          ),
          if (done && photo != null && e.photoIsToday) ...[
            const SizedBox(width: UiSpace.sm),
            SizedBox(
              width: 72,
              height: 96,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UiRadius.input),
                child: GroupPhoto(
                  key: ValueKey('group-member-photo-$id'),
                  checkIn: photo,
                ),
              ),
            ),
          ] else
            SizedBox(key: ValueKey('group-member-nophoto-$id')),
        ],
      ),
    );
  }
}
