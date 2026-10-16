import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../app/theme/motion.dart';
import '../../../app/theme/tokens.dart';
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
    final c = OurneyColors.of(context);
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
      spacing: OurneySpacing.xs,
      runSpacing: OurneySpacing.xs,
      children: [
        for (final emoji in reactionEmojis)
          if (widget.enabled || counts[emoji]! > 0)
            _ReactionChip(
              key: ValueKey('groups-react-${widget.checkInId}-$emoji'),
              emoji: emoji,
              count: counts[emoji]!,
              selected: mine == emoji,
              semanticLabel: l10n.groups_reactSemantics(emoji, counts[emoji]!),
              color: c,
              onTap: widget.enabled && _pending == null
                  ? () => _toggle(emoji, mine)
                  : null,
            ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String emoji;
  final int count;
  final bool selected;
  final String semanticLabel;
  final OurneyColors color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(OurneyRadii.capsule);
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: selected ? color.accent.withValues(alpha: 0.18) : color.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? color.accent : color.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: OurneySizes.minTap,
              minWidth: OurneySizes.minTap,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: OurneySpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(fontSize: 20),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 2),
                    Text('$count', style: text.labelLarge),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
