import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wall clock for "today" computations. Override in tests.
final journeysClockProvider = Provider<Clock>(
  (ref) => Clock(() => clock.now()),
);

/// Time from [now] to the next quarter hour, counted on the UTC timeline:
/// local wall-clock arithmetic goes negative in the repeated hour of a DST
/// fall-back and spun a 0 ms timer loop (B-B3). Every whole- and half-hour
/// UTC offset (and the 45-minute ones) lands on these instants too.
Duration untilNextQuarterHour(DateTime now) {
  const quarter = 15 * Duration.millisecondsPerMinute;
  final ms = now.millisecondsSinceEpoch;
  return Duration(milliseconds: quarter - ms % quarter);
}

/// "Now" for "today" computations. Recomputed when the app resumes and by
/// `DayTicker` (mounted app-wide in `OurneyApp`) on every quarter hour,
/// so "today" rolls over at midnight in any journey time zone (whole- and
/// half-hour offsets) for every screen and provider that reads it.
final journeysNowProvider = Provider<DateTime>((ref) {
  final now = ref.watch(journeysClockProvider).now();
  // Plain unit tests run without a widgets binding: no lifecycle there.
  if (_hasBinding()) {
    final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
    ref.onDispose(lifecycle.dispose);
  }
  return now;
});

bool _hasBinding() {
  try {
    WidgetsBinding.instance;
    return true;
  } on Object {
    return false;
  }
}

/// Maps every emission of [source] with the current [journeysNowProvider]
/// value. When "now" moves on, the last value is mapped again: the database
/// stream is subscribed once, never recreated by the clock.
Stream<R> mapWithNow<T, R>(
  Ref ref,
  Stream<T> source,
  R Function(T value, DateTime now) map,
) {
  final controller = StreamController<R>(sync: true);
  T? last;
  var has = false;
  void emit() {
    if (!has || controller.isClosed) return;
    try {
      controller.add(map(last as T, ref.read(journeysNowProvider)));
    } on Object catch (e, st) {
      controller.addError(e, st);
    }
  }

  final sub = source.listen(
    (v) {
      last = v;
      has = true;
      emit();
    },
    onError: controller.addError,
    onDone: controller.close,
  );
  ref.listen<DateTime>(journeysNowProvider, (_, _) => emit());
  ref.onDispose(() {
    unawaited(sub.cancel());
    unawaited(controller.close());
  });
  return controller.stream;
}
