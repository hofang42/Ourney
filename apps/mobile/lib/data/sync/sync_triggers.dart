import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

/// Runs [onTrigger] when the app should sync: shortly after start, when a
/// network connection appears (connectivity_plus) and when the app resumes.
/// [onTrigger] receives `force: true` so the outbox ignores its backoff.
class SyncTriggers {
  SyncTriggers({
    required this.onTrigger,
    Stream<List<ConnectivityResult>>? connectivity,
    bool listenLifecycle = true,
    Duration startDelay = const Duration(seconds: 2),
    Duration periodic = const Duration(minutes: 5),
  }) {
    _sub = connectivity?.listen(_onConnectivity);
    if (listenLifecycle) {
      _lifecycle = AppLifecycleListener(
        onResume: () => _fire(),
        onPause: () => _foreground = false,
      );
    }
    // Deferred so the camera opens first (NFR-1).
    _start = Timer(startDelay, _fire);
    _tick = Timer.periodic(periodic, (_) {
      if (_foreground) _fire();
    });
  }

  final void Function() onTrigger;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  AppLifecycleListener? _lifecycle;
  Timer? _start;
  Timer? _tick;
  bool _online = true;
  bool _foreground = true;

  void _onConnectivity(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    final regained = online && !_online;
    _online = online;
    if (regained) _fire();
  }

  void _fire() {
    _foreground = true;
    if (_online) onTrigger();
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _lifecycle?.dispose();
    _start?.cancel();
    _tick?.cancel();
  }
}
