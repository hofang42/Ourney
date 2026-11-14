import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../ui/ui.dart';
import '../l10n/generated/groups_localizations.dart';

/// Type-badge id of a wire `template_id` (`UiTypeBadge.ids`).
String groupTypeBadgeId(String templateId) => switch (templateId) {
  'weight_loss' => 'weight',
  'english_daily' => 'study',
  'travel' => 'trip',
  'couple' => 'couple',
  'workout30' => 'workout',
  _ => 'custom',
};

/// Figma `.join-ticket-preview`: group name, owner, members/length/progress
/// and the rules, shown before the caller confirms a join.
class GroupPreviewCard extends StatelessWidget {
  const GroupPreviewCard({required this.preview, super.key});

  final GroupPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = GroupsL10n.of(context);
    final ui = context.ui;
    final total = preview.durationDays;
    final stats = <(String, String)>[
      (
        l10n.groups_previewMembers,
        l10n.groups_previewMembersValue(
          preview.memberCount,
          preview.maxMembers,
        ),
      ),
      (
        l10n.groups_previewDuration,
        total == null
            ? l10n.groups_previewDurationOpen
            : l10n.groups_previewDurationValue(total),
      ),
      (
        l10n.groups_previewProgress,
        total == null
            ? l10n.groups_previewProgressOpen(preview.dayNumber)
            : l10n.groups_previewProgressValue(preview.dayNumber, total),
      ),
    ];
    return UiCard(
      key: const ValueKey('groups-join-preview'),
      radius: UiRadius.menu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UiTypeBadge(type: groupTypeBadgeId(preview.templateId), size: 44),
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.h2(color: ui.ink).copyWith(height: 1.3),
                    ),
                    Text(
                      l10n.groups_previewOwner(preview.ownerName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 13,
                        height: 1.4,
                        color: ui.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpace.md),
          for (final (label, value) in stats)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: UiText.body(
                        size: 13,
                        height: 1.4,
                        color: ui.inkMuted,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.body(
                        size: 14,
                        height: 1.4,
                        weight: FontWeight.w700,
                        color: ui.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (preview.members.isNotEmpty) ...[
            const SizedBox(height: UiSpace.sm),
            Wrap(
              spacing: UiSpace.xs,
              children: [
                for (final m in preview.members)
                  UiAvatar(
                    name: m.displayName,
                    colorIndex: UiAvatar.indexFor(m.displayName),
                    size: 32,
                  ),
              ],
            ),
          ],
          const SizedBox(height: UiSpace.md),
          Text(
            l10n.groups_joinRules,
            style: UiText.body(size: 13, height: 1.5, color: ui.ink),
          ),
          const SizedBox(height: UiSpace.xs),
          Text(
            l10n.groups_previewPrivate,
            style: UiText.body(size: 13, height: 1.5, color: ui.inkMuted),
          ),
        ],
      ),
    );
  }
}
