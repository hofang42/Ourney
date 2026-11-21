import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ourney_core/ourney_core.dart';

import '../../app/providers.dart';
import '../profile/profile_providers.dart';

/// The onboarding quiz answers (FR-A3 v2).
///
/// Stored locally in shared preferences (works signed out / local-only) and,
/// once signed in, mirrored to `profiles.onboarding_quiz` through
/// [AccountInsightsRepository]. The server copy is best effort: a failed save
/// never blocks the UI and is retried by [syncToServer] on the next sign-in.
class OnboardingQuizNotifier extends Notifier<OnboardingQuiz?> {
  static const prefsKey = 'app.onboardingQuiz';

  @override
  OnboardingQuiz? build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(prefsKey);
    if (raw == null) return null;
    try {
      return OnboardingQuiz.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  /// Saves [quiz] locally and, when signed in, on the server.
  Future<void> save(OnboardingQuiz quiz) async {
    state = quiz;
    await ref
        .read(sharedPreferencesProvider)
        .setString(prefsKey, jsonEncode(quiz.toJson()));
    await syncToServer();
  }

  /// Local answers win; when there are none, adopts the server copy (new
  /// device). Never throws.
  Future<void> syncToServer() async {
    final repo = ref.read(accountInsightsRepositoryProvider);
    if (repo == null || ref.read(currentUserIdProvider) == null) return;
    try {
      final local = state;
      if (local != null && !local.isEmpty) {
        await repo.saveQuiz(local);
        return;
      }
      final remote = await repo.fetchQuiz();
      if (remote != null && !remote.isEmpty) {
        state = remote;
        await ref
            .read(sharedPreferencesProvider)
            .setString(prefsKey, jsonEncode(remote.toJson()));
      }
    } on Object catch (e) {
      // Offline or the profile row does not exist yet: retried later (after
      // the profile is saved, and on the next sign-in).
      debugPrint('onboarding: quiz sync skipped: $e');
    }
  }

  /// Account deletion: forget the answers on this device.
  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(prefsKey);
  }
}

final onboardingQuizProvider =
    NotifierProvider<OnboardingQuizNotifier, OnboardingQuiz?>(
      OnboardingQuizNotifier.new,
    );

/// Default template / skin / kind / reminder for the create-journey form,
/// derived from the quiz. Null when the user skipped it.
final journeySuggestionProvider = Provider<JourneySuggestion?>(
  (ref) => ref.watch(onboardingQuizProvider)?.suggestion,
);
