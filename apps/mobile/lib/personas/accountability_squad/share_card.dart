import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/providers.dart';
import '../../app/theme/persona_theme.dart';
import '../../app/theme/tokens.dart' show OurneyColors;
import '../../features/groups/data/groups_providers.dart';
import '../../features/groups/domain/group_today.dart';
import '../../features/groups/ui/group_photo.dart';
import '../../features/groups/ui/reaction_bar.dart';
import '../../shared/needs_server_view.dart';
import 'l10n/generated/accountability_squad_localizations.dart';
import 'persona_palette.dart';
import 'persona_widgets.dart';

/// **Task S3** (`PersonaSkinId.accountabilitySquad` — `squadPolaroidWall`):
/// Shown on the Squad Today screen and used as the share card of Persona 2:
/// - Top progress bar (`x/y ĐÃ CHECK-IN HÔM NAY` / `x/y CHECKED IN TODAY`)
/// - Responsive 2-column Polaroid grid (`LayoutBuilder` — never hardcoded pixel
///   widths)
/// - Emoji reactions via [ReactionBar] (`lib/features/groups/ui/reaction_bar.dart`)
/// - Dashed waiting slot (`MINH · ĐANG CHỜ` / `MINH · WAITING`) for members who
///   haven't checked in yet. **No Nudge button in v1** (FR-G3 is P2).
/// - In local-only mode (`appConfigProvider.localOnly`), renders
///   [NeedsServerView].
class SquadPolaroidWall extends ConsumerWidget {
  const SquadPolaroidWall({
    required this.journey,
    required this.members,
    this.reactionsEnabled = true,
    this.onNudge,
    this.photoBuilder,
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  final Journey journey;
  final List<GroupMemberEntry> members;
  final bool reactionsEnabled;

  /// Shows the purple `Nudge <name>` pill in waiting tiles when non-null.
  /// Nudging (FR-G3) is not wired up in v1, so the app leaves this `null`.
  final ValueChanged<GroupMemberEntry>? onNudge;
  final Widget Function(BuildContext context, GroupMemberEntry entry)?
  photoBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  static String _formatShortTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appConfigProvider).localOnly) {
      return const NeedsServerView(key: ValueKey('s3-needs-server'));
    }

    final pTheme = OurneyPersonaTheme.of(context);
    final l10n = AccountabilitySquadL10n.of(context);

    final totalCount = members.length;
    final doneCount = members.where((m) => m.checkedInToday).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final hPad = PersonaLayout.horizontalPadding(maxW);
        const gridGap = 12.0;
        final contentWidth = (maxW - hPad * 2).clamp(
          200.0,
          PersonaLayout.maxContentWidth,
        );
        final colWidth = (contentWidth - gridGap) / 2;

        final rows = <Widget>[];
        for (var i = 0; i < members.length; i += 2) {
          final leftEntry = members[i];
          final rightEntry = i + 1 < members.length ? members[i + 1] : null;
          rows.add(
            Padding(
              padding: EdgeInsets.only(
                bottom: i + 2 < members.length ? gridGap : 0,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SquadMemberTile(
                        key: ValueKey('s3-member-${leftEntry.member.userId}'),
                        entry: leftEntry,
                        colWidth: colWidth,
                        pTheme: pTheme,
                        l10n: l10n,
                        reactionsEnabled: reactionsEnabled,
                        onNudge: onNudge,
                        photoBuilder: photoBuilder,
                      ),
                    ),
                    const SizedBox(width: gridGap),
                    Expanded(
                      child: rightEntry != null
                          ? _SquadMemberTile(
                              key: ValueKey(
                                's3-member-${rightEntry.member.userId}',
                              ),
                              entry: rightEntry,
                              colWidth: colWidth,
                              pTheme: pTheme,
                              l10n: l10n,
                              reactionsEnabled: reactionsEnabled,
                              onNudge: onNudge,
                              photoBuilder: photoBuilder,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView(
          key: const ValueKey('squad-polaroid-wall'),
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: PersonaLayout.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SquadProgressHeader(
                      done: doneCount,
                      total: totalCount,
                      label: l10n.accountability_squad_checkedInProgress(
                        doneCount,
                        totalCount,
                      ),
                      pTheme: pTheme,
                    ),
                    const SizedBox(height: 16),
                    if (members.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          l10n.accountability_squad_emptySquad,
                          key: const ValueKey('s3-empty-squad'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: pTheme.inkMuted,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      ...rows,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SquadProgressHeader extends StatelessWidget {
  const _SquadProgressHeader({
    required this.done,
    required this.total,
    required this.label,
    required this.pTheme,
  });

  final int done;
  final int total;
  final String label;
  final OurneyPersonaTheme pTheme;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    // The label straddles the amber fill and the (theme-coloured) track, so a
    // hard-stop gradient colours it dark-on-amber inside the fill and with the
    // theme's ink outside it, from a single Text.
    final labelText = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            stops: [ratio, ratio],
            colors: [PersonaPalette.onAccent(pTheme.primaryAccent), pTheme.ink],
          ).createShader(bounds),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('s3-progress-bar'),
        height: 46,
        decoration: BoxDecoration(
          color: pTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: ColoredBox(color: pTheme.primaryAccent),
            ),
            labelText,
          ],
        ),
      ),
    );
  }
}

class _SquadMemberTile extends StatelessWidget {
  const _SquadMemberTile({
    required this.entry,
    required this.colWidth,
    required this.pTheme,
    required this.l10n,
    required this.reactionsEnabled,
    required this.onNudge,
    required this.photoBuilder,
    super.key,
  });

  final GroupMemberEntry entry;
  final double colWidth;
  final OurneyPersonaTheme pTheme;
  final AccountabilitySquadL10n l10n;
  final bool reactionsEnabled;
  final ValueChanged<GroupMemberEntry>? onNudge;
  final Widget Function(BuildContext context, GroupMemberEntry entry)?
  photoBuilder;

  @override
  Widget build(BuildContext context) {
    final nameUpper = entry.member.displayName.toUpperCase();
    final radius = BorderRadius.circular(pTheme.cardRadius * 0.7);

    if (!entry.checkedInToday) {
      return DashedWaitingBox(
        key: ValueKey('s3-waiting-${entry.member.userId}'),
        borderRadius: pTheme.cardRadius * 0.7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Same footprint as a photo so the row keeps its rhythm.
            const SizedBox(height: 96),
            Text(
              l10n.accountability_squad_memberWaiting(nameUpper),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.accountability_squad_waitingHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pTheme.inkMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            if (onNudge != null) ...[
              const SizedBox(height: 8),
              PersonaPrimaryButton(
                key: ValueKey('s3-nudge-${entry.member.userId}'),
                label: l10n.accountability_squad_nudge(
                  entry.member.displayName,
                ),
                backgroundColor: pTheme.secondaryAccent,
                onPressed: () => onNudge!(entry),
              ),
            ],
          ],
        ),
      );
    }

    final checkIn = entry.photo;
    final timeText = checkIn != null
        ? SquadPolaroidWall._formatShortTime(checkIn.capturedAt)
        : null;

    final Widget photoWidget;
    if (photoBuilder != null) {
      photoWidget = photoBuilder!(context, entry);
    } else if (checkIn != null) {
      photoWidget = GroupPhoto(checkIn: checkIn);
    } else {
      photoWidget = ColoredBox(
        color: pTheme.surfaceElevated,
        child: Center(
          child: Icon(
            Icons.check_circle_rounded,
            color: pTheme.primaryAccent,
            size: 32,
          ),
        ),
      );
    }

    return Semantics(
      label: '$nameUpper${timeText != null ? ' $timeText' : ''}',
      child: Container(
        decoration: BoxDecoration(
          color: pTheme.surface,
          borderRadius: radius,
          border: Border.all(color: pTheme.border, width: pTheme.borderWidth),
        ),
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 0.86,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius.topLeft.x * 0.55),
                  border: Border.all(color: pTheme.border, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: photoWidget,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: nameUpper),
                    const TextSpan(text: ' '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: OurneyColors.of(context).success,
                      ),
                    ),
                    if (timeText != null) TextSpan(text: ' $timeText'),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pTheme.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (checkIn != null)
              _TileReactions(
                checkInId: checkIn.id,
                canReact: reactionsEnabled && !entry.isMe,
                addLabel: l10n.accountability_squad_addReaction,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact reaction strip for a wall tile: the emojis people already left
/// (`🔥 4`) plus a 48dp button that opens the full [ReactionBar] in a sheet.
///
/// The full bar offers five 48dp chips, which would wrap into several rows and
/// make a two-column wall lopsided; the sheet keeps FR-D4 behaviour unchanged.
class _TileReactions extends ConsumerWidget {
  const _TileReactions({
    required this.checkInId,
    required this.canReact,
    required this.addLabel,
  });

  final String checkInId;
  final bool canReact;
  final String addLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pTheme = OurneyPersonaTheme.of(context);
    final blocked = ref.watch(groupBlockedIdsProvider).value ?? const {};
    final reactions =
        ref.watch(groupReactionsProvider(checkInId)).value ??
        const <Reaction>[];
    final summary = ReactionSummary.of(
      reactions,
      myUserId: ref.watch(currentUserIdProvider),
      blockedIds: blocked,
    );

    // Tiles without the add button (the viewer's own photo) still reserve a
    // comparable strip, so a row keeps the same rhythm.
    return ConstrainedBox(
      key: ValueKey('s3-reactions-$checkInId'),
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in summary.counts.entries)
                  if (e.value > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: summary.mine == e.key
                            ? pTheme.primaryAccent.withValues(alpha: 0.22)
                            : null,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${e.key} ${e.value}',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: pTheme.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
              ],
            ),
          ),
          if (canReact)
            Semantics(
              button: true,
              label: addLabel,
              excludeSemantics: true,
              child: InkResponse(
                radius: 24,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: ReactionBar(checkInId: checkInId),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: PersonaLayout.minTouchTarget,
                  height: PersonaLayout.minTouchTarget,
                  child: Center(
                    child: Icon(
                      Icons.add_reaction_outlined,
                      size: 22,
                      color: pTheme.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
