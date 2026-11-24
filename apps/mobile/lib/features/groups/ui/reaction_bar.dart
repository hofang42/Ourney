import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../app/providers.dart';
import '../../../ui/ui.dart';
import '../data/groups_providers.dart';
import '../domain/group_today.dart';
import '../l10n/generated/groups_localizations.dart';
import 'group_errors.dart';

/// Emoji reactions on one check-in (FR-D4): 🔥 💪 👏 ❤️ 😂, one per person
/// (tapping another emoji replaces it, tapping yours removes it). No
/// comments in v1. [enabled] is false for the caller's own photo and once
/// the journey has ended (counts stay visible).
///
/// Unified onto [UiReactionSpark] + [UiCountRoll] (`lib/ui/components/reaction_bar.dart`)
/// with non-blocking per-emoji debounce so rapid celebratory tapping across
/// reactions never locks the bar while a network write is in flight.
class ReactionBar extends ConsumerStatefulWidget {
  const ReactionBar({required this.checkInId, this.enabled = true, super.key});

  final String checkInId;
  final bool enabled;

  @override
  ConsumerState<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends ConsumerState<ReactionBar> {
  /// Whether [_optimisticMine] currently overrides the stream's `summary.mine`.
  bool _hasOptimistic = false;

  /// Optimistic reaction while a write is in flight (`null` = unreacted).
  String? _optimisticMine;

  /// Per-emoji in-flight debounce set so tapping one reaction never blocks
  /// tapping any other reaction pill immediately.
  final Set<String> _pendingEmojis = <String>{};

  int _writeSeq = 0;

  Future<void> _toggle(String emoji, String? currentMine) async {
    if (_pendingEmojis.contains(emoji)) return;
    final repo = ref.read(groupRepositoryProvider);
    final removing = currentMine == emoji;
    final seq = ++_writeSeq;
    setState(() {
      _pendingEmojis
        ..clear()
        ..add(emoji);
      _hasOptimistic = true;
      _optimisticMine = removing ? null : emoji;
    });
    try {
      if (removing) {
        await repo.unreact(widget.checkInId);
      } else {
        await repo.react(widget.checkInId, emoji);
      }
    } on Object catch (e) {
      if (mounted && seq == _writeSeq) {
        setState(() {
          _hasOptimistic = false;
          _optimisticMine = null;
        });
        showGroupSnack(context, groupErrorMessage(context, e));
      }
    } finally {
      if (mounted && seq == _writeSeq) {
        setState(() {
          _pendingEmojis.clear();
          _hasOptimistic = false;
          _optimisticMine = null;
        });
      } else {
        _pendingEmojis.remove(emoji);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final myId = ref.watch(currentUserIdProvider);
    final blocked = ref.watch(groupBlockedIdsProvider).value ?? const {};
    final reactionsAsync = ref.watch(groupReactionsProvider(widget.checkInId));
    final hydrated = reactionsAsync.hasValue;
    final reactions = reactionsAsync.value ?? const <Reaction>[];
    final summary = ReactionSummary.of(
      reactions,
      myUserId: myId,
      blockedIds: blocked,
    );
    final counts = Map.of(summary.counts);
    var mine = summary.mine;
    if (_hasOptimistic) {
      // Optimistic: move the caller's reaction before the stream catches up.
      if (mine != null) counts[mine] = math.max(0, counts[mine]! - 1);
      mine = _optimisticMine;
      if (mine != null) counts[mine] = (counts[mine] ?? 0) + 1;
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
              hydrated: hydrated,
              selected: mine == emoji,
              semanticLabel: l10n.groups_reactSemantics(emoji, counts[emoji]!),
              onTap: widget.enabled && !_pendingEmojis.contains(emoji)
                  ? () => _toggle(emoji, mine)
                  : null,
            ),
      ],
    );
  }
}

/// Stored emoji -> Ourney sticker icon id (`react-<id>`); the emoji itself is
/// only the persisted value, never drawn in the UI.
const Map<String, String> _reactionIconId = {
  '🔥': 'fire',
  '💪': 'flex',
  '👏': 'clap',
  '❤️': 'heart',
  '😂': 'laugh',
};

/// `.reactions button`: 48dp bordered reaction button powered by
/// [UiReactionSpark] + [UiCountRoll]; selected = `2dp` `ui.accent` border.
class _ReactionChip extends StatefulWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.hydrated,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final String emoji;
  final int count;
  final bool hydrated;
  final bool selected;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  State<_ReactionChip> createState() => _ReactionChipState();
}

class _ReactionChipState extends State<_ReactionChip> {
  final GlobalKey<UiReactionSparkState> _sparkKey =
      GlobalKey<UiReactionSparkState>();
  late int _prevCount;
  late bool _wasHydrated;

  @override
  void initState() {
    super.initState();
    _prevCount = widget.count;
    _wasHydrated = widget.hydrated;
  }

  @override
  void didUpdateWidget(covariant _ReactionChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_wasHydrated && widget.hydrated) {
      _wasHydrated = true;
      _prevCount = widget.count;
    } else if (widget.count != oldWidget.count) {
      _prevCount = oldWidget.count;
    }
  }

  void _handlePress() {
    final cb = widget.onTap;
    if (cb == null) return;
    _sparkKey.currentState?.trigger(adding: !widget.selected);
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final iconId = _reactionIconId[widget.emoji] ?? 'heart';
    final selected = widget.selected;
    final count = widget.count;
    return UiPressable(
      onPressed: widget.onTap == null ? null : _handlePress,
      selected: selected,
      semanticLabel: widget.semanticLabel,
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
            color: selected ? ui.accent : ui.border,
            width: selected ? UiBorder.standard : UiBorder.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiReactionSpark(
              key: _sparkKey,
              id: iconId,
              selected: selected,
              child: OurneyIcon(name: 'react-$iconId', size: 20),
            ),
            if (count > 0) ...[
              const SizedBox(width: 3),
              UiCountRoll(
                value: count,
                initialValue: _prevCount,
                duration: UiMotion.normal,
                curve: UiCurves.easeOutStrong,
                slideDistance: 8.0,
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
