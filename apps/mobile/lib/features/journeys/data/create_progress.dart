import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Where the create flow was left (Figma `store.createProgress`): the Hub
/// shows a "Continue creating a journey" card while this is set, and the
/// flow reopens on that step with the saved answers ([draft]) (U8).
abstract final class CreateProgressPrefs {
  static const key = 'journeys.createProgressStep';

  /// JSON of the flow's answers (see `CreateFlowScreen`).
  static const draftKey = 'journeys.createProgressDraft';
}

class CreateProgressController extends Notifier<int?> {
  @override
  int? build() {
    final step = ref
        .watch(sharedPreferencesProvider)
        .getInt(CreateProgressPrefs.key);
    return step != null && step >= 2 && step <= 5 ? step : null;
  }

  /// The saved answers, or null when there is none (or it is unreadable).
  Map<String, Object?>? readDraft() {
    if (state == null) return null;
    final raw = ref
        .read(sharedPreferencesProvider)
        .getString(CreateProgressPrefs.draftKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      return map is Map<String, Object?> ? map : null;
    } on FormatException {
      return null;
    }
  }

  /// [step] is the 1-based step shown in the header ("step 3/5"); [draft]
  /// holds the answers to restore it with.
  Future<void> save(int step, {Map<String, Object?>? draft}) async {
    if (step < 2 || step > 5) {
      await clear();
      return;
    }
    state = step;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(CreateProgressPrefs.key, step);
    if (draft == null) {
      await prefs.remove(CreateProgressPrefs.draftKey);
    } else {
      await prefs.setString(CreateProgressPrefs.draftKey, jsonEncode(draft));
    }
  }

  Future<void> clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (state != null) state = null;
    await prefs.remove(CreateProgressPrefs.key);
    await prefs.remove(CreateProgressPrefs.draftKey);
  }
}

final createProgressProvider = NotifierProvider<CreateProgressController, int?>(
  CreateProgressController.new,
);
