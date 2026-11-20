import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/repositories/account_insights_repository.dart';
import 'package:ourney_core/ourney_core.dart';

import 'data_test_helpers.dart';

void main() {
  const quiz = OnboardingQuiz(reminder: '20:00');

  test('L3 saveQuiz reports a missing profile row instead of succeeding', () {
    final remote = FakeRemoteApi()..updateResult = const [];
    final repo = SupabaseAccountInsightsRepository(remote);
    expect(
      repo.saveQuiz(quiz),
      throwsA(
        isA<OurneyException>().having(
          (e) => e.error,
          'error',
          OurneyErrorCode.notFound,
        ),
      ),
    );
  });

  test('L3 saveQuiz succeeds when the profile row was updated', () async {
    final remote = FakeRemoteApi();
    await SupabaseAccountInsightsRepository(remote).saveQuiz(quiz);
    expect(remote.callsOf('update'), hasLength(1));
  });
}
