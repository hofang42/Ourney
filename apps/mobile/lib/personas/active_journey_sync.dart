import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';

/// Makes [journeyId] the active journey while its screen is open, so the
/// dock, the camera chip and the app theme follow the journey the user is
/// looking at (a detail page opened from the Hub, a group opened from the
/// Squad tab) instead of the one they used last.
class ActiveJourneySync extends ConsumerStatefulWidget {
  const ActiveJourneySync({
    required this.journeyId,
    required this.child,
    super.key,
  });

  final String journeyId;
  final Widget child;

  @override
  ConsumerState<ActiveJourneySync> createState() => _ActiveJourneySyncState();
}

class _ActiveJourneySyncState extends ConsumerState<ActiveJourneySync> {
  @override
  void initState() {
    super.initState();
    _select();
  }

  @override
  void didUpdateWidget(ActiveJourneySync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.journeyId != widget.journeyId) _select();
  }

  /// Deferred: a provider must not change during a widget lifecycle call.
  void _select() {
    final id = widget.journeyId;
    scheduleMicrotask(() {
      if (!mounted) return;
      unawaited(ref.read(activeJourneyIdProvider.notifier).select(id));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
