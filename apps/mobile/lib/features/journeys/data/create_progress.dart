import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Where the create flow was left (Figma `store.createProgress`): the Hub
/// shows a "Continue creating a journey" card while this is set. Only the
/// step is kept; the flow itself restarts from the type choice.
abstract final class CreateProgressPrefs {
  static const key = 'journeys.createProgressStep';
}

class CreateProgressController extends Notifier<int?> {
  @override
  int? build() {
    final step = ref
        .watch(sharedPreferencesProvider)
        .getInt(CreateProgressPrefs.key);
    return step != null && step >= 2 && step <= 5 ? step : null;
  }

  /// [step] is the 1-based step shown in the header ("step 3/5").
  Future<void> save(int step) async {
    if (step < 2 || step > 5) {
      await clear();
      return;
    }
    state = step;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(CreateProgressPrefs.key, step);
  }

  Future<void> clear() async {
    if (state == null) return;
    state = null;
    await ref.read(sharedPreferencesProvider).remove(CreateProgressPrefs.key);
  }
}

final createProgressProvider = NotifierProvider<CreateProgressController, int?>(
  CreateProgressController.new,
);
