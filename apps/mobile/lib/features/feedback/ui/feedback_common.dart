import 'package:flutter/material.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../ui/ui.dart';
import '../data/feedback_providers.dart';
import '../l10n/generated/feedback_localizations.dart';

/// Localized label for a [FeatureRequestCategory].
String feedbackCategoryLabel(
  FeedbackL10n l10n,
  FeatureRequestCategory category,
) =>
    switch (category) {
      FeatureRequestCategory.camera => l10n.feedback_catCamera,
      FeatureRequestCategory.journeys => l10n.feedback_catJourneys,
      FeatureRequestCategory.squad => l10n.feedback_catSquad,
      FeatureRequestCategory.sharing => l10n.feedback_catSharing,
      FeatureRequestCategory.design => l10n.feedback_catDesign,
      FeatureRequestCategory.other => l10n.feedback_catOther,
    };

/// Localized label for a [FeatureRequestStatus].
String feedbackStatusLabel(FeedbackL10n l10n, FeatureRequestStatus status) =>
    switch (status) {
      FeatureRequestStatus.newRequest => l10n.feedback_statusNew,
      FeatureRequestStatus.underReview => l10n.feedback_statusUnderReview,
      FeatureRequestStatus.planned => l10n.feedback_statusPlanned,
      FeatureRequestStatus.inProgress => l10n.feedback_statusInProgress,
      FeatureRequestStatus.shipped => l10n.feedback_statusShipped,
      FeatureRequestStatus.declined => l10n.feedback_statusDeclined,
    };

/// User-facing error string for a feature request error.
String feedbackErrorMessage(
  BuildContext context,
  Object error, {
  bool forCreate = false,
}) {
  final l10n = FeedbackL10n.of(context);
  final app = AppLocalizations.of(context);
  return switch (feedbackErrorCode(error)) {
    OurneyErrorCode.contentPolicy => l10n.feedback_errorContentPolicy,
    OurneyErrorCode.linksNotAllowed => l10n.feedback_errorLinksNotAllowed,
    OurneyErrorCode.rateLimited => forCreate
        ? l10n.feedback_errorRateLimited
        : l10n.feedback_errorRateLimitedAction,
    OurneyErrorCode.ended => l10n.feedback_errorVoteLocked,
    OurneyErrorCode.notFound => l10n.feedback_errorNotFound,
    OurneyErrorCode.serverOutdated => app.common_serverOutdated,
    OurneyErrorCode.offline => app.common_offline,
    _ => app.common_errorGeneric,
  };
}

/// Formats a UTC timestamp into a short local date string (`16/10/2026`).
String formatFeedbackDate(BuildContext context, DateTime instant) {
  final local = instant.toLocal();
  return MaterialLocalizations.of(context).formatCompactDate(local);
}

/// High-contrast status [UiTag] for Light and Dark mode (WCAG 2.2 AA >= 4.5:1).
class FeedbackStatusTag extends StatelessWidget {
  const FeedbackStatusTag({required this.status, super.key});

  final FeatureRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = FeedbackL10n.of(context);
    final ui = context.ui;
    final (Color bg, Color fg, Color border, Widget? glyph) = switch (status) {
      FeatureRequestStatus.shipped => (
          ui.successSoft,
          ui.success,
          ui.success,
          OurneyIcon(name: 'check', size: 12, flat: true, color: ui.success),
        ),
      FeatureRequestStatus.inProgress => (
          ui.brand,
          ui.onBrand,
          ui.outline,
          OurneyIcon(name: 'sparkle', size: 12, flat: true, color: ui.onBrand),
        ),
      FeatureRequestStatus.planned => (
          ui.fillSelected,
          ui.ink,
          ui.outline,
          OurneyIcon(name: 'clock', size: 12, flat: true, color: ui.ink),
        ),
      FeatureRequestStatus.underReview => (
          ui.fill,
          ui.inkSoft,
          ui.outline,
          null,
        ),
      FeatureRequestStatus.declined => (
          ui.fill,
          ui.inkMuted,
          ui.border,
          null,
        ),
      FeatureRequestStatus.newRequest => (
          ui.surface,
          ui.inkSoft,
          ui.outline,
          null,
        ),
    };
    return UiTag(
      label: feedbackStatusLabel(l10n, status),
      background: bg,
      foreground: fg,
      borderColor: border,
      glyph: glyph,
    );
  }
}

/// Outlined category [UiTag].
class FeedbackCategoryTag extends StatelessWidget {
  const FeedbackCategoryTag({required this.category, super.key});

  final FeatureRequestCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = FeedbackL10n.of(context);
    final ui = context.ui;
    return UiTag(
      label: feedbackCategoryLabel(l10n, category),
      background: ui.surface,
      foreground: ui.inkSoft,
      borderColor: ui.outline,
    );
  }
}

/// Tag indicating an official reply from Ourney team is present.
class FeedbackOfficialReplyTag extends StatelessWidget {
  const FeedbackOfficialReplyTag({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = FeedbackL10n.of(context);
    final ui = context.ui;
    return UiTag(
      label: l10n.feedback_officialReplyBadge,
      background: ui.fill,
      foreground: ui.ink,
      borderColor: ui.brand,
      glyph: OurneyIcon(name: 'sparkle', size: 12, flat: true, color: ui.ink),
    );
  }
}

/// Tactile Neo-Brutalist upvote pill (`minSize: Size(48, 56)`).
class VotePill extends StatelessWidget {
  const VotePill({
    required this.item,
    required this.onVote,
    super.key,
  });

  final FeatureRequest item;
  final VoidCallback? onVote;

  @override
  Widget build(BuildContext context) {
    final l10n = FeedbackL10n.of(context);
    final ui = context.ui;
    final canVote = item.canVote;
    final voted = item.votedByMe;

    final Color bg;
    final Color fg;
    if (!canVote) {
      bg = item.isShipped ? ui.successSoft : ui.surface;
      fg = item.isShipped ? ui.success : ui.inkMuted;
    } else if (voted) {
      bg = ui.brand;
      fg = ui.onBrand;
    } else {
      bg = ui.fill;
      fg = ui.ink;
    }

    final stateLabel = voted
        ? l10n.feedback_voteStateVoted
        : l10n.feedback_voteStateNotVoted;

    return UiPressable(
      key: ValueKey('feedback-vote-${item.id}'),
      onPressed: canVote ? onVote : null,
      selected: voted,
      shadowOffset: canVote ? UiShadow.tiny : 0,
      minSize: const Size(UiSize.tap, 56),
      borderRadius: BorderRadius.circular(14),
      semanticLabel: l10n.feedback_voteSemantics(
        item.title,
        item.voteCount,
        stateLabel,
      ),
      excludeChildSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: UiSize.tap, minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: !canVote && item.isShipped ? ui.success : ui.outline,
            width: UiBorder.thin,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OurneyIcon(
              name: item.isShipped ? 'check' : 'chevron-up',
              size: 16,
              flat: true,
              color: fg,
            ),
            const SizedBox(height: 2),
            Text(
              '${item.voteCount}',
              maxLines: 1,
              style: UiText.display(
                size: 14,
                weight: 800,
                height: 1.2,
                color: fg,
              ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single feature request row card on the `/feedback` board.
class FeatureRequestCard extends StatelessWidget {
  const FeatureRequestCard({
    required this.item,
    required this.onTap,
    required this.onVote,
    this.showNewStatus = false,
    super.key,
  });

  final FeatureRequest item;
  final VoidCallback onTap;
  final VoidCallback onVote;
  final bool showNewStatus;

  @override
  Widget build(BuildContext context) {
    final ui = context.ui;
    final showStatus =
        showNewStatus || item.status != FeatureRequestStatus.newRequest;

    return UiCard(
      key: ValueKey('feedback-card-${item.id}'),
      radius: UiRadius.menu,
      shadowOffset: UiShadow.small,
      padding: const EdgeInsets.all(UiSpace.md),
      onPressed: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VotePill(item: item, onVote: onVote),
          const SizedBox(width: UiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.35,
                    color: ui.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.body(
                    size: 13,
                    height: 1.4,
                    color: ui.inkMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (showStatus) FeedbackStatusTag(status: item.status),
                    FeedbackCategoryTag(category: item.category),
                    if (item.adminReply != null)
                      const FeedbackOfficialReplyTag(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
