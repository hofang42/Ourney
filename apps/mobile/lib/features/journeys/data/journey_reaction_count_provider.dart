import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/data_providers.dart';

/// Server count of live reactions on the journey's visible check-ins.
/// Local-only and signed-out sessions have no count.
final journeyReactionCountProvider = FutureProvider.autoDispose
    .family<int?, String>((ref, journeyId) async {
      if (ref.watch(currentUserIdProvider) == null) return null;
      final remote = ref.watch(dataLayerProvider).ctx.remote;
      if (remote == null) return null;
      final count = await remote.rpc('journey_reaction_count', {
        'p_journey': journeyId,
      });
      return count as int?;
    }, retry: (_, _) => null);
