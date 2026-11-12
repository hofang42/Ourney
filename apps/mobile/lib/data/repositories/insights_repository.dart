import 'package:ourney_core/ourney_core.dart';

import '../social_context.dart';
import '../social_mapping.dart';

/// [InsightsRepository] over the v1.3 RPCs (S16, S19–S21).
class DataInsightsRepository implements InsightsRepository {
  DataInsightsRepository(this.social);

  final SocialContext social;

  void refresh() => social.changed();

  /// Polled, refreshed after any social mutation and on every new message
  /// (Supabase Realtime, RLS-filtered to the caller's conversations).
  @override
  Stream<InboxCounts> watchInboxCounts() => social.watch(
    () => social.call('inbox_counts', const {}, inboxCountsFromJson),
    extraTriggers: () => [social.remote.watchInserts('messages')],
  );

  @override
  Future<JourneyInsights> journeyInsights(String journeyId) => social.call(
    'journey_insights',
    {'p_journey': journeyId},
    insightsFromJson,
  );

  @override
  Future<int> myReach() => social.call(
    'my_reach',
    const {},
    (json) => switch (json) {
      final num n => n.toInt(),
      null => 0,
      _ => int.parse('$json'),
    },
  );
}
