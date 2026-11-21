import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourney/data/sync/sync_triggers.dart';

void main() {
  test('seeds the online flag from the initial connectivity check', () async {
    final ctl = StreamController<List<ConnectivityResult>>();
    var fired = 0;
    final t = SyncTriggers(
      onTrigger: () => fired++,
      connectivity: ctl.stream,
      initialConnectivity: () async => [ConnectivityResult.none],
      listenLifecycle: false,
      startDelay: const Duration(days: 1),
      periodic: const Duration(days: 1),
    );
    await Future<void>.delayed(Duration.zero);
    // First event is "online": the app started offline, so this is a regain.
    ctl.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    expect(fired, 1);
    t.dispose();
    await ctl.close();
  });

  test(
    'a start that is already online does not fire on the first event',
    () async {
      final ctl = StreamController<List<ConnectivityResult>>();
      var fired = 0;
      final t = SyncTriggers(
        onTrigger: () => fired++,
        connectivity: ctl.stream,
        initialConnectivity: () async => [ConnectivityResult.wifi],
        listenLifecycle: false,
        startDelay: const Duration(days: 1),
        periodic: const Duration(days: 1),
      );
      await Future<void>.delayed(Duration.zero);
      ctl.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(fired, 0);
      t.dispose();
      await ctl.close();
    },
  );
}
