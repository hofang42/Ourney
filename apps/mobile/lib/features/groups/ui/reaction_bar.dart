import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/motion.dart';
import '../../../ui/ui.dart';
import '../data/groups_providers.dart';
import '../domain/group_today.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';

/// Emoji reactions on one check-in (FR-D4): 🔥 💪 👏 ❤️ 😂, one per person
/// (tapping another emoji replaces it, tapping yours removes it). No
/// comments in v1. [enabled] is false for the caller's own photo and once
/// the journey has ended (counts stay visible).
class ReactionBar extends ConsumerStatefulWidget {
  const ReactionBar({required this.checkInId, this.enabled = true, super.key});

  final String checkInId;
  final bool enabled;

  @override
  ConsumerState<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends ConsumerState<ReactionBar> {
  /// Optimistic value while a write is in flight (null = none pending;
  /// `''` = removing).
  String? _pending;

  Future<void> _toggle(String emoji, String? mine) async {
    final repo = ref.read(groupRepositoryProvider);
    final removing = mine == emoji;
    setState(() => _pending = removing ? '' : emoji);
    OurneyHaptics.selection();
    try {
      if (removing) {
        await repo.unreact(widget.checkInId);
      } else {
        await repo.react(widget.checkInId, emoji);
      }
    } on Object catch (e) {
      if (mounted) showGroupSnack(context, groupErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final myId = ref.watch(currentUserIdProvider);
    final blocked = ref.watch(groupBlockedIdsProvider).value ?? const {};
    final reactions =
        ref.watch(groupReactionsProvider(widget.checkInId)).value ??
        const <Reaction>[];
    final summary = ReactionSummary.of(
      reactions,
      myUserId: myId,
      blockedIds: blocked,
    );
    final counts = Map.of(summary.counts);
    var mine = summary.mine;
    if (_pending != null) {
      // Optimistic: move the caller's reaction before the stream catches up.
      if (mine != null) counts[mine] = counts[mine]! - 1;
      mine = _pending!.isEmpty ? null : _pending;
      if (mine != null) counts[mine] = counts[mine]! + 1;
    }

    return Wrap(
      key: ValueKey('groups-reactions-${widget.checkInId}'),
      spacing: UiSpace.xs,
      runSpacing: UiSpace.xs,
      children: [
        for (final emoji in reactionEmojis)
          if (widget.enabled || counts[emoji]! > 0)
            _ReactionChip(
              key: ValueKey('groups-react-${widget.checkInId}-$emoji'),
              emoji: emoji,
              count: counts[emoji]!,
              selected: mine == emoji,
              semanticLabel: l10n.groups_reactSemantics(emoji, counts[emoji]!),
              onTap: widget.enabled && _pending == null
                  ? () => _toggle(emoji, mine)
                  : null,
            ),
      ],
    );
  }
}

/// `.reactions button`: 48dp bordered emoji button; selected = ink border.
class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final String emoji;
  final int count;
  final bool selected;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    return UiPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      centerChild: true,
      borderRadius: BorderRadius.circular(UiRadius.input),
      child: Container(
        constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? ui.fill : ui.surface,
          borderRadius: BorderRadius.circular(UiRadius.input),
          border: Border.all(
            color: selected ? ui.ink : ui.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(fontSize: 16),
            ),
            if (count > 0) ...[
              const SizedBox(width: 3),
              Text(
                '$count',
                style: UiText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  height: 1.3,
                  color: ui.ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
