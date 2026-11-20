import 'package:ourney_core/ourney_core.dart';

import '../remote/remote_api.dart';

/// [AccountInsightsRepository] over RPC `profile_stats` and the caller's own
/// `profiles.onboarding_quiz` column (RLS: self only for writes).
class SupabaseAccountInsightsRepository implements AccountInsightsRepository {
  SupabaseAccountInsightsRepository(this.remote);

  final RemoteApi remote;

  String get _uid {
    final id = remote.currentUserId;
    if (id == null) {
      throw const OurneyException(OurneyErrorCode.unauthenticated);
    }
    return id;
  }

  @override
  Future<ProfileStats> fetchStats() async {
    _uid;
    return ProfileStats.fromJson(await remote.rpc('profile_stats'));
  }

  @override
  Future<OnboardingQuiz?> fetchQuiz() async {
    final rows = await remote.select('profiles', eq: {'id': _uid}, limit: 1);
    if (rows.isEmpty) return null;
    return OnboardingQuiz.fromJson(rows.first['onboarding_quiz']);
  }

  @override
  Future<void> saveQuiz(OnboardingQuiz quiz) async {
    final rows = await remote.update(
      'profiles',
      {'onboarding_quiz': quiz.toJson()},
      match: {'id': _uid},
    );
    // A new account has no profile row until the setup screen upserts it:
    // an update that matches nothing is a failed save, not a success.
    if (rows.isEmpty) throw const OurneyException(OurneyErrorCode.notFound);
  }
}
