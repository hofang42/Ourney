// Shared plumbing of the social v1.3 repositories (server-only, no drift
// cache): an RPC caller with error mapping, a change bus that refreshes every
// social stream after a mutation, and [refreshingStream].
import 'dart:async';

import 'package:ourney_core/ourney_core.dart';

import 'data_context.dart';
import 'remote/remote_api.dart';

/// `Timer.periodic`-shaped factory (injectable so tests never leak timers).
typedef PeriodicTimerFactory = Timer Function(
  Duration interval,
  void Function(Timer) tick,
);

/// Default refresh period of social lists and inbox counts.
const Duration socialPollInterval = Duration(seconds: 20);

class SocialContext {
  SocialContext(
    this.data, {
    this.pollInterval = socialPollInterval,
    PeriodicTimerFactory? periodic,
  }) : periodic = periodic ?? Timer.periodic;

  final DataContext data;

  /// Null disables polling (streams then refresh on fetch / mutations /
  /// realtime only).
  final Duration? pollInterval;
  final PeriodicTimerFactory periodic;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires after any social mutation of this client.
  Stream<void> get changes => _changes.stream;

  /// Asks every open social stream to re-fetch.
  void changed() {
    if (!_changes.isClosed) _changes.add(null);
  }

  RemoteApi get remote => data.requireRemote();

  String requireUserId() => data.requireUserId();

  /// Calls [fn] and parses its result. Malformed payloads surface as
  /// `OurneyException(unknown)` (transport errors are mapped by [RemoteApi]).
  Future<T> call<T>(
    String fn,
    Map<String, dynamic> params,
    T Function(Object? json) parse,
  ) async {
    final result = await remote.rpc(fn, params);
    try {
      return parse(result);
    } on OurneyException {
      rethrow;
    } on Object catch (e) {
      throw OurneyException(OurneyErrorCode.unknown, 'bad $fn payload: $e');
    }
  }

  /// Calls a `void` RPC then refreshes the social streams.
  Future<void> mutate(String fn, Map<String, dynamic> params) async {
    await remote.rpc(fn, params);
    changed();
  }

  /// A stream that fetches on listen, after every [changes] event, on each
  /// [extraTriggers] event and every [pollInterval].
  Stream<T> watch<T>(
    Future<T> Function() fetch, {
    Iterable<Stream<Object?>> Function()? extraTriggers,
  }) => refreshingStream(
    fetch: fetch,
    triggers: () => [changes, ...?extraTriggers?.call()],
    interval: pollInterval,
    periodic: periodic,
  );

  Future<void> dispose() => _changes.close();
}

/// Single-subscription stream of [fetch] results.
///
/// * Fetches once on listen, then again on any [triggers] event and every
///   [interval] (when non-null). Concurrent requests coalesce into one
///   follow-up fetch.
/// * Errors are forwarded until a first value was delivered; afterwards
///   `offline` failures of background refreshes are dropped (the last value
///   stays on screen) while other errors are forwarded.
/// * Errors of [triggers] are ignored (e.g. a realtime channel failure: the
///   poll still runs).
/// * Cancelling the subscription cancels the timer and every trigger.
Stream<T> refreshingStream<T>({
  required Future<T> Function() fetch,
  Iterable<Stream<Object?>> Function()? triggers,
  Duration? interval,
  PeriodicTimerFactory periodic = Timer.periodic,
}) {
  late final StreamController<T> controller;
  final subs = <StreamSubscription<Object?>>[];
  Timer? timer;
  var cancelled = false;
  var running = false;
  var again = false;
  var delivered = false;

  Future<void> run() async {
    if (cancelled) return;
    if (running) {
      again = true;
      return;
    }
    running = true;
    try {
      do {
        again = false;
        try {
          final value = await fetch();
          if (cancelled) return;
          delivered = true;
          controller.add(value);
        } on Object catch (e, st) {
          if (cancelled) return;
          final offline =
              e is OurneyException && e.error == OurneyErrorCode.offline;
          if (!delivered || !offline) controller.addError(e, st);
        }
      } while (again && !cancelled);
    } finally {
      running = false;
    }
  }

  controller = StreamController<T>(
    onListen: () {
      for (final t in triggers?.call() ?? const <Stream<Object?>>[]) {
        subs.add(t.listen((_) => unawaited(run()), onError: (Object _) {}));
      }
      final every = interval;
      if (every != null) timer = periodic(every, (_) => unawaited(run()));
      unawaited(run());
    },
    onCancel: () async {
      cancelled = true;
      timer?.cancel();
      timer = null;
      final pending = [for (final s in subs) s.cancel()];
      subs.clear();
      await Future.wait(pending);
    },
  );
  return controller.stream;
}
