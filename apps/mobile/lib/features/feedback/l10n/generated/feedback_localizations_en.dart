// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'feedback_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class FeedbackL10nEn extends FeedbackL10n {
  FeedbackL10nEn([String locale = 'en']) : super(locale);

  @override
  String get feedback_title => 'ideas.';

  @override
  String get feedback_detailTitle => 'idea.';

  @override
  String get feedback_newAction => 'Suggest a feature';

  @override
  String get feedback_moreOptions => 'More options';

  @override
  String get feedback_tabPopular => 'Popular';

  @override
  String get feedback_tabNew => 'New';

  @override
  String get feedback_tabPlanned => 'Planned';

  @override
  String get feedback_tabShipped => 'Shipped';

  @override
  String get feedback_chipMine => 'My requests';

  @override
  String get feedback_catAll => 'All';

  @override
  String get feedback_catCamera => 'Camera & Check-in';

  @override
  String get feedback_catJourneys => 'Journeys';

  @override
  String get feedback_catSquad => 'Squads';

  @override
  String get feedback_catSharing => 'Sharing';

  @override
  String get feedback_catDesign => 'Design';

  @override
  String get feedback_catOther => 'Other';

  @override
  String get feedback_statusNew => 'New';

  @override
  String get feedback_statusUnderReview => 'Under review';

  @override
  String get feedback_statusPlanned => 'Planned';

  @override
  String get feedback_statusInProgress => 'In progress';

  @override
  String get feedback_statusShipped => 'Shipped';

  @override
  String get feedback_statusDeclined => 'Not planned';

  @override
  String get feedback_searchLabel => 'Search ideas';

  @override
  String get feedback_searchHint => 'Search ideas or features…';

  @override
  String get feedback_searchClear => 'Clear search';

  @override
  String get feedback_newCta => 'Suggest a feature';

  @override
  String get feedback_officialReplyBadge => 'Ourney reply';

  @override
  String get feedback_officialReplyEyebrow => 'FROM OURNEY';

  @override
  String feedback_voteButton(int count) {
    return 'Upvote · $count';
  }

  @override
  String feedback_votedButton(int count) {
    return 'Upvoted · $count';
  }

  @override
  String feedback_voteSemantics(String title, int count, String state) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$title, $count votes, $state',
      one: '$title, 1 vote, $state',
    );
    return '$_temp0';
  }

  @override
  String get feedback_voteStateVoted => 'upvoted';

  @override
  String get feedback_voteStateNotVoted => 'not upvoted';

  @override
  String feedback_shippedVotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shipped · $count votes',
      one: 'Shipped · 1 vote',
    );
    return '$_temp0';
  }

  @override
  String get feedback_editedBadge => 'Edited';

  @override
  String get feedback_authorEditHint =>
      'You can edit or delete this idea until Ourney starts reviewing it.';

  @override
  String get feedback_editAction => 'Edit idea';

  @override
  String get feedback_deleteAction => 'Delete idea';

  @override
  String get feedback_deleteTitle => 'Delete this idea?';

  @override
  String get feedback_deleteBody =>
      'Your idea will be permanently removed from the community board.';

  @override
  String get feedback_deleteConfirm => 'Delete idea';

  @override
  String get feedback_deletedToast => 'Idea deleted.';

  @override
  String get feedback_createSheetTitle => 'suggest an idea.';

  @override
  String get feedback_editSheetTitle => 'edit idea.';

  @override
  String get feedback_createSheetSub =>
      'Ideas are visible to everyone signed in so the community can vote.';

  @override
  String get feedback_fieldTitleLabel => 'Idea title';

  @override
  String get feedback_fieldTitleHint => 'e.g. Lock-screen streak widget';

  @override
  String get feedback_fieldCategoryLabel => 'Category';

  @override
  String get feedback_fieldBodyLabel => 'Details';

  @override
  String get feedback_fieldBodyHint =>
      'Tell us how this would make your daily habit easier…';

  @override
  String get feedback_similarHeading => 'Similar ideas already posted:';

  @override
  String feedback_similarVoteChip(int count) {
    return '+1 ($count)';
  }

  @override
  String get feedback_bugEmailLink =>
      'Reporting a private bug with screenshots? Contact support';

  @override
  String get feedback_submitAction => 'Post idea';

  @override
  String get feedback_saveChanges => 'Save changes';

  @override
  String get feedback_createdToast => 'Idea posted with your upvote!';

  @override
  String get feedback_updatedToast => 'Idea updated.';

  @override
  String get feedback_mergedBanner =>
      'This idea and its votes were merged into an existing request.';

  @override
  String get feedback_mergedOpenTarget => 'View main idea';

  @override
  String get feedback_reportAction => 'Report idea';

  @override
  String get feedback_reportTitle => 'Report idea';

  @override
  String get feedback_reportedToast =>
      'Report sent. This idea is now hidden on your device.';

  @override
  String get feedback_blockAuthorAction => 'Block author';

  @override
  String get feedback_anonymousAuthor => 'Ourney member';

  @override
  String get feedback_emptyPopularTitle => 'no ideas yet.';

  @override
  String get feedback_emptyPopularBody =>
      'What should Ourney build next? Be the first to share an idea.';

  @override
  String get feedback_emptyPopularCta => 'Suggest the first idea';

  @override
  String get feedback_emptyPlannedTitle => 'nothing planned yet.';

  @override
  String get feedback_emptyPlannedBody =>
      'Top-voted community ideas will move onto the roadmap soon.';

  @override
  String get feedback_emptyShippedTitle =>
      'first shipped features coming soon.';

  @override
  String get feedback_emptyShippedBody =>
      'Whenever a community idea ships, you\'ll see it celebrated here.';

  @override
  String get feedback_emptyMineTitle => 'you haven\'t posted an idea yet.';

  @override
  String get feedback_emptyMineBody =>
      'Ideas you post will show up here so you can track their progress.';

  @override
  String get feedback_emptySearchTitle => 'no matching ideas.';

  @override
  String get feedback_emptySearchBody =>
      'You can turn this search into a new idea for the community.';

  @override
  String get feedback_emptySearchCta => 'Post this idea';

  @override
  String get feedback_loadMore => 'Load more ideas';

  @override
  String get feedback_endOfList => 'You\'ve reached the end';

  @override
  String get feedback_offlineStrip => 'Viewing saved ideas.';

  @override
  String get feedback_comingSoonTitle => 'feature board coming soon.';

  @override
  String get feedback_comingSoonBody =>
      'The server is being updated with the feature voting board. Please check back soon!';

  @override
  String get feedback_errorTitleLength =>
      'Title must be between 6 and 80 characters.';

  @override
  String get feedback_errorBodyLength =>
      'Details must be between 10 and 1000 characters.';

  @override
  String get feedback_errorContentPolicy =>
      'This text contains language that goes against Ourney\'s community guidelines.';

  @override
  String get feedback_errorLinksNotAllowed =>
      'Please don\'t include web links in feature ideas.';

  @override
  String get feedback_errorRateLimited =>
      'You\'ve reached the limit of 5 ideas in 24 hours. Upvote existing ones in the meantime!';

  @override
  String get feedback_errorRateLimitedAction =>
      'You\'re tapping a bit fast, wait a moment and try again.';

  @override
  String get feedback_errorOfflineDraftSaved =>
      'You\'re offline. Your draft is saved right here.';

  @override
  String get feedback_errorVoteLocked => 'Voting is closed for this idea.';

  @override
  String get feedback_errorNotFound =>
      'This idea no longer exists or is hidden.';
}
