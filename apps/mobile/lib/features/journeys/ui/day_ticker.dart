import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journeys_providers.dart';

export '../data/journeys_providers.dart' show untilNextQuarterHour;

/// Refreshes [journeysNowProvider] on every quarter hour while [child] is
/// mounted, so "today" rolls over at midnight in any journey time zone
/// (whole- and half-hour offsets). Owned by the widget so the timer stops
/// with the screen.
class DayTicker extends ConsumerStatefulWidget {
  const DayTicker({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DayTicker> createState() => _DayTickerState();
}

class _DayTickerState extends ConsumerState<DayTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final now = ref.read(journeysClockProvider).now();
    _timer = Timer(untilNextQuarterHour(now), () {
      ref.invalidate(journeysNowProvider);
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
