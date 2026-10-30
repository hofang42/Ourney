import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journeys_providers.dart';

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
    final now = DateTime.now();
    final next = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
    ).add(Duration(minutes: (now.minute ~/ 15 + 1) * 15));
    _timer = Timer(next.difference(now), () {
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
