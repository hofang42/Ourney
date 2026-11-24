import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../ui/ui.dart';
import '../l10n/generated/profile_localizations.dart';
import '../profile_providers.dart';

/// Figma `profile-stats` + `profile-badges`: total check-ins, longest streak,
/// finished journeys, and the steady-habit badge shelf (tap a badge to read
/// its rule). Numbers come from the server RPC when signed in and from this
/// device otherwise (see [profileStatsProvider]). While loading or on error
/// the zeros of an empty profile are shown: the section never blocks the
/// screen.
class ProfileStatsSection extends ConsumerStatefulWidget {
  const ProfileStatsSection({super.key});

  @override
  ConsumerState<ProfileStatsSection> createState() =>
      _ProfileStatsSectionState();
}

class _ProfileStatsSectionState extends ConsumerState<ProfileStatsSection> {
  BadgeId? _selected;

  static String _name(ProfileL10n l10n, BadgeId id) => switch (id) {
    BadgeId.streak7 => l10n.profile_badge7,
    BadgeId.streak30 => l10n.profile_badge30,
    BadgeId.firstFinish => l10n.profile_badgeFinish,
    BadgeId.days100 => l10n.profile_badge100,
  };

  static String _rule(ProfileL10n l10n, BadgeId id) => switch (id) {
    BadgeId.streak7 => l10n.profile_badge7Rule,
    BadgeId.streak30 => l10n.profile_badge30Rule,
    BadgeId.firstFinish => l10n.profile_badgeFinishRule,
    BadgeId.days100 => l10n.profile_badge100Rule,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = ProfileL10n.of(context);
    final ui = context.ui;
    final stats = ref.watch(profileStatsProvider).value ?? const ProfileStats();
    final badges = badgesFor(stats);
    return Column(
      key: const ValueKey('profile-stats'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bug 6: labels wrap to different line counts ("Chuỗi dài nhất" vs
        // "Hành trình đã xong"), so each tile took its own height. Stretch
        // the three tiles to the tallest one; Expanded keeps equal widths.
        IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (key, value, label) in [
              ('snaps', stats.totalSnaps, l10n.profile_statSnaps),
              ('longest', stats.longestStreak, l10n.profile_statLongest),
              ('done', stats.journeysCompleted, l10n.profile_statDone),
            ]) ...[
              Expanded(
                child: UiCard(
                  key: ValueKey('profile-stat-$key'),
                  radius: UiRadius.card,
                  padding: const EdgeInsets.symmetric(
                    horizontal: UiSpace.sm,
                    vertical: UiSpace.md,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$value',
                        maxLines: 1,
                        style: UiText.h1(size: 26, color: ui.ink),
                      ),
                      const SizedBox(height: UiSpace.xs),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.body(
                          size: 12,
                          height: 1.4,
                          color: ui.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (key != 'done') const SizedBox(width: UiSpace.sm),
            ],
          ],
          ),
        ),
        const SizedBox(height: UiSpace.xl),
        UiListHeading(title: l10n.profile_badgesTitle),
        Wrap(
          key: const ValueKey('profile-badges'),
          spacing: UiSpace.sm,
          runSpacing: UiSpace.sm,
          children: [
            for (final badge in badges)
              Semantics(
                button: true,
                label:
                    '${_name(l10n, badge.id)}, ${badge.unlocked ? l10n.profile_badgeUnlocked : l10n.profile_badgeLocked}',
                excludeSemantics: true,
                child: UiChip(
                  key: ValueKey('profile-badge-${badge.id.name}'),
                  label: _name(l10n, badge.id),
                  glyph: OurneyIcon(
                    name: badge.unlocked ? 'check' : 'lock',
                    flat: true,
                  ),
                  selected: badge.unlocked,
                  onPressed: () => setState(() => _selected = badge.id),
                ),
              ),
          ],
        ),
        if (_selected != null) ...[
          const SizedBox(height: UiSpace.sm),
          Text(
            _rule(l10n, _selected!),
            key: const ValueKey('profile-badge-rule'),
            style: UiText.muted(color: ui.inkMuted, size: 14),
          ),
        ],
      ],
    );
  }
}
